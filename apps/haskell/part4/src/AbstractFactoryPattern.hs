-- |
-- Module      : AbstractFactoryPattern
-- Description : Abstract Factory pattern implementation in Haskell
-- 
-- This module demonstrates the Abstract Factory pattern using various examples:
-- - Shape factories: Standard, Outlined, Filled
-- - UI factories: Windows, MacOS, Linux

module AbstractFactoryPattern
  ( -- * Shape Types
    Point(..)
  , ShapeStyle(..)
  , Shape(..)
  
  -- * Shape Factory Type Class
  , ShapeFactory(..)
  
  -- * Standard Factory
  , StandardFactory(..)
  
  -- * Outlined Factory
  , OutlinedFactory(..)
  , makeOutlinedFactory
  
  -- * Filled Factory
  , FilledFactory(..)
  , makeFilledFactory
  
  -- * UI Component Types
  , Button(..)
  , TextField(..)
  , CheckBox(..)
  
  -- * UI Factory Type Class
  , UIFactory(..)
  
  -- * Platform Factories
  , WindowsFactory(..)
  , MacOSFactory(..)
  , LinuxFactory(..)
  
  -- * Rendering
  , renderButton
  , renderTextField
  , renderCheckBox
  
  -- * Form Creation
  , Form(..)
  , createForm
  ) where

-- ============================================================
-- Shape Types
-- ============================================================

-- | 2D Point
data Point = Point Double Double
  deriving (Show, Eq)

-- | Shape style
data ShapeStyle = ShapeStyle
  { styleOutlineColor :: Maybe String
  , styleOutlineWidth :: Maybe Double
  , styleFillColor :: Maybe String
  } deriving (Show, Eq)

-- | Default (empty) style
defaultStyle :: ShapeStyle
defaultStyle = ShapeStyle Nothing Nothing Nothing

-- | Shape with style
data Shape
  = Circle Point Double ShapeStyle
  | Square Point Double ShapeStyle
  | Rectangle Point Double Double ShapeStyle
  deriving (Show, Eq)

-- ============================================================
-- Shape Factory Type Class
-- ============================================================

-- | Abstract factory for creating shapes
class ShapeFactory f where
  createCircle :: f -> Point -> Double -> Shape
  createSquare :: f -> Point -> Double -> Shape
  createRectangle :: f -> Point -> Double -> Double -> Shape

-- ============================================================
-- Standard Factory
-- ============================================================

-- | Standard shape factory (no styling)
data StandardFactory = StandardFactory
  deriving (Show, Eq)

instance ShapeFactory StandardFactory where
  createCircle _ center radius = Circle center radius defaultStyle
  createSquare _ topLeft side = Square topLeft side defaultStyle
  createRectangle _ topLeft width height = Rectangle topLeft width height defaultStyle

-- ============================================================
-- Outlined Factory
-- ============================================================

-- | Factory that creates shapes with outline
data OutlinedFactory = OutlinedFactory
  { ofOutlineColor :: String
  , ofOutlineWidth :: Double
  } deriving (Show, Eq)

-- | Create an outlined factory
makeOutlinedFactory :: String -> Double -> OutlinedFactory
makeOutlinedFactory = OutlinedFactory

instance ShapeFactory OutlinedFactory where
  createCircle f center radius = Circle center radius style
    where style = defaultStyle { styleOutlineColor = Just (ofOutlineColor f)
                                , styleOutlineWidth = Just (ofOutlineWidth f) }
  
  createSquare f topLeft side = Square topLeft side style
    where style = defaultStyle { styleOutlineColor = Just (ofOutlineColor f)
                                , styleOutlineWidth = Just (ofOutlineWidth f) }
  
  createRectangle f topLeft width height = Rectangle topLeft width height style
    where style = defaultStyle { styleOutlineColor = Just (ofOutlineColor f)
                                , styleOutlineWidth = Just (ofOutlineWidth f) }

-- ============================================================
-- Filled Factory
-- ============================================================

-- | Factory that creates shapes with fill color
data FilledFactory = FilledFactory
  { ffFillColor :: String
  } deriving (Show, Eq)

-- | Create a filled factory
makeFilledFactory :: String -> FilledFactory
makeFilledFactory = FilledFactory

