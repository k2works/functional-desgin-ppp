# Chapter 21: ベストプラクティス
#
# 関数型プログラミングのベストプラクティスと設計原則を示します。
# Elixir での実践的なコーディングパターンとアンチパターンを解説します。

defmodule Chapter21 do
  @moduledoc """
  関数型プログラミングのベストプラクティス

  このモジュールでは、以下のトピックを扱います：
  1. 不変性と純粋関数
  2. パイプラインと関数合成
  3. エラーハンドリング
  4. テスタビリティ
  5. パフォーマンス最適化
  6. コード構成
  """

  # ============================================================
  # 1. 不変性と純粋関数
  # ============================================================

  defmodule Immutability do
    @moduledoc """
    不変性のベストプラクティス
    """

    # ❌ 悪い例: 外部状態に依存
    defmodule BadExample do
      # これは純粋関数ではない（外部状態に依存）
      def get_current_time_greeting do
        hour = DateTime.utc_now().hour
        cond do
          hour < 12 -> "Good morning"
          hour < 18 -> "Good afternoon"
          true -> "Good evening"
        end
      end
    end

    # ✅ 良い例: 依存性を注入
    defmodule GoodExample do
      @doc "時刻を引数として受け取る純粋関数"
      def greeting_for_hour(hour) when hour >= 0 and hour < 24 do
        cond do
          hour < 12 -> "Good morning"
          hour < 18 -> "Good afternoon"
          true -> "Good evening"
        end
      end

      @doc "現在時刻を使用するラッパー（不純）"
      def current_greeting do
        greeting_for_hour(DateTime.utc_now().hour)
      end
    end

    # 不変データの操作
    defmodule DataOperations do
      @doc "マップの安全な更新"
      def update_user(user, updates) do
        Map.merge(user, updates)
      end

      @doc "ネストしたデータの更新"
      def update_nested(data, path, func) do
        update_in(data, path, func)
      end

      @doc "リストへの追加（先頭に追加が効率的）"
      def prepend(list, item), do: [item | list]

      @doc "リストへの追加（末尾に追加は非効率）"
      def append(list, item), do: list ++ [item]
    end
  end

  # ============================================================
  # 2. パイプラインと関数合成
  # ============================================================

  defmodule Pipelines do
    @moduledoc """
    パイプラインのベストプラクティス
    """

    # ❌ 悪い例: ネストした関数呼び出し
    defmodule NestedCalls do
      def process(data) do
        Enum.join(
          Enum.map(
            Enum.filter(
              String.split(data, ","),
              fn s -> String.length(String.trim(s)) > 0 end
            ),
            &String.upcase(String.trim(&1))
          ),
          " | "
        )
      end
    end

    # ✅ 良い例: パイプラインを使用
    defmodule PipelinedCalls do
      def process(data) do
        data
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&(String.length(&1) > 0))
        |> Enum.map(&String.upcase/1)
        |> Enum.join(" | ")
      end
    end

    # 関数合成のパターン
    defmodule Composition do
      @doc "関数を合成"
      def compose(f, g) do
        fn x -> f.(g.(x)) end
      end

      @doc "複数の関数を合成"
      def compose_all(functions) do
        Enum.reduce(functions, &(&1), fn f, acc ->
          fn x -> f.(acc.(x)) end
        end)
      end

      @doc "パイプライン順で合成"
      def pipe_compose(functions) do
        fn x ->
          Enum.reduce(functions, x, fn f, acc -> f.(acc) end)
        end
      end
    end

    # 変換パイプライン
    defmodule Transformations do
      @doc "データ変換パイプライン"
      def transform_users(users) do
        users
        |> filter_active()
        |> sort_by_name()
        |> format_for_display()
      end

      defp filter_active(users) do
        Enum.filter(users, & &1.active)
      end

      defp sort_by_name(users) do
        Enum.sort_by(users, & &1.name)
      end

      defp format_for_display(users) do
        Enum.map(users, fn user ->
          "#{user.name} <#{user.email}>"
        end)
      end
    end
  end

  # ============================================================
  # 3. エラーハンドリング
  # ============================================================

  defmodule ErrorHandling do
    @moduledoc """
    エラーハンドリングのベストプラクティス
    """

    # タグ付きタプルパターン
    defmodule TaggedTuples do
      @doc "成功/失敗を明示的に返す"
      def divide(a, b) when b != 0, do: {:ok, a / b}
      def divide(_a, 0), do: {:error, :division_by_zero}

      @doc "nilの代わりにタグ付きタプル"
      def find_user(users, id) do
        case Enum.find(users, &(&1.id == id)) do
          nil -> {:error, :not_found}
          user -> {:ok, user}
        end
      end

      @doc "with構文でのエラーチェーン"
      def process_order(order_id, user_id, users, orders) do
        with {:ok, user} <- find_user(users, user_id),
             {:ok, order} <- find_order(orders, order_id),
             :ok <- validate_owner(user, order) do
          {:ok, %{user: user, order: order}}
        end
      end

      defp find_order(orders, id) do
        case Enum.find(orders, &(&1.id == id)) do
          nil -> {:error, :order_not_found}
          order -> {:ok, order}
        end
      end

      defp validate_owner(user, order) do
        if order.user_id == user.id do
          :ok
        else
          {:error, :not_owner}
        end
      end
    end

    # Railway Oriented Programming
    defmodule Railway do
      @doc "成功の場合のみ関数を適用"
      def bind({:ok, value}, func), do: func.(value)
      def bind({:error, _} = error, _func), do: error

      @doc "値をOKトラックに乗せる"
      def succeed(value), do: {:ok, value}

      @doc "値をErrorトラックに乗せる"
      def fail(error), do: {:error, error}

      @doc "両方のトラックに関数を適用"
      def bimap({:ok, value}, ok_func, _err_func), do: {:ok, ok_func.(value)}
      def bimap({:error, error}, _ok_func, err_func), do: {:error, err_func.(error)}

      @doc "Railway パイプライン"
      def pipeline(value, functions) do
        Enum.reduce(functions, {:ok, value}, fn func, acc ->
          bind(acc, func)
        end)
      end
    end

    # 例外 vs 戻り値
    defmodule ExceptionsVsReturns do
      @doc "プログラミングエラーには例外を使用"
      def assert_positive!(n) when n > 0, do: n
      def assert_positive!(n), do: raise ArgumentError, "Expected positive, got #{n}"

      @doc "予想されるエラーには戻り値を使用"
      def parse_integer(string) do
        case Integer.parse(string) do
          {n, ""} -> {:ok, n}
          _ -> {:error, :invalid_format}
        end
      end
    end
  end

  # ============================================================
  # 4. テスタビリティ
  # ============================================================

  defmodule Testability do
    @moduledoc """
    テスタビリティのベストプラクティス
    """

    # 依存性注入
    defmodule DependencyInjection do
      @doc "HTTPクライアントを注入可能に"
      def fetch_user(user_id, http_client \\ &default_http_client/1) do
        url = "https://api.example.com/users/#{user_id}"
        case http_client.(url) do
          {:ok, body} -> {:ok, parse_json(body)}
          {:error, _} = error -> error
        end
      end

      defp default_http_client(_url) do
        # 実際のHTTPリクエスト（デフォルト実装）
        {:error, :not_implemented}
      end

      # シンプルなJSON風パーサー（デモ用）
      defp parse_json(~s({"name":"Alice"})), do: %{"name" => "Alice"}
      defp parse_json(body), do: %{"raw" => body}

      @doc "時計を注入可能に"
      def is_weekend?(clock \\ &DateTime.utc_now/0) do
        day = clock.() |> Date.day_of_week()
        day in [6, 7]
      end

      @doc "乱数生成を注入可能に"
      def roll_dice(random_fn \\ &:rand.uniform/1) do
        random_fn.(6)
      end
    end

    # プロパティベーステスト向けの設計
    defmodule PropertyBased do
      @doc "逆演算が存在する関数"
      def encode(string), do: Base.encode64(string)
      def decode(encoded), do: Base.decode64!(encoded)

      @doc "冪等な関数"
      def normalize_email(email) do
        email
        |> String.downcase()
        |> String.trim()
      end

      @doc "結合法則を満たす関数"
      def concat_strings(a, b), do: a <> b
    end

    # モック不要の設計
    defmodule NoMockNeeded do
      @doc "外部依存を境界に押し出す"
      def process_data(raw_data) do
        # 純粋な変換ロジック
        raw_data
        |> parse()
        |> validate()
        |> transform()
      end

      defp parse(data), do: String.split(data, "\n")
      defp validate(lines), do: Enum.filter(lines, &valid_line?/1)
      defp transform(lines), do: Enum.map(lines, &String.upcase/1)
      defp valid_line?(line), do: String.length(line) > 0
    end
  end

  # ============================================================
  # 5. パフォーマンス最適化
  # ============================================================

  defmodule Performance do
    @moduledoc """
    パフォーマンス最適化のベストプラクティス
    """

    # 遅延評価
    defmodule LazyEvaluation do
      @doc "大きなデータセットにはStreamを使用"
      def process_large_file(path) do
        File.stream!(path)
        |> Stream.map(&String.trim/1)
        |> Stream.filter(&(String.length(&1) > 0))
        |> Stream.map(&String.upcase/1)
        |> Enum.take(100)
      end

      @doc "無限ストリーム"
      def fibonacci_stream do
        Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
      end

      @doc "遅延評価で中間リストを避ける"
      def lazy_transform(data) do
        data
        |> Stream.map(&expensive_operation/1)
        |> Stream.filter(&relevant?/1)
        |> Enum.take(10)
      end

      defp expensive_operation(x), do: x * x
      defp relevant?(x), do: rem(x, 2) == 0
    end

    # 末尾再帰
    defmodule TailRecursion do
      @doc "❌ 末尾再帰でない（スタックを消費）"
      def sum_bad([]), do: 0
      def sum_bad([h | t]), do: h + sum_bad(t)

      @doc "✅ 末尾再帰（アキュムレータを使用）"
      def sum_good(list), do: do_sum(list, 0)

      defp do_sum([], acc), do: acc
      defp do_sum([h | t], acc), do: do_sum(t, acc + h)

      @doc "リストの反転（末尾再帰）"
      def reverse(list), do: do_reverse(list, [])

      defp do_reverse([], acc), do: acc
      defp do_reverse([h | t], acc), do: do_reverse(t, [h | acc])
    end

    # データ構造の選択
    defmodule DataStructures do
      @doc "O(1)のメンバーシップ検査にはMapSetを使用"
      def member_check_efficient(items, item) do
        set = MapSet.new(items)
        MapSet.member?(set, item)
      end

      @doc "O(n)のリストでの検索"
      def member_check_inefficient(items, item) do
        Enum.member?(items, item)
      end

      @doc "キーによる高速ルックアップにはMapを使用"
      def build_index(items, key_fn) do
        Map.new(items, fn item -> {key_fn.(item), item} end)
      end
    end
  end

  # ============================================================
  # 6. コード構成
  # ============================================================

  defmodule CodeOrganization do
    @moduledoc """
    コード構成のベストプラクティス
    """

    # 小さな関数
    defmodule SmallFunctions do
      @doc "一つのことだけを行う関数"
      def validate_email(email) do
        email
        |> check_format()
        |> check_domain()
        |> check_length()
      end

      defp check_format({:error, _} = error), do: error
      defp check_format(email) do
        if String.match?(email, ~r/^[\w.+-]+@[\w.-]+\.\w+$/) do
          email
        else
          {:error, :invalid_format}
        end
      end

      defp check_domain({:error, _} = error), do: error
      defp check_domain(email) do
        blocked = ["spam.com", "fake.com"]
        domain = email |> String.split("@") |> List.last()
        if domain in blocked do
          {:error, :blocked_domain}
        else
          email
        end
      end

      defp check_length({:error, _} = error), do: error
      defp check_length(email) do
        if String.length(email) > 254 do
          {:error, :too_long}
        else
          {:ok, email}
        end
      end
    end

    # モジュールの責務分離
    defmodule SeparationOfConcerns do
      # データ定義
      defmodule User do
        defstruct [:id, :name, :email, :role]

        def new(attrs), do: struct(__MODULE__, attrs)
      end

      # ビジネスロジック
      defmodule UserService do
        alias Chapter21.CodeOrganization.SeparationOfConcerns.User

        def can_access?(user, resource) do
          user.role in allowed_roles(resource)
        end

        defp allowed_roles(:admin_panel), do: [:admin]
        defp allowed_roles(:dashboard), do: [:admin, :user]
        defp allowed_roles(_), do: [:admin, :user, :guest]
      end

      # フォーマット
      defmodule UserFormatter do
        alias Chapter21.CodeOrganization.SeparationOfConcerns.User

        def to_display_name(%User{name: name}), do: name
        def to_email_format(%User{name: name, email: email}), do: "#{name} <#{email}>"
      end
    end

    # ドキュメントと型
    defmodule Documentation do
      @moduledoc """
      ドキュメントのベストプラクティス
      """

      @typedoc "ユーザーID"
      @type user_id :: pos_integer()

      @typedoc "ユーザーの役割"
      @type role :: :admin | :user | :guest

      @typedoc "ユーザー構造体"
      @type user :: %{id: user_id(), name: String.t(), role: role()}

      @doc """
      ユーザーを検索します。

      ## パラメータ
        - `users`: ユーザーのリスト
        - `id`: 検索するユーザーID

      ## 戻り値
        - `{:ok, user}`: ユーザーが見つかった場合
        - `{:error, :not_found}`: ユーザーが見つからない場合

      ## 例

          iex> users = [%{id: 1, name: "Alice", role: :admin}]
          iex> Documentation.find_user(users, 1)
          {:ok, %{id: 1, name: "Alice", role: :admin}}

      """
      @spec find_user([user()], user_id()) :: {:ok, user()} | {:error, :not_found}
      def find_user(users, id) do
        case Enum.find(users, &(&1.id == id)) do
          nil -> {:error, :not_found}
          user -> {:ok, user}
        end
      end
    end
  end

  # ============================================================
  # 7. 実践的なパターン集
  # ============================================================

  defmodule PracticalPatterns do
    @moduledoc """
    実践的なパターン集
    """

    # オプションパターン
    defmodule Options do
      @default_options [
        timeout: 5000,
        retries: 3,
        format: :json
      ]

      @doc "デフォルトオプションとマージ"
      def with_defaults(opts) do
        Keyword.merge(@default_options, opts)
      end

      @doc "オプションを使用した関数"
      def fetch_data(url, opts \\ []) do
        opts = with_defaults(opts)
        timeout = Keyword.get(opts, :timeout)
        retries = Keyword.get(opts, :retries)

        do_fetch(url, timeout, retries)
      end

      defp do_fetch(url, _timeout, _retries) do
        # 実際のフェッチロジック
        {:ok, "data from #{url}"}
      end
    end

    # ビルダーパターン
    defmodule Builder do
      defstruct fields: %{}, validations: []

      def new, do: %__MODULE__{}

      def set(builder, key, value) do
        %{builder | fields: Map.put(builder.fields, key, value)}
      end

      def add_validation(builder, validation) do
        %{builder | validations: [validation | builder.validations]}
      end

      def build(builder) do
        errors = builder.validations
        |> Enum.map(fn v -> v.(builder.fields) end)
        |> Enum.filter(&(&1 != :ok))

        case errors do
          [] -> {:ok, builder.fields}
          _ -> {:error, errors}
        end
      end
    end

    # 状態モナド的パターン
    defmodule StatePattern do
      @doc "状態を通してスレッドする"
      def run_with_state(initial_state, operations) do
        Enum.reduce(operations, {:ok, initial_state}, fn
          _op, {:error, _} = error -> error
          op, {:ok, state} -> op.(state)
        end)
      end

      @doc "例: カウンターの操作"
      def counter_example do
        operations = [
          fn state -> {:ok, Map.update(state, :count, 1, &(&1 + 1))} end,
          fn state -> {:ok, Map.update(state, :count, 1, &(&1 + 1))} end,
          fn state -> {:ok, Map.update(state, :count, 1, &(&1 * 2))} end
        ]

        run_with_state(%{count: 0}, operations)
      end
    end

    # メモ化パターン
    defmodule Memoization do
      use Agent

      def start_link do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
      end

      def memoize(key, func) do
        case Agent.get(__MODULE__, &Map.get(&1, key)) do
          nil ->
            result = func.()
            Agent.update(__MODULE__, &Map.put(&1, key, result))
            result
          cached ->
            cached
        end
      end

      def clear do
        Agent.update(__MODULE__, fn _ -> %{} end)
      end

      def stop do
        pid = Process.whereis(__MODULE__)
        if pid && Process.alive?(pid), do: Agent.stop(__MODULE__)
      end
    end
  end
end
