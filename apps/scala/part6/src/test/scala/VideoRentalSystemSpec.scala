import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import VideoRentalSystem.*

class VideoRentalSystemSpec extends AnyFunSpec with Matchers:

  // ============================================================
  // 1. 映画作成
  // ============================================================

  describe("Movie"):

    it("通常映画を作成できる"):
      val movie = Movie.regular("Inception")
      movie.title shouldBe "Inception"
      movie.category shouldBe MovieCategory.Regular

    it("新作映画を作成できる"):
      val movie = Movie.newRelease("New Movie")
      movie.category shouldBe MovieCategory.NewRelease

    it("子供向け映画を作成できる"):
      val movie = Movie.childrens("Frozen")
      movie.category shouldBe MovieCategory.Childrens

  // ============================================================
  // 2. 料金計算
  // ============================================================

  describe("料金計算"):

    describe("通常映画"):
      it("2日以内は2.0"):
        val rental = Rental(Movie.regular("Test"), 1)
        calculateRentalAmount(rental) shouldBe BigDecimal(2.0)

      it("2日でも2.0"):
        val rental = Rental(Movie.regular("Test"), 2)
        calculateRentalAmount(rental) shouldBe BigDecimal(2.0)

      it("3日は3.5 (2.0 + 1.5)"):
        val rental = Rental(Movie.regular("Test"), 3)
        calculateRentalAmount(rental) shouldBe BigDecimal(3.5)

      it("5日は6.5 (2.0 + 3 * 1.5)"):
        val rental = Rental(Movie.regular("Test"), 5)
        calculateRentalAmount(rental) shouldBe BigDecimal(6.5)

    describe("新作映画"):
      it("1日は3.0"):
        val rental = Rental(Movie.newRelease("Test"), 1)
        calculateRentalAmount(rental) shouldBe BigDecimal(3.0)

      it("3日は9.0"):
        val rental = Rental(Movie.newRelease("Test"), 3)
        calculateRentalAmount(rental) shouldBe BigDecimal(9.0)

    describe("子供向け映画"):
      it("3日以内は1.5"):
        val rental = Rental(Movie.childrens("Test"), 2)
        calculateRentalAmount(rental) shouldBe BigDecimal(1.5)

      it("3日でも1.5"):
        val rental = Rental(Movie.childrens("Test"), 3)
        calculateRentalAmount(rental) shouldBe BigDecimal(1.5)

      it("4日は3.0 (1.5 + 1.5)"):
        val rental = Rental(Movie.childrens("Test"), 4)
        calculateRentalAmount(rental) shouldBe BigDecimal(3.0)

      it("6日は6.0 (1.5 + 3 * 1.5)"):
        val rental = Rental(Movie.childrens("Test"), 6)
        calculateRentalAmount(rental) shouldBe BigDecimal(6.0)

  // ============================================================
  // 3. ポイント計算
  // ============================================================

  describe("ポイント計算"):

    it("通常映画は1ポイント"):
      val rental = Rental(Movie.regular("Test"), 5)
      calculateRentalPoints(rental) shouldBe 1

    it("子供向け映画は1ポイント"):
      val rental = Rental(Movie.childrens("Test"), 5)
      calculateRentalPoints(rental) shouldBe 1

    it("新作映画1日は1ポイント"):
      val rental = Rental(Movie.newRelease("Test"), 1)
      calculateRentalPoints(rental) shouldBe 1

    it("新作映画2日以上は2ポイント"):
      val rental = Rental(Movie.newRelease("Test"), 2)
      calculateRentalPoints(rental) shouldBe 2

  // ============================================================
  // 4. 合計計算
  // ============================================================

  describe("合計計算"):

    it("複数レンタルの合計料金を計算できる"):
      val rentals = List(
        Rental(Movie.regular("Inception"), 3),     // 3.5
        Rental(Movie.childrens("Frozen"), 4),       // 3.0
        Rental(Movie.newRelease("New Movie"), 2)   // 6.0
      )
      totalAmount(rentals) shouldBe BigDecimal(12.5)

    it("複数レンタルの合計ポイントを計算できる"):
      val rentals = List(
        Rental(Movie.regular("Inception"), 3),     // 1
        Rental(Movie.childrens("Frozen"), 4),       // 1
        Rental(Movie.newRelease("New Movie"), 2)   // 2
      )
      totalPoints(rentals) shouldBe 4

  // ============================================================
  // 5. 顧客
  // ============================================================

  describe("Customer"):

    it("レンタルを追加できる"):
      val customer = Customer("John")
        .addRental(Rental(Movie.regular("Test"), 3))
      customer.rentals should have length 1

    it("複数のレンタルを追加できる"):
      val customer = Customer("John")
        .addRentals(
          Rental(Movie.regular("Test1"), 3),
          Rental(Movie.newRelease("Test2"), 2)
        )
      customer.rentals should have length 2

  // ============================================================
  // 6. 明細データ
  // ============================================================

  describe("StatementData"):

    it("明細データを生成できる"):
      val customer = Customer("John")
        .addRentals(
          Rental(Movie.regular("Inception"), 3),
          Rental(Movie.newRelease("New Movie"), 2)
        )
      val data = generateStatementData(customer)

      data.customerName shouldBe "John"
      data.rentalLines should have length 2
      data.totalAmount shouldBe BigDecimal(9.5) // 3.5 + 6.0
      data.totalPoints shouldBe 3  // 1 + 2

  // ============================================================
  // 7. 明細書フォーマッター
  // ============================================================

  describe("明細書フォーマッター"):

    val customer = Customer("John")
      .addRentals(
        Rental(Movie.regular("Inception"), 3),
        Rental(Movie.newRelease("New Movie"), 2)
      )

    describe("テキスト形式"):
      it("テキスト明細書を生成できる"):
        val statement = generateStatement(customer, StatementFormat.Text)

        statement should include("Rental Record for John")
        statement should include("Inception")
        statement should include("3.5")
        statement should include("New Movie")
        statement should include("6")
        statement should include("Amount owed is 9.5")
        statement should include("3 frequent renter points")

    describe("HTML形式"):
      it("HTML明細書を生成できる"):
        val statement = generateStatement(customer, StatementFormat.Html)

        statement should include("<h1>Rental Record for <em>John</em></h1>")
        statement should include("<li>Inception - 3.5</li>")
        statement should include("New Movie")
        statement should include("<strong>9.5</strong>")
        statement should include("<strong>3</strong>")

    describe("JSON形式"):
      it("JSON明細書を生成できる"):
        val statement = generateStatement(customer, StatementFormat.Json)

        statement should include("\"customer\":\"John\"")
        statement should include("\"title\":\"Inception\"")
        statement should include("\"totalAmount\":9.5")
        statement should include("\"totalPoints\":3")

  // ============================================================
  // 8. ポリシーベース
  // ============================================================

  describe("PricingPolicy"):

    import PricingPolicies.*

    it("通常ポリシーで料金を計算できる"):
      regular.calculateAmount(3) shouldBe BigDecimal(3.5)

    it("新作ポリシーで料金を計算できる"):
      newRelease.calculateAmount(3) shouldBe BigDecimal(9.0)

    it("子供向けポリシーで料金を計算できる"):
      childrens.calculateAmount(4) shouldBe BigDecimal(3.0)

    it("プレミアムポリシーで料金を計算できる"):
      premium.calculateAmount(3) shouldBe BigDecimal(15.0)
      premium.calculatePoints(3) shouldBe 3

  describe("PolicyCustomer"):

    import PricingPolicies.*

    it("ポリシーベースの顧客で合計を計算できる"):
      val customer = PolicyCustomer("Alice")
        .addRental(PolicyRental(PolicyMovie("Movie1", regular), 3))
        .addRental(PolicyRental(PolicyMovie("Movie2", premium), 2))

      customer.totalAmount shouldBe BigDecimal(13.5) // 3.5 + 10.0
      customer.totalPoints shouldBe 3  // 1 + 2

  // ============================================================
  // 9. レンタルショップ
  // ============================================================

  describe("RentalShop"):

    it("映画を追加して取得できる"):
      val shop = new RentalShop
      shop.addMovie(Movie.regular("Inception"))

      shop.getMovie("Inception") shouldBe Some(Movie.regular("Inception"))

    it("顧客を登録できる"):
      val shop = new RentalShop
      shop.registerCustomer("John")

      shop.getCustomer("John") shouldBe defined

    it("映画をレンタルできる"):
      val shop = new RentalShop
      shop.addMovie(Movie.regular("Inception"))
      shop.registerCustomer("John")

      val rental = shop.rentMovie("John", "Inception", 3)

      rental shouldBe defined
      shop.getCustomer("John").get.rentals should have length 1

    it("顧客の明細書を生成できる"):
      val shop = new RentalShop
      shop.addMovie(Movie.regular("Inception"))
      shop.registerCustomer("John")
      shop.rentMovie("John", "Inception", 3)

      val statement = shop.generateCustomerStatement("John")

      statement shouldBe defined
      statement.get should include("John")
      statement.get should include("Inception")

  // ============================================================
  // 10. レンタル履歴
  // ============================================================

  describe("RentalHistory"):

    it("イベントを記録できる"):
      val history = new RentalHistory
      history.record(MovieRented(1000L, "John", "Inception", 3, BigDecimal(3.5)))
      history.record(MovieReturned(2000L, "John", "Inception"))

      history.getEvents should have length 2

    it("顧客別にイベントを取得できる"):
      val history = new RentalHistory
      history.record(MovieRented(1000L, "John", "Inception", 3, BigDecimal(3.5)))
      history.record(MovieRented(1500L, "Alice", "Frozen", 2, BigDecimal(1.5)))
      history.record(MovieReturned(2000L, "John", "Inception"))

      history.getEventsByCustomer("John") should have length 2

  // ============================================================
  // 11. 割引
  // ============================================================

  describe("Discount"):

    it("パーセント割引を適用できる"):
      val discount = PercentageDiscount(0.1)
      discount.apply(BigDecimal(100)) shouldBe BigDecimal(90)

    it("固定割引を適用できる"):
      val discount = FixedDiscount(BigDecimal(20))
      discount.apply(BigDecimal(100)) shouldBe BigDecimal(80)

    it("固定割引は0以下にならない"):
      val discount = FixedDiscount(BigDecimal(200))
      discount.apply(BigDecimal(100)) shouldBe BigDecimal(0)

    it("複数の割引を適用できる"):
      val discounts = Seq(
        PercentageDiscount(0.1),  // 100 -> 90
        FixedDiscount(BigDecimal(10))  // 90 -> 80
      )
      applyDiscounts(BigDecimal(100), discounts) shouldBe BigDecimal(80)

  // ============================================================
  // 12. 売上レポート
  // ============================================================

  describe("SalesReport"):

    it("売上レポートを生成できる"):
      val rentals = List(
        Rental(Movie.regular("Inception"), 3),
        Rental(Movie.regular("Matrix"), 2),
        Rental(Movie.newRelease("New Movie"), 2),
        Rental(Movie.childrens("Frozen"), 4)
      )

      val report = generateSalesReport(rentals, "2024-01")

      report.period shouldBe "2024-01"
      report.totalRentals shouldBe 4
      report.totalRevenue shouldBe BigDecimal(14.5) // 3.5 + 2.0 + 6.0 + 3.0
      report.rentalsByCategory(MovieCategory.Regular) shouldBe 2
      report.rentalsByCategory(MovieCategory.NewRelease) shouldBe 1
      report.rentalsByCategory(MovieCategory.Childrens) shouldBe 1

  // ============================================================
  // 13. DSL
  // ============================================================

  describe("RentalDSL"):

    import RentalDSL.*

    it("DSLで顧客とレンタルを作成できる"):
      val c = customer("John")
        .rents(regular("Inception"), 3)
        .rents(newRelease("New Movie"), 2)
        .build

      c.name shouldBe "John"
      c.rentals should have length 2

    it("DSLで明細書を生成できる"):
      val statement = customer("John")
        .rents(regular("Inception"), 3)
        .statement

      statement should include("John")
      statement should include("Inception")

    it("DSLで指定形式の明細書を生成できる"):
      val statement = customer("John")
        .rents(regular("Inception"), 3)
        .statementAs(StatementFormat.Html)

      statement should include("<h1>")
