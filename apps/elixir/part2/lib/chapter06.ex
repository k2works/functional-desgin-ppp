defmodule Chapter06 do
  @moduledoc """
  # Chapter 06: TDD and Functional Programming

  このモジュールでは、テスト駆動開発（TDD）と関数型プログラミングの組み合わせを学びます。
  Elixir の特性を活かした効果的な TDD の実践方法を示します。

  ## 主なトピック

  1. TDD の基本サイクル（Red-Green-Refactor）
  2. テスタブルな設計
  3. 純粋関数とテスト容易性
  4. モックとスタブの代替手法
  5. Outside-In TDD
  6. Parameterized Tests
  """

  # ============================================================
  # 1. 基本的な TDD 例：FizzBuzz
  # ============================================================

  defmodule FizzBuzz do
    @moduledoc """
    TDD の典型的な例題：FizzBuzz。
    Red-Green-Refactor サイクルで段階的に実装する。
    """

    @doc """
    数値を FizzBuzz 文字列に変換する。

    ## ルール
    - 3で割り切れる場合: "Fizz"
    - 5で割り切れる場合: "Buzz"
    - 両方で割り切れる場合: "FizzBuzz"
    - それ以外: 数値の文字列

    ## Examples

        iex> Chapter06.FizzBuzz.convert(1)
        "1"
        iex> Chapter06.FizzBuzz.convert(3)
        "Fizz"
        iex> Chapter06.FizzBuzz.convert(5)
        "Buzz"
        iex> Chapter06.FizzBuzz.convert(15)
        "FizzBuzz"
    """
    @spec convert(pos_integer()) :: String.t()
    def convert(n) when rem(n, 15) == 0, do: "FizzBuzz"
    def convert(n) when rem(n, 3) == 0, do: "Fizz"
    def convert(n) when rem(n, 5) == 0, do: "Buzz"
    def convert(n), do: Integer.to_string(n)

    @doc """
    1 から n までの FizzBuzz リストを生成する。

    ## Examples

        iex> Chapter06.FizzBuzz.generate(5)
        ["1", "2", "Fizz", "4", "Buzz"]
    """
    @spec generate(pos_integer()) :: [String.t()]
    def generate(n), do: Enum.map(1..n, &convert/1)
  end

  # ============================================================
  # 2. テスタブルな設計：依存性の注入
  # ============================================================

  defmodule PricingService do
    @moduledoc """
    価格計算サービス。
    外部依存を関数として注入することでテスタブルにする。
    """

    @type discount_fetcher :: (String.t() -> float())

    @doc """
    商品の最終価格を計算する。

    割引率を取得する関数を注入することで、外部依存をモック可能にする。

    ## Examples

        iex> # 常に10%割引を返すスタブ
        iex> discount_fetcher = fn _product_id -> 0.10 end
        iex> Chapter06.PricingService.calculate_price("PROD001", 1000, discount_fetcher)
        900.0
    """
    @spec calculate_price(String.t(), number(), discount_fetcher()) :: float()
    def calculate_price(product_id, base_price, discount_fetcher) do
      discount = discount_fetcher.(product_id)
      base_price * (1.0 - discount)
    end

    @doc """
    複数商品の合計価格を計算する。

    ## Examples

        iex> items = [{"P1", 1000}, {"P2", 500}]
        iex> discount_fetcher = fn
        ...>   "P1" -> 0.10
        ...>   "P2" -> 0.20
        ...> end
        iex> Chapter06.PricingService.calculate_total(items, discount_fetcher)
        1300.0
    """
    @spec calculate_total([{String.t(), number()}], discount_fetcher()) :: float()
    def calculate_total(items, discount_fetcher) do
      items
      |> Enum.map(fn {product_id, base_price} ->
        calculate_price(product_id, base_price, discount_fetcher)
      end)
      |> Enum.sum()
    end
  end

  # ============================================================
  # 3. 純粋関数によるビジネスロジック
  # ============================================================

  defmodule OrderProcessor do
    @moduledoc """
    注文処理ロジック。
    すべての計算は純粋関数として実装し、副作用は境界で処理する。
    """

    @type order :: %{
      items: [{String.t(), pos_integer(), number()}],
      customer_type: :regular | :premium | :vip
    }

    @type order_result :: %{
      subtotal: float(),
      discount: float(),
      tax: float(),
      total: float()
    }

    @doc """
    注文の小計を計算する（純粋関数）。

    ## Examples

        iex> items = [{"Item1", 2, 100.0}, {"Item2", 1, 200.0}]
        iex> Chapter06.OrderProcessor.calculate_subtotal(items)
        400.0
    """
    @spec calculate_subtotal([{String.t(), pos_integer(), number()}]) :: float()
    def calculate_subtotal(items) do
      items
      |> Enum.map(fn {_name, qty, price} -> qty * price end)
      |> Enum.sum()
    end

    @doc """
    顧客タイプに応じた割引率を返す（純粋関数）。

    ## Examples

        iex> Chapter06.OrderProcessor.discount_rate(:regular)
        0.0
        iex> Chapter06.OrderProcessor.discount_rate(:premium)
        0.05
        iex> Chapter06.OrderProcessor.discount_rate(:vip)
        0.10
    """
    @spec discount_rate(:regular | :premium | :vip) :: float()
    def discount_rate(:regular), do: 0.0
    def discount_rate(:premium), do: 0.05
    def discount_rate(:vip), do: 0.10

    @doc """
    税額を計算する（純粋関数）。

    ## Examples

        iex> Chapter06.OrderProcessor.calculate_tax(1000.0, 0.10)
        100.0
    """
    @spec calculate_tax(float(), float()) :: float()
    def calculate_tax(amount, tax_rate), do: amount * tax_rate

    @doc """
    注文を処理し、計算結果を返す（純粋関数）。

    ## Examples

        iex> order = %{
        ...>   items: [{"Item1", 2, 100.0}],
        ...>   customer_type: :premium
        ...> }
        iex> result = Chapter06.OrderProcessor.process_order(order, 0.08)
        iex> result.subtotal
        200.0
        iex> result.discount
        10.0
        iex> result.tax
        15.2
        iex> result.total
        205.2
    """
    @spec process_order(order(), float()) :: order_result()
    def process_order(%{items: items, customer_type: customer_type}, tax_rate) do
      subtotal = calculate_subtotal(items)
      discount_amount = subtotal * discount_rate(customer_type)
      discounted = subtotal - discount_amount
      tax_amount = calculate_tax(discounted, tax_rate)
      total = discounted + tax_amount

      %{
        subtotal: subtotal,
        discount: discount_amount,
        tax: tax_amount,
        total: total
      }
    end
  end

  # ============================================================
  # 4. State Machine with TDD
  # ============================================================

  defmodule OrderState do
    @moduledoc """
    注文状態遷移マシン。
    状態遷移を純粋関数としてモデル化し、TDD で検証する。
    """

    @type state :: :pending | :confirmed | :shipped | :delivered | :cancelled

    @type order :: %{
      id: String.t(),
      state: state(),
      items: list(),
      history: [state()]
    }

    @doc """
    新しい注文を作成する。

    ## Examples

        iex> order = Chapter06.OrderState.new("ORD001", [{"Item", 1}])
        iex> order.state
        :pending
    """
    @spec new(String.t(), list()) :: order()
    def new(id, items) do
      %{
        id: id,
        state: :pending,
        items: items,
        history: [:pending]
      }
    end

    @doc """
    注文を確認する。

    ## Examples

        iex> order = Chapter06.OrderState.new("ORD001", [])
        iex> {:ok, order} = Chapter06.OrderState.confirm(order)
        iex> order.state
        :confirmed
    """
    @spec confirm(order()) :: {:ok, order()} | {:error, String.t()}
    def confirm(%{state: :pending} = order) do
      {:ok, transition(order, :confirmed)}
    end
    def confirm(%{state: state}) do
      {:error, "Cannot confirm order in state: #{state}"}
    end

    @doc """
    注文を発送する。

    ## Examples

        iex> order = Chapter06.OrderState.new("ORD001", [])
        iex> {:ok, order} = Chapter06.OrderState.confirm(order)
        iex> {:ok, order} = Chapter06.OrderState.ship(order)
        iex> order.state
        :shipped
    """
    @spec ship(order()) :: {:ok, order()} | {:error, String.t()}
    def ship(%{state: :confirmed} = order) do
      {:ok, transition(order, :shipped)}
    end
    def ship(%{state: state}) do
      {:error, "Cannot ship order in state: #{state}"}
    end

    @doc """
    注文を配達完了にする。

    ## Examples

        iex> order = Chapter06.OrderState.new("ORD001", [])
        iex> {:ok, order} = Chapter06.OrderState.confirm(order)
        iex> {:ok, order} = Chapter06.OrderState.ship(order)
        iex> {:ok, order} = Chapter06.OrderState.deliver(order)
        iex> order.state
        :delivered
    """
    @spec deliver(order()) :: {:ok, order()} | {:error, String.t()}
    def deliver(%{state: :shipped} = order) do
      {:ok, transition(order, :delivered)}
    end
    def deliver(%{state: state}) do
      {:error, "Cannot deliver order in state: #{state}"}
    end

    @doc """
    注文をキャンセルする。

    ## Examples

        iex> order = Chapter06.OrderState.new("ORD001", [])
        iex> {:ok, order} = Chapter06.OrderState.cancel(order)
        iex> order.state
        :cancelled
    """
    @spec cancel(order()) :: {:ok, order()} | {:error, String.t()}
    def cancel(%{state: state} = order) when state in [:pending, :confirmed] do
      {:ok, transition(order, :cancelled)}
    end
    def cancel(%{state: state}) do
      {:error, "Cannot cancel order in state: #{state}"}
    end

    defp transition(order, new_state) do
      %{order | state: new_state, history: [new_state | order.history]}
    end

    @doc """
    注文が完了可能かどうかを判定する。

    ## Examples

        iex> order = Chapter06.OrderState.new("ORD001", [])
        iex> Chapter06.OrderState.can_complete?(order)
        true
        iex> {:ok, cancelled} = Chapter06.OrderState.cancel(order)
        iex> Chapter06.OrderState.can_complete?(cancelled)
        false
    """
    @spec can_complete?(order()) :: boolean()
    def can_complete?(%{state: state}) do
      state not in [:cancelled, :delivered]
    end
  end

  # ============================================================
  # 5. Calculator with Error Handling
  # ============================================================

  defmodule Calculator do
    @moduledoc """
    エラーハンドリングを含む計算機。
    Result 型を使った安全な計算を TDD で実装する。
    """

    @type result :: {:ok, number()} | {:error, String.t()}

    @doc """
    2つの数を加算する。

    ## Examples

        iex> Chapter06.Calculator.add(1, 2)
        {:ok, 3}
    """
    @spec add(number(), number()) :: result()
    def add(a, b), do: {:ok, a + b}

    @doc """
    2つの数を減算する。

    ## Examples

        iex> Chapter06.Calculator.subtract(5, 3)
        {:ok, 2}
    """
    @spec subtract(number(), number()) :: result()
    def subtract(a, b), do: {:ok, a - b}

    @doc """
    2つの数を乗算する。

    ## Examples

        iex> Chapter06.Calculator.multiply(3, 4)
        {:ok, 12}
    """
    @spec multiply(number(), number()) :: result()
    def multiply(a, b), do: {:ok, a * b}

    @doc """
    2つの数を除算する。ゼロ除算はエラー。

    ## Examples

        iex> Chapter06.Calculator.divide(10, 2)
        {:ok, 5.0}
        iex> Chapter06.Calculator.divide(1, 0)
        {:error, "Division by zero"}
    """
    @spec divide(number(), number()) :: result()
    def divide(_, b) when b == 0 or b == 0.0, do: {:error, "Division by zero"}
    def divide(a, b), do: {:ok, a / b}

    @doc """
    平方根を計算する。負数はエラー。

    ## Examples

        iex> Chapter06.Calculator.sqrt(16)
        {:ok, 4.0}
        iex> Chapter06.Calculator.sqrt(-1)
        {:error, "Cannot calculate square root of negative number"}
    """
    @spec sqrt(number()) :: result()
    def sqrt(n) when n < 0, do: {:error, "Cannot calculate square root of negative number"}
    def sqrt(n), do: {:ok, :math.sqrt(n)}

    @doc """
    計算をチェインする。

    ## Examples

        iex> Chapter06.Calculator.chain(10)
        ...> |> Chapter06.Calculator.then_add(5)
        ...> |> Chapter06.Calculator.then_multiply(2)
        {:ok, 30}
    """
    @spec chain(number()) :: result()
    def chain(n), do: {:ok, n}

    @spec then_add(result(), number()) :: result()
    def then_add({:ok, a}, b), do: add(a, b)
    def then_add(error, _), do: error

    @spec then_subtract(result(), number()) :: result()
    def then_subtract({:ok, a}, b), do: subtract(a, b)
    def then_subtract(error, _), do: error

    @spec then_multiply(result(), number()) :: result()
    def then_multiply({:ok, a}, b), do: multiply(a, b)
    def then_multiply(error, _), do: error

    @spec then_divide(result(), number()) :: result()
    def then_divide({:ok, a}, b), do: divide(a, b)
    def then_divide(error, _), do: error

    @doc """
    文字列式を評価する（簡易版）。

    ## Examples

        iex> Chapter06.Calculator.evaluate("2 + 3")
        {:ok, 5.0}
        iex> Chapter06.Calculator.evaluate("10 / 0")
        {:error, "Division by zero"}
        iex> Chapter06.Calculator.evaluate("invalid")
        {:error, "Invalid expression"}
    """
    @spec evaluate(String.t()) :: result()
    def evaluate(expr) do
      case parse_expression(expr) do
        {:ok, {a, op, b}} -> apply_operation(a, op, b)
        :error -> {:error, "Invalid expression"}
      end
    end

    defp parse_expression(expr) do
      parts = String.split(expr, " ")
      case parts do
        [a_str, op, b_str] ->
          with {a, ""} <- Float.parse(a_str),
               {b, ""} <- Float.parse(b_str) do
            {:ok, {a, op, b}}
          else
            _ -> :error
          end
        _ -> :error
      end
    end

    defp apply_operation(a, "+", b), do: add(a, b)
    defp apply_operation(a, "-", b), do: subtract(a, b)
    defp apply_operation(a, "*", b), do: multiply(a, b)
    defp apply_operation(a, "/", b), do: divide(a, b)
    defp apply_operation(_, _, _), do: {:error, "Unknown operator"}
  end

  # ============================================================
  # 6. Password Validator (TDD Example)
  # ============================================================

  defmodule PasswordValidator do
    @moduledoc """
    パスワードバリデータ。
    複数のルールを組み合わせた検証を TDD で実装する。
    """

    @type validation_result :: {:ok, String.t()} | {:error, [String.t()]}

    @doc """
    パスワードを検証する。

    ## ルール
    - 8文字以上
    - 大文字を1文字以上含む
    - 小文字を1文字以上含む
    - 数字を1文字以上含む
    - 特殊文字を1文字以上含む

    ## Examples

        iex> Chapter06.PasswordValidator.validate("Abc123!@")
        {:ok, "Abc123!@"}
        iex> Chapter06.PasswordValidator.validate("short")
        {:error, ["8文字以上必要", "大文字が必要", "数字が必要", "特殊文字が必要"]}
    """
    @spec validate(String.t()) :: validation_result()
    def validate(password) do
      rules = [
        &check_length/1,
        &check_uppercase/1,
        &check_lowercase/1,
        &check_digit/1,
        &check_special/1
      ]

      errors =
        rules
        |> Enum.map(fn rule -> rule.(password) end)
        |> Enum.filter(&match?({:error, _}, &1))
        |> Enum.map(fn {:error, msg} -> msg end)

      if errors == [] do
        {:ok, password}
      else
        {:error, errors}
      end
    end

    @doc """
    長さをチェックする。

    ## Examples

        iex> Chapter06.PasswordValidator.check_length("12345678")
        :ok
        iex> Chapter06.PasswordValidator.check_length("short")
        {:error, "8文字以上必要"}
    """
    @spec check_length(String.t()) :: :ok | {:error, String.t()}
    def check_length(password) do
      if String.length(password) >= 8 do
        :ok
      else
        {:error, "8文字以上必要"}
      end
    end

    @doc """
    大文字をチェックする。

    ## Examples

        iex> Chapter06.PasswordValidator.check_uppercase("Abc")
        :ok
        iex> Chapter06.PasswordValidator.check_uppercase("abc")
        {:error, "大文字が必要"}
    """
    @spec check_uppercase(String.t()) :: :ok | {:error, String.t()}
    def check_uppercase(password) do
      if String.match?(password, ~r/[A-Z]/) do
        :ok
      else
        {:error, "大文字が必要"}
      end
    end

    @doc """
    小文字をチェックする。

    ## Examples

        iex> Chapter06.PasswordValidator.check_lowercase("Abc")
        :ok
        iex> Chapter06.PasswordValidator.check_lowercase("ABC")
        {:error, "小文字が必要"}
    """
    @spec check_lowercase(String.t()) :: :ok | {:error, String.t()}
    def check_lowercase(password) do
      if String.match?(password, ~r/[a-z]/) do
        :ok
      else
        {:error, "小文字が必要"}
      end
    end

    @doc """
    数字をチェックする。

    ## Examples

        iex> Chapter06.PasswordValidator.check_digit("abc123")
        :ok
        iex> Chapter06.PasswordValidator.check_digit("abc")
        {:error, "数字が必要"}
    """
    @spec check_digit(String.t()) :: :ok | {:error, String.t()}
    def check_digit(password) do
      if String.match?(password, ~r/[0-9]/) do
        :ok
      else
        {:error, "数字が必要"}
      end
    end

    @doc """
    特殊文字をチェックする。

    ## Examples

        iex> Chapter06.PasswordValidator.check_special("abc!")
        :ok
        iex> Chapter06.PasswordValidator.check_special("abc")
        {:error, "特殊文字が必要"}
    """
    @spec check_special(String.t()) :: :ok | {:error, String.t()}
    def check_special(password) do
      if String.match?(password, ~r/[!@#$%^&*(),.?":{}|<>]/) do
        :ok
      else
        {:error, "特殊文字が必要"}
      end
    end
  end

  # ============================================================
  # 7. Test Data Builder Pattern
  # ============================================================

  defmodule UserBuilder do
    @moduledoc """
    テストデータビルダーパターン。
    テストで使用するデータを柔軟に構築する。
    """

    @type user :: %{
      name: String.t(),
      email: String.t(),
      age: non_neg_integer(),
      role: :user | :admin | :moderator,
      active: boolean()
    }

    @doc """
    デフォルト値を持つユーザーを作成する。

    ## Examples

        iex> user = Chapter06.UserBuilder.build()
        iex> user.name
        "Test User"
        iex> user.role
        :user
    """
    @spec build() :: user()
    def build do
      %{
        name: "Test User",
        email: "test@example.com",
        age: 25,
        role: :user,
        active: true
      }
    end

    @doc """
    特定のフィールドを上書きしてユーザーを作成する。

    ## Examples

        iex> user = Chapter06.UserBuilder.build(name: "Alice", role: :admin)
        iex> user.name
        "Alice"
        iex> user.role
        :admin
    """
    @spec build(keyword()) :: user()
    def build(overrides) do
      build() |> Map.merge(Map.new(overrides))
    end

    @doc """
    管理者ユーザーを作成する。

    ## Examples

        iex> admin = Chapter06.UserBuilder.admin()
        iex> admin.role
        :admin
    """
    @spec admin() :: user()
    def admin, do: build(role: :admin)

    @doc """
    非アクティブユーザーを作成する。

    ## Examples

        iex> inactive = Chapter06.UserBuilder.inactive()
        iex> inactive.active
        false
    """
    @spec inactive() :: user()
    def inactive, do: build(active: false)

    @doc """
    複数のユーザーを作成する。

    ## Examples

        iex> users = Chapter06.UserBuilder.build_list(3)
        iex> length(users)
        3
    """
    @spec build_list(pos_integer()) :: [user()]
    def build_list(count) do
      Enum.map(1..count, fn i ->
        build(name: "User #{i}", email: "user#{i}@example.com")
      end)
    end
  end

  # ============================================================
  # 8. Test Helper Functions
  # ============================================================

  @doc """
  テストで使用する日付ヘルパー。

  ## Examples

      iex> Chapter06.days_ago(0) == Date.utc_today()
      true
  """
  @spec days_ago(non_neg_integer()) :: Date.t()
  def days_ago(n), do: Date.add(Date.utc_today(), -n)

  @doc """
  テストで使用する日付ヘルパー。

  ## Examples

      iex> Chapter06.days_from_now(0) == Date.utc_today()
      true
  """
  @spec days_from_now(non_neg_integer()) :: Date.t()
  def days_from_now(n), do: Date.add(Date.utc_today(), n)

  @doc """
  ランダムな文字列を生成する。

  ## Examples

      iex> s = Chapter06.random_string(10)
      iex> String.length(s)
      10
  """
  @spec random_string(pos_integer()) :: String.t()
  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> binary_part(0, length)
  end

  @doc """
  ランダムなメールアドレスを生成する。

  ## Examples

      iex> email = Chapter06.random_email()
      iex> String.contains?(email, "@example.com")
      true
  """
  @spec random_email() :: String.t()
  def random_email do
    "#{random_string(8)}@example.com"
  end
end