instance ShapeFactory FilledFactory where
  createCircle f center radius = Circle center radius style
    where style = defaultStyle { styleFillColor = Just (ffFillColor f) }
  
  createSquare f topLeft side = Square topLeft side style
    where style = defaultStyle { styleFillColor = Just (ffFillColor f) }
  
  createRectangle f topLeft width height = Rectangle topLeft width height style
    where style = defaultStyle { styleFillColor = Just (ffFillColor f) }

-- ============================================================
-- UI Component Types
-- ============================================================

-- | Button component
data Button = Button
  { buttonLabel :: String
  , buttonPlatform :: String
  } deriving (Show, Eq)

-- | Text field component
data TextField = TextField
  { textFieldPlaceholder :: String
  , textFieldPlatform :: String
  } deriving (Show, Eq)

-- | Check box component
data CheckBox = CheckBox
  { checkBoxLabel :: String
  , checkBoxChecked :: Bool
  , checkBoxPlatform :: String
  } deriving (Show, Eq)

-- ============================================================
-- UI Factory Type Class
-- ============================================================

-- | Abstract factory for creating UI components
class UIFactory f where
  createButton :: f -> String -> Button
  createTextField :: f -> String -> TextField
  createCheckBox :: f -> String -> Bool -> CheckBox

-- ============================================================
-- Platform Factories
-- ============================================================

-- | Windows UI factory
data WindowsFactory = WindowsFactory
  deriving (Show, Eq)

instance UIFactory WindowsFactory where
  createButton _ label = Button label "windows"
  createTextField _ placeholder = TextField placeholder "windows"
  createCheckBox _ label checked = CheckBox label checked "windows"

-- | MacOS UI factory
data MacOSFactory = MacOSFactory
  deriving (Show, Eq)

instance UIFactory MacOSFactory where
  createButton _ label = Button label "macos"
  createTextField _ placeholder = TextField placeholder "macos"
  createCheckBox _ label checked = CheckBox label checked "macos"

-- | Linux UI factory
data LinuxFactory = LinuxFactory
  deriving (Show, Eq)

instance UIFactory LinuxFactory where
  createButton _ label = Button label "linux"
  createTextField _ placeholder = TextField placeholder "linux"
  createCheckBox _ label checked = CheckBox label checked "linux"

-- ============================================================
-- Rendering
-- ============================================================

-- | Render a button to string
renderButton :: Button -> String
renderButton btn = case buttonPlatform btn of
  "windows" -> "[" ++ buttonLabel btn ++ "]"
  "macos"   -> "(" ++ buttonLabel btn ++ ")"
  "linux"   -> "<" ++ buttonLabel btn ++ ">"
  _         -> buttonLabel btn

-- | Render a text field to string
renderTextField :: TextField -> String
renderTextField tf = case textFieldPlatform tf of
  "windows" -> "[____" ++ textFieldPlaceholder tf ++ "____]"
  "macos"   -> "(____" ++ textFieldPlaceholder tf ++ "____)"
  "linux"   -> "<____" ++ textFieldPlaceholder tf ++ "____>"
  _         -> textFieldPlaceholder tf

-- | Render a check box to string
renderCheckBox :: CheckBox -> String
renderCheckBox cb = 
  let mark = if checkBoxChecked cb then "X" else " "
  in case checkBoxPlatform cb of
    "windows" -> "[" ++ mark ++ "] " ++ checkBoxLabel cb
    "macos"   -> "(" ++ mark ++ ") " ++ checkBoxLabel cb
    "linux"   -> "<" ++ mark ++ "> " ++ checkBoxLabel cb
    _         -> "[" ++ mark ++ "] " ++ checkBoxLabel cb

-- ============================================================
-- Form Creation
-- ============================================================

-- | Form containing UI components
data Form = Form
  { formButton :: Button
  , formTextField :: TextField
  , formCheckBox :: CheckBox
  } deriving (Show, Eq)

-- | Create a form using a factory
createForm :: UIFactory f => f -> Form
createForm factory = Form
  { formButton = createButton factory "Submit"
  , formTextField = createTextField factory "Email"
  , formCheckBox = createCheckBox factory "Subscribe" False
  }
