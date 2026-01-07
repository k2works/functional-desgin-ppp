{-# LANGUAGE RecordWildCards #-}

-- |
-- Module      : DecoratorPattern
-- Description : Decorator pattern implementation in Haskell
-- 
-- This module demonstrates the Decorator pattern using various examples:
-- - JournaledShape: Shape with operation history tracking
-- - Function decorators: Logging, retry, caching, validation

module DecoratorPattern
  ( -- * Journaled Shape
    JournalEntry(..)
  , JournaledShape(..)
  , journalShape
  , getJournal
  , getShape
  , translateJournaled
  , scaleJournaled
  
  -- * Function Decorators
  , withLogging
  , withRetry
  , withCache
  , withValidation
  
  -- * Composing Decorators
  , composeDecorators
  
  -- * Timer Decorator
  , timedExecution
  
  -- * Countable operations
  , CountedResult(..)
  , withCounter
  ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

import CompositePattern (Shape(..), Point(..), translateShape, scaleShape)

-- ============================================================
-- Journaled Shape
-- ============================================================

-- | Journal entry for shape operations
data JournalEntry
  = TranslateEntry Double Double  -- ^ Translation by (dx, dy)
  | ScaleEntry Double             -- ^ Scale by factor
  deriving (Show, Eq)

-- | Shape with operation history
data JournaledShape = JournaledShape
  { jsJournal :: [JournalEntry]   -- ^ History of operations
  , jsShape :: Shape              -- ^ The wrapped shape
  } deriving (Show, Eq)

-- | Wrap a shape with journaling
journalShape :: Shape -> JournaledShape
journalShape shape = JournaledShape
  { jsJournal = []
  , jsShape = shape
  }

-- | Get the journal entries
getJournal :: JournaledShape -> [JournalEntry]
getJournal = jsJournal

-- | Get the underlying shape
getShape :: JournaledShape -> Shape
getShape = jsShape

-- | Translate a journaled shape
translateJournaled :: Double -> Double -> JournaledShape -> JournaledShape
translateJournaled dx dy js = JournaledShape
  { jsJournal = jsJournal js ++ [TranslateEntry dx dy]
  , jsShape = translateShape dx dy (jsShape js)
  }

-- | Scale a journaled shape
scaleJournaled :: Double -> JournaledShape -> JournaledShape
scaleJournaled factor js = JournaledShape
  { jsJournal = jsJournal js ++ [ScaleEntry factor]
  , jsShape = scaleShape factor (jsShape js)
  }

-- ============================================================
-- Function Decorators (Pure)
-- ============================================================

-- | Add logging to a function (collects log entries)
withLogging :: String -> (a -> b) -> (a -> (b, [String]))
withLogging name f = \x -> 
  let result = f x
  in (result, ["[LOG] " ++ name ++ " called", "[LOG] " ++ name ++ " returned"])

-- | Add retry logic to a function that might fail
withRetry :: Int -> (a -> Either String b) -> (a -> Either String b)
withRetry maxRetries f = go 0
  where
    go attempts x
      | attempts >= maxRetries = Left "Max retries exceeded"
      | otherwise = case f x of
          Right result -> Right result
          Left _ -> go (attempts + 1) x

-- | Add caching to a function (using a Map for pure memoization)
withCache :: Ord a => (a -> b) -> (Map a b -> a -> (b, Map a b))
withCache f = \cache x ->
  case Map.lookup x cache of
    Just cached -> (cached, cache)
    Nothing -> 
      let result = f x
      in (result, Map.insert x result cache)

-- | Add validation to a function
withValidation :: (a -> Bool) -> String -> (a -> Either String b) -> (a -> Either String b)
withValidation validator errMsg f = \x ->
  if validator x
    then f x
    else Left errMsg

-- ============================================================
-- Composing Decorators
-- ============================================================

-- | Compose multiple function transformations
composeDecorators :: [a -> a] -> a -> a
composeDecorators = foldr (.) id

-- ============================================================
-- Timer Decorator (IO)
-- ============================================================

-- | Execute a function and record if it completed (simplified)
timedExecution :: (a -> b) -> a -> (b, Bool)
timedExecution f x = 
  let result = f x
  in (result, True)

-- ============================================================
-- Counted Operations
-- ============================================================

-- | Result with call count
data CountedResult a = CountedResult
  { crResult :: a
  , crCount :: Int
  } deriving (Show, Eq)

-- | Wrap a function to count calls
withCounter :: (a -> b) -> ([a] -> [CountedResult b])
withCounter f = zipWith (\i x -> CountedResult (f x) i) [1..]
