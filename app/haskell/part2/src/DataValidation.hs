{-|
Module      : DataValidation
Description : Chapter 4 - Data Validation
Copyright   : (c) k2works, 2025
License     : MIT

This module demonstrates data validation patterns in Haskell:
- Result type for validation
- Validated type for error accumulation
- Smart constructors
- Domain primitives
- Applicative validation
-}
module DataValidation
    ( -- * Validation Result Types
      ValidationError(..)
    , ValidationResult
    , Validated(..)
      -- * Basic Validators
    , validateNonEmpty
    , validateMinLength
    , validateMaxLength
    , validateRange
    , validateEmail
    , validatePostalCode
      -- * Domain Types
    , Name(..)
    , mkName
    , Age(..)
    , mkAge
    , Email(..)
    , mkEmail
    , PostalCode(..)
    , mkPostalCode
      -- * Membership
    , Membership(..)
    , parseMembership
    , membershipToString
      -- * Status
    , Status(..)
    , parseStatus
      -- * Person Validation
    , Person(..)
    , validatePerson
    , PersonInput(..)
      -- * Address Validation
    , Address(..)
    , AddressInput(..)
    , validateAddress
      -- * Product Validation
    , ProductId(..)
    , mkProductId
    , Product(..)
    , ProductInput(..)
    , validateProduct
      -- * Order Validation
    , OrderItem(..)
    , OrderItemInput(..)
    , validateOrderItem
    , Order(..)
    , OrderInput(..)
    , validateOrder
      -- * Validated Applicative
    , valid
    , invalid
    , fromResult
    , toResult
    , (<*?>)
    , validateAllV
    ) where

import Data.Char (isDigit, isAlphaNum)
import Data.List (intercalate)

-- ============================================================
-- 1. Validation Result Types
-- ============================================================

-- | Validation error type
data ValidationError
    = EmptyValue String
    | TooShort String Int Int  -- field, actual, minimum
    | TooLong String Int Int   -- field, actual, maximum
    | OutOfRange String Int Int Int  -- field, actual, min, max
    | InvalidFormat String String  -- field, value
    | InvalidValue String String   -- field, reason
    | MissingField String
    | MultipleErrors [ValidationError]
    deriving (Eq)

instance Show ValidationError where
    show (EmptyValue field) = field ++ " cannot be empty"
    show (TooShort field actual minLen) = 
        field ++ " is too short (" ++ show actual ++ " < " ++ show minLen ++ ")"
    show (TooLong field actual maxLen) = 
        field ++ " is too long (" ++ show actual ++ " > " ++ show maxLen ++ ")"
    show (OutOfRange field actual minVal maxVal) = 
        field ++ " out of range: " ++ show actual ++ " (must be " ++ show minVal ++ "-" ++ show maxVal ++ ")"
    show (InvalidFormat field value) = 
        "Invalid " ++ field ++ " format: " ++ value
    show (InvalidValue field reason) = 
        "Invalid " ++ field ++ ": " ++ reason
    show (MissingField field) = 
        "Missing required field: " ++ field
    show (MultipleErrors errors) = 
        intercalate "; " (map show errors)

-- | Validation result type (fails fast)
type ValidationResult a = Either ValidationError a

-- | Validated type for error accumulation
data Validated a
    = Valid a
    | Invalid [ValidationError]
    deriving (Show, Eq)

instance Functor Validated where
    fmap f (Valid a) = Valid (f a)
    fmap _ (Invalid es) = Invalid es

instance Applicative Validated where
    pure = Valid
    Valid f <*> Valid a = Valid (f a)
    Invalid es1 <*> Invalid es2 = Invalid (es1 ++ es2)
    Invalid es <*> _ = Invalid es
    _ <*> Invalid es = Invalid es

-- ============================================================
-- 2. Basic Validators
-- ============================================================

-- | Validate non-empty string
validateNonEmpty :: String -> String -> ValidationResult String
validateNonEmpty field value
    | null value = Left (EmptyValue field)
    | otherwise = Right value

-- | Validate minimum length
validateMinLength :: String -> Int -> String -> ValidationResult String
validateMinLength field minLen value
    | length value < minLen = Left (TooShort field (length value) minLen)
    | otherwise = Right value

-- | Validate maximum length
validateMaxLength :: String -> Int -> String -> ValidationResult String
validateMaxLength field maxLen value
    | length value > maxLen = Left (TooLong field (length value) maxLen)
    | otherwise = Right value

-- | Validate numeric range
validateRange :: String -> Int -> Int -> Int -> ValidationResult Int
validateRange field minVal maxVal value
    | value < minVal || value > maxVal = Left (OutOfRange field value minVal maxVal)
    | otherwise = Right value

