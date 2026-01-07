{-|
Module      : Immutability
Description : Chapter 1 - Immutability and Data Transformation
Copyright   : (c) k2works, 2025
License     : MIT

This module demonstrates immutability concepts in Haskell:
- Immutable data structures
- Structural sharing
- Data transformation pipelines
- Side effect separation
- History management (Undo/Redo)
-}
module Immutability
    ( -- * Basic Data Types
      Person(..)
    , updateAge
      -- * Team Management
    , Member(..)
    , Role(..)
    , Team(..)
    , addMember
      -- * Order Processing
    , Item(..)
    , Membership(..)
    , Customer(..)
    , Order(..)
    , calculateSubtotal
    , membershipDiscount
    , calculateTotal
    , applyDiscount
    , processOrder
      -- * Invoice Processing
    , Invoice(..)
    , calculateInvoice
      -- * History Management
    , History(..)
    , createHistory
    , pushState
    , undo
    , redo
    , currentState
    , canUndo
    , canRedo
    ) where

-- | Person record demonstrating basic immutability
data Person = Person
    { personName :: String
    , personAge  :: Int
    } deriving (Show, Eq)

-- | Update a person's age, returning a new Person (original unchanged)
updateAge :: Person -> Int -> Person
updateAge person newAge = person { personAge = newAge }

-- | Member roles in a team
data Role = Developer | Designer | Manager
    deriving (Show, Eq)

-- | Team member
data Member = Member
    { memberName :: String
    , memberRole :: Role
    } deriving (Show, Eq)

-- | Team with structural sharing
data Team = Team
    { teamName    :: String
    , teamMembers :: [Member]
    } deriving (Show, Eq)

-- | Add a member to a team (structural sharing - existing members are shared)
addMember :: Team -> Member -> Team
addMember team newMember = team { teamMembers = teamMembers team ++ [newMember] }

-- | Order item
data Item = Item
    { itemName     :: String
    , itemPrice    :: Int
    , itemQuantity :: Int
    } deriving (Show, Eq)

-- | Membership levels for customers
data Membership = Gold | Silver | Bronze | Regular
    deriving (Show, Eq)

-- | Customer information
data Customer = Customer
    { customerName       :: String
    , customerMembership :: Membership
    } deriving (Show, Eq)

-- | Order with items and customer
data Order = Order
    { orderItems    :: [Item]
    , orderCustomer :: Customer
    } deriving (Show, Eq)

-- | Calculate subtotal for a single item
calculateSubtotal :: Item -> Int
calculateSubtotal item = itemPrice item * itemQuantity item

-- | Get discount rate based on membership level
membershipDiscount :: Membership -> Double
membershipDiscount Gold   = 0.1
membershipDiscount Silver = 0.05
membershipDiscount Bronze = 0.02
membershipDiscount Regular = 0.0

-- | Calculate total for an order (before discount)
calculateTotal :: Order -> Int
calculateTotal order = sum $ map calculateSubtotal (orderItems order)

-- | Apply membership discount to total
applyDiscount :: Order -> Int -> Double
applyDiscount order total =
    let discountRate = membershipDiscount (customerMembership (orderCustomer order))
    in fromIntegral total * (1 - discountRate)

-- | Process order: calculate total with discount applied
processOrder :: Order -> Double
processOrder order =
    let total = calculateTotal order
    in applyDiscount order total

-- | Invoice data
data Invoice = Invoice
    { invoiceSubtotal :: Int
    , invoiceTax      :: Double
    , invoiceTotal    :: Double
    } deriving (Show, Eq)

-- | Calculate invoice from items and tax rate (pure function)
calculateInvoice :: [Item] -> Double -> Invoice
calculateInvoice items taxRate =
    let subtotal = sum $ map calculateSubtotal items
        tax = fromIntegral subtotal * taxRate
        total = fromIntegral subtotal + tax
    in Invoice subtotal tax total

-- | History state for undo/redo functionality
data History a = History
    { historyCurrent :: Maybe a
    , historyPast    :: [a]
    , historyFuture  :: [a]
    } deriving (Show, Eq)

-- | Create empty history
createHistory :: History a
createHistory = History Nothing [] []

-- | Push a new state onto history
pushState :: History a -> a -> History a
pushState history newState =
    History
        { historyCurrent = Just newState
        , historyPast = case historyCurrent history of
            Nothing -> historyPast history
            Just current -> current : historyPast history
        , historyFuture = []
        }

-- | Undo to previous state
undo :: History a -> History a
undo history = case historyPast history of
    [] -> history
    (prev:rest) -> History
        { historyCurrent = Just prev
        , historyPast = rest
        , historyFuture = case historyCurrent history of
            Nothing -> historyFuture history
            Just current -> current : historyFuture history
        }

-- | Redo to next state
redo :: History a -> History a
redo history = case historyFuture history of
    [] -> history
    (next:rest) -> History
        { historyCurrent = Just next
        , historyPast = case historyCurrent history of
            Nothing -> historyPast history
            Just current -> current : historyPast history
        , historyFuture = rest
        }

-- | Get current state from history
currentState :: History a -> Maybe a
currentState = historyCurrent

-- | Check if undo is possible
canUndo :: History a -> Bool
canUndo history = not $ null $ historyPast history

-- | Check if redo is possible
canRedo :: History a -> Bool
canRedo history = not $ null $ historyFuture history
