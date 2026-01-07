module CommandPatternSpec (spec) where

import Test.Hspec

import CommandPattern

spec :: Spec
spec = do
  textCommandsSpec
  canvasCommandsSpec
  commandExecutorSpec
  batchProcessingSpec
  macroCommandsSpec

-- ============================================================
-- Text Commands Tests
-- ============================================================

textCommandsSpec :: Spec
textCommandsSpec = describe "Text Commands" $ do
  describe "InsertCommand" $ do
    it "should insert text at position" $ do
      let cmd = insertCommand 5 " World"
      executeTextCmd cmd "Hello" `shouldBe` "Hello World"

    it "should insert at beginning" $ do
      let cmd = insertCommand 0 "Hello "
      executeTextCmd cmd "World" `shouldBe` "Hello World"

    it "should insert at end" $ do
      let cmd = insertCommand 5 "!"
      executeTextCmd cmd "Hello" `shouldBe` "Hello!"

    it "should undo insert" $ do
      let cmd = insertCommand 5 " World"
          doc = executeTextCmd cmd "Hello"
      undoTextCmd cmd doc `shouldBe` "Hello"

  describe "DeleteCommand" $ do
    it "should delete text" $ do
      let cmd = deleteCommand 5 11 " World"
      executeTextCmd cmd "Hello World" `shouldBe` "Hello"

    it "should delete from beginning" $ do
      let cmd = deleteCommand 0 6 "Hello "
      executeTextCmd cmd "Hello World" `shouldBe` "World"

    it "should undo delete" $ do
      let cmd = deleteCommand 5 11 " World"
          doc = executeTextCmd cmd "Hello World"
      undoTextCmd cmd doc `shouldBe` "Hello World"

  describe "ReplaceCommand" $ do
    it "should replace text" $ do
      let cmd = replaceCommand 6 "World" "Universe"
      executeTextCmd cmd "Hello World" `shouldBe` "Hello Universe"

    it "should undo replace" $ do
      let cmd = replaceCommand 6 "World" "Universe"
          doc = executeTextCmd cmd "Hello World"
      undoTextCmd cmd doc `shouldBe` "Hello World"

-- ============================================================
-- Canvas Commands Tests
-- ============================================================

canvasCommandsSpec :: Spec
canvasCommandsSpec = describe "Canvas Commands" $ do
  let shape1 = CanvasShape "shape1" "circle" 10 20
      shape2 = CanvasShape "shape2" "square" 30 40

  describe "AddShapeCommand" $ do
    it "should add shape to canvas" $ do
      let cmd = addShapeCommand shape1
          canvas = executeCanvasCmd cmd emptyCanvas
      length (canvasShapes canvas) `shouldBe` 1

    it "should add multiple shapes" $ do
      let cmd1 = addShapeCommand shape1
          cmd2 = addShapeCommand shape2
          canvas = executeCanvasCmd cmd2 $ executeCanvasCmd cmd1 emptyCanvas
      length (canvasShapes canvas) `shouldBe` 2

    it "should undo add" $ do
      let cmd = addShapeCommand shape1
          canvas = executeCanvasCmd cmd emptyCanvas
          undone = undoCanvasCmd cmd canvas
      length (canvasShapes undone) `shouldBe` 0

  describe "MoveShapeCommand" $ do
    it "should move shape" $ do
      let addCmd = addShapeCommand shape1
          moveCmd = moveShapeCommand "shape1" 5 10
          canvas = executeCanvasCmd moveCmd $ executeCanvasCmd addCmd emptyCanvas
          movedShape = head $ canvasShapes canvas
      shapeX movedShape `shouldBe` 15
      shapeY movedShape `shouldBe` 30

    it "should undo move" $ do
      let addCmd = addShapeCommand shape1
          moveCmd = moveShapeCommand "shape1" 5 10
          canvas = executeCanvasCmd moveCmd $ executeCanvasCmd addCmd emptyCanvas
          undone = undoCanvasCmd moveCmd canvas
          originalShape = head $ canvasShapes undone
      shapeX originalShape `shouldBe` 10
      shapeY originalShape `shouldBe` 20

  describe "DeleteShapeCommand" $ do
    it "should delete shape" $ do
      let addCmd = addShapeCommand shape1
          deleteCmd = deleteShapeCommand shape1
          canvas = executeCanvasCmd deleteCmd $ executeCanvasCmd addCmd emptyCanvas
      length (canvasShapes canvas) `shouldBe` 0

    it "should undo delete" $ do
      let addCmd = addShapeCommand shape1
          deleteCmd = deleteShapeCommand shape1
          canvas = executeCanvasCmd deleteCmd $ executeCanvasCmd addCmd emptyCanvas
          restored = undoCanvasCmd deleteCmd canvas
      length (canvasShapes restored) `shouldBe` 1

