/**
 * 第5章: プロパティベーステスト
 * 
 * Scala では ScalaCheck ライブラリを使ってプロパティベーステストを実装します。
 * ScalaCheck は Haskell の QuickCheck にインスパイアされたライブラリです。
 */
package propertybasedtesting

// ============================================
// 1. 基本的な関数（テスト対象）
// ============================================

object StringOperations:
  /** 文字列を反転 */
  def reverseString(s: String): String = s.reverse
  
  /** 文字列を大文字に変換 */
  def toUpperCase(s: String): String = s.toUpperCase
  
  /** 文字列を小文字に変換 */
  def toLowerCase(s: String): String = s.toLowerCase

object NumberOperations:
  /** 数値リストをソート */
  def sortNumbers(nums: List[Int]): List[Int] = nums.sorted
  
  /** 絶対値（バグのない実装） */
  def abs(n: Int): Int = math.abs(n)
  
  /** 絶対値（Long版、オーバーフロー対策） */
  def absLong(n: Long): Long = math.abs(n)
  
  /** 最大値を取得 */
  def maxOption(nums: List[Int]): Option[Int] = 
    if nums.isEmpty then None else Some(nums.max)
  
  /** 最小値を取得 */
  def minOption(nums: List[Int]): Option[Int] =
    if nums.isEmpty then None else Some(nums.min)

// ============================================
// 2. ドメインモデル
// ============================================

/** 会員ランク */
enum Membership:
  case Bronze, Silver, Gold, Platinum

/** 人物データ */
case class Person(
  name: String,
  age: Int,
  membership: Membership
)

/** 商品データ */
case class Product(
  productId: String,
  name: String,
  price: BigDecimal,
  quantity: Int
)

/** 注文データ */
case class Order(
  orderId: String,
  items: List[OrderItem],
  customerId: String
)

case class OrderItem(
  product: Product,
  quantity: Int
)

// ============================================
// 3. ビジネスロジック
// ============================================

object PricingLogic:
  /** 割引率を適用して価格を計算 */
  def calculateDiscount(price: BigDecimal, rate: Double): BigDecimal =
    require(rate >= 0 && rate <= 1, "rate must be between 0 and 1")
    require(price >= 0, "price must be non-negative")
    price * BigDecimal(1 - rate)
  
  /** 会員ランクに基づく割引率 */
  def membershipDiscount(membership: Membership): Double =
    membership match
      case Membership.Bronze   => 0.0
      case Membership.Silver   => 0.05
      case Membership.Gold     => 0.10
      case Membership.Platinum => 0.15
  
  /** 注文合計を計算 */
  def calculateOrderTotal(order: Order): BigDecimal =
    order.items.foldLeft(BigDecimal(0)) { (acc, item) =>
      acc + (item.product.price * item.quantity)
    }
  
  /** 最終価格を計算（会員割引適用） */
  def calculateFinalPrice(order: Order, membership: Membership): BigDecimal =
    val total = calculateOrderTotal(order)
    val discountRate = membershipDiscount(membership)
    calculateDiscount(total, discountRate)

// ============================================
// 4. エンコード/デコード（ラウンドトリップ）
// ============================================

object RunLengthEncoding:
  /** ランレングス符号化 */
  def encode(s: String): List[(Char, Int)] =
    if s.isEmpty then List.empty
    else
      s.foldLeft(List.empty[(Char, Int)]) { (acc, char) =>
        acc match
          case Nil => List((char, 1))
          case (lastChar, count) :: rest if lastChar == char =>
            (lastChar, count + 1) :: rest
          case _ =>
            (char, 1) :: acc
      }.reverse
  
  /** ランレングス復号化 */
  def decode(encoded: List[(Char, Int)]): String =
    encoded.map { case (char, count) => char.toString * count }.mkString

object Base64Codec:
  import java.util.Base64
  import java.nio.charset.StandardCharsets
  
  /** Base64エンコード */
  def encode(s: String): String =
    Base64.getEncoder.encodeToString(s.getBytes(StandardCharsets.UTF_8))
  
  /** Base64デコード */
  def decode(encoded: String): String =
    new String(Base64.getDecoder.decode(encoded), StandardCharsets.UTF_8)

