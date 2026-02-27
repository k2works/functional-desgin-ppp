/**
 * 第17章: レンタルビデオシステム
 *
 * Martin Fowler の「リファクタリング」で有名なレンタルビデオシステム。
 * 関数型プログラミングによる料金計算ロジックの設計を学びます。
 */
object VideoRentalSystem:

  // ============================================================
  // 1. 基本型定義
  // ============================================================

  type Money = BigDecimal
  type Days = Int
  type Points = Int

  // ============================================================
  // 2. 映画カテゴリ
  // ============================================================

  /**
   * 映画カテゴリ
   */
  enum MovieCategory:
    case Regular     // 通常: 2日まで2.0、以降1日ごとに1.5追加
    case NewRelease  // 新作: 1日ごとに3.0
    case Childrens   // 子供向け: 3日まで1.5、以降1日ごとに1.5追加

  // ============================================================
  // 3. 映画
  // ============================================================

  /**
   * 映画
   */
  case class Movie(title: String, category: MovieCategory)

  object Movie:
    def regular(title: String): Movie = Movie(title, MovieCategory.Regular)
    def newRelease(title: String): Movie = Movie(title, MovieCategory.NewRelease)
    def childrens(title: String): Movie = Movie(title, MovieCategory.Childrens)

  // ============================================================
  // 4. レンタル
  // ============================================================

  /**
   * レンタル
   */
  case class Rental(movie: Movie, days: Days)

  // ============================================================
  // 5. 顧客
  // ============================================================

  /**
   * 顧客
   */
  case class Customer(name: String, rentals: List[Rental] = Nil):
    def addRental(rental: Rental): Customer =
      copy(rentals = rentals :+ rental)

    def addRentals(newRentals: Rental*): Customer =
      copy(rentals = rentals ++ newRentals)

  // ============================================================
  // 6. 料金計算
  // ============================================================

  /**
   * 料金計算の型クラス
   */
  trait PriceCalculator:
    def calculateAmount(days: Days): Money
    def calculatePoints(days: Days): Points

  /**
   * 通常映画の料金計算
   */
  object RegularPricing extends PriceCalculator:
    def calculateAmount(days: Days): Money =
      if days > 2 then
        BigDecimal(2.0) + BigDecimal((days - 2) * 1.5)
      else
        BigDecimal(2.0)

    def calculatePoints(days: Days): Points = 1

  /**
   * 新作映画の料金計算
   */
  object NewReleasePricing extends PriceCalculator:
    def calculateAmount(days: Days): Money =
      BigDecimal(days * 3.0)

    def calculatePoints(days: Days): Points =
      if days > 1 then 2 else 1

  /**
   * 子供向け映画の料金計算
   */
  object ChildrensPricing extends PriceCalculator:
    def calculateAmount(days: Days): Money =
      if days > 3 then
        BigDecimal(1.5) + BigDecimal((days - 3) * 1.5)
      else
        BigDecimal(1.5)

    def calculatePoints(days: Days): Points = 1

  /**
   * カテゴリに応じた料金計算器を取得
   */
  def getPriceCalculator(category: MovieCategory): PriceCalculator =
    category match
      case MovieCategory.Regular => RegularPricing
      case MovieCategory.NewRelease => NewReleasePricing
      case MovieCategory.Childrens => ChildrensPricing

  /**
   * レンタル料金を計算
   */
  def calculateRentalAmount(rental: Rental): Money =
    getPriceCalculator(rental.movie.category).calculateAmount(rental.days)

  /**
   * レンタルポイントを計算
   */
  def calculateRentalPoints(rental: Rental): Points =
    getPriceCalculator(rental.movie.category).calculatePoints(rental.days)

  /**
   * 合計料金を計算
   */
  def totalAmount(rentals: Seq[Rental]): Money =
    rentals.map(calculateRentalAmount).sum

  /**
   * 合計ポイントを計算
   */
  def totalPoints(rentals: Seq[Rental]): Points =
    rentals.map(calculateRentalPoints).sum

  // ============================================================
  // 7. 明細データ
  // ============================================================

  /**
   * レンタル明細行
   */
  case class RentalLine(
    title: String,
    days: Days,
    amount: Money,
    points: Points
  )

  /**
   * 明細データ
   */
  case class StatementData(
    customerName: String,
    rentalLines: List[RentalLine],
    totalAmount: Money,
    totalPoints: Points
  )

  /**
   * 明細データを生成
   */
  def generateStatementData(customer: Customer): StatementData =
    val lines = customer.rentals.map { rental =>
      RentalLine(
        title = rental.movie.title,
        days = rental.days,
        amount = calculateRentalAmount(rental),
        points = calculateRentalPoints(rental)
      )
    }
    StatementData(
      customerName = customer.name,
      rentalLines = lines,
      totalAmount = totalAmount(customer.rentals),
      totalPoints = totalPoints(customer.rentals)
    )

  // ============================================================
  // 8. 明細書フォーマッター
  // ============================================================

  /**
   * フォーマット形式
   */
  enum StatementFormat:
    case Text
    case Html
    case Json

  /**
   * 明細書フォーマッター trait
   */
  trait StatementFormatter:
    def format(data: StatementData): String

  /**
   * テキスト形式フォーマッター
   */
  object TextFormatter extends StatementFormatter:
    def format(data: StatementData): String =
      val header = s"Rental Record for ${data.customerName}\n"
      val lines = data.rentalLines.map { line =>
        s"\t${line.title}\t${line.amount}\n"
      }.mkString
      val footer = s"Amount owed is ${data.totalAmount}\n" +
        s"You earned ${data.totalPoints} frequent renter points"
      header + lines + footer

  /**
   * HTML形式フォーマッター
   */
  object HtmlFormatter extends StatementFormatter:
    def format(data: StatementData): String =
      val header = s"<h1>Rental Record for <em>${data.customerName}</em></h1>\n<ul>\n"
      val lines = data.rentalLines.map { line =>
        s"  <li>${line.title} - ${line.amount}</li>\n"
      }.mkString
      val footer = s"</ul>\n" +
        s"<p>Amount owed is <strong>${data.totalAmount}</strong></p>\n" +
        s"<p>You earned <strong>${data.totalPoints}</strong> frequent renter points</p>"
      header + lines + footer

  /**
   * JSON形式フォーマッター（簡易実装）
   */
  object JsonFormatter extends StatementFormatter:
    def format(data: StatementData): String =
      val rentalsJson = data.rentalLines.map { line =>
        s"""{"title":"${line.title}","days":${line.days},"amount":${line.amount},"points":${line.points}}"""
      }.mkString(",")
      s"""{"customer":"${data.customerName}","rentals":[$rentalsJson],"totalAmount":${data.totalAmount},"totalPoints":${data.totalPoints}}"""

  /**
   * フォーマット形式に応じたフォーマッターを取得
   */
  def getFormatter(format: StatementFormat): StatementFormatter =
    format match
      case StatementFormat.Text => TextFormatter
      case StatementFormat.Html => HtmlFormatter
      case StatementFormat.Json => JsonFormatter

  /**
   * 明細書を生成
   */
  def generateStatement(customer: Customer, format: StatementFormat = StatementFormat.Text): String =
    val data = generateStatementData(customer)
    getFormatter(format).format(data)

  // ============================================================
  // 9. 拡張可能な料金ポリシー
  // ============================================================

  /**
   * 料金ポリシー（関数型）
   */
  case class PricingPolicy(
    name: String,
    calculateAmount: Days => Money,
    calculatePoints: Days => Points
  )

  /**
   * 定義済み料金ポリシー
   */
  object PricingPolicies:
    val regular: PricingPolicy = PricingPolicy(
      "Regular",
      days => if days > 2 then BigDecimal(2.0 + (days - 2) * 1.5) else BigDecimal(2.0),
      _ => 1
    )

    val newRelease: PricingPolicy = PricingPolicy(
      "New Release",
      days => BigDecimal(days * 3.0),
      days => if days > 1 then 2 else 1
    )

    val childrens: PricingPolicy = PricingPolicy(
      "Children's",
      days => if days > 3 then BigDecimal(1.5 + (days - 3) * 1.5) else BigDecimal(1.5),
      _ => 1
    )

    val premium: PricingPolicy = PricingPolicy(
      "Premium",
      days => BigDecimal(days * 5.0),
      days => days  // 日数分のポイント
    )

  // ============================================================
  // 10. ポリシーベースの映画
  // ============================================================

  /**
   * ポリシーベースの映画
   */
  case class PolicyMovie(title: String, policy: PricingPolicy)

  /**
   * ポリシーベースのレンタル
   */
  case class PolicyRental(movie: PolicyMovie, days: Days):
    def amount: Money = movie.policy.calculateAmount(days)
    def points: Points = movie.policy.calculatePoints(days)

  /**
   * ポリシーベースの顧客
   */
  case class PolicyCustomer(name: String, rentals: List[PolicyRental] = Nil):
    def addRental(rental: PolicyRental): PolicyCustomer =
      copy(rentals = rentals :+ rental)

    def totalAmount: Money = rentals.map(_.amount).sum
    def totalPoints: Points = rentals.map(_.points).sum

  // ============================================================
  // 11. レンタルショップ
  // ============================================================

  /**
   * レンタルショップ
   */
  class RentalShop:
    private var movies: Map[String, Movie] = Map.empty
    private var customers: Map[String, Customer] = Map.empty

    def addMovie(movie: Movie): Unit =
      movies = movies + (movie.title -> movie)

    def getMovie(title: String): Option[Movie] =
      movies.get(title)

    def registerCustomer(name: String): Customer =
      val customer = Customer(name)
      customers = customers + (name -> customer)
      customer

    def getCustomer(name: String): Option[Customer] =
      customers.get(name)

    def rentMovie(customerName: String, movieTitle: String, days: Days): Option[Rental] =
      for
        customer <- customers.get(customerName)
        movie <- movies.get(movieTitle)
      yield
        val rental = Rental(movie, days)
        customers = customers + (customerName -> customer.addRental(rental))
        rental

    def generateCustomerStatement(customerName: String, format: StatementFormat = StatementFormat.Text): Option[String] =
      customers.get(customerName).map(c => generateStatement(c, format))

    def clear(): Unit =
      movies = Map.empty
      customers = Map.empty

  // ============================================================
  // 12. レンタル履歴
  // ============================================================

  /**
   * レンタルイベント
   */
  sealed trait RentalEvent:
    def timestamp: Long

  case class MovieRented(timestamp: Long, customerName: String, movieTitle: String, days: Days, amount: Money) extends RentalEvent
  case class MovieReturned(timestamp: Long, customerName: String, movieTitle: String) extends RentalEvent
  case class PointsRedeemed(timestamp: Long, customerName: String, points: Points) extends RentalEvent

  /**
   * レンタル履歴
   */
  class RentalHistory:
    private var events: List[RentalEvent] = Nil

    def record(event: RentalEvent): Unit =
      events = event :: events

    def getEvents: List[RentalEvent] = events.reverse

    def getEventsByCustomer(customerName: String): List[RentalEvent] =
      events.filter {
        case MovieRented(_, name, _, _, _) => name == customerName
        case MovieReturned(_, name, _) => name == customerName
        case PointsRedeemed(_, name, _) => name == customerName
      }.reverse

    def clear(): Unit = events = Nil

  // ============================================================
  // 13. 割引計算
  // ============================================================

  /**
   * 割引タイプ
   */
  sealed trait Discount:
    def apply(amount: Money): Money

  case class PercentageDiscount(percent: Double) extends Discount:
    def apply(amount: Money): Money = amount * BigDecimal(1 - percent)

  case class FixedDiscount(value: Money) extends Discount:
    def apply(amount: Money): Money = (amount - value) max BigDecimal(0)

  case class PointsDiscount(pointsPerUnit: Points, discountPerUnit: Money) extends Discount:
    private var availablePoints: Points = 0

    def setAvailablePoints(points: Points): PointsDiscount =
      availablePoints = points
      this

    def apply(amount: Money): Money =
      val maxDiscount = BigDecimal(availablePoints / pointsPerUnit) * discountPerUnit
      (amount - maxDiscount) max BigDecimal(0)

  /**
   * 割引を適用
   */
  def applyDiscounts(amount: Money, discounts: Seq[Discount]): Money =
    discounts.foldLeft(amount)((acc, d) => d.apply(acc))

  // ============================================================
  // 14. レポート生成
  // ============================================================

  /**
   * 売上レポート
   */
  case class SalesReport(
    period: String,
    totalRentals: Int,
    totalRevenue: Money,
    rentalsByCategory: Map[MovieCategory, Int],
    revenueByCategory: Map[MovieCategory, Money]
  )

  /**
   * 売上レポートを生成
   */
  def generateSalesReport(rentals: Seq[Rental], period: String): SalesReport =
    val rentalsByCategory = rentals.groupBy(_.movie.category).view.mapValues(_.size).toMap
    val revenueByCategory = rentals.groupBy(_.movie.category).view.mapValues(rs => totalAmount(rs)).toMap

    SalesReport(
      period = period,
      totalRentals = rentals.size,
      totalRevenue = totalAmount(rentals),
      rentalsByCategory = rentalsByCategory,
      revenueByCategory = revenueByCategory
    )

  // ============================================================
  // 15. DSL
  // ============================================================

  /**
   * レンタル DSL
   */
  object RentalDSL:
    def customer(name: String): CustomerBuilder = CustomerBuilder(name)

    case class CustomerBuilder(name: String, rentals: List[Rental] = Nil):
      def rents(movie: Movie, days: Days): CustomerBuilder =
        copy(rentals = rentals :+ Rental(movie, days))

      def build: Customer = Customer(name, rentals)

      def statement: String =
        generateStatement(build)

      def statementAs(format: StatementFormat): String =
        generateStatement(build, format)

    // 便利なメソッド
    def regular(title: String): Movie = Movie.regular(title)
    def newRelease(title: String): Movie = Movie.newRelease(title)
    def childrens(title: String): Movie = Movie.childrens(title)
