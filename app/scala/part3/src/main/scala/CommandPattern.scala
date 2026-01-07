/**
  * 第11章: Command パターン
  * 
  * Command パターンは、リクエストをオブジェクトとしてカプセル化し、
  * 操作の履歴管理、Undo/Redo、バッチ処理を可能にするパターンです。
  */
package commandpattern

// ============================================
// 1. Command インターフェース
// ============================================

/** コマンドの基本インターフェース */
trait Command[S]:
  def execute(state: S): S
  def undo(state: S): S

// ============================================
// 2. テキスト操作コマンド
// ============================================

/** テキストドキュメント */
case class Document(content: String):
  def length: Int = content.length
  
  def insert(position: Int, text: String): Document =
    val (before, after) = content.splitAt(position)
    Document(before + text + after)
  
  def delete(start: Int, end: Int): Document =
    val before = content.take(start)
    val after = content.drop(end)
    Document(before + after)
  
  def replace(start: Int, end: Int, text: String): Document =
    delete(start, end).insert(start, text)
  
  def substring(start: Int, end: Int): String =
    content.substring(start, end)

object Document:
  def empty: Document = Document("")

/** テキスト挿入コマンド */
case class InsertCommand(position: Int, text: String) extends Command[Document]:
  def execute(doc: Document): Document =
    doc.insert(position, text)
  
  def undo(doc: Document): Document =
    doc.delete(position, position + text.length)

/** テキスト削除コマンド */
case class DeleteCommand(start: Int, end: Int, deletedText: String) extends Command[Document]:
  def execute(doc: Document): Document =
    doc.delete(start, end)
  
  def undo(doc: Document): Document =
    doc.insert(start, deletedText)

object DeleteCommand:
  def apply(start: Int, end: Int, doc: Document): DeleteCommand =
    DeleteCommand(start, end, doc.substring(start, end))

/** テキスト置換コマンド */
case class ReplaceCommand(start: Int, oldText: String, newText: String) extends Command[Document]:
  def execute(doc: Document): Document =
    doc.replace(start, start + oldText.length, newText)
  
  def undo(doc: Document): Document =
    doc.replace(start, start + newText.length, oldText)

object ReplaceCommand:
  def apply(start: Int, end: Int, newText: String, doc: Document): ReplaceCommand =
    ReplaceCommand(start, doc.substring(start, end), newText)

// ============================================
// 3. キャンバス操作コマンド
// ============================================

/** 図形の基本トレイト */
sealed trait Shape:
  def id: String
  def x: Double
  def y: Double
  def move(dx: Double, dy: Double): Shape

case class Circle(id: String, x: Double, y: Double, radius: Double) extends Shape:
  def move(dx: Double, dy: Double): Circle = copy(x = x + dx, y = y + dy)

case class Rectangle(id: String, x: Double, y: Double, width: Double, height: Double) extends Shape:
  def move(dx: Double, dy: Double): Rectangle = copy(x = x + dx, y = y + dy)

/** キャンバス */
case class Canvas(shapes: List[Shape] = Nil):
  def addShape(shape: Shape): Canvas =
    copy(shapes = shapes :+ shape)
  
  def removeShape(id: String): Canvas =
    copy(shapes = shapes.filterNot(_.id == id))
  
  def moveShape(id: String, dx: Double, dy: Double): Canvas =
    copy(shapes = shapes.map { shape =>
      if shape.id == id then shape.move(dx, dy) else shape
    })
  
  def findShape(id: String): Option[Shape] =
    shapes.find(_.id == id)
  
  def updateShape(id: String, f: Shape => Shape): Canvas =
    copy(shapes = shapes.map { shape =>
      if shape.id == id then f(shape) else shape
    })

object Canvas:
  def empty: Canvas = Canvas()

/** 図形追加コマンド */
case class AddShapeCommand(shape: Shape) extends Command[Canvas]:
  def execute(canvas: Canvas): Canvas =
    canvas.addShape(shape)
  
  def undo(canvas: Canvas): Canvas =
    canvas.removeShape(shape.id)

/** 図形削除コマンド */
case class RemoveShapeCommand(shape: Shape) extends Command[Canvas]:
  def execute(canvas: Canvas): Canvas =
    canvas.removeShape(shape.id)
  
  def undo(canvas: Canvas): Canvas =
    canvas.addShape(shape)

object RemoveShapeCommand:
  def apply(id: String, canvas: Canvas): Option[RemoveShapeCommand] =
    canvas.findShape(id).map(RemoveShapeCommand(_))

/** 図形移動コマンド */
case class MoveShapeCommand(shapeId: String, dx: Double, dy: Double) extends Command[Canvas]:
  def execute(canvas: Canvas): Canvas =
    canvas.moveShape(shapeId, dx, dy)
  
  def undo(canvas: Canvas): Canvas =
    canvas.moveShape(shapeId, -dx, -dy)

