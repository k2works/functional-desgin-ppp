/**
 * 第5章: プロパティベーステスト - テストコード
 * 
 * ScalaCheck と ScalaTest の統合を使用してプロパティベーステストを実装します。
 */
package propertybasedtesting

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers
import org.scalatestplus.scalacheck.ScalaCheckPropertyChecks
import org.scalacheck.{Gen, Arbitrary, Shrink}
import org.scalacheck.Prop.forAll

class PropertyBasedTestingSpec extends AnyFunSuite with Matchers with ScalaCheckPropertyChecks:

  // ============================================
  // 1. 文字列操作のプロパティ
  // ============================================
  
  test("文字列反転は対合（involutory）: 2回反転すると元に戻る") {
    forAll { (s: String) =>
      StringOperations.reverseString(StringOperations.reverseString(s)) shouldBe s
    }
  }
  
  test("文字列反転は長さを保存する") {
    forAll { (s: String) =>
      StringOperations.reverseString(s).length shouldBe s.length
    }
  }
  
  test("大文字変換は冪等: 2回変換しても結果は同じ") {
    forAll { (s: String) =>
      StringOperations.toUpperCase(StringOperations.toUpperCase(s)) shouldBe 
        StringOperations.toUpperCase(s)
    }
  }
  
  test("小文字変換は冪等: 2回変換しても結果は同じ") {
    forAll { (s: String) =>
      StringOperations.toLowerCase(StringOperations.toLowerCase(s)) shouldBe 
        StringOperations.toLowerCase(s)
    }
  }
  
  test("大文字→小文字→大文字は大文字変換と同じ（英字のみ）") {
    forAll(Gen.alphaStr) { s =>
      StringOperations.toUpperCase(StringOperations.toLowerCase(s)) shouldBe 
        StringOperations.toUpperCase(s)
    }
  }

  // ============================================
  // 2. ソートのプロパティ
  // ============================================
  
  test("ソートは冪等: 2回ソートしても結果は同じ") {
    forAll { (nums: List[Int]) =>
      NumberOperations.sortNumbers(NumberOperations.sortNumbers(nums)) shouldBe 
        NumberOperations.sortNumbers(nums)
    }
  }
  
  test("ソートは要素を保存する: 要素の出現回数は変わらない") {
    forAll { (nums: List[Int]) =>
      NumberOperations.sortNumbers(nums).groupBy(identity).view.mapValues(_.size).toMap shouldBe
        nums.groupBy(identity).view.mapValues(_.size).toMap
    }
  }
  
  test("ソートは長さを保存する") {
    forAll { (nums: List[Int]) =>
      NumberOperations.sortNumbers(nums).length shouldBe nums.length
    }
  }
  
  test("ソート結果は昇順に並ぶ") {
    forAll { (nums: List[Int]) =>
      val sorted = NumberOperations.sortNumbers(nums)
      sorted.zip(sorted.drop(1)).forall { case (a, b) => a <= b } shouldBe true
    }
  }
  
  test("ソート結果の最初の要素は最小値") {
    forAll(Gen.nonEmptyListOf(Gen.chooseNum(-1000, 1000))) { nums =>
      NumberOperations.sortNumbers(nums).headOption shouldBe NumberOperations.minOption(nums)
    }
  }
  
  test("ソート結果の最後の要素は最大値") {
    forAll(Gen.nonEmptyListOf(Gen.chooseNum(-1000, 1000))) { nums =>
      NumberOperations.sortNumbers(nums).lastOption shouldBe NumberOperations.maxOption(nums)
    }
  }

  // ============================================
  // 3. 数値演算のプロパティ
  // ============================================
  
  test("絶対値は非負") {
    // Integer.MIN_VALUE を除外（オーバーフロー問題）
    forAll(Gen.chooseNum(Int.MinValue + 1, Int.MaxValue)) { n =>
      NumberOperations.abs(n) should be >= 0
    }
  }
  
  test("絶対値は冪等") {
    forAll(Gen.chooseNum(Int.MinValue + 1, Int.MaxValue)) { n =>
      NumberOperations.abs(NumberOperations.abs(n)) shouldBe NumberOperations.abs(n)
    }
  }
  
  test("加算の結合律") {
    forAll(Gen.chooseNum(-1000, 1000), Gen.chooseNum(-1000, 1000), Gen.chooseNum(-1000, 1000)) { 
      (a, b, c) =>
      ((a + b) + c) shouldBe (a + (b + c))
    }
  }
  
  test("加算の交換律") {
    forAll { (a: Int, b: Int) =>
      (a + b) shouldBe (b + a)
    }
  }
  
  test("加算の単位元") {
    forAll { (a: Int) =>
      (a + 0) shouldBe a
    }
  }
  
  test("乗算の結合律") {
    forAll(Gen.chooseNum(-100, 100), Gen.chooseNum(-100, 100), Gen.chooseNum(-100, 100)) { 
      (a, b, c) =>
      ((a * b) * c) shouldBe (a * (b * c))
    }
  }
  
  test("乗算の交換律") {
    forAll { (a: Int, b: Int) =>
      (a * b) shouldBe (b * a)
    }
  }
  
  test("乗算の単位元") {
    forAll { (a: Int) =>
      (a * 1) shouldBe a
    }
  }

  // ============================================
  // 4. ドメインモデルのジェネレータ
  // ============================================
  
  // カスタムジェネレータ
  val membershipGen: Gen[Membership] = Gen.oneOf(
    Membership.Bronze, Membership.Silver, Membership.Gold, Membership.Platinum
  )
  
  // 名前用のジェネレータ（英数字、非空）
  val nameGen: Gen[String] = Gen.alphaNumStr.suchThat(_.nonEmpty)
  
  val personGen: Gen[Person] = for
    name <- nameGen
    age <- Gen.chooseNum(0, 150)
    membership <- membershipGen
  yield Person(name, age, membership)
  
  val productGen: Gen[Product] = for
    id <- Gen.posNum[Int].map(Generators.formatProductId)
    name <- nameGen
    price <- Gen.posNum[Int].map(Generators.normalizePrice)
    quantity <- Gen.posNum[Int].map(Generators.normalizeQuantity)
  yield Product(id, name, price, quantity)
  
  val orderItemGen: Gen[OrderItem] = for
    product <- productGen
    quantity <- Gen.chooseNum(1, 10)
  yield OrderItem(product, quantity)
  
  val orderGen: Gen[Order] = for
    id <- Gen.posNum[Int].map(Generators.formatOrderId)
    items <- Gen.nonEmptyListOf(orderItemGen).map(_.take(5)) // 最大5アイテム
    customerId <- Gen.uuid.map(_.toString)
  yield Order(id, items, customerId)
  
  test("生成されたPersonは有効な年齢を持つ") {
    forAll(personGen) { person =>
      person.age should be >= 0
      person.age should be <= 150
    }
  }
  
  test("生成されたProductは有効な価格を持つ") {
    forAll(productGen) { product =>
      product.price should be > BigDecimal(0)
    }
  }
  
  test("生成されたProductは有効なIDを持つ") {
    forAll(productGen) { product =>
      Validation.isValidProductId(product.productId) shouldBe true
    }
  }
  
  test("生成されたOrderは有効なIDを持つ") {
    forAll(orderGen) { order =>
      Validation.isValidOrderId(order.orderId) shouldBe true
    }
  }

  // ============================================
  // 5. ビジネスロジックのプロパティ
  // ============================================
  
  test("割引後の価格は0以上、元の価格以下") {
    forAll(
      Gen.chooseNum(0, 10000).map(BigDecimal(_)),
      Gen.chooseNum(0.0, 1.0)
    ) { (price, rate) =>
      val discounted = PricingLogic.calculateDiscount(price, rate)
      discounted should be >= BigDecimal(0)
      discounted should be <= price
    }
  }
  
  test("割引率0%では価格は変わらない") {
    forAll(Gen.chooseNum(0, 10000).map(BigDecimal(_))) { price =>
      PricingLogic.calculateDiscount(price, 0.0) shouldBe price
    }
  }
  
  test("割引率100%では価格は0になる") {
    forAll(Gen.chooseNum(0, 10000).map(BigDecimal(_))) { price =>
      PricingLogic.calculateDiscount(price, 1.0) shouldBe BigDecimal(0)
    }
  }
  
  test("注文合計は常に非負") {
    forAll(orderGen) { order =>
      PricingLogic.calculateOrderTotal(order) should be >= BigDecimal(0)
    }
  }
  
  test("最終価格は注文合計以下（会員割引適用後）") {
    forAll(orderGen, membershipGen) { (order, membership) =>
      val total = PricingLogic.calculateOrderTotal(order)
      val finalPrice = PricingLogic.calculateFinalPrice(order, membership)
      finalPrice should be <= total
    }
  }
  
  test("Platinumは最大の割引を受ける") {
    forAll(orderGen) { order =>
      val platinumPrice = PricingLogic.calculateFinalPrice(order, Membership.Platinum)
      val bronzePrice = PricingLogic.calculateFinalPrice(order, Membership.Bronze)
      platinumPrice should be <= bronzePrice
    }
  }

  // ============================================
  // 6. ラウンドトリッププロパティ
  // ============================================
  
  test("ランレングス符号化は可逆") {
    forAll(Gen.alphaStr) { s =>
      RunLengthEncoding.decode(RunLengthEncoding.encode(s)) shouldBe s
    }
  }
  
  test("Base64エンコード/デコードは可逆") {
    forAll { (s: String) =>
      Base64Codec.decode(Base64Codec.encode(s)) shouldBe s
    }
  }
  
  // 簡易JSONコーデックは特殊文字を含まない場合のみ正しく動作
  val safeNameGen: Gen[String] = Gen.alphaNumStr.suchThat(s => 
    s.nonEmpty && !s.contains("\"") && !s.contains("\\")
  )
  
  val safePersonGen: Gen[Person] = for
    name <- safeNameGen
    age <- Gen.chooseNum(0, 150)
    membership <- membershipGen
  yield Person(name, age, membership)
  
  test("PersonのJSONエンコード/デコードは可逆（安全な文字のみ）") {
    forAll(safePersonGen) { person =>
      val encoded = JsonCodec.encodePerson(person)
      val decoded = JsonCodec.decodePerson(encoded)
      decoded shouldBe Some(person)
    }
  }

  // ============================================
  // 7. モノイドのプロパティ
  // ============================================
  
  test("Int加算モノイドの結合律") {
    import Monoid.given
    forAll { (a: Int, b: Int, c: Int) =>
      val m = summon[Monoid[Int]]
      m.combine(m.combine(a, b), c) shouldBe m.combine(a, m.combine(b, c))
    }
  }
  
  test("Int加算モノイドの単位元") {
    import Monoid.given
    forAll { (a: Int) =>
      val m = summon[Monoid[Int]]
      m.combine(a, m.empty) shouldBe a
      m.combine(m.empty, a) shouldBe a
    }
  }
  
  test("String連結モノイドの結合律") {
    import Monoid.given
    forAll { (a: String, b: String, c: String) =>
      val m = summon[Monoid[String]]
      m.combine(m.combine(a, b), c) shouldBe m.combine(a, m.combine(b, c))
    }
  }
  
  test("String連結モノイドの単位元") {
    import Monoid.given
    forAll { (a: String) =>
      val m = summon[Monoid[String]]
      m.combine(a, m.empty) shouldBe a
      m.combine(m.empty, a) shouldBe a
    }
  }
  
  test("List連結モノイドの結合律") {
    import Monoid.given
    forAll { (a: List[Int], b: List[Int], c: List[Int]) =>
      val m = summon[Monoid[List[Int]]]
      m.combine(m.combine(a, b), c) shouldBe m.combine(a, m.combine(b, c))
    }
  }
  
  test("List連結モノイドの単位元") {
    import Monoid.given
    forAll { (a: List[Int]) =>
      val m = summon[Monoid[List[Int]]]
      m.combine(a, m.empty) shouldBe a
      m.combine(m.empty, a) shouldBe a
    }
  }
  
  test("Monoid.foldは正しく動作する") {
    import Monoid.given
    forAll { (nums: List[Int]) =>
      Monoid.fold(nums) shouldBe nums.sum
    }
  }

  // ============================================
  // 8. コレクション操作のプロパティ
  // ============================================
  
  test("reverseは対合（involutory）") {
    forAll { (list: List[Int]) =>
      CollectionOps.reverse(CollectionOps.reverse(list)) shouldBe list
    }
  }
  
  test("reverseは長さを保存する") {
    forAll { (list: List[Int]) =>
      CollectionOps.reverse(list).length shouldBe list.length
    }
  }
  
  test("concatの結合律") {
    forAll { (a: List[Int], b: List[Int], c: List[Int]) =>
      CollectionOps.concat(CollectionOps.concat(a, b), c) shouldBe 
        CollectionOps.concat(a, CollectionOps.concat(b, c))
    }
  }
  
  test("concatの長さは入力の長さの合計") {
    forAll { (a: List[Int], b: List[Int]) =>
      CollectionOps.concat(a, b).length shouldBe (a.length + b.length)
    }
  }
  
  test("distinctは冪等") {
    forAll { (list: List[Int]) =>
      CollectionOps.distinct(CollectionOps.distinct(list)) shouldBe 
        CollectionOps.distinct(list)
    }
  }
  
  test("distinctの結果はすべてユニーク") {
    forAll { (list: List[Int]) =>
      val result = CollectionOps.distinct(list)
      result.toSet.size shouldBe result.length
    }
  }
  
  test("filterは長さを減らすか維持する") {
    forAll { (list: List[Int]) =>
      CollectionOps.filter(list)(_ > 0).length should be <= list.length
    }
  }
  
  test("filter(常にtrue)は元のリストと同じ") {
    forAll { (list: List[Int]) =>
      CollectionOps.filter(list)(_ => true) shouldBe list
    }
  }
  
  test("filter(常にfalse)は空リスト") {
    forAll { (list: List[Int]) =>
      CollectionOps.filter(list)(_ => false) shouldBe List.empty
    }
  }
  
  test("mapは長さを保存する") {
    forAll { (list: List[Int]) =>
      CollectionOps.map(list)(_ * 2).length shouldBe list.length
    }
  }
  
  test("map(identity)は元のリストと同じ") {
    forAll { (list: List[Int]) =>
      CollectionOps.map(list)(identity) shouldBe list
    }
  }
  
  test("map(f).map(g) == map(f andThen g)") {
    val f: Int => Int = _ + 1
    val g: Int => Int = _ * 2
    forAll { (list: List[Int]) =>
      CollectionOps.map(CollectionOps.map(list)(f))(g) shouldBe 
        CollectionOps.map(list)(f andThen g)
    }
  }

  // ============================================
  // 9. オラクルテスト（参照実装との比較）
  // ============================================
  
  test("sortNumbersは標準ライブラリのsortと同じ結果") {
    forAll { (nums: List[Int]) =>
      NumberOperations.sortNumbers(nums) shouldBe nums.sorted
    }
  }
  
  test("distinctは標準ライブラリのdistinctと同じ結果") {
    forAll { (list: List[Int]) =>
      CollectionOps.distinct(list) shouldBe list.distinct
    }
  }
  
  test("reverseは標準ライブラリのreverseと同じ結果") {
    forAll { (list: List[Int]) =>
      CollectionOps.reverse(list) shouldBe list.reverse
    }
  }

  // ============================================
  // 10. バリデーションのプロパティ
  // ============================================
  
  val validEmailGen: Gen[String] = for
    local <- Gen.alphaNumStr.suchThat(_.nonEmpty)
    domain <- Gen.alphaNumStr.suchThat(_.nonEmpty)
    tld <- Gen.oneOf("com", "org", "net", "io", "jp")
  yield s"$local@$domain.$tld"
  
  test("生成された有効なメールアドレスはバリデーションを通過する") {
    forAll(validEmailGen) { email =>
      Validation.isValidEmail(email) shouldBe true
    }
  }
  
  val validPhoneGen: Gen[String] = for
    length <- Gen.chooseNum(10, 15)
    digits <- Gen.listOfN(length, Gen.numChar)
  yield digits.mkString
  
  test("生成された有効な電話番号はバリデーションを通過する") {
    forAll(validPhoneGen) { phone =>
      Validation.isValidPhoneNumber(phone) shouldBe true
    }
  }
  
  val validProductIdGen: Gen[String] = 
    Gen.listOfN(5, Gen.numChar).map(digits => "PROD-" + digits.mkString)
  
  test("生成された有効な商品IDはバリデーションを通過する") {
    forAll(validProductIdGen) { id =>
      Validation.isValidProductId(id) shouldBe true
    }
  }
  
  val validOrderIdGen: Gen[String] = 
    Gen.listOfN(8, Gen.numChar).map(digits => "ORD-" + digits.mkString)
  
  test("生成された有効な注文IDはバリデーションを通過する") {
    forAll(validOrderIdGen) { id =>
      Validation.isValidOrderId(id) shouldBe true
    }
  }
