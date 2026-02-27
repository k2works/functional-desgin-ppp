/**
 * 第20章: パターン間の相互作用
 *
 * 複数のデザインパターンを組み合わせた実装例。
 * Composite + Decorator、Command + Observer などの相互作用を示す。
 */
import scala.collection.mutable.ListBuffer

object PatternInteractions:

  // ============================================================
  // 1. 基本図形インターフェース
  // ============================================================

  /**
   * 図形の基底trait
   */
  trait Shape:
    def move(dx: Double, dy: Double): Shape
    def scale(factor: Double): Shape
    def area: Double
    def draw: String

  // ============================================================
  // 2. 基本図形の実装
  // ============================================================

  case class Circle(x: Double, y: Double, radius: Double) extends Shape:
    def move(dx: Double, dy: Double): Circle = copy(x = x + dx, y = y + dy)
    def scale(factor: Double): Circle = copy(radius = radius * factor)
    def area: Double = Math.PI * radius * radius
    def draw: String = s"Circle(x=$x, y=$y, r=$radius)"

  case class Rectangle(x: Double, y: Double, width: Double, height: Double) extends Shape:
    def move(dx: Double, dy: Double): Rectangle = copy(x = x + dx, y = y + dy)
    def scale(factor: Double): Rectangle = copy(width = width * factor, height = height * factor)
    def area: Double = width * height
    def draw: String = s"Rectangle(x=$x, y=$y, w=$width, h=$height)"

  case class Triangle(x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double) extends Shape:
    def move(dx: Double, dy: Double): Triangle =
      copy(x1 = x1 + dx, y1 = y1 + dy, x2 = x2 + dx, y2 = y2 + dy, x3 = x3 + dx, y3 = y3 + dy)
    def scale(factor: Double): Triangle =
      val cx = (x1 + x2 + x3) / 3
      val cy = (y1 + y2 + y3) / 3
      copy(
        x1 = cx + (x1 - cx) * factor, y1 = cy + (y1 - cy) * factor,
        x2 = cx + (x2 - cx) * factor, y2 = cy + (y2 - cy) * factor,
        x3 = cx + (x3 - cx) * factor, y3 = cy + (y3 - cy) * factor
      )
    def area: Double =
      math.abs((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2)
    def draw: String = s"Triangle(($x1,$y1), ($x2,$y2), ($x3,$y3))"

  // ============================================================
  // 3. Composite パターン
  // ============================================================

  /**
   * 複合図形 - 複数の図形をまとめて扱う
   */
  case class CompositeShape(shapes: Vector[Shape] = Vector.empty) extends Shape:
    def add(shape: Shape): CompositeShape = copy(shapes = shapes :+ shape)
    def remove(shape: Shape): CompositeShape = copy(shapes = shapes.filterNot(_ == shape))
    def get(index: Int): Option[Shape] = shapes.lift(index)

    def move(dx: Double, dy: Double): CompositeShape =
      copy(shapes = shapes.map(_.move(dx, dy)))

    def scale(factor: Double): CompositeShape =
      copy(shapes = shapes.map(_.scale(factor)))

    def area: Double = shapes.map(_.area).sum

    def draw: String =
      s"Composite[\n  ${shapes.map(_.draw).mkString("\n  ")}\n]"

  object CompositeShape:
    def apply(shapes: Shape*): CompositeShape = CompositeShape(shapes.toVector)

  // ============================================================
  // 4. Decorator パターン
  // ============================================================

  /**
   * ジャーナルエントリ
   */
  case class JournalEntry(operation: String, timestamp: Long = System.currentTimeMillis())

  /**
   * ジャーナル付き図形 - 操作履歴を記録
   */
  case class JournaledShape(shape: Shape, journal: Vector[JournalEntry] = Vector.empty) extends Shape:
    def move(dx: Double, dy: Double): JournaledShape =
      copy(
        shape = shape.move(dx, dy),
        journal = journal :+ JournalEntry(s"move($dx, $dy)")
      )

    def scale(factor: Double): JournaledShape =
      copy(
        shape = shape.scale(factor),
        journal = journal :+ JournalEntry(s"scale($factor)")
      )

    def area: Double = shape.area
    def draw: String = s"[Journaled: ${journal.size} ops] ${shape.draw}"
    def getJournal: Vector[JournalEntry] = journal

  /**
   * 色付き図形
   */
  case class ColoredShape(shape: Shape, color: String) extends Shape:
    def move(dx: Double, dy: Double): ColoredShape = copy(shape = shape.move(dx, dy))
    def scale(factor: Double): ColoredShape = copy(shape = shape.scale(factor))
    def area: Double = shape.area
    def draw: String = s"[$color] ${shape.draw}"
    def withColor(newColor: String): ColoredShape = copy(color = newColor)

  /**
   * 枠付き図形
   */
  case class BorderedShape(shape: Shape, borderWidth: Int) extends Shape:
    def move(dx: Double, dy: Double): BorderedShape = copy(shape = shape.move(dx, dy))
    def scale(factor: Double): BorderedShape = copy(shape = shape.scale(factor))
    def area: Double = shape.area
    def draw: String = s"[Border: ${borderWidth}px] ${shape.draw}"

  // ============================================================
  // 5. Observer パターン
  // ============================================================

  /**
   * イベント
   */
  sealed trait Event
  case class CommandExecuted(command: Command, description: String) extends Event
  case class CommandUndone(command: Command) extends Event
  case class CommandRedone(command: Command) extends Event
  case class StateChanged(newState: Any) extends Event

  /**
   * オブザーバー
   */
  type Observer = Event => Unit

  /**
   * サブジェクト - オブザーバーを管理
   */
  class Subject:
    private val observers = ListBuffer.empty[Observer]

    def addObserver(observer: Observer): Unit =
      observers += observer

    def removeObserver(observer: Observer): Unit =
      observers -= observer

    def notifyObservers(event: Event): Unit =
      observers.foreach(_(event))

    def observerCount: Int = observers.size

  // ============================================================
  // 6. Command パターン
  // ============================================================

  /**
   * キャンバス - 図形を管理する
   */
  case class Canvas(shapes: Vector[Shape] = Vector.empty):
    def addShape(shape: Shape): Canvas = copy(shapes = shapes :+ shape)
    def removeShape(index: Int): Canvas =
      if index >= 0 && index < shapes.length then
        copy(shapes = shapes.patch(index, Nil, 1))
      else this
    def updateShape(index: Int, shape: Shape): Canvas =
      if index >= 0 && index < shapes.length then
        copy(shapes = shapes.updated(index, shape))
      else this
    def getShape(index: Int): Option[Shape] = shapes.lift(index)

  /**
   * コマンドの基底trait
   */
  trait Command:
    def execute(canvas: Canvas): Canvas
    def undo(canvas: Canvas): Canvas
    def describe: String

  /**
   * 図形追加コマンド
   */
  case class AddShapeCommand(shape: Shape) extends Command:
    def execute(canvas: Canvas): Canvas = canvas.addShape(shape)
    def undo(canvas: Canvas): Canvas = canvas.removeShape(canvas.shapes.length - 1)
    def describe: String = s"Add shape: ${shape.draw}"

  /**
   * 図形削除コマンド
   */
  case class RemoveShapeCommand(index: Int, removedShape: Option[Shape] = None) extends Command:
    def execute(canvas: Canvas): Canvas =
      canvas.removeShape(index)
    def undo(canvas: Canvas): Canvas =
      removedShape match
        case Some(shape) => Canvas(canvas.shapes.patch(index, Vector(shape), 0))
        case None => canvas
    def describe: String = s"Remove shape at index $index"
    def withRemovedShape(shape: Shape): RemoveShapeCommand = copy(removedShape = Some(shape))

  /**
   * 図形移動コマンド
   */
  case class MoveShapeCommand(index: Int, dx: Double, dy: Double) extends Command:
    def execute(canvas: Canvas): Canvas =
      canvas.getShape(index) match
        case Some(shape) => canvas.updateShape(index, shape.move(dx, dy))
        case None => canvas
    def undo(canvas: Canvas): Canvas =
      canvas.getShape(index) match
        case Some(shape) => canvas.updateShape(index, shape.move(-dx, -dy))
        case None => canvas
    def describe: String = s"Move shape[$index] by ($dx, $dy)"

  /**
   * 図形拡大縮小コマンド
   */
  case class ScaleShapeCommand(index: Int, factor: Double) extends Command:
    def execute(canvas: Canvas): Canvas =
      canvas.getShape(index) match
        case Some(shape) => canvas.updateShape(index, shape.scale(factor))
        case None => canvas
    def undo(canvas: Canvas): Canvas =
      canvas.getShape(index) match
        case Some(shape) => canvas.updateShape(index, shape.scale(1.0 / factor))
        case None => canvas
    def describe: String = s"Scale shape[$index] by $factor"

  /**
   * マクロコマンド - 複数のコマンドをまとめる
   */
  case class MacroCommand(commands: Vector[Command]) extends Command:
    def execute(canvas: Canvas): Canvas =
      commands.foldLeft(canvas)((c, cmd) => cmd.execute(c))
    def undo(canvas: Canvas): Canvas =
      commands.reverse.foldLeft(canvas)((c, cmd) => cmd.undo(c))
    def describe: String = s"Macro[${commands.map(_.describe).mkString(", ")}]"

  object MacroCommand:
    def apply(commands: Command*): MacroCommand = MacroCommand(commands.toVector)

  // ============================================================
  // 7. Command + Observer 統合
  // ============================================================

  /**
   * オブザーバブルキャンバス
   */
  class ObservableCanvas:
    private var canvas: Canvas = Canvas()
    private var history: Vector[Command] = Vector.empty
    private var redoStack: Vector[Command] = Vector.empty
    val subject: Subject = new Subject

    def getCanvas: Canvas = canvas
    def getHistory: Vector[Command] = history
    def getRedoStack: Vector[Command] = redoStack

    def executeCommand(command: Command): Unit =
      canvas = command.execute(canvas)
      history = history :+ command
      redoStack = Vector.empty
      subject.notifyObservers(CommandExecuted(command, command.describe))

    def undoLast(): Boolean =
      if history.isEmpty then false
      else
        val lastCommand = history.last
        canvas = lastCommand.undo(canvas)
        history = history.init
        redoStack = redoStack :+ lastCommand
        subject.notifyObservers(CommandUndone(lastCommand))
        true

    def redoLast(): Boolean =
      if redoStack.isEmpty then false
      else
        val command = redoStack.last
        canvas = command.execute(canvas)
        redoStack = redoStack.init
        history = history :+ command
        subject.notifyObservers(CommandRedone(command))
        true

    def canUndo: Boolean = history.nonEmpty
    def canRedo: Boolean = redoStack.nonEmpty

  // ============================================================
  // 8. Strategy パターンとの組み合わせ
  // ============================================================

  /**
   * レンダリング戦略
   */
  trait RenderStrategy:
    def render(canvas: Canvas): String

  object TextRenderStrategy extends RenderStrategy:
    def render(canvas: Canvas): String =
      canvas.shapes.zipWithIndex.map { case (shape, i) =>
        s"[$i] ${shape.draw}"
      }.mkString("\n")

  object JsonRenderStrategy extends RenderStrategy:
    def render(canvas: Canvas): String =
      val shapesJson = canvas.shapes.map(shapeToJson).mkString(",\n  ")
      s"{\n  \"shapes\": [\n  $shapesJson\n  ]\n}"

    private def shapeToJson(shape: Shape): String = shape match
      case Circle(x, y, r) => s"""{"type":"circle","x":$x,"y":$y,"radius":$r}"""
      case Rectangle(x, y, w, h) => s"""{"type":"rectangle","x":$x,"y":$y,"width":$w,"height":$h}"""
      case Triangle(x1, y1, x2, y2, x3, y3) => s"""{"type":"triangle","points":[[$x1,$y1],[$x2,$y2],[$x3,$y3]]}"""
      case CompositeShape(shapes) => s"""{"type":"composite","shapes":[${shapes.map(shapeToJson).mkString(",")}]}"""
      case ColoredShape(inner, color) => s"""{"color":"$color",${shapeToJson(inner).drop(1)}"""
      case BorderedShape(inner, width) => s"""{"border":$width,${shapeToJson(inner).drop(1)}"""
      case JournaledShape(inner, _) => shapeToJson(inner)
      case _ => s"""{"type":"unknown"}"""

  object SvgRenderStrategy extends RenderStrategy:
    def render(canvas: Canvas): String =
      val shapeSvg = canvas.shapes.map(shapeToSvg).mkString("\n  ")
      s"""<svg xmlns="http://www.w3.org/2000/svg">
  $shapeSvg
</svg>"""

    private def shapeToSvg(shape: Shape): String = shape match
      case Circle(x, y, r) => s"""<circle cx="$x" cy="$y" r="$r" />"""
      case Rectangle(x, y, w, h) => s"""<rect x="$x" y="$y" width="$w" height="$h" />"""
      case Triangle(x1, y1, x2, y2, x3, y3) => s"""<polygon points="$x1,$y1 $x2,$y2 $x3,$y3" />"""
      case CompositeShape(shapes) => s"""<g>${shapes.map(shapeToSvg).mkString("")}</g>"""
      case ColoredShape(inner, color) =>
        val innerSvg = shapeToSvg(inner)
        innerSvg.replaceFirst("/>", s""" fill="$color" />""")
      case BorderedShape(inner, width) =>
        val innerSvg = shapeToSvg(inner)
        innerSvg.replaceFirst("/>", s""" stroke-width="$width" />""")
      case JournaledShape(inner, _) => shapeToSvg(inner)
      case _ => "<!-- unknown shape -->"

  // ============================================================
  // 9. Factory パターンとの組み合わせ
  // ============================================================

  /**
   * 図形ファクトリ
   */
  trait ShapeFactory:
    def createCircle(x: Double, y: Double, radius: Double): Shape
    def createRectangle(x: Double, y: Double, width: Double, height: Double): Shape

  object SimpleShapeFactory extends ShapeFactory:
    def createCircle(x: Double, y: Double, radius: Double): Shape = Circle(x, y, radius)
    def createRectangle(x: Double, y: Double, width: Double, height: Double): Shape = Rectangle(x, y, width, height)

  class ColoredShapeFactory(color: String) extends ShapeFactory:
    def createCircle(x: Double, y: Double, radius: Double): Shape =
      ColoredShape(Circle(x, y, radius), color)
    def createRectangle(x: Double, y: Double, width: Double, height: Double): Shape =
      ColoredShape(Rectangle(x, y, width, height), color)

  class JournaledShapeFactory extends ShapeFactory:
    def createCircle(x: Double, y: Double, radius: Double): Shape =
      JournaledShape(Circle(x, y, radius))
    def createRectangle(x: Double, y: Double, width: Double, height: Double): Shape =
      JournaledShape(Rectangle(x, y, width, height))

  // ============================================================
  // 10. Visitor パターンとの組み合わせ
  // ============================================================

  /**
   * 図形ビジター
   */
  trait ShapeVisitor[T]:
    def visitCircle(circle: Circle): T
    def visitRectangle(rectangle: Rectangle): T
    def visitTriangle(triangle: Triangle): T
    def visitComposite(composite: CompositeShape): T
    def visitColored(colored: ColoredShape): T
    def visitBordered(bordered: BorderedShape): T
    def visitJournaled(journaled: JournaledShape): T

  object ShapeVisitor:
    def visit[T](shape: Shape, visitor: ShapeVisitor[T]): T = shape match
      case c: Circle => visitor.visitCircle(c)
      case r: Rectangle => visitor.visitRectangle(r)
      case t: Triangle => visitor.visitTriangle(t)
      case comp: CompositeShape => visitor.visitComposite(comp)
      case col: ColoredShape => visitor.visitColored(col)
      case bor: BorderedShape => visitor.visitBordered(bor)
      case jour: JournaledShape => visitor.visitJournaled(jour)

  /**
   * 面積計算ビジター
   */
  object AreaVisitor extends ShapeVisitor[Double]:
    def visitCircle(c: Circle): Double = c.area
    def visitRectangle(r: Rectangle): Double = r.area
    def visitTriangle(t: Triangle): Double = t.area
    def visitComposite(comp: CompositeShape): Double =
      comp.shapes.map(s => ShapeVisitor.visit(s, this)).sum
    def visitColored(col: ColoredShape): Double = ShapeVisitor.visit(col.shape, this)
    def visitBordered(bor: BorderedShape): Double = ShapeVisitor.visit(bor.shape, this)
    def visitJournaled(jour: JournaledShape): Double = ShapeVisitor.visit(jour.shape, this)

  /**
   * 境界ボックス計算ビジター
   */
  case class BoundingBox(minX: Double, minY: Double, maxX: Double, maxY: Double):
    def width: Double = maxX - minX
    def height: Double = maxY - minY
    def merge(other: BoundingBox): BoundingBox =
      BoundingBox(
        math.min(minX, other.minX),
        math.min(minY, other.minY),
        math.max(maxX, other.maxX),
        math.max(maxY, other.maxY)
      )

  object BoundingBoxVisitor extends ShapeVisitor[BoundingBox]:
    def visitCircle(c: Circle): BoundingBox =
      BoundingBox(c.x - c.radius, c.y - c.radius, c.x + c.radius, c.y + c.radius)
    def visitRectangle(r: Rectangle): BoundingBox =
      BoundingBox(r.x, r.y, r.x + r.width, r.y + r.height)
    def visitTriangle(t: Triangle): BoundingBox =
      BoundingBox(
        List(t.x1, t.x2, t.x3).min,
        List(t.y1, t.y2, t.y3).min,
        List(t.x1, t.x2, t.x3).max,
        List(t.y1, t.y2, t.y3).max
      )
    def visitComposite(comp: CompositeShape): BoundingBox =
      if comp.shapes.isEmpty then BoundingBox(0, 0, 0, 0)
      else comp.shapes.map(s => ShapeVisitor.visit(s, this)).reduce(_.merge(_))
    def visitColored(col: ColoredShape): BoundingBox = ShapeVisitor.visit(col.shape, this)
    def visitBordered(bor: BorderedShape): BoundingBox = ShapeVisitor.visit(bor.shape, this)
    def visitJournaled(jour: JournaledShape): BoundingBox = ShapeVisitor.visit(jour.shape, this)

  // ============================================================
  // 11. DSL
  // ============================================================

  object DSL:
    def circle(x: Double, y: Double, radius: Double): Circle = Circle(x, y, radius)
    def rectangle(x: Double, y: Double, width: Double, height: Double): Rectangle = Rectangle(x, y, width, height)
    def triangle(x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double): Triangle =
      Triangle(x1, y1, x2, y2, x3, y3)

    def composite(shapes: Shape*): CompositeShape = CompositeShape(shapes.toVector)

    extension (shape: Shape)
      def withColor(color: String): ColoredShape = ColoredShape(shape, color)
      def withBorder(width: Int): BorderedShape = BorderedShape(shape, width)
      def withJournal: JournaledShape = JournaledShape(shape)

    extension (canvas: ObservableCanvas)
      def +=(shape: Shape): Unit = canvas.executeCommand(AddShapeCommand(shape))
      def move(index: Int, dx: Double, dy: Double): Unit =
        canvas.executeCommand(MoveShapeCommand(index, dx, dy))
      def scale(index: Int, factor: Double): Unit =
        canvas.executeCommand(ScaleShapeCommand(index, factor))

  // ============================================================
  // 12. ログオブザーバー
  // ============================================================

  class LogObserver:
    private val logs = ListBuffer.empty[String]

    val observer: Observer = {
      case CommandExecuted(_, desc) => logs += s"Executed: $desc"
      case CommandUndone(cmd) => logs += s"Undone: ${cmd.describe}"
      case CommandRedone(cmd) => logs += s"Redone: ${cmd.describe}"
      case StateChanged(state) => logs += s"State changed: $state"
    }

    def getLogs: List[String] = logs.toList
    def clear(): Unit = logs.clear()
