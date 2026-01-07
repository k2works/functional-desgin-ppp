/**
  * 第12章: Visitor パターン
  * 
  * Visitor パターンは、データ構造と操作を分離し、
  * 既存のデータ構造を変更することなく新しい操作を追加できるようにするパターンです。
  */
package visitorpattern

// ============================================
// 1. Element: 図形の定義
// ============================================

/** 点 */
case class Point(x: Double, y: Double):
  def +(other: Point): Point = Point(x + other.x, y + other.y)
  def -(other: Point): Point = Point(x - other.x, y - other.y)
  def *(factor: Double): Point = Point(x * factor, y * factor)

/** 図形の基本トレイト */
sealed trait Shape:
  def translate(dx: Double, dy: Double): Shape
  def scale(factor: Double): Shape

/** 円 */
case class Circle(center: Point, radius: Double) extends Shape:
  def translate(dx: Double, dy: Double): Circle =
    copy(center = Point(center.x + dx, center.y + dy))
  
  def scale(factor: Double): Circle =
    copy(radius = radius * factor)

/** 正方形 */
case class Square(topLeft: Point, side: Double) extends Shape:
  def translate(dx: Double, dy: Double): Square =
    copy(topLeft = Point(topLeft.x + dx, topLeft.y + dy))
  
  def scale(factor: Double): Square =
    copy(side = side * factor)

/** 長方形 */
case class Rectangle(topLeft: Point, width: Double, height: Double) extends Shape:
  def translate(dx: Double, dy: Double): Rectangle =
    copy(topLeft = Point(topLeft.x + dx, topLeft.y + dy))
  
  def scale(factor: Double): Rectangle =
    copy(width = width * factor, height = height * factor)

/** 三角形 */
case class Triangle(p1: Point, p2: Point, p3: Point) extends Shape:
  def translate(dx: Double, dy: Double): Triangle =
    val offset = Point(dx, dy)
    copy(p1 = p1 + offset, p2 = p2 + offset, p3 = p3 + offset)
  
  def scale(factor: Double): Triangle =
    copy(p1 = p1 * factor, p2 = p2 * factor, p3 = p3 * factor)

/** 複合図形 */
case class CompositeShape(shapes: List[Shape]) extends Shape:
  def translate(dx: Double, dy: Double): CompositeShape =
    copy(shapes = shapes.map(_.translate(dx, dy)))
  
  def scale(factor: Double): CompositeShape =
    copy(shapes = shapes.map(_.scale(factor)))

// ============================================
// 2. Visitor トレイト（OOP スタイル）
// ============================================

/** Visitor インターフェース */
trait ShapeVisitor[A]:
  def visitCircle(circle: Circle): A
  def visitSquare(square: Square): A
  def visitRectangle(rectangle: Rectangle): A
  def visitTriangle(triangle: Triangle): A
  def visitComposite(composite: CompositeShape): A

/** Shape に accept メソッドを追加する拡張 */
extension (shape: Shape)
  def accept[A](visitor: ShapeVisitor[A]): A = shape match
    case c: Circle => visitor.visitCircle(c)
    case s: Square => visitor.visitSquare(s)
    case r: Rectangle => visitor.visitRectangle(r)
    case t: Triangle => visitor.visitTriangle(t)
    case cs: CompositeShape => visitor.visitComposite(cs)

// ============================================
// 3. 具体 Visitor: 面積計算
// ============================================

object AreaVisitor extends ShapeVisitor[Double]:
  def visitCircle(circle: Circle): Double =
    math.Pi * circle.radius * circle.radius
  
  def visitSquare(square: Square): Double =
    square.side * square.side
  
  def visitRectangle(rectangle: Rectangle): Double =
    rectangle.width * rectangle.height
  
  def visitTriangle(triangle: Triangle): Double =
    val Triangle(p1, p2, p3) = triangle
    math.abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2
  
  def visitComposite(composite: CompositeShape): Double =
    composite.shapes.map(_.accept(this)).sum

// ============================================
// 4. 具体 Visitor: 周囲長計算
// ============================================

object PerimeterVisitor extends ShapeVisitor[Double]:
  def visitCircle(circle: Circle): Double =
    2 * math.Pi * circle.radius
  
  def visitSquare(square: Square): Double =
    4 * square.side
  
  def visitRectangle(rectangle: Rectangle): Double =
    2 * (rectangle.width + rectangle.height)
  
  def visitTriangle(triangle: Triangle): Double =
    val Triangle(p1, p2, p3) = triangle
    distance(p1, p2) + distance(p2, p3) + distance(p3, p1)
  
  def visitComposite(composite: CompositeShape): Double =
    composite.shapes.map(_.accept(this)).sum
  
  private def distance(a: Point, b: Point): Double =
    math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2))

