{-|
Module      : PropertyBasedTesting
Description : Chapter 5 - Property-Based Testing
Copyright   : (c) k2works, 2025
License     : MIT

This module demonstrates property-based testing patterns:
- Properties of pure functions
- Generators for custom types
- Shrinking
- Model-based testing
-}
module PropertyBasedTesting
    ( -- * String Functions
      reverseString
    , capitalize
    , isPalindrome
      -- * List Functions  
    , mySort
    , myReverse
    , myFilter
      -- * Math Functions
    , absolute
    , factorial
    , fibonacci
      -- * Money Operations
    , Money(..)
    , addMoney
    , subtractMoney
    , multiplyMoney
      -- * Stack Operations
    , Stack
    , emptyStack
    , push
    , pop
    , peek
    , isEmpty
    , size
      -- * FizzBuzz
    , fizzBuzz
    , fizzBuzzList
    ) where

import Data.List (sort)
import Data.Char (toUpper, toLower)

-- ============================================================
-- 1. String Functions
-- ============================================================

-- | Reverse a string
reverseString :: String -> String
reverseString = reverse

-- | Capitalize first letter
capitalize :: String -> String
capitalize [] = []
capitalize (x:xs) = toUpper x : map toLower xs

-- | Check if string is palindrome
isPalindrome :: String -> Bool
isPalindrome s = cleanS == reverse cleanS
  where
    cleanS = map toLower $ filter (/= ' ') s

-- ============================================================
-- 2. List Functions
-- ============================================================

-- | Sort a list (wrapper for property testing)
mySort :: Ord a => [a] -> [a]
mySort = sort

-- | Reverse a list
myReverse :: [a] -> [a]
myReverse = reverse

-- | Filter a list
myFilter :: (a -> Bool) -> [a] -> [a]
myFilter = filter

-- ============================================================
-- 3. Math Functions
-- ============================================================

-- | Absolute value
absolute :: Int -> Int
absolute = abs

-- | Factorial (non-negative integers)
factorial :: Integer -> Integer
factorial n
    | n < 0 = error "factorial: negative input"
    | n == 0 = 1
    | otherwise = n * factorial (n - 1)

-- | Fibonacci number
fibonacci :: Int -> Integer
fibonacci n
    | n < 0 = error "fibonacci: negative input"
    | n == 0 = 0
    | n == 1 = 1
    | otherwise = fibonacci (n - 1) + fibonacci (n - 2)

-- ============================================================
-- 4. Money Operations
-- ============================================================

-- | Money type with currency
data Money = Money
    { moneyAmount :: Int      -- Amount in smallest unit (e.g., cents)
    , moneyCurrency :: String -- Currency code
    } deriving (Show, Eq)

-- | Add two money values (same currency)
addMoney :: Money -> Money -> Maybe Money
addMoney m1 m2
    | moneyCurrency m1 == moneyCurrency m2 = 
        Just Money { moneyAmount = moneyAmount m1 + moneyAmount m2
                   , moneyCurrency = moneyCurrency m1 }
    | otherwise = Nothing

-- | Subtract money (same currency)
subtractMoney :: Money -> Money -> Maybe Money
subtractMoney m1 m2
    | moneyCurrency m1 == moneyCurrency m2 = 
        Just Money { moneyAmount = moneyAmount m1 - moneyAmount m2
                   , moneyCurrency = moneyCurrency m1 }
    | otherwise = Nothing

-- | Multiply money by scalar
multiplyMoney :: Money -> Int -> Money
multiplyMoney m n = m { moneyAmount = moneyAmount m * n }

-- ============================================================
-- 5. Stack Operations
-- ============================================================

-- | Stack type
newtype Stack a = Stack { unStack :: [a] }
    deriving (Show, Eq)

-- | Empty stack
emptyStack :: Stack a
emptyStack = Stack []

-- | Push onto stack
push :: a -> Stack a -> Stack a
push x (Stack xs) = Stack (x:xs)

-- | Pop from stack
pop :: Stack a -> Maybe (a, Stack a)
pop (Stack []) = Nothing
pop (Stack (x:xs)) = Just (x, Stack xs)

-- | Peek at top of stack
peek :: Stack a -> Maybe a
peek (Stack []) = Nothing
peek (Stack (x:_)) = Just x

-- | Check if stack is empty
isEmpty :: Stack a -> Bool
isEmpty (Stack []) = True
isEmpty _ = False

-- | Get size of stack
size :: Stack a -> Int
size (Stack xs) = length xs

-- ============================================================
-- 6. FizzBuzz
-- ============================================================

-- | FizzBuzz for a single number
fizzBuzz :: Int -> String
fizzBuzz n
    | n `mod` 15 == 0 = "FizzBuzz"
    | n `mod` 3 == 0 = "Fizz"
    | n `mod` 5 == 0 = "Buzz"
    | otherwise = show n

-- | FizzBuzz for a range
fizzBuzzList :: Int -> Int -> [String]
fizzBuzzList start end = map fizzBuzz [start..end]
