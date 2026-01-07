module AdapterPatternSpec (spec) where

import Test.Hspec
import Test.QuickCheck

import AdapterPattern

spec :: Spec
spec = do
  variableLightAdapterSpec
  userFormatAdapterSpec
  apiResponseAdapterSpec
  temperatureAdapterSpec
  currencyAdapterSpec
  genericAdapterSpec

-- ============================================================
-- Variable Light Adapter Tests
-- ============================================================

variableLightAdapterSpec :: Spec
variableLightAdapterSpec = describe "VariableLightAdapter" $ do
  describe "VariableLight (Adaptee)" $ do
    it "should set intensity within bounds" $ do
      let light = VariableLight 0
          updated = setLightIntensity 50 light
      vlIntensity updated `shouldBe` 50

    it "should clamp intensity to 0" $ do
      let light = VariableLight 50
          updated = setLightIntensity (-10) light
      vlIntensity updated `shouldBe` 0

    it "should clamp intensity to 100" $ do
      let light = VariableLight 50
          updated = setLightIntensity 150 light
      vlIntensity updated `shouldBe` 100

  describe "makeVariableLightAdapter" $ do
    it "should create adapter with specified min/max" $ do
      let adapter = makeVariableLightAdapter 0 100
      vlaMinIntensity adapter `shouldBe` 0
      vlaMaxIntensity adapter `shouldBe` 100
      vlIntensity (vlaLight adapter) `shouldBe` 0

  describe "adaptedTurnOn" $ do
    it "should set light to max intensity" $ do
      let adapter = makeVariableLightAdapter 0 100
          (newAdapter, result) = adaptedTurnOn adapter
      vlIntensity (vlaLight newAdapter) `shouldBe` 100
      srOn result `shouldBe` True
      srIntensity result `shouldBe` Just 100

    it "should work with custom max intensity" $ do
      let adapter = makeVariableLightAdapter 10 80
          (newAdapter, result) = adaptedTurnOn adapter
      vlIntensity (vlaLight newAdapter) `shouldBe` 80
      srIntensity result `shouldBe` Just 80

  describe "adaptedTurnOff" $ do
    it "should set light to min intensity" $ do
      let adapter = makeVariableLightAdapter 0 100
          (onAdapter, _) = adaptedTurnOn adapter
          (offAdapter, result) = adaptedTurnOff onAdapter
      vlIntensity (vlaLight offAdapter) `shouldBe` 0
      srOn result `shouldBe` False
      srIntensity result `shouldBe` Just 0

    it "should work with custom min intensity" $ do
      let adapter = makeVariableLightAdapter 10 80
          (newAdapter, result) = adaptedTurnOff adapter
      vlIntensity (vlaLight newAdapter) `shouldBe` 10
      srIntensity result `shouldBe` Just 10

  describe "Switchable instance" $ do
    it "should work through Switchable interface for turnOn" $ do
      let adapter = makeVariableLightAdapter 0 100
          (newAdapter, result) = switchTurnOn adapter
      srOn result `shouldBe` True

    it "should work through Switchable interface for turnOff" $ do
      let adapter = makeVariableLightAdapter 0 100
          (newAdapter, result) = switchTurnOff adapter
      srOn result `shouldBe` False

-- ============================================================
-- User Format Adapter Tests
-- ============================================================

