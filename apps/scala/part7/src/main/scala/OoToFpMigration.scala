package oo_to_fp_migration

import java.time.Instant

// ============================================
// 第22章: オブジェクト指向から関数型への移行
// ============================================

// ============================================
// 1. OOスタイル（問題のあるアプローチ）
// ============================================

object OOStyle:
  /** OOスタイル: 内部状態を持つオブジェクト（可変） */
  class Account(val id: String, initialBalance: Double):
    private var _balance: Double = initialBalance
    private var _transactions: List[Transaction] = List.empty

    def balance: Double = _balance
    def transactions: List[Transaction] = _transactions

    def deposit(amount: Double): Double =
      if amount > 0 then
        _balance += amount
        _transactions = _transactions :+ Transaction(TransactionType.Deposit, amount)
        _balance
      else _balance

    def withdraw(amount: Double): Double =
      if amount > 0 && _balance >= amount then
        _balance -= amount
        _transactions = _transactions :+ Transaction(TransactionType.Withdrawal, amount)
        _balance
      else _balance

  enum TransactionType:
    case Deposit, Withdrawal

  case class Transaction(transactionType: TransactionType, amount: Double)

// ============================================
// 2. FPスタイル（推奨アプローチ）
// ============================================

object FPStyle:
  /** トランザクションの種類 */
  enum TransactionType:
    case Deposit, Withdrawal

  /** トランザクション記録 */
  case class Transaction(transactionType: TransactionType, amount: Double)

  /** 口座（不変データ） */
  case class Account(
      id: String,
      balance: Double,
      transactions: List[Transaction] = List.empty
  )

  /** 口座を作成 */
  def makeAccount(id: String, initialBalance: Double): Account =
    Account(id, initialBalance)

  /** 残高を取得 */
  def getBalance(account: Account): Double = account.balance

  /** 入金（新しい口座を返す） */
  def deposit(account: Account, amount: Double): Account =
    if amount > 0 then
      account.copy(
        balance = account.balance + amount,
        transactions = account.transactions :+ Transaction(TransactionType.Deposit, amount)
      )
    else account

  /** 出金（新しい口座を返す） */
  def withdraw(account: Account, amount: Double): Account =
    if amount > 0 && account.balance >= amount then
      account.copy(
        balance = account.balance - amount,
        transactions = account.transactions :+ Transaction(TransactionType.Withdrawal, amount)
      )
    else account

  /** 送金結果 */
  case class TransferResult(
      success: Boolean,
      from: Account,
      to: Account,
      error: Option[String] = None
  )

  /** 送金（2つの口座間） */
  def transfer(from: Account, to: Account, amount: Double): TransferResult =
    if amount <= 0 then
      TransferResult(false, from, to, Some("Amount must be positive"))
    else if from.balance < amount then
      TransferResult(false, from, to, Some("Insufficient funds"))
    else
      val newFrom = withdraw(from, amount)
      val newTo = deposit(to, amount)
      TransferResult(true, newFrom, newTo)

// ============================================
// 3. 移行戦略
// ============================================

