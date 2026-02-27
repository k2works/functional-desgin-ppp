/**
  * 第13章: Abstract Factory パターン
  * 
  * Abstract Factory パターンは、関連するオブジェクトのファミリーを、
  * その具体的なクラスを指定することなく生成するためのインターフェースを提供します。
  */
package abstractfactorypattern

// ============================================
// 1. 図形 - Product
// ============================================

/** 色 */
case class Color(r: Int, g: Int, b: Int):
  def toHex: String = f"#$r%02X$g%02X$b%02X"

object Color:
  val Black = Color(0, 0, 0)
  val White = Color(255, 255, 255)
  val Red = Color(255, 0, 0)
  val Green = Color(0, 255, 0)
  val Blue = Color(0, 0, 255)
  val Transparent = Color(-1, -1, -1)

/** 点 */
case class Point(x: Double, y: Double)

/** 図形スタイル */
case class ShapeStyle(
  strokeColor: Color = Color.Black,
  strokeWidth: Double = 1.0,
  fillColor: Color = Color.Transparent
)

/** 図形の基本トレイト */
sealed trait Shape:
  def style: ShapeStyle
  def translate(dx: Double, dy: Double): Shape
  def scale(factor: Double): Shape
  def withStyle(newStyle: ShapeStyle): Shape

/** 円 */
case class Circle(center: Point, radius: Double, style: ShapeStyle = ShapeStyle()) extends Shape:
  def translate(dx: Double, dy: Double): Circle =
    copy(center = Point(center.x + dx, center.y + dy))
  
  def scale(factor: Double): Circle =
    copy(radius = radius * factor)
  
  def withStyle(newStyle: ShapeStyle): Circle =
    copy(style = newStyle)

/** 正方形 */
case class Square(topLeft: Point, side: Double, style: ShapeStyle = ShapeStyle()) extends Shape:
  def translate(dx: Double, dy: Double): Square =
    copy(topLeft = Point(topLeft.x + dx, topLeft.y + dy))
  
  def scale(factor: Double): Square =
    copy(side = side * factor)
  
  def withStyle(newStyle: ShapeStyle): Square =
    copy(style = newStyle)

/** 長方形 */
case class Rectangle(topLeft: Point, width: Double, height: Double, style: ShapeStyle = ShapeStyle()) extends Shape:
  def translate(dx: Double, dy: Double): Rectangle =
    copy(topLeft = Point(topLeft.x + dx, topLeft.y + dy))
  
  def scale(factor: Double): Rectangle =
    copy(width = width * factor, height = height * factor)
  
  def withStyle(newStyle: ShapeStyle): Rectangle =
    copy(style = newStyle)

/** 三角形 */
case class Triangle(p1: Point, p2: Point, p3: Point, style: ShapeStyle = ShapeStyle()) extends Shape:
  def translate(dx: Double, dy: Double): Triangle =
    copy(
      p1 = Point(p1.x + dx, p1.y + dy),
      p2 = Point(p2.x + dx, p2.y + dy),
      p3 = Point(p3.x + dx, p3.y + dy)
    )
  
  def scale(factor: Double): Triangle =
    copy(
      p1 = Point(p1.x * factor, p1.y * factor),
      p2 = Point(p2.x * factor, p2.y * factor),
      p3 = Point(p3.x * factor, p3.y * factor)
    )
  
  def withStyle(newStyle: ShapeStyle): Triangle =
    copy(style = newStyle)

// ============================================
// 2. ShapeFactory - Abstract Factory
// ============================================

/** 図形ファクトリの抽象インターフェース */
trait ShapeFactory:
  def createCircle(center: Point, radius: Double): Circle
  def createSquare(topLeft: Point, side: Double): Square
  def createRectangle(topLeft: Point, width: Double, height: Double): Rectangle
  def createTriangle(p1: Point, p2: Point, p3: Point): Triangle

// ============================================
// 3. StandardShapeFactory - Concrete Factory
// ============================================

/** 標準図形ファクトリ */
object StandardShapeFactory extends ShapeFactory:
  def createCircle(center: Point, radius: Double): Circle =
    Circle(center, radius)
  
  def createSquare(topLeft: Point, side: Double): Square =
    Square(topLeft, side)
  
  def createRectangle(topLeft: Point, width: Double, height: Double): Rectangle =
    Rectangle(topLeft, width, height)
  
  def createTriangle(p1: Point, p2: Point, p3: Point): Triangle =
    Triangle(p1, p2, p3)