userFormatAdapterSpec :: Spec
userFormatAdapterSpec = describe "User Format Adapter" $ do
  describe "adaptOldToNew" $ do
    it "should convert old format to new format" $ do
      let oldUser = OldUserFormat
            { oufFirstName = "Taro"
            , oufLastName = "Yamada"
            , oufEmailAddress = "taro@example.com"
            , oufPhoneNumber = "090-1234-5678"
            }
          newUser = adaptOldToNew oldUser
      nufName newUser `shouldBe` "Yamada Taro"
      nufEmail newUser `shouldBe` "taro@example.com"
      nufPhone newUser `shouldBe` "090-1234-5678"

    it "should add migration metadata" $ do
      let oldUser = OldUserFormat "Taro" "Yamada" "taro@example.com" "090-1234-5678"
          newUser = adaptOldToNew oldUser
      case nufMetadata newUser of
        Just meta -> do
          umMigrated meta `shouldBe` True
          umOriginalFormat meta `shouldBe` "old"
        Nothing -> expectationFailure "Expected metadata"

  describe "adaptNewToOld" $ do
    it "should convert new format to old format" $ do
      let newUser = NewUserFormat
            { nufName = "Yamada Taro"
            , nufEmail = "taro@example.com"
            , nufPhone = "090-1234-5678"
            , nufMetadata = Nothing
            }
          oldUser = adaptNewToOld newUser
      oufFirstName oldUser `shouldBe` "Taro"
      oufLastName oldUser `shouldBe` "Yamada"
      oufEmailAddress oldUser `shouldBe` "taro@example.com"
      oufPhoneNumber oldUser `shouldBe` "090-1234-5678"

    it "should handle single name" $ do
      let newUser = NewUserFormat "Madonna" "madonna@example.com" "123-456-7890" Nothing
          oldUser = adaptNewToOld newUser
      oufFirstName oldUser `shouldBe` ""
      oufLastName oldUser `shouldBe` "Madonna"

    it "should handle multiple name parts" $ do
      let newUser = NewUserFormat "Van Der Berg Jan" "jan@example.com" "123-456-7890" Nothing
          oldUser = adaptNewToOld newUser
      oufLastName oldUser `shouldBe` "Van"
      oufFirstName oldUser `shouldBe` "Der Berg Jan"

-- ============================================================
-- API Response Adapter Tests
-- ============================================================

apiResponseAdapterSpec :: Spec
apiResponseAdapterSpec = describe "API Response Adapter" $ do
  describe "adaptExternalToInternal" $ do
    it "should convert external response to internal format" $ do
      let external = ExternalApiResponse
            { earDataId = "ext-123"
            , earDataIdentifier = "user-456"
            , earAttributeName = "Test User"
            , earAttributeCreatedAt = "2024-01-15T10:30:00Z"
            }
          internal = adaptExternalToInternal external
      idId internal `shouldBe` "user-456"
      idName internal `shouldBe` "Test User"
      idCreatedAt internal `shouldBe` "2024-01-15T10:30:00Z"

    it "should add source metadata" $ do
      let external = ExternalApiResponse "ext-123" "user-456" "Test" "2024-01-15"
          internal = adaptExternalToInternal external
      case idMetadata internal of
        Just meta -> do
          amSource meta `shouldBe` "external-api"
          amOriginalId meta `shouldBe` "ext-123"
        Nothing -> expectationFailure "Expected metadata"

  describe "adaptInternalToExternal" $ do
    it "should convert internal data to external format" $ do
      let internal = InternalData
            { idId = "user-456"
            , idName = "Test User"
            , idCreatedAt = "2024-01-15T10:30:00Z"
            , idMetadata = Just (ApiMetadata "external-api" "ext-123")
            }
          external = adaptInternalToExternal internal
      earDataIdentifier external `shouldBe` "user-456"
      earAttributeName external `shouldBe` "Test User"
      earAttributeCreatedAt external `shouldBe` "2024-01-15T10:30:00Z"
      earDataId external `shouldBe` "ext-123"

    it "should use id when no metadata" $ do
      let internal = InternalData "user-456" "Test" "2024-01-15" Nothing
          external = adaptInternalToExternal internal
      earDataId external `shouldBe` "user-456"

-- ============================================================
-- Temperature Adapter Tests
-- ============================================================

