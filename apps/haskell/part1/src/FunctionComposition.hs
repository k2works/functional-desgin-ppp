{-|
Module      : FunctionComposition
Description : Chapter 2 - Function Composition and Higher-Order Functions
Copyright   : (c) k2works, 2025
License     : MIT

This module demonstrates function composition concepts in Haskell:
- Function composition with (.) and (>>>)
- Partial application (currying)
- Higher-order functions
- Parallel function application (juxt)
- Function wrappers (logging, retry, memoization)
-}
module FunctionComposition
    ( -- * Basic Composition
      addTax
    , applyDiscountRate
    , roundToYen
    , calculateFinalPrice
    , calculateFinalPriceCompose
      -- * Partial Application
    , greet
    , sayHello
    , sayGoodbye
    , Email(..)
    , sendEmail
    , sendFromSystem
    , sendNotification
      -- * Parallel Function Application (juxt)
    , juxt2
    , juxt3
    , getStats
    , PersonAnalysis(..)
    , Category(..)
    , analyzePerson
      -- * Higher-Order Functions
    , processWithLogging
    , ProcessLog(..)
    , withRetry
    , RetryResult(..)
    , memoize
      -- * Validators
    , Validator
    , ValidationResult(..)
    , validateNonEmpty
    , validateMinLength
    , validateMaxLength
    , validateEmail
    , validateAge
    , combineValidators
    , validateAll
    ) where

import Control.Arrow ((>>>))
import Data.IORef
import qualified Data.Map as Map

-- ============================================================
-- 1. Basic Composition
-- ============================================================

-- | Add tax to an amount
addTax :: Double -> Double -> Double
addTax rate amount = amount * (1 + rate)

-- | Apply discount to an amount
applyDiscountRate :: Double -> Double -> Double
applyDiscountRate rate amount = amount * (1 - rate)

-- | Round to yen (integer)
roundToYen :: Double -> Integer
roundToYen = round

-- | Calculate final price using (>>>) - left to right composition
calculateFinalPrice :: Double -> Integer
calculateFinalPrice = applyDiscountRate 0.2 >>> addTax 0.1 >>> roundToYen

-- | Calculate final price using (.) - right to left composition
calculateFinalPriceCompose :: Double -> Integer
calculateFinalPriceCompose = roundToYen . addTax 0.1 . applyDiscountRate 0.2

-- ============================================================
-- 2. Partial Application (Currying)
-- ============================================================

-- | Greeting function (curried by default in Haskell)
greet :: String -> String -> String
greet greeting name = greeting ++ ", " ++ name ++ "!"

-- | Partial application: say hello
sayHello :: String -> String
sayHello = greet "Hello"

-- | Partial application: say goodbye
sayGoodbye :: String -> String
sayGoodbye = greet "Goodbye"

-- | Email data type
data Email = Email
    { emailFrom    :: String
    , emailTo      :: String
    , emailSubject :: String
    , emailBody    :: String
    } deriving (Show, Eq)

-- | Curried email creation function
sendEmail :: String -> String -> String -> String -> Email
sendEmail from to subject body = Email from to subject body

-- | Partial application: send from system
sendFromSystem :: String -> String -> String -> Email
sendFromSystem = sendEmail "system@example.com"

-- | Partial application: send notification
sendNotification :: String -> Email
sendNotification = sendFromSystem "user@example.com" "通知"

-- ============================================================
-- 3. Parallel Function Application (juxt)
-- ============================================================

-- | Apply two functions to the same input, returning a tuple
juxt2 :: (a -> b) -> (a -> c) -> a -> (b, c)
juxt2 f1 f2 x = (f1 x, f2 x)

-- | Apply three functions to the same input, returning a tuple
juxt3 :: (a -> b) -> (a -> c) -> (a -> d) -> a -> (b, c, d)
juxt3 f1 f2 f3 x = (f1 x, f2 x, f3 x)