object MigrationStrategies:
  import FPStyle.*

  // -----------------------------------------
  // 3.1 Strangler Fig パターン
  // -----------------------------------------

  /** スタイル識別子 */
  enum Style:
    case FP, OO

  /** Strangler パターン用のラッパー */
  case class StranglerAccount(style: Style, data: Account)

  /** フィーチャーフラグによるアカウント作成 */
  def createAccountStrangler(id: String, initialBalance: Double, useFP: Boolean): StranglerAccount =
    if useFP then StranglerAccount(Style.FP, makeAccount(id, initialBalance))
    else StranglerAccount(Style.OO, makeAccount(id, initialBalance))

  /** Strangler パターンでの入金 */
  def accountDeposit(account: StranglerAccount, amount: Double): StranglerAccount =
    account.style match
      case Style.FP => account.copy(data = deposit(account.data, amount))
      case Style.OO => account.copy(data = deposit(account.data, amount))

  // -----------------------------------------
  // 3.2 アダプターパターン
  // -----------------------------------------

  /** 既存のインターフェースを維持するためのトレイト */
  trait AccountOperations:
    def getAccountBalance: Double
    def depositToAccount(amount: Double): Double
    def withdrawFromAccount(amount: Double): Double

  /** FPスタイルのアダプター（状態は外部で管理） */
  class FPAccountAdapter(private var account: Account) extends AccountOperations:
    def getAccountBalance: Double = getBalance(account)

    def depositToAccount(amount: Double): Double =
      account = deposit(account, amount)
      getBalance(account)

    def withdrawFromAccount(amount: Double): Double =
      account = withdraw(account, amount)
      getBalance(account)

    def getAccount: Account = account

  def makeFPAccountAdapter(id: String, initialBalance: Double): FPAccountAdapter =
    new FPAccountAdapter(makeAccount(id, initialBalance))

  // -----------------------------------------
  // 3.3 イベントソーシング移行
  // -----------------------------------------

  /** イベントの種類 */
  enum EventType:
    case Created, Deposited, Withdrawn

  /** イベント */
  case class AccountEvent(
      eventType: EventType,
      data: Map[String, Any],
      timestamp: Long = System.currentTimeMillis()
  )

  /** イベント作成ヘルパー */
  def accountEvent(eventType: EventType, data: Map[String, Any]): AccountEvent =
    AccountEvent(eventType, data)

  /** イベントを適用して状態を更新 */
  def applyEvent(account: Account, event: AccountEvent): Account =
    event.eventType match
      case EventType.Created =>
        Account(
          id = event.data("id").toString,
          balance = event.data.getOrElse("balance", 0.0).asInstanceOf[Double],
          transactions = List.empty
        )
      case EventType.Deposited =>
        deposit(account, event.data("amount").asInstanceOf[Double])
      case EventType.Withdrawn =>
        withdraw(account, event.data("amount").asInstanceOf[Double])

  /** イベントのリプレイ */
  def replayEvents(events: List[AccountEvent]): Account =
    events.foldLeft(Account("", 0.0))(applyEvent)

  /** 既存データからイベントへの変換 */
  def migrateToEventSourcing(account: Account): List[AccountEvent] =
    val creationEvent = accountEvent(
      EventType.Created,
      Map("id" -> account.id, "balance" -> 0.0)
    )

    val transactionEvents = account.transactions.map { tx =>
      val eventType = tx.transactionType match
        case TransactionType.Deposit    => EventType.Deposited
        case TransactionType.Withdrawal => EventType.Withdrawn
      accountEvent(eventType, Map("amount" -> tx.amount))
    }

    creationEvent :: transactionEvents

  // -----------------------------------------
  // 3.4 段階的な関数抽出
  // -----------------------------------------

  /** 利息計算（純粋関数） */
  def calculateInterest(balance: Double, rate: Double, days: Int): Double =
    balance * rate * (days / 365.0)

  /** 手数料体系 */
  case class FeeStructure(
      minimumBalance: Double,
      lowBalanceFee: Double,
      premiumThreshold: Double,
      standardFee: Double
  )

  /** 手数料計算（純粋関数） */
  def calculateFee(balance: Double, feeStructure: FeeStructure): Double =
    if balance < feeStructure.minimumBalance then feeStructure.lowBalanceFee
    else if balance > feeStructure.premiumThreshold then 0.0
    else feeStructure.standardFee

  /** 出金可能判定（純粋関数） */
  def canWithdraw(account: Account, amount: Double, overdraftLimit: Double): Boolean =
    account.balance + overdraftLimit >= amount

  /** 新しい残高計算（純粋関数） */
  def calculateNewBalance(currentBalance: Double, operation: TransactionType, amount: Double): Double =
    operation match
      case TransactionType.Deposit    => currentBalance + amount
      case TransactionType.Withdrawal => currentBalance - amount

  /** 取引処理結果 */
  case class ProcessResult(
      success: Boolean,
      account: Account,
      error: Option[String] = None
  )

  /** 取引ルール */
  case class TransactionRules(overdraftLimit: Double)

  /** 取引処理（副作用なし） */
  def processTransaction(
      account: Account,
      operation: TransactionType,
      amount: Double,
      rules: TransactionRules
  ): ProcessResult =
    val canProcess = operation match
      case TransactionType.Deposit    => true
      case TransactionType.Withdrawal => canWithdraw(account, amount, rules.overdraftLimit)

    if canProcess then
      val newBalance = calculateNewBalance(account.balance, operation, amount)
      val newAccount = account.copy(
        balance = newBalance,
        transactions = account.transactions :+ Transaction(operation, amount)
      )
      ProcessResult(true, newAccount)
    else ProcessResult(false, account, Some("Insufficient funds"))

