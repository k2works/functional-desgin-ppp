-- |
-- Module      : AbstractFactoryPatternSpec
-- Description : Tests for Abstract Factory pattern

module AbstractFactoryPatternSpec (spec) where

import Test.Hspec
import AbstractFactoryPattern

spec :: Spec
spec = do
  describe "Shape Factory" $ do
    describe "StandardFactory" $ do
      let factory = StandardFactory
      
      it "creates circle without style" $ do
        let circle = createCircle factory (Point 10 20) 5
        circle `shouldBe` Circle (Point 10 20) 5 (ShapeStyle Nothing Nothing Nothing)
      
      it "creates square without style" $ do
        let square = createSquare factory (Point 0 0) 10
        square `shouldBe` Square (Point 0 0) 10 (ShapeStyle Nothing Nothing Nothing)
      
      it "creates rectangle without style" $ do
        let rect = createRectangle factory (Point 5 10) 20 30
        rect `shouldBe` Rectangle (Point 5 10) 20 30 (ShapeStyle Nothing Nothing Nothing)
    
    describe "OutlinedFactory" $ do
      let factory = makeOutlinedFactory "black" 2.0
      
      it "creates circle with outline" $ do
        let circle = createCircle factory (Point 10 20) 5
        case circle of
          Circle _ _ style -> do
            styleOutlineColor style `shouldBe` Just "black"
            styleOutlineWidth style `shouldBe` Just 2.0
            styleFillColor style `shouldBe` Nothing
          _ -> expectationFailure "Expected Circle"
      
      it "creates square with outline" $ do
        let square = createSquare factory (Point 0 0) 10
        case square of
          Square _ _ style -> do
            styleOutlineColor style `shouldBe` Just "black"
            styleOutlineWidth style `shouldBe` Just 2.0
          _ -> expectationFailure "Expected Square"
      
      it "creates rectangle with outline" $ do
        let rect = createRectangle factory (Point 5 10) 20 30
        case rect of
          Rectangle _ _ _ style -> do
            styleOutlineColor style `shouldBe` Just "black"
            styleOutlineWidth style `shouldBe` Just 2.0
          _ -> expectationFailure "Expected Rectangle"
    
    describe "FilledFactory" $ do
      let factory = makeFilledFactory "red"
      
      it "creates circle with fill" $ do
        let circle = createCircle factory (Point 10 20) 5
        case circle of
          Circle _ _ style -> do
            styleFillColor style `shouldBe` Just "red"
            styleOutlineColor style `shouldBe` Nothing
            styleOutlineWidth style `shouldBe` Nothing
          _ -> expectationFailure "Expected Circle"
      
      it "creates square with fill" $ do
        let square = createSquare factory (Point 0 0) 10
        case square of
          Square _ _ style -> styleFillColor style `shouldBe` Just "red"
          _ -> expectationFailure "Expected Square"
      
      it "creates rectangle with fill" $ do
        let rect = createRectangle factory (Point 5 10) 20 30
        case rect of
          Rectangle _ _ _ style -> styleFillColor style `shouldBe` Just "red"
          _ -> expectationFailure "Expected Rectangle"

  describe "UI Factory" $ do
    describe "WindowsFactory" $ do
      let factory = WindowsFactory
      
      it "creates Windows button" $ do
        let btn = createButton factory "Click Me"
        buttonLabel btn `shouldBe` "Click Me"
        buttonPlatform btn `shouldBe` "windows"
      
      it "creates Windows text field" $ do
        let tf = createTextField factory "Enter name"
        textFieldPlaceholder tf `shouldBe` "Enter name"
        textFieldPlatform tf `shouldBe` "windows"
      
      it "creates Windows checkbox" $ do
        let cb = createCheckBox factory "Accept" True
        checkBoxLabel cb `shouldBe` "Accept"
        checkBoxChecked cb `shouldBe` True
        checkBoxPlatform cb `shouldBe` "windows"
    
    describe "MacOSFactory" $ do
      let factory = MacOSFactory
      
      it "creates MacOS button" $ do
        let btn = createButton factory "OK"
        buttonPlatform btn `shouldBe` "macos"
      
      it "creates MacOS text field" $ do
        let tf = createTextField factory "Search"
        textFieldPlatform tf `shouldBe` "macos"
      
      it "creates MacOS checkbox" $ do
        let cb = createCheckBox factory "Remember" False
        checkBoxPlatform cb `shouldBe` "macos"
    
    describe "LinuxFactory" $ do
      let factory = LinuxFactory
      
      it "creates Linux button" $ do
        let btn = createButton factory "Submit"
        buttonPlatform btn `shouldBe` "linux"
      
      it "creates Linux text field" $ do
        let tf = createTextField factory "Path"
        textFieldPlatform tf `shouldBe` "linux"
      
      it "creates Linux checkbox" $ do
        let cb = createCheckBox factory "Enable" True
        checkBoxPlatform cb `shouldBe` "linux"

  describe "Rendering" $ do
    describe "renderButton" $ do
      it "renders Windows button with brackets" $ do
        let btn = Button "OK" "windows"
        renderButton btn `shouldBe` "[OK]"
      
      it "renders MacOS button with parentheses" $ do
        let btn = Button "OK" "macos"
        renderButton btn `shouldBe` "(OK)"
      
      it "renders Linux button with angle brackets" $ do
        let btn = Button "OK" "linux"
        renderButton btn `shouldBe` "<OK>"
    
    describe "renderTextField" $ do
      it "renders Windows text field" $ do
        let tf = TextField "Name" "windows"
        renderTextField tf `shouldBe` "[____Name____]"
      
      it "renders MacOS text field" $ do
        let tf = TextField "Name" "macos"
        renderTextField tf `shouldBe` "(____Name____)"
      
      it "renders Linux text field" $ do
        let tf = TextField "Name" "linux"
        renderTextField tf `shouldBe` "<____Name____>"
    
    describe "renderCheckBox" $ do
      it "renders unchecked Windows checkbox" $ do
        let cb = CheckBox "Option" False "windows"
        renderCheckBox cb `shouldBe` "[ ] Option"
      
      it "renders checked Windows checkbox" $ do
        let cb = CheckBox "Option" True "windows"
        renderCheckBox cb `shouldBe` "[X] Option"
      
      it "renders unchecked MacOS checkbox" $ do
        let cb = CheckBox "Option" False "macos"
        renderCheckBox cb `shouldBe` "( ) Option"
      
      it "renders checked MacOS checkbox" $ do
        let cb = CheckBox "Option" True "macos"
        renderCheckBox cb `shouldBe` "(X) Option"
      
      it "renders unchecked Linux checkbox" $ do
        let cb = CheckBox "Option" False "linux"
        renderCheckBox cb `shouldBe` "< > Option"
      
      it "renders checked Linux checkbox" $ do
        let cb = CheckBox "Option" True "linux"
        renderCheckBox cb `shouldBe` "<X> Option"

  describe "Form Creation" $ do
    it "creates form with Windows factory" $ do
      let form = createForm WindowsFactory
      buttonPlatform (formButton form) `shouldBe` "windows"
      textFieldPlatform (formTextField form) `shouldBe` "windows"
      checkBoxPlatform (formCheckBox form) `shouldBe` "windows"
      buttonLabel (formButton form) `shouldBe` "Submit"
      textFieldPlaceholder (formTextField form) `shouldBe` "Email"
      checkBoxLabel (formCheckBox form) `shouldBe` "Subscribe"
    
    it "creates form with MacOS factory" $ do
      let form = createForm MacOSFactory
      buttonPlatform (formButton form) `shouldBe` "macos"
      textFieldPlatform (formTextField form) `shouldBe` "macos"
      checkBoxPlatform (formCheckBox form) `shouldBe` "macos"
    
    it "creates form with Linux factory" $ do
      let form = createForm LinuxFactory
      buttonPlatform (formButton form) `shouldBe` "linux"
      textFieldPlatform (formTextField form) `shouldBe` "linux"
      checkBoxPlatform (formCheckBox form) `shouldBe` "linux"
