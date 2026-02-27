defmodule Chapter07 do
  @moduledoc """
  # Chapter 07: Effects and Pure Functions

  このモジュールでは、副作用（Effects）と純粋関数の分離について学びます。
  Elixir では、副作用を境界に追いやり、コアロジックを純粋に保つことが重要です。

  ## 主なトピック

  1. 純粋関数と副作用の分離
  2. 副作用の種類（I/O、状態、時間、乱数）
  3. 副作用の遅延実行
  4. Reader パターン
  5. 依存性注入による副作用の分離
  """

  # ============================================================
  # 1. 純粋関数と副作用
  # ============================================================

  defmodule PureVsImpure do
    @moduledoc """
    純粋関数と副作用を持つ関数の違いを示す。
    """

    @doc """
    純粋関数：同じ入力に対して常に同じ出力を返す。

    ## Examples

        iex> Chapter07.PureVsImpure.add(2, 3)
        5
        iex> Chapter07.PureVsImpure.add(2, 3)
        5
    """
    @spec add(number(), number()) :: number()
    def add(a, b), do: a + b

    @doc """
    純粋関数：リストの合計を計算する。

    ## Examples

        iex> Chapter07.PureVsImpure.sum([1, 2, 3, 4, 5])
        15
    """
    @spec sum([number()]) :: number()
    def sum(list), do: Enum.sum(list)

    @doc """
    純粋関数：文字列を大文字に変換する。

    ## Examples

        iex> Chapter07.PureVsImpure.upcase("hello")
        "HELLO"
    """
    @spec upcase(String.t()) :: String.t()
    def upcase(s), do: String.upcase(s)

    @doc """
    副作用を持つ関数：現在時刻を取得する（非決定的）。
    """
    @spec current_time() :: DateTime.t()
    def current_time, do: DateTime.utc_now()

    @doc """
    副作用を持つ関数：乱数を生成する（非決定的）。
    """
    @spec random_number() :: float()
    def random_number, do: :rand.uniform()

    @doc """
    副作用を持つ関数：コンソールに出力する（I/O）。
    """
    @spec print_message(String.t()) :: :ok
    def print_message(msg) do
      IO.puts(msg)
      :ok
    end
  end

  # ============================================================
  # 2. 副作用の分離：Functional Core, Imperative Shell
  # ============================================================

  defmodule PricingCore do
    @moduledoc """
    純粋な価格計算ロジック（Functional Core）。
    副作用なし、テストが容易。
    """

    @type discount :: %{type: :percentage | :fixed, value: number()}
    @type product :: %{name: String.t(), price: number()}

    @doc """
    割引を適用する（純粋関数）。

    ## Examples

        iex> Chapter07.PricingCore.apply_discount(100, %{type: :percentage, value: 10})
        90.0
        iex> Chapter07.PricingCore.apply_discount(100, %{type: :fixed, value: 15})
        85
    """
    @spec apply_discount(number(), discount()) :: number()
    def apply_discount(price, %{type: :percentage, value: pct}) do
      price * (1 - pct / 100)
    end
    def apply_discount(price, %{type: :fixed, value: amount}) do
      max(0, price - amount)
    end

    @doc """
    複数の商品の合計価格を計算する（純粋関数）。

    ## Examples

        iex> products = [
        ...>   %{name: "A", price: 100},
        ...>   %{name: "B", price: 200}
        ...> ]
        iex> Chapter07.PricingCore.calculate_total(products)
        300
    """
    @spec calculate_total([product()]) :: number()
    def calculate_total(products) do
      products
      |> Enum.map(& &1.price)
      |> Enum.sum()
    end

    @doc """
    税金を計算する（純粋関数）。

    ## Examples

        iex> Chapter07.PricingCore.calculate_tax(1000, 0.1)
        100.0
    """
    @spec calculate_tax(number(), number()) :: number()
    def calculate_tax(amount, tax_rate), do: amount * tax_rate

    @doc """
    注文の最終価格を計算する（純粋関数）。

    ## Examples

        iex> products = [%{name: "A", price: 1000}]
        iex> discount = %{type: :percentage, value: 10}
        iex> Chapter07.PricingCore.calculate_final_price(products, discount, 0.08)
        %{subtotal: 1000, discount: 100.0, tax: 72.0, total: 972.0}
    """
    @spec calculate_final_price([product()], discount(), number()) :: map()
    def calculate_final_price(products, discount, tax_rate) do
      subtotal = calculate_total(products)
      discount_amount = subtotal - apply_discount(subtotal, discount)
      after_discount = subtotal - discount_amount
      tax = calculate_tax(after_discount, tax_rate)
      total = after_discount + tax

      %{
        subtotal: subtotal,
        discount: discount_amount,
        tax: tax,
        total: total
      }
    end
  end

  defmodule PricingShell do
    @moduledoc """
    副作用を扱うシェル層（Imperative Shell）。
    外部サービスとの通信、I/O などをここで処理。
    """

    alias Chapter07.PricingCore

    @doc """
    外部から割引情報を取得して価格を計算する。
    discount_fetcher は副作用を持つ関数として注入される。
    """
    @spec calculate_order_price(
      [PricingCore.product()],
      (String.t() -> PricingCore.discount()),
      String.t(),
      number()
    ) :: map()
    def calculate_order_price(products, discount_fetcher, discount_code, tax_rate) do
      discount = discount_fetcher.(discount_code)
      PricingCore.calculate_final_price(products, discount, tax_rate)
    end
  end

  # ============================================================
  # 3. 副作用の遅延実行（Effect as Data）
  # ============================================================

  defmodule Effect do
    @moduledoc """
    副作用をデータとして表現し、実行を遅延させる。
    これにより、副作用を持つコードもテスト可能になる。
    """

    @type effect(a) :: {:effect, atom(), any(), (any() -> a)}

    @doc """
    コンソール出力のエフェクトを作成する。

    ## Examples

        iex> effect = Chapter07.Effect.console_log("Hello")
        iex> match?({:effect, :console_log, "Hello", _}, effect)
        true
    """
    @spec console_log(String.t()) :: effect(:ok)
    def console_log(message) do
      {:effect, :console_log, message, fn _ -> :ok end}
    end

    @doc """
    現在時刻取得のエフェクトを作成する。

    ## Examples

        iex> effect = Chapter07.Effect.get_current_time()
        iex> match?({:effect, :get_time, nil, _}, effect)
        true
    """
    @spec get_current_time() :: effect(DateTime.t())
    def get_current_time do
      {:effect, :get_time, nil, fn time -> time end}
    end

    @doc """
    乱数生成のエフェクトを作成する。

    ## Examples

        iex> effect = Chapter07.Effect.get_random()
        iex> match?({:effect, :random, nil, _}, effect)
        true
    """
    @spec get_random() :: effect(float())
    def get_random do
      {:effect, :random, nil, fn n -> n end}
    end

    @doc """
    HTTP GET リクエストのエフェクトを作成する。

    ## Examples

        iex> effect = Chapter07.Effect.http_get("https://api.example.com")
        iex> match?({:effect, :http_get, "https://api.example.com", _}, effect)
        true
    """
    @spec http_get(String.t()) :: effect({:ok, String.t()} | {:error, String.t()})
    def http_get(url) do
      {:effect, :http_get, url, fn response -> response end}
    end

    @doc """
    エフェクトを実際に実行する（本番用インタープリター）。

    ## Examples

        iex> Chapter07.Effect.run({:effect, :console_log, "test", fn _ -> :ok end})
        :ok
    """
    @spec run(effect(a)) :: a when a: any()
    def run({:effect, :console_log, message, cont}) do
      IO.puts(message)
      cont.(:ok)
    end
    def run({:effect, :get_time, _, cont}) do
      cont.(DateTime.utc_now())
    end
    def run({:effect, :random, _, cont}) do
      cont.(:rand.uniform())
    end
    def run({:effect, :http_get, _url, cont}) do
      # 実際にはHTTPクライアントを使用
      cont.({:ok, "response body"})
    end

    @doc """
    テスト用のインタープリター。モック値を返す。

    ## Examples

        iex> mock_values = %{get_time: ~U[2024-01-01 00:00:00Z]}
        iex> Chapter07.Effect.run_test({:effect, :get_time, nil, fn t -> t end}, mock_values)
        ~U[2024-01-01 00:00:00Z]
    """
    @spec run_test(effect(a), map()) :: a when a: any()
    def run_test({:effect, effect_type, _, cont}, mock_values) do
      mock_value = Map.get(mock_values, effect_type)
      cont.(mock_value)
    end
  end

  # ============================================================
  # 4. Reader パターン（依存性注入）
  # ============================================================

  defmodule Reader do
    @moduledoc """
    Reader モナドパターン。
    環境（依存性）を引数として受け取る関数をラップする。
    """

    @type t(env, a) :: (env -> a)

    @doc """
    値を Reader でラップする（pure/return）。

    ## Examples

        iex> reader = Chapter07.Reader.pure(42)
        iex> reader.(:any_env)
        42
    """
    @spec pure(a) :: t(any(), a) when a: any()
    def pure(value), do: fn _env -> value end

    @doc """
    環境を取得する Reader を作成する。

    ## Examples

        iex> reader = Chapter07.Reader.ask()
        iex> reader.(%{db: "connection"})
        %{db: "connection"}
    """
    @spec ask() :: t(env, env) when env: any()
    def ask, do: fn env -> env end

    @doc """
    環境の一部を取得する Reader を作成する。

    ## Examples

        iex> reader = Chapter07.Reader.asks(fn env -> env.db end)
        iex> reader.(%{db: "connection", cache: "redis"})
        "connection"
    """
    @spec asks((env -> a)) :: t(env, a) when env: any(), a: any()
    def asks(selector), do: fn env -> selector.(env) end

    @doc """
    Reader に関数を適用する（map/fmap）。

    ## Examples

        iex> reader = Chapter07.Reader.pure(10)
        iex> mapped = Chapter07.Reader.map(reader, &(&1 * 2))
        iex> mapped.(:any_env)
        20
    """
    @spec map(t(env, a), (a -> b)) :: t(env, b) when env: any(), a: any(), b: any()
    def map(reader, f), do: fn env -> f.(reader.(env)) end

    @doc """
    Reader をフラットマップする（bind/flatMap）。

    ## Examples

        iex> reader1 = Chapter07.Reader.pure(10)
        iex> reader2 = Chapter07.Reader.flat_map(reader1, fn x ->
        ...>   Chapter07.Reader.asks(fn env -> x + env.multiplier end)
        ...> end)
        iex> reader2.(%{multiplier: 5})
        15
    """
    @spec flat_map(t(env, a), (a -> t(env, b))) :: t(env, b) when env: any(), a: any(), b: any()
    def flat_map(reader, f), do: fn env -> f.(reader.(env)).(env) end

    @doc """
    Reader を実行する。

    ## Examples

        iex> reader = Chapter07.Reader.pure(42)
        iex> Chapter07.Reader.run(reader, :any_env)
        42
    """
    @spec run(t(env, a), env) :: a when env: any(), a: any()
    def run(reader, env), do: reader.(env)
  end

  defmodule ReaderExample do
    @moduledoc """
    Reader パターンの実践例：設定を使用するサービス。
    """

    alias Chapter07.Reader

    @type config :: %{
      db_url: String.t(),
      api_key: String.t(),
      timeout: pos_integer()
    }

    @doc """
    データベースURLを取得する Reader。

    ## Examples

        iex> reader = Chapter07.ReaderExample.get_db_url()
        iex> config = %{db_url: "postgres://localhost", api_key: "key", timeout: 5000}
        iex> Chapter07.Reader.run(reader, config)
        "postgres://localhost"
    """
    @spec get_db_url() :: Reader.t(config(), String.t())
    def get_db_url do
      Reader.asks(fn config -> config.db_url end)
    end

    @doc """
    API キーを取得する Reader。

    ## Examples

        iex> reader = Chapter07.ReaderExample.get_api_key()
        iex> config = %{db_url: "postgres://localhost", api_key: "secret", timeout: 5000}
        iex> Chapter07.Reader.run(reader, config)
        "secret"
    """
    @spec get_api_key() :: Reader.t(config(), String.t())
    def get_api_key do
      Reader.asks(fn config -> config.api_key end)
    end

    @doc """
    設定を使用してサービスを構築する Reader。

    ## Examples

        iex> reader = Chapter07.ReaderExample.build_service()
        iex> config = %{db_url: "postgres://localhost", api_key: "key", timeout: 5000}
        iex> Chapter07.Reader.run(reader, config)
        %{db: "postgres://localhost", key: "key", ready: true}
    """
    @spec build_service() :: Reader.t(config(), map())
    def build_service do
      Reader.flat_map(get_db_url(), fn db_url ->
        Reader.flat_map(get_api_key(), fn api_key ->
          Reader.pure(%{db: db_url, key: api_key, ready: true})
        end)
      end)
    end
  end

  # ============================================================
  # 5. 時間の抽象化
  # ============================================================

  defmodule TimeService do
    @moduledoc """
    時間を抽象化し、テスト可能にする。
    """

    @type time_provider :: (() -> DateTime.t())

    @doc """
    現在時刻を取得する（デフォルトプロバイダー）。

    ## Examples

        iex> time = Chapter07.TimeService.now()
        iex> is_struct(time, DateTime)
        true
    """
    @spec now() :: DateTime.t()
    def now, do: DateTime.utc_now()

    @doc """
    指定したプロバイダーから時刻を取得する。

    ## Examples

        iex> fixed_time = ~U[2024-01-01 12:00:00Z]
        iex> provider = fn -> fixed_time end
        iex> Chapter07.TimeService.now_with_provider(provider)
        ~U[2024-01-01 12:00:00Z]
    """
    @spec now_with_provider(time_provider()) :: DateTime.t()
    def now_with_provider(provider), do: provider.()

    @doc """
    タイムスタンプを追加する（注入可能な時間依存）。

    ## Examples

        iex> fixed_time = ~U[2024-01-01 12:00:00Z]
        iex> provider = fn -> fixed_time end
        iex> data = %{name: "event"}
        iex> Chapter07.TimeService.add_timestamp(data, provider)
        %{name: "event", timestamp: ~U[2024-01-01 12:00:00Z]}
    """
    @spec add_timestamp(map(), time_provider()) :: map()
    def add_timestamp(data, time_provider) do
      Map.put(data, :timestamp, time_provider.())
    end

    @doc """
    期限切れかどうかを判定する。

    ## Examples

        iex> now = ~U[2024-01-15 12:00:00Z]
        iex> expiry = ~U[2024-01-10 12:00:00Z]
        iex> Chapter07.TimeService.is_expired?(expiry, fn -> now end)
        true
        iex> Chapter07.TimeService.is_expired?(~U[2024-01-20 12:00:00Z], fn -> now end)
        false
    """
    @spec is_expired?(DateTime.t(), time_provider()) :: boolean()
    def is_expired?(expiry_date, time_provider) do
      DateTime.compare(time_provider.(), expiry_date) == :gt
    end
  end

  # ============================================================
  # 6. 乱数の抽象化
  # ============================================================

  defmodule RandomService do
    @moduledoc """
    乱数生成を抽象化し、テスト可能にする。
    """

    @type random_provider :: (() -> float())
    @type int_provider :: (Range.t() -> integer())

    @doc """
    0.0 から 1.0 の乱数を生成する。

    ## Examples

        iex> n = Chapter07.RandomService.random()
        iex> n >= 0.0 and n < 1.0
        true
    """
    @spec random() :: float()
    def random, do: :rand.uniform()

    @doc """
    指定したプロバイダーから乱数を取得する。

    ## Examples

        iex> provider = fn -> 0.5 end
        iex> Chapter07.RandomService.random_with_provider(provider)
        0.5
    """
    @spec random_with_provider(random_provider()) :: float()
    def random_with_provider(provider), do: provider.()

    @doc """
    範囲内の整数を生成する。

    ## Examples

        iex> provider = fn _range -> 5 end
        iex> Chapter07.RandomService.random_int(1..10, provider)
        5
    """
    @spec random_int(Range.t(), int_provider()) :: integer()
    def random_int(range, provider), do: provider.(range)

    @doc """
    リストからランダムに要素を選択する。

    ## Examples

        iex> list = ["a", "b", "c"]
        iex> # インデックス1を返すプロバイダー
        iex> provider = fn _range -> 1 end
        iex> Chapter07.RandomService.random_element(list, provider)
        "b"
    """
    @spec random_element(list(), int_provider()) :: any()
    def random_element(list, provider) do
      index = provider.(0..(length(list) - 1))
      Enum.at(list, index)
    end

    @doc """
    確率に基づいて真偽を返す。

    ## Examples

        iex> # 0.3 を返すプロバイダー（30%）
        iex> provider = fn -> 0.3 end
        iex> Chapter07.RandomService.with_probability(0.5, provider)
        true
        iex> Chapter07.RandomService.with_probability(0.2, provider)
        false
    """
    @spec with_probability(float(), random_provider()) :: boolean()
    def with_probability(probability, provider) do
      provider.() < probability
    end
  end

  # ============================================================
  # 7. ログの抽象化
  # ============================================================

  defmodule Logger do
    @moduledoc """
    ログ出力を抽象化し、テスト可能にする。
    """

    @type log_level :: :debug | :info | :warn | :error
    @type log_entry :: {log_level(), String.t(), DateTime.t()}
    @type logger :: (log_level(), String.t() -> :ok)

    @doc """
    標準のログ出力関数。
    """
    @spec default_logger() :: logger()
    def default_logger do
      fn level, message ->
        IO.puts("[#{level}] #{message}")
        :ok
      end
    end

    @doc """
    何もしないログ出力関数（テスト用）。

    ## Examples

        iex> logger = Chapter07.Logger.noop_logger()
        iex> logger.(:info, "test")
        :ok
    """
    @spec noop_logger() :: logger()
    def noop_logger, do: fn _level, _message -> :ok end

    @doc """
    ログを蓄積するログ出力関数（テスト用）。
    Agent を使用して状態を管理。
    """
    @spec collecting_logger() :: {logger(), (() -> [log_entry()])}
    def collecting_logger do
      {:ok, agent} = Agent.start_link(fn -> [] end)

      logger = fn level, message ->
        entry = {level, message, DateTime.utc_now()}
        Agent.update(agent, fn logs -> [entry | logs] end)
        :ok
      end

      get_logs = fn ->
        Agent.get(agent, fn logs -> Enum.reverse(logs) end)
      end

      {logger, get_logs}
    end

    @doc """
    ログレベルでフィルタリングするロガーを作成する。

    ## Examples

        iex> base_logger = Chapter07.Logger.noop_logger()
        iex> filtered = Chapter07.Logger.with_min_level(base_logger, :warn)
        iex> filtered.(:debug, "debug message")
        :ok
    """
    @spec with_min_level(logger(), log_level()) :: logger()
    def with_min_level(base_logger, min_level) do
      level_order = %{debug: 0, info: 1, warn: 2, error: 3}

      fn level, message ->
        if level_order[level] >= level_order[min_level] do
          base_logger.(level, message)
        else
          :ok
        end
      end
    end
  end

  # ============================================================
  # 8. 純粋関数によるビジネスロジック例
  # ============================================================

  defmodule ShoppingCart do
    @moduledoc """
    ショッピングカートのビジネスロジック（純粋関数）。
    """

    @type item :: %{id: String.t(), name: String.t(), price: number(), quantity: pos_integer()}
    @type cart :: %{items: [item()], coupon: String.t() | nil}

    @doc """
    空のカートを作成する。

    ## Examples

        iex> Chapter07.ShoppingCart.empty()
        %{items: [], coupon: nil}
    """
    @spec empty() :: cart()
    def empty, do: %{items: [], coupon: nil}

    @doc """
    カートに商品を追加する。

    ## Examples

        iex> cart = Chapter07.ShoppingCart.empty()
        iex> item = %{id: "1", name: "Book", price: 1000, quantity: 2}
        iex> cart = Chapter07.ShoppingCart.add_item(cart, item)
        iex> length(cart.items)
        1
    """
    @spec add_item(cart(), item()) :: cart()
    def add_item(%{items: items} = cart, item) do
      case Enum.find_index(items, &(&1.id == item.id)) do
        nil ->
          %{cart | items: [item | items]}
        index ->
          updated = Enum.at(items, index)
          updated = %{updated | quantity: updated.quantity + item.quantity}
          %{cart | items: List.replace_at(items, index, updated)}
      end
    end

    @doc """
    カートから商品を削除する。

    ## Examples

        iex> item = %{id: "1", name: "Book", price: 1000, quantity: 1}
        iex> cart = Chapter07.ShoppingCart.add_item(Chapter07.ShoppingCart.empty(), item)
        iex> cart = Chapter07.ShoppingCart.remove_item(cart, "1")
        iex> cart.items
        []
    """
    @spec remove_item(cart(), String.t()) :: cart()
    def remove_item(%{items: items} = cart, item_id) do
      %{cart | items: Enum.reject(items, &(&1.id == item_id))}
    end

    @doc """
    クーポンを適用する。

    ## Examples

        iex> cart = Chapter07.ShoppingCart.empty()
        iex> cart = Chapter07.ShoppingCart.apply_coupon(cart, "SAVE10")
        iex> cart.coupon
        "SAVE10"
    """
    @spec apply_coupon(cart(), String.t()) :: cart()
    def apply_coupon(cart, coupon_code) do
      %{cart | coupon: coupon_code}
    end

    @doc """
    カートの小計を計算する。

    ## Examples

        iex> cart = Chapter07.ShoppingCart.empty()
        iex> cart = Chapter07.ShoppingCart.add_item(cart, %{id: "1", name: "A", price: 100, quantity: 2})
        iex> cart = Chapter07.ShoppingCart.add_item(cart, %{id: "2", name: "B", price: 50, quantity: 3})
        iex> Chapter07.ShoppingCart.subtotal(cart)
        350
    """
    @spec subtotal(cart()) :: number()
    def subtotal(%{items: items}) do
      items
      |> Enum.map(fn item -> item.price * item.quantity end)
      |> Enum.sum()
    end

    @doc """
    カートの合計を計算する（割引適用後）。
    discount_resolver は副作用を持つ可能性があるため、注入する。

    ## Examples

        iex> cart = Chapter07.ShoppingCart.empty()
        iex> cart = Chapter07.ShoppingCart.add_item(cart, %{id: "1", name: "A", price: 1000, quantity: 1})
        iex> cart = Chapter07.ShoppingCart.apply_coupon(cart, "SAVE10")
        iex> # 10%割引を返すリゾルバ
        iex> resolver = fn "SAVE10" -> 0.10; _ -> 0.0 end
        iex> Chapter07.ShoppingCart.total(cart, resolver)
        900.0
    """
    @spec total(cart(), (String.t() | nil -> float())) :: float()
    def total(%{coupon: nil} = cart, _resolver), do: subtotal(cart) * 1.0
    def total(%{coupon: coupon} = cart, resolver) do
      discount_rate = resolver.(coupon)
      subtotal(cart) * (1 - discount_rate)
    end
  end
end