// ============================================
// 4. マルチメソッドによる多態性
// ============================================

object Polymorphism:
  /** 図形（ADT） */
  sealed trait Shape:
    def x: Double
    def y: Double

  case class Circle(x: Double, y: Double, radius: Double) extends Shape
  case class Rectangle(x: Double, y: Double, width: Double, height: Double) extends Shape
  case class Triangle(x: Double, y: Double, base: Double, height: Double) extends Shape

  /** 図形の面積を計算（パターンマッチで多態性） */
  def area(shape: Shape): Double = shape match
    case Circle(_, _, r)         => Math.PI * r * r
    case Rectangle(_, _, w, h)   => w * h
    case Triangle(_, _, base, h) => base * h / 2

  /** 図形を拡大（パターンマッチで多態性） */
  def scale(shape: Shape, factor: Double): Shape = shape match
    case c: Circle    => c.copy(radius = c.radius * factor)
    case r: Rectangle => r.copy(width = r.width * factor, height = r.height * factor)
    case t: Triangle  => t.copy(base = t.base * factor, height = t.height * factor)

  /** 共通操作（型に依存しない） */
  def move(shape: Shape, dx: Double, dy: Double): Shape = shape match
    case c: Circle    => c.copy(x = c.x + dx, y = c.y + dy)
    case r: Rectangle => r.copy(x = r.x + dx, y = r.y + dy)
    case t: Triangle  => t.copy(x = t.x + dx, y = t.y + dy)

  /** 周囲長を計算 */
  def perimeter(shape: Shape): Double = shape match
    case Circle(_, _, r)       => 2 * Math.PI * r
    case Rectangle(_, _, w, h) => 2 * (w + h)
    case Triangle(_, _, b, h) =>
      // 二等辺三角形と仮定
      val side = Math.sqrt((b / 2) * (b / 2) + h * h)
      b + 2 * side

// ============================================
// 5. イベント駆動アーキテクチャ
// ============================================

object EventDriven:
  /** イベント */
  case class Event[A](eventType: String, data: A)

  /** イベントハンドラ */
  type EventHandler[A, B] = Event[A] => B

  /** イベントシステム（不変） */
  case class EventSystem[A](
      handlers: Map[String, List[EventHandler[A, Any]]] = Map.empty,
      eventLog: List[Event[A]] = List.empty
  )

  /** イベントシステムを作成 */
  def makeEventSystem[A](): EventSystem[A] = 
    EventSystem[A](Map.empty[String, List[EventHandler[A, Any]]], List.empty[Event[A]])

  /** ハンドラを登録 */
  def subscribe[A, B](
      system: EventSystem[A],
      eventType: String,
      handler: EventHandler[A, B]
  ): EventSystem[A] =
    val currentHandlers = system.handlers.getOrElse(eventType, List.empty)
    system.copy(
      handlers = system.handlers + (eventType -> (currentHandlers :+ handler.asInstanceOf[EventHandler[A, Any]]))
    )

  /** パブリッシュ結果 */
  case class PublishResult[A](system: EventSystem[A], results: List[Any])

  /** イベントを発行 */
  def publish[A](system: EventSystem[A], eventType: String, data: A): PublishResult[A] =
    val event = Event(eventType, data)
    val handlers = system.handlers.getOrElse(eventType, List.empty)
    val results = handlers.map(h => h(event))
    val newSystem = system.copy(eventLog = system.eventLog :+ event)
    PublishResult(newSystem, results)

  /** イベントログを取得 */
  def getEventLog[A](system: EventSystem[A]): List[Event[A]] = system.eventLog