temperatureAdapterSpec :: Spec
temperatureAdapterSpec = describe "Temperature Adapter" $ do
  describe "celsiusToFahrenheit" $ do
    it "should convert 0°C to 32°F" $ do
      let c = Celsius 0
          f = celsiusToFahrenheit c
      getFahrenheit f `shouldBe` 32

    it "should convert 100°C to 212°F" $ do
      let c = Celsius 100
          f = celsiusToFahrenheit c
      getFahrenheit f `shouldBe` 212

    it "should convert -40°C to -40°F" $ do
      let c = Celsius (-40)
          f = celsiusToFahrenheit c
      getFahrenheit f `shouldBe` (-40)

  describe "fahrenheitToCelsius" $ do
    it "should convert 32°F to 0°C" $ do
      let f = Fahrenheit 32
          c = fahrenheitToCelsius f
      getCelsius c `shouldBe` 0

    it "should convert 212°F to 100°C" $ do
      let f = Fahrenheit 212
          c = fahrenheitToCelsius f
      getCelsius c `shouldBe` 100

  describe "roundtrip" $ do
    it "should be reversible" $ property $
      \temp -> 
        let c = Celsius temp
            f = celsiusToFahrenheit c
            c' = fahrenheitToCelsius f
        in abs (getCelsius c' - temp) < 0.0001

-- ============================================================
-- Currency Adapter Tests
-- ============================================================

currencyAdapterSpec :: Spec
currencyAdapterSpec = describe "Currency Adapter" $ do
  describe "USD to EUR" $ do
    it "should convert at 0.85 rate" $ do
      let usd = USD 100
          eur = convertUsdToEur usd
      getEur eur `shouldBe` 85

  describe "USD to JPY" $ do
    it "should convert at 110 rate" $ do
      let usd = USD 100
          jpy = convertUsdToJpy usd
      getJpy jpy `shouldBe` 11000

  describe "EUR to USD" $ do
    it "should convert at inverse 0.85 rate" $ do
      let eur = EUR 85
          usd = convertEurToUsd eur
      getUsd usd `shouldBe` 100

  describe "JPY to USD" $ do
    it "should convert at inverse 110 rate" $ do
      let jpy = JPY 11000
          usd = convertJpyToUsd jpy
      getUsd usd `shouldBe` 100

  describe "roundtrip" $ do
    it "USD -> EUR -> USD should be reversible" $ do
      let original = USD 100
          eur = convertUsdToEur original
          back = convertEurToUsd eur
      abs (getUsd back - getUsd original) < 0.01 `shouldBe` True

    it "USD -> JPY -> USD should be reversible" $ do
      let original = USD 100
          jpy = convertUsdToJpy original
          back = convertJpyToUsd jpy
      abs (getUsd back - getUsd original) < 0.01 `shouldBe` True

-- ============================================================
-- Generic Adapter Tests
-- ============================================================

genericAdapterSpec :: Spec
genericAdapterSpec = describe "Generic Adapter" $ do
  describe "Adapter" $ do
    it "should adapt in forward direction" $ do
      let adapter = Adapter
            { adapterTo = (* 2) :: Int -> Int
            , adapterFrom = (`div` 2)
            }
      adapt adapter 5 `shouldBe` 10

    it "should adapt in reverse direction" $ do
      let adapter = Adapter
            { adapterTo = (* 2) :: Int -> Int
            , adapterFrom = (`div` 2)
            }
      adaptBack adapter 10 `shouldBe` 5

    it "should work with different types" $ do
      let adapter = Adapter
            { adapterTo = show :: Int -> String
            , adapterFrom = read
            }
      adapt adapter 42 `shouldBe` "42"
      adaptBack adapter "42" `shouldBe` 42

    it "should compose with temperature conversion" $ do
      let tempAdapter = Adapter
            { adapterTo = \(Celsius c) -> Fahrenheit (c * 9/5 + 32)
            , adapterFrom = \(Fahrenheit f) -> Celsius ((f - 32) * 5/9)
            }
      getFahrenheit (adapt tempAdapter (Celsius 0)) `shouldBe` 32
      getCelsius (adaptBack tempAdapter (Fahrenheit 32)) `shouldBe` 0
