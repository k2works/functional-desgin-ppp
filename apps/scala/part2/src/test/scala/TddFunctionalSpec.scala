/**
 * 第6章: テスト駆動開発と関数型プログラミング - テストコード
 * 
 * TDD の Red-Green-Refactor サイクルに従ったテストスイートです。
 */
package tddfunctional

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class TddFunctionalSpec extends AnyFunSuite with Matchers:

  // ============================================
  // 1. FizzBuzz
  // ============================================
  
  test("FizzBuzz: 1は\"1\"を返す") {
    FizzBuzz.fizzbuzz(1) shouldBe "1"
  }
  
  test("FizzBuzz: 2は\"2\"を返す") {
    FizzBuzz.fizzbuzz(2) shouldBe "2"
  }
  
  test("FizzBuzz: 3は\"Fizz\"を返す") {
    FizzBuzz.fizzbuzz(3) shouldBe "Fizz"
  }
  
  test("FizzBuzz: 5は\"Buzz\"を返す") {
    FizzBuzz.fizzbuzz(5) shouldBe "Buzz"
  }
  
  test("FizzBuzz: 6は\"Fizz\"を返す（3の倍数）") {
    FizzBuzz.fizzbuzz(6) shouldBe "Fizz"
  }
  
  test("FizzBuzz: 10は\"Buzz\"を返す（5の倍数）") {
    FizzBuzz.fizzbuzz(10) shouldBe "Buzz"
  }
  
  test("FizzBuzz: 15は\"FizzBuzz\"を返す") {
    FizzBuzz.fizzbuzz(15) shouldBe "FizzBuzz"
  }
  
  test("FizzBuzz: 30は\"FizzBuzz\"を返す（15の倍数）") {
    FizzBuzz.fizzbuzz(30) shouldBe "FizzBuzz"
  }
  
  test("FizzBuzz: isFizzは3の倍数を判定する") {
    FizzBuzz.isFizz(3) shouldBe true
    FizzBuzz.isFizz(6) shouldBe true
    FizzBuzz.isFizz(4) shouldBe false
  }
  
  test("FizzBuzz: isBuzzは5の倍数を判定する") {
    FizzBuzz.isBuzz(5) shouldBe true
    FizzBuzz.isBuzz(10) shouldBe true
    FizzBuzz.isBuzz(7) shouldBe false
  }
  
  test("FizzBuzz: fizzbuzzSequenceは1からnまでのFizzBuzz列を生成する") {
    FizzBuzz.fizzbuzzSequence(15) shouldBe List(
      "1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz",
      "11", "Fizz", "13", "14", "FizzBuzz"
    )
  }

  // ============================================
  // 2. ローマ数字変換
  // ============================================
  
  test("ローマ数字: 1はIを返す") {
    RomanNumerals.toRoman(1) shouldBe "I"
  }
  
  test("ローマ数字: 3はIIIを返す") {
    RomanNumerals.toRoman(3) shouldBe "III"
  }
  
  test("ローマ数字: 4はIVを返す") {
    RomanNumerals.toRoman(4) shouldBe "IV"
  }
  
  test("ローマ数字: 5はVを返す") {
    RomanNumerals.toRoman(5) shouldBe "V"
  }
  
  test("ローマ数字: 9はIXを返す") {
    RomanNumerals.toRoman(9) shouldBe "IX"
  }
  
  test("ローマ数字: 10はXを返す") {
    RomanNumerals.toRoman(10) shouldBe "X"
  }
  
  test("ローマ数字: 40はXLを返す") {
    RomanNumerals.toRoman(40) shouldBe "XL"
  }
  
  test("ローマ数字: 50はLを返す") {
    RomanNumerals.toRoman(50) shouldBe "L"
  }
  
  test("ローマ数字: 90はXCを返す") {
    RomanNumerals.toRoman(90) shouldBe "XC"
  }
  
  test("ローマ数字: 100はCを返す") {
    RomanNumerals.toRoman(100) shouldBe "C"
  }
  
  test("ローマ数字: 400はCDを返す") {
    RomanNumerals.toRoman(400) shouldBe "CD"
  }
  
  test("ローマ数字: 500はDを返す") {
    RomanNumerals.toRoman(500) shouldBe "D"
  }
  
  test("ローマ数字: 900はCMを返す") {
    RomanNumerals.toRoman(900) shouldBe "CM"
  }
  
  test("ローマ数字: 1000はMを返す") {
    RomanNumerals.toRoman(1000) shouldBe "M"
  }
  
  test("ローマ数字: 1994はMCMXCIVを返す") {
    RomanNumerals.toRoman(1994) shouldBe "MCMXCIV"
  }
  
  test("ローマ数字: 3999はMMMCMXCIXを返す") {
    RomanNumerals.toRoman(3999) shouldBe "MMMCMXCIX"
  }
  
  test("ローマ数字: 範囲外の値は例外をスローする") {
    assertThrows[IllegalArgumentException] {
      RomanNumerals.toRoman(0)
    }
    assertThrows[IllegalArgumentException] {
      RomanNumerals.toRoman(4000)
    }
  }
  
  test("ローマ数字: fromRomanはローマ数字を整数に変換する") {
    RomanNumerals.fromRoman("I") shouldBe 1
    RomanNumerals.fromRoman("IV") shouldBe 4
    RomanNumerals.fromRoman("IX") shouldBe 9
    RomanNumerals.fromRoman("MCMXCIV") shouldBe 1994
  }
  
  test("ローマ数字: toRomanとfromRomanは逆関数") {
    for n <- 1 to 3999 do
      RomanNumerals.fromRoman(RomanNumerals.toRoman(n)) shouldBe n
  }

  // ============================================
  // 3. ボウリングスコア計算
  // ============================================
  
  test("ボウリング: ガタースコアは0") {
    Bowling.score(List.fill(20)(0)) shouldBe 0
  }
  
  test("ボウリング: すべて1ピンは20点") {
    Bowling.score(List.fill(20)(1)) shouldBe 20
  }
  
  test("ボウリング: スペアの後の投球はボーナス") {
    // 5 + 5 (spare) + 3 (bonus) + 3 + 0 + ... = 16
    Bowling.score(List(5, 5, 3, 0) ++ List.fill(16)(0)) shouldBe 16
  }
  
  test("ボウリング: ストライクの後の2投はボーナス") {
    // 10 (strike) + 3 + 4 (bonus) + 3 + 4 + ... = 24
    Bowling.score(List(10, 3, 4) ++ List.fill(16)(0)) shouldBe 24
  }
  
  test("ボウリング: パーフェクトゲームは300点") {
    // 12回のストライク
    Bowling.score(List.fill(12)(10)) shouldBe 300
  }
  
  test("ボウリング: 連続スペア") {
    // 5 + 5 (spare) + 5 (bonus) + 5 (spare) + 3 (bonus) + 3 + ... = 10 + 5 + 10 + 3 + 3 = 31
    Bowling.score(List(5, 5, 5, 5, 3, 0) ++ List.fill(14)(0)) shouldBe 31
  }
  
  test("ボウリング: isStrikeはストライクを判定する") {
    Bowling.isStrike(List(10, 0)) shouldBe true
    Bowling.isStrike(List(5, 5)) shouldBe false
    Bowling.isStrike(List(9, 0)) shouldBe false
  }
  
  test("ボウリング: isSpareはスペアを判定する") {
    Bowling.isSpare(List(5, 5)) shouldBe true
    Bowling.isSpare(List(10, 0)) shouldBe false
    Bowling.isSpare(List(3, 4)) shouldBe false
  }

  // ============================================
  // 4. 素数
  // ============================================
  
  test("素数: isPrimeは素数を正しく判定する") {
    Primes.isPrime(0) shouldBe false
    Primes.isPrime(1) shouldBe false
    Primes.isPrime(2) shouldBe true
    Primes.isPrime(3) shouldBe true
    Primes.isPrime(4) shouldBe false
    Primes.isPrime(5) shouldBe true
    Primes.isPrime(6) shouldBe false
    Primes.isPrime(7) shouldBe true
    Primes.isPrime(97) shouldBe true
    Primes.isPrime(100) shouldBe false
  }
  
  test("素数: primesUpToは正しい素数リストを返す") {
    Primes.primesUpTo(20) shouldBe List(2, 3, 5, 7, 11, 13, 17, 19)
  }
  
  test("素数: primesUpToは空リストを返す（2未満の場合）") {
    Primes.primesUpTo(1) shouldBe List.empty
  }
  
  test("素数: primeFactorsは素因数分解を返す") {
    Primes.primeFactors(1) shouldBe List.empty
    Primes.primeFactors(2) shouldBe List(2)
    Primes.primeFactors(4) shouldBe List(2, 2)
    Primes.primeFactors(6) shouldBe List(2, 3)
    Primes.primeFactors(24) shouldBe List(2, 2, 2, 3)
    Primes.primeFactors(100) shouldBe List(2, 2, 5, 5)
  }
  
  test("素数: primeFactorsの積は元の数に等しい") {
    for n <- 2 to 100 do
      Primes.primeFactors(n).product shouldBe n
  }

  // ============================================
  // 5. スタック
  // ============================================
  
  test("スタック: 空のスタックはisEmptyがtrue") {
    Stack.empty[Int].isEmpty shouldBe true
  }
  
  test("スタック: 要素をpushするとisEmptyがfalse") {
    Stack.empty[Int].push(1).isEmpty shouldBe false
  }
  
  test("スタック: pushした要素をpeekで見られる") {
    Stack.empty[Int].push(1).peek shouldBe Some(1)
  }
  
  test("スタック: LIFO順序で動作する") {
    val stack = Stack.empty[String]
      .push("a")
      .push("b")
      .push("c")
    
    val Some((v1, s1)) = stack.pop: @unchecked
    val Some((v2, s2)) = s1.pop: @unchecked
    val Some((v3, s3)) = s2.pop: @unchecked
    
    v1 shouldBe "c"
    v2 shouldBe "b"
    v3 shouldBe "a"
    s3.isEmpty shouldBe true
  }
  
  test("スタック: 空のスタックからpopするとNone") {
    Stack.empty[Int].pop shouldBe None
  }
  
  test("スタック: sizeは正しい要素数を返す") {
    Stack.empty[Int].size shouldBe 0
    Stack.empty[Int].push(1).size shouldBe 1
    Stack.empty[Int].push(1).push(2).push(3).size shouldBe 3
  }
  
  test("スタック: toListはスタックの内容をリストに変換する") {
    Stack(1, 2, 3).toList shouldBe List(1, 2, 3)
  }

  // ============================================
  // 6. 文字列電卓
  // ============================================
  
  test("文字列電卓: 空文字列は0を返す") {
    StringCalculator.add("") shouldBe 0
  }
  
  test("文字列電卓: 単一の数値はその値を返す") {
    StringCalculator.add("5") shouldBe 5
  }
  
  test("文字列電卓: カンマ区切りの数値を合計する") {
    StringCalculator.add("1,2,3") shouldBe 6
  }
  
  test("文字列電卓: 改行区切りも処理する") {
    StringCalculator.add("1\n2,3") shouldBe 6
  }
  
  test("文字列電卓: カスタム区切り文字を使用できる") {
    StringCalculator.add("//;\n1;2") shouldBe 3
  }
  
  test("文字列電卓: 負の数は例外をスローする") {
    val exception = intercept[IllegalArgumentException] {
      StringCalculator.add("1,-2,3")
    }
    exception.getMessage should include("-2")
  }
  
  test("文字列電卓: 複数の負の数はすべてエラーメッセージに含まれる") {
    val exception = intercept[IllegalArgumentException] {
      StringCalculator.add("1,-2,-3,4")
    }
    exception.getMessage should include("-2")
    exception.getMessage should include("-3")
  }
  
  test("文字列電卓: 1000より大きい数は無視する") {
    StringCalculator.add("2,1001") shouldBe 2
    StringCalculator.add("1000,1001") shouldBe 1000
  }

  // ============================================
  // 7. 税計算
  // ============================================
  
  test("税計算: calculateTaxは税額を計算する") {
    TaxCalculator.calculateTax(BigDecimal(1000), BigDecimal(0.1)) shouldBe BigDecimal(100)
  }
  
  test("税計算: calculateTotalWithTaxは税込み総額を計算する") {
    val items = List(
      Item("商品A", BigDecimal(1000)),
      Item("商品B", BigDecimal(2000))
    )
    val result = TaxCalculator.calculateTotalWithTax(items, BigDecimal(0.1))
    
    result.subtotal shouldBe BigDecimal(3000)
    result.tax shouldBe BigDecimal(300)
    result.total shouldBe BigDecimal(3300)
  }
  
  test("税計算: 空のリストは0を返す") {
    val result = TaxCalculator.calculateTotalWithTax(List.empty, BigDecimal(0.1))
    result.subtotal shouldBe BigDecimal(0)
    result.tax shouldBe BigDecimal(0)
    result.total shouldBe BigDecimal(0)
  }

  // ============================================
  // 8. 配送料計算
  // ============================================
  
  test("配送料: 10000円以上は送料無料") {
    val order = ShippingOrder(BigDecimal(10000), 1.0, Region.Domestic)
    ShippingCalculator.calculateShipping(order) shouldBe 0
  }
  
  test("配送料: ローカル地域の軽量荷物は300円") {
    val order = ShippingOrder(BigDecimal(5000), 3.0, Region.Local)
    ShippingCalculator.calculateShipping(order) shouldBe 300
  }
  
  test("配送料: ローカル地域の重量荷物は500円") {
    val order = ShippingOrder(BigDecimal(5000), 6.0, Region.Local)
    ShippingCalculator.calculateShipping(order) shouldBe 500
  }
  
  test("配送料: 国内の軽量荷物は500円") {
    val order = ShippingOrder(BigDecimal(5000), 3.0, Region.Domestic)
    ShippingCalculator.calculateShipping(order) shouldBe 500
  }
  
  test("配送料: 国内の重量荷物は800円") {
    val order = ShippingOrder(BigDecimal(5000), 6.0, Region.Domestic)
    ShippingCalculator.calculateShipping(order) shouldBe 800
  }
  
  test("配送料: 海外の軽量荷物は2000円") {
    val order = ShippingOrder(BigDecimal(5000), 3.0, Region.International)
    ShippingCalculator.calculateShipping(order) shouldBe 2000
  }
  
  test("配送料: 海外の重量荷物は3000円") {
    val order = ShippingOrder(BigDecimal(5000), 6.0, Region.International)
    ShippingCalculator.calculateShipping(order) shouldBe 3000
  }
  
  test("配送料: isFreeShippingは10000円以上でtrue") {
    ShippingCalculator.isFreeShipping(BigDecimal(9999)) shouldBe false
    ShippingCalculator.isFreeShipping(BigDecimal(10000)) shouldBe true
    ShippingCalculator.isFreeShipping(BigDecimal(10001)) shouldBe true
  }

  // ============================================
  // 9. キュー
  // ============================================
  
  test("キュー: 空のキューはisEmptyがtrue") {
    Queue.empty[Int].isEmpty shouldBe true
  }
  
  test("キュー: 要素をenqueueするとisEmptyがfalse") {
    Queue.empty[Int].enqueue(1).isEmpty shouldBe false
  }
  
  test("キュー: FIFO順序で動作する") {
    val queue = Queue.empty[String]
      .enqueue("a")
      .enqueue("b")
      .enqueue("c")
    
    val Some((v1, q1)) = queue.dequeue: @unchecked
    val Some((v2, q2)) = q1.dequeue: @unchecked
    val Some((v3, q3)) = q2.dequeue: @unchecked
    
    v1 shouldBe "a"
    v2 shouldBe "b"
    v3 shouldBe "c"
    q3.isEmpty shouldBe true
  }
  
  test("キュー: 空のキューからdequeueするとNone") {
    Queue.empty[Int].dequeue shouldBe None
  }
  
  test("キュー: peekはフロント要素を返す") {
    val queue = Queue.empty[Int].enqueue(1).enqueue(2)
    queue.peek shouldBe Some(1)
  }
  
  test("キュー: sizeは正しい要素数を返す") {
    Queue.empty[Int].size shouldBe 0
    Queue.empty[Int].enqueue(1).size shouldBe 1
    Queue.empty[Int].enqueue(1).enqueue(2).enqueue(3).size shouldBe 3
  }
  
  test("キュー: toListはキューの内容をリストに変換する") {
    Queue(1, 2, 3).toList shouldBe List(1, 2, 3)
  }

  // ============================================
  // 10. 電話番号フォーマッター
  // ============================================
  
  test("電話番号: 10桁はフォーマットされる") {
    PhoneFormatter.format("0312345678") shouldBe 
      PhoneFormatter.ValidationResult.Valid("031-2345-678")
  }
  
  test("電話番号: 11桁（携帯）はフォーマットされる") {
    PhoneFormatter.format("09012345678") shouldBe 
      PhoneFormatter.ValidationResult.Valid("090-1234-5678")
  }
  
  test("電話番号: ハイフン付きでも正しくフォーマットされる") {
    PhoneFormatter.format("090-1234-5678") shouldBe 
      PhoneFormatter.ValidationResult.Valid("090-1234-5678")
  }
  
  test("電話番号: 9桁未満はInvalid") {
    PhoneFormatter.format("123456789") match
      case PhoneFormatter.ValidationResult.Invalid(reason) =>
        reason should include("Too few digits")
      case _ => fail("Should be Invalid")
  }
  
  test("電話番号: 12桁以上はInvalid") {
    PhoneFormatter.format("123456789012") match
      case PhoneFormatter.ValidationResult.Invalid(reason) =>
        reason should include("Too many digits")
      case _ => fail("Should be Invalid")
  }
  
  test("電話番号: formatOrNoneは成功時にSomeを返す") {
    PhoneFormatter.formatOrNone("09012345678") shouldBe Some("090-1234-5678")
  }
  
  test("電話番号: formatOrNoneは失敗時にNoneを返す") {
    PhoneFormatter.formatOrNone("12345") shouldBe None
  }

  // ============================================
  // 11. ワードカウンター
  // ============================================
  
  test("ワードカウンター: 空文字列は空マップを返す") {
    WordCounter.countWords("") shouldBe Map.empty
  }
  
  test("ワードカウンター: 単語をカウントする") {
    WordCounter.countWords("hello world hello") shouldBe Map("hello" -> 2, "world" -> 1)
  }
  
  test("ワードカウンター: 大文字小文字を区別しない") {
    WordCounter.countWords("Hello HELLO hello") shouldBe Map("hello" -> 3)
  }
  
  test("ワードカウンター: 句読点を無視する") {
    WordCounter.countWords("hello, world! hello.") shouldBe Map("hello" -> 2, "world" -> 1)
  }
  
  test("ワードカウンター: topWordsは最頻出単語を返す") {
    val text = "apple banana apple cherry apple banana"
    WordCounter.topWords(text, 2) shouldBe List("apple" -> 3, "banana" -> 2)
  }
  
  test("ワードカウンター: uniqueWordCountはユニーク単語数を返す") {
    WordCounter.uniqueWordCount("apple banana apple") shouldBe 2
  }

  // ============================================
  // 12. パスワードバリデーター
  // ============================================
  
  test("パスワード: 有効なパスワードはRightを返す") {
    PasswordValidator.validate("Password1") shouldBe Right("Password1")
  }
  
  test("パスワード: 短すぎるパスワードはエラー") {
    val result = PasswordValidator.validate("Pass1")
    result.isLeft shouldBe true
    result.left.get should contain("Password must be at least 8 characters")
  }
  
  test("パスワード: 大文字がないパスワードはエラー") {
    val result = PasswordValidator.validate("password1")
    result.isLeft shouldBe true
    result.left.get should contain("Password must contain at least one uppercase letter")
  }
  
  test("パスワード: 小文字がないパスワードはエラー") {
    val result = PasswordValidator.validate("PASSWORD1")
    result.isLeft shouldBe true
    result.left.get should contain("Password must contain at least one lowercase letter")
  }
  
  test("パスワード: 数字がないパスワードはエラー") {
    val result = PasswordValidator.validate("Password")
    result.isLeft shouldBe true
    result.left.get should contain("Password must contain at least one digit")
  }
  
  test("パスワード: 複数のエラーは累積される") {
    val result = PasswordValidator.validate("abc")
    result.isLeft shouldBe true
    result.left.get.length should be >= 3
  }
  
  test("パスワード: strictRulesは特殊文字を要求する") {
    val result = PasswordValidator.validate("Password1234", PasswordValidator.strictRules)
    result.isLeft shouldBe true
    result.left.get should contain("Password must contain at least one special character")
  }
  
  test("パスワード: strictRulesで有効なパスワード") {
    val result = PasswordValidator.validate("Password123!", PasswordValidator.strictRules)
    result shouldBe Right("Password123!")
  }
  
  test("パスワード: isValidはブール値を返す") {
    PasswordValidator.isValid("Password1") shouldBe true
    PasswordValidator.isValid("abc") shouldBe false
  }