// ============================================
// 4. OutlinedShapeFactory - Concrete Factory
// ============================================

/** 輪郭線付き図形ファクトリ */
class OutlinedShapeFactory(
  strokeColor: Color,
  strokeWidth: Double
) extends ShapeFactory:
  private val style = ShapeStyle(strokeColor = strokeColor, strokeWidth = strokeWidth)
  
  def createCircle(center: Point, radius: Double): Circle =
    Circle(center, radius, style)
  
  def createSquare(topLeft: Point, side: Double): Square =
    Square(topLeft, side, style)
  
  def createRectangle(topLeft: Point, width: Double, height: Double): Rectangle =
    Rectangle(topLeft, width, height, style)
  
  def createTriangle(p1: Point, p2: Point, p3: Point): Triangle =
    Triangle(p1, p2, p3, style)

object OutlinedShapeFactory:
  def apply(strokeColor: Color, strokeWidth: Double): OutlinedShapeFactory =
    new OutlinedShapeFactory(strokeColor, strokeWidth)

// ============================================
// 5. FilledShapeFactory - Concrete Factory
// ============================================

/** 塗りつぶし図形ファクトリ */
class FilledShapeFactory(
  fillColor: Color,
  strokeColor: Color = Color.Black,
  strokeWidth: Double = 1.0
) extends ShapeFactory:
  private val style = ShapeStyle(strokeColor, strokeWidth, fillColor)
  
  def createCircle(center: Point, radius: Double): Circle =
    Circle(center, radius, style)
  
  def createSquare(topLeft: Point, side: Double): Square =
    Square(topLeft, side, style)
  
  def createRectangle(topLeft: Point, width: Double, height: Double): Rectangle =
    Rectangle(topLeft, width, height, style)
  
  def createTriangle(p1: Point, p2: Point, p3: Point): Triangle =
    Triangle(p1, p2, p3, style)

object FilledShapeFactory:
  def apply(fillColor: Color): FilledShapeFactory =
    new FilledShapeFactory(fillColor)
  
  def apply(fillColor: Color, strokeColor: Color, strokeWidth: Double): FilledShapeFactory =
    new FilledShapeFactory(fillColor, strokeColor, strokeWidth)

// ============================================
// 6. UI コンポーネント - Product
// ============================================

/** UI テーマ */
enum Theme:
  case Light, Dark

/** ボタン */
trait Button:
  def label: String
  def theme: Theme
  def render: String
  def onClick(handler: () => Unit): Button

/** テキストフィールド */
trait TextField:
  def placeholder: String
  def theme: Theme
  def render: String
  def value: String
  def setValue(newValue: String): TextField

/** チェックボックス */
trait Checkbox:
  def label: String
  def checked: Boolean
  def theme: Theme
  def render: String
  def toggle: Checkbox

// ============================================
// 7. Windows UI 実装
// ============================================

case class WindowsButton(label: String, theme: Theme) extends Button:
  def render: String = s"[${if theme == Theme.Dark then "▓" else "░"} $label]"
  def onClick(handler: () => Unit): WindowsButton = this

case class WindowsTextField(placeholder: String, theme: Theme, value: String = "") extends TextField:
  def render: String = s"|${if value.isEmpty then placeholder else value}|"
  def setValue(newValue: String): WindowsTextField = copy(value = newValue)

case class WindowsCheckbox(label: String, checked: Boolean, theme: Theme) extends Checkbox:
  def render: String = s"[${if checked then "X" else " "}] $label"
  def toggle: WindowsCheckbox = copy(checked = !checked)

// ============================================
// 8. MacOS UI 実装
// ============================================

case class MacOSButton(label: String, theme: Theme) extends Button:
  def render: String = s"(${if theme == Theme.Dark then "●" else "○"} $label)"
  def onClick(handler: () => Unit): MacOSButton = this

case class MacOSTextField(placeholder: String, theme: Theme, value: String = "") extends TextField:
  def render: String = s"⌊${if value.isEmpty then placeholder else value}⌋"
  def setValue(newValue: String): MacOSTextField = copy(value = newValue)

case class MacOSCheckbox(label: String, checked: Boolean, theme: Theme) extends Checkbox:
  def render: String = s"(${if checked then "✓" else " "}) $label"
  def toggle: MacOSCheckbox = copy(checked = !checked)

// ============================================
// 9. Web UI 実装
// ============================================

