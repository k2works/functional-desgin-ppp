defmodule Chapter16 do
  @moduledoc """
  # Chapter 16: 給与計算システム

  従業員の給与計算と支払い処理を統合的に管理するシステムです。
  マルチメソッド（プロトコル）による多態性を活用して、
  異なる給与タイプに対応した計算ロジックを実装します。

  ## 主なトピック

  1. 従業員モデル（月給制、時給制、歩合制）
  2. 給与計算（残業、コミッション）
  3. 支払いスケジュール（月次、週次、隔週）
  4. 支払い処理（保留、口座振込、郵送）
  """

  # ============================================================
  # 1. 従業員モデル
  # ============================================================

  defmodule Employee do
    @moduledoc "従業員の構造体"

    @type pay_type :: :salaried | :hourly | :commissioned
    @type schedule :: :monthly | :weekly | :biweekly
    @type payment_method :: :hold | :direct_deposit | :mail

    defstruct [
      :id,
      :name,
      :address,
      :pay_class,
      :schedule,
      :payment_method
    ]

    @type t :: %__MODULE__{
      id: String.t(),
      name: String.t(),
      address: String.t() | nil,
      pay_class: tuple(),
      schedule: schedule(),
      payment_method: payment_method()
    }

    @doc """
    月給制従業員を作成。

    ## Examples

        iex> e = Chapter16.Employee.make_salaried("E001", "田中太郎", 500_000)
        iex> e.name
        "田中太郎"
        iex> Chapter16.Employee.get_pay_type(e)
        :salaried
    """
    def make_salaried(id, name, salary) do
      %__MODULE__{
        id: id,
        name: name,
        pay_class: {:salaried, salary},
        schedule: :monthly,
        payment_method: :hold
      }
    end

    @doc """
    時給制従業員を作成。

    ## Examples

        iex> e = Chapter16.Employee.make_hourly("E002", "佐藤花子", 1500)
        iex> Chapter16.Employee.get_pay_type(e)
        :hourly
        iex> e.schedule
        :weekly
    """
    def make_hourly(id, name, hourly_rate) do
      %__MODULE__{
        id: id,
        name: name,
        pay_class: {:hourly, hourly_rate},
        schedule: :weekly,
        payment_method: :hold
      }
    end

    @doc """
    歩合制従業員を作成。

    ## Examples

        iex> e = Chapter16.Employee.make_commissioned("E003", "鈴木一郎", 200_000, 0.1)
        iex> Chapter16.Employee.get_pay_type(e)
        :commissioned
        iex> e.schedule
        :biweekly
    """
    def make_commissioned(id, name, base_pay, commission_rate) do
      %__MODULE__{
        id: id,
        name: name,
        pay_class: {:commissioned, base_pay, commission_rate},
        schedule: :biweekly,
        payment_method: :hold
      }
    end

    # Accessors

    def get_id(%__MODULE__{id: id}), do: id
    def get_name(%__MODULE__{name: name}), do: name
    def get_pay_class(%__MODULE__{pay_class: pay_class}), do: pay_class
    def get_schedule(%__MODULE__{schedule: schedule}), do: schedule
    def get_payment_method(%__MODULE__{payment_method: method}), do: method

    @doc "給与タイプを取得"
    def get_pay_type(%__MODULE__{pay_class: {type, _}}), do: type
    def get_pay_type(%__MODULE__{pay_class: {type, _, _}}), do: type

    # Updaters

    def set_address(%__MODULE__{} = employee, address) do
      %{employee | address: address}
    end

    def set_payment_method(%__MODULE__{} = employee, method)
        when method in [:hold, :direct_deposit, :mail] do
      %{employee | payment_method: method}
    end
  end

  # ============================================================
  # 2. 給与計算
  # ============================================================

  defmodule Classification do
    @moduledoc "給与分類と計算ロジック"

    alias Chapter16.Employee

    @doc """
    給与を計算する。

    ## Examples

        iex> e = Chapter16.Employee.make_salaried("E001", "田中", 500_000)
        iex> ctx = Chapter16.Classification.make_context()
        iex> Chapter16.Classification.calc_pay(e, ctx)
        500_000
    """
    def calc_pay(%Employee{pay_class: {:salaried, salary}}, _context) do
      salary
    end

    def calc_pay(%Employee{pay_class: {:hourly, hourly_rate}} = employee, context) do
      time_cards = get_in(context, [:time_cards, Employee.get_id(employee)]) || []
      hours = Enum.map(time_cards, fn {_date, hours} -> hours end)
      total_hours = Enum.sum(hours)

      # 週40時間を超える分は1.5倍
      regular_hours = min(total_hours, 40)
      overtime_hours = max(0, total_hours - 40)

      regular_hours * hourly_rate + overtime_hours * hourly_rate * 1.5
    end

    def calc_pay(%Employee{pay_class: {:commissioned, base_pay, commission_rate}} = employee, context) do
      sales_receipts = get_in(context, [:sales_receipts, Employee.get_id(employee)]) || []
      total_sales = Enum.sum(Enum.map(sales_receipts, fn {_date, amount} -> amount end))

      base_pay + total_sales * commission_rate
    end

    @doc "空のコンテキストを作成"
    def make_context do
      %{
        time_cards: %{},
        sales_receipts: %{}
      }
    end

    @doc "タイムカードを追加"
    def add_time_card(context, employee_id, date, hours) do
      update_in(context, [:time_cards, employee_id], fn
        nil -> [{date, hours}]
        cards -> [{date, hours} | cards]
      end)
    end

    @doc "売上レシートを追加"
    def add_sales_receipt(context, employee_id, date, amount) do
      update_in(context, [:sales_receipts, employee_id], fn
        nil -> [{date, amount}]
        receipts -> [{date, amount} | receipts]
      end)
    end
  end

  # ============================================================
  # 3. 支払いスケジュール
  # ============================================================

  defmodule Schedule do
    @moduledoc "支払いスケジュール判定"

    alias Chapter16.Employee

    @doc """
    指定日が支払日かどうかを判定。
    """
    def is_pay_day?(%Employee{schedule: :monthly}, date) do
      # 月末判定
      is_last_day_of_month?(date)
    end

    def is_pay_day?(%Employee{schedule: :weekly}, date) do
      # 金曜日判定
      Map.get(date, :day_of_week) == :friday
    end

    def is_pay_day?(%Employee{schedule: :biweekly}, date) do
      # 隔週金曜日判定
      Map.get(date, :day_of_week) == :friday and Map.get(date, :is_pay_week, false) == true
    end

    # Helper functions

    defp is_last_day_of_month?(date) do
      last_days = %{
        1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31, 6 => 30,
        7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31
      }

      last_day = Map.get(last_days, date.month, 30)

      # うるう年の2月を考慮
      last_day =
        if date.month == 2 and is_leap_year?(date.year) do
          29
        else
          last_day
        end

      date.day == last_day
    end

    defp is_leap_year?(year) do
      rem(year, 400) == 0 or (rem(year, 4) == 0 and rem(year, 100) != 0)
    end

    # Date factories

    @doc "日付を作成"
    def make_date(year, month, day) do
      %{year: year, month: month, day: day}
    end

    def make_date(year, month, day, day_of_week) do
      %{year: year, month: month, day: day, day_of_week: day_of_week}
    end

    def make_date(year, month, day, day_of_week, is_pay_week) do
      %{year: year, month: month, day: day, day_of_week: day_of_week, is_pay_week: is_pay_week}
    end

    @doc "月末の日付を作成"
    def end_of_month(year, month) do
      last_days = %{
        1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31, 6 => 30,
        7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31
      }

      day = Map.get(last_days, month, 30)

      day =
        if month == 2 and is_leap_year?(year) do
          29
        else
          day
        end

      make_date(year, month, day)
    end

    @doc "金曜日の日付を作成"
    def friday(year, month, day) do
      make_date(year, month, day, :friday)
    end

    @doc "支払い週の金曜日を作成"
    def pay_friday(year, month, day) do
      make_date(year, month, day, :friday, true)
    end
  end

  # ============================================================
  # 4. 支払い処理
  # ============================================================

  defmodule Payment do
    @moduledoc "支払い処理"

    alias Chapter16.Employee

    @doc """
    支払いを処理する。
    """
    def process(%Employee{payment_method: :hold} = employee, amount) do
      %{
        type: :hold,
        employee_id: Employee.get_id(employee),
        amount: amount,
        message: "支払いを保留"
      }
    end

    def process(%Employee{payment_method: :direct_deposit} = employee, amount) do
      %{
        type: :direct_deposit,
        employee_id: Employee.get_id(employee),
        amount: amount,
        message: "口座に振り込み"
      }
    end

    def process(%Employee{payment_method: :mail} = employee, amount) do
      %{
        type: :mail,
        employee_id: Employee.get_id(employee),
        amount: amount,
        message: "小切手を郵送"
      }
    end
  end

  # ============================================================
  # 5. 給与計算システム
  # ============================================================

  defmodule Payroll do
    @moduledoc "給与計算システム"

    alias Chapter16.{Employee, Classification, Schedule, Payment}

    @doc """
    従業員の給与を計算。
    """
    def calculate_pay(employee, context) do
      Classification.calc_pay(employee, context)
    end

    @doc """
    全従業員の給与を計算。
    """
    def calculate_payroll(employees, context) do
      Enum.map(employees, fn emp ->
        %{
          employee: emp,
          pay: calculate_pay(emp, context)
        }
      end)
    end

    @doc """
    給与支払いを実行。
    支払日に該当する従業員にのみ支払いを行う。
    """
    def run_payroll(employees, context, date) do
      employees
      |> Enum.filter(&Schedule.is_pay_day?(&1, date))
      |> Enum.map(fn emp ->
        pay = calculate_pay(emp, context)
        Payment.process(emp, pay)
      end)
    end

    @doc """
    給与レポートを生成。
    """
    def payroll_report(employees, context) do
      payroll = calculate_payroll(employees, context)
      total = Enum.sum(Enum.map(payroll, & &1.pay))

      %{
        employees: Enum.map(payroll, fn %{employee: emp, pay: pay} ->
          %{
            id: Employee.get_id(emp),
            name: Employee.get_name(emp),
            type: Employee.get_pay_type(emp),
            pay: pay
          }
        end),
        total: total,
        count: length(employees)
      }
    end
  end

  # ============================================================
  # 6. 従業員リポジトリ
  # ============================================================

  defmodule EmployeeRepository do
    @moduledoc "従業員リポジトリ（Agent ベース）"

    alias Chapter16.Employee

    def start_link do
      Agent.start_link(fn -> %{} end)
    end

    def stop(pid) do
      if Process.alive?(pid) do
        Agent.stop(pid)
      else
        :ok
      end
    end

    def add(pid, %Employee{} = employee) do
      Agent.update(pid, &Map.put(&1, employee.id, employee))
      {:ok, employee}
    end

    def get(pid, id) do
      case Agent.get(pid, &Map.get(&1, id)) do
        nil -> {:error, :not_found}
        employee -> {:ok, employee}
      end
    end

    def get_all(pid) do
      Agent.get(pid, &Map.values(&1))
    end

    def update(pid, id, update_fn) do
      Agent.get_and_update(pid, fn state ->
        case Map.get(state, id) do
          nil ->
            {{:error, :not_found}, state}
          employee ->
            updated = update_fn.(employee)
            {{:ok, updated}, Map.put(state, id, updated)}
        end
      end)
    end

    def delete(pid, id) do
      Agent.get_and_update(pid, fn state ->
        case Map.pop(state, id) do
          {nil, state} -> {{:error, :not_found}, state}
          {employee, state} -> {{:ok, employee}, state}
        end
      end)
    end
  end

  # ============================================================
  # 7. トランザクション
  # ============================================================

  defmodule Transaction do
    @moduledoc "給与システムのトランザクション"

    alias Chapter16.{Employee, EmployeeRepository, Classification}

    @doc "従業員追加トランザクション"
    def add_employee(repo, employee) do
      EmployeeRepository.add(repo, employee)
    end

    @doc "従業員削除トランザクション"
    def delete_employee(repo, id) do
      EmployeeRepository.delete(repo, id)
    end

    @doc "タイムカード追加トランザクション"
    def add_time_card(context, employee_id, date, hours) do
      Classification.add_time_card(context, employee_id, date, hours)
    end

    @doc "売上レシート追加トランザクション"
    def add_sales_receipt(context, employee_id, date, amount) do
      Classification.add_sales_receipt(context, employee_id, date, amount)
    end

    @doc "支払い方法変更トランザクション"
    def change_payment_method(repo, id, method) do
      EmployeeRepository.update(repo, id, &Employee.set_payment_method(&1, method))
    end

    @doc "住所変更トランザクション"
    def change_address(repo, id, address) do
      EmployeeRepository.update(repo, id, &Employee.set_address(&1, address))
    end
  end

  # ============================================================
  # 8. サービス層
  # ============================================================

  defmodule PayrollService do
    @moduledoc """
    給与計算サービス。
    リポジトリとコンテキストを管理し、給与計算操作を提供する。
    """

    alias Chapter16.{Employee, EmployeeRepository, Classification, Payroll, Schedule, Transaction}

    defstruct [:repo, :context]

    def new do
      {:ok, repo} = EmployeeRepository.start_link()
      %__MODULE__{
        repo: repo,
        context: Classification.make_context()
      }
    end

    def stop(%__MODULE__{repo: repo}) do
      EmployeeRepository.stop(repo)
    end

    # 従業員操作

    def add_salaried_employee(service, id, name, salary) do
      employee = Employee.make_salaried(id, name, salary)
      Transaction.add_employee(service.repo, employee)
    end

    def add_hourly_employee(service, id, name, hourly_rate) do
      employee = Employee.make_hourly(id, name, hourly_rate)
      Transaction.add_employee(service.repo, employee)
    end

    def add_commissioned_employee(service, id, name, base_pay, commission_rate) do
      employee = Employee.make_commissioned(id, name, base_pay, commission_rate)
      Transaction.add_employee(service.repo, employee)
    end

    def delete_employee(service, id) do
      Transaction.delete_employee(service.repo, id)
    end

    def get_employee(service, id) do
      EmployeeRepository.get(service.repo, id)
    end

    def get_all_employees(service) do
      EmployeeRepository.get_all(service.repo)
    end

    # タイムカード・売上

    def add_time_card(%__MODULE__{context: ctx} = service, employee_id, date, hours) do
      new_ctx = Transaction.add_time_card(ctx, employee_id, date, hours)
      %{service | context: new_ctx}
    end

    def add_sales_receipt(%__MODULE__{context: ctx} = service, employee_id, date, amount) do
      new_ctx = Transaction.add_sales_receipt(ctx, employee_id, date, amount)
      %{service | context: new_ctx}
    end

    # 支払い方法

    def change_payment_method(service, id, method) do
      Transaction.change_payment_method(service.repo, id, method)
    end

    # 給与計算

    def calculate_pay(service, employee_id) do
      case EmployeeRepository.get(service.repo, employee_id) do
        {:ok, employee} -> {:ok, Payroll.calculate_pay(employee, service.context)}
        error -> error
      end
    end

    def run_payroll(service, date) do
      employees = EmployeeRepository.get_all(service.repo)
      Payroll.run_payroll(employees, service.context, date)
    end

    def payroll_report(service) do
      employees = EmployeeRepository.get_all(service.repo)
      Payroll.payroll_report(employees, service.context)
    end
  end
end
