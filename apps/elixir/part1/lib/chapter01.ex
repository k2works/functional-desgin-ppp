defmodule Chapter01 do
  @moduledoc """
  第1章: 不変性とデータ変換

  Elixir における不変データ構造の基本から、パイプ演算子によるデータ変換、
  副作用の分離まで、実践的な例を通じて学びます。
  """

  # ============================================================
  # 1. 不変データ構造の基本
  # ============================================================

  defmodule Person do
    @moduledoc "人物を表す構造体。Elixir ではすべてのデータがデフォルトで不変。"
    @enforce_keys [:name, :age]
    defstruct [:name, :age]

    @type t :: %__MODULE__{
            name: String.t(),
            age: non_neg_integer()
          }
  end

  @doc """
  Person の年齢を更新した新しい Person を返す。
  元のデータは変更されない。

  ## Examples

      iex> person = %Chapter01.Person{name: "田中", age: 30}
      iex> Chapter01.update_age(person, 31)
      %Chapter01.Person{name: "田中", age: 31}
      iex> person.age
      30
  """
  @spec update_age(Person.t(), non_neg_integer()) :: Person.t()
  def update_age(%Person{} = person, new_age) do
    %{person | age: new_age}
  end

  @doc """
  Person に誕生日が来た（年齢 +1）新しい Person を返す。

  ## Examples

      iex> person = %Chapter01.Person{name: "鈴木", age: 25}
      iex> Chapter01.birthday(person)
      %Chapter01.Person{name: "鈴木", age: 26}
  """
  @spec birthday(Person.t()) :: Person.t()
  def birthday(%Person{age: age} = person) do
    %{person | age: age + 1}
  end

  # ============================================================
  # 2. 構造共有（Structural Sharing）
  # ============================================================

  defmodule Member do
    @enforce_keys [:name, :role]
    defstruct [:name, :role]

    @type t :: %__MODULE__{
            name: String.t(),
            role: String.t()
          }
  end

  defmodule Team do
    @enforce_keys [:name, :members]
    defstruct [:name, :members]

    @type t :: %__MODULE__{
            name: String.t(),
            members: [Member.t()]
          }
  end

  @doc """
  チームに新しいメンバーを追加した新しいチームを返す。
  既存のメンバーリストは共有される（構造共有）。

  ## Examples

      iex> team = %Chapter01.Team{name: "開発", members: []}
      iex> member = %Chapter01.Member{name: "山田", role: "developer"}
      iex> new_team = Chapter01.add_member(team, member)
      iex> length(new_team.members)
      1
  """
  @spec add_member(Team.t(), Member.t()) :: Team.t()
  def add_member(%Team{members: members} = team, %Member{} = member) do
    %{team | members: members ++ [member]}
  end

  @doc """
  チームからメンバーを削除した新しいチームを返す。

  ## Examples

      iex> member = %Chapter01.Member{name: "山田", role: "developer"}
      iex> team = %Chapter01.Team{name: "開発", members: [member]}
      iex> new_team = Chapter01.remove_member(team, "山田")
      iex> length(new_team.members)
      0
  """
  @spec remove_member(Team.t(), String.t()) :: Team.t()
  def remove_member(%Team{members: members} = team, name) do
    %{team | members: Enum.reject(members, &(&1.name == name))}
  end

  # ============================================================
  # 3. データ変換パイプライン
  # ============================================================

  defmodule Item do
    @enforce_keys [:name, :price, :quantity]
    defstruct [:name, :price, :quantity]

    @type t :: %__MODULE__{
            name: String.t(),
            price: non_neg_integer(),
            quantity: non_neg_integer()
          }
  end

  defmodule Customer do
    @enforce_keys [:name, :membership]
    defstruct [:name, :membership]

    @type t :: %__MODULE__{
            name: String.t(),
            membership: String.t()
          }
  end

  defmodule Order do
    @enforce_keys [:items, :customer]
    defstruct [:items, :customer]

    @type t :: %__MODULE__{
            items: [Item.t()],
            customer: Customer.t()
          }
  end

  @doc """
  アイテムの小計を計算する。

  ## Examples

      iex> item = %Chapter01.Item{name: "りんご", price: 100, quantity: 3}
      iex> Chapter01.calculate_subtotal(item)
      300
  """
  @spec calculate_subtotal(Item.t()) :: non_neg_integer()
  def calculate_subtotal(%Item{price: price, quantity: quantity}) do
    price * quantity
  end

  @doc """
  会員種別に応じた割引率を返す。

  ## Examples

      iex> Chapter01.membership_discount("gold")
      0.1
      iex> Chapter01.membership_discount("silver")
      0.05
      iex> Chapter01.membership_discount("bronze")
      0.02
      iex> Chapter01.membership_discount("regular")
      0.0
  """
  @spec membership_discount(String.t()) :: float()
  def membership_discount(membership) do
    case membership do
      "gold" -> 0.1
      "silver" -> 0.05
      "bronze" -> 0.02
      _ -> 0.0
    end
  end

  @doc """
  注文の合計金額を計算する。

  ## Examples

      iex> items = [
      ...>   %Chapter01.Item{name: "りんご", price: 100, quantity: 3},
      ...>   %Chapter01.Item{name: "みかん", price: 80, quantity: 5}
      ...> ]
      iex> Chapter01.calculate_total(items)
      700
  """
  @spec calculate_total([Item.t()]) :: non_neg_integer()
  def calculate_total(items) do
    items
    |> Enum.map(&calculate_subtotal/1)
    |> Enum.sum()
  end

  @doc """
  割引を適用した金額を計算する。

  ## Examples

      iex> Chapter01.apply_discount(1000, "gold")
      900.0
  """
  @spec apply_discount(number(), String.t()) :: float()
  def apply_discount(total, membership) do
    discount_rate = membership_discount(membership)
    total * (1 - discount_rate)
  end

  @doc """
  注文を処理し、割引後の合計金額を返す。
  パイプ演算子を使用したデータ変換パイプラインの例。

  ## Examples

      iex> items = [%Chapter01.Item{name: "りんご", price: 100, quantity: 10}]
      iex> customer = %Chapter01.Customer{name: "田中", membership: "gold"}
      iex> order = %Chapter01.Order{items: items, customer: customer}
      iex> Chapter01.process_order(order)
      900.0
  """
  @spec process_order(Order.t()) :: float()
  def process_order(%Order{items: items, customer: customer}) do
    items
    |> calculate_total()
    |> apply_discount(customer.membership)
  end

  # ============================================================
  # 4. 副作用の分離
  # ============================================================

  defmodule Invoice do
    @enforce_keys [:subtotal, :tax, :total]
    defstruct [:subtotal, :tax, :total]

    @type t :: %__MODULE__{
            subtotal: non_neg_integer(),
            tax: float(),
            total: float()
          }
  end

  @doc """
  税金を計算する（純粋関数）。

  ## Examples

      iex> Chapter01.calculate_tax(1000, 0.1)
      100.0
  """
  @spec calculate_tax(number(), float()) :: float()
  def calculate_tax(amount, tax_rate) do
    amount * tax_rate
  end

  @doc """
  請求書を計算する（純粋関数）。
  副作用なし - 同じ入力に対して常に同じ出力。

  ## Examples

      iex> items = [%Chapter01.Item{name: "本", price: 1000, quantity: 1}]
      iex> invoice = Chapter01.calculate_invoice(items, 0.1)
      iex> invoice.subtotal
      1000
      iex> invoice.tax
      100.0
      iex> invoice.total
      1100.0
  """
  @spec calculate_invoice([Item.t()], float()) :: Invoice.t()
  def calculate_invoice(items, tax_rate) do
    subtotal = calculate_total(items)
    tax = calculate_tax(subtotal, tax_rate)
    total = subtotal + tax

    %Invoice{subtotal: subtotal, tax: tax, total: total}
  end

  @doc """
  請求書を保存する（副作用あり - ログ出力）。
  実際のアプリケーションではDBへの保存など。
  """
  @spec save_invoice(Invoice.t()) :: Invoice.t()
  def save_invoice(%Invoice{} = invoice) do
    # 副作用: ログ出力（実際にはDB保存など）
    IO.puts("Saving invoice: #{inspect(invoice)}")
    invoice
  end

  @doc """
  通知を送信する（副作用あり）。
  """
  @spec send_notification(Invoice.t(), String.t()) :: Invoice.t()
  def send_notification(%Invoice{} = invoice, customer_email) do
    # 副作用: 通知送信
    IO.puts("Sending notification to: #{customer_email}")
    invoice
  end

  @doc """
  請求書処理全体のオーケストレーション。
  純粋関数と副作用を持つ関数を組み合わせる。
  """
  @spec process_and_save_invoice([Item.t()], float(), String.t()) :: Invoice.t()
  def process_and_save_invoice(items, tax_rate, customer_email) do
    items
    |> calculate_invoice(tax_rate)
    |> save_invoice()
    |> send_notification(customer_email)
  end

  # ============================================================
  # 5. 履歴管理（Undo/Redo）
  # ============================================================

  defmodule History do
    @moduledoc """
    不変データ構造を活用した履歴管理。
    Undo/Redo 操作を簡潔に実装できる。
    """
    defstruct current: nil, past: [], future: []

    @type t(a) :: %__MODULE__{
            current: a | nil,
            past: [a],
            future: [a]
          }
  end

  @doc """
  空の履歴を作成する。

  ## Examples

      iex> history = Chapter01.create_history()
      iex> history.current
      nil
      iex> history.past
      []
  """
  @spec create_history() :: History.t(any())
  def create_history do
    %History{}
  end

  @doc """
  新しい状態を履歴にプッシュする。

  ## Examples

      iex> history = Chapter01.create_history()
      iex> history = Chapter01.push_state(history, %{text: "Hello"})
      iex> history.current
      %{text: "Hello"}
  """
  @spec push_state(History.t(a), a) :: History.t(a) when a: any()
  def push_state(%History{current: nil} = history, new_state) do
    %{history | current: new_state}
  end

  def push_state(%History{current: current, past: past} = history, new_state) do
    %{history | current: new_state, past: [current | past], future: []}
  end

  @doc """
  直前の状態に戻す（Undo）。

  ## Examples

      iex> history = Chapter01.create_history()
      iex> history = Chapter01.push_state(history, %{text: "v1"})
      iex> history = Chapter01.push_state(history, %{text: "v2"})
      iex> history = Chapter01.undo(history)
      iex> history.current
      %{text: "v1"}
  """
  @spec undo(History.t(a)) :: History.t(a) when a: any()
  def undo(%History{past: []} = history), do: history

  def undo(%History{current: current, past: [previous | rest], future: future}) do
    %History{current: previous, past: rest, future: [current | future]}
  end

  @doc """
  やり直し操作（Redo）。

  ## Examples

      iex> history = Chapter01.create_history()
      iex> history = Chapter01.push_state(history, %{text: "v1"})
      iex> history = Chapter01.push_state(history, %{text: "v2"})
      iex> history = Chapter01.undo(history)
      iex> history = Chapter01.redo(history)
      iex> history.current
      %{text: "v2"}
  """
  @spec redo(History.t(a)) :: History.t(a) when a: any()
  def redo(%History{future: []} = history), do: history

  def redo(%History{current: current, past: past, future: [next | rest]}) do
    %History{current: next, past: [current | past], future: rest}
  end

  # ============================================================
  # 6. Stream による遅延評価
  # ============================================================

  defmodule ProcessedItem do
    @enforce_keys [:name, :price, :quantity, :subtotal]
    defstruct [:name, :price, :quantity, :subtotal]

    @type t :: %__MODULE__{
            name: String.t(),
            price: non_neg_integer(),
            quantity: non_neg_integer(),
            subtotal: non_neg_integer()
          }
  end

  @doc """
  アイテムを処理する（通常のEnumによる即時評価）。

  ## Examples

      iex> items = [
      ...>   %Chapter01.Item{name: "A", price: 100, quantity: 2},
      ...>   %Chapter01.Item{name: "B", price: 50, quantity: 0},
      ...>   %Chapter01.Item{name: "C", price: 200, quantity: 1}
      ...> ]
      iex> result = Chapter01.process_items(items)
      iex> length(result)
      2
      iex> hd(result).name
      "A"
  """
  @spec process_items([Item.t()]) :: [ProcessedItem.t()]
  def process_items(items) do
    items
    |> Enum.filter(&(&1.quantity > 0))
    |> Enum.map(fn item ->
      %ProcessedItem{
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        subtotal: calculate_subtotal(item)
      }
    end)
    |> Enum.filter(&(&1.subtotal > 100))
  end

  @doc """
  アイテムを処理する（Streamによる遅延評価）。
  大量データに対して効率的。

  ## Examples

      iex> items = [
      ...>   %Chapter01.Item{name: "A", price: 100, quantity: 2},
      ...>   %Chapter01.Item{name: "B", price: 50, quantity: 0},
      ...>   %Chapter01.Item{name: "C", price: 200, quantity: 1}
      ...> ]
      iex> result = Chapter01.process_items_lazy(items)
      iex> length(result)
      2
  """
  @spec process_items_lazy([Item.t()]) :: [ProcessedItem.t()]
  def process_items_lazy(items) do
    items
    |> Stream.filter(&(&1.quantity > 0))
    |> Stream.map(fn item ->
      %ProcessedItem{
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        subtotal: calculate_subtotal(item)
      }
    end)
    |> Stream.filter(&(&1.subtotal > 100))
    |> Enum.to_list()
  end

  @doc """
  無限ストリームから偶数を取得する例。

  ## Examples

      iex> Chapter01.take_even_numbers(5)
      [2, 4, 6, 8, 10]
  """
  @spec take_even_numbers(non_neg_integer()) :: [non_neg_integer()]
  def take_even_numbers(count) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.filter(&(rem(&1, 2) == 0))
    |> Enum.take(count)
  end

  # ============================================================
  # 7. マップ操作（ネストしたデータの更新）
  # ============================================================

  @doc """
  ネストしたマップのキーを更新する。
  Kernel.put_in/3 を使用。

  ## Examples

      iex> data = %{user: %{profile: %{name: "田中", age: 30}}}
      iex> Chapter01.update_nested_name(data, "鈴木")
      %{user: %{profile: %{name: "鈴木", age: 30}}}
  """
  @spec update_nested_name(map(), String.t()) :: map()
  def update_nested_name(data, new_name) do
    put_in(data, [:user, :profile, :name], new_name)
  end

  @doc """
  ネストしたマップの値を関数で更新する。
  Kernel.update_in/3 を使用。

  ## Examples

      iex> data = %{user: %{profile: %{name: "田中", age: 30}}}
      iex> Chapter01.increment_nested_age(data)
      %{user: %{profile: %{name: "田中", age: 31}}}
  """
  @spec increment_nested_age(map()) :: map()
  def increment_nested_age(data) do
    update_in(data, [:user, :profile, :age], &(&1 + 1))
  end

  @doc """
  ネストしたマップから値を取得する。
  Kernel.get_in/2 を使用。

  ## Examples

      iex> data = %{user: %{profile: %{name: "田中", age: 30}}}
      iex> Chapter01.get_nested_name(data)
      "田中"
  """
  @spec get_nested_name(map()) :: any()
  def get_nested_name(data) do
    get_in(data, [:user, :profile, :name])
  end
end