// ============================================
// 6. 実践的な移行例
// ============================================

object PracticalMigration:
  import FPStyle.*

  // -----------------------------------------
  // 6.1 ドメインモデリング
  // -----------------------------------------

  /** ユーザーID（値オブジェクト） */
  opaque type UserId = String
  object UserId:
    def apply(value: String): UserId = value
    extension (id: UserId) def value: String = id

  /** メールアドレス（値オブジェクト + バリデーション） */
  opaque type Email = String
  object Email:
    def apply(value: String): Either[String, Email] =
      if value.contains("@") && value.length > 3 then Right(value)
      else Left("Invalid email format")

    extension (email: Email) def value: String = email

  /** ユーザー（不変エンティティ） */
  case class User(id: UserId, name: String, email: String, active: Boolean = true)

  /** ユーザー作成結果 */
  sealed trait CreateUserResult
  case class UserCreated(user: User) extends CreateUserResult
  case class UserCreationFailed(errors: List[String]) extends CreateUserResult

  /** ユーザー作成（バリデーション付き） */
  def createUser(id: String, name: String, email: String): CreateUserResult =
    val errors = List(
      if name.isEmpty then Some("Name is required") else None,
      if !email.contains("@") then Some("Invalid email") else None,
      if id.isEmpty then Some("ID is required") else None
    ).flatten

    if errors.isEmpty then UserCreated(User(UserId(id), name, email))
    else UserCreationFailed(errors)

  // -----------------------------------------
  // 6.2 リポジトリパターン（FP版）
  // -----------------------------------------

  /** リポジトリ操作の結果 */
  sealed trait RepositoryResult[+A]
  case class Found[A](value: A) extends RepositoryResult[A]
  case object NotFound extends RepositoryResult[Nothing]
  case class RepoError(message: String) extends RepositoryResult[Nothing]

  /** 不変リポジトリ */
  case class UserRepository(users: Map[UserId, User] = Map.empty):
    def save(user: User): UserRepository =
      copy(users = users + (user.id -> user))

    def findById(id: UserId): RepositoryResult[User] =
      users.get(id) match
        case Some(user) => Found(user)
        case None       => NotFound

    def findAll: List[User] = users.values.toList

    def delete(id: UserId): UserRepository =
      copy(users = users - id)

    def update(id: UserId, f: User => User): UserRepository =
      users.get(id) match
        case Some(user) => copy(users = users + (id -> f(user)))
        case None       => this

  // -----------------------------------------
  // 6.3 サービス層（純粋関数）
  // -----------------------------------------

  /** サービス操作の結果 */
  case class ServiceResult[A](value: A, repository: UserRepository)

  /** ユーザーサービス（純粋関数として実装） */
  object UserService:
    def registerUser(
        repo: UserRepository,
        id: String,
        name: String,
        email: String
    ): Either[List[String], ServiceResult[User]] =
      createUser(id, name, email) match
        case UserCreated(user) =>
          Right(ServiceResult(user, repo.save(user)))
        case UserCreationFailed(errors) =>
          Left(errors)

    def deactivateUser(
        repo: UserRepository,
        id: UserId
    ): Either[String, ServiceResult[User]] =
      repo.findById(id) match
        case Found(user) =>
          val updated = user.copy(active = false)
          Right(ServiceResult(updated, repo.update(id, _ => updated)))
        case NotFound =>
          Left("User not found")
        case RepoError(msg) =>
          Left(msg)

    def getAllActiveUsers(repo: UserRepository): List[User] =
      repo.findAll.filter(_.active)

  // -----------------------------------------
  // 6.4 パイプライン処理
  // -----------------------------------------

  /** データ処理パイプライン */
  def pipeline[A, B, C](
      input: A,
      step1: A => B,
      step2: B => C
  ): C = step2(step1(input))

  /** パイプライン演算子（拡張メソッド） */
  extension [A](a: A)
    def |>[B](f: A => B): B = f(a)

  /** データ変換の例 */
  def transformUserData(users: List[User]): Map[String, List[String]] =
    users
      .filter(_.active)
      .groupBy(_.name.head.toString.toUpperCase)
      .view
      .mapValues(_.map(_.email))
      .toMap

