{-|
Module      : Polymorphism
Description : Chapter 3 - Polymorphism and Dispatch
Copyright   : (c) k2works, 2025
License     : MIT

This module demonstrates polymorphism concepts in Haskell:
- Algebraic Data Types (ADT) with pattern matching
- Type classes for ad-hoc polymorphism
- Composite dispatch (multiple values)
- Hierarchical dispatch
- Extensible systems
-}
module Polymorphism
    ( -- * Shapes with ADT
      Shape(..)
    , calculateArea
    , calculatePerimeter
      -- * Payment Processing (Composite Dispatch)
    , PaymentMethod(..)
    , Currency(..)
    , Payment(..)
    , PaymentResult(..)
    , processPayment
      -- * Account Types (Hierarchical Dispatch)
    , AccountType(..)
    , Account(..)
    , getInterestRate
    , calculateInterest
      -- * Type Classes
    , Drawable(..)
    , Transformable(..)
    , Point(..)
    , Rectangle(..)
    , Circle(..)
    , DrawableShape(..)
      -- * Expression Problem (Extensible)
    , Expr(..)
    , eval
    , prettyPrint
      -- * Notification System
    , NotificationChannel(..)
    , NotificationPriority(..)
    , Notification(..)
    , NotificationResponse(..)
    , sendNotification
      -- * Animal Sounds (Classic Polymorphism Example)
    , Animal(..)
    , speak
    , move
    ) where

-- ============================================================
-- 1. Algebraic Data Types (ADT) - Shape Example
-- ============================================================

-- | Shape represented as an ADT
data Shape
    = Rectangle' { rectWidth :: Double, rectHeight :: Double }
    | Circle' { circleRadius :: Double }
    | Triangle' { triBase :: Double, triHeight :: Double }
    | Square' { squareSide :: Double }
    deriving (Show, Eq)

-- | Calculate the area of a shape (pattern matching)
calculateArea :: Shape -> Double
calculateArea shape = case shape of
    Rectangle' w h -> w * h
    Circle' r      -> pi * r * r
    Triangle' b h  -> b * h / 2
    Square' s      -> s * s

-- | Calculate the perimeter of a shape
calculatePerimeter :: Shape -> Double
calculatePerimeter shape = case shape of
    Rectangle' w h -> 2 * (w + h)
    Circle' r      -> 2 * pi * r
    Triangle' b h  -> b + 2 * sqrt ((b/2)^2 + h^2)  -- isoceles approximation
    Square' s      -> 4 * s

-- ============================================================
-- 2. Composite Dispatch (Multiple Values)
-- ============================================================

-- | Payment method
data PaymentMethod
    = CreditCard
    | BankTransfer
    | Cash
    | Cryptocurrency
    deriving (Show, Eq)

-- | Currency types
data Currency
    = JPY
    | USD
    | EUR
    deriving (Show, Eq)

-- | Payment information
data Payment = Payment
    { paymentMethod   :: PaymentMethod
    , paymentCurrency :: Currency
    , paymentAmount   :: Int
    } deriving (Show, Eq)

-- | Payment result
data PaymentResult = PaymentResult
    { resultStatus    :: String
    , resultMessage   :: String
    , resultAmount    :: Int
    , resultConverted :: Maybe Int
    } deriving (Show, Eq)

-- | Process payment with composite dispatch (method + currency)
processPayment :: Payment -> PaymentResult
processPayment payment = case (paymentMethod payment, paymentCurrency payment) of
    (CreditCard, JPY) -> PaymentResult
        { resultStatus = "processed"
        , resultMessage = "クレジットカード（円）で処理しました"
        , resultAmount = paymentAmount payment
        , resultConverted = Nothing
        }
    (CreditCard, USD) -> PaymentResult
        { resultStatus = "processed"
        , resultMessage = "Credit card (USD) processed"
        , resultAmount = paymentAmount payment
        , resultConverted = Just (paymentAmount payment * 150)
        }
    (BankTransfer, JPY) -> PaymentResult
        { resultStatus = "pending"
        , resultMessage = "銀行振込を受け付けました"
        , resultAmount = paymentAmount payment
        , resultConverted = Nothing
        }
    (Cash, _) -> PaymentResult
        { resultStatus = "processed"
        , resultMessage = "現金で処理しました"
        , resultAmount = paymentAmount payment
        , resultConverted = Nothing
        }
    _ -> PaymentResult
        { resultStatus = "error"
        , resultMessage = "サポートされていない支払い方法です"
        , resultAmount = paymentAmount payment
        , resultConverted = Nothing
        }

-- ============================================================
-- 3. Hierarchical Dispatch (Account Types)
-- ============================================================

-- | Account type hierarchy (simulated with ADT)
data AccountType
    = Savings
    | PremiumSavings  -- "inherits" from Savings
    | Checking
    deriving (Show, Eq)

-- | Account data
data Account = Account
    { accountType    :: AccountType
    , accountBalance :: Int
    } deriving (Show, Eq)

-- | Get interest rate based on account type
getInterestRate :: AccountType -> Double
getInterestRate Savings        = 0.02
getInterestRate PremiumSavings = 0.05
getInterestRate Checking       = 0.001

-- | Calculate interest for an account
calculateInterest :: Account -> Double
calculateInterest account =
    fromIntegral (accountBalance account) * getInterestRate (accountType account)

-- ============================================================
-- 4. Type Classes (Ad-hoc Polymorphism)
-- ============================================================

-- | 2D Point
data Point = Point
    { pointX :: Double
    , pointY :: Double
    } deriving (Show, Eq)

-- | Drawable type class
class Drawable a where
    draw :: a -> String
    boundingBox :: a -> (Point, Point)  -- (min, max)

