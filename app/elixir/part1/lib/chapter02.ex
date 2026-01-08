defmodule Chapter02 do
  @moduledoc """
  第2章: 関数合成と高階関数

  小さな関数を組み合わせて複雑な処理を構築する方法を学びます。
  """

  # ============================================================
  # 1. 関数合成の基本
  # ============================================================

  @doc """
  税金を追加する関数を返す。

  ## Examples

      iex> add_tax = Chapter02.add_tax(0.1)
      iex> add_tax.(1000)
      1100.0
  """
  @spec add_tax(float()) :: (number() -> float())
  def add_tax(rate) do
    fn amount -> amount * (1 + rate) end
  end

  @doc """
  割引を適用する関数を返す。

  ## Examples

      iex> apply_discount = Chapter02.apply_discount(0.2)
      iex> apply_discount.(1000)
      800.0
  """
  @spec apply_discount(float()) :: (number() -> float())
  def apply_discount(rate) do
    fn amount -> amount * (1 - rate) end
  end

  @doc """
  円単位で丸める。

  ## Examples

      iex> Chapter02.round_to_yen(880.5)
      881
  """
  @spec round_to_yen(number()) :: integer()
  def round_to_yen(amount), do: round(amount)

  @doc """
  複数の関数を合成する（左から右へ順次適用）。

  ## Examples

      iex> add_one = fn x -> x + 1 end
      iex> double = fn x -> x * 2 end
      iex> composed = Chapter02.compose([add_one, double])
      iex> composed.(5)
      12
  """
  @spec compose([function()]) :: (any() -> any())
  def compose(fns) do
    fn input ->
      Enum.reduce(fns, input, fn f, acc -> f.(acc) end)
    end
  end

  @doc """
  価格計算パイプラインを作成する。
  20%割引 → 10%税込 → 丸め

  ## Examples

      iex> calculate = Chapter02.calculate_final_price()
      iex> calculate.(1000)
      880
  """
  @spec calculate_final_price() :: (number() -> integer())
  def calculate_final_price do
    discount = apply_discount(0.2)
    tax = add_tax(0.1)

    fn amount ->
      amount
      |> discount.()
      |> tax.()
      |> round_to_yen()
    end
  end

  # ============================================================
  # 2. カリー化と部分適用
  # ============================================================

  @doc """
  挨拶関数を返す。

  ## Examples

      iex> say_hello = Chapter02.greet("Hello")
      iex> say_hello.("田中")
      "Hello, 田中!"
  """
  @spec greet(String.t()) :: (String.t() -> String.t())
  def greet(greeting) do
    fn name -> "#{greeting}, #{name}!" end
  end

  defmodule Email do
    @moduledoc "メールを表す構造体"
    defstruct [:from, :to, :subject, :body]

    @type t :: %__MODULE__{
            from: String.t(),
            to: String.t(),
            subject: String.t(),
            body: String.t()
          }
  end

  @doc """
  メール送信関数を返す（カリー化）。

  ## Examples

      iex> send_from_system = Chapter02.send_email("system@example.com")
      iex> send_notification = send_from_system.("user@example.com").("通知")
      iex> email = send_notification.("メッセージ本文")
      iex> email.from
      "system@example.com"
      iex> email.subject
      "通知"
  """
  @spec send_email(String.t()) :: (String.t() -> (String.t() -> (String.t() -> Email.t())))
  def send_email(from) do
    fn to ->
      fn subject ->
        fn body ->
          %Email{from: from, to: to, subject: subject, body: body}
        end
      end
    end
  end

  # ============================================================
  # 3. 複数の関数を並列適用
  # ============================================================

  @doc """
  数値リストの統計情報を取得する。

  ## Examples

      iex> Chapter02.get_stats([3, 1, 4, 1, 5, 9, 2, 6])
      {3, 6, 8, 1, 9}
  """
  @spec get_stats([number()]) :: {number(), number(), non_neg_integer(), number(), number()}
  def get_stats(numbers) do
    {
      hd(numbers),
      List.last(numbers),
      length(numbers),
      Enum.min(numbers),
      Enum.max(numbers)
    }
  end

  @doc """
  人物を分析する。

  ## Examples

      iex> Chapter02.analyze_person(%{name: "田中", age: 25})
      %{name: "田中", age: 25, category: "adult"}
      iex> Chapter02.analyze_person(%{name: "鈴木", age: 15})
      %{name: "鈴木", age: 15, category: "minor"}
  """
  @spec analyze_person(map()) :: map()
  def analyze_person(%{name: name, age: age}) do
    category = if age >= 18, do: "adult", else: "minor"
    %{name: name, age: age, category: category}
  end

  @doc """
  複数の関数を適用して結果をタプルで返す（juxt相当）。

  ## Examples

      iex> juxt = Chapter02.juxt([&Enum.min/1, &Enum.max/1, &Enum.sum/1])
      iex> juxt.([1, 2, 3, 4, 5])
      {1, 5, 15}
  """
  @spec juxt([function()]) :: (any() -> tuple())
  def juxt(fns) do
    fn input ->
      fns
      |> Enum.map(fn f -> f.(input) end)
      |> List.to_tuple()
    end
  end

  # ============================================================
  # 4. 高階関数によるデータ処理
  # ============================================================

  @doc """
  ログ出力付きの関数ラッパーを作成する。
  """
  @spec with_logging((a -> b)) :: (a -> b) when a: any(), b: any()
  def with_logging(f) do
    fn input ->
      IO.puts("入力: #{inspect(input)}")
      result = f.(input)
      IO.puts("出力: #{inspect(result)}")
      result
    end
  end

  @doc """
  リトライ機能付きの関数ラッパーを作成する。

  ## Examples

      iex> counter = :counters.new(1, [:atomics])
      iex> unstable = fn _x ->
      ...>   count = :counters.get(counter, 1)
      ...>   :counters.add(counter, 1, 1)
      ...>   if count < 2, do: raise("Error"), else: :ok
      ...> end
      iex> with_retry = Chapter02.with_retry(unstable, 3)
      iex> with_retry.(nil)
      :ok
  """
  @spec with_retry((a -> b), non_neg_integer()) :: (a -> b) when a: any(), b: any()
  def with_retry(f, max_retries) do
    fn input ->
      do_retry(f, input, max_retries, 0)
    end
  end

  defp do_retry(f, input, max_retries, attempts) do
    try do
      f.(input)
    rescue
      e ->
        if attempts < max_retries do
          do_retry(f, input, max_retries, attempts + 1)
        else
          reraise e, __STACKTRACE__
        end
    end
  end

  @doc """
  メモ化（キャッシュ）機能付きの関数ラッパーを作成する。
  Agent を使用してキャッシュを管理する。

  ## Examples

      iex> {:ok, memoized} = Chapter02.memoize(fn x -> x * 2 end)
      iex> memoized.(5)
      10
      iex> memoized.(5)
      10
  """
  @spec memoize((a -> b)) :: {:ok, (a -> b)} when a: any(), b: any()
  def memoize(f) do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    memoized_fn = fn input ->
      Agent.get_and_update(agent, fn cache ->
        case Map.get(cache, input) do
          nil ->
            result = f.(input)
            {result, Map.put(cache, input, result)}

          cached ->
            {cached, cache}
        end
      end)
    end

    {:ok, memoized_fn}
  end

  # ============================================================
  # 5. パイプライン処理
  # ============================================================

  defmodule OrderItem do
    @moduledoc "注文アイテム"
    defstruct [:price, :quantity]

    @type t :: %__MODULE__{
            price: non_neg_integer(),
            quantity: non_neg_integer()
          }
  end

  defmodule Customer do
    @moduledoc "顧客"
    defstruct [:membership]

    @type t :: %__MODULE__{
            membership: String.t()
          }
  end

  defmodule Order do
    @moduledoc "注文"
    defstruct [:items, :customer, total: 0, shipping: 0]

    @type t :: %__MODULE__{
            items: [OrderItem.t()],
            customer: Customer.t(),
            total: number(),
            shipping: non_neg_integer()
          }
  end

  @doc """
  注文をバリデートする。

  ## Examples

      iex> order = %Chapter02.Order{items: [], customer: %Chapter02.Customer{membership: "gold"}}
      iex> Chapter02.validate_order(order)
      ** (ArgumentError) 注文にアイテムがありません
  """
  @spec validate_order(Order.t()) :: Order.t()
  def validate_order(%Order{items: []} = _order) do
    raise ArgumentError, "注文にアイテムがありません"
  end

  def validate_order(%Order{} = order), do: order

  @doc """
  注文の合計を計算する。

  ## Examples

      iex> items = [%Chapter02.OrderItem{price: 1000, quantity: 2}]
      iex> order = %Chapter02.Order{items: items, customer: %Chapter02.Customer{membership: "gold"}}
      iex> result = Chapter02.calculate_order_total(order)
      iex> result.total
      2000
  """
  @spec calculate_order_total(Order.t()) :: Order.t()
  def calculate_order_total(%Order{items: items} = order) do
    total = Enum.reduce(items, 0, fn item, acc -> acc + item.price * item.quantity end)
    %{order | total: total}
  end

  @doc """
  会員割引を適用する。

  ## Examples

      iex> order = %Chapter02.Order{
      ...>   items: [],
      ...>   customer: %Chapter02.Customer{membership: "gold"},
      ...>   total: 1000
      ...> }
      iex> result = Chapter02.apply_order_discount(order)
      iex> result.total
      900.0
  """
  @spec apply_order_discount(Order.t()) :: Order.t()
  def apply_order_discount(%Order{customer: customer, total: total} = order) do
    discount_rates = %{"gold" => 0.1, "silver" => 0.05, "bronze" => 0.02}
    discount_rate = Map.get(discount_rates, customer.membership, 0.0)
    %{order | total: total * (1 - discount_rate)}
  end

  @doc """
  送料を追加する。

  ## Examples

      iex> order = %Chapter02.Order{items: [], customer: nil, total: 3000}
      iex> result = Chapter02.add_shipping(order)
      iex> result.shipping
      500
      iex> result.total
      3500
  """
  @spec add_shipping(Order.t()) :: Order.t()
  def add_shipping(%Order{total: total} = order) do
    shipping = if total >= 5000, do: 0, else: 500
    %{order | shipping: shipping, total: total + shipping}
  end

  @doc """
  注文処理パイプラインを実行する。

  ## Examples

      iex> items = [
      ...>   %Chapter02.OrderItem{price: 1000, quantity: 2},
      ...>   %Chapter02.OrderItem{price: 500, quantity: 3}
      ...> ]
      iex> order = %Chapter02.Order{items: items, customer: %Chapter02.Customer{membership: "gold"}}
      iex> result = Chapter02.process_order_pipeline(order)
      iex> result.total
      3650.0
  """
  @spec process_order_pipeline(Order.t()) :: Order.t()
  def process_order_pipeline(order) do
    order
    |> validate_order()
    |> calculate_order_total()
    |> apply_order_discount()
    |> add_shipping()
  end

  # ============================================================
  # 6. バリデーション合成
  # ============================================================

  defmodule ValidationResult do
    @moduledoc "バリデーション結果"
    defstruct [:valid, :value, :error]

    @type t(a) :: %__MODULE__{
            valid: boolean(),
            value: a,
            error: String.t() | nil
          }
  end

  @doc """
  バリデータを作成する。

  ## Examples

      iex> is_positive = Chapter02.validator(fn x -> x > 0 end, "値は正の数である必要があります")
      iex> result = is_positive.(5)
      iex> result.valid
      true
      iex> result = is_positive.(-1)
      iex> result.valid
      false
      iex> result.error
      "値は正の数である必要があります"
  """
  @spec validator((a -> boolean()), String.t()) :: (a -> ValidationResult.t(a)) when a: any()
  def validator(pred, error_msg) do
    fn value ->
      if pred.(value) do
        %ValidationResult{valid: true, value: value, error: nil}
      else
        %ValidationResult{valid: false, value: value, error: error_msg}
      end
    end
  end

  @doc """
  複数のバリデータを合成する。

  ## Examples

      iex> is_positive = Chapter02.validator(fn x -> x > 0 end, "正の数が必要")
      iex> under_100 = Chapter02.validator(fn x -> x < 100 end, "100未満が必要")
      iex> validate = Chapter02.combine_validators([is_positive, under_100])
      iex> result = validate.(50)
      iex> result.valid
      true
      iex> result = validate.(-1)
      iex> result.valid
      false
  """
  @spec combine_validators([function()]) :: (a -> ValidationResult.t(a)) when a: any()
  def combine_validators(validators) do
    fn value ->
      Enum.reduce_while(validators, %ValidationResult{valid: true, value: value}, fn v, acc ->
        result = v.(acc.value)

        if result.valid do
          {:cont, result}
        else
          {:halt, result}
        end
      end)
    end
  end

  # ============================================================
  # 7. 関数の変換
  # ============================================================

  @doc """
  引数の順序を反転する。

  ## Examples

      iex> subtract = fn a, b -> a - b end
      iex> flipped = Chapter02.flip(subtract)
      iex> flipped.(3, 5)
      2
  """
  @spec flip((a, b -> c)) :: (b, a -> c) when a: any(), b: any(), c: any()
  def flip(f) do
    fn b, a -> f.(a, b) end
  end

  @doc """
  2引数関数をカリー化する。

  ## Examples

      iex> add = fn a, b -> a + b end
      iex> curried = Chapter02.curry(add)
      iex> add_5 = curried.(5)
      iex> add_5.(3)
      8
  """
  @spec curry((a, b -> c)) :: (a -> (b -> c)) when a: any(), b: any(), c: any()
  def curry(f) do
    fn a -> fn b -> f.(a, b) end end
  end

  @doc """
  カリー化された関数を非カリー化する。

  ## Examples

      iex> curried_add = fn a -> fn b -> a + b end end
      iex> uncurried = Chapter02.uncurry(curried_add)
      iex> uncurried.(5, 3)
      8
  """
  @spec uncurry((a -> (b -> c))) :: (a, b -> c) when a: any(), b: any(), c: any()
  def uncurry(f) do
    fn a, b -> f.(a).(b) end
  end

  @doc """
  述語関数の補関数を作成する。

  ## Examples

      iex> is_even = fn x -> rem(x, 2) == 0 end
      iex> is_odd = Chapter02.complement(is_even)
      iex> is_odd.(3)
      true
      iex> is_odd.(4)
      false
  """
  @spec complement((a -> boolean())) :: (a -> boolean()) when a: any()
  def complement(pred) do
    fn x -> not pred.(x) end
  end

  # ============================================================
  # 8. 述語の合成
  # ============================================================

  @doc """
  複数の述語をANDで合成する。

  ## Examples

      iex> valid_age = Chapter02.compose_predicates_and([
      ...>   fn x -> x > 0 end,
      ...>   fn x -> x <= 150 end
      ...> ])
      iex> valid_age.(25)
      true
      iex> valid_age.(-1)
      false
      iex> valid_age.(200)
      false
  """
  @spec compose_predicates_and([(a -> boolean())]) :: (a -> boolean()) when a: any()
  def compose_predicates_and(preds) do
    fn x -> Enum.all?(preds, fn pred -> pred.(x) end) end
  end

  @doc """
  複数の述語をORで合成する。

  ## Examples

      iex> is_special = Chapter02.compose_predicates_or([
      ...>   fn x -> x == 0 end,
      ...>   fn x -> x == 100 end
      ...> ])
      iex> is_special.(0)
      true
      iex> is_special.(100)
      true
      iex> is_special.(50)
      false
  """
  @spec compose_predicates_or([(a -> boolean())]) :: (a -> boolean()) when a: any()
  def compose_predicates_or(preds) do
    fn x -> Enum.any?(preds, fn pred -> pred.(x) end) end
  end

  defmodule CustomerInfo do
    @moduledoc "顧客情報"
    defstruct [:membership, :purchase_count, :total_spent]

    @type t :: %__MODULE__{
            membership: String.t(),
            purchase_count: non_neg_integer(),
            total_spent: non_neg_integer()
          }
  end

  @doc """
  プレミアム顧客かどうかを判定する。

  ## Examples

      iex> checker = Chapter02.premium_customer_checker()
      iex> checker.(%Chapter02.CustomerInfo{membership: "gold", purchase_count: 0, total_spent: 0})
      true
      iex> checker.(%Chapter02.CustomerInfo{membership: "bronze", purchase_count: 100, total_spent: 0})
      true
      iex> checker.(%Chapter02.CustomerInfo{membership: "bronze", purchase_count: 10, total_spent: 1000})
      false
  """
  @spec premium_customer_checker() :: (CustomerInfo.t() -> boolean())
  def premium_customer_checker do
    compose_predicates_or([
      fn c -> c.membership == "gold" end,
      fn c -> c.purchase_count >= 100 end,
      fn c -> c.total_spent >= 100_000 end
    ])
  end

  # ============================================================
  # 9. 関数のキャプチャとアリティ
  # ============================================================

  @doc """
  リストの要素を2倍にする（キャプチャ演算子の例）。

  ## Examples

      iex> Chapter02.double_all([1, 2, 3])
      [2, 4, 6]
  """
  @spec double_all([number()]) :: [number()]
  def double_all(list) do
    Enum.map(list, &(&1 * 2))
  end

  @doc """
  リストの要素を文字列に変換する（関数参照の例）。

  ## Examples

      iex> Chapter02.stringify_all([1, 2, 3])
      ["1", "2", "3"]
  """
  @spec stringify_all([any()]) :: [String.t()]
  def stringify_all(list) do
    Enum.map(list, &to_string/1)
  end
end
