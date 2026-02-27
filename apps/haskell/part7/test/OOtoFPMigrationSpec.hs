module OOtoFPMigrationSpec (spec) where

import Test.Hspec
import qualified Data.Map.Strict as Map
import OOtoFPMigration

spec :: Spec
spec = do
  describe "Class to Data Type Migration" $ do
    describe "Animal (Sum Type)" $ do
      let dog = Dog "Rex" "German Shepherd"
      let cat = Cat "Whiskers" "Orange"
      let flyingBird = Bird "Tweety" True
      let penguin = Bird "Pingu" False

      it "makes sounds" $ do
        makeSound dog `shouldBe` "Rex says: Woof!"
        makeSound cat `shouldBe` "Whiskers says: Meow!"
        makeSound flyingBird `shouldBe` "Tweety says: Tweet!"

      it "moves differently" $ do
        move dog `shouldBe` "Rex runs on four legs"
        move cat `shouldBe` "Whiskers prowls silently"
        move flyingBird `shouldBe` "Tweety flies through the air"
        move penguin `shouldBe` "Pingu hops on the ground"

      it "describes animals" $ do
        describeAnimal dog `shouldBe` "Rex says: Woof! and Rex runs on four legs"

    describe "Shape (Type Class)" $ do
      it "calculates circle area" $ do
        let circle = Circle 5.0
        abs (area circle - 78.54) < 0.01 `shouldBe` True

      it "calculates circle perimeter" $ do
        let circle = Circle 5.0
        abs (perimeter circle - 31.42) < 0.01 `shouldBe` True

      it "calculates rectangle area" $ do
        let rect = Rectangle 4.0 5.0
        area rect `shouldBe` 20.0

      it "calculates rectangle perimeter" $ do
        let rect = Rectangle 4.0 5.0
        perimeter rect `shouldBe` 18.0

      it "calculates triangle area" $ do
        let tri = Triangle 6.0 4.0 (3.0, 4.0, 5.0)
        area tri `shouldBe` 12.0

      it "calculates triangle perimeter" $ do
        let tri = Triangle 6.0 4.0 (3.0, 4.0, 5.0)
        perimeter tri `shouldBe` 12.0

  describe "Inheritance to Composition" $ do
    describe "Vehicle" $ do
      it "describes car" $ do
        describeVehicle car `shouldBe` "Car with 200hp gas engine and 4 wheels"

      it "describes motorcycle" $ do
        describeVehicle motorcycle `shouldBe` "Motorcycle with 80hp gas engine and 2 wheels"

      it "describes bicycle" $ do
        describeVehicle bicycle `shouldBe` "Bicycle with no engine and 2 wheels"

      it "creates custom vehicle" $ do
        let tesla = makeVehicle "Tesla" (ElectricEngine 100) (Wheels 4 19)
        describeVehicle tesla `shouldBe` "Tesla with 100kWh electric engine and 4 wheels"

  describe "Mutable State to Immutable Updates" $ do
    describe "BankAccount" $ do
      let account = makeAccount "ACC001" "Alice" 1000.0

      it "deposits money" $ do
        let account' = deposit 500.0 account
        getBalance account' `shouldBe` 1500.0
        getBalance account `shouldBe` 1000.0  -- Original unchanged

      it "ignores negative deposits" $ do
        let account' = deposit (-100.0) account
        getBalance account' `shouldBe` 1000.0

      it "withdraws money" $ do
        case withdraw 300.0 account of
          Just account' -> getBalance account' `shouldBe` 700.0
          Nothing -> expectationFailure "Should succeed"

      it "fails on insufficient funds" $ do
        withdraw 2000.0 account `shouldBe` Nothing

      it "transfers between accounts" $ do
        let account2 = makeAccount "ACC002" "Bob" 500.0
        case transfer 200.0 account account2 of
          Just (from', to') -> do
            getBalance from' `shouldBe` 800.0
            getBalance to' `shouldBe` 700.0
          Nothing -> expectationFailure "Should succeed"

      it "fails transfer on insufficient funds" $ do
        let account2 = makeAccount "ACC002" "Bob" 500.0
        transfer 2000.0 account account2 `shouldBe` Nothing

  describe "Strategy Pattern Migration" $ do
    describe "PaymentMethod" $ do
      it "processes credit card payment" $ do
        let pay = creditCard "1234567890123456"
        case pay 100.0 "Amazon" of
          Right msg -> msg `shouldBe` "Paid $100.0 to Amazon via credit card 1234****"
          Left _ -> expectationFailure "Should succeed"

      it "processes PayPal payment" $ do
        let pay = paypal "user@example.com"
        case pay 50.0 "eBay" of
          Right msg -> msg `shouldBe` "Paid $50.0 to eBay via PayPal (user@example.com)"
          Left _ -> expectationFailure "Should succeed"

      it "processes bitcoin payment" $ do
        let pay = bitcoin "1A2B3C4D5E6F7G8H"
        case pay 0.5 "Crypto Shop" of
          Right msg -> msg `shouldBe` "Paid $0.5 to Crypto Shop via Bitcoin wallet 1A2B3C4D..."
          Left _ -> expectationFailure "Should succeed"

      it "uses strategy via processPayment" $ do
        let strategy = debitCard "9876543210123456"
        case processPayment strategy 75.0 "Store" of
          Right msg -> msg `shouldBe` "Paid $75.0 to Store via debit card 9876****"
          Left _ -> expectationFailure "Should succeed"

  describe "Observer Pattern Migration" $ do
    describe "Event and Subscription" $ do
      let emailSub = subscribe "EmailService"
      let smsSub = subscribe "SMSService"

      it "notifies single subscriber" $ do
        emailSub (UserCreated "alice") `shouldBe` "EmailService notified: User alice created"

      it "publishes to multiple subscribers" $ do
        let notifications = publish [emailSub, smsSub] (OrderPlaced "ORD001" 99.99)
        length notifications `shouldBe` 2
        head notifications `shouldBe` "EmailService notified: Order ORD001 placed for $99.99"

      it "logs events" $ do
        let log1 = logEvent (UserCreated "bob") []
            log2 = logEvent (OrderPlaced "ORD001" 50.0) log1
        length log2 `shouldBe` 2

  describe "Factory Pattern Migration" $ do
    describe "Document" $ do
      it "creates PDF document" $ do
        let doc = createPDF "Hello World"
        renderDocument doc `shouldBe` "<PDF>Hello World</PDF>"

      it "creates Word document" $ do
        let doc = createWord "Report Content"
        renderDocument doc `shouldBe` "<WORD>Report Content</WORD>"

      it "creates HTML document" $ do
        let doc = createHTML "Web Page"
        renderDocument doc `shouldBe` "<html><body>Web Page</body></html>"

  describe "Singleton to Module" $ do
    describe "Config" $ do
      it "provides default config" $ do
        configDbHost defaultConfig `shouldBe` "localhost"
        configDbPort defaultConfig `shouldBe` 5432
        configLogLevel defaultConfig `shouldBe` "INFO"

      it "provides test config" $ do
        configLogLevel testConfig `shouldBe` "DEBUG"

      it "provides production config" $ do
        configDbHost productionConfig `shouldBe` "prod.db.example.com"
        configLogLevel productionConfig `shouldBe` "WARN"

  describe "Null Object to Maybe" $ do
    describe "findUser" $ do
      it "finds existing user" $ do
        case findUser "1" of
          Just user -> simpleUserName user `shouldBe` "Alice"
          Nothing -> expectationFailure "Should find user"

      it "returns Nothing for non-existent user" $ do
        findUser "999" `shouldBe` Nothing

    describe "getUserName" $ do
      it "gets name of existing user" $ do
        getUserName "1" `shouldBe` Just "Alice"

      it "returns Nothing for non-existent user" $ do
        getUserName "999" `shouldBe` Nothing

    describe "getUserNameOrDefault" $ do
      it "gets name of existing user" $ do
        getUserNameOrDefault "1" "Unknown" `shouldBe` "Alice"

      it "returns default for non-existent user" $ do
        getUserNameOrDefault "999" "Unknown" `shouldBe` "Unknown"

  describe "Template Method to Higher-Order Functions" $ do
    describe "DataProcessor" $ do
      it "processes with CSV processor" $ do
        processData csvProcessor "test" `shouldBe` "output:CSV[validated:test]"

      it "processes with JSON processor" $ do
        processData jsonProcessor "test" `shouldBe` "output:{\"data\": \"validated:test\"}"

      it "processes with XML processor" $ do
        processData xmlProcessor "test" `shouldBe` "output:<data>validated:test</data>"

  describe "Chain of Responsibility" $ do
    let validRequest = Request "/api/users" "GET" (Map.fromList [("Authorization", "Bearer token")]) ""
    let noAuthRequest = Request "/api/users" "GET" Map.empty ""
    let emptyBodyPost = Request "/api/users" "POST" (Map.fromList [("Authorization", "Bearer token")]) ""
    let validPost = Request "/api/users" "POST" (Map.fromList [("Authorization", "Bearer token")]) "{\"name\":\"test\"}"

    describe "authHandler" $ do
      it "passes request with auth header" $ do
        case authHandler validRequest of
          Right _ -> return ()
          Left _ -> expectationFailure "Should pass"

      it "rejects request without auth header" $ do
        case authHandler noAuthRequest of
          Left msg -> msg `shouldBe` "Unauthorized: No auth header"
          Right _ -> expectationFailure "Should reject"

    describe "validationHandler" $ do
      it "passes GET request" $ do
        case validationHandler validRequest of
          Right _ -> return ()
          Left _ -> expectationFailure "Should pass"

      it "rejects POST with empty body" $ do
        case validationHandler emptyBodyPost of
          Left msg -> msg `shouldBe` "Bad Request: Empty body"
          Right _ -> expectationFailure "Should reject"

      it "passes POST with body" $ do
        case validationHandler validPost of
          Right _ -> return ()
          Left _ -> expectationFailure "Should pass"

    describe "chainHandlers" $ do
      it "passes through all handlers" $ do
        let chain = chainHandlers [authHandler, loggingHandler, validationHandler]
        case chain validRequest of
          Right _ -> return ()
          Left _ -> expectationFailure "Should pass"

      it "stops at first failure" $ do
        let chain = chainHandlers [authHandler, validationHandler]
        case chain noAuthRequest of
          Left msg -> msg `shouldBe` "Unauthorized: No auth header"
          Right _ -> expectationFailure "Should fail at auth"

      it "fails at validation if auth passes" $ do
        let chain = chainHandlers [authHandler, validationHandler]
        case chain emptyBodyPost of
          Left msg -> msg `shouldBe` "Bad Request: Empty body"
          Right _ -> expectationFailure "Should fail at validation"

  describe "Integration: Combined Patterns" $ do
    it "builds complete request processing system" $ do
      let handlers = chainHandlers [authHandler, loggingHandler, validationHandler]
          request = Request "/api/orders" "POST" 
                    (Map.fromList [("Authorization", "Bearer xyz")]) 
                    "{\"item\":\"widget\"}"
      
      case handlers request of
        Right _ -> return ()
        Left err -> expectationFailure $ "Should succeed: " ++ err

    it "creates immutable vehicle and modifies" $ do
      let baseCar = car
          electricCar = baseCar { vehicleEngine = ElectricEngine 150 }
      vehicleEngine baseCar `shouldBe` GasEngine 200
      vehicleEngine electricCar `shouldBe` ElectricEngine 150
