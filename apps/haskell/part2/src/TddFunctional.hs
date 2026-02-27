{-|
Module      : TddFunctional
Description : Chapter 6 - TDD and Functional Programming
Copyright   : (c) k2works, 2025
License     : MIT

This module demonstrates TDD patterns in functional programming:
- Red-Green-Refactor cycle
- Roman numeral conversion
- Word count
- Bowling game score
-}
module TddFunctional
    ( -- * FizzBuzz (Basic TDD)
      fizz
    , buzz
    , fizzBuzz
      -- * Roman Numerals
    , toRoman
    , fromRoman
    , RomanDigit(..)
    , romanValue
      -- * Word Count
    , wordCount
    , wordFrequency
    , topWords
      -- * Bowling Game
    , Frame(..)
    , Game
    , roll
    , score
    , newGame
    , isGameComplete
      -- * String Calculator
    , add
    , parseNumbers
      -- * Prime Factors
    , primeFactors
    ) where

import Data.Char (isAlpha, toLower)
import Data.List (sortBy, group, sort)
import Data.Ord (comparing, Down(..))
import qualified Data.Map as Map

-- ============================================================
-- 1. FizzBuzz (Basic TDD Example)
-- ============================================================

-- | Check if divisible by 3
fizz :: Int -> Bool
fizz n = n `mod` 3 == 0

-- | Check if divisible by 5
buzz :: Int -> Bool
buzz n = n `mod` 5 == 0

-- | FizzBuzz implementation
fizzBuzz :: Int -> String
fizzBuzz n
    | fizz n && buzz n = "FizzBuzz"
    | fizz n = "Fizz"
    | buzz n = "Buzz"
    | otherwise = show n

-- ============================================================
-- 2. Roman Numerals
-- ============================================================

-- | Roman numeral digits
data RomanDigit = I | IV | V | IX | X | XL | L | XC | C | CD | D | CM | M
    deriving (Show, Eq, Ord, Enum)

-- | Get decimal value of roman digit
romanValue :: RomanDigit -> Int
romanValue I = 1
romanValue IV = 4
romanValue V = 5
romanValue IX = 9
romanValue X = 10
romanValue XL = 40
romanValue L = 50
romanValue XC = 90
romanValue C = 100
romanValue CD = 400
romanValue D = 500
romanValue CM = 900
romanValue M = 1000

-- | Convert decimal to roman numerals
toRoman :: Int -> String
toRoman n
    | n <= 0 = ""
    | n >= 1000 = "M" ++ toRoman (n - 1000)
    | n >= 900 = "CM" ++ toRoman (n - 900)
    | n >= 500 = "D" ++ toRoman (n - 500)
    | n >= 400 = "CD" ++ toRoman (n - 400)
    | n >= 100 = "C" ++ toRoman (n - 100)
    | n >= 90 = "XC" ++ toRoman (n - 90)
    | n >= 50 = "L" ++ toRoman (n - 50)
    | n >= 40 = "XL" ++ toRoman (n - 40)
    | n >= 10 = "X" ++ toRoman (n - 10)
    | n >= 9 = "IX" ++ toRoman (n - 9)
    | n >= 5 = "V" ++ toRoman (n - 5)
    | n >= 4 = "IV" ++ toRoman (n - 4)
    | otherwise = "I" ++ toRoman (n - 1)

-- | Convert roman numerals to decimal
fromRoman :: String -> Int
fromRoman = go 0
  where
    go acc [] = acc
    go acc [x] = acc + romanCharValue x
    go acc (x:y:rest)
        | romanCharValue x < romanCharValue y = go (acc - romanCharValue x) (y:rest)
        | otherwise = go (acc + romanCharValue x) (y:rest)
    
    romanCharValue 'I' = 1
    romanCharValue 'V' = 5
    romanCharValue 'X' = 10
    romanCharValue 'L' = 50
    romanCharValue 'C' = 100
    romanCharValue 'D' = 500
    romanCharValue 'M' = 1000
    romanCharValue _ = 0

-- ============================================================
-- 3. Word Count
-- ============================================================

-- | Count words in text
wordCount :: String -> Int
wordCount = length . words . filter (\c -> isAlpha c || c == ' ')

-- | Get word frequency
wordFrequency :: String -> Map.Map String Int
wordFrequency text = Map.fromListWith (+) [(w, 1) | w <- normalizedWords]
  where
    normalizedWords = map (map toLower) $ words $ filter (\c -> isAlpha c || c == ' ') text

-- | Get top N words by frequency
topWords :: Int -> String -> [(String, Int)]
topWords n text = take n $ sortBy (comparing (Down . snd)) $ Map.toList $ wordFrequency text

-- ============================================================
-- 4. Bowling Game
-- ============================================================

-- | Frame in bowling
data Frame
    = NormalFrame Int Int        -- Two rolls
    | Spare Int                  -- First roll that becomes spare
    | Strike                     -- Strike
    | TenthFrame Int Int (Maybe Int)  -- Tenth frame with potential bonus
    deriving (Show, Eq)

-- | Bowling game state
type Game = ([Int], Int)  -- (rolls, current frame)

-- | Create new game
newGame :: Game
newGame = ([], 1)

-- | Roll the ball
roll :: Int -> Game -> Game
roll pins (rolls, frame) = (rolls ++ [pins], frame)

-- | Calculate score
score :: Game -> Int
score (rolls, _) = scoreFrames rolls 1 0

scoreFrames :: [Int] -> Int -> Int -> Int
scoreFrames _ 11 acc = acc
scoreFrames [] _ acc = acc
scoreFrames rolls@(r1:rest) frame acc
    | frame == 10 = acc + sum rolls  -- Tenth frame: sum all remaining
    | r1 == 10 = scoreFrames rest (frame + 1) (acc + 10 + bonus2 rest)  -- Strike
    | otherwise = case rest of
        [] -> acc + r1
        (r2:rest2)
            | r1 + r2 == 10 -> scoreFrames rest2 (frame + 1) (acc + 10 + bonus1 rest2)  -- Spare
            | otherwise -> scoreFrames rest2 (frame + 1) (acc + r1 + r2)  -- Normal
  where
    bonus1 (x:_) = x
    bonus1 [] = 0
    bonus2 (x:y:_) = x + y
    bonus2 (x:_) = x
    bonus2 [] = 0

-- | Check if game is complete
isGameComplete :: Game -> Bool
isGameComplete (rolls, _) = length rolls >= 12 || countFrames rolls >= 10
  where
    countFrames [] = 0
    countFrames (10:rest) = 1 + countFrames rest
    countFrames (_:_:rest) = 1 + countFrames rest
    countFrames [_] = 0

-- ============================================================
-- 5. String Calculator
-- ============================================================

-- | Add numbers from string
add :: String -> Int
add "" = 0
add s = sum $ parseNumbers s

-- | Parse numbers from string
parseNumbers :: String -> [Int]
parseNumbers s = map read $ splitOn ',' $ map replaceNewline s
  where
    replaceNewline '\n' = ','
    replaceNewline c = c
    
    splitOn _ [] = []
    splitOn delim str = 
        let (before, after) = break (== delim) str
        in before : case after of
            [] -> []
            (_:rest) -> splitOn delim rest

-- ============================================================
-- 6. Prime Factors
-- ============================================================

-- | Get prime factors of a number
primeFactors :: Int -> [Int]
primeFactors n = factorize n 2
  where
    factorize 1 _ = []
    factorize num factor
        | factor * factor > num = [num]
        | num `mod` factor == 0 = factor : factorize (num `div` factor) factor
        | otherwise = factorize num (factor + 1)
