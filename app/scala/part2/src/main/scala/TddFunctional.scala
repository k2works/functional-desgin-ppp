/**
 * 第6章: テスト駆動開発と関数型プログラミング
 * 
 * TDD の Red-Green-Refactor サイクルを関数型スタイルで実践します。
 * 純粋関数と不変データ構造を活用したテスト駆動開発の例を示します。
 */
package tddfunctional

// ============================================
// 1. FizzBuzz - TDD の典型例
// ============================================

object FizzBuzz:
  /** 3で割り切れるかどうか */
  def isFizz(n: Int): Boolean = n % 3 == 0
  
  /** 5で割り切れるかどうか */
  def isBuzz(n: Int): Boolean = n % 5 == 0
  
  /** 15で割り切れるかどうか（FizzBuzz） */
  def isFizzBuzz(n: Int): Boolean = isFizz(n) && isBuzz(n)
  
  /** FizzBuzz変換 */
  def fizzbuzz(n: Int): String =
    if isFizzBuzz(n) then "FizzBuzz"
    else if isFizz(n) then "Fizz"
    else if isBuzz(n) then "Buzz"
    else n.toString
  
  /** 1からnまでのFizzBuzz列を生成 */
  def fizzbuzzSequence(n: Int): List[String] =
    (1 to n).map(fizzbuzz).toList

// ============================================
// 2. ローマ数字変換
// ============================================

object RomanNumerals:
  /** ローマ数字の対応表（大きい順） */
  private val romanNumerals: List[(Int, String)] = List(
    1000 -> "M",  900 -> "CM", 500 -> "D", 400 -> "CD",
    100 -> "C",   90 -> "XC",  50 -> "L",  40 -> "XL",
    10 -> "X",    9 -> "IX",   5 -> "V",   4 -> "IV",
    1 -> "I"
  )
  
  /** 整数をローマ数字に変換 */
  def toRoman(n: Int): String =
    require(n > 0 && n <= 3999, s"n must be between 1 and 3999, but was $n")
    
    @annotation.tailrec
    def loop(remaining: Int, result: StringBuilder): String =
      if remaining == 0 then result.toString
      else
        val (value, numeral) = romanNumerals.find(_._1 <= remaining).get
        loop(remaining - value, result.append(numeral))
    
    loop(n, new StringBuilder)
  
  /** ローマ数字を整数に変換 */
  def fromRoman(roman: String): Int =
    require(roman.nonEmpty, "Roman numeral cannot be empty")
    
    val romanToInt = Map(
      'I' -> 1, 'V' -> 5, 'X' -> 10, 'L' -> 50,
      'C' -> 100, 'D' -> 500, 'M' -> 1000
    )
    
    val values = roman.map(romanToInt)
    values.zipAll(values.tail, 0, 0).foldLeft(0) { case (acc, (curr, next)) =>
      if curr < next then acc - curr else acc + curr
    }

// ============================================
// 3. ボウリングスコア計算
// ============================================

object Bowling:
  /** フレームがストライクかどうか */
  def isStrike(rolls: List[Int]): Boolean = 
    rolls.headOption.contains(10)
  
  /** フレームがスペアかどうか */
  def isSpare(rolls: List[Int]): Boolean = 
    rolls.length >= 2 && rolls.take(2).sum == 10 && !isStrike(rolls)
  
  /** ストライクボーナス（次の2投の合計） */
  def strikeBonus(remaining: List[Int]): Int = 
    remaining.take(2).sum
  
  /** スペアボーナス（次の1投） */
  def spareBonus(remaining: List[Int]): Int = 
    remaining.headOption.getOrElse(0)
  
  /** フレームの基本スコア */
  def frameScore(rolls: List[Int]): Int = 
    rolls.take(2).sum
  
  /** ボウリングスコアを計算 */
  def score(rolls: List[Int]): Int =
    @annotation.tailrec
    def loop(remainingRolls: List[Int], frame: Int, total: Int): Int =
      if frame > 10 || remainingRolls.isEmpty then total
      else if isStrike(remainingRolls) then
        val frameTotal = 10 + strikeBonus(remainingRolls.tail)
        loop(remainingRolls.tail, frame + 1, total + frameTotal)
      else if isSpare(remainingRolls) then
        val frameTotal = 10 + spareBonus(remainingRolls.drop(2))
        loop(remainingRolls.drop(2), frame + 1, total + frameTotal)
      else
        val frameTotal = frameScore(remainingRolls)
        loop(remainingRolls.drop(2), frame + 1, total + frameTotal)
    
    loop(rolls, 1, 0)

// ============================================
// 4. 素数
// ============================================