-- | Transformable type class
class Transformable a where
    translate :: Double -> Double -> a -> a
    scale :: Double -> a -> a

-- | Rectangle for type class examples
data Rectangle = Rectangle
    { rectangleX      :: Double
    , rectangleY      :: Double
    , rectangleWidth  :: Double
    , rectangleHeight :: Double
    } deriving (Show, Eq)

-- | Circle for type class examples
data Circle = Circle
    { circleCenterX :: Double
    , circleCenterY :: Double
    , circleR       :: Double
    } deriving (Show, Eq)

instance Drawable Rectangle where
    draw r = "Rectangle at (" ++ show (rectangleX r) ++ ", " ++ show (rectangleY r) ++ 
             ") with size " ++ show (rectangleWidth r) ++ "x" ++ show (rectangleHeight r)
    boundingBox r = 
        ( Point (rectangleX r) (rectangleY r)
        , Point (rectangleX r + rectangleWidth r) (rectangleY r + rectangleHeight r)
        )

instance Drawable Circle where
    draw c = "Circle at (" ++ show (circleCenterX c) ++ ", " ++ show (circleCenterY c) ++ 
             ") with radius " ++ show (circleR c)
    boundingBox c =
        ( Point (circleCenterX c - circleR c) (circleCenterY c - circleR c)
        , Point (circleCenterX c + circleR c) (circleCenterY c + circleR c)
        )

instance Transformable Rectangle where
    translate dx dy r = r { rectangleX = rectangleX r + dx, rectangleY = rectangleY r + dy }
    scale factor r = r { rectangleWidth = rectangleWidth r * factor, rectangleHeight = rectangleHeight r * factor }

instance Transformable Circle where
    translate dx dy c = c { circleCenterX = circleCenterX c + dx, circleCenterY = circleCenterY c + dy }
    scale factor c = c { circleR = circleR c * factor }

-- | Wrapper for heterogeneous collections of drawable shapes
data DrawableShape
    = DrawableRect Rectangle
    | DrawableCircle Circle
    deriving (Show, Eq)

instance Drawable DrawableShape where
    draw (DrawableRect r) = draw r
    draw (DrawableCircle c) = draw c
    boundingBox (DrawableRect r) = boundingBox r
    boundingBox (DrawableCircle c) = boundingBox c

-- ============================================================
-- 5. Expression Problem (Extensible Data + Operations)
-- ============================================================

-- | Simple expression language
data Expr
    = Lit Int
    | Add Expr Expr
    | Mul Expr Expr
    | Neg Expr
    deriving (Show, Eq)

-- | Evaluate an expression
eval :: Expr -> Int
eval expr = case expr of
    Lit n     -> n
    Add e1 e2 -> eval e1 + eval e2
    Mul e1 e2 -> eval e1 * eval e2
    Neg e     -> negate (eval e)

-- | Pretty print an expression
prettyPrint :: Expr -> String
prettyPrint expr = case expr of
    Lit n     -> show n
    Add e1 e2 -> "(" ++ prettyPrint e1 ++ " + " ++ prettyPrint e2 ++ ")"
    Mul e1 e2 -> "(" ++ prettyPrint e1 ++ " * " ++ prettyPrint e2 ++ ")"
    Neg e     -> "(-" ++ prettyPrint e ++ ")"

-- ============================================================
-- 6. Notification System (Complex Composite Dispatch)
-- ============================================================

-- | Notification channel
data NotificationChannel
    = Email
    | SMS
    | Push
    | Slack
    deriving (Show, Eq)

-- | Notification priority
data NotificationPriority
    = Low
    | Normal
    | High
    | Urgent
    deriving (Show, Eq)

-- | Notification data
data Notification = Notification
    { notificationChannel  :: NotificationChannel
    , notificationPriority :: NotificationPriority
    , notificationMessage  :: String
    } deriving (Show, Eq)

-- | Notification response
data NotificationResponse = NotificationResponse
    { responseSuccess :: Bool
    , responseChannel :: String
    , responseDetails :: String
    } deriving (Show, Eq)

-- | Send notification with dispatch on channel and priority
sendNotification :: Notification -> NotificationResponse
sendNotification notif = case (notificationChannel notif, notificationPriority notif) of
    (Email, Urgent) -> NotificationResponse True "email" "Sent urgent email immediately"
    (Email, _)      -> NotificationResponse True "email" "Email queued for delivery"
    (SMS, Urgent)   -> NotificationResponse True "sms" "SMS sent with high priority"
    (SMS, High)     -> NotificationResponse True "sms" "SMS sent"
    (SMS, _)        -> NotificationResponse False "sms" "SMS only for high priority"
    (Push, _)       -> NotificationResponse True "push" "Push notification sent"
    (Slack, Urgent) -> NotificationResponse True "slack" "Slack message with @channel"
    (Slack, _)      -> NotificationResponse True "slack" "Slack message sent"

-- ============================================================
-- 7. Animal Sounds (Classic Polymorphism Example)
-- ============================================================

-- | Animal types
data Animal
    = Dog { dogName :: String }
    | Cat { catName :: String }
    | Bird { birdName :: String, birdCanFly :: Bool }
    deriving (Show, Eq)

-- | Make an animal speak
speak :: Animal -> String
speak animal = case animal of
    Dog name   -> name ++ " says: Woof!"
    Cat name   -> name ++ " says: Meow!"
    Bird name _ -> name ++ " says: Tweet!"

-- | Describe how an animal moves
move :: Animal -> String
move animal = case animal of
    Dog name      -> name ++ " runs on four legs"
    Cat name      -> name ++ " prowls silently"
    Bird name True -> name ++ " flies through the air"
    Bird name False -> name ++ " hops on the ground"
