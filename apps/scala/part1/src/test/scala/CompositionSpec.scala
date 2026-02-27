package composition

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class CompositionSpec extends AnyFlatSpec with Matchers:

  import Composition.*

  // =============================================================================
  // 関数合成の基本 (andThen, compose)
  // =============================================================================

  "calculateFinalPrice" should "割引、税金、丸めを適用する" in {
    // 1000円 -> 20%割引で800円 -> 10%税込で880円
    calculateFinalPrice(1000) shouldBe 880
  }

  "addTax" should "税金を追加する" in {
    addTax(0.1)(1000) shouldBe 1100.0
  }

  "applyDiscountRate" should "割引を適用する" in {
    applyDiscountRate(0.2)(1000) shouldBe 800.0
  }

  "roundToYen" should "円単位に丸める" in {
    roundToYen(99.5) shouldBe 100
    roundToYen(99.4) shouldBe 99
  }

  "calculateFinalPriceCompose" should "composeでも同じ結果を返す" in {
    calculateFinalPriceCompose(1000) shouldBe 880
  }

  // =============================================================================
  // 部分適用 (カリー化)
  // =============================================================================

  "sayHello" should "Hello で挨拶する" in {
    sayHello("田中") shouldBe "Hello, 田中!"
  }

  "sayGoodbye" should "Goodbye で挨拶する" in {
    sayGoodbye("鈴木") shouldBe "Goodbye, 鈴木!"
  }

  "sendNotification" should "部分適用されたメールを送信する" in {
    val email = sendNotification("メッセージ本文")
    email.from shouldBe "system@example.com"
    email.to shouldBe "user@example.com"
    email.subject shouldBe "通知"
    email.body shouldBe "メッセージ本文"
  }

  // =============================================================================
  // 複数の関数を並列適用
  // =============================================================================

  "getStats" should "数値リストの統計情報を返す" in {
    val (firstVal, lastVal, cnt, minVal, maxVal) = getStats(List(3, 1, 4, 1, 5, 9, 2, 6))
    firstVal shouldBe 3
    lastVal shouldBe 6
    cnt shouldBe 8
    minVal shouldBe 1
    maxVal shouldBe 9
  }

  "analyzePerson" should "人物情報を分析する" in {
    analyzePerson(Map("name" -> "田中", "age" -> 25)) shouldBe PersonAnalysis("田中", 25, "adult")
    analyzePerson(Map("name" -> "鈴木", "age" -> 15)) shouldBe PersonAnalysis("鈴木", 15, "minor")
  }

  // =============================================================================
  // 高階関数によるデータ処理
  // =============================================================================

  "processWithLogging" should "ログを出力しながら処理を実行する" in {
    val doubleWithLog = processWithLogging[Int, Int](_ * 2)
    doubleWithLog(5) shouldBe 10
  }

  "retry" should "失敗時にリトライする" in {
    var counter = 0
    val flakyFn: Int => String = _ => {
      counter += 1
      if counter < 3 then throw new RuntimeException("一時的なエラー")
      else "成功"
    }
    val retryFn = retry(flakyFn, 5)
    retryFn(0) shouldBe "成功"
    counter shouldBe 3
  }

  // =============================================================================
  // パイプライン処理
  // =============================================================================

  "pipeline" should "関数を順次適用する" in {
    val doubleThenAdd10 = pipeline[Int](_ * 2, _ + 10)
    doubleThenAdd10(10) shouldBe 30
  }

  "processOrderPipeline" should "注文を処理する" in {
    val order = Order(
      items = List(OrderItem(1000, 2), OrderItem(500, 3)),
      customer = Customer("gold")
    )
    val result = processOrderPipeline(order)
    // 合計: 2000 + 1500 = 3500
    // 割引: 3500 * 0.9 = 3150
    // 送料: 3150 >= 5000 ? 0 : 500 => 500
    // 最終: 3150 + 500 = 3650
    result.total shouldBe 3650.0
    result.shipping shouldBe 500
  }

  "validateOrder" should "空の注文でエラーを投げる" in {
    an[IllegalArgumentException] should be thrownBy {
      validateOrder(Order(items = List.empty, customer = Customer("regular")))
    }
  }

  // =============================================================================
  // 関数合成によるバリデーション
  // =============================================================================

  "validateQuantity" should "有効な数量を検証する" in {
    validateQuantity(50).valid shouldBe true
    validateQuantity(-1).valid shouldBe false
    validateQuantity(100).valid shouldBe false
  }

  "validator" should "述語に基づいてバリデーションする" in {
    val v = validator[Int](_ % 2 == 0, "偶数である必要があります")
    v(2).valid shouldBe true
    v(3).valid shouldBe false
    v(3).error shouldBe Some("偶数である必要があります")
  }

  // =============================================================================
  // 関数の変換
  // =============================================================================

  "flip" should "引数の順序を反転する" in {
    val subtract = (a: Int, b: Int) => a - b
    flip(subtract)(3, 5) shouldBe 2  // 5 - 3 = 2
  }

  "complementFn" should "述語の結果を反転する" in {
    val isEven = (x: Int) => x % 2 == 0
    val notEven = complementFn(isEven)
    notEven(3) shouldBe true
    notEven(2) shouldBe false
  }

  "constantlyFn" should "常に同じ値を返す" in {
    val always42 = constantlyFn[Any, Int](42)
    always42(()) shouldBe 42
    always42("anything") shouldBe 42
  }

  "curry" should "2引数関数をカリー化する" in {
    val add = (a: Int, b: Int) => a + b
    val curriedAdd = curry(add)
    val add5 = curriedAdd(5)
    add5(3) shouldBe 8
  }

  "uncurry" should "カリー化された関数を元に戻す" in {
    val curried = (a: Int) => (b: Int) => a + b
    val uncurried = uncurry(curried)
    uncurried(5, 3) shouldBe 8
  }

  // =============================================================================
  // 関数合成のパターン
  // =============================================================================

  "validAge" should "有効な年齢をチェックする" in {
    validAge(25) shouldBe true
    validAge(1) shouldBe true
    validAge(150) shouldBe true
    validAge(-1) shouldBe false
    validAge(151) shouldBe false
  }

  "premiumCustomer" should "プレミアム顧客をチェックする" in {
    premiumCustomer(CustomerInfo("gold", 0, 0)) shouldBe true
    premiumCustomer(CustomerInfo("bronze", 100, 0)) shouldBe true
    premiumCustomer(CustomerInfo("bronze", 0, 100000)) shouldBe true
    premiumCustomer(CustomerInfo("bronze", 10, 1000)) shouldBe false
  }