object Primes:
  /** 素数判定 */
  def isPrime(n: Int): Boolean =
    if n < 2 then false
    else if n == 2 then true
    else if n % 2 == 0 then false
    else
      val sqrtN = math.sqrt(n.toDouble).toInt
      !(3 to sqrtN by 2).exists(n % _ == 0)
  
  /** n以下の素数リスト */
  def primesUpTo(n: Int): List[Int] =
    (2 to n).filter(isPrime).toList
  
  /** 素因数分解 */
  def primeFactors(n: Int): List[Int] =
    require(n > 0, "n must be positive")
    
    @annotation.tailrec
    def loop(remaining: Int, factor: Int, factors: List[Int]): List[Int] =
      if remaining == 1 then factors.reverse
      else if remaining % factor == 0 then loop(remaining / factor, factor, factor :: factors)
      else loop(remaining, factor + 1, factors)
    
    loop(n, 2, Nil)

// ============================================
// 5. スタック - 不変データ構造
// ============================================

/** 不変スタック */
case class Stack[A] private (items: List[A]):
  /** スタックが空かどうか */
  def isEmpty: Boolean = items.isEmpty
  
  /** スタックのサイズ */
  def size: Int = items.length
  
  /** 要素をプッシュ（新しいスタックを返す） */
  def push(item: A): Stack[A] = Stack(item :: items)
  
  /** 要素をポップ（値と新しいスタックのタプルを返す） */
  def pop: Option[(A, Stack[A])] =
    items match
      case head :: tail => Some((head, Stack(tail)))
      case Nil => None
  
  /** トップ要素を覗く */
  def peek: Option[A] = items.headOption
  
  /** リストに変換 */
  def toList: List[A] = items

object Stack:
  /** 空のスタックを作成 */
  def empty[A]: Stack[A] = Stack(Nil)
  
  /** 要素からスタックを作成 */
  def apply[A](items: A*): Stack[A] = Stack(items.toList)

// ============================================
// 6. 文字列電卓
// ============================================

object StringCalculator:
  /** 文字列から数値を計算 */
  def add(input: String): Int =
    if input.isEmpty then 0
    else
      val (delimiter, numbers) = parseInput(input)
      val nums = parseNumbers(numbers, delimiter)
      validateNumbers(nums)
      nums.filter(_ <= 1000).sum
  
  /** 入力をパース（区切り文字と数値文字列に分離） */
  private def parseInput(input: String): (String, String) =
    if input.startsWith("//") then
      val delimiterEnd = input.indexOf("\n")
      val delimiter = input.substring(2, delimiterEnd)
      val numbers = input.substring(delimiterEnd + 1)
      (delimiter, numbers)
    else
      (",|\n", input)
  
  /** 数値をパース */
  private def parseNumbers(numbers: String, delimiter: String): List[Int] =
    numbers.split(delimiter).filter(_.nonEmpty).map(_.toInt).toList
  
  /** 負の数をバリデート */
  private def validateNumbers(nums: List[Int]): Unit =
    val negatives = nums.filter(_ < 0)
    if negatives.nonEmpty then
      throw new IllegalArgumentException(s"negatives not allowed: ${negatives.mkString(", ")}")

// ============================================
// 7. 純粋関数による税計算
// ============================================

/** 商品 */
case class Item(name: String, price: BigDecimal)

/** 税計算結果 */
case class TaxCalculation(
  subtotal: BigDecimal,
  tax: BigDecimal,
  total: BigDecimal
)

object TaxCalculator:
  /** 税額を計算 */
  def calculateTax(amount: BigDecimal, rate: BigDecimal): BigDecimal =
    amount * rate
  
  /** 税込み合計を計算 */
  def calculateTotalWithTax(items: List[Item], taxRate: BigDecimal): TaxCalculation =
    val subtotal = items.map(_.price).sum
    val tax = calculateTax(subtotal, taxRate)
    TaxCalculation(subtotal, tax, subtotal + tax)

// ============================================
// 8. 配送料計算（リファクタリング例）
// ============================================

/** 地域 */
enum Region:
  case Local, Domestic, International

/** 注文 */
case class ShippingOrder(
  total: BigDecimal,
  weight: Double,
  region: Region
)

object ShippingCalculator:
  /** 送料無料かどうか */
  def isFreeShipping(total: BigDecimal): Boolean = total >= 10000
  
  /** 送料テーブル（地域 -> 軽量かどうか -> 送料） */
  private val shippingRates: Map[Region, Map[Boolean, Int]] = Map(
    Region.Local -> Map(true -> 300, false -> 500),
    Region.Domestic -> Map(true -> 500, false -> 800),
    Region.International -> Map(true -> 2000, false -> 3000)
  )
  
  /** 配送料を計算 */
  def calculateShipping(order: ShippingOrder): Int =
    if isFreeShipping(order.total) then 0
    else
      val isLight = order.weight < 5.0
      shippingRates.get(order.region)
        .flatMap(_.get(isLight))
        .getOrElse(500)

// ============================================
// 9. キュー - 不変データ構造
// ============================================

