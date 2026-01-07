module CompositePatternSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import qualified Data.Map.Strict as Map

import CompositePattern

spec :: Spec
spec = do
  shapeSpec
  switchableSpec
  fileSystemSpec
  menuItemSpec
  expressionSpec
  organizationSpec

-- ============================================================
-- Shape Tests
-- ============================================================

shapeSpec :: Spec
shapeSpec = describe "Shape" $ do
  describe "Circle" $ do
    it "should translate correctly" $ do
      let circle = Circle (Point 10 10) 5
          translated = translateShape 5 5 circle
      translated `shouldBe` Circle (Point 15 15) 5

    it "should scale correctly" $ do
      let circle = Circle (Point 10 10) 5
          scaled = scaleShape 2 circle
      scaled `shouldBe` Circle (Point 10 10) 10

    it "should calculate area correctly" $ do
      let circle = Circle (Point 0 0) 5
      shapeArea circle `shouldBe` pi * 25

  describe "Square" $ do
    it "should translate correctly" $ do
      let square = Square (Point 0 0) 10
          translated = translateShape 3 4 square
      translated `shouldBe` Square (Point 3 4) 10

    it "should scale correctly" $ do
      let square = Square (Point 0 0) 10
          scaled = scaleShape 2 square
      scaled `shouldBe` Square (Point 0 0) 20

    it "should calculate area correctly" $ do
      let square = Square (Point 0 0) 10
      shapeArea square `shouldBe` 100

  describe "Rectangle" $ do
    it "should translate correctly" $ do
      let rect = Rectangle (Point 0 0) 10 5
          translated = translateShape 2 3 rect
      translated `shouldBe` Rectangle (Point 2 3) 10 5

    it "should scale correctly" $ do
      let rect = Rectangle (Point 0 0) 10 5
          scaled = scaleShape 2 rect
      scaled `shouldBe` Rectangle (Point 0 0) 20 10

    it "should calculate area correctly" $ do
      let rect = Rectangle (Point 0 0) 10 5
      shapeArea rect `shouldBe` 50

  describe "CompositeShape" $ do
    it "should create empty composite" $ do
      emptyComposite `shouldBe` CompositeShape []

    it "should add shapes to composite" $ do
      let circle = Circle (Point 0 0) 5
          square = Square (Point 10 10) 10
          composite = addShape square (addShape circle emptyComposite)
      composite `shouldBe` CompositeShape [circle, square]

    it "should translate all children" $ do
      let circle = Circle (Point 0 0) 5
          square = Square (Point 10 10) 10
          composite = addShape square (addShape circle emptyComposite)
          translated = translateShape 5 5 composite
      translated `shouldBe` CompositeShape 
        [ Circle (Point 5 5) 5
        , Square (Point 15 15) 10
        ]

    it "should scale all children" $ do
      let circle = Circle (Point 0 0) 5
          square = Square (Point 10 10) 10
          composite = addShape square (addShape circle emptyComposite)
          scaled = scaleShape 2 composite
      scaled `shouldBe` CompositeShape 
        [ Circle (Point 0 0) 10
        , Square (Point 10 10) 20
        ]

    it "should calculate total area" $ do
      let circle = Circle (Point 0 0) 5  -- area = pi * 25
          square = Square (Point 0 0) 10  -- area = 100
          composite = addShape square (addShape circle emptyComposite)
      shapeArea composite `shouldBe` (pi * 25 + 100)

    it "should support nested composites" $ do
      let circle = Circle (Point 0 0) 5
          square = Square (Point 0 0) 10
          inner = addShape square (addShape circle emptyComposite)
          outer = addShape inner emptyComposite
          translated = translateShape 1 1 outer
      case translated of
        CompositeShape [CompositeShape [Circle p1 _, Square p2 _]] -> do
          p1 `shouldBe` Point 1 1
          p2 `shouldBe` Point 1 1
        _ -> expectationFailure "Unexpected structure"

-- ============================================================
-- Switchable Tests
-- ============================================================