-- ============================================================
-- Command Executor Tests
-- ============================================================

commandExecutorSpec :: Spec
commandExecutorSpec = describe "CommandExecutor" $ do
  describe "makeExecutor" $ do
    it "should create executor with initial state" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
      getState executor `shouldBe` "Hello"

    it "should have empty undo stack" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
      canUndo executor `shouldBe` False

  describe "executeCommand" $ do
    it "should execute command and update state" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmd = insertCommand 5 " World"
          updated = executeCommand executeTextCmd cmd executor
      getState updated `shouldBe` "Hello World"

    it "should add command to undo stack" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmd = insertCommand 5 " World"
          updated = executeCommand executeTextCmd cmd executor
      canUndo updated `shouldBe` True

  describe "undoCommand" $ do
    it "should undo last command" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmd = insertCommand 5 " World"
          executed = executeCommand executeTextCmd cmd executor
          undone = undoCommand undoTextCmd executed
      getState undone `shouldBe` "Hello"

    it "should enable redo after undo" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmd = insertCommand 5 " World"
          executed = executeCommand executeTextCmd cmd executor
          undone = undoCommand undoTextCmd executed
      canRedo undone `shouldBe` True

    it "should do nothing with empty undo stack" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          undone = undoCommand undoTextCmd executor
      getState undone `shouldBe` "Hello"

  describe "redoCommand" $ do
    it "should redo last undone command" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmd = insertCommand 5 " World"
          executed = executeCommand executeTextCmd cmd executor
          undone = undoCommand undoTextCmd executed
          redone = redoCommand executeTextCmd undone
      getState redone `shouldBe` "Hello World"

    it "should clear redo stack on new command" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmd1 = insertCommand 5 " World"
          cmd2 = insertCommand 11 "!"
          executed = executeCommand executeTextCmd cmd1 executor
          undone = undoCommand undoTextCmd executed
          newCmd = executeCommand executeTextCmd cmd2 undone
      canRedo newCmd `shouldBe` False

-- ============================================================
-- Batch Processing Tests
-- ============================================================

batchProcessingSpec :: Spec
batchProcessingSpec = describe "Batch Processing" $ do
  describe "executeBatch" $ do
    it "should execute multiple commands" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmds = [insertCommand 5 " World", insertCommand 11 "!"]
          result = executeBatch executeTextCmd cmds executor
      getState result `shouldBe` "Hello World!"

    it "should build undo stack for all commands" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmds = [insertCommand 5 " World", insertCommand 11 "!"]
          result = executeBatch executeTextCmd cmds executor
          undone1 = undoCommand undoTextCmd result
          undone2 = undoCommand undoTextCmd undone1
      getState undone1 `shouldBe` "Hello World"
      getState undone2 `shouldBe` "Hello"

  describe "undoAll" $ do
    it "should undo all commands" $ do
      let executor = makeExecutor "Hello" :: CommandExecutor TextCommand String
          cmds = [insertCommand 5 " World", insertCommand 11 "!"]
          executed = executeBatch executeTextCmd cmds executor
          allUndone = undoAll undoTextCmd executed
      getState allUndone `shouldBe` "Hello"
      canUndo allUndone `shouldBe` False

-- ============================================================
-- Macro Commands Tests
-- ============================================================

macroCommandsSpec :: Spec
macroCommandsSpec = describe "Macro Commands" $ do
  describe "makeMacro" $ do
    it "should create macro from commands" $ do
      let cmds = [insertCommand 5 " World", insertCommand 11 "!"]
          macro = makeMacro cmds
      length (macroCommands macro) `shouldBe` 2

  describe "executeMacro" $ do
    it "should execute all commands in macro" $ do
      let cmds = [insertCommand 5 " World", insertCommand 11 "!"]
          macro = makeMacro cmds
          result = executeMacro executeTextCmd macro "Hello"
      result `shouldBe` "Hello World!"

  describe "undoMacro" $ do
    it "should undo all commands in reverse order" $ do
      let cmds = [insertCommand 5 " World", insertCommand 11 "!"]
          macro = makeMacro cmds
          executed = executeMacro executeTextCmd macro "Hello"
          undone = undoMacro undoTextCmd macro executed
      undone `shouldBe` "Hello"
