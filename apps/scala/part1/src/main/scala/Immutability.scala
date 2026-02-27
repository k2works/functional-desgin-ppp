package immutability

/**
 * 第1章: 不変性とデータ変換
 *
 * 関数型プログラミングにおける不変データ構造の基本から、
 * データ変換パイプライン、副作用の分離までを扱います。
 */
object Immutability:

  // =============================================================================
  // 1. 不変データ構造の基本
  // =============================================================================

  case class Person(name: String, age: Int)

  /**
   * 人物の年齢を更新する（元のデータは変更しない）
   */
  def updateAge(person: Person, newAge: Int): Person =
    person.copy(age = newAge)

  // =============================================================================
  // 2. 構造共有（Structural Sharing）
  // =============================================================================

  case class Member(name: String, role: String)
  case class Team(name: String, members: List[Member])

  /**
   * チームに新しいメンバーを追加する
   */
  def addMember(team: Team, member: Member): Team =
    team.copy(members = team.members :+ member)

  // =============================================================================
  // 3. データ変換パイプライン
  // =============================================================================

  case class Item(name: String, price: Int, quantity: Int)
  case class Customer(name: String, membership: String)
  case class Order(items: List[Item], customer: Customer)

  /**
   * 各アイテムの小計を計算する
   */
  def calculateSubtotal(item: Item): Int =
    item.price * item.quantity

  /**
   * 会員種別に応じた割引率を取得する
   */
  def membershipDiscount(membership: String): Double =
    membership match
      case "gold"   => 0.1
      case "silver" => 0.05
      case "bronze" => 0.02
      case _        => 0.0

  /**
   * 注文の合計金額を計算する
   */
  def calculateTotal(order: Order): Int =
    order.items.map(calculateSubtotal).sum

  /**
   * 割引後の金額を計算する
   */
  def applyDiscount(order: Order, total: Int): Double =
    val discountRate = membershipDiscount(order.customer.membership)
    total * (1 - discountRate)

  /**
   * 注文を処理し、割引後の合計金額を返す
   */
  def processOrder(order: Order): Double =
    val total = calculateTotal(order)
    applyDiscount(order, total)

  // =============================================================================
  // 4. 副作用の分離
  // =============================================================================

  case class Invoice(subtotal: Int, tax: Double, total: Double)

  /**
   * 純粋関数：税額を計算する
   */
  def pureCalculateTax(amount: Int, taxRate: Double): Double =
    amount * taxRate

  /**
   * ビジネスロジック（純粋関数）：請求書を計算する
   */
  def calculateInvoice(items: List[Item], taxRate: Double): Invoice =
    val subtotal = items.map(calculateSubtotal).sum
    val tax = pureCalculateTax(subtotal, taxRate)
    val total = subtotal + tax
    Invoice(subtotal, tax, total)

  /**
   * データベースへの保存（副作用）
   * Scala では副作用を持つ関数に ! は付けないが、コメントで明示
   */
  def saveInvoice(invoice: Invoice): Invoice =
    println(s"Saving invoice: $invoice")
    invoice

  /**
   * メール送信（副作用）
   */
  def sendNotification(invoice: Invoice, customerEmail: String): Invoice =
    println(s"Sending notification to: $customerEmail")
    invoice

  /**
   * 処理全体のオーケストレーション
   */
  def processAndSaveInvoice(items: List[Item], taxRate: Double, customerEmail: String): Invoice =
    val invoice = calculateInvoice(items, taxRate)
    val saved = saveInvoice(invoice)
    sendNotification(saved, customerEmail)

  // =============================================================================
  // 5. 永続的データ構造の活用：Undo/Redo の実装
  // =============================================================================

  case class History[A](current: Option[A], past: List[A], future: List[A])

  /**
   * 履歴を保持するデータ構造を作成する
   */
  def createHistory[A](): History[A] =
    History(current = None, past = List.empty, future = List.empty)

  /**
   * 新しい状態を履歴にプッシュする
   */
  def pushState[A](history: History[A], newState: A): History[A] =
    History(
      current = Some(newState),
      past = history.current.toList ++ history.past,
      future = List.empty
    )

  /**
   * 直前の状態に戻す
   */
  def undo[A](history: History[A]): History[A] =
    history.past match
      case Nil => history
      case previous :: rest =>
        History(
          current = Some(previous),
          past = rest,
          future = history.current.toList ++ history.future
        )

  /**
   * やり直し操作
   */
  def redo[A](history: History[A]): History[A] =
    history.future match
      case Nil => history
      case nextState :: rest =>
        History(
          current = Some(nextState),
          past = history.current.toList ++ history.past,
          future = rest
        )

  // =============================================================================
  // 6. Scala の関数合成による効率的な変換
  // =============================================================================

  case class ProcessedItem(name: String, price: Int, quantity: Int, subtotal: Int)

  /**
   * 複数の変換を合成した処理
   * Scala では LazyList や Iterator を使用して遅延評価を実現
   */
  def processItemsEfficiently(items: List[Item]): List[ProcessedItem] =
    items
      .filter(_.quantity > 0)
      .map(item => ProcessedItem(item.name, item.price, item.quantity, calculateSubtotal(item)))
      .filter(_.subtotal > 100)

  /**
   * Iterator を使用したより効率的な処理
   */
  def processItemsWithIterator(items: List[Item]): List[ProcessedItem] =
    items.iterator
      .filter(_.quantity > 0)
      .map(item => ProcessedItem(item.name, item.price, item.quantity, calculateSubtotal(item)))
      .filter(_.subtotal > 100)
      .toList
