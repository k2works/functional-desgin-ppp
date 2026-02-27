defmodule Chapter11Test do
  use ExUnit.Case, async: true

  # ============================================================
  # 1. テキスト操作コマンドのテスト
  # ============================================================

  describe "TextCommands - InsertCommand" do
    alias Chapter11.TextCommands.InsertCommand
    alias Chapter11.Command

    test "creates insert command" do
      cmd = InsertCommand.new(5, " World")
      assert cmd.position == 5
      assert cmd.text == " World"
    end

    test "execute inserts text at position" do
      cmd = InsertCommand.new(5, " World")
      result = Command.execute(cmd, "Hello")
      assert result == "Hello World"
    end

    test "execute inserts at beginning" do
      cmd = InsertCommand.new(0, "Hi ")
      result = Command.execute(cmd, "World")
      assert result == "Hi World"
    end

    test "execute inserts at end" do
      cmd = InsertCommand.new(5, "!")
      result = Command.execute(cmd, "Hello")
      assert result == "Hello!"
    end

    test "undo removes inserted text" do
      cmd = InsertCommand.new(5, " World")
      result = Command.undo(cmd, "Hello World")
      assert result == "Hello"
    end

    test "execute then undo returns original" do
      cmd = InsertCommand.new(5, " World")
      original = "Hello"
      modified = Command.execute(cmd, original)
      restored = Command.undo(cmd, modified)
      assert restored == original
    end
  end

  describe "TextCommands - DeleteCommand" do
    alias Chapter11.TextCommands.DeleteCommand
    alias Chapter11.Command

    test "creates delete command" do
      cmd = DeleteCommand.new(5, 11, " World")
      assert cmd.start_position == 5
      assert cmd.end_position == 11
      assert cmd.deleted_text == " World"
    end

    test "execute deletes text in range" do
      cmd = DeleteCommand.new(5, 11, " World")
      result = Command.execute(cmd, "Hello World")
      assert result == "Hello"
    end

    test "undo restores deleted text" do
      cmd = DeleteCommand.new(5, 11, " World")
      result = Command.undo(cmd, "Hello")
      assert result == "Hello World"
    end

    test "execute then undo returns original" do
      cmd = DeleteCommand.new(5, 11, " World")
      original = "Hello World"
      modified = Command.execute(cmd, original)
      restored = Command.undo(cmd, modified)
      assert restored == original
    end
  end

  describe "TextCommands - ReplaceCommand" do
    alias Chapter11.TextCommands.ReplaceCommand
    alias Chapter11.Command

    test "creates replace command" do
      cmd = ReplaceCommand.new(0, "Hello", "Hi")
      assert cmd.start_position == 0
      assert cmd.old_text == "Hello"
      assert cmd.new_text == "Hi"
    end

    test "execute replaces text" do
      cmd = ReplaceCommand.new(0, "Hello", "Hi")
      result = Command.execute(cmd, "Hello World")
      assert result == "Hi World"
    end

    test "undo restores original text" do
      cmd = ReplaceCommand.new(0, "Hello", "Hi")
      result = Command.undo(cmd, "Hi World")
      assert result == "Hello World"
    end

    test "execute then undo returns original" do
      cmd = ReplaceCommand.new(6, "World", "Elixir")
      original = "Hello World"
      modified = Command.execute(cmd, original)
      assert modified == "Hello Elixir"
      restored = Command.undo(cmd, modified)
      assert restored == original
    end
  end

  # ============================================================
  # 2. キャンバス操作コマンドのテスト
  # ============================================================

  describe "CanvasCommands - Shape" do
    alias Chapter11.CanvasCommands.Shape

    test "creates rectangle" do
      rect = Shape.rectangle("r1", 10, 20, 100, 50, "red")
      assert rect.id == "r1"
      assert rect.type == :rectangle
      assert rect.x == 10
      assert rect.y == 20
      assert rect.width == 100
      assert rect.height == 50
      assert rect.color == "red"
    end

    test "creates circle" do
      circle = Shape.circle("c1", 50, 50, 25, "blue")
      assert circle.id == "c1"
      assert circle.type == :circle
      assert circle.x == 50
      assert circle.y == 50
      assert circle.radius == 25
      assert circle.color == "blue"
    end
  end

  describe "CanvasCommands - AddShapeCommand" do
    alias Chapter11.CanvasCommands.{Canvas, Shape, AddShapeCommand}
    alias Chapter11.Command

    test "execute adds shape to canvas" do
      canvas = Canvas.new()
      shape = Shape.rectangle("r1", 10, 20, 100, 50)
      cmd = AddShapeCommand.new(shape)

      result = Command.execute(cmd, canvas)
      assert length(result.shapes) == 1
      assert hd(result.shapes).id == "r1"
    end

    test "undo removes shape from canvas" do
      shape = Shape.rectangle("r1", 10, 20, 100, 50)
      canvas = Canvas.new([shape])
      cmd = AddShapeCommand.new(shape)

      result = Command.undo(cmd, canvas)
      assert length(result.shapes) == 0
    end

    test "execute then undo returns original" do
      canvas = Canvas.new()
      shape = Shape.rectangle("r1", 10, 20, 100, 50)
      cmd = AddShapeCommand.new(shape)

      modified = Command.execute(cmd, canvas)
      restored = Command.undo(cmd, modified)
      assert restored.shapes == canvas.shapes
    end
  end

  describe "CanvasCommands - MoveShapeCommand" do
    alias Chapter11.CanvasCommands.{Canvas, Shape, MoveShapeCommand}
    alias Chapter11.Command

    test "execute moves shape by dx, dy" do
      shape = Shape.rectangle("r1", 10, 20, 100, 50)
      canvas = Canvas.new([shape])
      cmd = MoveShapeCommand.new("r1", 5, 10)

      result = Command.execute(cmd, canvas)
      moved = hd(result.shapes)
      assert moved.x == 15
      assert moved.y == 30
    end

    test "undo moves shape back" do
      shape = Shape.rectangle("r1", 15, 30, 100, 50)
      canvas = Canvas.new([shape])
      cmd = MoveShapeCommand.new("r1", 5, 10)

      result = Command.undo(cmd, canvas)
      moved = hd(result.shapes)
      assert moved.x == 10
      assert moved.y == 20
    end

    test "only moves matching shape" do
      shape1 = Shape.rectangle("r1", 10, 20, 100, 50)
      shape2 = Shape.rectangle("r2", 50, 60, 80, 40)
      canvas = Canvas.new([shape1, shape2])
      cmd = MoveShapeCommand.new("r1", 5, 10)

      result = Command.execute(cmd, canvas)
      [s1, s2] = result.shapes
      assert s1.x == 15
      assert s2.x == 50  # unchanged
    end
  end

  describe "CanvasCommands - RemoveShapeCommand" do
    alias Chapter11.CanvasCommands.{Canvas, Shape, RemoveShapeCommand}
    alias Chapter11.Command

    test "execute removes shape from canvas" do
      shape = Shape.rectangle("r1", 10, 20, 100, 50)
      canvas = Canvas.new([shape])
      cmd = RemoveShapeCommand.new(shape)

      result = Command.execute(cmd, canvas)
      assert length(result.shapes) == 0
    end

    test "undo restores removed shape" do
      shape = Shape.rectangle("r1", 10, 20, 100, 50)
      canvas = Canvas.new()
      cmd = RemoveShapeCommand.new(shape)

      result = Command.undo(cmd, canvas)
      assert length(result.shapes) == 1
      assert hd(result.shapes).id == "r1"
    end
  end

  describe "CanvasCommands - ChangeColorCommand" do
    alias Chapter11.CanvasCommands.{Canvas, Shape, ChangeColorCommand}
    alias Chapter11.Command

    test "execute changes shape color" do
      shape = Shape.rectangle("r1", 10, 20, 100, 50, "red")
      canvas = Canvas.new([shape])
      cmd = ChangeColorCommand.new("r1", "red", "blue")

      result = Command.execute(cmd, canvas)
      assert hd(result.shapes).color == "blue"
    end

    test "undo restores original color" do
      shape = Shape.rectangle("r1", 10, 20, 100, 50, "blue")
      canvas = Canvas.new([shape])
      cmd = ChangeColorCommand.new("r1", "red", "blue")

      result = Command.undo(cmd, canvas)
      assert hd(result.shapes).color == "red"
    end
  end

  # ============================================================
  # 3. CommandExecutor のテスト
  # ============================================================

  describe "CommandExecutor" do
    alias Chapter11.{CommandExecutor, Command}
    alias Chapter11.TextCommands.InsertCommand

    test "new creates executor with initial state" do
      executor = CommandExecutor.new("Hello")
      assert CommandExecutor.get_state(executor) == "Hello"
    end

    test "execute applies command and updates state" do
      executor = CommandExecutor.new("Hello")
      cmd = InsertCommand.new(5, " World")

      executor = CommandExecutor.execute(executor, cmd)
      assert CommandExecutor.get_state(executor) == "Hello World"
    end

    test "execute adds command to undo stack" do
      executor = CommandExecutor.new("Hello")
      cmd = InsertCommand.new(5, " World")

      executor = CommandExecutor.execute(executor, cmd)
      assert CommandExecutor.can_undo?(executor)
    end

    test "execute clears redo stack" do
      executor = CommandExecutor.new("Hello")
      cmd1 = InsertCommand.new(5, " World")
      cmd2 = InsertCommand.new(11, "!")

      executor = executor
        |> CommandExecutor.execute(cmd1)
        |> CommandExecutor.execute(cmd2)
        |> CommandExecutor.undo()
        |> CommandExecutor.execute(InsertCommand.new(11, "?"))

      refute CommandExecutor.can_redo?(executor)
    end

    test "undo reverts last command" do
      executor = CommandExecutor.new("Hello")
      cmd = InsertCommand.new(5, " World")

      executor = executor
        |> CommandExecutor.execute(cmd)
        |> CommandExecutor.undo()

      assert CommandExecutor.get_state(executor) == "Hello"
    end

    test "undo on empty stack does nothing" do
      executor = CommandExecutor.new("Hello")
      executor = CommandExecutor.undo(executor)
      assert CommandExecutor.get_state(executor) == "Hello"
    end

    test "redo re-applies undone command" do
      executor = CommandExecutor.new("Hello")
      cmd = InsertCommand.new(5, " World")

      executor = executor
        |> CommandExecutor.execute(cmd)
        |> CommandExecutor.undo()
        |> CommandExecutor.redo()

      assert CommandExecutor.get_state(executor) == "Hello World"
    end

    test "redo on empty stack does nothing" do
      executor = CommandExecutor.new("Hello")
      executor = CommandExecutor.redo(executor)
      assert CommandExecutor.get_state(executor) == "Hello"
    end

    test "multiple undo/redo operations" do
      executor = CommandExecutor.new("Hello")
      cmd1 = InsertCommand.new(5, " World")
      cmd2 = InsertCommand.new(11, "!")

      executor = executor
        |> CommandExecutor.execute(cmd1)
        |> CommandExecutor.execute(cmd2)

      assert CommandExecutor.get_state(executor) == "Hello World!"

      executor = CommandExecutor.undo(executor)
      assert CommandExecutor.get_state(executor) == "Hello World"

      executor = CommandExecutor.undo(executor)
      assert CommandExecutor.get_state(executor) == "Hello"

      executor = CommandExecutor.redo(executor)
      assert CommandExecutor.get_state(executor) == "Hello World"

      executor = CommandExecutor.redo(executor)
      assert CommandExecutor.get_state(executor) == "Hello World!"
    end
  end

  # ============================================================
  # 4. MacroCommand のテスト
  # ============================================================

  describe "MacroCommand" do
    alias Chapter11.{MacroCommand, Command}
    alias Chapter11.TextCommands.InsertCommand

    test "new creates macro with commands" do
      cmd1 = InsertCommand.new(0, "Hello")
      cmd2 = InsertCommand.new(5, " World")
      macro = MacroCommand.new([cmd1, cmd2])
      assert length(macro.commands) == 2
    end

    test "execute runs all commands in order" do
      cmd1 = InsertCommand.new(0, "Hello")
      cmd2 = InsertCommand.new(5, " World")
      macro = MacroCommand.new([cmd1, cmd2])

      result = Command.execute(macro, "")
      assert result == "Hello World"
    end

    test "undo reverts all commands in reverse order" do
      cmd1 = InsertCommand.new(0, "Hello")
      cmd2 = InsertCommand.new(5, " World")
      macro = MacroCommand.new([cmd1, cmd2])

      result = Command.undo(macro, "Hello World")
      assert result == ""
    end

    test "macro command works with executor" do
      alias Chapter11.CommandExecutor

      cmd1 = InsertCommand.new(0, "Hello")
      cmd2 = InsertCommand.new(5, " World")
      macro = MacroCommand.new([cmd1, cmd2])

      executor = CommandExecutor.new("")
        |> CommandExecutor.execute(macro)

      assert CommandExecutor.get_state(executor) == "Hello World"

      executor = CommandExecutor.undo(executor)
      assert CommandExecutor.get_state(executor) == ""
    end
  end

  # ============================================================
  # 5. BatchExecutor のテスト
  # ============================================================

  describe "BatchExecutor" do
    alias Chapter11.{CommandExecutor, BatchExecutor}
    alias Chapter11.TextCommands.InsertCommand

    test "execute_batch runs multiple commands" do
      executor = CommandExecutor.new("Hello")
      commands = [
        InsertCommand.new(5, " World"),
        InsertCommand.new(11, "!")
      ]

      executor = BatchExecutor.execute_batch(executor, commands)
      assert CommandExecutor.get_state(executor) == "Hello World!"
    end

    test "undo_all reverts all commands" do
      executor = CommandExecutor.new("Hello")
      commands = [
        InsertCommand.new(5, " World"),
        InsertCommand.new(11, "!")
      ]

      executor = executor
        |> BatchExecutor.execute_batch(commands)
        |> BatchExecutor.undo_all()

      assert CommandExecutor.get_state(executor) == "Hello"
    end

    test "redo_all re-applies all undone commands" do
      executor = CommandExecutor.new("Hello")
      commands = [
        InsertCommand.new(5, " World"),
        InsertCommand.new(11, "!")
      ]

      executor = executor
        |> BatchExecutor.execute_batch(commands)
        |> BatchExecutor.undo_all()
        |> BatchExecutor.redo_all()

      assert CommandExecutor.get_state(executor) == "Hello World!"
    end
  end

  # ============================================================
  # 6. CommandQueue のテスト
  # ============================================================

  describe "CommandQueue" do
    alias Chapter11.{CommandQueue, Command}
    alias Chapter11.TextCommands.InsertCommand

    test "new creates empty queue" do
      queue = CommandQueue.new()
      assert CommandQueue.length(queue) == 0
    end

    test "enqueue adds command to queue" do
      queue = CommandQueue.new()
      cmd = InsertCommand.new(5, " World")
      queue = CommandQueue.enqueue(queue, cmd)
      assert CommandQueue.length(queue) == 1
    end

    test "flush executes all queued commands" do
      queue = CommandQueue.new()
        |> CommandQueue.enqueue(InsertCommand.new(5, " World"))
        |> CommandQueue.enqueue(InsertCommand.new(11, "!"))

      {result, new_queue} = CommandQueue.flush(queue, "Hello")
      assert result == "Hello World!"
      assert CommandQueue.length(new_queue) == 0
    end

    test "clear empties the queue" do
      queue = CommandQueue.new()
        |> CommandQueue.enqueue(InsertCommand.new(5, " World"))
        |> CommandQueue.clear()

      assert CommandQueue.length(queue) == 0
    end
  end

  # ============================================================
  # 7. CommandLogger のテスト
  # ============================================================

  describe "CommandLogger" do
    alias Chapter11.{CommandLogger}
    alias Chapter11.TextCommands.InsertCommand

    test "logs command execution" do
      {:ok, logger} = CommandLogger.start_link()
      cmd = InsertCommand.new(5, " World")

      CommandLogger.log(logger, cmd, :execute)
      logs = CommandLogger.get_logs(logger)

      assert length(logs) == 1
      assert hd(logs).command == cmd
      assert hd(logs).action == :execute
    end

    test "logs multiple actions" do
      {:ok, logger} = CommandLogger.start_link()
      cmd = InsertCommand.new(5, " World")

      CommandLogger.log(logger, cmd, :execute)
      CommandLogger.log(logger, cmd, :undo)

      logs = CommandLogger.get_logs(logger)
      assert length(logs) == 2
      assert Enum.at(logs, 0).action == :execute
      assert Enum.at(logs, 1).action == :undo
    end

    test "clear removes all logs" do
      {:ok, logger} = CommandLogger.start_link()
      cmd = InsertCommand.new(5, " World")

      CommandLogger.log(logger, cmd, :execute)
      CommandLogger.clear(logger)

      logs = CommandLogger.get_logs(logger)
      assert length(logs) == 0
    end
  end

  # ============================================================
  # Doctest
  # ============================================================

  doctest Chapter11.TextCommands.InsertCommand
  doctest Chapter11.TextCommands.DeleteCommand
  doctest Chapter11.TextCommands.ReplaceCommand
  doctest Chapter11.CommandExecutor
  doctest Chapter11.MacroCommand
  doctest Chapter11.BatchExecutor
end
