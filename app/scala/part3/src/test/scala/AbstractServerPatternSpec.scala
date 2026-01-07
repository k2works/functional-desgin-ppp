import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import AbstractServerPattern.*

class AbstractServerPatternSpec extends AnyFunSpec with Matchers:

  // ============================================================
  // 1. Switchable パターン
  // ============================================================

  describe("Switchable パターン"):

    describe("Light"):
      it("初期状態はオフ"):
        val light = Light()
        light.isOn shouldBe false

      it("オンにできる"):
        val light = Light().on
        light.isOn shouldBe true
        light.state shouldBe LightState.On

      it("オフにできる"):
        val light = Light().on.off
        light.isOn shouldBe false
        light.state shouldBe LightState.Off

      it("トグルできる"):
        val light = Light()
        light.toggle.isOn shouldBe true
        light.toggle.toggle.isOn shouldBe false

    describe("Fan"):
      it("初期状態はオフでスピードなし"):
        val fan = Fan()
        fan.isOn shouldBe false
        fan.speed shouldBe None

      it("オンにするとデフォルトスピード（Low）が設定される"):
        val fan = Fan().on
        fan.isOn shouldBe true
        fan.speed shouldBe Some(FanSpeed.Low)

      it("スピードを変更できる"):
        val fan = Fan().on
        val highSpeedFan = Fan.setSpeed(fan, FanSpeed.High)
        highSpeedFan.speed shouldBe Some(FanSpeed.High)

      it("オフの状態ではスピードを変更できない"):
        val fan = Fan()
        val result = Fan.setSpeed(fan, FanSpeed.High)
        result.speed shouldBe None

      it("オフにするとスピードがリセットされる"):
        val fan = Fan().on.off
        fan.speed shouldBe None

    describe("Motor"):
      it("初期状態はオフで方向なし"):
        val motor = Motor()
        motor.isOn shouldBe false
        motor.direction shouldBe None

      it("オンにするとデフォルト方向（Forward）が設定される"):
        val motor = Motor().on
        motor.isOn shouldBe true
        motor.direction shouldBe Some(MotorDirection.Forward)

      it("方向を反転できる"):
        val motor = Motor().on
        val reversed = Motor.reverseDirection(motor)
        reversed.direction shouldBe Some(MotorDirection.Reverse)

      it("方向を再度反転できる"):
        val motor = Motor().on
        val reversed = Motor.reverseDirection(Motor.reverseDirection(motor))
        reversed.direction shouldBe Some(MotorDirection.Forward)

      it("オフの状態では方向を反転できない"):
        val motor = Motor()
        val result = Motor.reverseDirection(motor)
        result.direction shouldBe None

    describe("Switch クライアント"):
      it("異なるデバイスを同じインターフェースで操作できる"):
        val light = Switch.engage(Light())
        val fan = Switch.engage(Fan())
        val motor = Switch.engage(Motor())

        Switch.status(light) shouldBe "on"
        Switch.status(fan) shouldBe "on"
        Switch.status(motor) shouldBe "on"

      it("disengage でオフにできる"):
        val light = Switch.disengage(Switch.engage(Light()))
        Switch.status(light) shouldBe "off"

      it("toggle で状態を切り替えられる"):
        val light = Light()
        Switch.status(light) shouldBe "off"
        Switch.status(Switch.toggle(light)) shouldBe "on"
        Switch.status(Switch.toggle(Switch.toggle(light))) shouldBe "off"

  // ============================================================
  // 2. Repository パターン
  // ============================================================

  describe("Repository パターン"):

    describe("MemoryRepository"):
      it("エンティティを保存できる"):
        val repo = UserRepository.inMemory()
        val user = repo.save(User(name = "Alice", email = "alice@example.com"))

        user.id shouldBe defined
        user.name shouldBe "Alice"

      it("IDでエンティティを取得できる"):
        val repo = UserRepository.inMemory()
        val saved = repo.save(User(name = "Bob", email = "bob@example.com"))

        val found = repo.findById(saved.id.get)
        found shouldBe defined
        found.get.name shouldBe "Bob"

      it("全てのエンティティを取得できる"):
        val repo = UserRepository.inMemory()
        repo.save(User(name = "Alice", email = "alice@example.com"))
        repo.save(User(name = "Bob", email = "bob@example.com"))

        val users = repo.findAll
        users.length shouldBe 2

      it("エンティティを削除できる"):
        val repo = UserRepository.inMemory()
        val saved = repo.save(User(name = "Charlie", email = "charlie@example.com"))

        val deleted = repo.delete(saved.id.get)
        deleted shouldBe defined
        repo.findById(saved.id.get) shouldBe None

      it("存在しないIDの削除はNoneを返す"):
        val repo = UserRepository.inMemory()
        repo.delete("nonexistent") shouldBe None

    describe("UserService"):
      it("ユーザーを作成できる"):
        val repo = UserRepository.inMemory()
        val user = UserService.createUser(repo, "Diana", "diana@example.com")

        user.name shouldBe "Diana"
        user.email shouldBe "diana@example.com"
        user.id shouldBe defined

      it("ユーザーを取得できる"):
        val repo = UserRepository.inMemory()
        val created = UserService.createUser(repo, "Eve", "eve@example.com")

        val found = UserService.getUser(repo, created.id.get)
        found shouldBe defined
        found.get.name shouldBe "Eve"

      it("全ユーザーを取得できる"):
        val repo = UserRepository.inMemory()
        UserService.createUser(repo, "Frank", "frank@example.com")
        UserService.createUser(repo, "Grace", "grace@example.com")

        val users = UserService.getAllUsers(repo)
        users.length shouldBe 2

      it("ユーザーを削除できる"):
        val repo = UserRepository.inMemory()
        val user = UserService.createUser(repo, "Henry", "henry@example.com")

        val deleted = UserService.deleteUser(repo, user.id.get)
        deleted shouldBe defined
        UserService.getUser(repo, user.id.get) shouldBe None

  // ============================================================
  // 3. Logger パターン
  // ============================================================

  describe("Logger パターン"):

    describe("TestLogger"):
      it("ログを記録できる"):
        val logger = new TestLogger()
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warn("Warn message")
        logger.error("Error message")

        val logs = logger.getLogs
        logs should have length 4
        logs(0) shouldBe ("DEBUG", "Debug message")
        logs(1) shouldBe ("INFO", "Info message")
        logs(2) shouldBe ("WARN", "Warn message")
        logs(3) shouldBe ("ERROR", "Error message")

      it("例外付きエラーログを記録できる"):
        val logger = new TestLogger()
        logger.error("Failed", new RuntimeException("Test error"))

        val logs = logger.getLogs
        logs(0)._1 shouldBe "ERROR"
        logs(0)._2 should include("Test error")

      it("クリアできる"):
        val logger = new TestLogger()
        logger.info("Test")
        logger.clear()
        logger.getLogs shouldBe empty

    describe("ApplicationService"):
      it("リクエストを処理してログを記録する"):
        val logger = new TestLogger()
        val service = new ApplicationService(logger)

        val result = service.processRequest("test-request")

        result shouldBe "Processed: test-request"
        logger.getLogs.exists(_._2.contains("test-request")) shouldBe true

      it("SilentLoggerを使用しても動作する"):
        val service = new ApplicationService(SilentLogger)
        service.processRequest("silent-request") shouldBe "Processed: silent-request"

  // ============================================================
  // 4. Notification パターン
  // ============================================================

  describe("Notification パターン"):

    describe("MockNotification"):
      it("通知を記録できる"):
        val notification = new MockNotification()
        notification.send("user@example.com", "Subject", "Body")

        val sent = notification.getSentNotifications
        sent should have length 1
        sent(0) shouldBe ("user@example.com", "Subject", "Body")

      it("複数の通知を記録できる"):
        val notification = new MockNotification()
        notification.send("a@example.com", "S1", "B1")
        notification.send("b@example.com", "S2", "B2")

        notification.getSentNotifications should have length 2

    describe("CompositeNotification"):
      it("複数のサービスに通知を送信できる"):
        val mock1 = new MockNotification()
        val mock2 = new MockNotification()
        val composite = new CompositeNotification(mock1, mock2)

        composite.send("user@example.com", "Test", "Message")

        mock1.getSentNotifications should have length 1
        mock2.getSentNotifications should have length 1

    describe("OrderService"):
      it("注文時に通知を送信する"):
        val notification = new MockNotification()
        val orderService = new OrderService(notification)

        orderService.placeOrder("user123", "ORD001", 99.99)

        val sent = notification.getSentNotifications
        sent should have length 1
        sent(0)._1 shouldBe "user123"
        sent(0)._2 should include("ORD001")

  // ============================================================
  // 5. Storage パターン
  // ============================================================

  describe("Storage パターン"):

    describe("MemoryStorage"):
      it("データを書き込んで読み取れる"):
        val storage = new MemoryStorage()
        storage.write("key1", "value1")

        storage.read("key1") shouldBe Some("value1")

      it("存在確認ができる"):
        val storage = new MemoryStorage()
        storage.exists("key") shouldBe false
        storage.write("key", "value")
        storage.exists("key") shouldBe true

      it("削除できる"):
        val storage = new MemoryStorage()
        storage.write("key", "value")
        storage.delete("key") shouldBe true
        storage.read("key") shouldBe None

      it("存在しないキーの削除はfalseを返す"):
        val storage = new MemoryStorage()
        storage.delete("nonexistent") shouldBe false

    describe("FileStorage"):
      it("ファイルパスベースで保存できる"):
        val storage = new FileStorage("/tmp/test")
        storage.write("config.json", "{}")

        storage.read("config.json") shouldBe Some("{}")
        storage.exists("config.json") shouldBe true

    describe("CacheService"):
      it("キャッシュにデータを設定して取得できる"):
        val storage = new MemoryStorage()
        val cache = new CacheService(storage)

        cache.set("user:1", "Alice")
        cache.get("user:1") shouldBe Some("Alice")

      it("キャッシュを無効化できる"):
        val storage = new MemoryStorage()
        val cache = new CacheService(storage)

        cache.set("user:1", "Alice")
        cache.invalidate("user:1")
        cache.get("user:1") shouldBe None

  // ============================================================
  // 6. 関数型アプローチ
  // ============================================================

  describe("関数型アプローチ"):

    import FunctionalAbstractServer.*

    describe("SwitchableFn"):
      it("関数型スイッチで操作できる"):
        val switch = createSwitch(simpleDeviceSwitchable)
        val device = SimpleDevice()

        switch.status(device) shouldBe "off"
        switch.status(switch.engage(device)) shouldBe "on"
        switch.status(switch.disengage(switch.engage(device))) shouldBe "off"

      it("トグルできる"):
        val switch = createSwitch(simpleDeviceSwitchable)
        val device = SimpleDevice()

        switch.status(switch.toggle(device)) shouldBe "on"
        switch.status(switch.toggle(switch.toggle(device))) shouldBe "off"

    describe("RepositoryFn"):
      it("関数型リポジトリで CRUD 操作できる"):
        case class Item(id: Option[String], name: String)

        val repo = createInMemoryRepository[Item, String](
          getId = _.id,
          setId = (item, id) => item.copy(id = Some(id)),
          generateId = () => java.util.UUID.randomUUID().toString
        )

        val saved = repo.save(Item(None, "Test Item"))
        saved.id shouldBe defined

        repo.findById(saved.id.get) shouldBe Some(saved)
        repo.findAll().length shouldBe 1

        repo.delete(saved.id.get) shouldBe Some(saved)
        repo.findAll() shouldBe empty

  // ============================================================
  // 7. 依存性注入
  // ============================================================

  describe("依存性注入"):

    describe("UserManagementService"):
      it("ユーザー登録時にリポジトリ保存と通知を行う"):
        val repo = UserRepository.inMemory()
        val notification = new MockNotification()
        val logger = new TestLogger()
        val service = new UserManagementService(repo, notification, logger)

        val user = service.registerUser("Alice", "alice@example.com")

        user.name shouldBe "Alice"
        repo.findById(user.id.get) shouldBe defined
        notification.getSentNotifications should have length 1
        logger.getLogs.exists(_._2.contains("Alice")) shouldBe true

      it("ユーザー削除時にリポジトリ削除と通知を行う"):
        val repo = UserRepository.inMemory()
        val notification = new MockNotification()
        val logger = new TestLogger()
        val service = new UserManagementService(repo, notification, logger)

        val user = service.registerUser("Bob", "bob@example.com")
        notification.clear()
        logger.clear()

        val deleted = service.deactivateUser(user.id.get)

        deleted shouldBe defined
        repo.findById(user.id.get) shouldBe None
        notification.getSentNotifications should have length 1

      it("存在しないユーザーの削除は警告ログを出す"):
        val repo = UserRepository.inMemory()
        val notification = new MockNotification()
        val logger = new TestLogger()
        val service = new UserManagementService(repo, notification, logger)

        val result = service.deactivateUser("nonexistent")

        result shouldBe None
        logger.getLogs.exists { case (level, _) => level == "WARN" } shouldBe true

  // ============================================================
  // 8. Reader スタイル
  // ============================================================

  describe("Reader スタイル"):

    import ReaderStyle.*

    it("環境を通じて依存性を提供できる"):
      val repo = UserRepository.inMemory()
      val notification = new MockNotification()
      val logger = new TestLogger()
      val env = AppEnv(repo, notification, logger)

      val user = createUserR("Charlie", "charlie@example.com")(env)

      user.name shouldBe "Charlie"
      notification.getSentNotifications should have length 1

    it("Reader を合成できる"):
      val repo = UserRepository.inMemory()
      val notification = new MockNotification()
      val logger = new TestLogger()
      val env = AppEnv(repo, notification, logger)

      // ユーザー作成して取得
      val user = createUserR("Diana", "diana@example.com")(env)
      val found = getUserR(user.id.get)(env)

      found shouldBe defined
      found.get.name shouldBe "Diana"

  // ============================================================
  // 9. Payment Gateway パターン
  // ============================================================

  describe("Payment Gateway パターン"):

    describe("MockPaymentGateway"):
      it("課金を記録できる"):
        val gateway = new MockPaymentGateway()
        val result = gateway.charge(100.0, "valid_token")

        result shouldBe a[PaymentSuccess]
        gateway.getCharges should have length 1
        gateway.getCharges(0) shouldBe (100.0, "valid_token")

      it("失敗をシミュレートできる"):
        val gateway = new MockPaymentGateway()
        gateway.setShouldFail(true)

        gateway.charge(100.0, "valid_token") shouldBe a[PaymentFailure]

      it("返金を記録できる"):
        val gateway = new MockPaymentGateway()
        val chargeResult = gateway.charge(100.0, "valid_token").asInstanceOf[PaymentSuccess]
        val refundResult = gateway.refund(chargeResult.transactionId, 50.0)

        refundResult shouldBe a[PaymentSuccess]
        gateway.getRefunds should have length 1

    describe("StripeGateway"):
      it("有効なトークンで課金できる"):
        val gateway = new StripeGateway()
        val result = gateway.charge(100.0, "valid_token")

        result shouldBe a[PaymentSuccess]
        val success = result.asInstanceOf[PaymentSuccess]
        success.transactionId should startWith("stripe_")

      it("無効なトークンは失敗する"):
        val gateway = new StripeGateway()
        val result = gateway.charge(100.0, "invalid_token")

        result shouldBe a[PaymentFailure]

    describe("PayPalGateway"):
      it("有効なトークンで課金できる"):
        val gateway = new PayPalGateway()
        val result = gateway.charge(100.0, "valid_token")

        result shouldBe a[PaymentSuccess]
        val success = result.asInstanceOf[PaymentSuccess]
        success.transactionId should startWith("paypal_")

    describe("CheckoutService"):
      it("支払いを処理できる"):
        val gateway = new MockPaymentGateway()
        val service = new CheckoutService(gateway)

        val result = service.processPayment(100.0, "valid_token")

        result shouldBe a[Right[_, _]]

      it("失敗時はエラーを返す"):
        val gateway = new MockPaymentGateway()
        gateway.setShouldFail(true)
        val service = new CheckoutService(gateway)

        val result = service.processPayment(100.0, "valid_token")

        result shouldBe a[Left[_, _]]

      it("返金を処理できる"):
        val gateway = new MockPaymentGateway()
        val service = new CheckoutService(gateway)

        val paymentResult = service.processPayment(100.0, "valid_token")
        val transactionId = paymentResult.toOption.get
        val refundResult = service.refundPayment(transactionId, 50.0)

        refundResult shouldBe a[Right[_, _]]

      it("異なる Gateway に切り替え可能"):
        val stripeService = new CheckoutService(new StripeGateway())
        val paypalService = new CheckoutService(new PayPalGateway())

        val stripeResult = stripeService.processPayment(100.0, "valid_token")
        val paypalResult = paypalService.processPayment(100.0, "valid_token")

        stripeResult.toOption.get should startWith("stripe_")
        paypalResult.toOption.get should startWith("paypal_")
