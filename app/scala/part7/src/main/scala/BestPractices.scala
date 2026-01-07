/**
 * 第21章: 関数型デザインのベストプラクティス
 *
 * データ中心設計、純粋関数と副作用の分離、テスト可能な設計パターンの実装例。
 */
import scala.util.{Try, Success, Failure}

object BestPractices:

  // ============================================================
  // 1. データ中心設計
  // ============================================================

  /**
   * シンプルなデータ構造を使用
   */
  case class User(
    id: String,
    name: String,
    email: String,
    createdAt: Long = System.currentTimeMillis()
  )

  case class OrderItem(
    productId: String,
    quantity: Int,
    price: BigDecimal
  )

  case class Order(
    id: String,
    userId: String,
    items: Vector[OrderItem],
    status: OrderStatus = OrderStatus.Pending,
    createdAt: Long = System.currentTimeMillis()
  )

  enum OrderStatus:
    case Pending, Processing, Completed, Cancelled

  // ============================================================
  // 2. 小さな純粋関数
  // ============================================================

  object OrderCalculations:
    /**
     * 各関数は単一の責任を持つ
     */
    def calculateItemTotal(item: OrderItem): BigDecimal =
      item.price * item.quantity

    def calculateOrderTotal(order: Order): BigDecimal =
      order.items.map(calculateItemTotal).sum

    def applyDiscount(total: BigDecimal, discountRate: BigDecimal): BigDecimal =
      total * (1 - discountRate)

    def applyTax(total: BigDecimal, taxRate: BigDecimal): BigDecimal =
      total * (1 + taxRate)

  // ============================================================
  // 3. データ変換パイプライン
  // ============================================================

  case class ProcessedOrder(
    order: Order,
    subtotal: BigDecimal,
    discount: BigDecimal,
    tax: BigDecimal,
    total: BigDecimal
  )

  object OrderProcessing:
    import OrderCalculations.*

    def processOrder(
      order: Order,
      discountRate: BigDecimal,
      taxRate: BigDecimal
    ): ProcessedOrder =
      val subtotal = calculateOrderTotal(order)
      val discountedSubtotal = applyDiscount(subtotal, discountRate)
      val discount = subtotal - discountedSubtotal
      val tax = discountedSubtotal * taxRate
      val total = discountedSubtotal + tax

      ProcessedOrder(
        order = order.copy(status = OrderStatus.Processing),
        subtotal = subtotal,
        discount = discount,
        tax = tax,
        total = total
      )

  // ============================================================
  // 4. データ検証
  // ============================================================

  sealed trait ValidationResult[+A]:
    def isValid: Boolean
    def map[B](f: A => B): ValidationResult[B]
    def flatMap[B](f: A => ValidationResult[B]): ValidationResult[B]

  case class Valid[A](value: A) extends ValidationResult[A]:
    def isValid: Boolean = true
    def map[B](f: A => B): ValidationResult[B] = Valid(f(value))
    def flatMap[B](f: A => ValidationResult[B]): ValidationResult[B] = f(value)

  case class Invalid(errors: Vector[String]) extends ValidationResult[Nothing]:
    def isValid: Boolean = false
    def map[B](f: Nothing => B): ValidationResult[B] = this
    def flatMap[B](f: Nothing => ValidationResult[B]): ValidationResult[B] = this

  object Validation:
    def validEmail(email: String): Boolean =
      email.matches("^[^@]+@[^@]+\\.[^@]+$")

    def nonEmpty(s: String): Boolean =
      s != null && s.trim.nonEmpty

    def positive(n: BigDecimal): Boolean = n > 0

    def validateUser(user: User): ValidationResult[User] =
      val errors = Vector.newBuilder[String]

      if !nonEmpty(user.name) then
        errors += "Name is required"
      if !validEmail(user.email) then
        errors += "Invalid email format"

      val errs = errors.result()
      if errs.isEmpty then Valid(user) else Invalid(errs)

    def validateOrderItem(item: OrderItem): ValidationResult[OrderItem] =
      val errors = Vector.newBuilder[String]

      if item.quantity <= 0 then
        errors += "Quantity must be positive"
      if !positive(item.price) then
        errors += "Price must be positive"

      val errs = errors.result()
      if errs.isEmpty then Valid(item) else Invalid(errs)

    def validateOrder(order: Order): ValidationResult[Order] =
      val errors = Vector.newBuilder[String]

      if order.items.isEmpty then
        errors += "Order must have at least one item"

      val itemErrors = order.items.flatMap { item =>
        validateOrderItem(item) match
          case Invalid(errs) => errs
          case _ => Vector.empty
      }
      errors ++= itemErrors

      val errs = errors.result()
      if errs.isEmpty then Valid(order) else Invalid(errs)

  // ============================================================
  // 5. イミュータブルな更新
  // ============================================================

  object ImmutableUpdates:
    def updateUserEmail(user: User, newEmail: String): Either[String, User] =
      if Validation.validEmail(newEmail) then
        Right(user.copy(email = newEmail))
      else
        Left("Invalid email format")

    def addOrderItem(order: Order, item: OrderItem): Either[String, Order] =
      Validation.validateOrderItem(item) match
        case Valid(_) => Right(order.copy(items = order.items :+ item))
        case Invalid(errs) => Left(errs.mkString(", "))

    def cancelOrder(order: Order): Either[String, Order] =
      if order.status == OrderStatus.Pending then
        Right(order.copy(status = OrderStatus.Cancelled))
      else
        Left("Only pending orders can be cancelled")

  // ============================================================
  // 6. 純粋関数と副作用の分離
  // ============================================================

  /**
   * 副作用を表現する型
   */
  sealed trait IO[+A]:
    def map[B](f: A => B): IO[B] = IO.Map(this, f)
    def flatMap[B](f: A => IO[B]): IO[B] = IO.FlatMap(this, f)
    def run(): A

  object IO:
    case class Pure[A](value: A) extends IO[A]:
      def run(): A = value

    case class Suspend[A](thunk: () => A) extends IO[A]:
      def run(): A = thunk()

    case class Map[A, B](io: IO[A], f: A => B) extends IO[B]:
      def run(): B = f(io.run())

    case class FlatMap[A, B](io: IO[A], f: A => IO[B]) extends IO[B]:
      def run(): B = f(io.run()).run()

    def pure[A](a: A): IO[A] = Pure(a)
    def suspend[A](thunk: => A): IO[A] = Suspend(() => thunk)

  // ============================================================
  // 7. 高階関数によるデコレーション
  // ============================================================

  object FunctionDecorators:
    /**
     * ロギングデコレータ
     */
    def withLogging[A, B](f: A => B, logger: String => Unit): A => B =
      (a: A) =>
        logger(s"Input: $a")
        val result = f(a)
        logger(s"Output: $result")
        result

    /**
     * 計測デコレータ
     */
    def withTiming[A, B](f: A => B, reporter: Long => Unit): A => B =
      (a: A) =>
        val start = System.nanoTime()
        val result = f(a)
        val elapsed = System.nanoTime() - start
        reporter(elapsed)
        result

    /**
     * リトライデコレータ
     */
    def withRetry[A, B](f: A => B, maxRetries: Int): A => Try[B] =
      (a: A) =>
        def attempt(remaining: Int): Try[B] =
          Try(f(a)) match
            case success @ Success(_) => success
            case Failure(_) if remaining > 0 => attempt(remaining - 1)
            case failure => failure
        attempt(maxRetries)

    /**
     * キャッシュデコレータ
     */
    def withCache[A, B](f: A => B): A => B =
      val cache = scala.collection.mutable.Map.empty[A, B]
      (a: A) => cache.getOrElseUpdate(a, f(a))

  // ============================================================
  // 8. 関数合成
  // ============================================================

  object FunctionComposition:
    /**
     * パイプライン形式の関数合成
     */
    def pipeline[A](fns: (A => A)*): A => A =
      fns.reduce((f, g) => x => g(f(x)))

    /**
     * 条件付き関数適用
     */
    def when[A](condition: Boolean)(f: A => A): A => A =
      if condition then f else identity

    /**
     * 繰り返し適用
     */
    def repeat[A](n: Int)(f: A => A): A => A =
      if n <= 0 then identity
      else pipeline((1 to n).map(_ => f): _*)

  // ============================================================
  // 9. テスト可能な設計 - 依存性注入
  // ============================================================

  /**
   * リポジトリインターフェース
   */
  trait Repository[T, ID]:
    def findById(id: ID): Option[T]
    def findAll(): Vector[T]
    def save(entity: T): T
    def delete(id: ID): Boolean

  /**
   * インメモリリポジトリ（テスト用）
   */
  class InMemoryRepository[T, ID](idExtractor: T => ID) extends Repository[T, ID]:
    private var data = Vector.empty[T]

    def findById(id: ID): Option[T] =
      data.find(e => idExtractor(e) == id)

    def findAll(): Vector[T] = data

    def save(entity: T): T =
      data = data.filterNot(e => idExtractor(e) == idExtractor(entity)) :+ entity
      entity

    def delete(id: ID): Boolean =
      val sizeBefore = data.size
      data = data.filterNot(e => idExtractor(e) == id)
      data.size < sizeBefore

  // ============================================================
  // 10. テスト可能な設計 - 時間の抽象化
  // ============================================================

  /**
   * 時間プロバイダー
   */
  trait Clock:
    def now(): Long

  object SystemClock extends Clock:
    def now(): Long = System.currentTimeMillis()

  class FixedClock(time: Long) extends Clock:
    def now(): Long = time

  /**
   * ID生成器
   */
  trait IdGenerator:
    def generate(): String

  object UuidGenerator extends IdGenerator:
    def generate(): String = java.util.UUID.randomUUID().toString

  class SequentialIdGenerator(prefix: String = "id") extends IdGenerator:
    private var counter = 0
    def generate(): String =
      counter += 1
      s"$prefix-$counter"

  // ============================================================
  // 11. テスト可能な設計 - 設定の分離
  // ============================================================

  case class PricingConfig(
    taxRate: BigDecimal = BigDecimal("0.1"),
    discountRate: BigDecimal = BigDecimal("0.0"),
    currency: String = "JPY"
  )

  case class PriceBreakdown(
    basePrice: BigDecimal,
    discountedPrice: BigDecimal,
    tax: BigDecimal,
    total: BigDecimal,
    currency: String
  )

  object Pricing:
    def calculatePrice(config: PricingConfig, basePrice: BigDecimal): PriceBreakdown =
      val discounted = basePrice * (1 - config.discountRate)
      val tax = discounted * config.taxRate
      val total = discounted + tax

      PriceBreakdown(
        basePrice = basePrice,
        discountedPrice = discounted,
        tax = tax,
        total = total,
        currency = config.currency
      )

  // ============================================================
  // 12. テスト可能な設計 - 検証の分離
  // ============================================================

  type Validator[T] = T => Vector[String]

  object Validators:
    def required(fieldName: String): Validator[Option[Any]] =
      (value: Option[Any]) =>
        if value.isEmpty then Vector(s"$fieldName is required")
        else Vector.empty

    def nonEmptyString(fieldName: String): Validator[String] =
      (value: String) =>
        if value == null || value.trim.isEmpty then Vector(s"$fieldName must not be empty")
        else Vector.empty

    def email(fieldName: String): Validator[String] =
      (value: String) =>
        if value == null || !Validation.validEmail(value) then Vector(s"$fieldName must be a valid email")
        else Vector.empty

    def positive(fieldName: String): Validator[BigDecimal] =
      (value: BigDecimal) =>
        if value <= 0 then Vector(s"$fieldName must be positive")
        else Vector.empty

    def minLength(fieldName: String, min: Int): Validator[String] =
      (value: String) =>
        if value == null || value.length < min then Vector(s"$fieldName must be at least $min characters")
        else Vector.empty

    def combine[T](validators: Validator[T]*): Validator[T] =
      (value: T) => validators.flatMap(_(value)).toVector

  // ============================================================
  // 13. サービス層の設計
  // ============================================================

  class UserService(
    repository: Repository[User, String],
    clock: Clock,
    idGenerator: IdGenerator
  ):
    def createUser(name: String, email: String): Either[Vector[String], User] =
      val user = User(
        id = idGenerator.generate(),
        name = name,
        email = email,
        createdAt = clock.now()
      )

      Validation.validateUser(user) match
        case Valid(u) =>
          Right(repository.save(u))
        case Invalid(errors) =>
          Left(errors)

    def getUser(id: String): Option[User] =
      repository.findById(id)

    def updateEmail(id: String, newEmail: String): Either[String, User] =
      repository.findById(id) match
        case Some(user) =>
          ImmutableUpdates.updateUserEmail(user, newEmail).map(repository.save)
        case None =>
          Left(s"User not found: $id")

    def getAllUsers(): Vector[User] =
      repository.findAll()

  // ============================================================
  // 14. DSL
  // ============================================================

  object DSL:
    def user(name: String, email: String)(using clock: Clock, idGen: IdGenerator): User =
      User(idGen.generate(), name, email, clock.now())

    def order(userId: String, items: OrderItem*)(using clock: Clock, idGen: IdGenerator): Order =
      Order(idGen.generate(), userId, items.toVector, createdAt = clock.now())

    def item(productId: String, quantity: Int, price: BigDecimal): OrderItem =
      OrderItem(productId, quantity, price)

    extension (order: Order)
      def withItem(item: OrderItem): Order = order.copy(items = order.items :+ item)
      def process(discountRate: BigDecimal, taxRate: BigDecimal): ProcessedOrder =
        OrderProcessing.processOrder(order, discountRate, taxRate)

  // ============================================================
  // 15. 結果型
  // ============================================================

  enum Result[+E, +A]:
    case Success(value: A)
    case Failure(error: E)

    def map[B](f: A => B): Result[E, B] = this match
      case Success(a) => Success(f(a))
      case Failure(e) => Failure(e)

    def flatMap[E2 >: E, B](f: A => Result[E2, B]): Result[E2, B] = this match
      case Success(a) => f(a)
      case Failure(e) => Failure(e)

    def getOrElse[A2 >: A](default: => A2): A2 = this match
      case Success(a) => a
      case Failure(_) => default

    def isSuccess: Boolean = this match
      case Success(_) => true
      case Failure(_) => false

  object Result:
    def success[A](value: A): Result[Nothing, A] = Success(value)
    def failure[E](error: E): Result[E, Nothing] = Failure(error)

    def fromOption[A](opt: Option[A], ifNone: => String): Result[String, A] =
      opt match
        case Some(a) => Success(a)
        case None => Failure(ifNone)

    def fromEither[E, A](either: Either[E, A]): Result[E, A] =
      either match
        case Right(a) => Success(a)
        case Left(e) => Failure(e)
