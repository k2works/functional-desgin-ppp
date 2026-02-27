-- |
-- Module      : BestPractices
-- Description : Functional Programming Best Practices
-- 
-- This module demonstrates best practices for functional programming
-- in Haskell, including immutability, composition, and pure functions.

module BestPractices
  ( -- * Immutability Practices
    -- ** Immutable Data Updates
    User(..)
  , updateUserName
  , updateUserEmail
  , updateUserAge
  
  -- ** Record Update Pattern
  , updateUser
  
  -- * Function Composition
  -- ** Pipeline Pattern
  , Pipeline
  , pipeline
  , (|>)
  , (<|)
  
  -- ** Composed Transformations
  , trim
  , toLowerCase
  , removeSpaces
  , sanitizeInput
  
  -- * Pure Functions
  -- ** Referential Transparency
  , pureAdd
  , pureMultiply
  , pureCompute
  
  -- ** Separating Effects
  , Computation(..)
  , pureStep
  , runComputation
  
  -- * Error Handling
  -- ** Result Type
  , Result(..)
  , mapResult
  , flatMapResult
  , fromMaybe'
  
  -- ** Validation Pattern
  , Validation(..)
  , validate
  , validateAll
  , combineValidations
  
  -- * Data Transformation
  -- ** Map/Filter/Reduce
  , mapOver
  , filterBy
  , reduceWith
  , transformPipeline
  
  -- ** Lazy Evaluation
  , lazyRange
  , takeWhile'
  , infiniteSequence
  
  -- * Type Safety
  -- ** Newtype Pattern
  , Email(..)
  , mkEmail
  , Username(..)
  , mkUsername
  , Age(..)
  , mkAge
  
  -- ** Smart Constructors
  , PositiveInt(..)
  , mkPositiveInt
  , NonEmptyString(..)
  , mkNonEmptyString
  
  -- * Testing Best Practices
  -- ** Property-Based Testing Support
  , associative
  , commutative
  , identity'
  , inverse
  ) where

import Data.Char (toLower, isSpace)

-- ============================================================
-- Immutability Practices
-- ============================================================

-- | User record
data User = User
  { userName :: String
  , userEmail :: String
  , userAge :: Int
  } deriving (Show, Eq)

-- | Update user name (immutable)
updateUserName :: String -> User -> User
updateUserName newName user = user { userName = newName }

-- | Update user email (immutable)
updateUserEmail :: String -> User -> User
updateUserEmail newEmail user = user { userEmail = newEmail }

-- | Update user age (immutable)
updateUserAge :: Int -> User -> User
updateUserAge newAge user = user { userAge = newAge }

-- | Generic record update
updateUser :: (User -> User) -> User -> User
updateUser f = f

-- ============================================================
-- Function Composition
-- ============================================================

-- | Pipeline type
type Pipeline a b = a -> b

-- | Create pipeline
pipeline :: [a -> a] -> a -> a
pipeline = foldl' (flip (.)) id

-- | Forward pipe operator
(|>) :: a -> (a -> b) -> b
x |> f = f x
infixl 1 |>

-- | Backward pipe operator
(<|) :: (a -> b) -> a -> b
f <| x = f x
infixr 0 <|

-- | Trim whitespace
trim :: String -> String
trim = dropWhile isSpace . reverse . dropWhile isSpace . reverse

-- | Convert to lowercase
toLowerCase :: String -> String
toLowerCase = map toLower

-- | Remove all spaces
removeSpaces :: String -> String
removeSpaces = filter (not . isSpace)

-- | Sanitize input (composed transformation)
sanitizeInput :: String -> String
sanitizeInput = toLowerCase . trim

-- ============================================================
-- Pure Functions
-- ============================================================

-- | Pure addition
pureAdd :: Num a => a -> a -> a
pureAdd x y = x + y

-- | Pure multiplication
pureMultiply :: Num a => a -> a -> a
pureMultiply x y = x * y

-- | Pure computation (referentially transparent)
pureCompute :: Int -> Int -> Int -> Int
pureCompute x y z = (x + y) * z

-- | Computation monad for separating effects
data Computation a
  = Pure a
  | Effect (IO a)

instance Functor Computation where
  fmap f (Pure a) = Pure (f a)
  fmap f (Effect io) = Effect (fmap f io)

-- | Pure computation step
pureStep :: a -> Computation a
pureStep = Pure

-- | Run computation
runComputation :: Computation a -> IO a
runComputation (Pure a) = return a
runComputation (Effect io) = io

-- ============================================================
-- Error Handling
-- ============================================================

-- | Result type for error handling
data Result e a
  = Success a
  | Failure e
  deriving (Show, Eq)

-- | Map over result
mapResult :: (a -> b) -> Result e a -> Result e b
mapResult f (Success a) = Success (f a)
mapResult _ (Failure e) = Failure e

-- | Flat map result
flatMapResult :: (a -> Result e b) -> Result e a -> Result e b
flatMapResult f (Success a) = f a
flatMapResult _ (Failure e) = Failure e

