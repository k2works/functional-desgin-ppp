{-# LANGUAGE RecordWildCards #-}

-- |
-- Module      : AdapterPattern
-- Description : Adapter pattern implementation in Haskell
-- 
-- This module demonstrates the Adapter pattern using various examples:
-- - VariableLight adapter: Adapts intensity-based light to on/off interface
-- - Data format adapters: Converting between different data formats
-- - API response adapters: Transforming external API responses

module AdapterPattern
  ( -- * Switchable Interface
    SwitchResult(..)
  , Switchable(..)
  
  -- * Variable Light (Adaptee)
  , VariableLight(..)
  , setLightIntensity
  
  -- * Variable Light Adapter
  , VariableLightAdapter(..)
  , makeVariableLightAdapter
  , adaptedTurnOn
  , adaptedTurnOff
  
  -- * User Format Adapters
  , OldUserFormat(..)
  , NewUserFormat(..)
  , UserMetadata(..)
  , adaptOldToNew
  , adaptNewToOld
  
  -- * API Response Adapters
  , ExternalApiResponse(..)
  , InternalData(..)
  , ApiMetadata(..)
  , adaptExternalToInternal
  , adaptInternalToExternal
  
  -- * Temperature Adapter
  , Celsius(..)
  , Fahrenheit(..)
  , celsiusToFahrenheit
  , fahrenheitToCelsius
  
  -- * Currency Adapter
  , USD(..)
  , EUR(..)
  , JPY(..)
  , convertUsdToEur
  , convertUsdToJpy
  , convertEurToUsd
  , convertJpyToUsd
  
  -- * Generic Adapter
  , Adapter(..)
  , adapt
  , adaptBack
  ) where

import Data.List.NonEmpty (nonEmpty)
import qualified Data.List.NonEmpty as NE

-- ============================================================
-- Switchable Interface (Target)
-- ============================================================

-- | Result of a switch operation
data SwitchResult = SwitchResult
  { srOn :: Bool
  , srIntensity :: Maybe Int
  } deriving (Show, Eq)

-- | Switchable interface - the target interface
class Switchable a where
  switchTurnOn :: a -> (a, SwitchResult)
  switchTurnOff :: a -> (a, SwitchResult)

-- ============================================================
-- Variable Light (Adaptee)
-- ============================================================

-- | Variable light with intensity control
data VariableLight = VariableLight
  { vlIntensity :: Int  -- ^ 0-100
  } deriving (Show, Eq)

-- | Set the light intensity (the adaptee's specific method)
setLightIntensity :: Int -> VariableLight -> VariableLight
setLightIntensity intensity vl = vl { vlIntensity = max 0 (min 100 intensity) }

-- ============================================================
-- Variable Light Adapter
-- ============================================================

-- | Adapter that wraps VariableLight and provides Switchable interface
data VariableLightAdapter = VariableLightAdapter
  { vlaLight :: VariableLight
  , vlaMinIntensity :: Int
  , vlaMaxIntensity :: Int
  } deriving (Show, Eq)

-- | Create a variable light adapter
makeVariableLightAdapter :: Int -> Int -> VariableLightAdapter
makeVariableLightAdapter minI maxI = VariableLightAdapter
  { vlaLight = VariableLight 0
  , vlaMinIntensity = minI
  , vlaMaxIntensity = maxI
  }

-- | Turn on through the adapter
adaptedTurnOn :: VariableLightAdapter -> (VariableLightAdapter, SwitchResult)
adaptedTurnOn adapter =
  let newLight = setLightIntensity (vlaMaxIntensity adapter) (vlaLight adapter)
      newAdapter = adapter { vlaLight = newLight }
      result = SwitchResult True (Just $ vlIntensity newLight)
  in (newAdapter, result)

-- | Turn off through the adapter
adaptedTurnOff :: VariableLightAdapter -> (VariableLightAdapter, SwitchResult)
adaptedTurnOff adapter =
  let newLight = setLightIntensity (vlaMinIntensity adapter) (vlaLight adapter)
      newAdapter = adapter { vlaLight = newLight }
      result = SwitchResult False (Just $ vlIntensity newLight)
  in (newAdapter, result)

-- Make VariableLightAdapter an instance of Switchable
instance Switchable VariableLightAdapter where
  switchTurnOn = adaptedTurnOn
  switchTurnOff = adaptedTurnOff

-- ============================================================
-- User Format Adapters
-- ============================================================

-- | Old user format (legacy system)
data OldUserFormat = OldUserFormat
  { oufFirstName :: String
  , oufLastName :: String
  , oufEmailAddress :: String
  , oufPhoneNumber :: String
  } deriving (Show, Eq)

-- | Metadata for converted users
data UserMetadata = UserMetadata
  { umMigrated :: Bool
  , umOriginalFormat :: String
  } deriving (Show, Eq)

-- | New user format (modern system)
data NewUserFormat = NewUserFormat
  { nufName :: String
  , nufEmail :: String
  , nufPhone :: String
  , nufMetadata :: Maybe UserMetadata
  } deriving (Show, Eq)

-- | Adapt old user format to new format
adaptOldToNew :: OldUserFormat -> NewUserFormat
adaptOldToNew old = NewUserFormat
  { nufName = oufLastName old ++ " " ++ oufFirstName old
  , nufEmail = oufEmailAddress old
  , nufPhone = oufPhoneNumber old
  , nufMetadata = Just UserMetadata
      { umMigrated = True
      , umOriginalFormat = "old"
      }
  }

-- | Adapt new user format to old format
adaptNewToOld :: NewUserFormat -> OldUserFormat
adaptNewToOld new =
  case nonEmpty (words (nufName new)) of
    Nothing -> OldUserFormat
      { oufFirstName = ""
      , oufLastName = ""
      , oufEmailAddress = nufEmail new
      , oufPhoneNumber = nufPhone new
      }
    Just ne -> OldUserFormat
      { oufFirstName = unwords (NE.tail ne)
      , oufLastName = NE.head ne
      , oufEmailAddress = nufEmail new
      , oufPhoneNumber = nufPhone new
      }

-- ============================================================
-- API Response Adapters
-- ============================================================

-- | External API response format
data ExternalApiResponse = ExternalApiResponse
  { earDataId :: String
  , earDataIdentifier :: String
  , earAttributeName :: String
  , earAttributeCreatedAt :: String
  } deriving (Show, Eq)

-- | Metadata for internal data
data ApiMetadata = ApiMetadata
  { amSource :: String
  , amOriginalId :: String
  } deriving (Show, Eq)

-- | Internal data format
data InternalData = InternalData
  { idId :: String
  , idName :: String
  , idCreatedAt :: String
  , idMetadata :: Maybe ApiMetadata
  } deriving (Show, Eq)

-- | Adapt external API response to internal format
adaptExternalToInternal :: ExternalApiResponse -> InternalData
adaptExternalToInternal external = InternalData
  { idId = earDataIdentifier external
  , idName = earAttributeName external
  , idCreatedAt = earAttributeCreatedAt external
  , idMetadata = Just ApiMetadata
      { amSource = "external-api"
      , amOriginalId = earDataId external
      }
  }

-- | Adapt internal data to external API format
adaptInternalToExternal :: InternalData -> ExternalApiResponse
adaptInternalToExternal internal = ExternalApiResponse
  { earDataId = maybe (idId internal) amOriginalId (idMetadata internal)
  , earDataIdentifier = idId internal
  , earAttributeName = idName internal
  , earAttributeCreatedAt = idCreatedAt internal
  }

-- ============================================================
-- Temperature Adapter
-- ============================================================

-- | Temperature in Celsius
newtype Celsius = Celsius { getCelsius :: Double }
  deriving (Show, Eq)

-- | Temperature in Fahrenheit
newtype Fahrenheit = Fahrenheit { getFahrenheit :: Double }
  deriving (Show, Eq)

-- | Convert Celsius to Fahrenheit
celsiusToFahrenheit :: Celsius -> Fahrenheit
celsiusToFahrenheit (Celsius c) = Fahrenheit (c * 9/5 + 32)

-- | Convert Fahrenheit to Celsius
fahrenheitToCelsius :: Fahrenheit -> Celsius
fahrenheitToCelsius (Fahrenheit f) = Celsius ((f - 32) * 5/9)

-- ============================================================
-- Currency Adapter
-- ============================================================

-- | US Dollars
newtype USD = USD { getUsd :: Double }
  deriving (Show, Eq)

-- | Euros
newtype EUR = EUR { getEur :: Double }
  deriving (Show, Eq)

-- | Japanese Yen
newtype JPY = JPY { getJpy :: Double }
  deriving (Show, Eq)

-- | Convert USD to EUR (simplified rate)
convertUsdToEur :: USD -> EUR
convertUsdToEur (USD usd) = EUR (usd * 0.85)

-- | Convert USD to JPY (simplified rate)
convertUsdToJpy :: USD -> JPY
convertUsdToJpy (USD usd) = JPY (usd * 110)

-- | Convert EUR to USD
convertEurToUsd :: EUR -> USD
convertEurToUsd (EUR eur) = USD (eur / 0.85)

-- | Convert JPY to USD
convertJpyToUsd :: JPY -> USD
convertJpyToUsd (JPY jpy) = USD (jpy / 110)

-- ============================================================
-- Generic Adapter
-- ============================================================

-- | Generic bidirectional adapter
data Adapter a b = Adapter
  { adapterTo :: a -> b    -- ^ Convert from A to B
  , adapterFrom :: b -> a  -- ^ Convert from B to A
  }

-- | Apply adapter to convert from A to B
adapt :: Adapter a b -> a -> b
adapt = adapterTo

-- | Apply adapter to convert from B to A
adaptBack :: Adapter a b -> b -> a
adaptBack = adapterFrom
