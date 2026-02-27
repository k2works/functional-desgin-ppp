package polymorphism

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class PolymorphismSpec extends AnyFlatSpec with Matchers:

  import Polymorphism.*

  // =============================================================================
  // Sealed Trait による多態性
  // =============================================================================

  "calculateArea" should "長方形の面積を計算する" in {
    calculateArea(Rectangle(4, 5)) shouldBe 20.0
  }

  it should "円の面積を計算する" in {
    val area = calculateArea(Circle(3))
    Math.abs(area - Math.PI * 9) should be < 0.001
  }

  it should "三角形の面積を計算する" in {
    calculateArea(Triangle(6, 5)) shouldBe 15.0
  }

  // =============================================================================
  // 複合ディスパッチ
  // =============================================================================

  "processPayment" should "クレジットカード円決済を処理する" in {
    val result = processPayment(Payment(PaymentMethod.CreditCard, Currency.JPY, 1000))
    result.status shouldBe "processed"
    result.amount shouldBe 1000
  }

  it should "クレジットカードドル決済を変換する" in {
    val result = processPayment(Payment(PaymentMethod.CreditCard, Currency.USD, 100))
    result.status shouldBe "processed"
    result.converted shouldBe Some(15000)
  }

  it should "銀行振込を受け付ける" in {
    val result = processPayment(Payment(PaymentMethod.BankTransfer, Currency.JPY, 5000))
    result.status shouldBe "pending"
  }

  it should "サポートされていない方法でエラーを返す" in {
    val result = processPayment(Payment(PaymentMethod.Cash, Currency.EUR, 100))
    result.status shouldBe "error"
  }

  // =============================================================================
  // 階層的ディスパッチ
  // =============================================================================

  "calculateInterest" should "普通預金の利息を計算する" in {
    calculateInterest(SavingsAccount(10000)) shouldBe 200.0
  }

  it should "プレミアム預金の利息を計算する" in {
    calculateInterest(PremiumSavingsAccount(10000)) shouldBe 500.0
  }

  it should "当座預金の利息を計算する" in {
    calculateInterest(CheckingAccount(10000)) shouldBe 10.0
  }

  // =============================================================================
  // トレイトを実装するケースクラス
  // =============================================================================

  "DrawableRectangle" should "Drawable を実装する" in {
    val rect = DrawableRectangle(10, 20, 100, 50)
    rect.draw shouldBe "Rectangle at (10.0,20.0) with size 100.0x50.0"
    rect.boundingBox shouldBe BoundingBox(10, 20, 100, 50)
  }

  "DrawableCircle" should "Drawable を実装する" in {
    val circle = DrawableCircle(50, 50, 25)
    circle.draw shouldBe "Circle at (50.0,50.0) with radius 25.0"
    circle.boundingBox shouldBe BoundingBox(25, 25, 50, 50)
  }

  "DrawableRectangle" should "Transformable を実装する" in {
    val rect = DrawableRectangle(10, 20, 100, 50)
    val moved = rect.translate(5, 10)
    val scaled = rect.scale(2)

    moved.x shouldBe 15
    moved.y shouldBe 30
    scaled.width shouldBe 200
    scaled.height shouldBe 100
  }

  "DrawableCircle" should "Transformable を実装する" in {
    val circle = DrawableCircle(50, 50, 25)
    val moved = circle.translate(10, 10)
    val scaled = circle.scale(2)

    moved.x shouldBe 60
    moved.y shouldBe 60
    scaled.radius shouldBe 50
  }

  // =============================================================================
  // 型クラス
  // =============================================================================

  "Stringable type class" should "Map を文字列に変換する" in {
    val map: Map[String, Any] = Map("name" -> "田中", "age" -> 30)
    map.toCustomString shouldBe "{name: 田中, age: 30}"
  }

  it should "List を文字列に変換する" in {
    val list: List[Any] = List(1, 2, 3)
    list.toCustomString shouldBe "[1, 2, 3]"
  }

  it should "String をそのまま返す" in {
    "hello".toCustomString shouldBe "hello"
  }

  it should "Int を文字列に変換する" in {
    42.toCustomString shouldBe "42"
  }

  it should "Option[Int] を文字列に変換する" in {
    (Some(42): Option[Int]).toCustomString shouldBe "42"
    (None: Option[Int]).toCustomString shouldBe "nil"
  }

  // =============================================================================
  // コンポーネントパターン
  // =============================================================================

  "DatabaseConnection" should "ライフサイクルを管理する" in {
    val db = DatabaseConnection("localhost", 5432)
    val started = db.start
    val stopped = started.stop

    started.connected shouldBe true
    stopped.connected shouldBe false
  }

  "WebServer" should "データベースと共にライフサイクルを管理する" in {
    val db = DatabaseConnection("localhost", 5432)
    val server = WebServer(8080, db)
    val started = server.start
    val stopped = started.stop

    started.running shouldBe true
    started.db.connected shouldBe true
    stopped.running shouldBe false
    stopped.db.connected shouldBe false
  }

  // =============================================================================
  // 通知パターン
  // =============================================================================

  "EmailNotification" should "通知を送信する" in {
    val notification = EmailNotification("user@example.com", "テスト")
    val result = notification.sendNotification("メッセージ本文")

    result.notificationType shouldBe "email"
    result.to shouldBe "user@example.com"
    result.status shouldBe "sent"
  }

  "SMSNotification" should "長いメッセージを切り詰める" in {
    val notification = SMSNotification("090-1234-5678")
    val longMessage = "あ" * 200
    val result = notification.sendNotification(longMessage)

    result.notificationType shouldBe "sms"
    result.body.length shouldBe 157
  }

  "createNotification" should "ファクトリとして機能する" in {
    val email = createNotification("email", Map("to" -> "test@example.com"))
    val sms = createNotification("sms", Map("phone" -> "090-0000-0000"))
    val push = createNotification("push", Map("device" -> "token123"))

    email shouldBe a[EmailNotification]
    sms shouldBe a[SMSNotification]
    push shouldBe a[PushNotification]
  }

  it should "未知のタイプでエラーを投げる" in {
    an[IllegalArgumentException] should be thrownBy {
      createNotification("unknown", Map.empty)
    }
  }

  // =============================================================================
  // シリアライズとデシリアライズ
  // =============================================================================

  "deserialize" should "JSON フォーマットを処理する" in {
    val result = deserialize(SerializeFormat.JSON, """{"key": "value"}""")
    result.format shouldBe SerializeFormat.JSON
    result.parsed shouldBe true
  }

  it should "EDN フォーマットを処理する" in {
    val result = deserialize(SerializeFormat.EDN, """{:key "value"}""")
    result.format shouldBe SerializeFormat.EDN
    result.parsed shouldBe true
  }

  it should "サポートされていないフォーマットでエラーを投げる" in {
    an[IllegalArgumentException] should be thrownBy {
      deserialize(SerializeFormat.XML, "<root/>")
    }
  }
