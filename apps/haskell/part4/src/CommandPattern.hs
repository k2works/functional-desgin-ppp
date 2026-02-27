{-# LANGUAGE GADTs #-}

-- |
-- Module      : CommandPattern
-- Description : Command pattern implementation in Haskell
-- 
-- This module demonstrates the Command pattern using various examples:
-- - Text commands: Insert, Delete, Replace
-- - Canvas commands: AddShape, MoveShape, DeleteShape
-- - Command executor with Undo/Redo support
-- - Macro commands for batching

module CommandPattern
  ( -- * Text Commands
    TextCommand(..)
  , insertCommand
  , deleteCommand
  , replaceCommand
  , executeTextCmd
  , undoTextCmd
  
  -- * Canvas Types
  , CanvasShape(..)
  , Canvas(..)
  , emptyCanvas
  
  -- * Canvas Commands
  , CanvasCommand(..)
  , addShapeCommand
  , moveShapeCommand
  , deleteShapeCommand
  , executeCanvasCmd
  , undoCanvasCmd
  
  -- * Command Executor
  , CommandExecutor(..)
  , makeExecutor
  , executeCommand
  , undoCommand
  , redoCommand
  , canUndo
  , canRedo
  , getState
  
  -- * Batch Processing
  , executeBatch
  , undoAll
  
  -- * Macro Commands
  , MacroCommand(..)
  , makeMacro
  , executeMacro
  , undoMacro
  ) where



-- ============================================================
-- Text Commands
-- ============================================================

-- | Text editing commands
data TextCommand
  = InsertCmd Int String      -- ^ Insert text at position
  | DeleteCmd Int Int String  -- ^ Delete from start to end, storing deleted text
  | ReplaceCmd Int String String  -- ^ Replace old text with new at position
  deriving (Show, Eq)

-- | Create an insert command
insertCommand :: Int -> String -> TextCommand
insertCommand = InsertCmd

-- | Create a delete command
deleteCommand :: Int -> Int -> String -> TextCommand
deleteCommand = DeleteCmd

-- | Create a replace command
replaceCommand :: Int -> String -> String -> TextCommand
replaceCommand = ReplaceCmd

-- | Execute a text command
executeTextCmd :: TextCommand -> String -> String
executeTextCmd cmd doc = case cmd of
  InsertCmd pos text ->
    let (before, after) = splitAt pos doc
    in before ++ text ++ after
  
  DeleteCmd start end _ ->
    let (before, rest) = splitAt start doc
        after = drop (end - start) rest
    in before ++ after
  
  ReplaceCmd pos oldText newText ->
    let (before, rest) = splitAt pos doc
        after = drop (length oldText) rest
    in before ++ newText ++ after

-- | Undo a text command
undoTextCmd :: TextCommand -> String -> String
undoTextCmd cmd doc = case cmd of
  InsertCmd pos text ->
    let (before, rest) = splitAt pos doc
        after = drop (length text) rest
    in before ++ after
  
  DeleteCmd start _ deletedText ->
    let (before, after) = splitAt start doc
    in before ++ deletedText ++ after
  
  ReplaceCmd pos oldText newText ->
    let (before, rest) = splitAt pos doc
        after = drop (length newText) rest
    in before ++ oldText ++ after

-- ============================================================
-- Canvas Types
-- ============================================================

-- | Shape on canvas
data CanvasShape = CanvasShape
  { shapeId :: String
  , shapeType :: String
  , shapeX :: Double
  , shapeY :: Double
  } deriving (Show, Eq)

-- | Canvas with shapes
data Canvas = Canvas
  { canvasShapes :: [CanvasShape]
  } deriving (Show, Eq)

-- | Create an empty canvas
emptyCanvas :: Canvas
emptyCanvas = Canvas []

-- ============================================================
-- Canvas Commands
-- ============================================================

-- | Canvas editing commands
data CanvasCommand
  = AddShapeCmd CanvasShape           -- ^ Add a shape
  | MoveShapeCmd String Double Double -- ^ Move shape by (dx, dy)
  | DeleteShapeCmd CanvasShape        -- ^ Delete a shape (store for undo)
  deriving (Show, Eq)

-- | Create an add shape command
addShapeCommand :: CanvasShape -> CanvasCommand
addShapeCommand = AddShapeCmd

-- | Create a move shape command
moveShapeCommand :: String -> Double -> Double -> CanvasCommand
moveShapeCommand = MoveShapeCmd

-- | Create a delete shape command
deleteShapeCommand :: CanvasShape -> CanvasCommand
deleteShapeCommand = DeleteShapeCmd

-- | Execute a canvas command
executeCanvasCmd :: CanvasCommand -> Canvas -> Canvas
executeCanvasCmd cmd canvas = case cmd of
  AddShapeCmd shape ->
    canvas { canvasShapes = canvasShapes canvas ++ [shape] }
  
  MoveShapeCmd sid dx dy ->
    canvas { canvasShapes = map moveShape (canvasShapes canvas) }
    where
      moveShape s
        | shapeId s == sid = s { shapeX = shapeX s + dx, shapeY = shapeY s + dy }
        | otherwise = s
  
  DeleteShapeCmd shape ->
    canvas { canvasShapes = filter (\s -> shapeId s /= shapeId shape) (canvasShapes canvas) }

-- | Undo a canvas command
undoCanvasCmd :: CanvasCommand -> Canvas -> Canvas
undoCanvasCmd cmd canvas = case cmd of
  AddShapeCmd shape ->
    canvas { canvasShapes = filter (\s -> shapeId s /= shapeId shape) (canvasShapes canvas) }
  
  MoveShapeCmd sid dx dy ->
    canvas { canvasShapes = map moveBack (canvasShapes canvas) }
    where
      moveBack s
        | shapeId s == sid = s { shapeX = shapeX s - dx, shapeY = shapeY s - dy }
        | otherwise = s
  
  DeleteShapeCmd shape ->
    canvas { canvasShapes = canvasShapes canvas ++ [shape] }

-- ============================================================
-- Generic Command Executor
-- ============================================================

-- | Command executor with undo/redo support
data CommandExecutor cmd state = CommandExecutor
  { execState :: state
  , undoStack :: [cmd]
  , redoStack :: [cmd]
  } deriving (Show, Eq)

-- | Create a new command executor
makeExecutor :: state -> CommandExecutor cmd state
makeExecutor initialState = CommandExecutor
  { execState = initialState
  , undoStack = []
  , redoStack = []
  }

-- | Execute a command
executeCommand :: (cmd -> state -> state) -> cmd -> CommandExecutor cmd state -> CommandExecutor cmd state
executeCommand execFn cmd executor = CommandExecutor
  { execState = execFn cmd (execState executor)
  , undoStack = cmd : undoStack executor
  , redoStack = []  -- Clear redo stack on new command
  }

-- | Undo the last command
undoCommand :: (cmd -> state -> state) -> CommandExecutor cmd state -> CommandExecutor cmd state
undoCommand undoFn executor = case undoStack executor of
  [] -> executor
  (cmd:rest) -> CommandExecutor
    { execState = undoFn cmd (execState executor)
    , undoStack = rest
    , redoStack = cmd : redoStack executor
    }

-- | Redo the last undone command
redoCommand :: (cmd -> state -> state) -> CommandExecutor cmd state -> CommandExecutor cmd state
redoCommand execFn executor = case redoStack executor of
  [] -> executor
  (cmd:rest) -> CommandExecutor
    { execState = execFn cmd (execState executor)
    , undoStack = cmd : undoStack executor
    , redoStack = rest
    }

-- | Check if undo is possible
canUndo :: CommandExecutor cmd state -> Bool
canUndo = not . null . undoStack

-- | Check if redo is possible
canRedo :: CommandExecutor cmd state -> Bool
canRedo = not . null . redoStack

-- | Get the current state
getState :: CommandExecutor cmd state -> state
getState = execState

-- ============================================================
-- Batch Processing
-- ============================================================

-- | Execute multiple commands in batch
executeBatch :: (cmd -> state -> state) -> [cmd] -> CommandExecutor cmd state -> CommandExecutor cmd state
executeBatch execFn cmds executor = foldl (flip (executeCommand execFn)) executor cmds

-- | Undo all commands
undoAll :: (cmd -> state -> state) -> CommandExecutor cmd state -> CommandExecutor cmd state
undoAll undoFn executor
  | canUndo executor = undoAll undoFn (undoCommand undoFn executor)
  | otherwise = executor

-- ============================================================
-- Macro Commands
-- ============================================================

-- | Macro command containing multiple commands
newtype MacroCommand cmd = MacroCommand { macroCommands :: [cmd] }
  deriving (Show, Eq)

-- | Create a macro command
makeMacro :: [cmd] -> MacroCommand cmd
makeMacro = MacroCommand

-- | Execute a macro command
executeMacro :: (cmd -> state -> state) -> MacroCommand cmd -> state -> state
executeMacro execFn macro state = foldl (flip execFn) state (macroCommands macro)

-- | Undo a macro command (commands in reverse order)
undoMacro :: (cmd -> state -> state) -> MacroCommand cmd -> state -> state
undoMacro undoFn macro state = foldl (flip undoFn) state (reverse $ macroCommands macro)
