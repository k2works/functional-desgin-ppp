/**
  * 第10章: Strategy パターン
  * 
  * Strategy パターンは、アルゴリズムをカプセル化し、
  * それらを交換可能にするパターンです。
  */
package strategypattern

// ============================================
// 1. 料金計算戦略（トレイトベース）
// ============================================

/** 料金計算戦略のインターフェース */
trait PricingStrategy:
  def calculatePrice(amount: BigDecimal): BigDecimal

/** 通常料金戦略 */
case object RegularPricing extends PricingStrategy:
  def calculatePrice(amount: BigDecimal): BigDecimal = amount

/** 割引料金戦略 */
case class DiscountPricing(discountRate: BigDecimal) extends PricingStrategy:
  require(discountRate >= 0 && discountRate <= 1, "Discount rate must be 0-1")
  
  def calculatePrice(amount: BigDecimal): BigDecimal =
    amount * (BigDecimal(1) - discountRate)

/** 会員レベル */
enum MemberLevel(val discountRate: BigDecimal):
  case Gold extends MemberLevel(BigDecimal("0.20"))
  case Silver extends MemberLevel(BigDecimal("0.15"))
  case Bronze extends MemberLevel(BigDecimal("0.10"))

/** 会員料金戦略 */
case class MemberPricing(level: MemberLevel) extends PricingStrategy:
  def calculatePrice(amount: BigDecimal): BigDecimal =
    amount * (BigDecimal(1) - level.discountRate)

/** 大量購入割引戦略 */
case class BulkPricing(
  threshold: Int,
  bulkDiscount: BigDecimal
) extends PricingStrategy:
  require(bulkDiscount >= 0 && bulkDiscount <= 1, "Bulk discount must be 0-1")
  
  def calculatePrice(amount: BigDecimal): BigDecimal = amount
  
  def calculatePrice(amount: BigDecimal, quantity: Int): BigDecimal =
    if quantity >= threshold then
      amount * (BigDecimal(1) - bulkDiscount)
    else
      amount

// ============================================
// 2. ショッピングカート（Context）
// ============================================

/** カート内の商品 */
case class CartItem(name: String, price: BigDecimal, quantity: Int = 1)

/** ショッピングカート */
case class ShoppingCart(
  items: List[CartItem] = Nil,
  strategy: PricingStrategy = RegularPricing
):
  /** 商品を追加 */
  def addItem(item: CartItem): ShoppingCart =
    copy(items = items :+ item)
  
  /** 商品を削除 */
  def removeItem(name: String): ShoppingCart =
    copy(items = items.filterNot(_.name == name))
  
  /** 戦略を変更 */
  def changeStrategy(newStrategy: PricingStrategy): ShoppingCart =
    copy(strategy = newStrategy)
  
  /** 小計（割引前） */
  def subtotal: BigDecimal =
    items.map(item => item.price * item.quantity).sum
  
  /** 合計（割引後） */
  def total: BigDecimal =
    strategy.calculatePrice(subtotal)
  
  /** 商品数 */
  def itemCount: Int = items.map(_.quantity).sum

object ShoppingCart:
  def empty: ShoppingCart = ShoppingCart()
  
  def apply(items: CartItem*): ShoppingCart =
    ShoppingCart(items.toList)

// ============================================
// 3. 関数型アプローチ
// ============================================

