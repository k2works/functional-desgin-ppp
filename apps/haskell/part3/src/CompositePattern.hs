{-# LANGUAGE RecordWildCards #-}

-- |
-- Module      : CompositePattern
-- Description : Composite pattern implementation in Haskell
-- 
-- This module demonstrates the Composite pattern using various examples:
-- - Shape: Geometric shapes with translate and scale operations
-- - Switchable: On/Off switchable devices
-- - FileSystem: Files and directories
-- - MenuItem: Menu items and set menus
-- - Expression: Mathematical expressions
-- - Organization: Organizational structure

module CompositePattern
  ( -- * Shape types and operations
    Point(..)
  , Shape(..)
  , translateShape
  , scaleShape
  , shapeArea
  , emptyComposite
  , addShape
  
  -- * Switchable types and operations
  , Switchable(..)
  , turnOn
  , turnOff
  , isOn
  , emptySwitchableComposite
  , addSwitchable
  
  -- * FileSystem types and operations
  , FileSystemEntry(..)
  , fileSize
  , fileCount
  , findByExtension
  , allFiles
  , emptyDirectory
  , addEntry
  
  -- * MenuItem types and operations
  , MenuItem(..)
  , menuPrice
  , menuItemCount
  , emptySetMenu
  , addMenuItem
  
  -- * Expression types and operations
  , Expr(..)
  , evaluate
  , simplify
  , variables
  , bindVars
  
  -- * Organization types and operations
  , OrganizationMember(..)
  , totalSalary
  , employeeCount
  , findByRole
  , emptyDepartment
  , addMember
  ) where

-- | 2D Point
data Point = Point
  { pointX :: Double
  , pointY :: Double
  } deriving (Show, Eq)

-- | Shape - Composite pattern for geometric shapes
data Shape
  = Circle Point Double           -- ^ Circle with center and radius
  | Square Point Double           -- ^ Square with top-left corner and side length
  | Rectangle Point Double Double -- ^ Rectangle with top-left, width, and height
  | CompositeShape [Shape]        -- ^ Composite containing multiple shapes
  deriving (Show, Eq)

-- | Translate a shape by (dx, dy)
translateShape :: Double -> Double -> Shape -> Shape
translateShape dx dy shape = case shape of
  Circle (Point x y) r -> Circle (Point (x + dx) (y + dy)) r
  Square (Point x y) s -> Square (Point (x + dx) (y + dy)) s
  Rectangle (Point x y) w h -> Rectangle (Point (x + dx) (y + dy)) w h
  CompositeShape shapes -> CompositeShape (map (translateShape dx dy) shapes)

-- | Scale a shape by a factor
scaleShape :: Double -> Shape -> Shape
scaleShape factor shape = case shape of
  Circle c r -> Circle c (r * factor)
  Square tl s -> Square tl (s * factor)
  Rectangle tl w h -> Rectangle tl (w * factor) (h * factor)
  CompositeShape shapes -> CompositeShape (map (scaleShape factor) shapes)

-- | Calculate the area of a shape
shapeArea :: Shape -> Double
shapeArea shape = case shape of
  Circle _ r -> pi * r * r
  Square _ s -> s * s
  Rectangle _ w h -> w * h
  CompositeShape shapes -> sum (map shapeArea shapes)

-- | Create an empty composite shape
emptyComposite :: Shape
emptyComposite = CompositeShape []

-- | Add a shape to a composite
addShape :: Shape -> Shape -> Shape
addShape s (CompositeShape shapes) = CompositeShape (shapes ++ [s])
addShape s other = CompositeShape [other, s]

-- ============================================================
-- Switchable
-- ============================================================

-- | Switchable - Composite pattern for switchable devices
data Switchable
  = Light String Bool             -- ^ Light with name and on/off state
  | DimmableLight String Int      -- ^ Dimmable light with name and intensity (0-100)
  | Fan String Bool Int           -- ^ Fan with name, on/off state, and speed
  | CompositeSwitchable String [Switchable]  -- ^ Composite with name and list
  deriving (Show, Eq)

-- | Turn on a switchable
turnOn :: Switchable -> Switchable
turnOn switchable = case switchable of
  Light name _ -> Light name True
  DimmableLight name _ -> DimmableLight name 100
  Fan name _ speed -> Fan name True (max speed 1)
  CompositeSwitchable name items -> CompositeSwitchable name (map turnOn items)

-- | Turn off a switchable
turnOff :: Switchable -> Switchable
turnOff switchable = case switchable of
  Light name _ -> Light name False
  DimmableLight name _ -> DimmableLight name 0
  Fan name _ speed -> Fan name False speed
  CompositeSwitchable name items -> CompositeSwitchable name (map turnOff items)

-- | Check if a switchable is on
isOn :: Switchable -> Bool
isOn switchable = case switchable of
  Light _ on -> on
  DimmableLight _ intensity -> intensity > 0
  Fan _ on _ -> on
  CompositeSwitchable _ items -> any isOn items

-- | Create an empty composite switchable
emptySwitchableComposite :: String -> Switchable
emptySwitchableComposite name = CompositeSwitchable name []

-- | Add a switchable to a composite
addSwitchable :: Switchable -> Switchable -> Switchable
addSwitchable item (CompositeSwitchable name items) = 
  CompositeSwitchable name (items ++ [item])
addSwitchable item other = 
  CompositeSwitchable "Group" [other, item]

-- ============================================================
-- FileSystem
-- ============================================================

-- | FileSystemEntry - Composite pattern for file system
data FileSystemEntry
  = File String Int String        -- ^ File with name, size, and extension
  | Directory String [FileSystemEntry]  -- ^ Directory with name and children
  deriving (Show, Eq)

-- | Get the total size of a file system entry
fileSize :: FileSystemEntry -> Int
fileSize entry = case entry of
  File _ size _ -> size
  Directory _ children -> sum (map fileSize children)

-- | Get the number of files in a file system entry
fileCount :: FileSystemEntry -> Int
fileCount entry = case entry of
  File {} -> 1
  Directory _ children -> sum (map fileCount children)

-- | Find files by extension
findByExtension :: String -> FileSystemEntry -> [FileSystemEntry]
findByExtension ext entry = case entry of
  File _ _ fileExt | fileExt == ext -> [entry]
  File {} -> []
  Directory _ children -> concatMap (findByExtension ext) children

-- | Get all files in a file system entry
allFiles :: FileSystemEntry -> [FileSystemEntry]
allFiles entry = case entry of
  File {} -> [entry]
  Directory _ children -> concatMap allFiles children

-- | Create an empty directory
emptyDirectory :: String -> FileSystemEntry
emptyDirectory name = Directory name []

-- | Add an entry to a directory
addEntry :: FileSystemEntry -> FileSystemEntry -> FileSystemEntry
addEntry child (Directory name children) = Directory name (children ++ [child])
addEntry child other = Directory "root" [other, child]

-- ============================================================
-- MenuItem
-- ============================================================

-- | MenuItem - Composite pattern for menu items
data MenuItem
  = Item String Double String     -- ^ Item with name, price, and category
  | SetMenu String [MenuItem] Double  -- ^ Set menu with name, items, and discount rate
  deriving (Show, Eq)

-- | Calculate the price of a menu item
menuPrice :: MenuItem -> Double
menuPrice item = case item of
  Item _ price _ -> price
  SetMenu _ items discountRate -> 
    let totalPrice = sum (map menuPrice items)
    in totalPrice * (1 - discountRate)

-- | Get the number of items in a menu item
menuItemCount :: MenuItem -> Int
menuItemCount item = case item of
  Item {} -> 1
  SetMenu _ items _ -> sum (map menuItemCount items)

-- | Create an empty set menu
emptySetMenu :: String -> Double -> MenuItem
emptySetMenu name discount = SetMenu name [] discount

-- | Add an item to a set menu
addMenuItem :: MenuItem -> MenuItem -> MenuItem
addMenuItem child (SetMenu name items discount) = SetMenu name (items ++ [child]) discount
addMenuItem child other = SetMenu "Set" [other, child] 0.0

-- ============================================================
-- Expression
-- ============================================================

-- | Expression - Composite pattern for mathematical expressions
data Expr
  = Number Double                 -- ^ Numeric literal
  | Variable String (Maybe Double)  -- ^ Variable with optional bound value
  | Add Expr Expr                 -- ^ Addition
  | Subtract Expr Expr            -- ^ Subtraction
  | Multiply Expr Expr            -- ^ Multiplication
  | Divide Expr Expr              -- ^ Division
  | Negate Expr                   -- ^ Negation
  deriving (Show, Eq)

-- | Evaluate an expression
evaluate :: Expr -> Maybe Double
evaluate expr = case expr of
  Number n -> Just n
  Variable _ (Just v) -> Just v
  Variable name Nothing -> Nothing  -- Unbound variable
  Add l r -> (+) <$> evaluate l <*> evaluate r
  Subtract l r -> (-) <$> evaluate l <*> evaluate r
  Multiply l r -> (*) <$> evaluate l <*> evaluate r
  Divide l r -> do
    lv <- evaluate l
    rv <- evaluate r
    if rv == 0 then Nothing else Just (lv / rv)
  Negate e -> negate <$> evaluate e

-- | Simplify an expression
simplify :: Expr -> Expr
simplify expr = case expr of
  Add l r -> case (simplify l, simplify r) of
    (Number 0, r') -> r'
    (l', Number 0) -> l'
    (Number a, Number b) -> Number (a + b)
    (l', r') -> Add l' r'
  Subtract l r -> case (simplify l, simplify r) of
    (l', Number 0) -> l'
    (Number a, Number b) -> Number (a - b)
    (l', r') | l' == r' -> Number 0
    (l', r') -> Subtract l' r'
  Multiply l r -> case (simplify l, simplify r) of
    (Number 0, _) -> Number 0
    (_, Number 0) -> Number 0
    (Number 1, r') -> r'
    (l', Number 1) -> l'
    (Number a, Number b) -> Number (a * b)
    (l', r') -> Multiply l' r'
  Divide l r -> case (simplify l, simplify r) of
    (Number 0, _) -> Number 0
    (l', Number 1) -> l'
    (Number a, Number b) | b /= 0 -> Number (a / b)
    (l', r') -> Divide l' r'
  Negate e -> case simplify e of
    Number n -> Number (-n)
    Negate e' -> e'  -- Double negation
    e' -> Negate e'
  e -> e

-- | Get all variable names in an expression
variables :: Expr -> [String]
variables expr = case expr of
  Number _ -> []
  Variable name _ -> [name]
  Add l r -> variables l ++ variables r
  Subtract l r -> variables l ++ variables r
  Multiply l r -> variables l ++ variables r
  Divide l r -> variables l ++ variables r
  Negate e -> variables e

-- | Bind values to variables
bindVars :: [(String, Double)] -> Expr -> Expr
bindVars bindings expr = case expr of
  Variable name Nothing -> 
    case lookup name bindings of
      Just v -> Variable name (Just v)
      Nothing -> expr
  Variable {} -> expr
  Number n -> Number n
  Add l r -> Add (bindVars bindings l) (bindVars bindings r)
  Subtract l r -> Subtract (bindVars bindings l) (bindVars bindings r)
  Multiply l r -> Multiply (bindVars bindings l) (bindVars bindings r)
  Divide l r -> Divide (bindVars bindings l) (bindVars bindings r)
  Negate e -> Negate (bindVars bindings e)

-- ============================================================
-- Organization
-- ============================================================

-- | OrganizationMember - Composite pattern for organizational structure
data OrganizationMember
  = Employee String Double String  -- ^ Employee with name, salary, and role
  | Department String (Maybe String) [OrganizationMember]  -- ^ Department with name, manager, and members
  deriving (Show, Eq)

-- | Calculate the total salary
totalSalary :: OrganizationMember -> Double
totalSalary member = case member of
  Employee _ salary _ -> salary
  Department _ _ members -> sum (map totalSalary members)

-- | Get the number of employees
employeeCount :: OrganizationMember -> Int
employeeCount member = case member of
  Employee {} -> 1
  Department _ _ members -> sum (map employeeCount members)

-- | Find employees by role
findByRole :: String -> OrganizationMember -> [OrganizationMember]
findByRole role member = case member of
  Employee _ _ r | r == role -> [member]
  Employee {} -> []
  Department _ _ members -> concatMap (findByRole role) members

-- | Create an empty department
emptyDepartment :: String -> Maybe String -> OrganizationMember
emptyDepartment name manager = Department name manager []

-- | Add a member to a department
addMember :: OrganizationMember -> OrganizationMember -> OrganizationMember
addMember child (Department name manager members) = Department name manager (members ++ [child])
addMember child other = Department "Organization" Nothing [other, child]