case class WebButton(label: String, theme: Theme) extends Button:
  def render: String =
    val bgColor = if theme == Theme.Dark then "#333" else "#fff"
    s"""<button style="background:$bgColor">$label</button>"""
  def onClick(handler: () => Unit): WebButton = this

case class WebTextField(placeholder: String, theme: Theme, value: String = "") extends TextField:
  def render: String =
    s"""<input type="text" placeholder="$placeholder" value="$value"/>"""
  def setValue(newValue: String): WebTextField = copy(value = newValue)

case class WebCheckbox(label: String, checked: Boolean, theme: Theme) extends Checkbox:
  def render: String =
    val checkedAttr = if checked then " checked" else ""
    s"""<label><input type="checkbox"$checkedAttr/>$label</label>"""
  def toggle: WebCheckbox = copy(checked = !checked)

// ============================================
// 10. UIFactory - Abstract Factory
// ============================================

/** UI ファクトリの抽象インターフェース */
trait UIFactory:
  def theme: Theme
  def createButton(label: String): Button
  def createTextField(placeholder: String): TextField
  def createCheckbox(label: String, checked: Boolean = false): Checkbox

// ============================================
// 11. Concrete UI Factories
// ============================================

/** Windows UI ファクトリ */
class WindowsUIFactory(val theme: Theme = Theme.Light) extends UIFactory:
  def createButton(label: String): WindowsButton =
    WindowsButton(label, theme)
  
  def createTextField(placeholder: String): WindowsTextField =
    WindowsTextField(placeholder, theme)
  
  def createCheckbox(label: String, checked: Boolean = false): WindowsCheckbox =
    WindowsCheckbox(label, checked, theme)

object WindowsUIFactory:
  def apply(theme: Theme = Theme.Light): WindowsUIFactory = new WindowsUIFactory(theme)

/** MacOS UI ファクトリ */
class MacOSUIFactory(val theme: Theme = Theme.Light) extends UIFactory:
  def createButton(label: String): MacOSButton =
    MacOSButton(label, theme)
  
  def createTextField(placeholder: String): MacOSTextField =
    MacOSTextField(placeholder, theme)
  
  def createCheckbox(label: String, checked: Boolean = false): MacOSCheckbox =
    MacOSCheckbox(label, checked, theme)

object MacOSUIFactory:
  def apply(theme: Theme = Theme.Light): MacOSUIFactory = new MacOSUIFactory(theme)

/** Web UI ファクトリ */
class WebUIFactory(val theme: Theme = Theme.Light) extends UIFactory:
  def createButton(label: String): WebButton =
    WebButton(label, theme)
  
  def createTextField(placeholder: String): WebTextField =
    WebTextField(placeholder, theme)
  
  def createCheckbox(label: String, checked: Boolean = false): WebCheckbox =
    WebCheckbox(label, checked, theme)

object WebUIFactory:
  def apply(theme: Theme = Theme.Light): WebUIFactory = new WebUIFactory(theme)

// ============================================
// 12. Database コンポーネント - Product
// ============================================

/** クエリ結果 */
case class QueryResult(
  columns: List[String],
  rows: List[List[Any]],
  affectedRows: Int = 0
)

/** データベース接続 */
trait Connection:
  def database: String
  def isConnected: Boolean
  def connect(): Connection
  def disconnect(): Connection
  def execute(sql: String): QueryResult

/** クエリビルダー */
trait QueryBuilder:
  def select(columns: String*): QueryBuilder
  def from(table: String): QueryBuilder
  def where(condition: String): QueryBuilder
  def orderBy(column: String, ascending: Boolean = true): QueryBuilder
  def limit(n: Int): QueryBuilder
  def build: String

/** マイグレーション */
trait Migration:
  def version: Int
  def up: String
  def down: String

// ============================================
// 13. PostgreSQL 実装
// ============================================

case class PostgreSQLConnection(database: String, isConnected: Boolean = false) extends Connection:
  def connect(): PostgreSQLConnection = copy(isConnected = true)
  def disconnect(): PostgreSQLConnection = copy(isConnected = false)
  def execute(sql: String): QueryResult =
    QueryResult(List("result"), List(List(s"PostgreSQL: $sql")), 1)