/** 不変キュー（2つのリストで実装） */
case class Queue[A] private (front: List[A], back: List[A]):
  /** キューが空かどうか */
  def isEmpty: Boolean = front.isEmpty && back.isEmpty
  
  /** キューのサイズ */
  def size: Int = front.length + back.length
  
  /** 要素をエンキュー（新しいキューを返す） */
  def enqueue(item: A): Queue[A] = Queue(front, item :: back)
  
  /** 要素をデキュー（値と新しいキューのタプルを返す） */
  def dequeue: Option[(A, Queue[A])] =
    front match
      case head :: tail => Some((head, Queue(tail, back)))
      case Nil =>
        back.reverse match
          case head :: tail => Some((head, Queue(tail, Nil)))
          case Nil => None
  
  /** フロント要素を覗く */
  def peek: Option[A] =
    front match
      case head :: _ => Some(head)
      case Nil => back.reverse.headOption
  
  /** リストに変換 */
  def toList: List[A] = front ++ back.reverse

object Queue:
  /** 空のキューを作成 */
  def empty[A]: Queue[A] = Queue(Nil, Nil)
  
  /** 要素からキューを作成 */
  def apply[A](items: A*): Queue[A] = Queue(items.toList, Nil)

// ============================================
// 10. 電話番号フォーマッター
// ============================================

object PhoneFormatter:
  /** 電話番号のバリデーション結果 */
  enum ValidationResult:
    case Valid(formatted: String)
    case Invalid(reason: String)
  
  /** 電話番号をフォーマット */
  def format(phone: String): ValidationResult =
    val digits = phone.filter(_.isDigit)
    
    digits.length match
      case 10 =>
        // 市外局番なし: 0XX-XXXX-XXXX 形式を想定
        val formatted = s"${digits.take(3)}-${digits.slice(3, 7)}-${digits.drop(7)}"
        ValidationResult.Valid(formatted)
      case 11 =>
        // 携帯電話: 0X0-XXXX-XXXX 形式
        val formatted = s"${digits.take(3)}-${digits.slice(3, 7)}-${digits.drop(7)}"
        ValidationResult.Valid(formatted)
      case n if n < 10 =>
        ValidationResult.Invalid(s"Too few digits: $n (minimum 10)")
      case n =>
        ValidationResult.Invalid(s"Too many digits: $n (maximum 11)")
  
  /** フォーマット済み電話番号を取得（成功時のみ） */
  def formatOrNone(phone: String): Option[String] =
    format(phone) match
      case ValidationResult.Valid(formatted) => Some(formatted)
      case ValidationResult.Invalid(_) => None

// ============================================
// 11. ワードカウンター
// ============================================

object WordCounter:
  /** 単語をカウント */
  def countWords(text: String): Map[String, Int] =
    if text.trim.isEmpty then Map.empty
    else
      text
        .toLowerCase
        .split("""[\s,.!?;:'"()\[\]{}]+""")
        .filter(_.nonEmpty)
        .groupBy(identity)
        .view
        .mapValues(_.length)
        .toMap
  
  /** 最頻出単語を取得 */
  def topWords(text: String, n: Int): List[(String, Int)] =
    countWords(text)
      .toList
      .sortBy(-_._2)
      .take(n)
  
  /** ユニーク単語数を取得 */
  def uniqueWordCount(text: String): Int =
    countWords(text).size

// ============================================
// 12. パスワードバリデーター
// ============================================

object PasswordValidator:
  /** バリデーションルール */
  type Rule = String => Option[String]
  
  /** 最小長ルール */
  def minLength(min: Int): Rule = password =>
    if password.length >= min then None
    else Some(s"Password must be at least $min characters")
  
  /** 大文字必須ルール */
  val hasUppercase: Rule = password =>
    if password.exists(_.isUpper) then None
    else Some("Password must contain at least one uppercase letter")
  
  /** 小文字必須ルール */
  val hasLowercase: Rule = password =>
    if password.exists(_.isLower) then None
    else Some("Password must contain at least one lowercase letter")
  
  /** 数字必須ルール */
  val hasDigit: Rule = password =>
    if password.exists(_.isDigit) then None
    else Some("Password must contain at least one digit")
  
  /** 特殊文字必須ルール */
  val hasSpecialChar: Rule = password =>
    val specialChars = "!@#$%^&*()_+-=[]{}|;:',.<>?/"
    if password.exists(specialChars.contains) then None
    else Some("Password must contain at least one special character")
  
  /** デフォルトルール */
  val defaultRules: List[Rule] = List(
    minLength(8),
    hasUppercase,
    hasLowercase,
    hasDigit
  )
  
  /** 厳格ルール */
  val strictRules: List[Rule] = List(
    minLength(12),
    hasUppercase,
    hasLowercase,
    hasDigit,
    hasSpecialChar
  )
  
  /** パスワードをバリデート */
  def validate(password: String, rules: List[Rule] = defaultRules): Either[List[String], String] =
    val errors = rules.flatMap(_(password))
    if errors.isEmpty then Right(password)
    else Left(errors)
  
  /** パスワードが有効かどうか */
  def isValid(password: String, rules: List[Rule] = defaultRules): Boolean =
    validate(password, rules).isRight
