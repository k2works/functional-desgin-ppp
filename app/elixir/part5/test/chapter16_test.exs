defmodule Chapter16Test do
  use ExUnit.Case, async: false
  doctest Chapter16

  alias Chapter16.{Employee, Classification, Schedule, Payment, Payroll, EmployeeRepository, Transaction, PayrollService}

  # ============================================================
  # Employee Tests
  # ============================================================

  describe "Employee" do
    test "make_salaried/3 creates a salaried employee" do
      e = Employee.make_salaried("E001", "田中太郎", 500_000)

      assert e.id == "E001"
      assert e.name == "田中太郎"
      assert Employee.get_pay_type(e) == :salaried
      assert e.schedule == :monthly
      assert e.payment_method == :hold
    end

    test "make_hourly/3 creates an hourly employee" do
      e = Employee.make_hourly("E002", "佐藤花子", 1500)

      assert e.id == "E002"
      assert Employee.get_pay_type(e) == :hourly
      assert e.schedule == :weekly
    end

    test "make_commissioned/4 creates a commissioned employee" do
      e = Employee.make_commissioned("E003", "鈴木一郎", 200_000, 0.1)

      assert e.id == "E003"
      assert Employee.get_pay_type(e) == :commissioned
      assert e.schedule == :biweekly
    end

    test "set_address/2 updates employee address" do
      e = Employee.make_salaried("E001", "田中", 500_000)
      updated = Employee.set_address(e, "東京都渋谷区")

      assert updated.address == "東京都渋谷区"
    end

    test "set_payment_method/2 updates payment method" do
      e = Employee.make_salaried("E001", "田中", 500_000)
      updated = Employee.set_payment_method(e, :direct_deposit)

      assert updated.payment_method == :direct_deposit
    end
  end

  # ============================================================
  # Classification Tests
  # ============================================================

  describe "Classification - Salaried" do
    test "calc_pay/2 returns monthly salary" do
      e = Employee.make_salaried("E001", "田中", 500_000)
      ctx = Classification.make_context()

      assert Classification.calc_pay(e, ctx) == 500_000
    end
  end

  describe "Classification - Hourly" do
    test "calc_pay/2 returns 0 when no time cards" do
      e = Employee.make_hourly("E002", "佐藤", 1500)
      ctx = Classification.make_context()

      assert Classification.calc_pay(e, ctx) == 0.0
    end

    test "calc_pay/2 calculates regular hours" do
      e = Employee.make_hourly("E002", "佐藤", 1500)
      ctx =
        Classification.make_context()
        |> Classification.add_time_card("E002", "2024-01-15", 8)
        |> Classification.add_time_card("E002", "2024-01-16", 8)

      # 16 hours * 1500 = 24000
      assert Classification.calc_pay(e, ctx) == 24000.0
    end

    test "calc_pay/2 calculates overtime at 1.5x" do
      e = Employee.make_hourly("E002", "佐藤", 1000)
      ctx =
        Classification.make_context()
        |> Classification.add_time_card("E002", "2024-01-15", 45)

      # 40 * 1000 + 5 * 1000 * 1.5 = 40000 + 7500 = 47500
      assert Classification.calc_pay(e, ctx) == 47500.0
    end
  end

  describe "Classification - Commissioned" do
    test "calc_pay/2 returns base pay when no sales" do
      e = Employee.make_commissioned("E003", "鈴木", 200_000, 0.1)
      ctx = Classification.make_context()

      assert Classification.calc_pay(e, ctx) == 200_000.0
    end

    test "calc_pay/2 adds commission from sales" do
      e = Employee.make_commissioned("E003", "鈴木", 200_000, 0.1)
      ctx =
        Classification.make_context()
        |> Classification.add_sales_receipt("E003", "2024-01-15", 100_000)
        |> Classification.add_sales_receipt("E003", "2024-01-16", 50_000)

      # 200000 + (100000 + 50000) * 0.1 = 200000 + 15000 = 215000
      assert Classification.calc_pay(e, ctx) == 215_000.0
    end
  end

  # ============================================================
  # Schedule Tests
  # ============================================================

  describe "Schedule" do
    test "monthly employees paid on last day of month" do
      e = Employee.make_salaried("E001", "田中", 500_000)

      assert Schedule.is_pay_day?(e, Schedule.end_of_month(2024, 1))
      refute Schedule.is_pay_day?(e, Schedule.make_date(2024, 1, 15))
    end

    test "weekly employees paid on Fridays" do
      e = Employee.make_hourly("E002", "佐藤", 1500)

      assert Schedule.is_pay_day?(e, Schedule.friday(2024, 1, 19))
      refute Schedule.is_pay_day?(e, Schedule.make_date(2024, 1, 18, :thursday))
    end

    test "biweekly employees paid on pay week Fridays" do
      e = Employee.make_commissioned("E003", "鈴木", 200_000, 0.1)

      assert Schedule.is_pay_day?(e, Schedule.pay_friday(2024, 1, 19))
      refute Schedule.is_pay_day?(e, Schedule.friday(2024, 1, 12))
    end

    test "end_of_month handles February" do
      feb_date = Schedule.end_of_month(2024, 2)
      assert feb_date.day == 29  # 2024 is a leap year

      feb_date_2023 = Schedule.end_of_month(2023, 2)
      assert feb_date_2023.day == 28
    end
  end

  # ============================================================
  # Payment Tests
  # ============================================================

  describe "Payment" do
    test "process/2 with :hold returns hold result" do
      e = Employee.make_salaried("E001", "田中", 500_000)
      result = Payment.process(e, 500_000)

      assert result.type == :hold
      assert result.employee_id == "E001"
      assert result.amount == 500_000
    end

    test "process/2 with :direct_deposit returns deposit result" do
      e = Employee.make_salaried("E001", "田中", 500_000)
             |> Employee.set_payment_method(:direct_deposit)
      result = Payment.process(e, 500_000)

      assert result.type == :direct_deposit
    end

    test "process/2 with :mail returns mail result" do
      e = Employee.make_salaried("E001", "田中", 500_000)
             |> Employee.set_payment_method(:mail)
      result = Payment.process(e, 500_000)

      assert result.type == :mail
    end
  end

  # ============================================================
  # Payroll Tests
  # ============================================================

  describe "Payroll" do
    test "calculate_payroll/2 calculates for all employees" do
      employees = [
        Employee.make_salaried("E001", "田中", 500_000),
        Employee.make_hourly("E002", "佐藤", 1500)
      ]
      ctx =
        Classification.make_context()
        |> Classification.add_time_card("E002", "2024-01-15", 40)

      payroll = Payroll.calculate_payroll(employees, ctx)

      assert length(payroll) == 2
      assert Enum.sum(Enum.map(payroll, & &1.pay)) == 560_000.0
    end

    test "payroll_report/2 generates report" do
      employees = [
        Employee.make_salaried("E001", "田中", 500_000),
        Employee.make_hourly("E002", "佐藤", 1500)
      ]
      ctx =
        Classification.make_context()
        |> Classification.add_time_card("E002", "2024-01-15", 40)

      report = Payroll.payroll_report(employees, ctx)

      assert report.count == 2
      assert report.total == 560_000.0
    end

    test "run_payroll/3 only pays employees on pay day" do
      employees = [
        Employee.make_salaried("E001", "田中", 500_000),
        Employee.make_hourly("E002", "佐藤", 1500)
      ]
      ctx =
        Classification.make_context()
        |> Classification.add_time_card("E002", "2024-01-15", 40)

      # Friday - only hourly employee gets paid
      friday = Schedule.friday(2024, 1, 19)
      payments = Payroll.run_payroll(employees, ctx, friday)

      assert length(payments) == 1
      assert hd(payments).employee_id == "E002"
    end
  end

  # ============================================================
  # EmployeeRepository Tests
  # ============================================================

  describe "EmployeeRepository" do
    setup do
      {:ok, repo} = EmployeeRepository.start_link()
      on_exit(fn -> EmployeeRepository.stop(repo) end)
      %{repo: repo}
    end

    test "add/2 and get/2 work", %{repo: repo} do
      employee = Employee.make_salaried("E001", "田中", 500_000)
      {:ok, _} = EmployeeRepository.add(repo, employee)

      assert {:ok, e} = EmployeeRepository.get(repo, "E001")
      assert e.name == "田中"
    end

    test "get/2 returns error for non-existent employee", %{repo: repo} do
      assert {:error, :not_found} = EmployeeRepository.get(repo, "NONEXISTENT")
    end

    test "get_all/1 returns all employees", %{repo: repo} do
      EmployeeRepository.add(repo, Employee.make_salaried("E001", "田中", 500_000))
      EmployeeRepository.add(repo, Employee.make_hourly("E002", "佐藤", 1500))

      employees = EmployeeRepository.get_all(repo)
      assert length(employees) == 2
    end

    test "update/3 updates employee", %{repo: repo} do
      EmployeeRepository.add(repo, Employee.make_salaried("E001", "田中", 500_000))

      {:ok, updated} = EmployeeRepository.update(repo, "E001", &Employee.set_address(&1, "東京"))

      assert updated.address == "東京"
    end

    test "delete/2 removes employee", %{repo: repo} do
      EmployeeRepository.add(repo, Employee.make_salaried("E001", "田中", 500_000))

      {:ok, _} = EmployeeRepository.delete(repo, "E001")

      assert {:error, :not_found} = EmployeeRepository.get(repo, "E001")
    end
  end

  # ============================================================
  # Transaction Tests
  # ============================================================

  describe "Transaction" do
    setup do
      {:ok, repo} = EmployeeRepository.start_link()
      on_exit(fn -> EmployeeRepository.stop(repo) end)
      %{repo: repo}
    end

    test "add_employee/2 adds employee to repo", %{repo: repo} do
      employee = Employee.make_salaried("E001", "田中", 500_000)
      {:ok, _} = Transaction.add_employee(repo, employee)

      assert {:ok, _} = EmployeeRepository.get(repo, "E001")
    end

    test "delete_employee/2 removes employee", %{repo: repo} do
      employee = Employee.make_salaried("E001", "田中", 500_000)
      EmployeeRepository.add(repo, employee)

      {:ok, _} = Transaction.delete_employee(repo, "E001")

      assert {:error, :not_found} = EmployeeRepository.get(repo, "E001")
    end

    test "add_time_card/4 adds time card to context" do
      ctx = Classification.make_context()
      ctx = Transaction.add_time_card(ctx, "E001", "2024-01-15", 8)

      assert get_in(ctx, [:time_cards, "E001"]) == [{"2024-01-15", 8}]
    end

    test "add_sales_receipt/4 adds receipt to context" do
      ctx = Classification.make_context()
      ctx = Transaction.add_sales_receipt(ctx, "E001", "2024-01-15", 10_000)

      assert get_in(ctx, [:sales_receipts, "E001"]) == [{"2024-01-15", 10_000}]
    end

    test "change_payment_method/3 updates employee payment method", %{repo: repo} do
      employee = Employee.make_salaried("E001", "田中", 500_000)
      EmployeeRepository.add(repo, employee)

      {:ok, updated} = Transaction.change_payment_method(repo, "E001", :direct_deposit)

      assert updated.payment_method == :direct_deposit
    end
  end

  # ============================================================
  # PayrollService Tests
  # ============================================================

  describe "PayrollService" do
    setup do
      service = PayrollService.new()
      on_exit(fn -> PayrollService.stop(service) end)
      %{service: service}
    end

    test "add_salaried_employee/4 adds employee", %{service: service} do
      {:ok, employee} = PayrollService.add_salaried_employee(service, "E001", "田中", 500_000)

      assert employee.name == "田中"
      assert {:ok, _} = PayrollService.get_employee(service, "E001")
    end

    test "add_hourly_employee/4 adds employee", %{service: service} do
      {:ok, employee} = PayrollService.add_hourly_employee(service, "E002", "佐藤", 1500)

      assert Employee.get_pay_type(employee) == :hourly
    end

    test "add_commissioned_employee/5 adds employee", %{service: service} do
      {:ok, employee} = PayrollService.add_commissioned_employee(service, "E003", "鈴木", 200_000, 0.1)

      assert Employee.get_pay_type(employee) == :commissioned
    end

    test "add_time_card/4 updates context", %{service: service} do
      PayrollService.add_hourly_employee(service, "E002", "佐藤", 1500)
      service = PayrollService.add_time_card(service, "E002", "2024-01-15", 8)

      assert {:ok, pay} = PayrollService.calculate_pay(service, "E002")
      assert pay == 12000.0
    end

    test "add_sales_receipt/4 updates context", %{service: service} do
      PayrollService.add_commissioned_employee(service, "E003", "鈴木", 200_000, 0.1)
      service = PayrollService.add_sales_receipt(service, "E003", "2024-01-15", 100_000)

      assert {:ok, pay} = PayrollService.calculate_pay(service, "E003")
      assert pay == 210_000.0
    end

    test "payroll_report/1 generates report", %{service: service} do
      PayrollService.add_salaried_employee(service, "E001", "田中", 500_000)
      PayrollService.add_hourly_employee(service, "E002", "佐藤", 1500)

      report = PayrollService.payroll_report(service)

      assert report.count == 2
    end

    test "run_payroll/2 pays employees on pay day", %{service: service} do
      PayrollService.add_salaried_employee(service, "E001", "田中", 500_000)

      # End of month - salaried employee gets paid
      end_of_month = Schedule.end_of_month(2024, 1)
      payments = PayrollService.run_payroll(service, end_of_month)

      assert length(payments) == 1
      assert hd(payments).employee_id == "E001"
    end
  end

  # ============================================================
  # Integration Tests
  # ============================================================

  describe "Integration" do
    test "complete payroll workflow" do
      service = PayrollService.new()

      try do
        # Add employees
        PayrollService.add_salaried_employee(service, "E001", "田中太郎", 500_000)
        PayrollService.add_hourly_employee(service, "E002", "佐藤花子", 1500)
        PayrollService.add_commissioned_employee(service, "E003", "鈴木一郎", 200_000, 0.1)

        # Change payment methods
        PayrollService.change_payment_method(service, "E001", :direct_deposit)
        PayrollService.change_payment_method(service, "E002", :direct_deposit)
        PayrollService.change_payment_method(service, "E003", :mail)

        # Add time cards and sales receipts
        service = PayrollService.add_time_card(service, "E002", "2024-01-15", 8)
        service = PayrollService.add_time_card(service, "E002", "2024-01-16", 8)
        service = PayrollService.add_time_card(service, "E002", "2024-01-17", 8)
        service = PayrollService.add_time_card(service, "E002", "2024-01-18", 8)
        service = PayrollService.add_time_card(service, "E002", "2024-01-19", 8)

        service = PayrollService.add_sales_receipt(service, "E003", "2024-01-10", 50_000)
        service = PayrollService.add_sales_receipt(service, "E003", "2024-01-15", 75_000)

        # Generate report
        report = PayrollService.payroll_report(service)

        assert report.count == 3
        # E001: 500000, E002: 40 * 1500 = 60000, E003: 200000 + 125000 * 0.1 = 212500
        assert report.total == 772_500.0

        # Run payroll for end of month (salaried gets paid)
        end_of_month = Schedule.end_of_month(2024, 1)
        payments = PayrollService.run_payroll(service, end_of_month)

        salaried_payment = Enum.find(payments, &(&1.employee_id == "E001"))
        assert salaried_payment.type == :direct_deposit
        assert salaried_payment.amount == 500_000
      after
        PayrollService.stop(service)
      end
    end
  end
end