object FunctionalStrategy:
  /** 料金戦略の型 */
  type PriceFn = BigDecimal => BigDecimal
  
  /** 通常料金 */
  val regular: PriceFn = identity
  
  /** 割引料金 */
  def discount(rate: BigDecimal): PriceFn =
    amount => amount * (BigDecimal(1) - rate)
  
  /** 会員料金 */
  def member(level: MemberLevel): PriceFn =
    discount(level.discountRate)
  
  /** 税金戦略 */
  def tax(rate: BigDecimal): PriceFn =
    amount => amount * (BigDecimal(1) + rate)
  
  /** 固定額割引 */
  def fixedDiscount(discountAmount: BigDecimal): PriceFn =
    amount => (amount - discountAmount).max(BigDecimal(0))
  
  /** 戦略の合成 */
  def compose(strategies: PriceFn*): PriceFn =
    amount => strategies.foldLeft(amount)((a, f) => f(a))
  
  /** 条件付き戦略 */
  def conditional(
    predicate: BigDecimal => Boolean,
    thenStrategy: PriceFn,
    elseStrategy: PriceFn = regular
  ): PriceFn =
    amount =>
      if predicate(amount) then thenStrategy(amount)
      else elseStrategy(amount)
  
  /** しきい値ベースの戦略 */
  def tiered(tiers: List[(BigDecimal, PriceFn)]): PriceFn =
    amount =>
      tiers
        .sortBy(-_._1) // 高い順にソート
        .find(_._1 <= amount)
        .map(_._2(amount))
        .getOrElse(amount)
  
  /** 最小値/最大値制約 */
  def clamp(min: BigDecimal, max: BigDecimal): PriceFn =
    amount => amount.min(max).max(min)
  
  /** 丸め戦略 */
  def round(scale: Int): PriceFn =
    amount => amount.setScale(scale, BigDecimal.RoundingMode.HALF_UP)

// ============================================
// 4. 関数型カート
// ============================================

/** 関数型ショッピングカート */
case class FunctionalCart(
  items: List[CartItem] = Nil,
  strategies: List[FunctionalStrategy.PriceFn] = List(FunctionalStrategy.regular)
):
  import FunctionalStrategy._
  
  def addItem(item: CartItem): FunctionalCart =
    copy(items = items :+ item)
  
  def addStrategy(strategy: PriceFn): FunctionalCart =
    copy(strategies = strategies :+ strategy)
  
  def clearStrategies(): FunctionalCart =
    copy(strategies = List(regular))
  
  def subtotal: BigDecimal =
    items.map(item => item.price * item.quantity).sum
  
  def total: BigDecimal =
    compose(strategies*)(subtotal)

// ============================================
// 5. 配送料金戦略
// ============================================

/** 配送料金戦略のインターフェース */
trait ShippingStrategy:
  def calculate(weight: Double, distance: Double): BigDecimal

/** 標準配送 */
case object StandardShipping extends ShippingStrategy:
  def calculate(weight: Double, distance: Double): BigDecimal =
    BigDecimal(weight * 10 + distance * 5)

/** 速達配送 */
case object ExpressShipping extends ShippingStrategy:
  def calculate(weight: Double, distance: Double): BigDecimal =
    BigDecimal(weight * 20 + distance * 15)

/** 無料配送 */
case class FreeShipping(minOrderAmount: BigDecimal) extends ShippingStrategy:
  def calculate(weight: Double, distance: Double): BigDecimal =
    BigDecimal(0)

/** 重量制配送 */
case class WeightBasedShipping(
  baseRate: BigDecimal,
  perKgRate: BigDecimal,
  freeThreshold: Double = Double.MaxValue
) extends ShippingStrategy:
  def calculate(weight: Double, distance: Double): BigDecimal =
    if weight >= freeThreshold then BigDecimal(0)
    else baseRate + BigDecimal(weight) * perKgRate

/** 距離制配送 */
case class DistanceBasedShipping(
  baseRate: BigDecimal,
  perKmRate: BigDecimal,
  zones: Map[Int, BigDecimal] = Map.empty
) extends ShippingStrategy:
  def calculate(weight: Double, distance: Double): BigDecimal =
    val zone = (distance / 100).toInt // 100km = 1ゾーン
    zones.get(zone) match
      case Some(zoneRate) => zoneRate
      case None => baseRate + BigDecimal(distance) * perKmRate

// ============================================
// 6. 注文コンテキスト
// ============================================

