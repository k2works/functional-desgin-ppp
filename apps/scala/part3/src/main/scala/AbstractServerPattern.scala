/**
 * 第14章: Abstract Server パターン
 *
 * Abstract Server パターンは依存関係逆転の原則（DIP）を実現するパターンです。
 * 高レベルモジュールが低レベルモジュールの詳細に依存するのではなく、
 * 両者が抽象に依存することで疎結合を実現します。
 */
object AbstractServerPattern:

  // ============================================================
  // 1. Switchable パターン - デバイス制御
  // ============================================================

  /**
   * Abstract Server: スイッチ可能なデバイスのインターフェース
   */
  trait Switchable[A]:
    def turnOn(device: A): A
    def turnOff(device: A): A
    def isOn(device: A): Boolean

  /**
   * Switchable の拡張メソッド
   */
  extension [A](device: A)(using s: Switchable[A])
    def on: A = s.turnOn(device)
    def off: A = s.turnOff(device)
    def isOn: Boolean = s.isOn(device)
    def toggle: A = if device.isOn then device.off else device.on

  // --- Concrete Server: Light ---

  enum LightState:
    case On, Off

  case class Light(state: LightState = LightState.Off)

  given Switchable[Light] with
    def turnOn(light: Light): Light = light.copy(state = LightState.On)
    def turnOff(light: Light): Light = light.copy(state = LightState.Off)
    def isOn(light: Light): Boolean = light.state == LightState.On

  // --- Concrete Server: Fan ---

  enum FanSpeed:
    case Low, Medium, High

  case class Fan(
    state: LightState = LightState.Off,
    speed: Option[FanSpeed] = None
  )

  given Switchable[Fan] with
    def turnOn(fan: Fan): Fan =
      fan.copy(state = LightState.On, speed = Some(fan.speed.getOrElse(FanSpeed.Low)))
    def turnOff(fan: Fan): Fan =
      fan.copy(state = LightState.Off, speed = None)
    def isOn(fan: Fan): Boolean = fan.state == LightState.On

  object Fan:
    def setSpeed(fan: Fan, speed: FanSpeed): Fan =
      if fan.isOn then fan.copy(speed = Some(speed)) else fan

  // --- Concrete Server: Motor ---

  enum MotorDirection:
    case Forward, Reverse

  case class Motor(
    state: LightState = LightState.Off,
    direction: Option[MotorDirection] = None
  )

  given Switchable[Motor] with
    def turnOn(motor: Motor): Motor =
      motor.copy(
        state = LightState.On,
        direction = Some(motor.direction.getOrElse(MotorDirection.Forward))
      )
    def turnOff(motor: Motor): Motor =
      motor.copy(state = LightState.Off)
    def isOn(motor: Motor): Boolean = motor.state == LightState.On

  object Motor:
    def reverseDirection(motor: Motor): Motor =
      if motor.isOn then
        val newDirection = motor.direction match
          case Some(MotorDirection.Forward) => MotorDirection.Reverse
          case Some(MotorDirection.Reverse) => MotorDirection.Forward
          case None => MotorDirection.Forward
        motor.copy(direction = Some(newDirection))
      else motor

  // --- Client: Switch ---

  /**
   * Switch クライアント - Switchable プロトコルを通じてデバイスを操作
   */
  object Switch:
    def engage[A: Switchable](device: A): A = device.on
    def disengage[A: Switchable](device: A): A = device.off
    def toggle[A: Switchable](device: A): A = device.toggle
    def status[A: Switchable](device: A): String = if device.isOn then "on" else "off"

  // ============================================================
  // 2. Repository パターン - データアクセス
  // ============================================================

  /**
   * Abstract Server: リポジトリインターフェース
   */
  trait Repository[F[_], E, ID]:
    def findById(id: ID): F[Option[E]]
    def findAll: F[Seq[E]]
    def save(entity: E): F[E]
    def delete(id: ID): F[Option[E]]

  /**
   * シンプルなID型
   */
  type Id = String

  /**
   * User エンティティ
   */
  case class User(
    id: Option[Id] = None,
    name: String,
    email: String,
    createdAt: Long = System.currentTimeMillis()
  )

  /**
   * Identity モナド（同期処理用）
   */
  type Identity[A] = A

  /**
   * Concrete Server: インメモリリポジトリ
   */
  class MemoryRepository[E, ID](
    getId: E => Option[ID],
    setId: (E, ID) => E,
    generateId: () => ID
  ) extends Repository[Identity, E, ID]:

    private var data: Map[ID, E] = Map.empty

    def findById(id: ID): Identity[Option[E]] = data.get(id)

    def findAll: Identity[Seq[E]] = data.values.toSeq

    def save(entity: E): Identity[E] =
      val id = getId(entity).getOrElse(generateId())
      val entityWithId = setId(entity, id)
      data = data + (id -> entityWithId)
      entityWithId

    def delete(id: ID): Identity[Option[E]] =
      val entity = data.get(id)
      data = data - id
      entity

    def clear(): Unit = data = Map.empty

  /**
   * UserRepository のファクトリー
   */
  object UserRepository:
    def inMemory(): MemoryRepository[User, Id] =
      new MemoryRepository[User, Id](
        getId = _.id,
        setId = (user, id) => user.copy(id = Some(id)),
        generateId = () => java.util.UUID.randomUUID().toString
      )

  /**
   * Client: UserService
   */
  object UserService:
    def createUser[F[_]](
      repository: Repository[F, User, Id],
      name: String,
      email: String
    ): F[User] =
      repository.save(User(name = name, email = email))

    def getUser[F[_]](
      repository: Repository[F, User, Id],
      id: Id
    ): F[Option[User]] =
      repository.findById(id)

    def getAllUsers[F[_]](
      repository: Repository[F, User, Id]
    ): F[Seq[User]] =
      repository.findAll

    def deleteUser[F[_]](
      repository: Repository[F, User, Id],
      id: Id
    ): F[Option[User]] =
      repository.delete(id)

  // ============================================================
  // 3. Logger パターン - ロギング抽象化
  // ============================================================

  /**
   * Abstract Server: Logger インターフェース
   */
  trait Logger:
    def debug(message: String): Unit
    def info(message: String): Unit
    def warn(message: String): Unit
    def error(message: String): Unit
    def error(message: String, throwable: Throwable): Unit

  /**
   * Concrete Server: Console Logger
   */
  class ConsoleLogger extends Logger:
    def debug(message: String): Unit = println(s"[DEBUG] $message")
    def info(message: String): Unit = println(s"[INFO] $message")
    def warn(message: String): Unit = println(s"[WARN] $message")
    def error(message: String): Unit = println(s"[ERROR] $message")
    def error(message: String, throwable: Throwable): Unit =
      println(s"[ERROR] $message: ${throwable.getMessage}")

  /**
   * Concrete Server: Test Logger（テスト用にログを記録）
   */
  class TestLogger extends Logger:
    private var logs: List[(String, String)] = List.empty

    def debug(message: String): Unit = logs = logs :+ ("DEBUG", message)
    def info(message: String): Unit = logs = logs :+ ("INFO", message)
    def warn(message: String): Unit = logs = logs :+ ("WARN", message)
    def error(message: String): Unit = logs = logs :+ ("ERROR", message)
    def error(message: String, throwable: Throwable): Unit =
      logs = logs :+ ("ERROR", s"$message: ${throwable.getMessage}")

    def getLogs: List[(String, String)] = logs
    def clear(): Unit = logs = List.empty

  /**
   * Concrete Server: Silent Logger（何も出力しない）
   */
  object SilentLogger extends Logger:
    def debug(message: String): Unit = ()
    def info(message: String): Unit = ()
    def warn(message: String): Unit = ()
    def error(message: String): Unit = ()
    def error(message: String, throwable: Throwable): Unit = ()

  /**
   * Client: Application Service
   */
  class ApplicationService(logger: Logger):
    def processRequest(request: String): String =
      logger.info(s"Processing request: $request")
      try
        val result = s"Processed: $request"
        logger.debug(s"Request completed successfully")
        result
      catch
        case e: Exception =>
          logger.error("Request failed", e)
          throw e

  // ============================================================
  // 4. Notification パターン - 通知抽象化
  // ============================================================

  /**
   * Abstract Server: Notification インターフェース
   */
  trait NotificationService:
    def send(recipient: String, subject: String, message: String): Boolean

  /**
   * Concrete Server: Email Notification
   */
  class EmailNotification extends NotificationService:
    def send(recipient: String, subject: String, message: String): Boolean =
      // 実際にはメール送信ロジック
      println(s"Email to $recipient: [$subject] $message")
      true

  /**
   * Concrete Server: SMS Notification
   */
  class SmsNotification extends NotificationService:
    def send(recipient: String, subject: String, message: String): Boolean =
      // 実際にはSMS送信ロジック
      println(s"SMS to $recipient: $message")
      true

  /**
   * Concrete Server: Push Notification
   */
  class PushNotification extends NotificationService:
    def send(recipient: String, subject: String, message: String): Boolean =
      // 実際にはプッシュ通知ロジック
      println(s"Push to $recipient: [$subject] $message")
      true

  /**
   * Concrete Server: Mock Notification（テスト用）
   */
  class MockNotification extends NotificationService:
    private var sentNotifications: List[(String, String, String)] = List.empty

    def send(recipient: String, subject: String, message: String): Boolean =
      sentNotifications = sentNotifications :+ (recipient, subject, message)
      true

    def getSentNotifications: List[(String, String, String)] = sentNotifications
    def clear(): Unit = sentNotifications = List.empty

  /**
   * Concrete Server: Composite Notification（複数に送信）
   */
  class CompositeNotification(services: NotificationService*) extends NotificationService:
    def send(recipient: String, subject: String, message: String): Boolean =
      services.forall(_.send(recipient, subject, message))

  /**
   * Client: Order Service
   */
  class OrderService(notification: NotificationService):
    def placeOrder(userId: String, orderId: String, amount: Double): Boolean =
      // 注文処理ロジック
      notification.send(
        userId,
        s"Order Confirmation: $orderId",
        s"Your order for $$${amount} has been placed."
      )

  // ============================================================
  // 5. Storage パターン - ストレージ抽象化
  // ============================================================

  /**
   * Abstract Server: Storage インターフェース
   */
  trait Storage:
    def read(key: String): Option[String]
    def write(key: String, value: String): Unit
    def delete(key: String): Boolean
    def exists(key: String): Boolean

  /**
   * Concrete Server: Memory Storage
   */
  class MemoryStorage extends Storage:
    private var data: Map[String, String] = Map.empty

    def read(key: String): Option[String] = data.get(key)
    def write(key: String, value: String): Unit = data = data + (key -> value)
    def delete(key: String): Boolean =
      val existed = data.contains(key)
      data = data - key
      existed
    def exists(key: String): Boolean = data.contains(key)

  /**
   * Concrete Server: File Storage（シミュレーション）
   */
  class FileStorage(basePath: String) extends Storage:
    private var files: Map[String, String] = Map.empty // シミュレーション用

    def read(key: String): Option[String] = files.get(s"$basePath/$key")
    def write(key: String, value: String): Unit =
      files = files + (s"$basePath/$key" -> value)
    def delete(key: String): Boolean =
      val path = s"$basePath/$key"
      val existed = files.contains(path)
      files = files - path
      existed
    def exists(key: String): Boolean = files.contains(s"$basePath/$key")

  /**
   * Client: Cache Service
   */
  class CacheService(storage: Storage, ttlMs: Long = 60000):
    private var timestamps: Map[String, Long] = Map.empty

    def get(key: String): Option[String] =
      timestamps.get(key) match
        case Some(ts) if System.currentTimeMillis() - ts < ttlMs =>
          storage.read(key)
        case Some(_) =>
          // 期限切れ
          storage.delete(key)
          timestamps = timestamps - key
          None
        case None =>
          None

    def set(key: String, value: String): Unit =
      storage.write(key, value)
      timestamps = timestamps + (key -> System.currentTimeMillis())

    def invalidate(key: String): Unit =
      storage.delete(key)
      timestamps = timestamps - key

  // ============================================================
  // 6. 関数型アプローチ - 高階関数による抽象化
  // ============================================================

  object FunctionalAbstractServer:

    /**
     * 関数型 Switchable - 状態変換関数のレコード
     */
    case class SwitchableFn[A](
      turnOn: A => A,
      turnOff: A => A,
      isOn: A => Boolean
    ):
      def toggle(device: A): A =
        if isOn(device) then turnOff(device) else turnOn(device)

    /**
     * 関数型 Repository - CRUD操作関数のレコード
     */
    case class RepositoryFn[E, ID](
      findById: ID => Option[E],
      findAll: () => Seq[E],
      save: E => E,
      delete: ID => Option[E]
    )

    /**
     * 関数型スイッチクライアント
     */
    trait FunctionalSwitch[A]:
      def engage(device: A): A
      def disengage(device: A): A
      def toggle(device: A): A
      def status(device: A): String

    def createSwitch[A](switchable: SwitchableFn[A]): FunctionalSwitch[A] =
      new FunctionalSwitch[A]:
        def engage(device: A): A = switchable.turnOn(device)
        def disengage(device: A): A = switchable.turnOff(device)
        def toggle(device: A): A = switchable.toggle(device)
        def status(device: A): String = if switchable.isOn(device) then "on" else "off"

    /**
     * シンプルなデバイス型
     */
    case class SimpleDevice(on: Boolean = false)

    val simpleDeviceSwitchable: SwitchableFn[SimpleDevice] = SwitchableFn(
      turnOn = _.copy(on = true),
      turnOff = _.copy(on = false),
      isOn = _.on
    )

    /**
     * インメモリリポジトリを関数型で作成
     */
    def createInMemoryRepository[E, ID](
      getId: E => Option[ID],
      setId: (E, ID) => E,
      generateId: () => ID
    ): RepositoryFn[E, ID] =
      var data: Map[ID, E] = Map.empty

      RepositoryFn(
        findById = id => data.get(id),
        findAll = () => data.values.toSeq,
        save = entity =>
          val id = getId(entity).getOrElse(generateId())
          val entityWithId = setId(entity, id)
          data = data + (id -> entityWithId)
          entityWithId,
        delete = id =>
          val entity = data.get(id)
          data = data - id
          entity
      )

  // ============================================================
  // 7. 依存性注入 - Constructor Injection
  // ============================================================

  /**
   * 依存性を注入可能なサービス
   */
  class UserManagementService(
    repository: Repository[Identity, User, Id],
    notification: NotificationService,
    logger: Logger
  ):
    def registerUser(name: String, email: String): User =
      logger.info(s"Registering user: $name")
      val user = repository.save(User(name = name, email = email))
      notification.send(
        email,
        "Welcome!",
        s"Hello $name, your account has been created."
      )
      logger.info(s"User registered: ${user.id.getOrElse("unknown")}")
      user

    def deactivateUser(userId: Id): Option[User] =
      logger.info(s"Deactivating user: $userId")
      repository.findById(userId) match
        case Some(user) =>
          repository.delete(userId)
          notification.send(
            user.email,
            "Account Deactivated",
            s"Hello ${user.name}, your account has been deactivated."
          )
          logger.info(s"User deactivated: $userId")
          Some(user)
        case None =>
          logger.warn(s"User not found: $userId")
          None

  // ============================================================
  // 8. Reader モナド風の依存性注入
  // ============================================================

  object ReaderStyle:

    /**
     * 環境（依存性の集合）
     */
    case class AppEnv(
      repository: Repository[Identity, User, Id],
      notification: NotificationService,
      logger: Logger
    )

    /**
     * Reader 型（環境を受け取って結果を返す関数）
     */
    type Reader[A] = AppEnv => A

    /**
     * Reader のコンビネータ
     */
    object Reader:
      def pure[A](a: A): Reader[A] = _ => a
      def ask: Reader[AppEnv] = identity

      extension [A](ra: Reader[A])
        def map[B](f: A => B): Reader[B] = env => f(ra(env))
        def flatMap[B](f: A => Reader[B]): Reader[B] = env => f(ra(env))(env)

    /**
     * Reader を使ったサービス関数
     */
    def createUserR(name: String, email: String): Reader[User] = env =>
      env.logger.info(s"Creating user: $name")
      val user = env.repository.save(User(name = name, email = email))
      env.notification.send(email, "Welcome!", s"Hello $name!")
      user

    def getUserR(id: Id): Reader[Option[User]] = env =>
      env.repository.findById(id)

    def deleteUserR(id: Id): Reader[Option[User]] = env =>
      env.logger.info(s"Deleting user: $id")
      env.repository.delete(id)

  // ============================================================
  // 9. Payment Gateway パターン
  // ============================================================

  /**
   * 支払い結果
   */
  sealed trait PaymentResult
  case class PaymentSuccess(transactionId: String, amount: Double) extends PaymentResult
  case class PaymentFailure(reason: String) extends PaymentResult

  /**
   * Abstract Server: Payment Gateway
   */
  trait PaymentGateway:
    def charge(amount: Double, cardToken: String): PaymentResult
    def refund(transactionId: String, amount: Double): PaymentResult

  /**
   * Concrete Server: Stripe Gateway（シミュレーション）
   */
  class StripeGateway extends PaymentGateway:
    def charge(amount: Double, cardToken: String): PaymentResult =
      if cardToken.startsWith("valid_") then
        PaymentSuccess(s"stripe_${System.currentTimeMillis()}", amount)
      else
        PaymentFailure("Invalid card token")

    def refund(transactionId: String, amount: Double): PaymentResult =
      if transactionId.startsWith("stripe_") then
        PaymentSuccess(s"refund_${transactionId}", amount)
      else
        PaymentFailure("Invalid transaction ID")

  /**
   * Concrete Server: PayPal Gateway（シミュレーション）
   */
  class PayPalGateway extends PaymentGateway:
    def charge(amount: Double, cardToken: String): PaymentResult =
      if cardToken.startsWith("valid_") then
        PaymentSuccess(s"paypal_${System.currentTimeMillis()}", amount)
      else
        PaymentFailure("Invalid card token")

    def refund(transactionId: String, amount: Double): PaymentResult =
      if transactionId.startsWith("paypal_") then
        PaymentSuccess(s"refund_${transactionId}", amount)
      else
        PaymentFailure("Invalid transaction ID")

  /**
   * Concrete Server: Mock Gateway（テスト用）
   */
  class MockPaymentGateway extends PaymentGateway:
    private var charges: List[(Double, String)] = List.empty
    private var refunds: List[(String, Double)] = List.empty
    private var shouldFail: Boolean = false

    def setShouldFail(fail: Boolean): Unit = shouldFail = fail

    def charge(amount: Double, cardToken: String): PaymentResult =
      if shouldFail then
        PaymentFailure("Mock failure")
      else
        charges = charges :+ (amount, cardToken)
        PaymentSuccess(s"mock_${charges.length}", amount)

    def refund(transactionId: String, amount: Double): PaymentResult =
      if shouldFail then
        PaymentFailure("Mock failure")
      else
        refunds = refunds :+ (transactionId, amount)
        PaymentSuccess(s"refund_${transactionId}", amount)

    def getCharges: List[(Double, String)] = charges
    def getRefunds: List[(String, Double)] = refunds
    def clear(): Unit =
      charges = List.empty
      refunds = List.empty

  /**
   * Client: Checkout Service
   */
  class CheckoutService(paymentGateway: PaymentGateway):
    def processPayment(amount: Double, cardToken: String): Either[String, String] =
      paymentGateway.charge(amount, cardToken) match
        case PaymentSuccess(transactionId, _) => Right(transactionId)
        case PaymentFailure(reason) => Left(reason)

    def refundPayment(transactionId: String, amount: Double): Either[String, String] =
      paymentGateway.refund(transactionId, amount) match
        case PaymentSuccess(refundId, _) => Right(refundId)
        case PaymentFailure(reason) => Left(reason)
