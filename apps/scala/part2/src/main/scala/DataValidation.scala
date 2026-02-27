package datavalidation

/**
 * 第4章: データバリデーション
 *
 * Scala における型安全なデータバリデーションの実現方法を学びます。
 * Either、Validated パターン、スマートコンストラクタを活用した
 * 堅牢なデータ検証について扱います。
 */
object DataValidation:

  // =============================================================================
  // 1. 基本的なバリデーション（Either を使用）
  // =============================================================================

  /**
   * バリデーション結果を表す型
   */
  type ValidationResult[A] = Either[List[String], A]

  /**
   * 名前のバリデーション
   */
  def validateName(name: String): ValidationResult[String] =
    if name.isEmpty then Left(List("名前は空にできません"))
    else if name.length > 100 then Left(List("名前は100文字以内である必要があります"))
    else Right(name)

  /**
   * 年齢のバリデーション
   */
  def validateAge(age: Int): ValidationResult[Int] =
    if age < 0 then Left(List("年齢は0以上である必要があります"))
    else if age > 150 then Left(List("年齢は150以下である必要があります"))
    else Right(age)

  /**
   * メールアドレスのバリデーション
   */
  def validateEmail(email: String): ValidationResult[String] =
    val emailRegex = ".+@.+\\..+".r
    if emailRegex.matches(email) then Right(email)
    else Left(List("無効なメールアドレス形式です"))

  // =============================================================================
  // 2. 列挙型とスマートコンストラクタ
  // =============================================================================

  /**
   * 会員種別
   */
  enum Membership:
    case Bronze, Silver, Gold, Platinum

  object Membership:
    def fromString(s: String): ValidationResult[Membership] =
      s.toLowerCase match
        case "bronze"   => Right(Bronze)
        case "silver"   => Right(Silver)
        case "gold"     => Right(Gold)
        case "platinum" => Right(Platinum)
        case _          => Left(List(s"無効な会員種別: $s"))

  /**
   * ステータス
   */
  enum Status:
    case Active, Inactive, Suspended

  // =============================================================================
  // 3. Validated パターン（エラー蓄積）
  // =============================================================================

  /**
   * バリデーション結果（エラー蓄積可能）
   */
  enum Validated[+E, +A]:
    case Valid(value: A)
    case Invalid(errors: List[E])

    def map[B](f: A => B): Validated[E, B] = this match
      case Valid(a)      => Valid(f(a))
      case Invalid(errs) => Invalid(errs)

    def flatMap[EE >: E, B](f: A => Validated[EE, B]): Validated[EE, B] = this match
      case Valid(a)      => f(a)
      case Invalid(errs) => Invalid(errs)

    def isValid: Boolean = this match
      case Valid(_)   => true
      case Invalid(_) => false

    def toEither: Either[List[E], A] = this match
      case Valid(a)      => Right(a)
      case Invalid(errs) => Left(errs)

  object Validated:
    def valid[E, A](a: A): Validated[E, A] = Valid(a)
    def invalid[E, A](errors: List[E]): Validated[E, A] = Invalid(errors)

    /**
     * 2つの Validated を結合（エラー蓄積）
     */
    def combine[E, A, B, C](va: Validated[E, A], vb: Validated[E, B])(f: (A, B) => C): Validated[E, C] =
      (va, vb) match
        case (Valid(a), Valid(b))           => Valid(f(a, b))
        case (Invalid(e1), Invalid(e2))     => Invalid(e1 ++ e2)
        case (Invalid(e), _)                => Invalid(e)
        case (_, Invalid(e))                => Invalid(e)

    /**
     * 3つの Validated を結合
     */
    def combine3[E, A, B, C, D](va: Validated[E, A], vb: Validated[E, B], vc: Validated[E, C])(f: (A, B, C) => D): Validated[E, D] =
      combine(combine(va, vb)((a, b) => (a, b)), vc) { case ((a, b), c) => f(a, b, c) }

    /**
     * 4つの Validated を結合
     */
    def combine4[E, A, B, C, D, R](va: Validated[E, A], vb: Validated[E, B], vc: Validated[E, C], vd: Validated[E, D])(f: (A, B, C, D) => R): Validated[E, R] =
      combine(combine3(va, vb, vc)((a, b, c) => (a, b, c)), vd) { case ((a, b, c), d) => f(a, b, c, d) }

  // =============================================================================
  // 4. ドメインモデルとバリデーション
  // =============================================================================

  /**
   * 商品ID（バリデーション済み）
   */
  opaque type ProductId = String

  object ProductId:
    private val pattern = "PROD-\\d{5}".r

    def apply(id: String): Validated[String, ProductId] =
      if pattern.matches(id) then Validated.valid(id)
      else Validated.invalid(List(s"無効な商品ID形式: $id (PROD-XXXXXの形式が必要)"))

    def unsafe(id: String): ProductId = id

    extension (id: ProductId)
      def value: String = id

  /**
   * 商品名
   */
  opaque type ProductName = String

  object ProductName:
    def apply(name: String): Validated[String, ProductName] =
      if name.isEmpty then Validated.invalid(List("商品名は空にできません"))
      else if name.length > 200 then Validated.invalid(List("商品名は200文字以内である必要があります"))
      else Validated.valid(name)

    def unsafe(name: String): ProductName = name

    extension (name: ProductName)
      def value: String = name

  /**
   * 価格（正の数）
   */
  opaque type Price = BigDecimal

  object Price:
    def apply(amount: BigDecimal): Validated[String, Price] =
      if amount <= 0 then Validated.invalid(List("価格は正の数である必要があります"))
      else Validated.valid(amount)

    def unsafe(amount: BigDecimal): Price = amount

    extension (price: Price)
      def value: BigDecimal = price

  /**
   * 数量（正の整数）
   */
  opaque type Quantity = Int

  object Quantity:
    def apply(qty: Int): Validated[String, Quantity] =
      if qty <= 0 then Validated.invalid(List("数量は正の整数である必要があります"))
      else Validated.valid(qty)

    def unsafe(qty: Int): Quantity = qty

    extension (qty: Quantity)
      def value: Int = qty

  /**
   * 商品
   */
  case class Product(
    id: ProductId,
    name: ProductName,
    price: Price,
    description: Option[String] = None,
    category: Option[String] = None
  )

  object Product:
    def create(
      id: String,
      name: String,
      price: BigDecimal,
      description: Option[String] = None,
      category: Option[String] = None
    ): Validated[String, Product] =
      Validated.combine3(
        ProductId(id),
        ProductName(name),
        Price(price)
      )((pid, pname, pprice) => Product(pid, pname, pprice, description, category))

  // =============================================================================
  // 5. 注文ドメインモデル
  // =============================================================================

  /**
   * 注文ID
   */
  opaque type OrderId = String

  object OrderId:
    private val pattern = "ORD-\\d{8}".r

    def apply(id: String): Validated[String, OrderId] =
      if pattern.matches(id) then Validated.valid(id)
      else Validated.invalid(List(s"無効な注文ID形式: $id"))

    def unsafe(id: String): OrderId = id

    extension (id: OrderId)
      def value: String = id

  /**
   * 顧客ID
   */
  opaque type CustomerId = String

  object CustomerId:
    private val pattern = "CUST-\\d{6}".r

    def apply(id: String): Validated[String, CustomerId] =
      if pattern.matches(id) then Validated.valid(id)
      else Validated.invalid(List(s"無効な顧客ID形式: $id"))

    def unsafe(id: String): CustomerId = id

    extension (id: CustomerId)
      def value: String = id

  /**
   * 注文アイテム
   */
  case class OrderItem(
    productId: ProductId,
    quantity: Quantity,
    price: Price
  ):
    def total: BigDecimal = Price.value(price) * Quantity.value(quantity)

  object OrderItem:
    def create(productId: String, quantity: Int, price: BigDecimal): Validated[String, OrderItem] =
      Validated.combine3(
        ProductId(productId),
        Quantity(quantity),
        Price(price)
      )(OrderItem.apply)

  /**
   * 注文
   */
  case class Order(
    orderId: OrderId,
    customerId: CustomerId,
    items: List[OrderItem],
    orderDate: java.time.LocalDate,
    total: Option[BigDecimal] = None,
    status: Option[Status] = None
  ):
    def calculateTotal: BigDecimal = items.map(_.total).sum

  // =============================================================================
  // 6. 条件付きバリデーション
  // =============================================================================

  /**
   * 通知タイプ
   */
  enum NotificationType:
    case Email, SMS, Push

  /**
   * 通知（ADT による条件付きバリデーション）
   */
  sealed trait Notification:
    def body: String

  case class EmailNotification(to: String, subject: String, body: String) extends Notification
  case class SMSNotification(phoneNumber: String, body: String) extends Notification
  case class PushNotification(deviceToken: String, body: String) extends Notification

  object Notification:
    private val emailPattern = ".+@.+\\..+".r
    private val phonePattern = "\\d{2,4}-\\d{2,4}-\\d{4}".r

    def createEmail(to: String, subject: String, body: String): Validated[String, EmailNotification] =
      if !emailPattern.matches(to) then Validated.invalid(List("無効なメールアドレス形式です"))
      else if subject.isEmpty then Validated.invalid(List("件名は空にできません"))
      else if body.isEmpty then Validated.invalid(List("本文は空にできません"))
      else Validated.valid(EmailNotification(to, subject, body))

    def createSMS(phoneNumber: String, body: String): Validated[String, SMSNotification] =
      if !phonePattern.matches(phoneNumber) then Validated.invalid(List("無効な電話番号形式です"))
      else if body.isEmpty then Validated.invalid(List("本文は空にできません"))
      else Validated.valid(SMSNotification(phoneNumber, body))

    def createPush(deviceToken: String, body: String): Validated[String, PushNotification] =
      if deviceToken.isEmpty then Validated.invalid(List("デバイストークンは空にできません"))
      else if body.isEmpty then Validated.invalid(List("本文は空にできません"))
      else Validated.valid(PushNotification(deviceToken, body))

  // =============================================================================
  // 7. バリデーションユーティリティ
  // =============================================================================

  /**
   * バリデーション結果を返す
   */
  case class ValidationResponse[A](valid: Boolean, data: Option[A], errors: List[String])

  def validatePerson(name: String, age: Int): ValidationResponse[Person] =
    val nameV = if name.isEmpty then Validated.invalid[String, String](List("名前は空にできません"))
      else if name.length > 100 then Validated.invalid[String, String](List("名前は100文字以内である必要があります"))
      else Validated.valid[String, String](name)
    val ageV = if age < 0 then Validated.invalid[String, Int](List("年齢は0以上である必要があります"))
      else if age > 150 then Validated.invalid[String, Int](List("年齢は150以下である必要があります"))
      else Validated.valid[String, Int](age)

    val validated = Validated.combine(nameV, ageV)((n, a) => Person(n, a))

    validated match
      case Validated.Valid(p) => ValidationResponse(true, Some(p), List.empty)
      case Validated.Invalid(e) => ValidationResponse(false, None, e)

  case class Person(name: String, age: Int, email: Option[String] = None)

  /**
   * 例外をスローするバリデーション
   */
  def conformOrThrow[A](validated: Validated[String, A]): A =
    validated match
      case Validated.Valid(a)      => a
      case Validated.Invalid(errs) => throw new IllegalArgumentException(s"Validation failed: ${errs.mkString(", ")}")

  // =============================================================================
  // 8. 計算関数
  // =============================================================================

  /**
   * 注文アイテムの合計を計算
   */
  def calculateItemTotal(item: OrderItem): BigDecimal =
    Price.value(item.price) * Quantity.value(item.quantity)

  /**
   * 注文全体の合計を計算
   */
  def calculateOrderTotal(order: Order): BigDecimal =
    order.items.map(calculateItemTotal).sum

  /**
   * 割引を適用
   */
  def applyDiscount(total: BigDecimal, discountRate: Double): Either[String, BigDecimal] =
    if discountRate < 0 || discountRate > 1 then
      Left("割引率は0から1の間である必要があります")
    else
      Right(total * (1 - discountRate))

  /**
   * 人物を作成
   */
  def createPerson(name: String, age: Int): Validated[String, Person] =
    Validated.combine(
      validateName(name).fold(Validated.invalid, Validated.valid),
      validateAge(age).fold(Validated.invalid, Validated.valid)
    )(Person(_, _))

  def createPerson(name: String, age: Int, email: String): Validated[String, Person] =
    Validated.combine3(
      validateName(name).fold(Validated.invalid, Validated.valid),
      validateAge(age).fold(Validated.invalid, Validated.valid),
      validateEmail(email).fold(Validated.invalid, Validated.valid)
    )((n, a, e) => Person(n, a, Some(e)))

  /**
   * 複数の価格を合計
   */
  def sumPrices(prices: BigDecimal*): BigDecimal =
    prices.sum
