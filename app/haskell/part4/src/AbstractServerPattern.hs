{-# LANGUAGE TypeFamilies #-}
-- |
-- Module      : AbstractServerPattern
-- Description : Abstract Server pattern implementation in Haskell
-- 
-- This module demonstrates the Abstract Server pattern using various examples:
-- - Switchable interface with Light, Fan, Motor implementations
-- - Repository interface with Memory and Mock implementations
-- - Service layer depending on abstractions

module AbstractServerPattern
  ( -- * Switchable Interface
    SwitchState(..)
  , Switchable(..)
  
  -- * Light Implementation
  , Light(..)
  , makeLight
  , makeLightOn
  
  -- * Fan Implementation
  , FanSpeed(..)
  , Fan(..)
  , makeFan
  , setFanSpeed
  
  -- * Motor Implementation
  , MotorDirection(..)
  , Motor(..)
  , makeMotor
  , reverseMotor
  
  -- * Switch Client
  , engage
  , disengage
  , toggle
  , switchStatus
  
  -- * Repository Interface
  , Entity(..)
  , Repository(..)
  
  -- * Memory Repository
  , MemoryRepository(..)
  , makeMemoryRepo
  
  -- * Mock Repository
  , MockRepository(..)
  , makeMockRepo
  
  -- * User Service
  , User(..)
  , createUser
  , getUser
  , getAllUsers
  , deleteUser
  
  -- * Logger Interface
  , LogLevel(..)
  , Logger(..)
  
  -- * Console Logger
  , ConsoleLogger(..)
  
  -- * Null Logger
  , NullLogger(..)
  
  -- * File Logger (simulation)
  , FileLogger(..)
  , makeFileLogger
  ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Maybe (maybeToList)

-- ============================================================
-- Switchable Interface
-- ============================================================

-- | State of a switchable device
data SwitchState = On | Off
  deriving (Show, Eq)

-- | Switchable interface (Abstract Server)
class Switchable a where
  turnOn :: a -> a
  turnOff :: a -> a
  isOn :: a -> Bool

-- ============================================================
-- Light Implementation
-- ============================================================

-- | Light device
data Light = Light
  { lightState :: SwitchState
  , lightName :: String
  } deriving (Show, Eq)

-- | Create a light (off by default)
makeLight :: String -> Light
makeLight name = Light Off name

-- | Create a light that is on
makeLightOn :: String -> Light
makeLightOn name = Light On name

instance Switchable Light where
  turnOn light = light { lightState = On }
  turnOff light = light { lightState = Off }
  isOn light = lightState light == On

-- ============================================================
-- Fan Implementation
-- ============================================================

-- | Fan speed levels
data FanSpeed = Low | Medium | High
  deriving (Show, Eq, Ord)

-- | Fan device
data Fan = Fan
  { fanState :: SwitchState
  , fanSpeed :: FanSpeed
  , fanName :: String
  } deriving (Show, Eq)

-- | Create a fan
makeFan :: String -> Fan
makeFan name = Fan Off Low name

-- | Set fan speed (only works when on)
setFanSpeed :: FanSpeed -> Fan -> Fan
setFanSpeed speed fan
  | isOn fan = fan { fanSpeed = speed }
  | otherwise = fan

instance Switchable Fan where
  turnOn fan = fan { fanState = On }
  turnOff fan = fan { fanState = Off }
  isOn fan = fanState fan == On

-- ============================================================
-- Motor Implementation
-- ============================================================

-- | Motor direction
data MotorDirection = Forward | Reverse
  deriving (Show, Eq)

-- | Motor device
data Motor = Motor
  { motorState :: SwitchState
  , motorDirection :: MotorDirection
  , motorName :: String
  } deriving (Show, Eq)

-- | Create a motor
makeMotor :: String -> Motor
makeMotor name = Motor Off Forward name

-- | Reverse motor direction (only works when on)
reverseMotor :: Motor -> Motor
reverseMotor motor
  | isOn motor = motor { motorDirection = flipDir (motorDirection motor) }
  | otherwise = motor
  where
    flipDir Forward = Reverse
    flipDir Reverse = Forward

instance Switchable Motor where
  turnOn motor = motor { motorState = On }
  turnOff motor = motor { motorState = Off }
  isOn motor = motorState motor == On

-- ============================================================
-- Switch Client
-- ============================================================

-- | Engage a switch (turn on)
engage :: Switchable a => a -> a
engage = turnOn

-- | Disengage a switch (turn off)
disengage :: Switchable a => a -> a
disengage = turnOff

-- | Toggle a switch
toggle :: Switchable a => a -> a
toggle device
  | isOn device = turnOff device
  | otherwise = turnOn device

-- | Get switch status
switchStatus :: Switchable a => a -> SwitchState
switchStatus device
  | isOn device = On
  | otherwise = Off

-- ============================================================
-- Repository Interface
-- ============================================================

-- | Entity with ID
class Entity a where
  entityId :: a -> String
  setEntityId :: String -> a -> a

-- | Repository interface (Abstract Server)
class Repository r where
  type Item r
  findById :: r -> String -> Maybe (Item r)
  findAll :: r -> [Item r]
  save :: r -> Item r -> (r, Item r)
  delete :: r -> String -> (r, Maybe (Item r))

-- ============================================================
-- Memory Repository
-- ============================================================

-- | In-memory repository
data MemoryRepository a = MemoryRepository
  { memData :: Map String a
  , memNextId :: Int
  } deriving (Show, Eq)

-- | Create an empty memory repository
makeMemoryRepo :: MemoryRepository a
makeMemoryRepo = MemoryRepository Map.empty 1

instance Entity a => Repository (MemoryRepository a) where
  type Item (MemoryRepository a) = a
  
  findById repo idVal = Map.lookup idVal (memData repo)
  
  findAll repo = Map.elems (memData repo)
  
  save repo entity = 
    let id' = entityId entity
        newId = if null id' then show (memNextId repo) else id'
        entity' = setEntityId newId entity
        newData = Map.insert newId entity' (memData repo)
        newNextId = if null id' then memNextId repo + 1 else memNextId repo
    in (repo { memData = newData, memNextId = newNextId }, entity')
  
  delete repo idVal =
    let entity = Map.lookup idVal (memData repo)
        newData = Map.delete idVal (memData repo)
    in (repo { memData = newData }, entity)

-- ============================================================
-- Mock Repository
-- ============================================================

-- | Mock repository for testing
data MockRepository a = MockRepository
  { mockData :: [a]
  } deriving (Show, Eq)

-- | Create a mock repository with predefined data
makeMockRepo :: [a] -> MockRepository a
makeMockRepo = MockRepository

instance Entity a => Repository (MockRepository a) where
  type Item (MockRepository a) = a
  
  findById repo idVal = 
    case filter (\x -> entityId x == idVal) (mockData repo) of
      (x:_) -> Just x
      [] -> Nothing
  
  findAll repo = mockData repo
  
  save repo entity =
    let id' = entityId entity
        newId = if null id' then show (length (mockData repo) + 1) else id'
        entity' = setEntityId newId entity
        newData = mockData repo ++ [entity']
    in (repo { mockData = newData }, entity')
  
  delete repo idVal =
    let (deleted, remaining) = partition (\x -> entityId x == idVal) (mockData repo)
    in (repo { mockData = remaining }, listToMaybe deleted)
    where
      partition p xs = (filter p xs, filter (not . p) xs)
      listToMaybe [] = Nothing
      listToMaybe (x:_) = Just x

-- ============================================================
-- User Service
-- ============================================================

-- | User entity
data User = User
  { oderId :: String
  , userName :: String
  , userEmail :: String
  } deriving (Show, Eq)

instance Entity User where
  entityId = oderId
  setEntityId idVal user = user { oderId = idVal }

-- | Create a new user
createUser :: (Repository r, Item r ~ User) => r -> String -> String -> (r, User)
createUser repo name email = 
  let user = User "" name email
  in save repo user

-- | Get a user by ID
getUser :: Repository r => r -> String -> Maybe (Item r)
getUser = findById

-- | Get all users
getAllUsers :: Repository r => r -> [Item r]
getAllUsers = findAll

-- | Delete a user
deleteUser :: Repository r => r -> String -> (r, Maybe (Item r))
deleteUser = delete

-- ============================================================
-- Logger Interface
-- ============================================================

-- | Log levels
data LogLevel = Debug | Info | Warning | Error
  deriving (Show, Eq, Ord)

-- | Logger interface (Abstract Server)
class Logger l where
  logMessage :: l -> LogLevel -> String -> (l, String)

-- ============================================================
-- Console Logger
-- ============================================================

-- | Console logger
data ConsoleLogger = ConsoleLogger
  { clMinLevel :: LogLevel
  } deriving (Show, Eq)

instance Logger ConsoleLogger where
  logMessage logger level msg
    | level >= clMinLevel logger = 
        let output = "[" ++ show level ++ "] " ++ msg
        in (logger, output)
    | otherwise = (logger, "")

-- ============================================================
-- Null Logger
-- ============================================================

-- | Null logger (discards all messages)
data NullLogger = NullLogger
  deriving (Show, Eq)

instance Logger NullLogger where
  logMessage logger _ _ = (logger, "")

-- ============================================================
-- File Logger (simulation)
-- ============================================================

-- | File logger (stores messages in a list)
data FileLogger = FileLogger
  { flPath :: String
  , flMessages :: [String]
  } deriving (Show, Eq)

-- | Create a file logger
makeFileLogger :: String -> FileLogger
makeFileLogger path = FileLogger path []

instance Logger FileLogger where
  logMessage logger level msg =
    let formatted = "[" ++ show level ++ "] " ++ msg
        newMessages = flMessages logger ++ [formatted]
    in (logger { flMessages = newMessages }, formatted)