// ============================================
// 5. 具体 Visitor: JSON 変換
// ============================================

object JsonVisitor extends ShapeVisitor[String]:
  def visitCircle(circle: Circle): String =
    s"""{"type":"circle","center":{"x":${circle.center.x},"y":${circle.center.y}},"radius":${circle.radius}}"""
  
  def visitSquare(square: Square): String =
    s"""{"type":"square","topLeft":{"x":${square.topLeft.x},"y":${square.topLeft.y}},"side":${square.side}}"""
  
  def visitRectangle(rectangle: Rectangle): String =
    s"""{"type":"rectangle","topLeft":{"x":${rectangle.topLeft.x},"y":${rectangle.topLeft.y}},"width":${rectangle.width},"height":${rectangle.height}}"""
  
  def visitTriangle(triangle: Triangle): String =
    s"""{"type":"triangle","p1":{"x":${triangle.p1.x},"y":${triangle.p1.y}},"p2":{"x":${triangle.p2.x},"y":${triangle.p2.y}},"p3":{"x":${triangle.p3.x},"y":${triangle.p3.y}}}"""
  
  def visitComposite(composite: CompositeShape): String =
    val shapesJson = composite.shapes.map(_.accept(this)).mkString(",")
    s"""{"type":"composite","shapes":[$shapesJson]}"""

// ============================================
// 6. 具体 Visitor: XML 変換
// ============================================

object XmlVisitor extends ShapeVisitor[String]:
  def visitCircle(circle: Circle): String =
    s"""<circle><center x="${circle.center.x}" y="${circle.center.y}"/><radius>${circle.radius}</radius></circle>"""
  
  def visitSquare(square: Square): String =
    s"""<square><topLeft x="${square.topLeft.x}" y="${square.topLeft.y}"/><side>${square.side}</side></square>"""
  
  def visitRectangle(rectangle: Rectangle): String =
    s"""<rectangle><topLeft x="${rectangle.topLeft.x}" y="${rectangle.topLeft.y}"/><width>${rectangle.width}</width><height>${rectangle.height}</height></rectangle>"""
  
  def visitTriangle(triangle: Triangle): String =
    s"""<triangle><p1 x="${triangle.p1.x}" y="${triangle.p1.y}"/><p2 x="${triangle.p2.x}" y="${triangle.p2.y}"/><p3 x="${triangle.p3.x}" y="${triangle.p3.y}"/></triangle>"""
  
  def visitComposite(composite: CompositeShape): String =
    val shapesXml = composite.shapes.map(_.accept(this)).mkString
    s"""<composite>$shapesXml</composite>"""

// ============================================
// 7. 具体 Visitor: バウンディングボックス計算
// ============================================

/** バウンディングボックス */
case class BoundingBox(minX: Double, minY: Double, maxX: Double, maxY: Double):
  def width: Double = maxX - minX
  def height: Double = maxY - minY
  def center: Point = Point((minX + maxX) / 2, (minY + maxY) / 2)
  
  def union(other: BoundingBox): BoundingBox =
    BoundingBox(
      math.min(minX, other.minX),
      math.min(minY, other.minY),
      math.max(maxX, other.maxX),
      math.max(maxY, other.maxY)
    )

object BoundingBoxVisitor extends ShapeVisitor[BoundingBox]:
  def visitCircle(circle: Circle): BoundingBox =
    val r = circle.radius
    BoundingBox(
      circle.center.x - r, circle.center.y - r,
      circle.center.x + r, circle.center.y + r
    )
  
  def visitSquare(square: Square): BoundingBox =
    BoundingBox(
      square.topLeft.x, square.topLeft.y,
      square.topLeft.x + square.side, square.topLeft.y + square.side
    )
  
  def visitRectangle(rectangle: Rectangle): BoundingBox =
    BoundingBox(
      rectangle.topLeft.x, rectangle.topLeft.y,
      rectangle.topLeft.x + rectangle.width, rectangle.topLeft.y + rectangle.height
    )
  
  def visitTriangle(triangle: Triangle): BoundingBox =
    val xs = List(triangle.p1.x, triangle.p2.x, triangle.p3.x)
    val ys = List(triangle.p1.y, triangle.p2.y, triangle.p3.y)
    BoundingBox(xs.min, ys.min, xs.max, ys.max)
  
  def visitComposite(composite: CompositeShape): BoundingBox =
    composite.shapes.map(_.accept(this)).reduce(_ union _)

