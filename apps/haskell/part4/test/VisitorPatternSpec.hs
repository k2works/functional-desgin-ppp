-- |
-- Module      : VisitorPatternSpec
-- Description : Tests for Visitor pattern

module VisitorPatternSpec (spec) where

import Test.Hspec
import VisitorPattern

spec :: Spec
spec = do
  describe "Shape Visitors" $ do
    describe "shapeToJson" $ do
      it "converts circle to JSON" $ do
        let circle = Circle (Point 10 20) 5
        shapeToJson circle `shouldBe` "{\"type\":\"circle\",\"center\":[10.0,20.0],\"radius\":5.0}"
      
      it "converts square to JSON" $ do
        let square = Square (Point 0 0) 10
        shapeToJson square `shouldBe` "{\"type\":\"square\",\"topLeft\":[0.0,0.0],\"side\":10.0}"
      
      it "converts rectangle to JSON" $ do
        let rect = Rectangle (Point 5 10) 20 30
        shapeToJson rect `shouldBe` "{\"type\":\"rectangle\",\"topLeft\":[5.0,10.0],\"width\":20.0,\"height\":30.0}"
    
    describe "shapeToXml" $ do
      it "converts circle to XML" $ do
        let circle = Circle (Point 10 20) 5
        shapeToXml circle `shouldBe` "<circle><center x=\"10.0\" y=\"20.0\"/><radius>5.0</radius></circle>"
      
      it "converts square to XML" $ do
        let square = Square (Point 0 0) 10
        shapeToXml square `shouldBe` "<square><topLeft x=\"0.0\" y=\"0.0\"/><side>10.0</side></square>"
      
      it "converts rectangle to XML" $ do
        let rect = Rectangle (Point 5 10) 20 30
        shapeToXml rect `shouldBe` "<rectangle><topLeft x=\"5.0\" y=\"10.0\"/><width>20.0</width><height>30.0</height></rectangle>"
    
    describe "shapeArea" $ do
      it "calculates circle area" $ do
        let circle = Circle (Point 0 0) 5
        shapeArea circle `shouldBe` (pi * 25)
      
      it "calculates square area" $ do
        let square = Square (Point 0 0) 4
        shapeArea square `shouldBe` 16
      
      it "calculates rectangle area" $ do
        let rect = Rectangle (Point 0 0) 5 10
        shapeArea rect `shouldBe` 50
    
    describe "shapePerimeter" $ do
      it "calculates circle perimeter" $ do
        let circle = Circle (Point 0 0) 5
        shapePerimeter circle `shouldBe` (2 * pi * 5)
      
      it "calculates square perimeter" $ do
        let square = Square (Point 0 0) 4
        shapePerimeter square `shouldBe` 16
      
      it "calculates rectangle perimeter" $ do
        let rect = Rectangle (Point 0 0) 5 10
        shapePerimeter rect `shouldBe` 30
    
    describe "shapeBoundingBox" $ do
      it "calculates circle bounding box" $ do
        let circle = Circle (Point 10 10) 5
        shapeBoundingBox circle `shouldBe` (5, 5, 15, 15)
      
      it "calculates square bounding box" $ do
        let square = Square (Point 0 0) 10
        shapeBoundingBox square `shouldBe` (0, 0, 10, 10)
      
      it "calculates rectangle bounding box" $ do
        let rect = Rectangle (Point 5 10) 20 30
        shapeBoundingBox rect `shouldBe` (5, 10, 25, 40)

  describe "Visitor Composition" $ do
    describe "visitShapes" $ do
      it "applies visitor to all shapes" $ do
        let shapes = [Circle (Point 0 0) 1, Square (Point 0 0) 2]
        visitShapes shapeArea shapes `shouldBe` [pi, 4]
    
    describe "totalArea" $ do
      it "calculates total area of shapes" $ do
        let shapes = [Circle (Point 0 0) 1, Square (Point 0 0) 2]
        totalArea shapes `shouldBe` (pi + 4)
      
      it "returns 0 for empty list" $ do
        totalArea [] `shouldBe` 0
    
    describe "totalPerimeter" $ do
      it "calculates total perimeter of shapes" $ do
        let shapes = [Square (Point 0 0) 2, Rectangle (Point 0 0) 3 4]
        totalPerimeter shapes `shouldBe` (8 + 14)

  describe "Expression Visitors" $ do
    describe "evaluate" $ do
      it "evaluates numeric literal" $ do
        evaluate [] (Num 42) `shouldBe` Just 42
      
      it "evaluates variable with binding" $ do
        evaluate [("x", 10)] (Var "x") `shouldBe` Just 10
      
      it "returns Nothing for undefined variable" $ do
        evaluate [] (Var "x") `shouldBe` Nothing
      
      it "evaluates addition" $ do
        evaluate [] (Add (Num 2) (Num 3)) `shouldBe` Just 5
      
      it "evaluates subtraction" $ do
        evaluate [] (Sub (Num 10) (Num 3)) `shouldBe` Just 7
      
      it "evaluates multiplication" $ do
        evaluate [] (Mul (Num 4) (Num 5)) `shouldBe` Just 20
      
      it "evaluates division" $ do
        evaluate [] (Div (Num 20) (Num 4)) `shouldBe` Just 5
      
      it "returns Nothing for division by zero" $ do
        evaluate [] (Div (Num 10) (Num 0)) `shouldBe` Nothing
      
      it "evaluates negation" $ do
        evaluate [] (Neg (Num 5)) `shouldBe` Just (-5)
      
      it "evaluates complex expression with variables" $ do
        let env = [("x", 2), ("y", 3)]
        evaluate env (Add (Mul (Var "x") (Var "y")) (Num 1)) `shouldBe` Just 7
    
    describe "prettyPrint" $ do
      it "prints numeric literal" $ do
        prettyPrint (Num 42) `shouldBe` "42.0"
      
      it "prints variable" $ do
        prettyPrint (Var "x") `shouldBe` "x"
      
      it "prints addition" $ do
        prettyPrint (Add (Num 1) (Num 2)) `shouldBe` "(1.0 + 2.0)"
      
      it "prints complex expression" $ do
        prettyPrint (Mul (Add (Var "x") (Num 1)) (Var "y")) 
          `shouldBe` "((x + 1.0) * y)"
      
      it "prints negation" $ do
        prettyPrint (Neg (Var "x")) `shouldBe` "-x"
    
    describe "exprVariables" $ do
      it "returns empty for numeric literal" $ do
        exprVariables (Num 42) `shouldBe` []
      
      it "returns variable name" $ do
        exprVariables (Var "x") `shouldBe` ["x"]
      
      it "returns unique variables from expression" $ do
        exprVariables (Add (Var "x") (Mul (Var "y") (Var "x"))) 
          `shouldBe` ["x", "y"]
    
    describe "exprDepth" $ do
      it "returns 1 for literal" $ do
        exprDepth (Num 42) `shouldBe` 1
      
      it "returns 1 for variable" $ do
        exprDepth (Var "x") `shouldBe` 1
      
      it "calculates depth for binary operation" $ do
        exprDepth (Add (Num 1) (Num 2)) `shouldBe` 2
      
      it "calculates depth for nested expression" $ do
        exprDepth (Add (Num 1) (Mul (Num 2) (Num 3))) `shouldBe` 3
    
    describe "simplify" $ do
      it "simplifies x + 0 to x" $ do
        simplify (Add (Var "x") (Num 0)) `shouldBe` Var "x"
      
      it "simplifies 0 + x to x" $ do
        simplify (Add (Num 0) (Var "x")) `shouldBe` Var "x"
      
      it "simplifies x - 0 to x" $ do
        simplify (Sub (Var "x") (Num 0)) `shouldBe` Var "x"
      
      it "simplifies x - x to 0" $ do
        simplify (Sub (Var "x") (Var "x")) `shouldBe` Num 0
      
      it "simplifies x * 0 to 0" $ do
        simplify (Mul (Var "x") (Num 0)) `shouldBe` Num 0
      
      it "simplifies 0 * x to 0" $ do
        simplify (Mul (Num 0) (Var "x")) `shouldBe` Num 0
      
      it "simplifies x * 1 to x" $ do
        simplify (Mul (Var "x") (Num 1)) `shouldBe` Var "x"
      
      it "simplifies 1 * x to x" $ do
        simplify (Mul (Num 1) (Var "x")) `shouldBe` Var "x"
      
      it "simplifies 0 / x to 0" $ do
        simplify (Div (Num 0) (Var "x")) `shouldBe` Num 0
      
      it "simplifies x / 1 to x" $ do
        simplify (Div (Var "x") (Num 1)) `shouldBe` Var "x"
      
      it "simplifies double negation" $ do
        simplify (Neg (Neg (Var "x"))) `shouldBe` Var "x"
      
      it "folds constant expressions" $ do
        simplify (Add (Num 2) (Num 3)) `shouldBe` Num 5

  describe "Tree Visitors" $ do
    describe "treeFold" $ do
      it "folds leaf" $ do
        treeFold id (\x _ -> x) (Leaf 42) `shouldBe` 42
      
      it "folds tree to sum" $ do
        let tree = Node 1 [Leaf 2, Leaf 3, Leaf 4]
        treeFold id (\x xs -> x + sum xs) tree `shouldBe` 10
    
    describe "treeMap" $ do
      it "maps function over leaf" $ do
        treeMap (*2) (Leaf 5) `shouldBe` Leaf 10
      
      it "maps function over tree" $ do
        let tree = Node 1 [Leaf 2, Leaf 3]
        treeMap (*2) tree `shouldBe` Node 2 [Leaf 4, Leaf 6]
    
    describe "treeSize" $ do
      it "returns 1 for leaf" $ do
        treeSize (Leaf 42) `shouldBe` 1
      
      it "counts all nodes" $ do
        let tree = Node 1 [Leaf 2, Node 3 [Leaf 4, Leaf 5]]
        treeSize tree `shouldBe` 5
    
    describe "treeDepth" $ do
      it "returns 1 for leaf" $ do
        treeDepth (Leaf 42) `shouldBe` 1
      
      it "calculates depth correctly" $ do
        let tree = Node 1 [Leaf 2, Node 3 [Leaf 4]]
        treeDepth tree `shouldBe` 3
      
      it "handles node with no children" $ do
        treeDepth (Node 1 []) `shouldBe` 1
    
    describe "treeToList" $ do
      it "converts leaf to singleton list" $ do
        treeToList (Leaf 42) `shouldBe` [42]
      
      it "converts tree to preorder list" $ do
        let tree = Node 1 [Leaf 2, Node 3 [Leaf 4, Leaf 5]]
        treeToList tree `shouldBe` [1, 2, 3, 4, 5]
