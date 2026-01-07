/**
 * 第7章: Composite パターン
 * 
 * Composite パターンは、オブジェクトをツリー構造で構成し、
 * 個々のオブジェクトとオブジェクトの集合を同じように扱うことができるようにするパターンです。
 */
package compositepattern

// ============================================
// 1. Shape の例 - 図形の Composite パターン
// ============================================

/** 2D座標 */
case class Point(x: Double, y: Double):
  def +(other: Point): Point = Point(x + other.x, y + other.y)
  def *(factor: Double): Point = Point(x * factor, y * factor)

/** 図形の共通インターフェース（sealed trait） */
sealed trait Shape:
  /** 図形を移動する */
  def translate(dx: Double, dy: Double): Shape
  
  /** 図形を拡大/縮小する */
  def scale(factor: Double): Shape
  
  /** 面積を計算する */
  def area: Double
  
  /** バウンディングボックスを取得 */
  def boundingBox: BoundingBox

/** バウンディングボックス */
case class BoundingBox(topLeft: Point, bottomRight: Point):
  def width: Double = bottomRight.x - topLeft.x
  def height: Double = bottomRight.y - topLeft.y
  def area: Double = width * height
  
  /** 二つのバウンディングボックスを結合 */
  def union(other: BoundingBox): BoundingBox =
    BoundingBox(
      Point(math.min(topLeft.x, other.topLeft.x), math.min(topLeft.y, other.topLeft.y)),
      Point(math.max(bottomRight.x, other.bottomRight.x), math.max(bottomRight.y, other.bottomRight.y))
    )

/** 円（Leaf） */
case class Circle(center: Point, radius: Double) extends Shape:
  def translate(dx: Double, dy: Double): Circle =
    copy(center = Point(center.x + dx, center.y + dy))
  
  def scale(factor: Double): Circle =
    copy(radius = radius * factor)
  
  def area: Double = math.Pi * radius * radius
  
  def boundingBox: BoundingBox =
    BoundingBox(
      Point(center.x - radius, center.y - radius),
      Point(center.x + radius, center.y + radius)
    )

/** 正方形（Leaf） */
case class Square(topLeft: Point, side: Double) extends Shape:
  def translate(dx: Double, dy: Double): Square =
    copy(topLeft = Point(topLeft.x + dx, topLeft.y + dy))
  
  def scale(factor: Double): Square =
    copy(side = side * factor)
  
  def area: Double = side * side
  
  def boundingBox: BoundingBox =
    BoundingBox(topLeft, Point(topLeft.x + side, topLeft.y + side))

/** 長方形（Leaf） */
case class Rectangle(topLeft: Point, width: Double, height: Double) extends Shape:
  def translate(dx: Double, dy: Double): Rectangle =
    copy(topLeft = Point(topLeft.x + dx, topLeft.y + dy))
  
  def scale(factor: Double): Rectangle =
    copy(width = width * factor, height = height * factor)
  
  def area: Double = width * height
  
  def boundingBox: BoundingBox =
    BoundingBox(topLeft, Point(topLeft.x + width, topLeft.y + height))

/** 三角形（Leaf） */
case class Triangle(p1: Point, p2: Point, p3: Point) extends Shape:
  def translate(dx: Double, dy: Double): Triangle =
    Triangle(
      Point(p1.x + dx, p1.y + dy),
      Point(p2.x + dx, p2.y + dy),
      Point(p3.x + dx, p3.y + dy)
    )
  
  def scale(factor: Double): Triangle =
    // 中心を基準にスケール
    val cx = (p1.x + p2.x + p3.x) / 3
    val cy = (p1.y + p2.y + p3.y) / 3
    Triangle(
      Point(cx + (p1.x - cx) * factor, cy + (p1.y - cy) * factor),
      Point(cx + (p2.x - cx) * factor, cy + (p2.y - cy) * factor),
      Point(cx + (p3.x - cx) * factor, cy + (p3.y - cy) * factor)
    )
  
  def area: Double =
    math.abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2
  
  def boundingBox: BoundingBox =
    BoundingBox(
      Point(List(p1.x, p2.x, p3.x).min, List(p1.y, p2.y, p3.y).min),
      Point(List(p1.x, p2.x, p3.x).max, List(p1.y, p2.y, p3.y).max)
    )

/** 複合図形（Composite） */
case class CompositeShape(shapes: List[Shape] = Nil) extends Shape:
  def add(shape: Shape): CompositeShape = copy(shapes = shapes :+ shape)
  
  def remove(shape: Shape): CompositeShape = copy(shapes = shapes.filterNot(_ == shape))
  
  def translate(dx: Double, dy: Double): CompositeShape =
    copy(shapes = shapes.map(_.translate(dx, dy)))
  
  def scale(factor: Double): CompositeShape =
    copy(shapes = shapes.map(_.scale(factor)))
  
  def area: Double = shapes.map(_.area).sum
  
  def boundingBox: BoundingBox =
    shapes match
      case Nil => BoundingBox(Point(0, 0), Point(0, 0))
      case head :: tail => tail.foldLeft(head.boundingBox)((acc, s) => acc.union(s.boundingBox))
  
  def count: Int = shapes.length
  
  def flatten: List[Shape] =
    shapes.flatMap {
      case cs: CompositeShape => cs.flatten
      case s => List(s)
    }

