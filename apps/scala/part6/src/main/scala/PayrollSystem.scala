/**
 * 第16章: 給与計算システム
 *
 * 関数型プログラミングにおけるドメインモデリングと
 * 多態性の実現を学びます。
 */
object PayrollSystem:

  // ============================================================
  // 1. 基本型定義
  // ============================================================

  type EmployeeId = String
  type Money = BigDecimal
  type Hours = Double
  type Rate = Double

  // ============================================================
  // 2. 給与分類（PayClass）
  // ============================================================

  /**
   * 給与分類を表す sealed trait
   */
  sealed trait PayClass:
    def payType: String

  /**
   * 月給制
   */
  case class Salaried(salary: Money) extends PayClass:
    def payType: String = "salaried"

  /**
   * 時給制
   */
  case class Hourly(hourlyRate: Money) extends PayClass:
    def payType: String = "hourly"

  /**
   * 歩合制
   */
  case class Commissioned(basePay: Money, commissionRate: Rate) extends PayClass:
    def payType: String = "commissioned"

  // ============================================================
  // 3. 支払いスケジュール
  // ============================================================

  /**
   * 支払いスケジュール
   */
  enum Schedule:
    case Monthly   // 月次（月末）
    case Weekly    // 週次（毎週金曜日）
    case Biweekly  // 隔週（隔週金曜日）

  // ============================================================
  // 4. 支払い方法
  // ============================================================

  /**
   * 支払い方法
   */
  enum PaymentMethod:
    case Hold          // 保留
    case DirectDeposit(accountNumber: String) // 口座振込
    case Mail(address: String)                // 小切手郵送

  // ============================================================
  // 5. 従業員（Employee）
  // ============================================================

  /**
   * 従業員を表すケースクラス
   */
  case class Employee(
    id: EmployeeId,
    name: String,
    payClass: PayClass,
    schedule: Schedule,
    paymentMethod: PaymentMethod,
    address: Option[String] = None
  )

  /**
   * 従業員ファクトリ
   */
  object Employee:
    def salaried(id: EmployeeId, name: String, salary: Money): Employee =
      Employee(id, name, Salaried(salary), Schedule.Monthly, PaymentMethod.Hold)

    def hourly(id: EmployeeId, name: String, hourlyRate: Money): Employee =
      Employee(id, name, Hourly(hourlyRate), Schedule.Weekly, PaymentMethod.Hold)

    def commissioned(id: EmployeeId, name: String, basePay: Money, commissionRate: Rate): Employee =
      Employee(id, name, Commissioned(basePay, commissionRate), Schedule.Biweekly, PaymentMethod.Hold)

  // ============================================================
  // 6. コンテキスト（タイムカード、売上）
  // ============================================================

  /**
   * タイムカード
   */
  case class TimeCard(employeeId: EmployeeId, date: String, hours: Hours)

  /**
   * 売上伝票
   */
  case class SalesReceipt(employeeId: EmployeeId, date: String, amount: Money)

  /**
   * 給与計算コンテキスト
   */
  case class PayrollContext(
    timeCards: Map[EmployeeId, List[TimeCard]] = Map.empty.withDefaultValue(Nil),
    salesReceipts: Map[EmployeeId, List[SalesReceipt]] = Map.empty.withDefaultValue(Nil)
  ):
    def addTimeCard(tc: TimeCard): PayrollContext =
      val cards = timeCards(tc.employeeId)
      copy(timeCards = timeCards + (tc.employeeId -> (tc :: cards)))

    def addSalesReceipt(sr: SalesReceipt): PayrollContext =
      val receipts = salesReceipts(sr.employeeId)
      copy(salesReceipts = salesReceipts + (sr.employeeId -> (sr :: receipts)))

    def getTimeCards(employeeId: EmployeeId): List[TimeCard] =
      timeCards(employeeId)

    def getSalesReceipts(employeeId: EmployeeId): List[SalesReceipt] =
      salesReceipts(employeeId)

  object PayrollContext:
    def empty: PayrollContext = PayrollContext()

  // ============================================================
  // 7. 給与計算
  // ============================================================

  /**
   * 給与計算の型クラス
   */
  trait PayCalculator[P <: PayClass]:
    def calculate(payClass: P, context: PayrollContext, employeeId: EmployeeId): Money

  given PayCalculator[Salaried] with
    def calculate(payClass: Salaried, context: PayrollContext, employeeId: EmployeeId): Money =
      payClass.salary

  given PayCalculator[Hourly] with
    def calculate(payClass: Hourly, context: PayrollContext, employeeId: EmployeeId): Money =
      val timeCards = context.getTimeCards(employeeId)
      val totalHours = timeCards.map(_.hours).sum
      val regularHours = math.min(totalHours, 40.0)
      val overtimeHours = math.max(0.0, totalHours - 40.0)
      payClass.hourlyRate * BigDecimal(regularHours) +
        payClass.hourlyRate * BigDecimal(overtimeHours) * BigDecimal(1.5)

  given PayCalculator[Commissioned] with
    def calculate(payClass: Commissioned, context: PayrollContext, employeeId: EmployeeId): Money =
      val salesReceipts = context.getSalesReceipts(employeeId)
      val totalSales = salesReceipts.map(_.amount).sum
      payClass.basePay + totalSales * BigDecimal(payClass.commissionRate)

  /**
   * 従業員の給与を計算
   */
  def calculatePay(employee: Employee, context: PayrollContext): Money =
    employee.payClass match
      case s: Salaried => summon[PayCalculator[Salaried]].calculate(s, context, employee.id)
      case h: Hourly => summon[PayCalculator[Hourly]].calculate(h, context, employee.id)
      case c: Commissioned => summon[PayCalculator[Commissioned]].calculate(c, context, employee.id)

  // ============================================================
  // 8. 支払いスケジュール判定
  // ============================================================

  /**
   * 日付情報
   */
  case class PayDate(
    year: Int,
    month: Int,
    day: Int,
    dayOfWeek: DayOfWeek,
    isLastDayOfMonth: Boolean,
    isPayWeek: Boolean = true  // 隔週判定用
  )

  enum DayOfWeek:
    case Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

  /**
   * 支払日判定
   */
  def isPayDay(employee: Employee, date: PayDate): Boolean =
    employee.schedule match
      case Schedule.Monthly => date.isLastDayOfMonth
      case Schedule.Weekly => date.dayOfWeek == DayOfWeek.Friday
      case Schedule.Biweekly => date.dayOfWeek == DayOfWeek.Friday && date.isPayWeek

  // ============================================================
  // 9. 支払い処理
  // ============================================================

  /**
   * 支払い結果
   */
  sealed trait PaymentResult:
    def employeeId: EmployeeId
    def amount: Money

  case class HeldPayment(employeeId: EmployeeId, amount: Money) extends PaymentResult
  case class DirectDepositPayment(employeeId: EmployeeId, amount: Money, accountNumber: String) extends PaymentResult
  case class MailedPayment(employeeId: EmployeeId, amount: Money, address: String) extends PaymentResult

  /**
   * 支払いを処理
   */
  def processPayment(employee: Employee, amount: Money): PaymentResult =
    employee.paymentMethod match
      case PaymentMethod.Hold =>
        HeldPayment(employee.id, amount)
      case PaymentMethod.DirectDeposit(account) =>
        DirectDepositPayment(employee.id, amount, account)
      case PaymentMethod.Mail(address) =>
        MailedPayment(employee.id, amount, address)

  // ============================================================
  // 10. 給与支払い実行
  // ============================================================

  /**
   * 給与支払いを実行
   */
  def runPayroll(employees: Seq[Employee], context: PayrollContext, date: PayDate): Seq[PaymentResult] =
    employees
      .filter(isPayDay(_, date))
      .map { emp =>
        val pay = calculatePay(emp, context)
        processPayment(emp, pay)
      }

  // ============================================================
  // 11. 従業員変更操作
  // ============================================================

  /**
   * 従業員更新操作
   */
  object EmployeeOperations:
    def changePaymentMethod(employee: Employee, method: PaymentMethod): Employee =
      employee.copy(paymentMethod = method)

    def changeAddress(employee: Employee, address: String): Employee =
      employee.copy(address = Some(address))

    def changeName(employee: Employee, name: String): Employee =
      employee.copy(name = name)

    def changeToSalaried(employee: Employee, salary: Money): Employee =
      employee.copy(payClass = Salaried(salary), schedule = Schedule.Monthly)

    def changeToHourly(employee: Employee, hourlyRate: Money): Employee =
      employee.copy(payClass = Hourly(hourlyRate), schedule = Schedule.Weekly)

    def changeToCommissioned(employee: Employee, basePay: Money, commissionRate: Rate): Employee =
      employee.copy(payClass = Commissioned(basePay, commissionRate), schedule = Schedule.Biweekly)

  // ============================================================
  // 12. 従業員リポジトリ
  // ============================================================

  /**
   * 従業員リポジトリ
   */
  trait EmployeeRepository:
    def findById(id: EmployeeId): Option[Employee]
    def findAll: Seq[Employee]
    def save(employee: Employee): Employee
    def delete(id: EmployeeId): Option[Employee]

  /**
   * インメモリ従業員リポジトリ
   */
  class InMemoryEmployeeRepository extends EmployeeRepository:
    private var employees: Map[EmployeeId, Employee] = Map.empty

    def findById(id: EmployeeId): Option[Employee] = employees.get(id)
    def findAll: Seq[Employee] = employees.values.toSeq
    def save(employee: Employee): Employee =
      employees = employees + (employee.id -> employee)
      employee
    def delete(id: EmployeeId): Option[Employee] =
      val emp = employees.get(id)
      employees = employees - id
      emp
    def clear(): Unit = employees = Map.empty

  // ============================================================
  // 13. 給与明細
  // ============================================================

  /**
   * 給与明細
   */
  case class Payslip(
    employeeId: EmployeeId,
    employeeName: String,
    payPeriod: String,
    grossPay: Money,
    deductions: Map[String, Money] = Map.empty,
    netPay: Money
  ):
    def addDeduction(name: String, amount: Money): Payslip =
      val newDeductions = deductions + (name -> amount)
      val newNetPay = grossPay - newDeductions.values.sum
      copy(deductions = newDeductions, netPay = newNetPay)

  object Payslip:
    def create(employee: Employee, payPeriod: String, grossPay: Money): Payslip =
      Payslip(employee.id, employee.name, payPeriod, grossPay, Map.empty, grossPay)

  // ============================================================
  // 14. 控除計算
  // ============================================================

  /**
   * 控除タイプ
   */
  sealed trait Deduction:
    def name: String
    def calculate(grossPay: Money): Money

  case class FixedDeduction(name: String, amount: Money) extends Deduction:
    def calculate(grossPay: Money): Money = amount

  case class PercentageDeduction(name: String, rate: Rate) extends Deduction:
    def calculate(grossPay: Money): Money = grossPay * BigDecimal(rate)

  case class TieredDeduction(name: String, tiers: List[(Money, Rate)]) extends Deduction:
    def calculate(grossPay: Money): Money =
      var remaining = grossPay
      var total = BigDecimal(0)
      val sortedTiers = tiers.sortBy(_._1)
      var prevThreshold = BigDecimal(0)
      for (threshold, rate) <- sortedTiers do
        val taxableInTier = (remaining min (threshold - prevThreshold)) max BigDecimal(0)
        total += taxableInTier * BigDecimal(rate)
        remaining -= taxableInTier
        prevThreshold = threshold
      total

  /**
   * 控除を適用
   */
  def applyDeductions(payslip: Payslip, deductions: Seq[Deduction]): Payslip =
    deductions.foldLeft(payslip) { (ps, ded) =>
      ps.addDeduction(ded.name, ded.calculate(ps.grossPay))
    }

  // ============================================================
  // 15. 給与計算サービス
  // ============================================================

  /**
   * 給与計算サービス
   */
  class PayrollService(
    repository: EmployeeRepository,
    deductions: Seq[Deduction] = Seq.empty
  ):
    def addEmployee(employee: Employee): Employee =
      repository.save(employee)

    def removeEmployee(id: EmployeeId): Option[Employee] =
      repository.delete(id)

    def getEmployee(id: EmployeeId): Option[Employee] =
      repository.findById(id)

    def updateEmployee(id: EmployeeId, f: Employee => Employee): Option[Employee] =
      repository.findById(id).map { emp =>
        repository.save(f(emp))
      }

    def runPayroll(context: PayrollContext, date: PayDate, payPeriod: String): Seq[Payslip] =
      val employees = repository.findAll
      employees
        .filter(isPayDay(_, date))
        .map { emp =>
          val grossPay = calculatePay(emp, context)
          val payslip = Payslip.create(emp, payPeriod, grossPay)
          applyDeductions(payslip, deductions)
        }

  // ============================================================
  // 16. イベントソーシング風の操作履歴
  // ============================================================

  /**
   * 給与計算イベント
   */
  sealed trait PayrollEvent:
    def timestamp: Long
    def employeeId: EmployeeId

  case class EmployeeAdded(timestamp: Long, employeeId: EmployeeId, employee: Employee) extends PayrollEvent
  case class EmployeeRemoved(timestamp: Long, employeeId: EmployeeId) extends PayrollEvent
  case class EmployeeUpdated(timestamp: Long, employeeId: EmployeeId, employee: Employee) extends PayrollEvent
  case class TimeCardAdded(timestamp: Long, employeeId: EmployeeId, timeCard: TimeCard) extends PayrollEvent
  case class SalesReceiptAdded(timestamp: Long, employeeId: EmployeeId, salesReceipt: SalesReceipt) extends PayrollEvent
  case class PayrollRun(timestamp: Long, employeeId: EmployeeId, amount: Money) extends PayrollEvent

  /**
   * イベントストア
   */
  class EventStore:
    private var events: List[PayrollEvent] = Nil

    def append(event: PayrollEvent): Unit =
      events = event :: events

    def getEvents: List[PayrollEvent] = events.reverse

    def getEventsByEmployee(employeeId: EmployeeId): List[PayrollEvent] =
      events.filter(_.employeeId == employeeId).reverse

    def clear(): Unit = events = Nil

  // ============================================================
  // 17. レポート生成
  // ============================================================

  /**
   * 給与レポート
   */
  case class PayrollReport(
    payPeriod: String,
    totalGrossPay: Money,
    totalDeductions: Money,
    totalNetPay: Money,
    employeeCount: Int,
    payslips: Seq[Payslip]
  )

  object PayrollReport:
    def generate(payPeriod: String, payslips: Seq[Payslip]): PayrollReport =
      val totalGross = payslips.map(_.grossPay).sum
      val totalDeductions = payslips.flatMap(_.deductions.values).sum
      val totalNet = payslips.map(_.netPay).sum
      PayrollReport(payPeriod, totalGross, totalDeductions, totalNet, payslips.length, payslips)

  // ============================================================
  // 18. DSL for payroll configuration
  // ============================================================

  /**
   * 給与計算 DSL
   */
  object PayrollDSL:
    def employee(id: EmployeeId)(name: String): EmployeeBuilder =
      EmployeeBuilder(id, name)

    case class EmployeeBuilder(
      id: EmployeeId,
      name: String,
      payClass: Option[PayClass] = None,
      schedule: Option[Schedule] = None,
      paymentMethod: PaymentMethod = PaymentMethod.Hold
    ):
      def salaried(salary: Money): EmployeeBuilder =
        copy(payClass = Some(Salaried(salary)), schedule = Some(Schedule.Monthly))

      def hourly(rate: Money): EmployeeBuilder =
        copy(payClass = Some(Hourly(rate)), schedule = Some(Schedule.Weekly))

      def commissioned(basePay: Money, commissionRate: Rate): EmployeeBuilder =
        copy(payClass = Some(Commissioned(basePay, commissionRate)), schedule = Some(Schedule.Biweekly))

      def withDirectDeposit(account: String): EmployeeBuilder =
        copy(paymentMethod = PaymentMethod.DirectDeposit(account))

      def withMailPayment(address: String): EmployeeBuilder =
        copy(paymentMethod = PaymentMethod.Mail(address))

      def build: Employee =
        Employee(
          id,
          name,
          payClass.getOrElse(throw new IllegalStateException("PayClass not set")),
          schedule.getOrElse(Schedule.Monthly),
          paymentMethod
        )