/** 図形サイズ変更コマンド */
case class ResizeShapeCommand(shapeId: String, oldShape: Shape, newShape: Shape) extends Command[Canvas]:
  def execute(canvas: Canvas): Canvas =
    canvas.updateShape(shapeId, _ => newShape)
  
  def undo(canvas: Canvas): Canvas =
    canvas.updateShape(shapeId, _ => oldShape)

// ============================================
// 4. コマンド実行器（Invoker）
// ============================================

/** コマンド実行器 */
case class CommandExecutor[S](
  state: S,
  undoStack: List[Command[S]] = Nil,
  redoStack: List[Command[S]] = Nil
):
  /** コマンドを実行 */
  def execute(command: Command[S]): CommandExecutor[S] =
    copy(
      state = command.execute(state),
      undoStack = command :: undoStack,
      redoStack = Nil
    )
  
  /** 最後のコマンドを取り消す */
  def undo: CommandExecutor[S] =
    undoStack match
      case head :: tail =>
        copy(
          state = head.undo(state),
          undoStack = tail,
          redoStack = head :: redoStack
        )
      case Nil => this
  
  /** 取り消したコマンドを再実行 */
  def redo: CommandExecutor[S] =
    redoStack match
      case head :: tail =>
        copy(
          state = head.execute(state),
          undoStack = head :: undoStack,
          redoStack = tail
        )
      case Nil => this
  
  /** Undo可能か */
  def canUndo: Boolean = undoStack.nonEmpty
  
  /** Redo可能か */
  def canRedo: Boolean = redoStack.nonEmpty
  
  /** Undo履歴の数 */
  def undoCount: Int = undoStack.length
  
  /** Redo履歴の数 */
  def redoCount: Int = redoStack.length
  
  /** 複数コマンドをバッチ実行 */
  def executeBatch(commands: List[Command[S]]): CommandExecutor[S] =
    commands.foldLeft(this)((exec, cmd) => exec.execute(cmd))
  
  /** 全てUndoする */
  def undoAll: CommandExecutor[S] =
    if canUndo then undo.undoAll else this
  
  /** 全てRedoする */
  def redoAll: CommandExecutor[S] =
    if canRedo then redo.redoAll else this
  
  /** 履歴をクリア */
  def clearHistory: CommandExecutor[S] =
    copy(undoStack = Nil, redoStack = Nil)

object CommandExecutor:
  def apply[S](initialState: S): CommandExecutor[S] =
    CommandExecutor(initialState, Nil, Nil)

// ============================================
// 5. マクロコマンド（複合コマンド）
// ============================================

/** マクロコマンド - 複数のコマンドを一つとして扱う */
case class MacroCommand[S](commands: List[Command[S]]) extends Command[S]:
  def execute(state: S): S =
    commands.foldLeft(state)((s, cmd) => cmd.execute(s))
  
  def undo(state: S): S =
    commands.reverse.foldLeft(state)((s, cmd) => cmd.undo(s))
  
  def add(command: Command[S]): MacroCommand[S] =
    copy(commands = commands :+ command)
  
  def isEmpty: Boolean = commands.isEmpty
  
  def size: Int = commands.length

object MacroCommand:
  def empty[S]: MacroCommand[S] = MacroCommand(Nil)
  def apply[S](commands: Command[S]*): MacroCommand[S] = MacroCommand(commands.toList)

// ============================================
// 6. 計算機コマンド
// ============================================

/** 計算機の状態 */
case class Calculator(value: Double = 0, history: List[String] = Nil):
  def withValue(newValue: Double, operation: String): Calculator =
    copy(value = newValue, history = history :+ s"$operation -> $newValue")

object Calculator:
  def apply(): Calculator = Calculator(0, Nil)

/** 計算コマンドのベーストレイト */
sealed trait CalculatorCommand extends Command[Calculator]

/** 加算コマンド */
case class AddCommand(operand: Double) extends CalculatorCommand:
  def execute(calc: Calculator): Calculator =
    calc.withValue(calc.value + operand, s"+ $operand")
  
  def undo(calc: Calculator): Calculator =
    calc.withValue(calc.value - operand, s"undo + $operand")

/** 減算コマンド */
case class SubtractCommand(operand: Double) extends CalculatorCommand:
  def execute(calc: Calculator): Calculator =
    calc.withValue(calc.value - operand, s"- $operand")
  
  def undo(calc: Calculator): Calculator =
    calc.withValue(calc.value + operand, s"undo - $operand")