object CompositeShape:
  def apply(shapes: Shape*): CompositeShape = CompositeShape(shapes.toList)

// ============================================
// 2. Switchable の例 - スイッチの Composite パターン
// ============================================

/** スイッチの共通インターフェース */
sealed trait Switchable:
  def turnOn: Switchable
  def turnOff: Switchable
  def isOn: Boolean

/** 照明（Leaf） */
case class Light(on: Boolean = false, name: String = "Light") extends Switchable:
  def turnOn: Light = copy(on = true)
  def turnOff: Light = copy(on = false)
  def isOn: Boolean = on

/** 調光可能な照明（Leaf） */
case class DimmableLight(intensity: Int = 0, name: String = "DimmableLight") extends Switchable:
  def turnOn: DimmableLight = copy(intensity = 100)
  def turnOff: DimmableLight = copy(intensity = 0)
  def isOn: Boolean = intensity > 0
  
  def setIntensity(value: Int): DimmableLight =
    copy(intensity = math.max(0, math.min(100, value)))

/** 扇風機（Leaf） */
case class Fan(speed: Int = 0, name: String = "Fan") extends Switchable:
  def turnOn: Fan = copy(speed = 3) // 中速でオン
  def turnOff: Fan = copy(speed = 0)
  def isOn: Boolean = speed > 0
  
  def setSpeed(value: Int): Fan =
    copy(speed = math.max(0, math.min(5, value)))

/** 複合スイッチ（Composite） */
case class CompositeSwitchable(
  switchables: List[Switchable] = Nil,
  name: String = "Group"
) extends Switchable:
  
  def add(switchable: Switchable): CompositeSwitchable =
    copy(switchables = switchables :+ switchable)
  
  def remove(switchable: Switchable): CompositeSwitchable =
    copy(switchables = switchables.filterNot(_ == switchable))
  
  def turnOn: CompositeSwitchable =
    copy(switchables = switchables.map(_.turnOn))
  
  def turnOff: CompositeSwitchable =
    copy(switchables = switchables.map(_.turnOff))
  
  def isOn: Boolean = switchables.exists(_.isOn)
  
  def allOn: Boolean = switchables.nonEmpty && switchables.forall(_.isOn)
  
  def count: Int = switchables.length
  
  def flatten: List[Switchable] =
    switchables.flatMap {
      case cs: CompositeSwitchable => cs.flatten
      case s => List(s)
    }

object CompositeSwitchable:
  def apply(switchables: Switchable*): CompositeSwitchable =
    CompositeSwitchable(switchables.toList)

// ============================================
// 3. FileSystem の例 - ファイルシステムの Composite パターン
// ============================================

/** ファイルシステムエントリの共通インターフェース */
sealed trait FileSystemEntry:
  def name: String
  def size: Long
  def path: String
  def find(predicate: FileSystemEntry => Boolean): List[FileSystemEntry]

/** ファイル（Leaf） */
case class File(name: String, size: Long, parentPath: String = "") extends FileSystemEntry:
  def path: String = if parentPath.isEmpty then name else s"$parentPath/$name"
  
  def find(predicate: FileSystemEntry => Boolean): List[FileSystemEntry] =
    if predicate(this) then List(this) else Nil

/** ディレクトリ（Composite） */
case class Directory(
  name: String,
  children: List[FileSystemEntry] = Nil,
  parentPath: String = ""
) extends FileSystemEntry:
  
  def path: String = if parentPath.isEmpty then name else s"$parentPath/$name"
  
  def add(entry: FileSystemEntry): Directory =
    val newEntry = entry match
      case f: File => f.copy(parentPath = path)
      case d: Directory => d.copy(parentPath = path)
    copy(children = children :+ newEntry)
  
  def remove(entryName: String): Directory =
    copy(children = children.filterNot(_.name == entryName))
  
  def size: Long = children.map(_.size).sum
  
  def find(predicate: FileSystemEntry => Boolean): List[FileSystemEntry] =
    val selfMatch = if predicate(this) then List(this) else Nil
    val childMatches = children.flatMap(_.find(predicate))
    selfMatch ++ childMatches
  
  def fileCount: Int =
    children.foldLeft(0) { (acc, entry) =>
      entry match
        case _: File => acc + 1
        case d: Directory => acc + d.fileCount
    }
  
  def directoryCount: Int =
    children.foldLeft(0) { (acc, entry) =>
      entry match
        case _: File => acc
        case d: Directory => acc + 1 + d.directoryCount
    }
  
  def listAll: List[String] =
    children.flatMap {
      case f: File => List(f.path)
      case d: Directory => 
        val childDir = d.copy(parentPath = path)
        childDir.path :: childDir.listAll
    }

// ============================================
// 4. Menu の例 - メニューの Composite パターン
// ============================================