// ============================================
// 8. 具体 Visitor: 描画コマンド生成
// ============================================

/** 描画コマンド */
sealed trait DrawCommand
case class DrawCircle(center: Point, radius: Double, stroke: String = "black", fill: String = "none") extends DrawCommand
case class DrawRect(topLeft: Point, width: Double, height: Double, stroke: String = "black", fill: String = "none") extends DrawCommand
case class DrawPolygon(points: List[Point], stroke: String = "black", fill: String = "none") extends DrawCommand
case class DrawGroup(commands: List[DrawCommand]) extends DrawCommand

object DrawVisitor extends ShapeVisitor[DrawCommand]:
  def visitCircle(circle: Circle): DrawCommand =
    DrawCircle(circle.center, circle.radius)
  
  def visitSquare(square: Square): DrawCommand =
    DrawRect(square.topLeft, square.side, square.side)
  
  def visitRectangle(rectangle: Rectangle): DrawCommand =
    DrawRect(rectangle.topLeft, rectangle.width, rectangle.height)
  
  def visitTriangle(triangle: Triangle): DrawCommand =
    DrawPolygon(List(triangle.p1, triangle.p2, triangle.p3))
  
  def visitComposite(composite: CompositeShape): DrawCommand =
    DrawGroup(composite.shapes.map(_.accept(this)))

// ============================================
// 9. 型クラスベースの Visitor パターン
// ============================================

/** 型クラス: シリアライズ可能 */
trait Serializable[A]:
  def toJson(a: A): String
  def toXml(a: A): String

object Serializable:
  given Serializable[Circle] with
    def toJson(c: Circle): String =
      s"""{"type":"circle","center":{"x":${c.center.x},"y":${c.center.y}},"radius":${c.radius}}"""
    def toXml(c: Circle): String =
      s"""<circle><center x="${c.center.x}" y="${c.center.y}"/><radius>${c.radius}</radius></circle>"""
  
  given Serializable[Square] with
    def toJson(s: Square): String =
      s"""{"type":"square","topLeft":{"x":${s.topLeft.x},"y":${s.topLeft.y}},"side":${s.side}}"""
    def toXml(s: Square): String =
      s"""<square><topLeft x="${s.topLeft.x}" y="${s.topLeft.y}"/><side>${s.side}</side></square>"""
  
  given Serializable[Rectangle] with
    def toJson(r: Rectangle): String =
      s"""{"type":"rectangle","topLeft":{"x":${r.topLeft.x},"y":${r.topLeft.y}},"width":${r.width},"height":${r.height}}"""
    def toXml(r: Rectangle): String =
      s"""<rectangle><topLeft x="${r.topLeft.x}" y="${r.topLeft.y}"/><width>${r.width}</width><height>${r.height}</height></rectangle>"""

/** 型クラス: 面積計算可能 */
trait HasArea[A]:
  def area(a: A): Double

object HasArea:
  given HasArea[Circle] with
    def area(c: Circle): Double = math.Pi * c.radius * c.radius
  
  given HasArea[Square] with
    def area(s: Square): Double = s.side * s.side
  
  given HasArea[Rectangle] with
    def area(r: Rectangle): Double = r.width * r.height
  
  given HasArea[Triangle] with
    def area(t: Triangle): Double =
      math.abs((t.p2.x - t.p1.x) * (t.p3.y - t.p1.y) - (t.p3.x - t.p1.x) * (t.p2.y - t.p1.y)) / 2

/** 型クラス: 周囲長計算可能 */
trait HasPerimeter[A]:
  def perimeter(a: A): Double

object HasPerimeter:
  given HasPerimeter[Circle] with
    def perimeter(c: Circle): Double = 2 * math.Pi * c.radius
  
  given HasPerimeter[Square] with
    def perimeter(s: Square): Double = 4 * s.side
  
  given HasPerimeter[Rectangle] with
    def perimeter(r: Rectangle): Double = 2 * (r.width + r.height)

// 型クラス用の拡張メソッド
extension [A](a: A)
  def toJson(using s: Serializable[A]): String = s.toJson(a)
  def toXml(using s: Serializable[A]): String = s.toXml(a)
  def area(using ha: HasArea[A]): Double = ha.area(a)
  def perimeter(using hp: HasPerimeter[A]): Double = hp.perimeter(a)