/** 乗算コマンド */
case class MultiplyCommand(operand: Double) extends CalculatorCommand:
  def execute(calc: Calculator): Calculator =
    calc.withValue(calc.value * operand, s"* $operand")
  
  def undo(calc: Calculator): Calculator =
    calc.withValue(calc.value / operand, s"undo * $operand")

/** 除算コマンド */
case class DivideCommand(operand: Double) extends CalculatorCommand:
  require(operand != 0, "Cannot divide by zero")
  
  def execute(calc: Calculator): Calculator =
    calc.withValue(calc.value / operand, s"/ $operand")
  
  def undo(calc: Calculator): Calculator =
    calc.withValue(calc.value * operand, s"undo / $operand")

/** 値設定コマンド */
case class SetValueCommand(newValue: Double, previousValue: Double) extends CalculatorCommand:
  def execute(calc: Calculator): Calculator =
    calc.withValue(newValue, s"set $newValue")
  
  def undo(calc: Calculator): Calculator =
    calc.withValue(previousValue, s"undo set $newValue")

object SetValueCommand:
  def apply(newValue: Double, calc: Calculator): SetValueCommand =
    SetValueCommand(newValue, calc.value)

// ============================================
// 7. ファイル操作コマンド
// ============================================

/** 仮想ファイルシステム */
case class FileSystem(
  files: Map[String, String] = Map.empty,
  directories: Set[String] = Set("/")
):
  def createFile(path: String, content: String): FileSystem =
    copy(files = files + (path -> content))
  
  def deleteFile(path: String): FileSystem =
    copy(files = files - path)
  
  def readFile(path: String): Option[String] =
    files.get(path)
  
  def updateFile(path: String, content: String): FileSystem =
    copy(files = files + (path -> content))
  
  def fileExists(path: String): Boolean =
    files.contains(path)
  
  def createDirectory(path: String): FileSystem =
    copy(directories = directories + path)
  
  def deleteDirectory(path: String): FileSystem =
    copy(directories = directories - path)
  
  def directoryExists(path: String): Boolean =
    directories.contains(path)

object FileSystem:
  def empty: FileSystem = FileSystem()

/** ファイル作成コマンド */
case class CreateFileCommand(path: String, content: String) extends Command[FileSystem]:
  def execute(fs: FileSystem): FileSystem =
    fs.createFile(path, content)
  
  def undo(fs: FileSystem): FileSystem =
    fs.deleteFile(path)

/** ファイル削除コマンド */
case class DeleteFileCommand(path: String, content: String) extends Command[FileSystem]:
  def execute(fs: FileSystem): FileSystem =
    fs.deleteFile(path)
  
  def undo(fs: FileSystem): FileSystem =
    fs.createFile(path, content)

object DeleteFileCommand:
  def apply(path: String, fs: FileSystem): Option[DeleteFileCommand] =
    fs.readFile(path).map(content => DeleteFileCommand(path, content))

/** ファイル更新コマンド */
case class UpdateFileCommand(path: String, oldContent: String, newContent: String) extends Command[FileSystem]:
  def execute(fs: FileSystem): FileSystem =
    fs.updateFile(path, newContent)
  
  def undo(fs: FileSystem): FileSystem =
    fs.updateFile(path, oldContent)

object UpdateFileCommand:
  def apply(path: String, newContent: String, fs: FileSystem): Option[UpdateFileCommand] =
    fs.readFile(path).map(oldContent => UpdateFileCommand(path, oldContent, newContent))

/** ファイル移動/リネームコマンド */
case class MoveFileCommand(oldPath: String, newPath: String, content: String) extends Command[FileSystem]:
  def execute(fs: FileSystem): FileSystem =
    fs.deleteFile(oldPath).createFile(newPath, content)
  
  def undo(fs: FileSystem): FileSystem =
    fs.deleteFile(newPath).createFile(oldPath, content)

object MoveFileCommand:
  def apply(oldPath: String, newPath: String, fs: FileSystem): Option[MoveFileCommand] =
    fs.readFile(oldPath).map(content => MoveFileCommand(oldPath, newPath, content))

// ============================================
// 8. タスク管理コマンド
// ============================================

/** タスクの状態 */
enum TaskStatus:
  case Todo, InProgress, Done

/** タスク */
case class Task(
  id: String,
  title: String,
  status: TaskStatus = TaskStatus.Todo,
  priority: Int = 0
)

/** タスクリスト */
case class TaskList(tasks: Map[String, Task] = Map.empty):
  def addTask(task: Task): TaskList =
    copy(tasks = tasks + (task.id -> task))
  
  def removeTask(id: String): TaskList =
    copy(tasks = tasks - id)
  
  def updateTask(id: String, f: Task => Task): TaskList =
    tasks.get(id) match
      case Some(task) => copy(tasks = tasks + (id -> f(task)))
      case None => this
  
  def getTask(id: String): Option[Task] =
    tasks.get(id)
  
  def allTasks: List[Task] =
    tasks.values.toList