-- | Validate email format
validateEmail :: String -> ValidationResult String
validateEmail value
    | '@' `elem` value && '.' `elem` value = Right value
    | otherwise = Left (InvalidFormat "email" value)

-- | Validate Japanese postal code format (XXX-XXXX)
validatePostalCode :: String -> ValidationResult String
validatePostalCode value
    | length value == 8 && 
      all isDigit (take 3 value) && 
      value !! 3 == '-' && 
      all isDigit (drop 4 value) = Right value
    | otherwise = Left (InvalidFormat "postal code" value)

-- ============================================================
-- 3. Domain Primitives (Smart Constructors)
-- ============================================================

-- | Name domain type
newtype Name = Name { unName :: String }
    deriving (Show, Eq)

-- | Smart constructor for Name
mkName :: String -> ValidationResult Name
mkName value = do
    _ <- validateNonEmpty "name" value
    _ <- validateMaxLength "name" 100 value
    Right (Name value)

-- | Age domain type
newtype Age = Age { unAge :: Int }
    deriving (Show, Eq)

-- | Smart constructor for Age
mkAge :: Int -> ValidationResult Age
mkAge value = do
    _ <- validateRange "age" 0 150 value
    Right (Age value)

-- | Email domain type
newtype Email = Email { unEmail :: String }
    deriving (Show, Eq)

-- | Smart constructor for Email
mkEmail :: String -> ValidationResult Email
mkEmail value = do
    _ <- validateNonEmpty "email" value
    _ <- validateEmail value
    Right (Email value)

-- | Postal code domain type
newtype PostalCode = PostalCode { unPostalCode :: String }
    deriving (Show, Eq)

-- | Smart constructor for PostalCode
mkPostalCode :: String -> ValidationResult PostalCode
mkPostalCode value = do
    _ <- validatePostalCode value
    Right (PostalCode value)

-- ============================================================
-- 4. Membership and Status (Enums)
-- ============================================================

-- | Membership levels
data Membership = Bronze | Silver | Gold | Platinum
    deriving (Show, Eq, Ord, Enum, Bounded)

-- | Parse membership from string
parseMembership :: String -> ValidationResult Membership
parseMembership s = case map toLowerChar s of
    "bronze" -> Right Bronze
    "silver" -> Right Silver
    "gold" -> Right Gold
    "platinum" -> Right Platinum
    _ -> Left (InvalidValue "membership" ("unknown value: " ++ s))
  where
    toLowerChar c
        | c >= 'A' && c <= 'Z' = toEnum (fromEnum c + 32)
        | otherwise = c

-- | Convert membership to string
membershipToString :: Membership -> String
membershipToString Bronze = "bronze"
membershipToString Silver = "silver"
membershipToString Gold = "gold"
membershipToString Platinum = "platinum"

-- | Status types
data Status = Active | Inactive | Suspended
    deriving (Show, Eq, Ord, Enum, Bounded)

-- | Parse status from string
parseStatus :: String -> ValidationResult Status
parseStatus s = case map toLowerChar s of
    "active" -> Right Active
    "inactive" -> Right Inactive
    "suspended" -> Right Suspended
    _ -> Left (InvalidValue "status" ("unknown value: " ++ s))
  where
    toLowerChar c
        | c >= 'A' && c <= 'Z' = toEnum (fromEnum c + 32)
        | otherwise = c

-- ============================================================
-- 5. Person Validation
-- ============================================================

-- | Person record
data Person = Person
    { personName :: Name
    , personAge  :: Age
    , personEmail :: Maybe Email
    , personMembership :: Maybe Membership
    } deriving (Show, Eq)

-- | Raw input for person validation
data PersonInput = PersonInput
    { inputName :: String
    , inputAge :: Int
    , inputEmail :: Maybe String
    , inputMembership :: Maybe String
    } deriving (Show, Eq)

-- | Validate person input
validatePerson :: PersonInput -> ValidationResult Person
validatePerson input = do
    name <- mkName (inputName input)
    age <- mkAge (inputAge input)
    email <- case inputEmail input of
        Nothing -> Right Nothing
        Just e -> fmap Just (mkEmail e)
    membership <- case inputMembership input of
        Nothing -> Right Nothing
        Just m -> fmap Just (parseMembership m)
    Right Person
        { personName = name
        , personAge = age
        , personEmail = email
        , personMembership = membership
        }

-- ============================================================
-- 6. Address Validation
-- ============================================================

-- | Address record
data Address = Address
    { addressStreet :: String
    , addressCity :: String
    , addressPostalCode :: PostalCode
    } deriving (Show, Eq)