class PostgreSQLQueryBuilder extends QueryBuilder:
  private var selectCols: List[String] = List("*")
  private var fromTable: String = ""
  private var whereClause: Option[String] = None
  private var orderByClause: Option[(String, Boolean)] = None
  private var limitClause: Option[Int] = None
  
  def select(columns: String*): PostgreSQLQueryBuilder =
    selectCols = columns.toList
    this
  
  def from(table: String): PostgreSQLQueryBuilder =
    fromTable = table
    this
  
  def where(condition: String): PostgreSQLQueryBuilder =
    whereClause = Some(condition)
    this
  
  def orderBy(column: String, ascending: Boolean = true): PostgreSQLQueryBuilder =
    orderByClause = Some((column, ascending))
    this
  
  def limit(n: Int): PostgreSQLQueryBuilder =
    limitClause = Some(n)
    this
  
  def build: String =
    val base = s"SELECT ${selectCols.mkString(", ")} FROM $fromTable"
    val where = whereClause.map(c => s" WHERE $c").getOrElse("")
    val order = orderByClause.map { case (col, asc) =>
      s" ORDER BY $col ${if asc then "ASC" else "DESC"}"
    }.getOrElse("")
    val limit = limitClause.map(n => s" LIMIT $n").getOrElse("")
    base + where + order + limit

// ============================================
// 14. MySQL 実装
// ============================================

case class MySQLConnection(database: String, isConnected: Boolean = false) extends Connection:
  def connect(): MySQLConnection = copy(isConnected = true)
  def disconnect(): MySQLConnection = copy(isConnected = false)
  def execute(sql: String): QueryResult =
    QueryResult(List("result"), List(List(s"MySQL: $sql")), 1)

class MySQLQueryBuilder extends QueryBuilder:
  private var selectCols: List[String] = List("*")
  private var fromTable: String = ""
  private var whereClause: Option[String] = None
  private var orderByClause: Option[(String, Boolean)] = None
  private var limitClause: Option[Int] = None
  
  def select(columns: String*): MySQLQueryBuilder =
    selectCols = columns.toList
    this
  
  def from(table: String): MySQLQueryBuilder =
    fromTable = s"`$table`"  // MySQL uses backticks
    this
  
  def where(condition: String): MySQLQueryBuilder =
    whereClause = Some(condition)
    this
  
  def orderBy(column: String, ascending: Boolean = true): MySQLQueryBuilder =
    orderByClause = Some((column, ascending))
    this
  
  def limit(n: Int): MySQLQueryBuilder =
    limitClause = Some(n)
    this
  
  def build: String =
    val base = s"SELECT ${selectCols.mkString(", ")} FROM $fromTable"
    val where = whereClause.map(c => s" WHERE $c").getOrElse("")
    val order = orderByClause.map { case (col, asc) =>
      s" ORDER BY $col ${if asc then "ASC" else "DESC"}"
    }.getOrElse("")
    val limit = limitClause.map(n => s" LIMIT $n").getOrElse("")
    base + where + order + limit

// ============================================
// 15. SQLite 実装
// ============================================

case class SQLiteConnection(database: String, isConnected: Boolean = false) extends Connection:
  def connect(): SQLiteConnection = copy(isConnected = true)
  def disconnect(): SQLiteConnection = copy(isConnected = false)
  def execute(sql: String): QueryResult =
    QueryResult(List("result"), List(List(s"SQLite: $sql")), 1)

class SQLiteQueryBuilder extends QueryBuilder:
  private var selectCols: List[String] = List("*")
  private var fromTable: String = ""
  private var whereClause: Option[String] = None
  private var orderByClause: Option[(String, Boolean)] = None
  private var limitClause: Option[Int] = None
  
  def select(columns: String*): SQLiteQueryBuilder =
    selectCols = columns.toList
    this
  
  def from(table: String): SQLiteQueryBuilder =
    fromTable = table
    this
  
  def where(condition: String): SQLiteQueryBuilder =
    whereClause = Some(condition)
    this
  
  def orderBy(column: String, ascending: Boolean = true): SQLiteQueryBuilder =
    orderByClause = Some((column, ascending))
    this
  
  def limit(n: Int): SQLiteQueryBuilder =
    limitClause = Some(n)
    this
  
  def build: String =
    val base = s"SELECT ${selectCols.mkString(", ")} FROM $fromTable"
    val where = whereClause.map(c => s" WHERE $c").getOrElse("")
    val order = orderByClause.map { case (col, asc) =>
      s" ORDER BY $col ${if asc then "ASC" else "DESC"}"
    }.getOrElse("")
    val limit = limitClause.map(n => s" LIMIT $n").getOrElse("")
    base + where + order + limit