// ============================================
// 10. パターンマッチベースの Visitor
// ============================================

object PatternMatchVisitor:
  /** 面積計算（パターンマッチ版） */
  def calculateArea(shape: Shape): Double = shape match
    case Circle(_, radius) => math.Pi * radius * radius
    case Square(_, side) => side * side
    case Rectangle(_, width, height) => width * height
    case Triangle(p1, p2, p3) =>
      math.abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2
    case CompositeShape(shapes) => shapes.map(calculateArea).sum
  
  /** 周囲長計算（パターンマッチ版） */
  def calculatePerimeter(shape: Shape): Double = shape match
    case Circle(_, radius) => 2 * math.Pi * radius
    case Square(_, side) => 4 * side
    case Rectangle(_, width, height) => 2 * (width + height)
    case Triangle(p1, p2, p3) =>
      distance(p1, p2) + distance(p2, p3) + distance(p3, p1)
    case CompositeShape(shapes) => shapes.map(calculatePerimeter).sum
  
  /** JSON 変換（パターンマッチ版） */
  def toJson(shape: Shape): String = shape match
    case Circle(center, radius) =>
      s"""{"type":"circle","center":{"x":${center.x},"y":${center.y}},"radius":$radius}"""
    case Square(topLeft, side) =>
      s"""{"type":"square","topLeft":{"x":${topLeft.x},"y":${topLeft.y}},"side":$side}"""
    case Rectangle(topLeft, width, height) =>
      s"""{"type":"rectangle","topLeft":{"x":${topLeft.x},"y":${topLeft.y}},"width":$width,"height":$height}"""
    case Triangle(p1, p2, p3) =>
      s"""{"type":"triangle","p1":{"x":${p1.x},"y":${p1.y}},"p2":{"x":${p2.x},"y":${p2.y}},"p3":{"x":${p3.x},"y":${p3.y}}}"""
    case CompositeShape(shapes) =>
      val shapesJson = shapes.map(toJson).mkString(",")
      s"""{"type":"composite","shapes":[$shapesJson]}"""
  
  private def distance(a: Point, b: Point): Double =
    math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2))

// ============================================
// 11. 式木（Expression Tree）の Visitor
// ============================================

/** 式木 */
sealed trait Expr

case class Num(value: Double) extends Expr
case class Var(name: String) extends Expr
case class Add(left: Expr, right: Expr) extends Expr
case class Sub(left: Expr, right: Expr) extends Expr
case class Mul(left: Expr, right: Expr) extends Expr
case class Div(left: Expr, right: Expr) extends Expr

/** 式木用 Visitor */
trait ExprVisitor[A]:
  def visitNum(num: Num): A
  def visitVar(v: Var): A
  def visitAdd(add: Add): A
  def visitSub(sub: Sub): A
  def visitMul(mul: Mul): A
  def visitDiv(div: Div): A

extension (expr: Expr)
  def accept[A](visitor: ExprVisitor[A]): A = expr match
    case n: Num => visitor.visitNum(n)
    case v: Var => visitor.visitVar(v)
    case a: Add => visitor.visitAdd(a)
    case s: Sub => visitor.visitSub(s)
    case m: Mul => visitor.visitMul(m)
    case d: Div => visitor.visitDiv(d)

/** 式評価 Visitor */
class EvalVisitor(env: Map[String, Double]) extends ExprVisitor[Double]:
  def visitNum(num: Num): Double = num.value
  def visitVar(v: Var): Double = env.getOrElse(v.name, 0.0)
  def visitAdd(add: Add): Double = add.left.accept(this) + add.right.accept(this)
  def visitSub(sub: Sub): Double = sub.left.accept(this) - sub.right.accept(this)
  def visitMul(mul: Mul): Double = mul.left.accept(this) * mul.right.accept(this)
  def visitDiv(div: Div): Double = div.left.accept(this) / div.right.accept(this)

object EvalVisitor:
  def apply(env: Map[String, Double] = Map.empty): EvalVisitor = new EvalVisitor(env)