object JsonCodec:
  /** シンプルなJSON風エンコード（Person用） */
  def encodePerson(person: Person): String =
    s"""{"name":"${escapeJson(person.name)}","age":${person.age},"membership":"${person.membership}"}"""
  
  /** JSONデコード（Person用） */
  def decodePerson(json: String): Option[Person] =
    val namePattern = """"name":"([^"]*)"""".r
    val agePattern = """"age":(\d+)""".r
    val membershipPattern = """"membership":"(\w+)"""".r
    
    for
      nameMatch <- namePattern.findFirstMatchIn(json)
      ageMatch <- agePattern.findFirstMatchIn(json)
      membershipMatch <- membershipPattern.findFirstMatchIn(json)
      membership <- parseMembership(membershipMatch.group(1))
    yield Person(
      unescapeJson(nameMatch.group(1)),
      ageMatch.group(1).toInt,
      membership
    )
  
  private def escapeJson(s: String): String =
    s.replace("\\", "\\\\")
     .replace("\"", "\\\"")
     .replace("\n", "\\n")
     .replace("\r", "\\r")
     .replace("\t", "\\t")
  
  private def unescapeJson(s: String): String =
    s.replace("\\t", "\t")
     .replace("\\r", "\r")
     .replace("\\n", "\n")
     .replace("\\\"", "\"")
     .replace("\\\\", "\\")
  
  private def parseMembership(s: String): Option[Membership] =
    s match
      case "Bronze"   => Some(Membership.Bronze)
      case "Silver"   => Some(Membership.Silver)
      case "Gold"     => Some(Membership.Gold)
      case "Platinum" => Some(Membership.Platinum)
      case _          => None

// ============================================
// 5. 代数的構造（モノイド）
// ============================================

/** モノイド型クラス */
trait Monoid[A]:
  def empty: A
  def combine(x: A, y: A): A

object Monoid:
  /** Int加算モノイド */
  given intAddition: Monoid[Int] with
    def empty: Int = 0
    def combine(x: Int, y: Int): Int = x + y
  
  /** Int乗算モノイド */
  val intMultiplication: Monoid[Int] = new Monoid[Int]:
    def empty: Int = 1
    def combine(x: Int, y: Int): Int = x * y
  
  /** 文字列連結モノイド */
  given stringConcat: Monoid[String] with
    def empty: String = ""
    def combine(x: String, y: String): String = x + y
  
  /** リスト連結モノイド */
  given listConcat[A]: Monoid[List[A]] with
    def empty: List[A] = List.empty
    def combine(x: List[A], y: List[A]): List[A] = x ++ y
  
  /** モノイドを使った畳み込み */
  def fold[A](items: List[A])(using m: Monoid[A]): A =
    items.foldLeft(m.empty)(m.combine)

// ============================================
// 6. カスタムジェネレータ用のヘルパー
// ============================================

object Generators:
  /** 商品IDを生成 */
  def formatProductId(n: Int): String =
    f"PROD-${math.abs(n % 100000)}%05d"
  
  /** 注文IDを生成 */
  def formatOrderId(n: Int): String =
    f"ORD-${math.abs(n % 100000000)}%08d"
  
  /** 正の価格を生成（1〜10000） */
  def normalizePrice(n: Int): BigDecimal =
    BigDecimal(1 + math.abs(n % 10000))
  
  /** 正の数量を生成（1〜100） */
  def normalizeQuantity(n: Int): Int =
    1 + math.abs(n % 100)
  
  /** 年齢を正規化（0〜150） */
  def normalizeAge(n: Int): Int =
    math.abs(n % 151)

// ============================================
// 7. バリデーション（プロパティテスト対象）
// ============================================

object Validation:
  /** メールアドレスの簡易バリデーション */
  def isValidEmail(email: String): Boolean =
    email.contains("@") && 
    email.split("@").length == 2 &&
    email.split("@")(1).contains(".")
  
  /** 電話番号の簡易バリデーション（数字のみ、10-15桁） */
  def isValidPhoneNumber(phone: String): Boolean =
    phone.forall(_.isDigit) && 
    phone.length >= 10 && 
    phone.length <= 15
  
  /** 商品IDのバリデーション */
  def isValidProductId(id: String): Boolean =
    id.startsWith("PROD-") && 
    id.length == 10 &&
    id.drop(5).forall(_.isDigit)
  
  /** 注文IDのバリデーション */
  def isValidOrderId(id: String): Boolean =
    id.startsWith("ORD-") && 
    id.length == 12 &&
    id.drop(4).forall(_.isDigit)

// ============================================
// 8. コレクション操作（プロパティテスト対象）
// ============================================

object CollectionOps:
  /** リストの重複を除去 */
  def distinct[A](list: List[A]): List[A] = list.distinct
  
  /** リストを逆順に */
  def reverse[A](list: List[A]): List[A] = list.reverse
  
  /** 二つのリストを結合 */
  def concat[A](list1: List[A], list2: List[A]): List[A] = list1 ++ list2
  
  /** フィルタ操作 */
  def filter[A](list: List[A])(predicate: A => Boolean): List[A] = 
    list.filter(predicate)
  
  /** マップ操作 */
  def map[A, B](list: List[A])(f: A => B): List[B] = list.map(f)
  
  /** フラットマップ操作 */
  def flatMap[A, B](list: List[A])(f: A => List[B]): List[B] = list.flatMap(f)
