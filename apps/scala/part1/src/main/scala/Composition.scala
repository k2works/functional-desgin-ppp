package composition

/**
 * 第2章: 関数合成と高階関数
 *
 * 小さな関数を組み合わせて複雑な処理を構築する方法を学びます。
 * andThen、compose、部分適用などの関数合成ツールと、
 * 高階関数を活用したデータ処理パターンを扱います。
 */
object Composition:

  // =============================================================================
  // 1. 関数合成の基本 (andThen, compose)
  // =============================================================================

  /**
   * 税金を追加する
   */
  def addTax(rate: Double)(amount: Double): Double =
    amount * (1 + rate)

  /**
   * 割引を適用する
   */
  def applyDiscountRate(rate: Double)(amount: Double): Double =
    amount * (1 - rate)

  /**
   * 円単位に丸める
   */
  def roundToYen(amount: Double): Long =
    Math.round(amount)

  /**
   * 最終価格を計算する合成関数
   * andThen: 左から右へ実行
   * compose: 右から左へ実行
   */
  val calculateFinalPrice: Double => Long =
    applyDiscountRate(0.2) andThen addTax(0.1) andThen roundToYen

  // composeを使った場合（右から左）
  val calculateFinalPriceCompose: Double => Long =
    (roundToYen _) compose addTax(0.1) compose applyDiscountRate(0.2)

  // =============================================================================
  // 2. 部分適用とカリー化
  // =============================================================================

  /**
   * 挨拶する
   */
  def greet(greeting: String, name: String): String =
    s"$greeting, $name!"

  // カリー化版
  def greetCurried(greeting: String)(name: String): String =
    s"$greeting, $name!"

  val sayHello: String => String = greetCurried("Hello")
  val sayGoodbye: String => String = greetCurried("Goodbye")

  /**
   * メールを送信する
   */
  case class Email(from: String, to: String, subject: String, body: String)

  def sendEmail(from: String)(to: String)(subject: String)(body: String): Email =
    Email(from, to, subject, body)

  val sendFromSystem: String => String => String => Email = sendEmail("system@example.com")
  val sendNotification: String => Email = sendFromSystem("user@example.com")("通知")

  // =============================================================================
  // 3. 複数の関数を並列適用（Scala版 juxt）
  // =============================================================================

  /**
   * 数値リストの統計情報を取得する
   */
  def getStats(numbers: List[Int]): (Int, Int, Int, Int, Int) =
    (numbers.head, numbers.last, numbers.length, numbers.min, numbers.max)

  /**
   * 人物情報を分析する
   */
  case class PersonAnalysis(name: String, age: Int, category: String)

  def analyzePerson(person: Map[String, Any]): PersonAnalysis =
    val name = person("name").asInstanceOf[String]
    val age = person("age").asInstanceOf[Int]
    val category = if age >= 18 then "adult" else "minor"
    PersonAnalysis(name, age, category)

  // =============================================================================
  // 4. 高階関数によるデータ処理
  // =============================================================================

  /**
   * 処理をラップしてログを出力する高階関数
   */
  def processWithLogging[A, B](f: A => B): A => B =
    (input: A) =>
      println(s"入力: $input")
      val result = f(input)
      println(s"出力: $result")
      result

  /**
   * 失敗時にリトライする高階関数
   */
  def retry[A, B](f: A => B, maxRetries: Int): A => B =
    (input: A) =>
      def attempt(attempts: Int): B =
        try
          f(input)
        catch
          case e: Exception =>
            if attempts < maxRetries then attempt(attempts + 1)
            else throw e
      attempt(0)

  /**
   * TTL付きメモ化を行う高階関数
   */
  def memoizeWithTtl[A, B](f: A => B, ttlMs: Long): A => B =
    var cache: Map[A, (B, Long)] = Map.empty

    (input: A) =>
      val now = System.currentTimeMillis()
      cache.get(input) match
        case Some((value, time)) if now - time < ttlMs => value
        case _ =>
          val result = f(input)
          cache = cache + (input -> (result, now))
          result

  // =============================================================================
  // 5. パイプライン処理
  // =============================================================================

  /**
   * 関数のリストを順次適用するパイプラインを作成する
   */
  def pipeline[A](fns: (A => A)*): A => A =
    (input: A) => fns.foldLeft(input)((acc, f) => f(acc))

  // 注文処理パイプライン
  case class OrderItem(price: Int, quantity: Int)
  case class Customer(membership: String)
  case class Order(items: List[OrderItem], customer: Customer, total: Double = 0, shipping: Int = 0)

  /**
   * 注文を検証する
   */
  def validateOrder(order: Order): Order =
    if order.items.isEmpty then
      throw new IllegalArgumentException("注文にアイテムがありません")
    else
      order

  /**
   * 注文合計を計算する
   */
  def calculateOrderTotal(order: Order): Order =
    val total = order.items.map(item => item.price * item.quantity).sum
    order.copy(total = total)

  /**
   * 注文割引を適用する
   */
  def applyOrderDiscount(order: Order): Order =
    val discountRates = Map("gold" -> 0.1, "silver" -> 0.05, "bronze" -> 0.02)
    val discountRate = discountRates.getOrElse(order.customer.membership, 0.0)
    order.copy(total = order.total * (1 - discountRate))

  /**
   * 送料を追加する
   */
  def addShipping(order: Order): Order =
    val shipping = if order.total >= 5000 then 0 else 500
    order.copy(shipping = shipping, total = order.total + shipping)

  val processOrderPipeline: Order => Order =
    pipeline(validateOrder, calculateOrderTotal, applyOrderDiscount, addShipping)

  // =============================================================================
  // 6. 関数合成によるバリデーション
  // =============================================================================

  case class ValidationResult[A](valid: Boolean, value: A, error: Option[String] = None)

  /**
   * バリデータを作成する高階関数
   */
  def validator[A](pred: A => Boolean, errorMsg: String): A => ValidationResult[A] =
    (value: A) =>
      if pred(value) then ValidationResult(valid = true, value = value)
      else ValidationResult(valid = false, value = value, error = Some(errorMsg))

  /**
   * 複数のバリデータを合成する
   */
  def combineValidators[A](validators: (A => ValidationResult[A])*): A => ValidationResult[A] =
    (value: A) =>
      validators.foldLeft(ValidationResult(valid = true, value = value)) { (result, v) =>
        if result.valid then v(result.value)
        else result
      }

  val validatePositive: Int => ValidationResult[Int] =
    validator[Int](_ > 0, "値は正の数である必要があります")

  val validateUnder100: Int => ValidationResult[Int] =
    validator[Int](_ < 100, "値は100未満である必要があります")

  val validateInteger: Any => ValidationResult[Any] =
    validator[Any](_.isInstanceOf[Int], "値は整数である必要があります")

  def validateQuantity(value: Int): ValidationResult[Int] =
    combineValidators(validatePositive, validateUnder100)(value)

  // =============================================================================
  // 7. 関数の変換
  // =============================================================================

  /**
   * 引数の順序を反転する
   */
  def flip[A, B, C](f: (A, B) => C): (B, A) => C =
    (b: B, a: A) => f(a, b)

  /**
   * 述語の結果を反転する
   */
  def complementFn[A](pred: A => Boolean): A => Boolean =
    (a: A) => !pred(a)

  /**
   * 常に同じ値を返す関数を作成する
   */
  def constantlyFn[A, B](value: B): A => B =
    (_: A) => value

  /**
   * 2引数関数をカリー化する
   */
  def curry[A, B, C](f: (A, B) => C): A => B => C =
    (a: A) => (b: B) => f(a, b)

  /**
   * カリー化された関数を元に戻す
   */
  def uncurry[A, B, C](f: A => B => C): (A, B) => C =
    (a: A, b: B) => f(a)(b)

  // =============================================================================
  // 8. 関数合成のパターン
  // =============================================================================

  /**
   * 複数の述語を AND で合成する
   */
  def composePredicates[A](preds: (A => Boolean)*): A => Boolean =
    (x: A) => preds.forall(_(x))

  /**
   * 複数の述語を OR で合成する
   */
  def composePredicatesOr[A](preds: (A => Boolean)*): A => Boolean =
    (x: A) => preds.exists(_(x))

  /**
   * 有効な年齢かチェックする
   */
  val validAge: Int => Boolean =
    composePredicates[Int](
      _ > 0,
      _ <= 150
    )

  /**
   * プレミアム顧客かチェックする
   */
  case class CustomerInfo(membership: String, purchaseCount: Int, totalSpent: Int)

  val premiumCustomer: CustomerInfo => Boolean =
    composePredicatesOr[CustomerInfo](
      _.membership == "gold",
      _.purchaseCount >= 100,
      _.totalSpent >= 100000
    )
