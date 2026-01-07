import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import PayrollSystem.*

class PayrollSystemSpec extends AnyFunSpec with Matchers:

  // ============================================================
  // 1. 従業員作成
  // ============================================================

  describe("Employee"):

    describe("ファクトリメソッド"):
      it("月給制従業員を作成できる"):
        val emp = Employee.salaried("E001", "田中太郎", BigDecimal(500000))
        emp.id shouldBe "E001"
        emp.name shouldBe "田中太郎"
        emp.payClass shouldBe Salaried(BigDecimal(500000))
        emp.schedule shouldBe Schedule.Monthly
        emp.paymentMethod shouldBe PaymentMethod.Hold

      it("時給制従業員を作成できる"):
        val emp = Employee.hourly("E002", "佐藤花子", BigDecimal(1500))
        emp.payClass shouldBe Hourly(BigDecimal(1500))
        emp.schedule shouldBe Schedule.Weekly

      it("歩合制従業員を作成できる"):
        val emp = Employee.commissioned("E003", "鈴木一郎", BigDecimal(200000), 0.1)
        emp.payClass shouldBe Commissioned(BigDecimal(200000), 0.1)
        emp.schedule shouldBe Schedule.Biweekly

  // ============================================================
  // 2. 給与計算
  // ============================================================

  describe("給与計算"):

    describe("月給制"):
      it("固定給与を返す"):
        val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
        val ctx = PayrollContext.empty
        calculatePay(emp, ctx) shouldBe BigDecimal(500000)

    describe("時給制"):
      it("労働時間に基づいて計算する"):
        val emp = Employee.hourly("E002", "佐藤", BigDecimal(1500))
        val ctx = PayrollContext.empty
          .addTimeCard(TimeCard("E002", "2024-01-15", 8))
          .addTimeCard(TimeCard("E002", "2024-01-16", 8))
        calculatePay(emp, ctx) shouldBe BigDecimal(24000) // 16時間 * 1500

      it("残業時間は1.5倍で計算する"):
        val emp = Employee.hourly("E002", "佐藤", BigDecimal(1000))
        val ctx = PayrollContext.empty
          .addTimeCard(TimeCard("E002", "2024-01-15", 45))
        // 40 * 1000 + 5 * 1000 * 1.5 = 47500
        calculatePay(emp, ctx) shouldBe BigDecimal(47500)

      it("タイムカードがない場合は0"):
        val emp = Employee.hourly("E002", "佐藤", BigDecimal(1500))
        val ctx = PayrollContext.empty
        calculatePay(emp, ctx) shouldBe BigDecimal(0)

    describe("歩合制"):
      it("基本給 + 売上 * コミッション率で計算する"):
        val emp = Employee.commissioned("E003", "鈴木", BigDecimal(200000), 0.1)
        val ctx = PayrollContext.empty
          .addSalesReceipt(SalesReceipt("E003", "2024-01-15", BigDecimal(100000)))
          .addSalesReceipt(SalesReceipt("E003", "2024-01-16", BigDecimal(50000)))
        // 200000 + 150000 * 0.1 = 215000
        calculatePay(emp, ctx) shouldBe BigDecimal(215000)

      it("売上がない場合は基本給のみ"):
        val emp = Employee.commissioned("E003", "鈴木", BigDecimal(200000), 0.1)
        val ctx = PayrollContext.empty
        calculatePay(emp, ctx) shouldBe BigDecimal(200000)

  // ============================================================
  // 3. 支払いスケジュール
  // ============================================================

  describe("支払いスケジュール"):

    describe("月次（月末）"):
      it("月末は支払日"):
        val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
        val date = PayDate(2024, 1, 31, DayOfWeek.Wednesday, isLastDayOfMonth = true)
        isPayDay(emp, date) shouldBe true

      it("月末以外は支払日ではない"):
        val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
        val date = PayDate(2024, 1, 15, DayOfWeek.Monday, isLastDayOfMonth = false)
        isPayDay(emp, date) shouldBe false

    describe("週次（金曜日）"):
      it("金曜日は支払日"):
        val emp = Employee.hourly("E002", "佐藤", BigDecimal(1500))
        val date = PayDate(2024, 1, 19, DayOfWeek.Friday, isLastDayOfMonth = false)
        isPayDay(emp, date) shouldBe true

      it("金曜日以外は支払日ではない"):
        val emp = Employee.hourly("E002", "佐藤", BigDecimal(1500))
        val date = PayDate(2024, 1, 18, DayOfWeek.Thursday, isLastDayOfMonth = false)
        isPayDay(emp, date) shouldBe false

    describe("隔週（隔週金曜日）"):
      it("支払週の金曜日は支払日"):
        val emp = Employee.commissioned("E003", "鈴木", BigDecimal(200000), 0.1)
        val date = PayDate(2024, 1, 19, DayOfWeek.Friday, isLastDayOfMonth = false, isPayWeek = true)
        isPayDay(emp, date) shouldBe true

      it("支払週でない金曜日は支払日ではない"):
        val emp = Employee.commissioned("E003", "鈴木", BigDecimal(200000), 0.1)
        val date = PayDate(2024, 1, 26, DayOfWeek.Friday, isLastDayOfMonth = false, isPayWeek = false)
        isPayDay(emp, date) shouldBe false

  // ============================================================
  // 4. 支払い処理
  // ============================================================

  describe("支払い処理"):

    it("保留の場合は HeldPayment を返す"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
      val result = processPayment(emp, BigDecimal(500000))
      result shouldBe HeldPayment("E001", BigDecimal(500000))

    it("口座振込の場合は DirectDepositPayment を返す"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
        .copy(paymentMethod = PaymentMethod.DirectDeposit("1234567890"))
      val result = processPayment(emp, BigDecimal(500000))
      result shouldBe DirectDepositPayment("E001", BigDecimal(500000), "1234567890")

    it("郵送の場合は MailedPayment を返す"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
        .copy(paymentMethod = PaymentMethod.Mail("東京都渋谷区1-1-1"))
      val result = processPayment(emp, BigDecimal(500000))
      result shouldBe MailedPayment("E001", BigDecimal(500000), "東京都渋谷区1-1-1")

  // ============================================================
  // 5. 給与支払い実行
  // ============================================================

  describe("給与支払い実行"):

    it("支払日の従業員にのみ支払う"):
      val salaried = Employee.salaried("E001", "田中", BigDecimal(500000))
      val hourly = Employee.hourly("E002", "佐藤", BigDecimal(1500))

      val ctx = PayrollContext.empty
        .addTimeCard(TimeCard("E002", "2024-01-15", 40))

      // 月末（月給制の支払日）
      val monthEndDate = PayDate(2024, 1, 31, DayOfWeek.Wednesday, isLastDayOfMonth = true)
      val results = runPayroll(Seq(salaried, hourly), ctx, monthEndDate)

      results should have length 1
      results.head.employeeId shouldBe "E001"

    it("金曜日には時給制従業員に支払う"):
      val salaried = Employee.salaried("E001", "田中", BigDecimal(500000))
      val hourly = Employee.hourly("E002", "佐藤", BigDecimal(1500))

      val ctx = PayrollContext.empty
        .addTimeCard(TimeCard("E002", "2024-01-15", 40))

      val fridayDate = PayDate(2024, 1, 19, DayOfWeek.Friday, isLastDayOfMonth = false)
      val results = runPayroll(Seq(salaried, hourly), ctx, fridayDate)

      results should have length 1
      results.head.employeeId shouldBe "E002"
      results.head.amount shouldBe BigDecimal(60000) // 40 * 1500

  // ============================================================
  // 6. 従業員操作
  // ============================================================

  describe("EmployeeOperations"):

    import EmployeeOperations.*

    it("支払い方法を変更できる"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
      val updated = changePaymentMethod(emp, PaymentMethod.DirectDeposit("123456"))
      updated.paymentMethod shouldBe PaymentMethod.DirectDeposit("123456")

    it("住所を変更できる"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
      val updated = changeAddress(emp, "東京都")
      updated.address shouldBe Some("東京都")

    it("月給制に変更できる"):
      val emp = Employee.hourly("E001", "田中", BigDecimal(1500))
      val updated = changeToSalaried(emp, BigDecimal(500000))
      updated.payClass shouldBe Salaried(BigDecimal(500000))
      updated.schedule shouldBe Schedule.Monthly

    it("時給制に変更できる"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
      val updated = changeToHourly(emp, BigDecimal(1500))
      updated.payClass shouldBe Hourly(BigDecimal(1500))
      updated.schedule shouldBe Schedule.Weekly

  // ============================================================
  // 7. 従業員リポジトリ
  // ============================================================

  describe("InMemoryEmployeeRepository"):

    it("従業員を保存して取得できる"):
      val repo = new InMemoryEmployeeRepository
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))

      repo.save(emp)
      repo.findById("E001") shouldBe Some(emp)

    it("全従業員を取得できる"):
      val repo = new InMemoryEmployeeRepository
      repo.save(Employee.salaried("E001", "田中", BigDecimal(500000)))
      repo.save(Employee.hourly("E002", "佐藤", BigDecimal(1500)))

      repo.findAll should have length 2

    it("従業員を削除できる"):
      val repo = new InMemoryEmployeeRepository
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))

      repo.save(emp)
      repo.delete("E001") shouldBe Some(emp)
      repo.findById("E001") shouldBe None

  // ============================================================
  // 8. 給与明細
  // ============================================================

  describe("Payslip"):

    it("給与明細を作成できる"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
      val payslip = Payslip.create(emp, "2024-01", BigDecimal(500000))

      payslip.employeeId shouldBe "E001"
      payslip.grossPay shouldBe BigDecimal(500000)
      payslip.netPay shouldBe BigDecimal(500000)

    it("控除を追加できる"):
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
      val payslip = Payslip.create(emp, "2024-01", BigDecimal(500000))
        .addDeduction("所得税", BigDecimal(50000))
        .addDeduction("社会保険", BigDecimal(30000))

      payslip.deductions should have size 2
      payslip.netPay shouldBe BigDecimal(420000)

  // ============================================================
  // 9. 控除計算
  // ============================================================

  describe("Deduction"):

    describe("FixedDeduction"):
      it("固定額を控除する"):
        val ded = FixedDeduction("健康保険", BigDecimal(10000))
        ded.calculate(BigDecimal(500000)) shouldBe BigDecimal(10000)

    describe("PercentageDeduction"):
      it("割合で控除する"):
        val ded = PercentageDeduction("所得税", 0.1)
        ded.calculate(BigDecimal(500000)) shouldBe BigDecimal(50000)

    describe("applyDeductions"):
      it("複数の控除を適用できる"):
        val emp = Employee.salaried("E001", "田中", BigDecimal(500000))
        val payslip = Payslip.create(emp, "2024-01", BigDecimal(500000))
        val deductions = Seq(
          FixedDeduction("健康保険", BigDecimal(10000)),
          PercentageDeduction("所得税", 0.1)
        )
        val result = applyDeductions(payslip, deductions)

        result.deductions should have size 2
        result.netPay shouldBe BigDecimal(440000) // 500000 - 10000 - 50000

  // ============================================================
  // 10. 給与計算サービス
  // ============================================================

  describe("PayrollService"):

    it("従業員を追加できる"):
      val repo = new InMemoryEmployeeRepository
      val service = new PayrollService(repo)
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))

      service.addEmployee(emp)
      service.getEmployee("E001") shouldBe Some(emp)

    it("従業員を更新できる"):
      val repo = new InMemoryEmployeeRepository
      val service = new PayrollService(repo)
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))

      service.addEmployee(emp)
      service.updateEmployee("E001", _.copy(name = "田中太郎"))

      service.getEmployee("E001").get.name shouldBe "田中太郎"

    it("給与支払いを実行できる"):
      val repo = new InMemoryEmployeeRepository
      val deductions = Seq(PercentageDeduction("所得税", 0.1))
      val service = new PayrollService(repo, deductions)

      service.addEmployee(Employee.salaried("E001", "田中", BigDecimal(500000)))

      val ctx = PayrollContext.empty
      val date = PayDate(2024, 1, 31, DayOfWeek.Wednesday, isLastDayOfMonth = true)
      val payslips = service.runPayroll(ctx, date, "2024-01")

      payslips should have length 1
      payslips.head.grossPay shouldBe BigDecimal(500000)
      payslips.head.netPay shouldBe BigDecimal(450000) // 500000 - 50000

  // ============================================================
  // 11. イベントストア
  // ============================================================

  describe("EventStore"):

    it("イベントを追加して取得できる"):
      val store = new EventStore
      val emp = Employee.salaried("E001", "田中", BigDecimal(500000))

      store.append(EmployeeAdded(1000L, "E001", emp))
      store.append(TimeCardAdded(2000L, "E001", TimeCard("E001", "2024-01-15", 8)))

      store.getEvents should have length 2

    it("従業員別にイベントを取得できる"):
      val store = new EventStore
      val emp1 = Employee.salaried("E001", "田中", BigDecimal(500000))
      val emp2 = Employee.hourly("E002", "佐藤", BigDecimal(1500))

      store.append(EmployeeAdded(1000L, "E001", emp1))
      store.append(EmployeeAdded(2000L, "E002", emp2))
      store.append(TimeCardAdded(3000L, "E001", TimeCard("E001", "2024-01-15", 8)))

      store.getEventsByEmployee("E001") should have length 2

  // ============================================================
  // 12. レポート生成
  // ============================================================

  describe("PayrollReport"):

    it("給与レポートを生成できる"):
      val emp1 = Employee.salaried("E001", "田中", BigDecimal(500000))
      val emp2 = Employee.salaried("E002", "佐藤", BigDecimal(400000))

      val payslip1 = Payslip.create(emp1, "2024-01", BigDecimal(500000))
        .addDeduction("所得税", BigDecimal(50000))
      val payslip2 = Payslip.create(emp2, "2024-01", BigDecimal(400000))
        .addDeduction("所得税", BigDecimal(40000))

      val report = PayrollReport.generate("2024-01", Seq(payslip1, payslip2))

      report.totalGrossPay shouldBe BigDecimal(900000)
      report.totalDeductions shouldBe BigDecimal(90000)
      report.totalNetPay shouldBe BigDecimal(810000)
      report.employeeCount shouldBe 2

  // ============================================================
  // 13. DSL
  // ============================================================

  describe("PayrollDSL"):

    import PayrollDSL.*

    it("DSLで従業員を作成できる"):
      val emp = employee("E001")("田中太郎")
        .salaried(BigDecimal(500000))
        .withDirectDeposit("1234567890")
        .build

      emp.id shouldBe "E001"
      emp.name shouldBe "田中太郎"
      emp.payClass shouldBe Salaried(BigDecimal(500000))
      emp.paymentMethod shouldBe PaymentMethod.DirectDeposit("1234567890")

    it("時給制従業員をDSLで作成できる"):
      val emp = employee("E002")("佐藤花子")
        .hourly(BigDecimal(1500))
        .build

      emp.payClass shouldBe Hourly(BigDecimal(1500))
      emp.schedule shouldBe Schedule.Weekly

    it("歩合制従業員をDSLで作成できる"):
      val emp = employee("E003")("鈴木一郎")
        .commissioned(BigDecimal(200000), 0.1)
        .withMailPayment("東京都渋谷区")
        .build

      emp.payClass shouldBe Commissioned(BigDecimal(200000), 0.1)
      emp.paymentMethod shouldBe PaymentMethod.Mail("東京都渋谷区")