/** 式を文字列化する Visitor */
object PrintVisitor extends ExprVisitor[String]:
  def visitNum(num: Num): String = num.value.toString
  def visitVar(v: Var): String = v.name
  def visitAdd(add: Add): String = s"(${add.left.accept(this)} + ${add.right.accept(this)})"
  def visitSub(sub: Sub): String = s"(${sub.left.accept(this)} - ${sub.right.accept(this)})"
  def visitMul(mul: Mul): String = s"(${mul.left.accept(this)} * ${mul.right.accept(this)})"
  def visitDiv(div: Div): String = s"(${div.left.accept(this)} / ${div.right.accept(this)})"

/** 変数を収集する Visitor */
object VarCollector extends ExprVisitor[Set[String]]:
  def visitNum(num: Num): Set[String] = Set.empty
  def visitVar(v: Var): Set[String] = Set(v.name)
  def visitAdd(add: Add): Set[String] = add.left.accept(this) ++ add.right.accept(this)
  def visitSub(sub: Sub): Set[String] = sub.left.accept(this) ++ sub.right.accept(this)
  def visitMul(mul: Mul): Set[String] = mul.left.accept(this) ++ mul.right.accept(this)
  def visitDiv(div: Div): Set[String] = div.left.accept(this) ++ div.right.accept(this)

/** 式を簡約する Visitor */
object SimplifyVisitor extends ExprVisitor[Expr]:
  def visitNum(num: Num): Expr = num
  def visitVar(v: Var): Expr = v
  
  def visitAdd(add: Add): Expr =
    (add.left.accept(this), add.right.accept(this)) match
      case (Num(0), r) => r
      case (l, Num(0)) => l
      case (Num(a), Num(b)) => Num(a + b)
      case (l, r) => Add(l, r)
  
  def visitSub(sub: Sub): Expr =
    (sub.left.accept(this), sub.right.accept(this)) match
      case (l, Num(0)) => l
      case (Num(a), Num(b)) => Num(a - b)
      case (l, r) if l == r => Num(0)
      case (l, r) => Sub(l, r)
  
  def visitMul(mul: Mul): Expr =
    (mul.left.accept(this), mul.right.accept(this)) match
      case (Num(0), _) => Num(0)
      case (_, Num(0)) => Num(0)
      case (Num(1), r) => r
      case (l, Num(1)) => l
      case (Num(a), Num(b)) => Num(a * b)
      case (l, r) => Mul(l, r)
  
  def visitDiv(div: Div): Expr =
    (div.left.accept(this), div.right.accept(this)) match
      case (Num(0), _) => Num(0)
      case (l, Num(1)) => l
      case (Num(a), Num(b)) if b != 0 => Num(a / b)
      case (l, r) => Div(l, r)

// ============================================
// 12. ファイルシステム Visitor
// ============================================

/** ファイルシステムエントリ */
sealed trait FileEntry:
  def name: String

case class File(name: String, size: Long, content: String = "") extends FileEntry
case class Directory(name: String, entries: List[FileEntry] = Nil) extends FileEntry

/** ファイルシステム Visitor */
trait FileVisitor[A]:
  def visitFile(file: File): A
  def visitDirectory(dir: Directory): A

extension (entry: FileEntry)
  def accept[A](visitor: FileVisitor[A]): A = entry match
    case f: File => visitor.visitFile(f)
    case d: Directory => visitor.visitDirectory(d)

/** サイズ計算 Visitor */
object SizeVisitor extends FileVisitor[Long]:
  def visitFile(file: File): Long = file.size
  def visitDirectory(dir: Directory): Long =
    dir.entries.map(_.accept(this)).sum

/** ファイル数カウント Visitor */
object FileCountVisitor extends FileVisitor[Int]:
  def visitFile(file: File): Int = 1
  def visitDirectory(dir: Directory): Int =
    dir.entries.map(_.accept(this)).sum

/** パス一覧 Visitor */
class PathListVisitor(basePath: String = "") extends FileVisitor[List[String]]:
  def visitFile(file: File): List[String] =
    List(s"$basePath/${file.name}")
  
  def visitDirectory(dir: Directory): List[String] =
    val currentPath = s"$basePath/${dir.name}"
    currentPath :: dir.entries.flatMap { entry =>
      entry.accept(new PathListVisitor(currentPath))
    }

/** 検索 Visitor */
class SearchVisitor(predicate: FileEntry => Boolean) extends FileVisitor[List[FileEntry]]:
  def visitFile(file: File): List[FileEntry] =
    if predicate(file) then List(file) else Nil
  
  def visitDirectory(dir: Directory): List[FileEntry] =
    val dirMatch = if predicate(dir) then List(dir) else Nil
    dirMatch ++ dir.entries.flatMap(_.accept(this))