switchableSpec :: Spec
switchableSpec = describe "Switchable" $ do
  describe "Light" $ do
    it "should turn on" $ do
      let light = Light "Ceiling" False
          onLight = turnOn light
      onLight `shouldBe` Light "Ceiling" True
      isOn onLight `shouldBe` True

    it "should turn off" $ do
      let light = Light "Ceiling" True
          offLight = turnOff light
      offLight `shouldBe` Light "Ceiling" False
      isOn offLight `shouldBe` False

  describe "DimmableLight" $ do
    it "should turn on to max intensity" $ do
      let light = DimmableLight "Bedside" 0
          onLight = turnOn light
      onLight `shouldBe` DimmableLight "Bedside" 100
      isOn onLight `shouldBe` True

    it "should turn off to zero intensity" $ do
      let light = DimmableLight "Bedside" 50
          offLight = turnOff light
      offLight `shouldBe` DimmableLight "Bedside" 0
      isOn offLight `shouldBe` False

  describe "Fan" $ do
    it "should turn on" $ do
      let fan = Fan "CeilingFan" False 0
          onFan = turnOn fan
      onFan `shouldBe` Fan "CeilingFan" True 1
      isOn onFan `shouldBe` True

    it "should turn off but preserve speed" $ do
      let fan = Fan "CeilingFan" True 3
          offFan = turnOff fan
      offFan `shouldBe` Fan "CeilingFan" False 3
      isOn offFan `shouldBe` False

  describe "CompositeSwitchable" $ do
    it "should create empty composite" $ do
      let composite = emptySwitchableComposite "Room"
      composite `shouldBe` CompositeSwitchable "Room" []

    it "should add switchables" $ do
      let light = Light "Ceiling" False
          fan = Fan "Fan" False 0
          composite = addSwitchable fan (addSwitchable light (emptySwitchableComposite "Room"))
      composite `shouldBe` CompositeSwitchable "Room" [light, fan]

    it "should turn on all children" $ do
      let light = Light "Ceiling" False
          dimmable = DimmableLight "Lamp" 0
          composite = addSwitchable dimmable (addSwitchable light (emptySwitchableComposite "Room"))
          onComposite = turnOn composite
      onComposite `shouldBe` CompositeSwitchable "Room" 
        [ Light "Ceiling" True
        , DimmableLight "Lamp" 100
        ]
      isOn onComposite `shouldBe` True

    it "should turn off all children" $ do
      let light = Light "Ceiling" True
          dimmable = DimmableLight "Lamp" 100
          composite = addSwitchable dimmable (addSwitchable light (emptySwitchableComposite "Room"))
          offComposite = turnOff composite
      offComposite `shouldBe` CompositeSwitchable "Room" 
        [ Light "Ceiling" False
        , DimmableLight "Lamp" 0
        ]
      isOn offComposite `shouldBe` False

    it "should report isOn if any child is on" $ do
      let light = Light "Ceiling" False
          dimmable = DimmableLight "Lamp" 50
          composite = addSwitchable dimmable (addSwitchable light (emptySwitchableComposite "Room"))
      isOn composite `shouldBe` True

-- ============================================================
-- FileSystem Tests
-- ============================================================

fileSystemSpec :: Spec
fileSystemSpec = describe "FileSystem" $ do
  describe "File" $ do
    it "should have correct size" $ do
      let file = File "readme.txt" 1024 ".txt"
      fileSize file `shouldBe` 1024

    it "should count as 1 file" $ do
      let file = File "readme.txt" 1024 ".txt"
      fileCount file `shouldBe` 1

  describe "Directory" $ do
    it "should calculate total size" $ do
      let readme = File "readme.txt" 1024 ".txt"
          config = File "config.json" 512 ".json"
          dir = Directory "project" [readme, config]
      fileSize dir `shouldBe` 1536

    it "should count total files" $ do
      let readme = File "readme.txt" 1024 ".txt"
          config = File "config.json" 512 ".json"
          src = Directory "src" 
            [ File "main.fs" 2048 ".fs"
            , File "util.fs" 1024 ".fs"
            ]
          root = Directory "project" [readme, config, src]
      fileCount root `shouldBe` 4

    it "should find files by extension" $ do
      let readme = File "readme.txt" 1024 ".txt"
          config = File "config.json" 512 ".json"
          src = Directory "src" 
            [ File "main.fs" 2048 ".fs"
            , File "util.fs" 1024 ".fs"
            ]
          root = Directory "project" [readme, config, src]
          fsFiles = findByExtension ".fs" root
      length fsFiles `shouldBe` 2

    it "should get all files" $ do
      let readme = File "readme.txt" 1024 ".txt"
          config = File "config.json" 512 ".json"
          src = Directory "src" 
            [ File "main.fs" 2048 ".fs"
            , File "util.fs" 1024 ".fs"
            ]
          root = Directory "project" [readme, config, src]
          files = allFiles root
      length files `shouldBe` 4

    it "should add entries" $ do
      let dir = emptyDirectory "project"
          file = File "readme.txt" 1024 ".txt"
          updated = addEntry file dir
      fileCount updated `shouldBe` 1

