defmodule Chapter03 do
  @moduledoc """
  第3章: 多態性の実現方法

  Elixir におけるプロトコル、ビヘイビア、パターンマッチングを使った
  多態性の実現方法を学びます。
  """

  # ============================================================
  # 1. パターンマッチングによる多態性（代数的データ型相当）
  # ============================================================

  @doc """
  図形を表す型。タグ付きタプルを使用。
  """

  @type shape ::
          {:rectangle, width :: number(), height :: number()}
          | {:circle, radius :: number()}
          | {:triangle, base :: number(), height :: number()}

  @doc """
  図形の面積を計算する。

  ## Examples

      iex> Chapter03.calculate_area({:rectangle, 4, 5})
      20
      iex> Chapter03.calculate_area({:circle, 3})
      28.274333882308138
      iex> Chapter03.calculate_area({:triangle, 6, 5})
      15.0
  """
  @spec calculate_area(shape()) :: number()
  def calculate_area({:rectangle, width, height}), do: width * height
  def calculate_area({:circle, radius}), do: :math.pi() * radius * radius
  def calculate_area({:triangle, base, height}), do: base * height / 2

  @doc """
  図形の周囲長を計算する。

  ## Examples

      iex> Chapter03.calculate_perimeter({:rectangle, 4, 5})
      18
      iex> Chapter03.calculate_perimeter({:circle, 3})
      18.84955592153876
  """
  @spec calculate_perimeter(shape()) :: number()
  def calculate_perimeter({:rectangle, width, height}), do: 2 * (width + height)
  def calculate_perimeter({:circle, radius}), do: 2 * :math.pi() * radius
  def calculate_perimeter({:triangle, a, b}), do: a + b + :math.sqrt(a * a + b * b)

  # ============================================================
  # 2. 構造体とパターンマッチング
  # ============================================================

  defmodule Rectangle do
    @moduledoc "長方形"
    defstruct [:width, :height]
    @type t :: %__MODULE__{width: number(), height: number()}
  end

  defmodule Circle do
    @moduledoc "円"
    defstruct [:radius]
    @type t :: %__MODULE__{radius: number()}
  end

  defmodule Triangle do
    @moduledoc "三角形"
    defstruct [:base, :height]
    @type t :: %__MODULE__{base: number(), height: number()}
  end

  @doc """
  構造体を使った図形の面積計算。

  ## Examples

      iex> Chapter03.area(%Chapter03.Rectangle{width: 4, height: 5})
      20
      iex> Chapter03.area(%Chapter03.Circle{radius: 3})
      28.274333882308138
  """
  @spec area(Rectangle.t() | Circle.t() | Triangle.t()) :: number()
  def area(%Rectangle{width: w, height: h}), do: w * h
  def area(%Circle{radius: r}), do: :math.pi() * r * r
  def area(%Triangle{base: b, height: h}), do: b * h / 2

  # ============================================================
  # 3. 複合ディスパッチ
  # ============================================================

  @type payment_method :: :credit_card | :bank_transfer | :cash
  @type currency :: :jpy | :usd | :eur

  defmodule Payment do
    @moduledoc "支払い"
    defstruct [:method, :currency, :amount]

    @type t :: %__MODULE__{
            method: Chapter03.payment_method(),
            currency: Chapter03.currency(),
            amount: non_neg_integer()
          }
  end

  defmodule PaymentResult do
    @moduledoc "支払い結果"
    defstruct [:status, :message, :amount, :converted]

    @type t :: %__MODULE__{
            status: String.t(),
            message: String.t(),
            amount: non_neg_integer(),
            converted: non_neg_integer() | nil
          }
  end

  @doc """
  支払いを処理する（複合ディスパッチ）。

  ## Examples

      iex> payment = %Chapter03.Payment{method: :credit_card, currency: :jpy, amount: 1000}
      iex> result = Chapter03.process_payment(payment)
      iex> result.status
      "processed"

      iex> payment = %Chapter03.Payment{method: :credit_card, currency: :usd, amount: 100}
      iex> result = Chapter03.process_payment(payment)
      iex> result.converted
      15000
  """
  @spec process_payment(Payment.t()) :: PaymentResult.t()
  def process_payment(%Payment{method: method, currency: currency, amount: amount}) do
    case {method, currency} do
      {:credit_card, :jpy} ->
        %PaymentResult{
          status: "processed",
          message: "クレジットカード（円）で処理しました",
          amount: amount
        }

      {:credit_card, :usd} ->
        %PaymentResult{
          status: "processed",
          message: "Credit card (USD) processed",
          amount: amount,
          converted: amount * 150
        }

      {:bank_transfer, :jpy} ->
        %PaymentResult{
          status: "pending",
          message: "銀行振込を受け付けました",
          amount: amount
        }

      _ ->
        %PaymentResult{
          status: "error",
          message: "サポートされていない支払い方法です",
          amount: amount
        }
    end
  end

  # ============================================================
  # 4. プロトコルによる多態性
  # ============================================================

  defprotocol Describable do
    @moduledoc """
    オブジェクトを説明するプロトコル。
    """
    @doc "オブジェクトの説明を返す"
    @spec describe(t) :: String.t()
    def describe(value)
  end

  defmodule ShopProduct do
    @moduledoc "商品"
    defstruct [:name, :price]
    @type t :: %__MODULE__{name: String.t(), price: non_neg_integer()}
  end

  defmodule Service do
    @moduledoc "サービス"
    defstruct [:name, :hourly_rate]
    @type t :: %__MODULE__{name: String.t(), hourly_rate: non_neg_integer()}
  end

  defimpl Describable, for: ShopProduct do
    def describe(%ShopProduct{name: name, price: price}) do
      "商品: #{name} (#{price}円)"
    end
  end

  defimpl Describable, for: Service do
    def describe(%Service{name: name, hourly_rate: rate}) do
      "サービス: #{name} (時給#{rate}円)"
    end
  end

  # Elixir の組み込み型にも実装できる
  defimpl Describable, for: Map do
    def describe(map) do
      "マップ with #{map_size(map)} keys"
    end
  end

  defimpl Describable, for: List do
    def describe(list) do
      "リスト with #{length(list)} elements"
    end
  end

  # ============================================================
  # 5. 口座の例（階層的ディスパッチ）
  # ============================================================

  defmodule SavingsAccount do
    @moduledoc "普通預金口座"
    defstruct [:balance]
    @type t :: %__MODULE__{balance: non_neg_integer()}

    def interest_rate, do: 0.02
  end

  defmodule PremiumSavingsAccount do
    @moduledoc "プレミアム預金口座"
    defstruct [:balance]
    @type t :: %__MODULE__{balance: non_neg_integer()}

    def interest_rate, do: 0.05
  end

  defmodule CheckingAccount do
    @moduledoc "当座預金口座"
    defstruct [:balance]
    @type t :: %__MODULE__{balance: non_neg_integer()}

    def interest_rate, do: 0.001
  end

  @doc """
  口座の利息を計算する。

  ## Examples

      iex> Chapter03.calculate_interest(%Chapter03.SavingsAccount{balance: 10000})
      200.0
      iex> Chapter03.calculate_interest(%Chapter03.PremiumSavingsAccount{balance: 10000})
      500.0
      iex> Chapter03.calculate_interest(%Chapter03.CheckingAccount{balance: 10000})
      10.0
  """
  @spec calculate_interest(SavingsAccount.t() | PremiumSavingsAccount.t() | CheckingAccount.t()) ::
          float()
  def calculate_interest(%SavingsAccount{balance: balance}) do
    balance * SavingsAccount.interest_rate()
  end

  def calculate_interest(%PremiumSavingsAccount{balance: balance}) do
    balance * PremiumSavingsAccount.interest_rate()
  end

  def calculate_interest(%CheckingAccount{balance: balance}) do
    balance * CheckingAccount.interest_rate()
  end

  # ============================================================
  # 6. ビヘイビアによる多態性
  # ============================================================

  defmodule Serializer do
    @moduledoc """
    シリアライザのビヘイビア定義。
    """
    @callback serialize(data :: any()) :: String.t()
    @callback deserialize(string :: String.t()) :: any()
  end

  defmodule JsonSerializer do
    @moduledoc "JSONシリアライザ"
    @behaviour Serializer

    @impl Serializer
    def serialize(data) do
      # 簡易実装（実際は Jason などを使用）
      inspect(data)
    end

    @impl Serializer
    def deserialize(_string) do
      # 簡易実装
      %{}
    end
  end

  defmodule CsvSerializer do
    @moduledoc "CSVシリアライザ"
    @behaviour Serializer

    @impl Serializer
    def serialize(data) when is_list(data) do
      data
      |> Enum.map(&Enum.join(&1, ","))
      |> Enum.join("\n")
    end

    def serialize(_), do: ""

    @impl Serializer
    def deserialize(string) do
      string
      |> String.split("\n")
      |> Enum.map(&String.split(&1, ","))
    end
  end

  # ============================================================
  # 7. 型クラス相当（プロトコル + 実装）
  # ============================================================

  defprotocol Monoid do
    @moduledoc """
    モノイドの定義。
    empty と combine を持つ。
    """
    @doc "結合演算"
    @spec combine(t, t) :: t
    def combine(a, b)
  end

  defmodule Sum do
    @moduledoc "加算モノイド"
    defstruct [:value]
    @type t :: %__MODULE__{value: number()}

    def empty, do: %Sum{value: 0}
  end

  defmodule Multiply do
    @moduledoc "乗算モノイド"
    defstruct [:value]
    @type t :: %__MODULE__{value: number()}

    def empty, do: %Multiply{value: 1}
  end

  defimpl Monoid, for: Sum do
    def combine(%Sum{value: a}, %Sum{value: b}), do: %Sum{value: a + b}
  end

  defimpl Monoid, for: Multiply do
    def combine(%Multiply{value: a}, %Multiply{value: b}), do: %Multiply{value: a * b}
  end

  defimpl Monoid, for: List do
    def combine(a, b), do: a ++ b
  end

  @doc """
  モノイドのリストを畳み込む。

  ## Examples

      iex> sums = [%Chapter03.Sum{value: 1}, %Chapter03.Sum{value: 2}, %Chapter03.Sum{value: 3}]
      iex> Chapter03.fold_monoid(sums, Chapter03.Sum.empty())
      %Chapter03.Sum{value: 6}

      iex> mults = [%Chapter03.Multiply{value: 2}, %Chapter03.Multiply{value: 3}]
      iex> Chapter03.fold_monoid(mults, Chapter03.Multiply.empty())
      %Chapter03.Multiply{value: 6}
  """
  @spec fold_monoid([any()], any()) :: any()
  def fold_monoid(list, empty) do
    Enum.reduce(list, empty, &Monoid.combine(&2, &1))
  end

  # ============================================================
  # 8. 動的ディスパッチ（マップによる）
  # ============================================================

  @doc """
  関数マップによる動的ディスパッチ。

  ## Examples

      iex> handlers = %{
      ...>   add: fn a, b -> a + b end,
      ...>   multiply: fn a, b -> a * b end,
      ...>   subtract: fn a, b -> a - b end
      ...> }
      iex> Chapter03.dispatch(handlers, :add, [5, 3])
      8
      iex> Chapter03.dispatch(handlers, :multiply, [5, 3])
      15
  """
  @spec dispatch(map(), atom(), list()) :: any()
  def dispatch(handlers, operation, args) do
    case Map.get(handlers, operation) do
      nil -> raise ArgumentError, "Unknown operation: #{operation}"
      handler -> apply(handler, args)
    end
  end

  @doc """
  拡張可能な計算機を作成する。

  ## Examples

      iex> calc = Chapter03.create_calculator()
      iex> calc.(:add, 5, 3)
      8
      iex> calc.(:divide, 10, 2)
      5.0
  """
  @spec create_calculator() :: (atom(), number(), number() -> number())
  def create_calculator do
    handlers = %{
      add: fn a, b -> a + b end,
      subtract: fn a, b -> a - b end,
      multiply: fn a, b -> a * b end,
      divide: fn a, b -> a / b end
    }

    fn operation, a, b ->
      dispatch(handlers, operation, [a, b])
    end
  end

  # ============================================================
  # 9. 式の評価（再帰的なパターンマッチング）
  # ============================================================

  @type expr ::
          {:num, number()}
          | {:add, expr(), expr()}
          | {:sub, expr(), expr()}
          | {:mul, expr(), expr()}
          | {:div, expr(), expr()}

  @doc """
  式を評価する。

  ## Examples

      iex> expr = {:add, {:num, 5}, {:mul, {:num, 2}, {:num, 3}}}
      iex> Chapter03.evaluate(expr)
      11

      iex> expr = {:div, {:sub, {:num, 10}, {:num, 4}}, {:num, 2}}
      iex> Chapter03.evaluate(expr)
      3.0
  """
  @spec evaluate(expr()) :: number()
  def evaluate({:num, n}), do: n
  def evaluate({:add, left, right}), do: evaluate(left) + evaluate(right)
  def evaluate({:sub, left, right}), do: evaluate(left) - evaluate(right)
  def evaluate({:mul, left, right}), do: evaluate(left) * evaluate(right)
  def evaluate({:div, left, right}), do: evaluate(left) / evaluate(right)

  @doc """
  式を文字列に変換する。

  ## Examples

      iex> expr = {:add, {:num, 5}, {:mul, {:num, 2}, {:num, 3}}}
      iex> Chapter03.expr_to_string(expr)
      "(5 + (2 * 3))"
  """
  @spec expr_to_string(expr()) :: String.t()
  def expr_to_string({:num, n}), do: to_string(n)

  def expr_to_string({:add, left, right}) do
    "(#{expr_to_string(left)} + #{expr_to_string(right)})"
  end

  def expr_to_string({:sub, left, right}) do
    "(#{expr_to_string(left)} - #{expr_to_string(right)})"
  end

  def expr_to_string({:mul, left, right}) do
    "(#{expr_to_string(left)} * #{expr_to_string(right)})"
  end

  def expr_to_string({:div, left, right}) do
    "(#{expr_to_string(left)} / #{expr_to_string(right)})"
  end

  # ============================================================
  # 10. ガード節による多態性
  # ============================================================

  @doc """
  値の種類に応じた処理（ガード節を使用）。

  ## Examples

      iex> Chapter03.describe_value(42)
      "正の整数: 42"
      iex> Chapter03.describe_value(-5)
      "負の整数: -5"
      iex> Chapter03.describe_value(3.14)
      "浮動小数点数: 3.14"
      iex> Chapter03.describe_value("hello")
      "文字列: hello"
      iex> Chapter03.describe_value([1, 2, 3])
      "リスト（要素数: 3）"
  """
  @spec describe_value(any()) :: String.t()
  def describe_value(n) when is_integer(n) and n > 0, do: "正の整数: #{n}"
  def describe_value(n) when is_integer(n) and n < 0, do: "負の整数: #{n}"
  def describe_value(0), do: "ゼロ"
  def describe_value(n) when is_float(n), do: "浮動小数点数: #{n}"
  def describe_value(s) when is_binary(s), do: "文字列: #{s}"
  def describe_value(list) when is_list(list), do: "リスト（要素数: #{length(list)}）"
  def describe_value(map) when is_map(map), do: "マップ（キー数: #{map_size(map)}）"
  def describe_value(_), do: "その他"
end