// ============================================
// 16. DatabaseFactory - Abstract Factory
// ============================================

/** データベースファクトリの抽象インターフェース */
trait DatabaseFactory:
  def createConnection(database: String): Connection
  def createQueryBuilder(): QueryBuilder
  def databaseType: String

/** PostgreSQL ファクトリ */
object PostgreSQLFactory extends DatabaseFactory:
  def createConnection(database: String): PostgreSQLConnection =
    PostgreSQLConnection(database)
  
  def createQueryBuilder(): PostgreSQLQueryBuilder =
    new PostgreSQLQueryBuilder
  
  def databaseType: String = "PostgreSQL"

/** MySQL ファクトリ */
object MySQLFactory extends DatabaseFactory:
  def createConnection(database: String): MySQLConnection =
    MySQLConnection(database)
  
  def createQueryBuilder(): MySQLQueryBuilder =
    new MySQLQueryBuilder
  
  def databaseType: String = "MySQL"

/** SQLite ファクトリ */
object SQLiteFactory extends DatabaseFactory:
  def createConnection(database: String): SQLiteConnection =
    SQLiteConnection(database)
  
  def createQueryBuilder(): SQLiteQueryBuilder =
    new SQLiteQueryBuilder
  
  def databaseType: String = "SQLite"

// ============================================
// 17. 関数型アプローチ
// ============================================

object FunctionalFactory:
  /** 図形ファクトリを関数として表現 */
  type ShapeCreator[S <: Shape] = () => S
  
  /** ファクトリ設定 */
  case class FactoryConfig(
    strokeColor: Color = Color.Black,
    strokeWidth: Double = 1.0,
    fillColor: Color = Color.Transparent
  ):
    def style: ShapeStyle = ShapeStyle(strokeColor, strokeWidth, fillColor)
  
  /** 図形作成関数を生成 */
  def circleCreator(config: FactoryConfig)(center: Point, radius: Double): Circle =
    Circle(center, radius, config.style)
  
  def squareCreator(config: FactoryConfig)(topLeft: Point, side: Double): Square =
    Square(topLeft, side, config.style)
  
  def rectangleCreator(config: FactoryConfig)(topLeft: Point, width: Double, height: Double): Rectangle =
    Rectangle(topLeft, width, height, config.style)
  
  /** ファクトリを合成 */
  def composeFactory(
    baseConfig: FactoryConfig,
    modifiers: (FactoryConfig => FactoryConfig)*
  ): FactoryConfig =
    modifiers.foldLeft(baseConfig)((config, modifier) => modifier(config))
  
  /** 修飾子 */
  def withStroke(color: Color, width: Double): FactoryConfig => FactoryConfig =
    config => config.copy(strokeColor = color, strokeWidth = width)
  
  def withFill(color: Color): FactoryConfig => FactoryConfig =
    config => config.copy(fillColor = color)

// ============================================
// 18. ファクトリレジストリ
// ============================================

object FactoryRegistry:
  private var shapeFactories: Map[String, ShapeFactory] = Map(
    "standard" -> StandardShapeFactory,
    "outlined" -> OutlinedShapeFactory(Color.Black, 2.0),
    "filled" -> FilledShapeFactory(Color.Blue)
  )
  
  private var uiFactories: Map[String, UIFactory] = Map(
    "windows" -> WindowsUIFactory(),
    "macos" -> MacOSUIFactory(),
    "web" -> WebUIFactory()
  )
  
  private var dbFactories: Map[String, DatabaseFactory] = Map(
    "postgresql" -> PostgreSQLFactory,
    "mysql" -> MySQLFactory,
    "sqlite" -> SQLiteFactory
  )
  
  def registerShapeFactory(name: String, factory: ShapeFactory): Unit =
    shapeFactories = shapeFactories + (name -> factory)
  
  def getShapeFactory(name: String): Option[ShapeFactory] =
    shapeFactories.get(name)
  
  def registerUIFactory(name: String, factory: UIFactory): Unit =
    uiFactories = uiFactories + (name -> factory)
  
  def getUIFactory(name: String): Option[UIFactory] =
    uiFactories.get(name)
  
  def registerDatabaseFactory(name: String, factory: DatabaseFactory): Unit =
    dbFactories = dbFactories + (name -> factory)
  
  def getDatabaseFactory(name: String): Option[DatabaseFactory] =
    dbFactories.get(name)