-- | Get statistics from a list of numbers
getStats :: [Int] -> (Int, Int, Int, Int, Int)
getStats numbers =
    ( head numbers
    , last numbers
    , length numbers
    , minimum numbers
    , maximum numbers
    )

-- | Category for person analysis
data Category = Adult | Minor
    deriving (Show, Eq)

-- | Person analysis result
data PersonAnalysis = PersonAnalysis
    { analysisName     :: String
    , analysisAge      :: Int
    , analysisCategory :: Category
    } deriving (Show, Eq)

-- | Analyze a person record
analyzePerson :: String -> Int -> PersonAnalysis
analyzePerson name age = PersonAnalysis
    { analysisName = name
    , analysisAge = age
    , analysisCategory = if age >= 18 then Adult else Minor
    }

-- ============================================================
-- 4. Higher-Order Functions
-- ============================================================

-- | Log entry for process logging
data ProcessLog a b = ProcessLog
    { logInput  :: a
    , logOutput :: b
    } deriving (Show, Eq)

-- | Wrap a function with logging (pure version - returns log with result)
processWithLogging :: (a -> b) -> a -> (b, ProcessLog a b)
processWithLogging f x =
    let result = f x
        logEntry = ProcessLog x result
    in (result, logEntry)

-- | Result of a retry operation
data RetryResult a
    = Success a
    | Failure String Int  -- error message and attempts made
    deriving (Show, Eq)

-- | Retry a function that might fail
withRetry :: Int -> (a -> Either String b) -> a -> RetryResult b
withRetry maxRetries f x = go 0
  where
    go attempts
        | attempts >= maxRetries = Failure "Max retries exceeded" attempts
        | otherwise = case f x of
            Right result -> Success result
            Left _ -> go (attempts + 1)

-- | Simple memoization using IORef (for demonstration)
memoize :: Ord a => (a -> b) -> IO (a -> IO b)
memoize f = do
    cacheRef <- newIORef Map.empty
    return $ \x -> do
        cache <- readIORef cacheRef
        case Map.lookup x cache of
            Just result -> return result
            Nothing -> do
                let result = f x
                modifyIORef cacheRef (Map.insert x result)
                return result

-- ============================================================
-- 5. Validators (Composable Functions)
-- ============================================================

-- | Validation result
data ValidationResult
    = Valid
    | Invalid String
    deriving (Show, Eq)

-- | Validator type alias
type Validator a = a -> ValidationResult

-- | Validate that a string is non-empty
validateNonEmpty :: Validator String
validateNonEmpty s
    | null s    = Invalid "Value cannot be empty"
    | otherwise = Valid

-- | Validate minimum length
validateMinLength :: Int -> Validator String
validateMinLength minLen s
    | length s < minLen = Invalid $ "Must be at least " ++ show minLen ++ " characters"
    | otherwise = Valid

-- | Validate maximum length
validateMaxLength :: Int -> Validator String
validateMaxLength maxLen s
    | length s > maxLen = Invalid $ "Must be at most " ++ show maxLen ++ " characters"
    | otherwise = Valid

-- | Validate email format (simple check)
validateEmail :: Validator String
validateEmail s
    | '@' `elem` s && '.' `elem` s = Valid
    | otherwise = Invalid "Invalid email format"

-- | Validate age range
validateAge :: Validator Int
validateAge age
    | age < 0    = Invalid "Age cannot be negative"
    | age > 150  = Invalid "Age seems unrealistic"
    | otherwise  = Valid

-- | Combine two validators (AND logic)
combineValidators :: Validator a -> Validator a -> Validator a
combineValidators v1 v2 x = case v1 x of
    Valid -> v2 x
    invalid -> invalid

-- | Validate with all validators, collecting all errors
validateAll :: [Validator a] -> a -> [ValidationResult]
validateAll validators x = filter isInvalid $ map ($ x) validators
  where
    isInvalid Valid = False
    isInvalid (Invalid _) = True