object TaskList:
  def empty: TaskList = TaskList()

/** タスク追加コマンド */
case class AddTaskCommand(task: Task) extends Command[TaskList]:
  def execute(list: TaskList): TaskList =
    list.addTask(task)
  
  def undo(list: TaskList): TaskList =
    list.removeTask(task.id)

/** タスク削除コマンド */
case class RemoveTaskCommand(task: Task) extends Command[TaskList]:
  def execute(list: TaskList): TaskList =
    list.removeTask(task.id)
  
  def undo(list: TaskList): TaskList =
    list.addTask(task)

object RemoveTaskCommand:
  def apply(id: String, list: TaskList): Option[RemoveTaskCommand] =
    list.getTask(id).map(RemoveTaskCommand(_))

/** タスクステータス変更コマンド */
case class ChangeTaskStatusCommand(
  taskId: String,
  oldStatus: TaskStatus,
  newStatus: TaskStatus
) extends Command[TaskList]:
  def execute(list: TaskList): TaskList =
    list.updateTask(taskId, _.copy(status = newStatus))
  
  def undo(list: TaskList): TaskList =
    list.updateTask(taskId, _.copy(status = oldStatus))

object ChangeTaskStatusCommand:
  def apply(taskId: String, newStatus: TaskStatus, list: TaskList): Option[ChangeTaskStatusCommand] =
    list.getTask(taskId).map(task => ChangeTaskStatusCommand(taskId, task.status, newStatus))

/** タスク優先度変更コマンド */
case class ChangeTaskPriorityCommand(
  taskId: String,
  oldPriority: Int,
  newPriority: Int
) extends Command[TaskList]:
  def execute(list: TaskList): TaskList =
    list.updateTask(taskId, _.copy(priority = newPriority))
  
  def undo(list: TaskList): TaskList =
    list.updateTask(taskId, _.copy(priority = oldPriority))

object ChangeTaskPriorityCommand:
  def apply(taskId: String, newPriority: Int, list: TaskList): Option[ChangeTaskPriorityCommand] =
    list.getTask(taskId).map(task => ChangeTaskPriorityCommand(taskId, task.priority, newPriority))

// ============================================
// 9. 遅延実行キュー
// ============================================

/** コマンドキュー - 遅延実行用 */
case class CommandQueue[S](
  commands: List[Command[S]] = Nil
):
  def enqueue(command: Command[S]): CommandQueue[S] =
    copy(commands = commands :+ command)
  
  def enqueueAll(cmds: List[Command[S]]): CommandQueue[S] =
    copy(commands = commands ++ cmds)
  
  def dequeue: (Option[Command[S]], CommandQueue[S]) =
    commands match
      case head :: tail => (Some(head), CommandQueue(tail))
      case Nil => (None, this)
  
  def executeAll(initialState: S): S =
    commands.foldLeft(initialState)((s, cmd) => cmd.execute(s))
  
  def executeNext(state: S): (S, CommandQueue[S]) =
    commands match
      case head :: tail => (head.execute(state), CommandQueue(tail))
      case Nil => (state, this)
  
  def isEmpty: Boolean = commands.isEmpty
  def size: Int = commands.length
  def clear: CommandQueue[S] = CommandQueue(Nil)

object CommandQueue:
  def empty[S]: CommandQueue[S] = CommandQueue(Nil)

// ============================================
// 10. 関数型コマンドビルダー
// ============================================

/** 関数型コマンド - execute と undo を関数として持つ */
case class FunctionalCommand[S](
  executeFn: S => S,
  undoFn: S => S,
  description: String = ""
) extends Command[S]:
  def execute(state: S): S = executeFn(state)
  def undo(state: S): S = undoFn(state)

object FunctionalCommand:
  /** 可逆な操作からコマンドを作成 */
  def reversible[S](forward: S => S, backward: S => S, desc: String = ""): FunctionalCommand[S] =
    FunctionalCommand(forward, backward, desc)
  
  /** 対称な操作（自身がUndoになる）からコマンドを作成 */
  def symmetric[S](transform: S => S, desc: String = ""): FunctionalCommand[S] =
    FunctionalCommand(transform, transform, desc)
  
  /** 値設定操作からコマンドを作成 */
  def setValue[S, A](get: S => A, set: (S, A) => S, newValue: A, desc: String = "")(state: S): FunctionalCommand[S] =
    val oldValue = get(state)
    FunctionalCommand(
      s => set(s, newValue),
      s => set(s, oldValue),
      desc
    )
