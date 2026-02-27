-- |
-- Module      : OOtoFPMigration
-- Description : Object-Oriented to Functional Programming Migration
-- 
-- This module demonstrates how to migrate common OO patterns to
-- functional equivalents in Haskell.

{-# LANGUAGE TypeFamilies #-}

module OOtoFPMigration
  ( -- * Class to Data Type Migration
    -- ** OO: Animal class hierarchy -> FP: Sum types
    Animal(..)
  , makeSound
  , move
  , describeAnimal
  
  -- ** OO: Shape interface -> FP: Type class
  , Shape(..)
  , Circle(..)
  , Rectangle(..)
  , Triangle(..)
  
  -- * Inheritance to Composition
  -- ** OO: Vehicle hierarchy -> FP: Composition
  , Engine(..)
  , Wheels(..)
  , Vehicle(..)
  , makeVehicle
  , car
  , motorcycle
  , bicycle
  , describeVehicle
  
  -- * Mutable State to Immutable Updates
  -- ** OO: BankAccount class -> FP: Pure functions
  , BankAccount(..)
  , makeAccount
  , deposit
  , withdraw
  , transfer
  , getBalance
  
  -- * Strategy Pattern Migration
  -- ** OO: PaymentStrategy interface -> FP: Function
  , PaymentMethod
  , creditCard
  , debitCard
  , paypal
  , bitcoin
  , processPayment
  
  -- * Observer Pattern Migration
  -- ** OO: Observer pattern -> FP: Pure subscriptions
  , Event(..)
  , Subscription
  , subscribe
  , publish
  , EventLog
  , logEvent
  
  -- * Factory Pattern Migration
  -- ** OO: Factory class -> FP: Smart constructors
  , Document(..)
  , createPDF
  , createWord
  , createHTML
  , renderDocument
  
  -- * Singleton to Module
  -- ** OO: Singleton pattern -> FP: Module-level values
  , Config(..)
  , defaultConfig
  , testConfig
  , productionConfig
  
  -- * Null Object to Maybe
  -- ** OO: Null object pattern -> FP: Maybe
  , SimpleUser(..)
  , findUser
  , getUserName
  , getUserNameOrDefault
  
  -- * Template Method to Higher-Order Functions
  -- ** OO: Template method -> FP: HOF
  , DataProcessor
  , csvProcessor
  , jsonProcessor
  , xmlProcessor
  , processData
  
  -- * Chain of Responsibility to Function Composition
  -- ** OO: Chain of responsibility -> FP: Function chain
  , Request(..)
  , Handler
  , authHandler
  , loggingHandler
  , validationHandler
  , handleRequest
  , chainHandlers
  ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

-- ============================================================
-- Class to Data Type Migration
-- ============================================================

-- | OO: Animal class hierarchy -> FP: Sum types
data Animal
  = Dog { dogName :: String, dogBreed :: String }
  | Cat { catName :: String, catColor :: String }
  | Bird { birdName :: String, birdCanFly :: Bool }
  deriving (Show, Eq)

-- | Make sound (polymorphic behavior via pattern matching)
makeSound :: Animal -> String
makeSound (Dog name _) = name ++ " says: Woof!"
makeSound (Cat name _) = name ++ " says: Meow!"
makeSound (Bird name _) = name ++ " says: Tweet!"

-- | Move (polymorphic behavior)
move :: Animal -> String
move (Dog name _) = name ++ " runs on four legs"
move (Cat name _) = name ++ " prowls silently"
move (Bird name canFly)
  | canFly = name ++ " flies through the air"
  | otherwise = name ++ " hops on the ground"

-- | Describe animal
describeAnimal :: Animal -> String
describeAnimal animal = makeSound animal ++ " and " ++ move animal

-- | Shape type class (interface equivalent)
class Shape a where
  area :: a -> Double
  perimeter :: a -> Double

-- | Circle shape
data Circle = Circle { circleRadius :: Double }
  deriving (Show, Eq)

instance Shape Circle where
  area (Circle r) = pi * r * r
  perimeter (Circle r) = 2 * pi * r

-- | Rectangle shape
data Rectangle = Rectangle { rectWidth :: Double, rectHeight :: Double }
  deriving (Show, Eq)

instance Shape Rectangle where
  area (Rectangle w h) = w * h
  perimeter (Rectangle w h) = 2 * (w + h)

-- | Triangle shape
data Triangle = Triangle { triBase :: Double, triHeight :: Double, triSides :: (Double, Double, Double) }
  deriving (Show, Eq)

instance Shape Triangle where
  area (Triangle b h _) = 0.5 * b * h
  perimeter (Triangle _ _ (a, b, c)) = a + b + c

-- ============================================================
-- Inheritance to Composition
-- ============================================================

-- | Engine type (component)
data Engine
  = NoEngine
  | GasEngine { horsepower :: Int }
  | ElectricEngine { batteryKwh :: Int }
  deriving (Show, Eq)

-- | Wheels type (component)
data Wheels = Wheels { wheelCount :: Int, wheelSize :: Int }
  deriving (Show, Eq)

-- | Vehicle (composition over inheritance)
data Vehicle = Vehicle
  { vehicleName :: String
  , vehicleEngine :: Engine
  , vehicleWheels :: Wheels
  } deriving (Show, Eq)

-- | Create vehicle
makeVehicle :: String -> Engine -> Wheels -> Vehicle
makeVehicle = Vehicle

-- | Predefined car
car :: Vehicle
car = makeVehicle "Car" (GasEngine 200) (Wheels 4 17)

-- | Predefined motorcycle
motorcycle :: Vehicle
motorcycle = makeVehicle "Motorcycle" (GasEngine 80) (Wheels 2 18)

-- | Predefined bicycle
bicycle :: Vehicle
bicycle = makeVehicle "Bicycle" NoEngine (Wheels 2 26)

-- | Describe vehicle
describeVehicle :: Vehicle -> String
describeVehicle v = vehicleName v ++ " with " ++ engineDesc ++ " and " ++ wheelsDesc
  where
    engineDesc = case vehicleEngine v of
      NoEngine -> "no engine"
      GasEngine hp -> show hp ++ "hp gas engine"
      ElectricEngine kw -> show kw ++ "kWh electric engine"
    wheelsDesc = show (wheelCount (vehicleWheels v)) ++ " wheels"

-- ============================================================
-- Mutable State to Immutable Updates
-- ============================================================

-- | Bank account (immutable)
data BankAccount = BankAccount
  { accountId :: String
  , accountBalance :: Double
  , accountOwner :: String
  } deriving (Show, Eq)

-- | Create account
makeAccount :: String -> String -> Double -> BankAccount
makeAccount aid owner initial = BankAccount aid initial owner

-- | Deposit (returns new account)
deposit :: Double -> BankAccount -> BankAccount
deposit amount account
  | amount > 0 = account { accountBalance = accountBalance account + amount }
  | otherwise = account

-- | Withdraw (returns new account or Nothing if insufficient)
withdraw :: Double -> BankAccount -> Maybe BankAccount
withdraw amount account
  | amount > 0 && accountBalance account >= amount =
      Just account { accountBalance = accountBalance account - amount }
  | otherwise = Nothing

-- | Transfer between accounts
transfer :: Double -> BankAccount -> BankAccount -> Maybe (BankAccount, BankAccount)
transfer amount from to = do
  from' <- withdraw amount from
  let to' = deposit amount to
  return (from', to')

-- | Get balance
getBalance :: BankAccount -> Double
getBalance = accountBalance

-- ============================================================
-- Strategy Pattern Migration
-- ============================================================

-- | Payment method (strategy as function)
type PaymentMethod = Double -> String -> Either String String

-- | Credit card payment
creditCard :: String -> PaymentMethod
creditCard cardNumber amount merchant =
  Right $ "Paid $" ++ show amount ++ " to " ++ merchant ++ " via credit card " ++ take 4 cardNumber ++ "****"

-- | Debit card payment
debitCard :: String -> PaymentMethod
debitCard cardNumber amount merchant =
  Right $ "Paid $" ++ show amount ++ " to " ++ merchant ++ " via debit card " ++ take 4 cardNumber ++ "****"

-- | PayPal payment
paypal :: String -> PaymentMethod
paypal email amount merchant =
  Right $ "Paid $" ++ show amount ++ " to " ++ merchant ++ " via PayPal (" ++ email ++ ")"

-- | Bitcoin payment
bitcoin :: String -> PaymentMethod
bitcoin wallet amount merchant =
  Right $ "Paid $" ++ show amount ++ " to " ++ merchant ++ " via Bitcoin wallet " ++ take 8 wallet ++ "..."

-- | Process payment using strategy
processPayment :: PaymentMethod -> Double -> String -> Either String String
processPayment method amount merchant = method amount merchant

-- ============================================================
-- Observer Pattern Migration
-- ============================================================

-- | Event type
data Event
  = UserCreated String
  | UserDeleted String
  | OrderPlaced String Double
  | OrderCancelled String
  deriving (Show, Eq)

-- | Subscription function
type Subscription = Event -> String

-- | Subscribe to events (returns notification function)
subscribe :: String -> Subscription
subscribe subscriberName event = case event of
  UserCreated user -> subscriberName ++ " notified: User " ++ user ++ " created"
  UserDeleted user -> subscriberName ++ " notified: User " ++ user ++ " deleted"
  OrderPlaced orderId amount -> subscriberName ++ " notified: Order " ++ orderId ++ " placed for $" ++ show amount
  OrderCancelled orderId -> subscriberName ++ " notified: Order " ++ orderId ++ " cancelled"

-- | Publish event to all subscribers
publish :: [Subscription] -> Event -> [String]
publish subscribers event = map ($ event) subscribers

-- | Event log type
type EventLog = [Event]

-- | Log event (pure function)
logEvent :: Event -> EventLog -> EventLog
logEvent event log' = event : log'

-- ============================================================
-- Factory Pattern Migration
-- ============================================================

-- | Document type
data Document
  = PDFDocument String
  | WordDocument String
  | HTMLDocument String
  deriving (Show, Eq)

-- | Create PDF (smart constructor)
createPDF :: String -> Document
createPDF = PDFDocument

-- | Create Word document (smart constructor)
createWord :: String -> Document
createWord = WordDocument

-- | Create HTML document (smart constructor)
createHTML :: String -> Document
createHTML = HTMLDocument

-- | Render document
renderDocument :: Document -> String
renderDocument (PDFDocument content) = "<PDF>" ++ content ++ "</PDF>"
renderDocument (WordDocument content) = "<WORD>" ++ content ++ "</WORD>"
renderDocument (HTMLDocument content) = "<html><body>" ++ content ++ "</body></html>"

-- ============================================================
-- Singleton to Module
-- ============================================================

-- | Configuration type
data Config = Config
  { configDbHost :: String
  , configDbPort :: Int
  , configLogLevel :: String
  } deriving (Show, Eq)

-- | Default configuration
defaultConfig :: Config
defaultConfig = Config "localhost" 5432 "INFO"

-- | Test configuration
testConfig :: Config
testConfig = Config "localhost" 5433 "DEBUG"

-- | Production configuration
productionConfig :: Config
productionConfig = Config "prod.db.example.com" 5432 "WARN"

-- ============================================================
-- Null Object to Maybe
-- ============================================================

-- | Simple user type for examples
data SimpleUser = SimpleUser { simpleUserName :: String, simpleUserEmail :: String }
  deriving (Show, Eq)

-- | User database (simulation)
userDatabase :: Map String SimpleUser
userDatabase = Map.fromList
  [ ("1", SimpleUser "Alice" "alice@example.com")
  , ("2", SimpleUser "Bob" "bob@example.com")
  ]

-- | Find user (returns Maybe instead of null)
findUser :: String -> Maybe SimpleUser
findUser userId = Map.lookup userId userDatabase

-- | Get user name (safe navigation with Maybe)
getUserName :: String -> Maybe String
getUserName userId = simpleUserName <$> findUser userId

-- | Get user name or default
getUserNameOrDefault :: String -> String -> String
getUserNameOrDefault userId defaultName =
  maybe defaultName simpleUserName (findUser userId)

-- ============================================================
-- Template Method to Higher-Order Functions
-- ============================================================

-- | Data processor (HOF instead of template method)
type DataProcessor = String -> String

-- | CSV processor
csvProcessor :: DataProcessor
csvProcessor input = "CSV[" ++ input ++ "]"

-- | JSON processor
jsonProcessor :: DataProcessor
jsonProcessor input = "{\"data\": \"" ++ input ++ "\"}"

-- | XML processor
xmlProcessor :: DataProcessor
xmlProcessor input = "<data>" ++ input ++ "</data>"

-- | Process data with given processor (template method equivalent)
processData :: DataProcessor -> String -> String
processData processor input =
  let validated = "validated:" ++ input
      transformed = processor validated
      output = "output:" ++ transformed
  in output

-- ============================================================
-- Chain of Responsibility to Function Composition
-- ============================================================

-- | Request type
data Request = Request
  { reqPath :: String
  , reqMethod :: String
  , reqHeaders :: Map String String
  , reqBody :: String
  } deriving (Show, Eq)

-- | Handler function
type Handler = Request -> Either String Request

-- | Authentication handler
authHandler :: Handler
authHandler req =
  case Map.lookup "Authorization" (reqHeaders req) of
    Nothing -> Left "Unauthorized: No auth header"
    Just _ -> Right req

-- | Logging handler
loggingHandler :: Handler
loggingHandler req = Right req  -- In real code, would log request

-- | Validation handler
validationHandler :: Handler
validationHandler req
  | null (reqBody req) && reqMethod req == "POST" = Left "Bad Request: Empty body"
  | otherwise = Right req

-- | Handle request with single handler
handleRequest :: Handler -> Request -> Either String Request
handleRequest = ($)

-- | Chain handlers together
chainHandlers :: [Handler] -> Handler
chainHandlers [] req = Right req
chainHandlers (h:hs) req = case h req of
  Left err -> Left err
  Right req' -> chainHandlers hs req'