-- | Convert from Maybe with default error
fromMaybe' :: e -> Maybe a -> Result e a
fromMaybe' _ (Just a) = Success a
fromMaybe' e Nothing = Failure e

-- | Validation result
data Validation e a
  = Valid a
  | Invalid [e]
  deriving (Show, Eq)

-- | Single validation
validate :: (a -> Bool) -> e -> a -> Validation e a
validate predicate err value =
  if predicate value
  then Valid value
  else Invalid [err]

-- | Validate all rules
validateAll :: [(a -> Bool, e)] -> a -> Validation e a
validateAll rules value =
  let errors = [err | (predicate, err) <- rules, not (predicate value)]
  in if null errors
     then Valid value
     else Invalid errors

-- | Combine validations
combineValidations :: [Validation e a] -> Validation e [a]
combineValidations validations =
  let (valids, invalids) = partitionValidations validations
  in if null invalids
     then Valid valids
     else Invalid (concat invalids)
  where
    partitionValidations [] = ([], [])
    partitionValidations (Valid a : rest) =
      let (vs, is) = partitionValidations rest in (a : vs, is)
    partitionValidations (Invalid es : rest) =
      let (vs, is) = partitionValidations rest in (vs, es : is)

-- ============================================================
-- Data Transformation
-- ============================================================

-- | Map over collection
mapOver :: (a -> b) -> [a] -> [b]
mapOver = map

-- | Filter collection
filterBy :: (a -> Bool) -> [a] -> [a]
filterBy = filter

-- | Reduce collection
reduceWith :: (b -> a -> b) -> b -> [a] -> b
reduceWith = foldl'

-- | Transform pipeline combining map, filter, reduce
transformPipeline :: (a -> b) -> (b -> Bool) -> (c -> b -> c) -> c -> [a] -> c
transformPipeline mapF filterF reduceF initial xs =
  reduceWith reduceF initial (filterBy filterF (mapOver mapF xs))

-- ============================================================
-- Lazy Evaluation
-- ============================================================

-- | Lazy range
lazyRange :: Int -> Int -> [Int]
lazyRange start end = [start..end]

-- | Take while predicate
takeWhile' :: (a -> Bool) -> [a] -> [a]
takeWhile' = takeWhile

-- | Infinite sequence
infiniteSequence :: a -> (a -> a) -> [a]
infiniteSequence start next = iterate next start

-- ============================================================
-- Type Safety
-- ============================================================

-- | Email newtype
newtype Email = Email { unEmail :: String }
  deriving (Show, Eq)

-- | Smart constructor for Email
mkEmail :: String -> Maybe Email
mkEmail s
  | '@' `elem` s && '.' `elem` dropWhile (/= '@') s = Just (Email s)
  | otherwise = Nothing

-- | Username newtype
newtype Username = Username { unUsername :: String }
  deriving (Show, Eq)

-- | Smart constructor for Username
mkUsername :: String -> Maybe Username
mkUsername s
  | length s >= 3 && length s <= 20 = Just (Username s)
  | otherwise = Nothing

-- | Age newtype
newtype Age = Age { unAge :: Int }
  deriving (Show, Eq)

-- | Smart constructor for Age
mkAge :: Int -> Maybe Age
mkAge n
  | n >= 0 && n <= 150 = Just (Age n)
  | otherwise = Nothing

-- | Positive integer newtype
newtype PositiveInt = PositiveInt { unPositiveInt :: Int }
  deriving (Show, Eq)

-- | Smart constructor for PositiveInt
mkPositiveInt :: Int -> Maybe PositiveInt
mkPositiveInt n
  | n > 0 = Just (PositiveInt n)
  | otherwise = Nothing

-- | Non-empty string newtype
newtype NonEmptyString = NonEmptyString { unNonEmptyString :: String }
  deriving (Show, Eq)

-- | Smart constructor for NonEmptyString
mkNonEmptyString :: String -> Maybe NonEmptyString
mkNonEmptyString s
  | null s = Nothing
  | otherwise = Just (NonEmptyString s)

-- ============================================================
-- Testing Best Practices
-- ============================================================

-- | Test for associativity: f (f a b) c == f a (f b c)
associative :: Eq a => (a -> a -> a) -> a -> a -> a -> Bool
associative f a b c = f (f a b) c == f a (f b c)

-- | Test for commutativity: f a b == f b a
commutative :: Eq b => (a -> a -> b) -> a -> a -> Bool
commutative f a b = f a b == f b a

-- | Test for identity: f a identity == a
identity' :: Eq a => (a -> a -> a) -> a -> a -> Bool
identity' f identity a = f a identity == a && f identity a == a

-- | Test for inverse: f a (inverse a) == identity
inverse :: Eq a => (a -> a -> a) -> (a -> a) -> a -> a -> Bool
inverse f inv identity a = f a (inv a) == identity