// ============================================
// 7. 移行チェックリスト
// ============================================

object MigrationChecklist:
  /** チェック項目 */
  case class ChecklistItem(description: String, completed: Boolean = false)

  /** 移行チェックリスト */
  case class MigrationChecklist(
      preparation: List[ChecklistItem],
      execution: List[ChecklistItem],
      completion: List[ChecklistItem]
  )

  /** デフォルトのチェックリスト */
  val defaultChecklist: MigrationChecklist = MigrationChecklist(
    preparation = List(
      ChecklistItem("現在のコードの状態を把握"),
      ChecklistItem("テストカバレッジを確認"),
      ChecklistItem("移行の優先順位を決定"),
      ChecklistItem("チームへの教育")
    ),
    execution = List(
      ChecklistItem("純粋関数を抽出"),
      ChecklistItem("副作用を分離"),
      ChecklistItem("ADTに移行"),
      ChecklistItem("テストを追加")
    ),
    completion = List(
      ChecklistItem("古いコードを削除"),
      ChecklistItem("ドキュメントを更新"),
      ChecklistItem("パフォーマンスを確認"),
      ChecklistItem("チームレビュー")
    )
  )

  /** 項目を完了としてマーク */
  def markCompleted(
      checklist: MigrationChecklist,
      phase: String,
      index: Int
  ): MigrationChecklist =
    phase match
      case "preparation" =>
        checklist.copy(
          preparation = checklist.preparation.updated(
            index,
            checklist.preparation(index).copy(completed = true)
          )
        )
      case "execution" =>
        checklist.copy(
          execution = checklist.execution.updated(
            index,
            checklist.execution(index).copy(completed = true)
          )
        )
      case "completion" =>
        checklist.copy(
          completion = checklist.completion.updated(
            index,
            checklist.completion(index).copy(completed = true)
          )
        )
      case _ => checklist

  /** 進捗を計算 */
  def calculateProgress(checklist: MigrationChecklist): Double =
    val all = checklist.preparation ++ checklist.execution ++ checklist.completion
    val completed = all.count(_.completed)
    if all.isEmpty then 0.0 else completed.toDouble / all.size * 100

// ============================================
// 8. 比較表
// ============================================

object Comparison:
  /** 比較項目 */
  case class ComparisonItem(aspect: String, oo: String, fp: String, advantage: String)

  /** OO vs FP 比較表 */
  val comparisonTable: List[ComparisonItem] = List(
    ComparisonItem("基本単位", "オブジェクト", "データ + 関数", "FP: より単純な構造"),
    ComparisonItem("状態管理", "可変（mutable）", "不変（immutable）", "FP: 予測可能"),
    ComparisonItem("多態性", "継承・インターフェース", "ADT・パターンマッチ", "FP: より柔軟"),
    ComparisonItem("コード再利用", "継承", "関数合成", "FP: より疎結合"),
    ComparisonItem("副作用", "どこでも可能", "境界に分離", "FP: テスト容易"),
    ComparisonItem("テスト", "モックが必要", "入力→出力のみ", "FP: シンプル"),
    ComparisonItem("デバッグ", "状態追跡が困難", "値が不変で追跡容易", "FP: 容易"),
    ComparisonItem("並行処理", "ロックが必要", "不変データで安全", "FP: 安全")
  )

  /** アドバンテージをカウント */
  def countAdvantages: Map[String, Int] =
    comparisonTable
      .map(_.advantage)
      .groupBy(a => if a.contains("FP") then "FP" else "OO")
      .view
      .mapValues(_.size)
      .toMap
