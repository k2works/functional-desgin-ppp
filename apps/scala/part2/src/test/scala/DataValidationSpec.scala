package datavalidation

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class DataValidationSpec extends AnyFlatSpec with Matchers:

  import DataValidation.*
  import Validated.*

  // =============================================================================
  // 基本的なバリデーション
  // =============================================================================

  "validateName" should "有効な名前を検証する" in {
    validateName("田中太郎") shouldBe Right("田中太郎")
  }

  it should "空の名前を拒否する" in {
    validateName("") shouldBe Left(List("名前は空にできません"))
  }

  it should "長すぎる名前を拒否する" in {
    validateName("a" * 101) shouldBe Left(List("名前は100文字以内である必要があります"))
  }

  "validateAge" should "有効な年齢を検証する" in {
    validateAge(25) shouldBe Right(25)
    validateAge(0) shouldBe Right(0)
    validateAge(150) shouldBe Right(150)
  }

  it should "負の年齢を拒否する" in {
    validateAge(-1) shouldBe Left(List("年齢は0以上である必要があります"))
  }

  it should "大きすぎる年齢を拒否する" in {
    validateAge(151) shouldBe Left(List("年齢は150以下である必要があります"))
  }

  "validateEmail" should "有効なメールを検証する" in {
    validateEmail("test@example.com") shouldBe Right("test@example.com")
  }

  it should "無効なメールを拒否する" in {
    validateEmail("invalid-email").isLeft shouldBe true
  }

  // =============================================================================
  // 列挙型
  // =============================================================================

  "Membership.fromString" should "有効な会員種別を変換する" in {
    Membership.fromString("gold") shouldBe Right(Membership.Gold)
    Membership.fromString("silver") shouldBe Right(Membership.Silver)
  }

  it should "無効な会員種別を拒否する" in {
    Membership.fromString("diamond").isLeft shouldBe true
  }

  // =============================================================================
  // Validated パターン
  // =============================================================================

  "Validated.combine" should "2つの有効な値を結合する" in {
    val result = combine(valid[String, Int](1), valid[String, Int](2))(_ + _)
    result shouldBe Valid(3)
  }

  it should "エラーを蓄積する" in {
    val result = combine(
      invalid[String, Int](List("error1")),
      invalid[String, Int](List("error2"))
    )(_ + _)
    result shouldBe Invalid(List("error1", "error2"))
  }

  "Validated.combine3" should "3つの値を結合する" in {
    val result = combine3(
      valid[String, Int](1),
      valid[String, Int](2),
      valid[String, Int](3)
    )(_ + _ + _)
    result shouldBe Valid(6)
  }

  // =============================================================================
  // ドメインモデル
  // =============================================================================

  "ProductId" should "有効な商品IDを検証する" in {
    ProductId("PROD-00001").isValid shouldBe true
    ProductId("PROD-99999").isValid shouldBe true
  }

  it should "無効な商品IDを拒否する" in {
    ProductId("PROD-1").isValid shouldBe false
    ProductId("PRD-00001").isValid shouldBe false
  }

  "ProductName" should "有効な商品名を検証する" in {
    ProductName("テスト商品").isValid shouldBe true
  }

  it should "空の商品名を拒否する" in {
    ProductName("").isValid shouldBe false
  }

  "Price" should "正の価格を検証する" in {
    Price(BigDecimal(1000)).isValid shouldBe true
  }

  it should "0以下の価格を拒否する" in {
    Price(BigDecimal(0)).isValid shouldBe false
    Price(BigDecimal(-100)).isValid shouldBe false
  }

  "Quantity" should "正の数量を検証する" in {
    Quantity(1).isValid shouldBe true
    Quantity(100).isValid shouldBe true
  }

  it should "0以下の数量を拒否する" in {
    Quantity(0).isValid shouldBe false
    Quantity(-1).isValid shouldBe false
  }

  "Product.create" should "有効な商品を作成する" in {
    val result = Product.create("PROD-00001", "テスト商品", BigDecimal(1000))
    result.isValid shouldBe true
  }

  it should "無効なデータで複数のエラーを返す" in {
    val result = Product.create("INVALID", "", BigDecimal(-100))
    result match
      case Invalid(errors) => errors.length should be >= 3
      case Valid(_)        => fail("Should be invalid")
  }

  // =============================================================================
  // 注文ドメインモデル
  // =============================================================================

  "OrderId" should "有効な注文IDを検証する" in {
    OrderId("ORD-00000001").isValid shouldBe true
  }

  it should "無効な注文IDを拒否する" in {
    OrderId("ORD-1").isValid shouldBe false
  }

  "CustomerId" should "有効な顧客IDを検証する" in {
    CustomerId("CUST-000001").isValid shouldBe true
  }

  "OrderItem.create" should "有効な注文アイテムを作成する" in {
    OrderItem.create("PROD-00001", 2, BigDecimal(1000)).isValid shouldBe true
  }

  // =============================================================================
  // 条件付きバリデーション（通知）
  // =============================================================================

  "Notification.createEmail" should "有効なメール通知を作成する" in {
    val result = Notification.createEmail("test@example.com", "テスト", "本文")
    result.isValid shouldBe true
  }

  it should "無効なメールアドレスを拒否する" in {
    val result = Notification.createEmail("invalid", "テスト", "本文")
    result.isValid shouldBe false
  }

  "Notification.createSMS" should "有効なSMS通知を作成する" in {
    val result = Notification.createSMS("090-1234-5678", "本文")
    result.isValid shouldBe true
  }

  it should "無効な電話番号を拒否する" in {
    val result = Notification.createSMS("invalid", "本文")
    result.isValid shouldBe false
  }

  "Notification.createPush" should "有効なPush通知を作成する" in {
    val result = Notification.createPush("token123", "本文")
    result.isValid shouldBe true
  }

  it should "空のデバイストークンを拒否する" in {
    val result = Notification.createPush("", "本文")
    result.isValid shouldBe false
  }

  // =============================================================================
  // バリデーションユーティリティ
  // =============================================================================

  "validatePerson" should "有効なデータで valid: true を返す" in {
    val result = validatePerson("田中", 30)
    result.valid shouldBe true
    result.data shouldBe Some(Person("田中", 30))
  }

  it should "無効なデータで valid: false を返す" in {
    val result = validatePerson("", 30)
    result.valid shouldBe false
    result.errors should not be empty
  }

  it should "複数のエラーを蓄積する" in {
    val result = validatePerson("", -1)
    result.valid shouldBe false
    result.errors.length shouldBe 2
  }

  "conformOrThrow" should "有効なデータで値を返す" in {
    val validated = valid[String, Int](42)
    conformOrThrow(validated) shouldBe 42
  }

  it should "無効なデータで例外をスロー" in {
    val validated = invalid[String, Int](List("error"))
    an[IllegalArgumentException] should be thrownBy {
      conformOrThrow(validated)
    }
  }

  // =============================================================================
  // 計算関数
  // =============================================================================

  "calculateItemTotal" should "アイテムの合計を計算する" in {
    val item = OrderItem(ProductId.unsafe("PROD-00001"), Quantity.unsafe(2), Price.unsafe(BigDecimal(1000)))
    calculateItemTotal(item) shouldBe BigDecimal(2000)
  }

  "applyDiscount" should "割引を適用する" in {
    applyDiscount(BigDecimal(1000), 0.1) shouldBe Right(BigDecimal(900))
    applyDiscount(BigDecimal(1000), 0.2) shouldBe Right(BigDecimal(800))
  }

  it should "無効な割引率を拒否する" in {
    applyDiscount(BigDecimal(1000), -0.1).isLeft shouldBe true
    applyDiscount(BigDecimal(1000), 1.1).isLeft shouldBe true
  }

  "createPerson (2 args)" should "有効な人物を作成する" in {
    val result = createPerson("田中", 30)
    result.isValid shouldBe true
  }

  "createPerson (3 args)" should "メール付きで有効な人物を作成する" in {
    val result = createPerson("田中", 30, "tanaka@example.com")
    result.isValid shouldBe true
  }

  "sumPrices" should "複数の価格を合計する" in {
    sumPrices() shouldBe BigDecimal(0)
    sumPrices(BigDecimal(100)) shouldBe BigDecimal(100)
    sumPrices(BigDecimal(100), BigDecimal(200)) shouldBe BigDecimal(300)
  }
