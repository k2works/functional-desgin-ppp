-- |
-- Module      : VisitorPattern
-- Description : Visitor pattern implementation in Haskell
-- 
-- This module demonstrates the Visitor pattern using various examples:
-- - Shape visitors: toJson, toXml, area, perimeter
-- - Expression visitors: evaluate, prettyPrint, variables
-- - Tree visitors: fold, map, traverse

module VisitorPattern
  ( -- * Shape Types
    Point(..)
  , Shape(..)
  
  -- * Shape Visitors
  , shapeToJson
  , shapeToXml
  , shapeArea
  , shapePerimeter
  , shapeBoundingBox
  
  -- * Visitor Composition
  , visitShapes
  , totalArea
  , totalPerimeter
  
  -- * Expression Types
  , Expr(..)
  
  -- * Expression Visitors
  , evaluate
  , prettyPrint
  , exprVariables
  , exprDepth
  , simplify
  
  -- * Tree Types
  , Tree(..)
  
  -- * Tree Visitors
  , treeFold
  , treeMap
  , treeSize
  , treeDepth
  , treeToList
  ) where

import Data.List (nub)

-- ============================================================
-- Shape Types
-- ============================================================

-- | 2D Point
data Point = Point Double Double
  deriving (Show, Eq)

-- | Shape ADT
data Shape
  = Circle Point Double           -- ^ Circle with center and radius
  | Square Point Double           -- ^ Square with top-left and side
  | Rectangle Point Double Double -- ^ Rectangle with top-left, width, height
  deriving (Show, Eq)

-- ============================================================
-- Shape Visitors
-- ============================================================

-- | Convert shape to JSON string
shapeToJson :: Shape -> String
shapeToJson shape = case shape of
  Circle (Point x y) r ->
    "{\"type\":\"circle\",\"center\":[" ++ show x ++ "," ++ show y ++ "],\"radius\":" ++ show r ++ "}"
  
  Square (Point x y) s ->
    "{\"type\":\"square\",\"topLeft\":[" ++ show x ++ "," ++ show y ++ "],\"side\":" ++ show s ++ "}"
  
  Rectangle (Point x y) w h ->
    "{\"type\":\"rectangle\",\"topLeft\":[" ++ show x ++ "," ++ show y ++ "],\"width\":" ++ show w ++ ",\"height\":" ++ show h ++ "}"

-- | Convert shape to XML string
shapeToXml :: Shape -> String
shapeToXml shape = case shape of
  Circle (Point x y) r ->
    "<circle><center x=\"" ++ show x ++ "\" y=\"" ++ show y ++ "\"/><radius>" ++ show r ++ "</radius></circle>"
  
  Square (Point x y) s ->
    "<square><topLeft x=\"" ++ show x ++ "\" y=\"" ++ show y ++ "\"/><side>" ++ show s ++ "</side></square>"
  
  Rectangle (Point x y) w h ->
    "<rectangle><topLeft x=\"" ++ show x ++ "\" y=\"" ++ show y ++ "\"/><width>" ++ show w ++ "</width><height>" ++ show h ++ "</height></rectangle>"

-- | Calculate shape area
shapeArea :: Shape -> Double
shapeArea shape = case shape of
  Circle _ r -> pi * r * r
  Square _ s -> s * s
  Rectangle _ w h -> w * h

-- | Calculate shape perimeter
shapePerimeter :: Shape -> Double
shapePerimeter shape = case shape of
  Circle _ r -> 2 * pi * r
  Square _ s -> 4 * s
  Rectangle _ w h -> 2 * (w + h)

-- | Calculate bounding box (minX, minY, maxX, maxY)
shapeBoundingBox :: Shape -> (Double, Double, Double, Double)
shapeBoundingBox shape = case shape of
  Circle (Point x y) r -> (x - r, y - r, x + r, y + r)
  Square (Point x y) s -> (x, y, x + s, y + s)
  Rectangle (Point x y) w h -> (x, y, x + w, y + h)

-- ============================================================
-- Visitor Composition
-- ============================================================

-- | Visit multiple shapes with a visitor function
visitShapes :: (Shape -> a) -> [Shape] -> [a]
visitShapes = map

-- | Calculate total area of shapes
totalArea :: [Shape] -> Double
totalArea = sum . visitShapes shapeArea

-- | Calculate total perimeter of shapes
totalPerimeter :: [Shape] -> Double
totalPerimeter = sum . visitShapes shapePerimeter

-- ============================================================
-- Expression Types
-- ============================================================

-- | Expression ADT
data Expr
  = Num Double                    -- ^ Numeric literal
  | Var String                    -- ^ Variable
  | Add Expr Expr                 -- ^ Addition
  | Sub Expr Expr                 -- ^ Subtraction
  | Mul Expr Expr                 -- ^ Multiplication
  | Div Expr Expr                 -- ^ Division
  | Neg Expr                      -- ^ Negation
  deriving (Show, Eq)