-- ============================================================
-- MenuItem Tests
-- ============================================================

menuItemSpec :: Spec
menuItemSpec = describe "MenuItem" $ do
  describe "Item" $ do
    it "should have correct price" $ do
      let burger = Item "Hamburger" 500 "Main"
      menuPrice burger `shouldBe` 500

    it "should count as 1 item" $ do
      let burger = Item "Hamburger" 500 "Main"
      menuItemCount burger `shouldBe` 1

  describe "SetMenu" $ do
    it "should apply discount" $ do
      let burger = Item "Hamburger" 500 "Main"
          fries = Item "Fries" 200 "Side"
          drink = Item "Cola" 150 "Drink"
          setMenu = SetMenu "Lunch Set" [burger, fries, drink] 0.1
      -- Total: 850, with 10% discount: 765
      menuPrice setMenu `shouldBe` 765

    it "should count all items" $ do
      let burger = Item "Hamburger" 500 "Main"
          fries = Item "Fries" 200 "Side"
          drink = Item "Cola" 150 "Drink"
          setMenu = SetMenu "Lunch Set" [burger, fries, drink] 0.1
      menuItemCount setMenu `shouldBe` 3

    it "should create empty set menu" $ do
      let setMenu = emptySetMenu "Special" 0.2
      menuItemCount setMenu `shouldBe` 0

    it "should add items to set menu" $ do
      let setMenu = emptySetMenu "Special" 0.0
          burger = Item "Hamburger" 500 "Main"
          updated = addMenuItem burger setMenu
      menuItemCount updated `shouldBe` 1
      menuPrice updated `shouldBe` 500

-- ============================================================
-- Expression Tests
-- ============================================================