/** 注文 */
case class Order(
  cart: ShoppingCart,
  shippingStrategy: ShippingStrategy = StandardShipping,
  weight: Double = 1.0,
  distance: Double = 10.0
):
  def itemsTotal: BigDecimal = cart.total
  
  def shippingCost: BigDecimal =
    shippingStrategy.calculate(weight, distance)
  
  def grandTotal: BigDecimal =
    itemsTotal + shippingCost
  
  def changeShipping(strategy: ShippingStrategy): Order =
    copy(shippingStrategy = strategy)

// ============================================
// 7. 支払い戦略
// ============================================

/** 支払い結果 */
case class PaymentResult(
  success: Boolean,
  transactionId: Option[String] = None,
  fee: BigDecimal = BigDecimal(0),
  message: String = ""
)

/** 支払い戦略のインターフェース */
trait PaymentStrategy:
  def pay(amount: BigDecimal): PaymentResult
  def fee(amount: BigDecimal): BigDecimal

/** クレジットカード支払い */
case class CreditCardPayment(
  cardNumber: String,
  feeRate: BigDecimal = BigDecimal("0.03")
) extends PaymentStrategy:
  def pay(amount: BigDecimal): PaymentResult =
    PaymentResult(
      success = true,
      transactionId = Some(s"CC-${System.currentTimeMillis()}"),
      fee = fee(amount),
      message = s"Charged ${amount + fee(amount)} to card ending ${cardNumber.takeRight(4)}"
    )
  
  def fee(amount: BigDecimal): BigDecimal =
    amount * feeRate

/** 銀行振込 */
case class BankTransferPayment(
  bankCode: String,
  fixedFee: BigDecimal = BigDecimal(300)
) extends PaymentStrategy:
  def pay(amount: BigDecimal): PaymentResult =
    PaymentResult(
      success = true,
      transactionId = Some(s"BT-${System.currentTimeMillis()}"),
      fee = fixedFee,
      message = s"Transfer ${amount + fixedFee} to bank $bankCode"
    )
  
  def fee(amount: BigDecimal): BigDecimal = fixedFee

/** 代金引換 */
case class CashOnDeliveryPayment(
  fixedFee: BigDecimal = BigDecimal(500)
) extends PaymentStrategy:
  def pay(amount: BigDecimal): PaymentResult =
    PaymentResult(
      success = true,
      transactionId = Some(s"COD-${System.currentTimeMillis()}"),
      fee = fixedFee,
      message = s"Collect ${amount + fixedFee} on delivery"
    )
  
  def fee(amount: BigDecimal): BigDecimal = fixedFee

/** ポイント支払い */
case class PointsPayment(
  availablePoints: Int,
  pointValue: BigDecimal = BigDecimal("0.01")
) extends PaymentStrategy:
  def pay(amount: BigDecimal): PaymentResult =
    val pointsNeeded = (amount / pointValue).toInt
    if pointsNeeded <= availablePoints then
      PaymentResult(
        success = true,
        transactionId = Some(s"PT-${System.currentTimeMillis()}"),
        fee = BigDecimal(0),
        message = s"Used $pointsNeeded points"
      )
    else
      PaymentResult(
        success = false,
        message = s"Insufficient points: need $pointsNeeded, have $availablePoints"
      )
  
  def fee(amount: BigDecimal): BigDecimal = BigDecimal(0)

// ============================================
// 8. ソート戦略
// ============================================

/** ソート戦略 */
object SortStrategy:
  /** ソート関数の型 */
  type SortFn[A] = List[A] => List[A]
  
  /** 昇順ソート */
  def ascending[A](using ord: Ordering[A]): SortFn[A] = _.sorted
  
  /** 降順ソート */
  def descending[A](using ord: Ordering[A]): SortFn[A] = _.sorted(ord.reverse)
  
  /** カスタムキーでソート */
  def byKey[A, B](key: A => B)(using ord: Ordering[B]): SortFn[A] = _.sortBy(key)
  
  /** 複合ソート */
  def compound[A](primary: Ordering[A], secondary: Ordering[A]): SortFn[A] =
    _.sorted(primary.orElse(secondary))
  
  /** 安定ソート（既存の順序を維持） */
  def stable[A, B](key: A => B)(using ord: Ordering[B]): SortFn[A] =
    list => list.zipWithIndex.sortBy { case (a, i) => (key(a), i) }.map(_._1)