-- ============================================================
-- Expression Visitors
-- ============================================================

-- | Evaluate an expression with variable bindings
evaluate :: [(String, Double)] -> Expr -> Maybe Double
evaluate env expr = case expr of
  Num n -> Just n
  Var name -> lookup name env
  Add l r -> (+) <$> evaluate env l <*> evaluate env r
  Sub l r -> (-) <$> evaluate env l <*> evaluate env r
  Mul l r -> (*) <$> evaluate env l <*> evaluate env r
  Div l r -> do
    lv <- evaluate env l
    rv <- evaluate env r
    if rv == 0 then Nothing else Just (lv / rv)
  Neg e -> negate <$> evaluate env e

-- | Pretty print an expression
prettyPrint :: Expr -> String
prettyPrint expr = case expr of
  Num n -> show n
  Var name -> name
  Add l r -> "(" ++ prettyPrint l ++ " + " ++ prettyPrint r ++ ")"
  Sub l r -> "(" ++ prettyPrint l ++ " - " ++ prettyPrint r ++ ")"
  Mul l r -> "(" ++ prettyPrint l ++ " * " ++ prettyPrint r ++ ")"
  Div l r -> "(" ++ prettyPrint l ++ " / " ++ prettyPrint r ++ ")"
  Neg e -> "-" ++ prettyPrint e

-- | Get all variable names in an expression
exprVariables :: Expr -> [String]
exprVariables expr = nub $ go expr
  where
    go (Num _) = []
    go (Var name) = [name]
    go (Add l r) = go l ++ go r
    go (Sub l r) = go l ++ go r
    go (Mul l r) = go l ++ go r
    go (Div l r) = go l ++ go r
    go (Neg e) = go e

-- | Calculate expression depth
exprDepth :: Expr -> Int
exprDepth expr = case expr of
  Num _ -> 1
  Var _ -> 1
  Add l r -> 1 + max (exprDepth l) (exprDepth r)
  Sub l r -> 1 + max (exprDepth l) (exprDepth r)
  Mul l r -> 1 + max (exprDepth l) (exprDepth r)
  Div l r -> 1 + max (exprDepth l) (exprDepth r)
  Neg e -> 1 + exprDepth e

-- | Simplify an expression
simplify :: Expr -> Expr
simplify expr = case expr of
  Add l r -> case (simplify l, simplify r) of
    (Num 0, r') -> r'
    (l', Num 0) -> l'
    (Num a, Num b) -> Num (a + b)
    (l', r') -> Add l' r'
  Sub l r -> case (simplify l, simplify r) of
    (l', Num 0) -> l'
    (Num a, Num b) -> Num (a - b)
    (l', r') | l' == r' -> Num 0
    (l', r') -> Sub l' r'
  Mul l r -> case (simplify l, simplify r) of
    (Num 0, _) -> Num 0
    (_, Num 0) -> Num 0
    (Num 1, r') -> r'
    (l', Num 1) -> l'
    (Num a, Num b) -> Num (a * b)
    (l', r') -> Mul l' r'
  Div l r -> case (simplify l, simplify r) of
    (Num 0, _) -> Num 0
    (l', Num 1) -> l'
    (Num a, Num b) | b /= 0 -> Num (a / b)
    (l', r') -> Div l' r'
  Neg e -> case simplify e of
    Num n -> Num (-n)
    Neg e' -> e'
    e' -> Neg e'
  e -> e

-- ============================================================
-- Tree Types
-- ============================================================

-- | Generic tree
data Tree a
  = Leaf a
  | Node a [Tree a]
  deriving (Show, Eq)

-- ============================================================
-- Tree Visitors
-- ============================================================

-- | Fold a tree with functions for leaf and node
treeFold :: (a -> b) -> (a -> [b] -> b) -> Tree a -> b
treeFold leafFn nodeFn tree = case tree of
  Leaf x -> leafFn x
  Node x children -> nodeFn x (map (treeFold leafFn nodeFn) children)

-- | Map a function over tree values
treeMap :: (a -> b) -> Tree a -> Tree b
treeMap f tree = case tree of
  Leaf x -> Leaf (f x)
  Node x children -> Node (f x) (map (treeMap f) children)

-- | Count nodes in tree
treeSize :: Tree a -> Int
treeSize = treeFold (const 1) (\_ sizes -> 1 + sum sizes)

-- | Calculate tree depth
treeDepth :: Tree a -> Int
treeDepth = treeFold (const 1) (\_ depths -> 1 + maximum (0 : depths))

-- | Convert tree to list (preorder)
treeToList :: Tree a -> [a]
treeToList = treeFold (: []) (\x childLists -> x : concat childLists)
