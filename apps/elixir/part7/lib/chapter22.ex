# Chapter 22: OO から FP への移行
#
# オブジェクト指向プログラミングから関数型プログラミングへの
# 移行パターンとリファクタリング手法を示します。

defmodule Chapter22 do
  @moduledoc """
  OO から FP への移行

  このモジュールでは、以下のトピックを扱います：
  1. クラスからモジュールへ
  2. 継承からコンポジションへ
  3. ミュータブル状態からイミュータブル変換へ
  4. デザインパターンの変換
  5. 実践的な移行例
  """

  # ============================================================
  # 1. クラスからモジュールへ
  # ============================================================

  defmodule ClassToModule do
    @moduledoc """
    OOPのクラスをElixirのモジュールに変換するパターン
    """

    # OOP風のクラス（変換前のイメージ）
    # class BankAccount:
    #     def __init__(self, owner, balance=0):
    #         self.owner = owner
    #         self.balance = balance
    #
    #     def deposit(self, amount):
    #         self.balance += amount
    #
    #     def withdraw(self, amount):
    #         if amount <= self.balance:
    #             self.balance -= amount
    #             return True
    #         return False

    # Elixir版: 構造体 + 関数
    defmodule BankAccount do
      @moduledoc "銀行口座を表すモジュール"

      defstruct [:owner, balance: 0]

      @doc "新しい口座を作成"
      def new(owner, balance \\ 0) do
        %__MODULE__{owner: owner, balance: balance}
      end

      @doc "入金（新しい口座を返す）"
      def deposit(account, amount) when amount > 0 do
        %{account | balance: account.balance + amount}
      end

      @doc "出金（成功/失敗をタプルで返す）"
      def withdraw(account, amount) when amount > 0 do
        if amount <= account.balance do
          {:ok, %{account | balance: account.balance - amount}}
        else
          {:error, :insufficient_funds}
        end
      end

      @doc "残高照会"
      def balance(%__MODULE__{balance: b}), do: b

      @doc "口座所有者"
      def owner(%__MODULE__{owner: o}), do: o
    end

    # シングルトンパターンの代替: モジュール属性
    defmodule Configuration do
      @default_timeout 5000
      @max_retries 3

      def timeout, do: @default_timeout
      def max_retries, do: @max_retries
    end

    # ファクトリパターンの代替: 関数
    defmodule ShapeFactory do
      def create(:circle, radius) do
        %{type: :circle, radius: radius}
      end

      def create(:rectangle, width, height) do
        %{type: :rectangle, width: width, height: height}
      end

      def create(:square, side) do
        %{type: :square, side: side}
      end

      def area(%{type: :circle, radius: r}), do: :math.pi() * r * r
      def area(%{type: :rectangle, width: w, height: h}), do: w * h
      def area(%{type: :square, side: s}), do: s * s
    end
  end

  # ============================================================
  # 2. 継承からコンポジションへ
  # ============================================================

  defmodule InheritanceToComposition do
    @moduledoc """
    OOPの継承をコンポジションとプロトコルで置き換える
    """

    # OOP風の継承（変換前のイメージ）
    # class Animal:
    #     def speak(self): pass
    #
    # class Dog(Animal):
    #     def speak(self): return "Woof!"
    #
    # class Cat(Animal):
    #     def speak(self): return "Meow!"

    # Elixir版: プロトコル
    defprotocol Speakable do
      @doc "動物の鳴き声を返す"
      def speak(animal)
    end

    defmodule Dog do
      defstruct [:name]
      def new(name), do: %__MODULE__{name: name}
    end

    defmodule Cat do
      defstruct [:name]
      def new(name), do: %__MODULE__{name: name}
    end

    defimpl Speakable, for: Dog do
      def speak(_dog), do: "Woof!"
    end

    defimpl Speakable, for: Cat do
      def speak(_cat), do: "Meow!"
    end

    # ビヘイビアによる共通インターフェース
    defmodule Serializable do
      @callback to_json(term()) :: String.t()
      @callback from_json(String.t()) :: {:ok, term()} | {:error, term()}
    end

    defmodule User do
      @behaviour Serializable

      defstruct [:id, :name, :email]

      def new(id, name, email) do
        %__MODULE__{id: id, name: name, email: email}
      end

      @impl true
      def to_json(%__MODULE__{id: id, name: name, email: email}) do
        ~s({"id":#{id},"name":"#{name}","email":"#{email}"})
      end

      @impl true
      def from_json(json) do
        # 簡易パーサー
        with {:ok, id} <- extract_field(json, "id", :integer),
             {:ok, name} <- extract_field(json, "name", :string),
             {:ok, email} <- extract_field(json, "email", :string) do
          {:ok, %__MODULE__{id: id, name: name, email: email}}
        end
      end

      defp extract_field(json, field, :integer) do
        case Regex.run(~r/"#{field}":(\d+)/, json) do
          [_, value] -> {:ok, String.to_integer(value)}
          _ -> {:error, {:missing_field, field}}
        end
      end

      defp extract_field(json, field, :string) do
        case Regex.run(~r/"#{field}":"([^"]*)"/, json) do
          [_, value] -> {:ok, value}
          _ -> {:error, {:missing_field, field}}
        end
      end
    end

    # テンプレートメソッドの代替: 高階関数
    defmodule DataProcessor do
      @doc "データ処理のテンプレート"
      def process(data, opts \\ []) do
        parser = Keyword.get(opts, :parser, &default_parse/1)
        validator = Keyword.get(opts, :validator, &default_validate/1)
        transformer = Keyword.get(opts, :transformer, &default_transform/1)

        data
        |> parser.()
        |> validator.()
        |> transformer.()
      end

      defp default_parse(data), do: {:ok, data}
      defp default_validate({:ok, data}), do: {:ok, data}
      defp default_validate(error), do: error
      defp default_transform({:ok, data}), do: {:ok, data}
      defp default_transform(error), do: error
    end
  end

  # ============================================================
  # 3. ミュータブル状態からイミュータブル変換へ
  # ============================================================

  defmodule MutableToImmutable do
    @moduledoc """
    ミュータブルな状態操作をイミュータブルな変換に置き換える
    """

    # OOP風のミュータブル状態（変換前のイメージ）
    # class ShoppingCart:
    #     def __init__(self):
    #         self.items = []
    #
    #     def add_item(self, item):
    #         self.items.append(item)
    #
    #     def remove_item(self, item_id):
    #         self.items = [i for i in self.items if i.id != item_id]
    #
    #     def total(self):
    #         return sum(i.price for i in self.items)

    # Elixir版: イミュータブルな構造体
    defmodule ShoppingCart do
      defstruct items: []

      def new, do: %__MODULE__{}

      def add_item(cart, item) do
        %{cart | items: [item | cart.items]}
      end

      def remove_item(cart, item_id) do
        items = Enum.reject(cart.items, &(&1.id == item_id))
        %{cart | items: items}
      end

      def update_quantity(cart, item_id, quantity) do
        items = Enum.map(cart.items, fn item ->
          if item.id == item_id do
            %{item | quantity: quantity}
          else
            item
          end
        end)
        %{cart | items: items}
      end

      def total(cart) do
        cart.items
        |> Enum.map(&(&1.price * &1.quantity))
        |> Enum.sum()
      end

      def item_count(cart) do
        cart.items
        |> Enum.map(& &1.quantity)
        |> Enum.sum()
      end
    end

    # 状態遷移のパターン
    defmodule OrderState do
      @doc "注文の状態遷移（純粋関数）"
      def transition(%{status: :pending} = order, :confirm) do
        {:ok, order |> Map.put(:status, :confirmed) |> Map.put(:confirmed_at, DateTime.utc_now())}
      end

      def transition(%{status: :confirmed} = order, :ship) do
        {:ok, order |> Map.put(:status, :shipped) |> Map.put(:shipped_at, DateTime.utc_now())}
      end

      def transition(%{status: :shipped} = order, :deliver) do
        {:ok, order |> Map.put(:status, :delivered) |> Map.put(:delivered_at, DateTime.utc_now())}
      end

      def transition(%{status: :pending} = order, :cancel) do
        {:ok, order |> Map.put(:status, :cancelled) |> Map.put(:cancelled_at, DateTime.utc_now())}
      end

      def transition(%{status: :confirmed} = order, :cancel) do
        {:ok, order |> Map.put(:status, :cancelled) |> Map.put(:cancelled_at, DateTime.utc_now())}
      end

      def transition(%{status: status}, action) do
        {:error, {:invalid_transition, status, action}}
      end
    end

    # イベントソーシング的アプローチ
    defmodule EventSourced do
      defmodule Account do
        defstruct [:id, :balance, :events]

        def new(id) do
          %__MODULE__{id: id, balance: 0, events: []}
        end

        def apply_event(account, {:deposited, amount, timestamp}) do
          %{account |
            balance: account.balance + amount,
            events: [{:deposited, amount, timestamp} | account.events]
          }
        end

        def apply_event(account, {:withdrawn, amount, timestamp}) do
          %{account |
            balance: account.balance - amount,
            events: [{:withdrawn, amount, timestamp} | account.events]
          }
        end

        def deposit(account, amount) when amount > 0 do
          event = {:deposited, amount, DateTime.utc_now()}
          {:ok, apply_event(account, event)}
        end

        def withdraw(account, amount) when amount > 0 do
          if amount <= account.balance do
            event = {:withdrawn, amount, DateTime.utc_now()}
            {:ok, apply_event(account, event)}
          else
            {:error, :insufficient_funds}
          end
        end

        def history(account) do
          Enum.reverse(account.events)
        end

        def replay(account, events) do
          Enum.reduce(events, account, &apply_event(&2, &1))
        end
      end
    end
  end

  # ============================================================
  # 4. デザインパターンの変換
  # ============================================================

  defmodule PatternTransformation do
    @moduledoc """
    GoFデザインパターンの関数型への変換
    """

    # Strategy パターン -> 高階関数
    defmodule StrategyToFunction do
      @doc "ソート戦略を関数として渡す"
      def sort(items, comparator \\ &<=/2) do
        Enum.sort(items, comparator)
      end

      # 事前定義された戦略
      def by_name, do: fn a, b -> a.name <= b.name end
      def by_price, do: fn a, b -> a.price <= b.price end
      def by_date, do: fn a, b -> Date.compare(a.date, b.date) != :gt end
    end

    # Observer パターン -> メッセージパッシング
    defmodule ObserverToMessages do
      use GenServer

      def start_link(opts \\ []) do
        name = Keyword.get(opts, :name)
        GenServer.start_link(__MODULE__, [], name: name)
      end

      def subscribe(pid, subscriber) do
        GenServer.call(pid, {:subscribe, subscriber})
      end

      def unsubscribe(pid, subscriber_id) do
        GenServer.call(pid, {:unsubscribe, subscriber_id})
      end

      def notify(pid, event) do
        GenServer.cast(pid, {:notify, event})
      end

      def stop(pid) do
        if Process.alive?(pid), do: GenServer.stop(pid)
      end

      @impl true
      def init(_) do
        {:ok, %{subscribers: [], next_id: 1}}
      end

      @impl true
      def handle_call({:subscribe, subscriber}, _from, state) do
        id = state.next_id
        subscribers = [{id, subscriber} | state.subscribers]
        {:reply, {:ok, id}, %{state | subscribers: subscribers, next_id: id + 1}}
      end

      @impl true
      def handle_call({:unsubscribe, id}, _from, state) do
        subscribers = Enum.reject(state.subscribers, fn {sid, _} -> sid == id end)
        {:reply, :ok, %{state | subscribers: subscribers}}
      end

      @impl true
      def handle_cast({:notify, event}, state) do
        Enum.each(state.subscribers, fn {_id, subscriber} ->
          send(subscriber, {:event, event})
        end)
        {:noreply, state}
      end
    end

    # Decorator パターン -> 関数合成
    defmodule DecoratorToComposition do
      @doc "基本的なロガー"
      def log(message) do
        "[LOG] #{message}"
      end

      @doc "タイムスタンプを追加"
      def with_timestamp(log_fn) do
        fn message ->
          timestamp = DateTime.utc_now() |> DateTime.to_string()
          log_fn.("[#{timestamp}] #{message}")
        end
      end

      @doc "レベルを追加"
      def with_level(log_fn, level) do
        fn message ->
          log_fn.("[#{level}] #{message}")
        end
      end

      @doc "フォーマットを追加"
      def with_format(log_fn, format) do
        fn message ->
          formatted = String.replace(format, "%m", message)
          log_fn.(formatted)
        end
      end

      @doc "複合ロガーを作成"
      def create_logger do
        (&log/1)
        |> with_timestamp()
        |> with_level(:info)
      end
    end

    # Command パターン -> データとしてのコマンド
    defmodule CommandToData do
      @doc "コマンドを実行"
      def execute({:create_user, name, email}) do
        {:ok, %{id: :erlang.unique_integer([:positive]), name: name, email: email}}
      end

      def execute({:delete_user, id}) do
        {:ok, {:deleted, id}}
      end

      def execute({:update_user, id, changes}) do
        {:ok, {:updated, id, changes}}
      end

      @doc "コマンドのバッチ実行"
      def execute_batch(commands) do
        Enum.map(commands, &execute/1)
      end

      @doc "アンドゥ可能なコマンド"
      def execute_with_undo({:create_user, _, _} = cmd) do
        case execute(cmd) do
          {:ok, user} -> {:ok, user, {:delete_user, user.id}}
          error -> error
        end
      end

      def execute_with_undo({:update_user, id, changes}) do
        # 実際には元の状態を保存する必要がある
        {:ok, {:updated, id, changes}, {:update_user, id, %{}}}
      end
    end

    # Visitor パターン -> パターンマッチ
    defmodule VisitorToPatternMatch do
      @doc "式を評価"
      def eval({:number, n}), do: n
      def eval({:add, a, b}), do: eval(a) + eval(b)
      def eval({:sub, a, b}), do: eval(a) - eval(b)
      def eval({:mul, a, b}), do: eval(a) * eval(b)
      def eval({:div, a, b}), do: eval(a) / eval(b)
      def eval({:neg, a}), do: -eval(a)

      @doc "式を文字列化"
      def stringify({:number, n}), do: "#{n}"
      def stringify({:add, a, b}), do: "(#{stringify(a)} + #{stringify(b)})"
      def stringify({:sub, a, b}), do: "(#{stringify(a)} - #{stringify(b)})"
      def stringify({:mul, a, b}), do: "(#{stringify(a)} * #{stringify(b)})"
      def stringify({:div, a, b}), do: "(#{stringify(a)} / #{stringify(b)})"
      def stringify({:neg, a}), do: "(-#{stringify(a)})"

      @doc "式を最適化"
      def optimize({:add, {:number, 0}, b}), do: optimize(b)
      def optimize({:add, a, {:number, 0}}), do: optimize(a)
      def optimize({:mul, {:number, 1}, b}), do: optimize(b)
      def optimize({:mul, a, {:number, 1}}), do: optimize(a)
      def optimize({:mul, {:number, 0}, _}), do: {:number, 0}
      def optimize({:mul, _, {:number, 0}}), do: {:number, 0}
      def optimize({op, a, b}) when op in [:add, :sub, :mul, :div] do
        {op, optimize(a), optimize(b)}
      end
      def optimize(expr), do: expr
    end
  end

  # ============================================================
  # 5. 実践的な移行例
  # ============================================================

  defmodule PracticalMigration do
    @moduledoc """
    実践的な移行例
    """

    # ユーザー管理システム
    defmodule UserManagement do
      # データ定義
      defmodule User do
        defstruct [:id, :name, :email, :role, :active, created_at: nil]

        def new(attrs) do
          Map.merge(
            %__MODULE__{
              id: :erlang.unique_integer([:positive]),
              active: true,
              created_at: DateTime.utc_now()
            },
            Map.new(attrs)
          )
        end
      end

      # 純粋な変換関数
      defmodule Transformations do
        def activate(user), do: %{user | active: true}
        def deactivate(user), do: %{user | active: false}

        def change_role(user, role) when role in [:admin, :user, :guest] do
          {:ok, %{user | role: role}}
        end
        def change_role(_user, _role), do: {:error, :invalid_role}

        def update_email(user, email) do
          if valid_email?(email) do
            {:ok, %{user | email: email}}
          else
            {:error, :invalid_email}
          end
        end

        defp valid_email?(email) do
          String.match?(email, ~r/^[\w.+-]+@[\w.-]+\.\w+$/)
        end
      end

      # クエリ関数
      defmodule Queries do
        def active_users(users) do
          Enum.filter(users, & &1.active)
        end

        def by_role(users, role) do
          Enum.filter(users, &(&1.role == role))
        end

        def find_by_email(users, email) do
          Enum.find(users, &(&1.email == email))
        end

        def admins(users), do: by_role(users, :admin)
        def guests(users), do: by_role(users, :guest)
      end

      # リポジトリ（状態を持つ）
      defmodule Repository do
        use Agent

        def start_link(opts \\ []) do
          name = Keyword.get(opts, :name, __MODULE__)
          Agent.start_link(fn -> %{} end, name: name)
        end

        def add(user, repo \\ __MODULE__) do
          Agent.update(repo, &Map.put(&1, user.id, user))
          user
        end

        def get(id, repo \\ __MODULE__) do
          Agent.get(repo, &Map.get(&1, id))
        end

        def update(user, repo \\ __MODULE__) do
          Agent.update(repo, &Map.put(&1, user.id, user))
          user
        end

        def delete(id, repo \\ __MODULE__) do
          Agent.update(repo, &Map.delete(&1, id))
          :ok
        end

        def all(repo \\ __MODULE__) do
          Agent.get(repo, &Map.values(&1))
        end

        def clear(repo \\ __MODULE__) do
          Agent.update(repo, fn _ -> %{} end)
        end

        def stop(repo \\ __MODULE__) do
          pid = case repo do
            name when is_atom(name) -> Process.whereis(name)
            pid when is_pid(pid) -> pid
          end
          if pid && Process.alive?(pid), do: Agent.stop(pid)
        end
      end

      # サービス層（ビジネスロジックの調整）
      defmodule Service do
        alias UserManagement.{User, Transformations, Repository}

        def create_user(attrs, repo \\ Repository) do
          user = User.new(attrs)
          Repository.add(user, repo)
          {:ok, user}
        end

        def update_email(user_id, email, repo \\ Repository) do
          case Repository.get(user_id, repo) do
            nil -> {:error, :not_found}
            user ->
              case Transformations.update_email(user, email) do
                {:ok, updated} ->
                  Repository.update(updated, repo)
                  {:ok, updated}
                error -> error
              end
          end
        end

        def promote_to_admin(user_id, repo \\ Repository) do
          case Repository.get(user_id, repo) do
            nil -> {:error, :not_found}
            user ->
              case Transformations.change_role(user, :admin) do
                {:ok, updated} ->
                  Repository.update(updated, repo)
                  {:ok, updated}
                error -> error
              end
          end
        end

        def deactivate_user(user_id, repo \\ Repository) do
          case Repository.get(user_id, repo) do
            nil -> {:error, :not_found}
            user ->
              updated = Transformations.deactivate(user)
              Repository.update(updated, repo)
              {:ok, updated}
          end
        end
      end
    end

    # 注文処理システム
    defmodule OrderProcessing do
      # 値オブジェクト
      defmodule Money do
        defstruct [:amount, :currency]

        def new(amount, currency \\ :jpy) do
          %__MODULE__{amount: amount, currency: currency}
        end

        def add(%__MODULE__{amount: a1, currency: c}, %__MODULE__{amount: a2, currency: c}) do
          {:ok, %__MODULE__{amount: a1 + a2, currency: c}}
        end
        def add(_, _), do: {:error, :currency_mismatch}

        def multiply(%__MODULE__{amount: a, currency: c}, factor) do
          %__MODULE__{amount: a * factor, currency: c}
        end

        def format(%__MODULE__{amount: a, currency: :jpy}), do: "¥#{a}"
        def format(%__MODULE__{amount: a, currency: :usd}), do: "$#{a / 100}"
      end

      # エンティティ
      defmodule Order do
        defstruct [:id, :customer_id, :items, :status, :total, created_at: nil]

        def new(customer_id) do
          %__MODULE__{
            id: :erlang.unique_integer([:positive]),
            customer_id: customer_id,
            items: [],
            status: :pending,
            total: Money.new(0),
            created_at: DateTime.utc_now()
          }
        end

        def add_item(order, item) do
          items = [item | order.items]
          total = calculate_total(items)
          %{order | items: items, total: total}
        end

        defp calculate_total(items) do
          Enum.reduce(items, Money.new(0), fn item, acc ->
            item_total = Money.multiply(item.price, item.quantity)
            case Money.add(acc, item_total) do
              {:ok, sum} -> sum
              _ -> acc
            end
          end)
        end
      end

      # 状態遷移
      defmodule OrderStateMachine do
        def confirm(%{status: :pending} = order) do
          {:ok, %{order | status: :confirmed}}
        end
        def confirm(_), do: {:error, :invalid_state}

        def ship(%{status: :confirmed} = order) do
          {:ok, %{order | status: :shipped}}
        end
        def ship(_), do: {:error, :invalid_state}

        def deliver(%{status: :shipped} = order) do
          {:ok, %{order | status: :delivered}}
        end
        def deliver(_), do: {:error, :invalid_state}

        def cancel(%{status: status} = order) when status in [:pending, :confirmed] do
          {:ok, %{order | status: :cancelled}}
        end
        def cancel(_), do: {:error, :invalid_state}
      end
    end
  end
end