// ============================================
// 9. バリデーション戦略
// ============================================

/** バリデーション結果 */
sealed trait ValidationResult[+A]:
  def isValid: Boolean
  def map[B](f: A => B): ValidationResult[B]
  def flatMap[B](f: A => ValidationResult[B]): ValidationResult[B]

case class Valid[A](value: A) extends ValidationResult[A]:
  def isValid: Boolean = true
  def map[B](f: A => B): ValidationResult[B] = Valid(f(value))
  def flatMap[B](f: A => ValidationResult[B]): ValidationResult[B] = f(value)

case class Invalid(errors: List[String]) extends ValidationResult[Nothing]:
  def isValid: Boolean = false
  def map[B](f: Nothing => B): ValidationResult[B] = this
  def flatMap[B](f: Nothing => ValidationResult[B]): ValidationResult[B] = this

object Invalid:
  def apply(error: String): Invalid = Invalid(List(error))

/** バリデーション戦略 */
object ValidationStrategy:
  /** バリデータの型 */
  type Validator[A] = A => ValidationResult[A]
  
  /** 常に有効 */
  def always[A]: Validator[A] = a => Valid(a)
  
  /** 常に無効 */
  def never[A](error: String): Validator[A] = _ => Invalid(error)
  
  /** 述語ベースのバリデータ */
  def predicate[A](pred: A => Boolean, error: String): Validator[A] =
    a => if pred(a) then Valid(a) else Invalid(error)
  
  /** 最小値チェック */
  def min[A: Ordering](minValue: A, error: String): Validator[A] =
    predicate(a => Ordering[A].gteq(a, minValue), error)
  
  /** 最大値チェック */
  def max[A: Ordering](maxValue: A, error: String): Validator[A] =
    predicate(a => Ordering[A].lteq(a, maxValue), error)
  
  /** 範囲チェック */
  def range[A: Ordering](minValue: A, maxValue: A, error: String): Validator[A] =
    predicate(a => Ordering[A].gteq(a, minValue) && Ordering[A].lteq(a, maxValue), error)
  
  /** バリデータの合成（AND） */
  def all[A](validators: Validator[A]*): Validator[A] =
    a =>
      val results = validators.map(_(a))
      val errors = results.collect { case Invalid(errs) => errs }.flatten.toList
      if errors.isEmpty then Valid(a)
      else Invalid(errors)
  
  /** バリデータの合成（OR） */
  def any[A](validators: Validator[A]*): Validator[A] =
    a =>
      val results = validators.map(_(a))
      if results.exists(_.isValid) then Valid(a)
      else
        val errors = results.collect { case Invalid(errs) => errs }.flatten.toList
        Invalid(errors)

// ============================================
// 10. 検索戦略
// ============================================

/** 検索戦略 */
object SearchStrategy:
  import scala.collection.Searching._
  
  /** 検索関数の型 */
  type SearchFn[A] = (List[A], A => Boolean) => Option[A]
  
  /** 最初に見つかった要素 */
  def findFirst[A]: SearchFn[A] = (list, pred) => list.find(pred)
  
  /** 最後に見つかった要素 */
  def findLast[A]: SearchFn[A] = (list, pred) => list.findLast(pred)
  
  /** 全て見つける */
  def findAll[A]: (List[A], A => Boolean) => List[A] = (list, pred) => list.filter(pred)
  
  /** 二分探索（ソート済みリスト用） */
  def binarySearch[A](target: A)(using ord: Ordering[A]): List[A] => Option[Int] =
    list =>
      list.search(target) match
        case Found(idx) => Some(idx)
        case InsertionPoint(_) => None
