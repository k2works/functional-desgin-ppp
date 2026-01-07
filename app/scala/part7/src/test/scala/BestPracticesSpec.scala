import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import BestPractices.*

class BestPracticesSpec extends AnyFunSpec with Matchers:

  describe("データ中心設計"):
    describe("User"):
      it("ユーザーを作成できる"):
        val user = User("u1", "John", "john@example.com")
        user.id shouldBe "u1"
        user.name shouldBe "John"
        user.email shouldBe "john@example.com"

    describe("Order"):
      it("注文を作成できる"):
        val items = Vector(OrderItem("p1", 2, BigDecimal(100)))
        val order = Order("o1", "u1", items)
        order.items.length shouldBe 1
        order.status shouldBe OrderStatus.Pending

  describe("小さな純粋関数"):
    import OrderCalculations.*

    describe("calculateItemTotal"):
      it("アイテムの合計を計算できる"):
        val item = OrderItem("p1", 2, BigDecimal(100))
        calculateItemTotal(item) shouldBe BigDecimal(200)

    describe("calculateOrderTotal"):
      it("注文の合計を計算できる"):
        val items = Vector(
          OrderItem("p1", 2, BigDecimal(100)),
          OrderItem("p2", 1, BigDecimal(200))
        )
        val order = Order("o1", "u1", items)
        calculateOrderTotal(order) shouldBe BigDecimal(400)

    describe("applyDiscount"):
      it("割引を適用できる"):
        applyDiscount(BigDecimal(100), BigDecimal("0.1")) shouldBe BigDecimal(90)

    describe("applyTax"):
      it("税金を適用できる"):
        applyTax(BigDecimal(100), BigDecimal("0.1")) shouldBe BigDecimal(110)

  describe("データ変換パイプライン"):
    import OrderProcessing.*

    it("注文を処理できる"):
      val items = Vector(OrderItem("p1", 2, BigDecimal(100)))
      val order = Order("o1", "u1", items)
      val processed = processOrder(order, BigDecimal("0.1"), BigDecimal("0.08"))

      processed.subtotal shouldBe BigDecimal(200)
      processed.discount shouldBe BigDecimal(20)
      processed.order.status shouldBe OrderStatus.Processing

  describe("データ検証"):
    import Validation.*

    describe("validEmail"):
      it("有効なメールアドレスを検証できる"):
        validEmail("test@example.com") shouldBe true
        validEmail("invalid") shouldBe false
        validEmail("") shouldBe false

    describe("validateUser"):
      it("有効なユーザーを検証できる"):
        val user = User("u1", "John", "john@example.com")
        validateUser(user) shouldBe a[Valid[_]]

      it("無効なユーザーを検出できる"):
        val user = User("u1", "", "invalid")
        validateUser(user) match
          case Invalid(errors) =>
            errors.length shouldBe 2
          case _ => fail("Should be invalid")

    describe("validateOrder"):
      it("有効な注文を検証できる"):
        val items = Vector(OrderItem("p1", 2, BigDecimal(100)))
        val order = Order("o1", "u1", items)
        validateOrder(order) shouldBe a[Valid[_]]

      it("空の注文を検出できる"):
        val order = Order("o1", "u1", Vector.empty)
        validateOrder(order) match
          case Invalid(errors) =>
            errors should contain("Order must have at least one item")
          case _ => fail("Should be invalid")

      it("無効なアイテムを検出できる"):
        val items = Vector(OrderItem("p1", -1, BigDecimal(100)))
        val order = Order("o1", "u1", items)
        validateOrder(order) match
          case Invalid(errors) =>
            errors should contain("Quantity must be positive")
          case _ => fail("Should be invalid")

  describe("イミュータブルな更新"):
    import ImmutableUpdates.*

    describe("updateUserEmail"):
      it("メールアドレスを更新できる"):
        val user = User("u1", "John", "john@example.com")
        updateUserEmail(user, "new@example.com") match
          case Right(updated) => updated.email shouldBe "new@example.com"
          case Left(_) => fail("Should succeed")

      it("無効なメールアドレスで失敗する"):
        val user = User("u1", "John", "john@example.com")
        updateUserEmail(user, "invalid") shouldBe a[Left[_, _]]

    describe("addOrderItem"):
      it("アイテムを追加できる"):
        val order = Order("o1", "u1", Vector.empty)
        val item = OrderItem("p1", 2, BigDecimal(100))
        addOrderItem(order, item) match
          case Right(updated) => updated.items.length shouldBe 1
          case Left(_) => fail("Should succeed")

    describe("cancelOrder"):
      it("保留中の注文をキャンセルできる"):
        val order = Order("o1", "u1", Vector.empty)
        cancelOrder(order) match
          case Right(cancelled) => cancelled.status shouldBe OrderStatus.Cancelled
          case Left(_) => fail("Should succeed")

      it("処理中の注文はキャンセルできない"):
        val order = Order("o1", "u1", Vector.empty, OrderStatus.Processing)
        cancelOrder(order) shouldBe a[Left[_, _]]

  describe("純粋関数と副作用の分離"):
    describe("IO"):
      it("純粋な値をラップできる"):
        val io = IO.pure(42)
        io.run() shouldBe 42

      it("遅延評価ができる"):
        var sideEffect = false
        val io = IO.suspend {
          sideEffect = true
          42
        }
        sideEffect shouldBe false
        io.run() shouldBe 42
        sideEffect shouldBe true

      it("mapで変換できる"):
        val io = IO.pure(21).map(_ * 2)
        io.run() shouldBe 42

      it("flatMapで合成できる"):
        val io = IO.pure(10).flatMap(x => IO.pure(x + 5))
        io.run() shouldBe 15

  describe("高階関数によるデコレーション"):
    import FunctionDecorators.*

    describe("withLogging"):
      it("ロギングを追加できる"):
        val logs = scala.collection.mutable.ListBuffer.empty[String]
        val add = (x: Int) => x + 1
        val logged = withLogging(add, logs += _)

        logged(5) shouldBe 6
        logs should have length 2

    describe("withTiming"):
      it("計測を追加できる"):
        var elapsed: Long = 0
        val slow = (_: Int) => Thread.sleep(10)
        val timed = withTiming(slow, elapsed = _)

        timed(1)
        elapsed should be > 0L

    describe("withRetry"):
      it("リトライを追加できる"):
        var attempts = 0
        val flaky = (_: Int) => {
          attempts += 1
          if attempts < 3 then throw new RuntimeException("fail")
          42
        }
        val retried = withRetry(flaky, 5)

        retried(1).get shouldBe 42
        attempts shouldBe 3

    describe("withCache"):
      it("キャッシュを追加できる"):
        var computations = 0
        val expensive = (x: Int) => {
          computations += 1
          x * 2
        }
        val cached = withCache(expensive)

        cached(5) shouldBe 10
        cached(5) shouldBe 10
        cached(3) shouldBe 6
        computations shouldBe 2  // 5と3の2回のみ計算

  describe("関数合成"):
    import FunctionComposition.*

    describe("pipeline"):
      it("関数をパイプラインで合成できる"):
        val process = pipeline[Int](_ + 1, _ * 2, _ - 3)
        process(5) shouldBe 9  // (5+1)*2-3 = 9

    describe("when"):
      it("条件付きで関数を適用できる"):
        val maybeDouble = when[Int](true)(_ * 2)
        maybeDouble(5) shouldBe 10

        val noop = when[Int](false)(_ * 2)
        noop(5) shouldBe 5

    describe("repeat"):
      it("関数を繰り返し適用できる"):
        val addThree = repeat[Int](3)(_ + 1)
        addThree(0) shouldBe 3

  describe("テスト可能な設計 - 依存性注入"):
    it("インメモリリポジトリを使用できる"):
      val repo = new InMemoryRepository[User, String](_.id)

      val user = User("u1", "John", "john@example.com")
      repo.save(user)

      repo.findById("u1") shouldBe Some(user)
      repo.findAll() should have length 1

    it("エンティティを削除できる"):
      val repo = new InMemoryRepository[User, String](_.id)
      val user = User("u1", "John", "john@example.com")
      repo.save(user)

      repo.delete("u1") shouldBe true
      repo.findById("u1") shouldBe None

  describe("テスト可能な設計 - 時間の抽象化"):
    it("固定時刻でテストできる"):
      val clock = new FixedClock(1000)
      clock.now() shouldBe 1000

    it("シーケンシャルIDを生成できる"):
      val idGen = new SequentialIdGenerator("test")
      idGen.generate() shouldBe "test-1"
      idGen.generate() shouldBe "test-2"

  describe("テスト可能な設計 - 設定の分離"):
    import Pricing.*

    it("デフォルト設定で計算できる"):
      val config = PricingConfig()
      val result = calculatePrice(config, BigDecimal(1000))

      result.discountedPrice shouldBe BigDecimal(1000)
      result.tax shouldBe BigDecimal(100)
      result.total shouldBe BigDecimal(1100)

    it("カスタム設定で計算できる"):
      val config = PricingConfig(
        taxRate = BigDecimal("0.08"),
        discountRate = BigDecimal("0.1")
      )
      val result = calculatePrice(config, BigDecimal(1000))

      result.discountedPrice shouldBe BigDecimal(900)
      result.tax shouldBe BigDecimal(72)
      result.total shouldBe BigDecimal(972)

  describe("テスト可能な設計 - 検証の分離"):
    import Validators.*

    it("複数のバリデータを組み合わせられる"):
      val validateName = combine(
        nonEmptyString("name"),
        minLength("name", 2)
      )

      validateName("") should not be empty
      validateName("A") should not be empty
      validateName("John") shouldBe empty

    it("メールバリデータが動作する"):
      email("email")("test@example.com") shouldBe empty
      email("email")("invalid") should not be empty

  describe("サービス層"):
    it("ユーザーを作成できる"):
      val repo = new InMemoryRepository[User, String](_.id)
      val clock = new FixedClock(1000)
      val idGen = new SequentialIdGenerator("user")
      val service = new UserService(repo, clock, idGen)

      service.createUser("John", "john@example.com") match
        case Right(user) =>
          user.id shouldBe "user-1"
          user.createdAt shouldBe 1000
        case Left(_) => fail("Should succeed")

    it("無効なユーザーでエラーを返す"):
      val repo = new InMemoryRepository[User, String](_.id)
      val clock = new FixedClock(1000)
      val idGen = new SequentialIdGenerator("user")
      val service = new UserService(repo, clock, idGen)

      service.createUser("", "invalid") match
        case Left(errors) => errors should not be empty
        case Right(_) => fail("Should fail")

    it("メールアドレスを更新できる"):
      val repo = new InMemoryRepository[User, String](_.id)
      val clock = new FixedClock(1000)
      val idGen = new SequentialIdGenerator("user")
      val service = new UserService(repo, clock, idGen)

      service.createUser("John", "john@example.com")
      service.updateEmail("user-1", "new@example.com") match
        case Right(user) => user.email shouldBe "new@example.com"
        case Left(_) => fail("Should succeed")

  describe("DSL"):
    it("DSLでユーザーを作成できる"):
      given Clock = new FixedClock(1000)
      given IdGenerator = new SequentialIdGenerator("u")

      import DSL.*
      val u = user("John", "john@example.com")
      u.name shouldBe "John"
      u.id shouldBe "u-1"

    it("DSLで注文を作成できる"):
      given Clock = new FixedClock(1000)
      given IdGenerator = new SequentialIdGenerator("o")

      import DSL.*
      val o = order("u1", item("p1", 2, BigDecimal(100)))
      o.items.length shouldBe 1

    it("DSLで注文を処理できる"):
      given Clock = new FixedClock(1000)
      given IdGenerator = new SequentialIdGenerator("o")

      import DSL.*
      val processed = order("u1", item("p1", 2, BigDecimal(100)))
        .process(BigDecimal("0.1"), BigDecimal("0.08"))
      processed.subtotal shouldBe BigDecimal(200)

  describe("Result型"):
    import Result.*

    it("成功を表現できる"):
      val result = success(42)
      result.isSuccess shouldBe true
      result.getOrElse(0) shouldBe 42

    it("失敗を表現できる"):
      val result: Result[String, Int] = failure("error")
      result.isSuccess shouldBe false
      result.getOrElse(0) shouldBe 0

    it("mapで変換できる"):
      val result = success(21).map(_ * 2)
      result.getOrElse(0) shouldBe 42

    it("flatMapで合成できる"):
      val result = success(10).flatMap(x => success(x + 5))
      result.getOrElse(0) shouldBe 15

    it("Optionから変換できる"):
      fromOption(Some(42), "error").getOrElse(0) shouldBe 42
      fromOption(None, "error") match
        case Failure(e) => e shouldBe "error"
        case _ => fail("Should be failure")

    it("Eitherから変換できる"):
      fromEither(Right(42)).getOrElse(0) shouldBe 42
      fromEither(Left("error")) match
        case Failure(e) => e shouldBe "error"
        case _ => fail("Should be failure")