expressionSpec :: Spec
expressionSpec = describe "Expression" $ do
  describe "Number" $ do
    it "should evaluate to its value" $ do
      evaluate (Number 42) `shouldBe` Just 42

  describe "Variable" $ do
    it "should evaluate bound variable" $ do
      evaluate (Variable "x" (Just 10)) `shouldBe` Just 10

    it "should fail for unbound variable" $ do
      evaluate (Variable "x" Nothing) `shouldBe` Nothing

  describe "Add" $ do
    it "should add two numbers" $ do
      evaluate (Add (Number 2) (Number 3)) `shouldBe` Just 5

    it "should simplify x + 0 to x" $ do
      let expr = Add (Variable "x" (Just 5)) (Number 0)
      simplify expr `shouldBe` Variable "x" (Just 5)

    it "should simplify 0 + x to x" $ do
      let expr = Add (Number 0) (Variable "x" (Just 5))
      simplify expr `shouldBe` Variable "x" (Just 5)

    it "should simplify constant addition" $ do
      simplify (Add (Number 2) (Number 3)) `shouldBe` Number 5

  describe "Subtract" $ do
    it "should subtract two numbers" $ do
      evaluate (Subtract (Number 5) (Number 3)) `shouldBe` Just 2

    it "should simplify x - 0 to x" $ do
      simplify (Subtract (Variable "x" (Just 5)) (Number 0)) 
        `shouldBe` Variable "x" (Just 5)

    it "should simplify x - x to 0" $ do
      let x = Variable "x" Nothing
      simplify (Subtract x x) `shouldBe` Number 0

  describe "Multiply" $ do
    it "should multiply two numbers" $ do
      evaluate (Multiply (Number 4) (Number 5)) `shouldBe` Just 20

    it "should simplify x * 0 to 0" $ do
      simplify (Multiply (Variable "x" (Just 5)) (Number 0)) `shouldBe` Number 0

    it "should simplify 0 * x to 0" $ do
      simplify (Multiply (Number 0) (Variable "x" (Just 5))) `shouldBe` Number 0

    it "should simplify x * 1 to x" $ do
      simplify (Multiply (Variable "x" (Just 5)) (Number 1)) 
        `shouldBe` Variable "x" (Just 5)

    it "should simplify 1 * x to x" $ do
      simplify (Multiply (Number 1) (Variable "x" (Just 5))) 
        `shouldBe` Variable "x" (Just 5)

  describe "Divide" $ do
    it "should divide two numbers" $ do
      evaluate (Divide (Number 10) (Number 2)) `shouldBe` Just 5

    it "should return Nothing for division by zero" $ do
      evaluate (Divide (Number 10) (Number 0)) `shouldBe` Nothing

    it "should simplify 0 / x to 0" $ do
      simplify (Divide (Number 0) (Variable "x" (Just 5))) `shouldBe` Number 0

    it "should simplify x / 1 to x" $ do
      simplify (Divide (Variable "x" (Just 5)) (Number 1)) 
        `shouldBe` Variable "x" (Just 5)

  describe "Negate" $ do
    it "should negate a number" $ do
      evaluate (Negate (Number 5)) `shouldBe` Just (-5)

    it "should simplify double negation" $ do
      simplify (Negate (Negate (Variable "x" Nothing))) 
        `shouldBe` Variable "x" Nothing

  describe "Complex expressions" $ do
    it "should evaluate (2 + 3) * 4" $ do
      let expr = Multiply (Add (Number 2) (Number 3)) (Number 4)
      evaluate expr `shouldBe` Just 20

    it "should get variables" $ do
      let expr = Add (Variable "x" Nothing) (Variable "y" Nothing)
      variables expr `shouldBe` ["x", "y"]

    it "should bind variables" $ do
      let expr = Add (Variable "x" Nothing) (Variable "y" Nothing)
          bound = bindVars [("x", 10), ("y", 20)] expr
      evaluate bound `shouldBe` Just 30

-- ============================================================
-- Organization Tests
-- ============================================================

organizationSpec :: Spec
organizationSpec = describe "Organization" $ do
  describe "Employee" $ do
    it "should have correct salary" $ do
      let emp = Employee "Alice" 50000 "Engineer"
      totalSalary emp `shouldBe` 50000

    it "should count as 1 employee" $ do
      let emp = Employee "Alice" 50000 "Engineer"
      employeeCount emp `shouldBe` 1

  describe "Department" $ do
    it "should calculate total salary" $ do
      let alice = Employee "Alice" 50000 "Engineer"
          bob = Employee "Bob" 60000 "Engineer"
          dept = Department "Engineering" (Just "Charlie") [alice, bob]
      totalSalary dept `shouldBe` 110000

    it "should count all employees" $ do
      let alice = Employee "Alice" 50000 "Engineer"
          bob = Employee "Bob" 60000 "Engineer"
          charlie = Employee "Charlie" 70000 "Manager"
          eng = Department "Engineering" (Just "Charlie") [alice, bob]
          company = Department "Company" Nothing [eng, charlie]
      employeeCount company `shouldBe` 3

    it "should find employees by role" $ do
      let alice = Employee "Alice" 50000 "Engineer"
          bob = Employee "Bob" 60000 "Engineer"
          charlie = Employee "Charlie" 70000 "Manager"
          eng = Department "Engineering" (Just "Charlie") [alice, bob]
          company = Department "Company" Nothing [eng, charlie]
          engineers = findByRole "Engineer" company
      length engineers `shouldBe` 2

    it "should create empty department" $ do
      let dept = emptyDepartment "Sales" (Just "Dave")
      employeeCount dept `shouldBe` 0

    it "should add members" $ do
      let dept = emptyDepartment "Sales" Nothing
          emp = Employee "Eve" 45000 "Sales"
          updated = addMember emp dept
      employeeCount updated `shouldBe` 1