/** メニュー項目の共通インターフェース */
sealed trait MenuItem:
  def name: String
  def price: BigDecimal
  def isVegetarian: Boolean
  def description: String

/** 単品メニュー（Leaf） */
case class SingleItem(
  name: String,
  price: BigDecimal,
  isVegetarian: Boolean,
  description: String
) extends MenuItem

/** セットメニュー（Composite） */
case class SetMenu(
  name: String,
  items: List[MenuItem] = Nil,
  discount: BigDecimal = BigDecimal(0),
  description: String = ""
) extends MenuItem:
  
  def add(item: MenuItem): SetMenu = copy(items = items :+ item)
  
  def remove(itemName: String): SetMenu =
    copy(items = items.filterNot(_.name == itemName))
  
  /** セットメニューの価格（割引適用後） */
  def price: BigDecimal =
    val total = items.map(_.price).sum
    total - discount
  
  /** セット内のすべてがベジタリアンならtrue */
  def isVegetarian: Boolean = items.forall(_.isVegetarian)
  
  def itemCount: Int = items.length
  
  /** 元の合計価格 */
  def originalPrice: BigDecimal = items.map(_.price).sum
  
  /** 割引率 */
  def discountRate: Double =
    if originalPrice > 0 then (discount / originalPrice).toDouble * 100 else 0

// ============================================
// 5. Expression の例 - 数式の Composite パターン
// ============================================

/** 数式の共通インターフェース */
sealed trait Expression:
  def evaluate: Double
  def simplify: Expression
  def variables: Set[String]

/** 数値（Leaf） */
case class Number(value: Double) extends Expression:
  def evaluate: Double = value
  def simplify: Expression = this
  def variables: Set[String] = Set.empty
  override def toString: String = value.toString

/** 変数（Leaf） */
case class Variable(name: String, value: Option[Double] = None) extends Expression:
  def evaluate: Double = value.getOrElse(
    throw new IllegalStateException(s"Variable $name has no value")
  )
  def simplify: Expression = value.map(Number(_)).getOrElse(this)
  def variables: Set[String] = if value.isEmpty then Set(name) else Set.empty
  override def toString: String = name

/** 加算（Composite） */
case class Add(left: Expression, right: Expression) extends Expression:
  def evaluate: Double = left.evaluate + right.evaluate
  
  def simplify: Expression =
    (left.simplify, right.simplify) match
      case (Number(0), r) => r
      case (l, Number(0)) => l
      case (Number(a), Number(b)) => Number(a + b)
      case (l, r) => Add(l, r)
  
  def variables: Set[String] = left.variables ++ right.variables
  override def toString: String = s"($left + $right)"

/** 減算（Composite） */
case class Subtract(left: Expression, right: Expression) extends Expression:
  def evaluate: Double = left.evaluate - right.evaluate
  
  def simplify: Expression =
    (left.simplify, right.simplify) match
      case (l, Number(0)) => l
      case (Number(a), Number(b)) => Number(a - b)
      case (l, r) if l == r => Number(0)
      case (l, r) => Subtract(l, r)
  
  def variables: Set[String] = left.variables ++ right.variables
  override def toString: String = s"($left - $right)"

/** 乗算（Composite） */
case class Multiply(left: Expression, right: Expression) extends Expression:
  def evaluate: Double = left.evaluate * right.evaluate
  
  def simplify: Expression =
    (left.simplify, right.simplify) match
      case (Number(0), _) => Number(0)
      case (_, Number(0)) => Number(0)
      case (Number(1), r) => r
      case (l, Number(1)) => l
      case (Number(a), Number(b)) => Number(a * b)
      case (l, r) => Multiply(l, r)
  
  def variables: Set[String] = left.variables ++ right.variables
  override def toString: String = s"($left * $right)"

/** 除算（Composite） */
case class Divide(left: Expression, right: Expression) extends Expression:
  def evaluate: Double =
    val r = right.evaluate
    if r == 0 then throw new ArithmeticException("Division by zero")
    else left.evaluate / r
  
  def simplify: Expression =
    (left.simplify, right.simplify) match
      case (Number(0), _) => Number(0)
      case (l, Number(1)) => l
      case (Number(a), Number(b)) if b != 0 => Number(a / b)
      case (l, r) if l == r => Number(1)
      case (l, r) => Divide(l, r)
  
  def variables: Set[String] = left.variables ++ right.variables
  override def toString: String = s"($left / $right)"

object Expression:
  /** 変数に値を束縛 */
  def bind(expr: Expression, bindings: Map[String, Double]): Expression =
    expr match
      case n: Number => n
      case v: Variable => bindings.get(v.name).map(Number(_)).getOrElse(v)
      case Add(l, r) => Add(bind(l, bindings), bind(r, bindings))
      case Subtract(l, r) => Subtract(bind(l, bindings), bind(r, bindings))
      case Multiply(l, r) => Multiply(bind(l, bindings), bind(r, bindings))
      case Divide(l, r) => Divide(bind(l, bindings), bind(r, bindings))