-- | Raw input for address validation
data AddressInput = AddressInput
    { inputStreet :: String
    , inputCity :: String
    , inputPostalCode :: String
    } deriving (Show, Eq)

-- | Validate address input
validateAddress :: AddressInput -> ValidationResult Address
validateAddress input = do
    street <- validateNonEmpty "street" (inputStreet input)
    city <- validateNonEmpty "city" (inputCity input)
    postalCode <- mkPostalCode (inputPostalCode input)
    Right Address
        { addressStreet = street
        , addressCity = city
        , addressPostalCode = postalCode
        }

-- ============================================================
-- 7. Product Validation
-- ============================================================

-- | Product ID (PROD-XXXXX format)
newtype ProductId = ProductId { unProductId :: String }
    deriving (Show, Eq)

-- | Smart constructor for ProductId
mkProductId :: String -> ValidationResult ProductId
mkProductId value
    | length value == 10 &&
      take 5 value == "PROD-" &&
      all isDigit (drop 5 value) = Right (ProductId value)
    | otherwise = Left (InvalidFormat "product ID" value)

-- | Product record
data Product = Product
    { productId :: ProductId
    , productName :: String
    , productPrice :: Int
    } deriving (Show, Eq)

-- | Raw input for product validation
data ProductInput = ProductInput
    { inputProductId :: String
    , inputProductName :: String
    , inputProductPrice :: Int
    } deriving (Show, Eq)

-- | Validate product input
validateProduct :: ProductInput -> ValidationResult Product
validateProduct input = do
    pid <- mkProductId (inputProductId input)
    name <- validateNonEmpty "product name" (inputProductName input)
    _ <- validateMaxLength "product name" 200 name
    if inputProductPrice input <= 0
        then Left (InvalidValue "price" "must be positive")
        else Right Product
            { productId = pid
            , productName = name
            , productPrice = inputProductPrice input
            }

-- ============================================================
-- 8. Order Validation
-- ============================================================

-- | Order item
data OrderItem = OrderItem
    { orderItemProduct :: Product
    , orderItemQuantity :: Int
    } deriving (Show, Eq)

-- | Raw input for order item
data OrderItemInput = OrderItemInput
    { inputOrderProduct :: ProductInput
    , inputOrderQuantity :: Int
    } deriving (Show, Eq)

-- | Validate order item
validateOrderItem :: OrderItemInput -> ValidationResult OrderItem
validateOrderItem input = do
    product <- validateProduct (inputOrderProduct input)
    if inputOrderQuantity input <= 0
        then Left (InvalidValue "quantity" "must be positive")
        else Right OrderItem
            { orderItemProduct = product
            , orderItemQuantity = inputOrderQuantity input
            }

-- | Order record
data Order = Order
    { orderItems :: [OrderItem]
    , orderCustomer :: Person
    } deriving (Show, Eq)

-- | Raw input for order
data OrderInput = OrderInput
    { inputOrderItems :: [OrderItemInput]
    , inputOrderCustomer :: PersonInput
    } deriving (Show, Eq)

-- | Validate order
validateOrder :: OrderInput -> ValidationResult Order
validateOrder input = do
    items <- mapM validateOrderItem (inputOrderItems input)
    if null items
        then Left (EmptyValue "order items")
        else do
            customer <- validatePerson (inputOrderCustomer input)
            Right Order
                { orderItems = items
                , orderCustomer = customer
                }

-- ============================================================
-- 9. Validated Applicative Functions
-- ============================================================

-- | Create valid value
valid :: a -> Validated a
valid = Valid

-- | Create invalid value with single error
invalid :: ValidationError -> Validated a
invalid e = Invalid [e]

-- | Convert Result to Validated
fromResult :: ValidationResult a -> Validated a
fromResult (Right a) = Valid a
fromResult (Left e) = Invalid [e]

-- | Convert Validated to Result
toResult :: Validated a -> ValidationResult a
toResult (Valid a) = Right a
toResult (Invalid []) = Left (InvalidValue "unknown" "no errors but invalid")
toResult (Invalid [e]) = Left e
toResult (Invalid es) = Left (MultipleErrors es)

-- | Applicative apply for Validated (infix operator)
(<*?>) :: Validated (a -> b) -> Validated a -> Validated b
(<*?>) = (<*>)

-- | Validate all with error accumulation
validateAllV :: [Validated a] -> Validated [a]
validateAllV = foldr combine (Valid [])
  where
    combine (Valid a) (Valid as) = Valid (a:as)
    combine (Invalid es1) (Invalid es2) = Invalid (es1 ++ es2)
    combine (Invalid es) _ = Invalid es
    combine _ (Invalid es) = Invalid es
