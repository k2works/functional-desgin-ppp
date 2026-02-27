package commandpattern

import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers

class CommandPatternSpec extends AnyFunSpec with Matchers:

  // ============================================
  // 1. テキスト操作コマンド
  // ============================================

  describe("Document") {
    it("テキストを挿入できる") {
      val doc = Document("Hello")
      doc.insert(5, " World").content shouldBe "Hello World"
    }

    it("テキストを削除できる") {
      val doc = Document("Hello World")
      doc.delete(5, 11).content shouldBe "Hello"
    }

    it("テキストを置換できる") {
      val doc = Document("Hello World")
      doc.replace(6, 11, "Scala").content shouldBe "Hello Scala"
    }
  }

  describe("InsertCommand") {
    it("テキストを指定位置に挿入する") {
      val doc = Document("Hello")
      val cmd = InsertCommand(5, " World")
      cmd.execute(doc).content shouldBe "Hello World"
    }

    it("Undo で挿入を取り消す") {
      val doc = Document("Hello World")
      val cmd = InsertCommand(5, " World")
      cmd.undo(doc).content shouldBe "Hello"
    }
  }

  describe("DeleteCommand") {
    it("テキストを削除する") {
      val doc = Document("Hello World")
      val cmd = DeleteCommand(5, 11, " World")
      cmd.execute(doc).content shouldBe "Hello"
    }

    it("Undo で削除を取り消す") {
      val doc = Document("Hello")
      val cmd = DeleteCommand(5, 11, " World")
      cmd.undo(doc).content shouldBe "Hello World"
    }
  }

  describe("ReplaceCommand") {
    it("テキストを置換する") {
      val doc = Document("Hello World")
      val cmd = ReplaceCommand(6, "World", "Scala")
      cmd.execute(doc).content shouldBe "Hello Scala"
    }

    it("Undo で置換を取り消す") {
      val doc = Document("Hello Scala")
      val cmd = ReplaceCommand(6, "World", "Scala")
      cmd.undo(doc).content shouldBe "Hello World"
    }
  }

  // ============================================
  // 2. キャンバス操作コマンド
  // ============================================

  describe("Canvas") {
    val circle = Circle("c1", 10, 20, 5)
    val rect = Rectangle("r1", 30, 40, 10, 20)

    it("図形を追加できる") {
      val canvas = Canvas.empty.addShape(circle)
      canvas.shapes should contain(circle)
    }

    it("図形を削除できる") {
      val canvas = Canvas(List(circle, rect)).removeShape("c1")
      canvas.shapes should not contain circle
      canvas.shapes should contain(rect)
    }

    it("図形を移動できる") {
      val canvas = Canvas(List(circle)).moveShape("c1", 5, 10)
      canvas.findShape("c1") shouldBe Some(Circle("c1", 15, 30, 5))
    }
  }

  describe("AddShapeCommand") {
    val circle = Circle("c1", 10, 20, 5)

    it("図形を追加する") {
      val cmd = AddShapeCommand(circle)
      val canvas = cmd.execute(Canvas.empty)
      canvas.shapes should contain(circle)
    }

    it("Undo で追加を取り消す") {
      val cmd = AddShapeCommand(circle)
      val canvas = Canvas(List(circle))
      cmd.undo(canvas).shapes should not contain circle
    }
  }

  describe("RemoveShapeCommand") {
    val circle = Circle("c1", 10, 20, 5)

    it("図形を削除する") {
      val cmd = RemoveShapeCommand(circle)
      val canvas = Canvas(List(circle))
      cmd.execute(canvas).shapes should not contain circle
    }

    it("Undo で削除を取り消す") {
      val cmd = RemoveShapeCommand(circle)
      val canvas = Canvas.empty
      cmd.undo(canvas).shapes should contain(circle)
    }
  }

  describe("MoveShapeCommand") {
    val circle = Circle("c1", 10, 20, 5)

    it("図形を移動する") {
      val cmd = MoveShapeCommand("c1", 5, 10)
      val canvas = Canvas(List(circle))
      cmd.execute(canvas).findShape("c1") shouldBe Some(Circle("c1", 15, 30, 5))
    }

    it("Undo で移動を取り消す") {
      val cmd = MoveShapeCommand("c1", 5, 10)
      val canvas = Canvas(List(Circle("c1", 15, 30, 5)))
      cmd.undo(canvas).findShape("c1") shouldBe Some(Circle("c1", 10, 20, 5))
    }
  }

  // ============================================
  // 3. コマンド実行器
  // ============================================

  describe("CommandExecutor") {
    describe("基本操作") {
      it("コマンドを実行する") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
        exec.state.content shouldBe "Hello World"
      }

      it("Undo スタックに追加する") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
        exec.canUndo shouldBe true
        exec.undoCount shouldBe 1
      }

      it("Redo スタックをクリアする") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
          .undo
          .execute(InsertCommand(5, "!"))
        exec.canRedo shouldBe false
      }
    }

    describe("Undo/Redo") {
      it("Undo で前の状態に戻る") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
          .undo
        exec.state.content shouldBe "Hello"
      }

      it("Redo で Undo を取り消す") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
          .undo
          .redo
        exec.state.content shouldBe "Hello World"
      }

      it("複数回の Undo/Redo が可能") {
        val exec = CommandExecutor(Document("A"))
          .execute(InsertCommand(1, "B"))
          .execute(InsertCommand(2, "C"))
          .execute(InsertCommand(3, "D"))
        
        exec.state.content shouldBe "ABCD"
        exec.undo.state.content shouldBe "ABC"
        exec.undo.undo.state.content shouldBe "AB"
        exec.undo.undo.undo.state.content shouldBe "A"
        exec.undo.undo.undo.redo.state.content shouldBe "AB"
      }

      it("Undo スタックが空の場合は何もしない") {
        val exec = CommandExecutor(Document("Hello"))
        exec.undo.state.content shouldBe "Hello"
      }

      it("Redo スタックが空の場合は何もしない") {
        val exec = CommandExecutor(Document("Hello"))
        exec.redo.state.content shouldBe "Hello"
      }
    }

    describe("バッチ処理") {
      it("複数のコマンドを一括実行する") {
        val commands = List(
          InsertCommand(5, " World"),
          InsertCommand(11, "!")
        )
        val exec = CommandExecutor(Document("Hello")).executeBatch(commands)
        exec.state.content shouldBe "Hello World!"
        exec.undoCount shouldBe 2
      }

      it("undoAll で全てを取り消す") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
          .execute(InsertCommand(11, "!"))
          .undoAll
        exec.state.content shouldBe "Hello"
        exec.canUndo shouldBe false
      }

      it("redoAll で全てを再実行する") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
          .execute(InsertCommand(11, "!"))
          .undoAll
          .redoAll
        exec.state.content shouldBe "Hello World!"
        exec.canRedo shouldBe false
      }
    }

    describe("履歴管理") {
      it("履歴をクリアできる") {
        val exec = CommandExecutor(Document("Hello"))
          .execute(InsertCommand(5, " World"))
          .clearHistory
        exec.canUndo shouldBe false
        exec.canRedo shouldBe false
        exec.state.content shouldBe "Hello World"
      }
    }
  }

  // ============================================
  // 4. マクロコマンド
  // ============================================

  describe("MacroCommand") {
    it("複数のコマンドを一つとして実行する") {
      val macroCmd = MacroCommand(
        InsertCommand(5, " World"),
        InsertCommand(11, "!")
      )
      val doc = macroCmd.execute(Document("Hello"))
      doc.content shouldBe "Hello World!"
    }

    it("Undo で全てのコマンドを逆順に取り消す") {
      val macroCmd = MacroCommand(
        InsertCommand(5, " World"),
        InsertCommand(11, "!")
      )
      val doc = macroCmd.undo(Document("Hello World!"))
      doc.content shouldBe "Hello"
    }

    it("コマンドを追加できる") {
      val macroCmd = MacroCommand.empty[Document]
        .add(InsertCommand(5, " World"))
        .add(InsertCommand(11, "!"))
      macroCmd.size shouldBe 2
    }

    it("CommandExecutor と組み合わせて使用できる") {
      val macroCmd = MacroCommand(
        InsertCommand(5, " World"),
        InsertCommand(11, "!")
      )
      val exec = CommandExecutor(Document("Hello"))
        .execute(macroCmd)
      
      exec.state.content shouldBe "Hello World!"
      exec.undoCount shouldBe 1
      
      val undone = exec.undo
      undone.state.content shouldBe "Hello"
    }
  }

  // ============================================
  // 5. 計算機コマンド
  // ============================================

  describe("CalculatorCommand") {
    describe("AddCommand") {
      it("値を加算する") {
        val calc = AddCommand(10).execute(Calculator())
        calc.value shouldBe 10
      }

      it("Undo で加算を取り消す") {
        val calc = AddCommand(10).undo(Calculator(value = 10))
        calc.value shouldBe 0
      }
    }

    describe("SubtractCommand") {
      it("値を減算する") {
        val calc = SubtractCommand(3).execute(Calculator(value = 10))
        calc.value shouldBe 7
      }
    }

    describe("MultiplyCommand") {
      it("値を乗算する") {
        val calc = MultiplyCommand(5).execute(Calculator(value = 10))
        calc.value shouldBe 50
      }
    }

    describe("DivideCommand") {
      it("値を除算する") {
        val calc = DivideCommand(2).execute(Calculator(value = 10))
        calc.value shouldBe 5
      }

      it("ゼロ除算はエラー") {
        an[IllegalArgumentException] should be thrownBy DivideCommand(0)
      }
    }

    describe("計算機全体") {
      it("複合計算をサポートする") {
        val exec = CommandExecutor(Calculator())
          .execute(AddCommand(100))
          .execute(MultiplyCommand(2))
          .execute(SubtractCommand(50))
          .execute(DivideCommand(3))
        
        exec.state.value shouldBe 50 // (100 * 2 - 50) / 3 = 50
      }

      it("Undo で計算を取り消せる") {
        val exec = CommandExecutor(Calculator())
          .execute(AddCommand(100))
          .execute(MultiplyCommand(2))
          .undo
        
        exec.state.value shouldBe 100
      }
    }
  }

  // ============================================
  // 6. ファイル操作コマンド
  // ============================================

  describe("FileSystemCommand") {
    describe("CreateFileCommand") {
      it("ファイルを作成する") {
        val cmd = CreateFileCommand("/test.txt", "Hello")
        val fs = cmd.execute(FileSystem.empty)
        fs.readFile("/test.txt") shouldBe Some("Hello")
      }

      it("Undo でファイルを削除する") {
        val cmd = CreateFileCommand("/test.txt", "Hello")
        val fs = FileSystem.empty.createFile("/test.txt", "Hello")
        cmd.undo(fs).fileExists("/test.txt") shouldBe false
      }
    }

    describe("DeleteFileCommand") {
      it("ファイルを削除する") {
        val fs = FileSystem.empty.createFile("/test.txt", "Hello")
        val cmd = DeleteFileCommand("/test.txt", fs).get
        cmd.execute(fs).fileExists("/test.txt") shouldBe false
      }

      it("Undo でファイルを復元する") {
        val cmd = DeleteFileCommand("/test.txt", "Hello")
        cmd.undo(FileSystem.empty).readFile("/test.txt") shouldBe Some("Hello")
      }
    }

    describe("UpdateFileCommand") {
      it("ファイルを更新する") {
        val fs = FileSystem.empty.createFile("/test.txt", "Hello")
        val cmd = UpdateFileCommand("/test.txt", "World", fs).get
        cmd.execute(fs).readFile("/test.txt") shouldBe Some("World")
      }

      it("Undo で元の内容に戻す") {
        val fs = FileSystem.empty.createFile("/test.txt", "World")
        val cmd = UpdateFileCommand("/test.txt", "Hello", "World")
        cmd.undo(fs).readFile("/test.txt") shouldBe Some("Hello")
      }
    }

    describe("MoveFileCommand") {
      it("ファイルを移動する") {
        val fs = FileSystem.empty.createFile("/old.txt", "Content")
        val cmd = MoveFileCommand("/old.txt", "/new.txt", fs).get
        val result = cmd.execute(fs)
        result.fileExists("/old.txt") shouldBe false
        result.readFile("/new.txt") shouldBe Some("Content")
      }

      it("Undo で元の場所に戻す") {
        val fs = FileSystem.empty.createFile("/new.txt", "Content")
        val cmd = MoveFileCommand("/old.txt", "/new.txt", "Content")
        val result = cmd.undo(fs)
        result.fileExists("/new.txt") shouldBe false
        result.readFile("/old.txt") shouldBe Some("Content")
      }
    }
  }

  // ============================================
  // 7. タスク管理コマンド
  // ============================================

  describe("TaskCommand") {
    val task1 = Task("t1", "Task 1")
    val task2 = Task("t2", "Task 2", TaskStatus.InProgress)

    describe("AddTaskCommand") {
      it("タスクを追加する") {
        val cmd = AddTaskCommand(task1)
        val list = cmd.execute(TaskList.empty)
        list.getTask("t1") shouldBe Some(task1)
      }

      it("Undo でタスクを削除する") {
        val cmd = AddTaskCommand(task1)
        val list = TaskList.empty.addTask(task1)
        cmd.undo(list).getTask("t1") shouldBe None
      }
    }

    describe("RemoveTaskCommand") {
      it("タスクを削除する") {
        val list = TaskList.empty.addTask(task1)
        val cmd = RemoveTaskCommand("t1", list).get
        cmd.execute(list).getTask("t1") shouldBe None
      }

      it("Undo でタスクを復元する") {
        val cmd = RemoveTaskCommand(task1)
        cmd.undo(TaskList.empty).getTask("t1") shouldBe Some(task1)
      }
    }

    describe("ChangeTaskStatusCommand") {
      it("タスクのステータスを変更する") {
        val list = TaskList.empty.addTask(task1)
        val cmd = ChangeTaskStatusCommand("t1", TaskStatus.Done, list).get
        cmd.execute(list).getTask("t1").map(_.status) shouldBe Some(TaskStatus.Done)
      }

      it("Undo で元のステータスに戻す") {
        val list = TaskList.empty.addTask(task1.copy(status = TaskStatus.Done))
        val cmd = ChangeTaskStatusCommand("t1", TaskStatus.Todo, TaskStatus.Done)
        cmd.undo(list).getTask("t1").map(_.status) shouldBe Some(TaskStatus.Todo)
      }
    }

    describe("ChangeTaskPriorityCommand") {
      it("タスクの優先度を変更する") {
        val list = TaskList.empty.addTask(task1)
        val cmd = ChangeTaskPriorityCommand("t1", 10, list).get
        cmd.execute(list).getTask("t1").map(_.priority) shouldBe Some(10)
      }
    }
  }

  // ============================================
  // 8. コマンドキュー
  // ============================================

  describe("CommandQueue") {
    it("コマンドをキューに追加できる") {
      val queue = CommandQueue.empty[Document]
        .enqueue(InsertCommand(5, " World"))
        .enqueue(InsertCommand(11, "!"))
      queue.size shouldBe 2
    }

    it("コマンドをデキューできる") {
      val queue = CommandQueue.empty[Document]
        .enqueue(InsertCommand(5, " World"))
      val (cmd, newQueue) = queue.dequeue
      cmd shouldBe defined
      newQueue.isEmpty shouldBe true
    }

    it("全てのコマンドを実行できる") {
      val queue = CommandQueue.empty[Document]
        .enqueue(InsertCommand(5, " World"))
        .enqueue(InsertCommand(11, "!"))
      val result = queue.executeAll(Document("Hello"))
      result.content shouldBe "Hello World!"
    }

    it("次のコマンドを実行できる") {
      val queue = CommandQueue.empty[Document]
        .enqueue(InsertCommand(5, " World"))
        .enqueue(InsertCommand(11, "!"))
      val (result, newQueue) = queue.executeNext(Document("Hello"))
      result.content shouldBe "Hello World"
      newQueue.size shouldBe 1
    }

    it("複数のコマンドを一括追加できる") {
      val commands = List(
        InsertCommand(5, " World"),
        InsertCommand(11, "!")
      )
      val queue = CommandQueue.empty[Document].enqueueAll(commands)
      queue.size shouldBe 2
    }
  }

  // ============================================
  // 9. 関数型コマンド
  // ============================================

  describe("FunctionalCommand") {
    it("可逆な操作を作成できる") {
      val cmd = FunctionalCommand.reversible[Int](
        _ + 10,
        _ - 10,
        "Add 10"
      )
      cmd.execute(5) shouldBe 15
      cmd.undo(15) shouldBe 5
    }

    it("対称な操作を作成できる") {
      val cmd = FunctionalCommand.symmetric[Boolean](
        !_,
        "Toggle"
      )
      cmd.execute(true) shouldBe false
      cmd.undo(false) shouldBe true
    }

    it("値設定操作を作成できる") {
      case class State(value: Int)
      val initial = State(10)
      val cmd = FunctionalCommand.setValue[State, Int](
        _.value,
        (s, v) => s.copy(value = v),
        100,
        "Set to 100"
      )(initial)
      cmd.execute(initial).value shouldBe 100
      cmd.undo(State(100)).value shouldBe 10
    }

    it("CommandExecutor と組み合わせられる") {
      val cmd = FunctionalCommand.reversible[Int](_ * 2, _ / 2)
      val exec = CommandExecutor(5)
        .execute(cmd)
        .execute(cmd)
      exec.state shouldBe 20
      exec.undo.state shouldBe 10
    }
  }
