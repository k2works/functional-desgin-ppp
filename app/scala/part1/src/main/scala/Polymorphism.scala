package polymorphism

/**
 * 第3章: 多態性とディスパッチ
 *
 * Scala における多態性の実現方法を学びます。
 * トレイト、sealed trait、パターンマッチング、型クラスを活用した
 * 柔軟な多態的設計パターンを扱います。
 */
object Polymorphism:

  // =============================================================================
  // 1. Sealed Trait による多態性（代数的データ型）
  // =============================================================================

  /**
   * 図形を表す sealed trait
   * パターンマッチングで網羅性がチェックされる
   */
  sealed trait Shape
  case class Rectangle(width: Double, height: Double) extends Shape
  case class Circle(radius: Double) extends Shape
  case class Triangle(base: Double, height: Double) extends Shape

  /**
   * 図形の面積を計算する
   * パターンマッチングによるディスパッチ
   */
  def calculateArea(shape: Shape): Double = shape match
    case Rectangle(w, h) => w * h
    case Circle(r)       => Math.PI * r * r
    case Triangle(b, h)  => b * h / 2

  // =============================================================================
  // 2. 複合ディスパッチ（タプルによるパターンマッチング）
  // =============================================================================

  /**
   * 支払い方法
   */
  enum PaymentMethod:
    case CreditCard, BankTransfer, Cash

  /**
   * 通貨
   */
  enum Currency:
    case JPY, USD, EUR

  case class Payment(method: PaymentMethod, currency: Currency, amount: Int)
  case class PaymentResult(status: String, message: String, amount: Int, converted: Option[Int] = None)

  /**
   * 支払いを処理する（複合ディスパッチ）
   */
  def processPayment(payment: Payment): PaymentResult =
    import PaymentMethod.*, Currency.*
    (payment.method, payment.currency) match
      case (CreditCard, JPY) =>
        PaymentResult("processed", "クレジットカード（円）で処理しました", payment.amount)
      case (CreditCard, USD) =>
        PaymentResult("processed", "Credit card (USD) processed", payment.amount, Some(payment.amount * 150))
      case (BankTransfer, JPY) =>
        PaymentResult("pending", "銀行振込を受け付けました", payment.amount)
      case _ =>
        PaymentResult("error", "サポートされていない支払い方法です", payment.amount)

  // =============================================================================
  // 3. 階層的ディスパッチ（継承による）
  // =============================================================================

  /**
   * 口座タイプの階層
   */
  sealed trait Account:
    def balance: Int
    def interestRate: Double

  case class SavingsAccount(balance: Int) extends Account:
    val interestRate = 0.02

  case class PremiumSavingsAccount(balance: Int) extends Account:
    val interestRate = 0.05

  case class CheckingAccount(balance: Int) extends Account:
    val interestRate = 0.001

  /**
   * 利息を計算する
   */
  def calculateInterest(account: Account): Double =
    account.balance * account.interestRate

  // =============================================================================
  // 4. トレイト（Protocols に相当）
  // =============================================================================

  /**
   * 描画可能なオブジェクトのトレイト
   */
  trait Drawable:
    def draw: String
    def boundingBox: BoundingBox

  case class BoundingBox(x: Double, y: Double, width: Double, height: Double)

  /**
   * 変換可能なオブジェクトのトレイト
   */
  trait Transformable[T]:
    def translate(dx: Double, dy: Double): T
    def scale(factor: Double): T
    def rotate(angle: Double): T

  // =============================================================================
  // 5. トレイトを実装するケースクラス（Records に相当）
  // =============================================================================

  case class DrawableRectangle(x: Double, y: Double, width: Double, height: Double)
      extends Drawable with Transformable[DrawableRectangle]:

    def draw: String = s"Rectangle at ($x,$y) with size ${width}x$height"

    def boundingBox: BoundingBox = BoundingBox(x, y, width, height)

    def translate(dx: Double, dy: Double): DrawableRectangle =
      copy(x = x + dx, y = y + dy)

    def scale(factor: Double): DrawableRectangle =
      copy(width = width * factor, height = height * factor)

    def rotate(angle: Double): DrawableRectangle = this

  case class DrawableCircle(x: Double, y: Double, radius: Double)
      extends Drawable with Transformable[DrawableCircle]:

    def draw: String = s"Circle at ($x,$y) with radius $radius"

    def boundingBox: BoundingBox =
      BoundingBox(x - radius, y - radius, radius * 2, radius * 2)

    def translate(dx: Double, dy: Double): DrawableCircle =
      copy(x = x + dx, y = y + dy)

    def scale(factor: Double): DrawableCircle =
      copy(radius = radius * factor)

    def rotate(angle: Double): DrawableCircle = this

  // =============================================================================
  // 6. 型クラス（既存型への拡張）
  // =============================================================================

  /**
   * 文字列に変換可能な型クラス
   */
  trait Stringable[A]:
    def stringify(a: A): String

  object Stringable:
    def apply[A](using s: Stringable[A]): Stringable[A] = s

    given Stringable[Map[String, Any]] with
      def stringify(m: Map[String, Any]): String =
        "{" + m.map((k, v) => s"$k: $v").mkString(", ") + "}"

    given Stringable[List[Any]] with
      def stringify(l: List[Any]): String =
        "[" + l.mkString(", ") + "]"

    given Stringable[String] with
      def stringify(s: String): String = s

    given Stringable[Int] with
      def stringify(i: Int): String = i.toString

    given optionStringable[A](using s: Stringable[A]): Stringable[Option[A]] with
      def stringify(opt: Option[A]): String = opt match
        case Some(a) => s.stringify(a)
        case None    => "nil"

  /**
   * 型クラスを使用する拡張メソッド
   */
  extension [A](a: A)
    def toCustomString(using s: Stringable[A]): String = s.stringify(a)

  // =============================================================================
  // 7. コンポーネントパターン
  // =============================================================================

  /**
   * ライフサイクル管理トレイト
   */
  trait Lifecycle[T]:
    def start: T
    def stop: T

  case class DatabaseConnection(host: String, port: Int, connected: Boolean = false)
      extends Lifecycle[DatabaseConnection]:

    def start: DatabaseConnection =
      println(s"データベースに接続中: $host : $port")
      copy(connected = true)

    def stop: DatabaseConnection =
      println("データベース接続を切断中")
      copy(connected = false)

  case class WebServer(port: Int, db: DatabaseConnection, running: Boolean = false)
      extends Lifecycle[WebServer]:

    def start: WebServer =
      println(s"Webサーバーを起動中 ポート: $port")
      val startedDb = db.start
      copy(db = startedDb, running = true)

    def stop: WebServer =
      println("Webサーバーを停止中")
      val stoppedDb = db.stop
      copy(db = stoppedDb, running = false)

  // =============================================================================
  // 8. 条件分岐の置き換え（Strategy パターン）
  // =============================================================================

  /**
   * 通知送信トレイト
   */
  trait NotificationSender:
    def sendNotification(message: String): NotificationResult
    def deliveryTime: String

  case class NotificationResult(
    notificationType: String,
    to: String,
    body: String,
    status: String,
    subject: Option[String] = None,
    device: Option[String] = None
  )

  case class EmailNotification(to: String, subject: String = "通知") extends NotificationSender:
    def sendNotification(message: String): NotificationResult =
      NotificationResult(
        notificationType = "email",
        to = to,
        body = message,
        status = "sent",
        subject = Some(subject)
      )
    def deliveryTime: String = "1-2分"

  case class SMSNotification(phoneNumber: String) extends NotificationSender:
    def sendNotification(message: String): NotificationResult =
      val truncatedMessage = if message.length > 160 then message.take(157) else message
      NotificationResult(
        notificationType = "sms",
        to = phoneNumber,
        body = truncatedMessage,
        status = "sent"
      )
    def deliveryTime: String = "数秒"

  case class PushNotification(deviceToken: String) extends NotificationSender:
    def sendNotification(message: String): NotificationResult =
      NotificationResult(
        notificationType = "push",
        to = deviceToken,
        body = message,
        status = "sent",
        device = Some(deviceToken)
      )
    def deliveryTime: String = "即時"

  /**
   * ファクトリ関数
   */
  def createNotification(notificationType: String, opts: Map[String, String]): NotificationSender =
    notificationType match
      case "email" => EmailNotification(opts.getOrElse("to", ""), opts.getOrElse("subject", "通知"))
      case "sms"   => SMSNotification(opts.getOrElse("phone", ""))
      case "push"  => PushNotification(opts.getOrElse("device", ""))
      case _       => throw new IllegalArgumentException(s"未知の通知タイプ: $notificationType")

  // =============================================================================
  // 9. シリアライズ/デシリアライズ
  // =============================================================================

  /**
   * シリアライズフォーマット
   */
  enum SerializeFormat:
    case JSON, EDN, XML

  case class DeserializeResult(parsed: Boolean, format: SerializeFormat, data: Any)

  /**
   * フォーマットに応じてデシリアライズする
   */
  def deserialize(format: SerializeFormat, data: String): DeserializeResult =
    import SerializeFormat.*
    format match
      case JSON => DeserializeResult(parsed = true, format = JSON, data = data)
      case EDN  => DeserializeResult(parsed = true, format = EDN, data = Map("key" -> "value"))
      case XML  => throw new IllegalArgumentException(s"サポートされていないフォーマット: $format")
