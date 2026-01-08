# Chapter 20: パターン間の相互作用
#
# 関数型設計パターンの組み合わせ方と相互作用を示します。
# 複数のパターンを組み合わせて、より強力で柔軟な設計を実現します。

defmodule Chapter20 do
  @moduledoc """
  パターン間の相互作用

  このモジュールでは、以下のパターン組み合わせを扱います：
  1. Visitor + Iterator: データ構造の走査と処理
  2. Strategy + Factory: 動的な戦略生成
  3. Observer + State: 状態変化の通知
  4. Decorator + Pipeline: 処理の拡張
  5. Composite + Visitor: 木構造の処理
  """

  # ============================================================
  # 1. Visitor + Iterator パターン
  # ============================================================

  defmodule VisitorIterator do
    @moduledoc """
    Visitor と Iterator の組み合わせ

    データ構造を走査しながら、各要素に操作を適用する
    """

    # 木構造のノード
    defmodule TreeNode do
      defstruct [:value, :left, :right]

      def leaf(value), do: %__MODULE__{value: value, left: nil, right: nil}

      def node(value, left, right) do
        %__MODULE__{value: value, left: left, right: right}
      end
    end

    # イテレータ: 走査戦略
    defmodule Iterator do
      @doc "前順走査（Pre-order）"
      def preorder(nil), do: []
      def preorder(%TreeNode{value: v, left: l, right: r}) do
        [v | preorder(l) ++ preorder(r)]
      end

      @doc "中順走査（In-order）"
      def inorder(nil), do: []
      def inorder(%TreeNode{value: v, left: l, right: r}) do
        inorder(l) ++ [v] ++ inorder(r)
      end

      @doc "後順走査（Post-order）"
      def postorder(nil), do: []
      def postorder(%TreeNode{value: v, left: l, right: r}) do
        postorder(l) ++ postorder(r) ++ [v]
      end

      @doc "レベル順走査（Level-order / BFS）"
      def levelorder(nil), do: []
      def levelorder(root), do: do_levelorder([root])

      defp do_levelorder([]), do: []
      defp do_levelorder(queue) do
        values = Enum.map(queue, fn
          nil -> nil
          %TreeNode{value: v} -> v
        end) |> Enum.reject(&is_nil/1)

        children = queue
        |> Enum.flat_map(fn
          nil -> []
          %TreeNode{left: l, right: r} ->
            [l, r] |> Enum.reject(&is_nil/1)
        end)

        values ++ do_levelorder(children)
      end
    end

    # ビジター: 要素への操作
    defmodule Visitor do
      @doc "合計を計算"
      def sum(values), do: Enum.sum(values)

      @doc "最大値を取得"
      def max(values), do: Enum.max(values, fn -> nil end)

      @doc "最小値を取得"
      def min(values), do: Enum.min(values, fn -> nil end)

      @doc "変換を適用"
      def map(values, func), do: Enum.map(values, func)

      @doc "フィルタを適用"
      def filter(values, pred), do: Enum.filter(values, pred)

      @doc "畳み込み"
      def reduce(values, acc, func), do: Enum.reduce(values, acc, func)
    end

    @doc "走査戦略とビジター操作を組み合わせる"
    def traverse_and_visit(tree, iterator_fn, visitor_fn) do
      tree
      |> iterator_fn.()
      |> visitor_fn.()
    end
  end

  # ============================================================
  # 2. Strategy + Factory パターン
  # ============================================================

  defmodule StrategyFactory do
    @moduledoc """
    Strategy と Factory の組み合わせ

    実行時に適切な戦略を動的に生成する
    """

    # 割引戦略のファクトリ
    defmodule DiscountFactory do
      @doc "顧客タイプに基づいて割引戦略を生成"
      def create(:regular), do: &regular_discount/1
      def create(:premium), do: &premium_discount/1
      def create(:vip), do: &vip_discount/1
      def create({:seasonal, rate}), do: seasonal_discount(rate)
      def create({:combined, strategies}), do: combined_discount(strategies)

      defp regular_discount(price), do: price
      defp premium_discount(price), do: price * 0.9
      defp vip_discount(price), do: price * 0.8

      defp seasonal_discount(rate) do
        fn price -> price * (1 - rate) end
      end

      defp combined_discount(strategies) do
        fn price ->
          Enum.reduce(strategies, price, fn strategy, acc ->
            create(strategy).(acc)
          end)
        end
      end
    end

    # 価格計算機
    defmodule PriceCalculator do
      @doc "戦略を使用して価格を計算"
      def calculate(price, customer_type) do
        strategy = DiscountFactory.create(customer_type)
        strategy.(price)
      end

      @doc "複数アイテムの合計を計算"
      def calculate_total(items, customer_type) do
        strategy = DiscountFactory.create(customer_type)
        items
        |> Enum.map(fn {_name, price} -> strategy.(price) end)
        |> Enum.sum()
      end
    end

    # 検証戦略のファクトリ
    defmodule ValidatorFactory do
      @doc "フィールドタイプに基づいてバリデータを生成"
      def create(:email), do: &valid_email?/1
      def create(:phone), do: &valid_phone?/1
      def create(:age), do: &valid_age?/1
      def create({:range, min, max}), do: range_validator(min, max)
      def create({:pattern, regex}), do: pattern_validator(regex)
      def create({:all, validators}), do: all_validator(validators)

      defp valid_email?(value) do
        String.match?(value, ~r/^[\w.+-]+@[\w.-]+\.\w+$/)
      end

      defp valid_phone?(value) do
        String.match?(value, ~r/^\d{2,4}-\d{2,4}-\d{4}$/)
      end

      defp valid_age?(value) when is_integer(value) and value >= 0 and value <= 150, do: true
      defp valid_age?(_), do: false

      defp range_validator(min, max) do
        fn value -> value >= min and value <= max end
      end

      defp pattern_validator(regex) do
        fn value -> String.match?(value, regex) end
      end

      defp all_validator(validators) do
        fn value ->
          validators
          |> Enum.map(&create/1)
          |> Enum.all?(fn validator -> validator.(value) end)
        end
      end
    end
  end

  # ============================================================
  # 3. Observer + State パターン
  # ============================================================

  defmodule ObserverState do
    @moduledoc """
    Observer と State の組み合わせ

    状態変化を監視し、適切な通知を行う
    """

    defmodule OrderStateMachine do
      use GenServer

      defstruct [:state, :order_id, :observers, :history]

      @states [:pending, :confirmed, :shipped, :delivered, :cancelled]
      @transitions %{
        pending: [:confirmed, :cancelled],
        confirmed: [:shipped, :cancelled],
        shipped: [:delivered],
        delivered: [],
        cancelled: []
      }

      def start_link(order_id, opts \\ []) do
        name = Keyword.get(opts, :name)
        GenServer.start_link(__MODULE__, order_id, name: name)
      end

      def current_state(pid), do: GenServer.call(pid, :current_state)
      def history(pid), do: GenServer.call(pid, :history)

      def subscribe(pid, observer) do
        GenServer.call(pid, {:subscribe, observer})
      end

      def unsubscribe(pid, observer_id) do
        GenServer.call(pid, {:unsubscribe, observer_id})
      end

      def transition(pid, new_state) do
        GenServer.call(pid, {:transition, new_state})
      end

      def stop(pid) do
        if Process.alive?(pid), do: GenServer.stop(pid)
      end

      @impl true
      def init(order_id) do
        {:ok, %__MODULE__{
          state: :pending,
          order_id: order_id,
          observers: [],
          history: [{:pending, DateTime.utc_now()}]
        }}
      end

      @impl true
      def handle_call(:current_state, _from, machine) do
        {:reply, machine.state, machine}
      end

      @impl true
      def handle_call(:history, _from, machine) do
        {:reply, Enum.reverse(machine.history), machine}
      end

      @impl true
      def handle_call({:subscribe, observer}, _from, machine) do
        id = :erlang.unique_integer([:positive])
        observers = [{id, observer} | machine.observers]
        {:reply, {:ok, id}, %{machine | observers: observers}}
      end

      @impl true
      def handle_call({:unsubscribe, observer_id}, _from, machine) do
        observers = Enum.reject(machine.observers, fn {id, _} -> id == observer_id end)
        {:reply, :ok, %{machine | observers: observers}}
      end

      @impl true
      def handle_call({:transition, new_state}, _from, machine) do
        allowed = Map.get(@transitions, machine.state, [])

        if new_state in allowed do
          # 状態を変更
          timestamp = DateTime.utc_now()
          new_machine = %{machine |
            state: new_state,
            history: [{new_state, timestamp} | machine.history]
          }

          # オブザーバーに通知
          event = %{
            order_id: machine.order_id,
            old_state: machine.state,
            new_state: new_state,
            timestamp: timestamp
          }
          notify_observers(new_machine.observers, event)

          {:reply, {:ok, new_state}, new_machine}
        else
          {:reply, {:error, :invalid_transition}, machine}
        end
      end

      defp notify_observers(observers, event) do
        Enum.each(observers, fn {_id, observer} ->
          try do
            observer.(event)
          rescue
            _ -> :ok
          end
        end)
      end
    end
  end

  # ============================================================
  # 4. Decorator + Pipeline パターン
  # ============================================================

  defmodule DecoratorPipeline do
    @moduledoc """
    Decorator と Pipeline の組み合わせ

    処理パイプラインに動的に機能を追加する
    """

    # ログデコレータ
    def with_logging(func, label \\ "operation") do
      fn input ->
        IO.puts("[#{label}] Input: #{inspect(input)}")
        result = func.(input)
        IO.puts("[#{label}] Output: #{inspect(result)}")
        result
      end
    end

    # タイミングデコレータ
    def with_timing(func) do
      fn input ->
        start = System.monotonic_time(:microsecond)
        result = func.(input)
        elapsed = System.monotonic_time(:microsecond) - start
        {result, elapsed}
      end
    end

    # エラーハンドリングデコレータ
    def with_error_handling(func, default \\ nil) do
      fn input ->
        try do
          {:ok, func.(input)}
        rescue
          e -> {:error, e, default}
        end
      end
    end

    # リトライデコレータ
    def with_retry(func, max_attempts \\ 3, delay \\ 100) do
      fn input ->
        do_retry(func, input, max_attempts, delay, 1)
      end
    end

    defp do_retry(func, input, max_attempts, _delay, attempt) when attempt > max_attempts do
      {:error, :max_retries_exceeded}
    end

    defp do_retry(func, input, max_attempts, delay, attempt) do
      try do
        {:ok, func.(input)}
      rescue
        _ ->
          Process.sleep(delay)
          do_retry(func, input, max_attempts, delay, attempt + 1)
      end
    end

    # キャッシュデコレータ（Agent使用）
    defmodule CacheDecorator do
      def start_link do
        Agent.start_link(fn -> %{} end)
      end

      def with_cache(func, cache_pid) do
        fn input ->
          case Agent.get(cache_pid, &Map.get(&1, input)) do
            nil ->
              result = func.(input)
              Agent.update(cache_pid, &Map.put(&1, input, result))
              result
            cached ->
              cached
          end
        end
      end

      def stop(pid) do
        if Process.alive?(pid), do: Agent.stop(pid)
      end
    end

    # パイプラインビルダー
    defmodule PipelineBuilder do
      defstruct steps: []

      def new, do: %__MODULE__{}

      def add_step(builder, step) do
        %{builder | steps: builder.steps ++ [step]}
      end

      def add_logging(builder, label \\ "step") do
        add_step(builder, &DecoratorPipeline.with_logging(&1, label))
      end

      def add_error_handling(builder, default \\ nil) do
        add_step(builder, &DecoratorPipeline.with_error_handling(&1, default))
      end

      def build(builder, base_func) do
        Enum.reduce(builder.steps, base_func, fn decorator, func ->
          decorator.(func)
        end)
      end

      def execute(builder, base_func, input) do
        pipeline = build(builder, base_func)
        pipeline.(input)
      end
    end
  end

  # ============================================================
  # 5. Composite + Visitor パターン
  # ============================================================

  defmodule CompositeVisitor do
    @moduledoc """
    Composite と Visitor の組み合わせ

    複合構造を走査し、各要素に操作を適用する
    """

    # ファイルシステムのコンポジット
    defmodule FileSystem do
      defmodule File do
        defstruct [:name, :size, :content]

        def new(name, size, content \\ "") do
          %__MODULE__{name: name, size: size, content: content}
        end
      end

      defmodule Directory do
        defstruct [:name, children: []]

        def new(name, children \\ []) do
          %__MODULE__{name: name, children: children}
        end

        def add_child(dir, child) do
          %{dir | children: dir.children ++ [child]}
        end
      end

      # ビジター関数
      @doc "合計サイズを計算"
      def total_size(%File{size: size}), do: size
      def total_size(%Directory{children: children}) do
        children
        |> Enum.map(&total_size/1)
        |> Enum.sum()
      end

      @doc "ファイル数をカウント"
      def file_count(%File{}), do: 1
      def file_count(%Directory{children: children}) do
        children
        |> Enum.map(&file_count/1)
        |> Enum.sum()
      end

      @doc "ディレクトリ数をカウント"
      def dir_count(%File{}), do: 0
      def dir_count(%Directory{children: children}) do
        1 + Enum.sum(Enum.map(children, &dir_count/1))
      end

      @doc "すべてのファイル名を取得"
      def all_files(%File{name: name}), do: [name]
      def all_files(%Directory{children: children}) do
        children
        |> Enum.flat_map(&all_files/1)
      end

      @doc "パターンにマッチするファイルを検索"
      def find_files(%File{name: name} = file, pattern) do
        if String.match?(name, pattern), do: [file], else: []
      end
      def find_files(%Directory{children: children}, pattern) do
        children
        |> Enum.flat_map(&find_files(&1, pattern))
      end

      @doc "ツリー構造を表示"
      def display(node, indent \\ 0) do
        prefix = String.duplicate("  ", indent)
        case node do
          %File{name: name, size: size} ->
            "#{prefix}📄 #{name} (#{size} bytes)"

          %Directory{name: name, children: children} ->
            header = "#{prefix}📁 #{name}/"
            child_displays = Enum.map(children, &display(&1, indent + 1))
            Enum.join([header | child_displays], "\n")
        end
      end

      @doc "カスタムビジターを適用"
      def accept(%File{} = file, visitor) do
        visitor.(:file, file)
      end
      def accept(%Directory{children: children} = dir, visitor) do
        dir_result = visitor.(:directory, dir)
        child_results = Enum.map(children, &accept(&1, visitor))
        {dir_result, child_results}
      end
    end

    # 式のコンポジット
    defmodule Expression do
      defmodule Number do
        defstruct [:value]
        def new(value), do: %__MODULE__{value: value}
      end

      defmodule BinaryOp do
        defstruct [:op, :left, :right]
        def new(op, left, right), do: %__MODULE__{op: op, left: left, right: right}
      end

      defmodule UnaryOp do
        defstruct [:op, :operand]
        def new(op, operand), do: %__MODULE__{op: op, operand: operand}
      end

      # 評価ビジター
      def evaluate(%Number{value: v}), do: v
      def evaluate(%BinaryOp{op: :add, left: l, right: r}), do: evaluate(l) + evaluate(r)
      def evaluate(%BinaryOp{op: :sub, left: l, right: r}), do: evaluate(l) - evaluate(r)
      def evaluate(%BinaryOp{op: :mul, left: l, right: r}), do: evaluate(l) * evaluate(r)
      def evaluate(%BinaryOp{op: :div, left: l, right: r}), do: evaluate(l) / evaluate(r)
      def evaluate(%UnaryOp{op: :neg, operand: o}), do: -evaluate(o)

      # 文字列表現ビジター
      def stringify(%Number{value: v}), do: "#{v}"
      def stringify(%BinaryOp{op: op, left: l, right: r}) do
        op_str = case op do
          :add -> "+"
          :sub -> "-"
          :mul -> "*"
          :div -> "/"
        end
        "(#{stringify(l)} #{op_str} #{stringify(r)})"
      end
      def stringify(%UnaryOp{op: :neg, operand: o}) do
        "(-#{stringify(o)})"
      end

      # ノード数カウントビジター
      def node_count(%Number{}), do: 1
      def node_count(%BinaryOp{left: l, right: r}), do: 1 + node_count(l) + node_count(r)
      def node_count(%UnaryOp{operand: o}), do: 1 + node_count(o)

      # 深さ計算ビジター
      def depth(%Number{}), do: 1
      def depth(%BinaryOp{left: l, right: r}), do: 1 + max(depth(l), depth(r))
      def depth(%UnaryOp{operand: o}), do: 1 + depth(o)
    end
  end

  # ============================================================
  # 6. パターン統合の実践例
  # ============================================================

  defmodule IntegratedExample do
    @moduledoc """
    複数パターンを統合した実践的な例
    """

    alias Chapter20.StrategyFactory.{DiscountFactory, ValidatorFactory}
    alias Chapter20.DecoratorPipeline.PipelineBuilder

    # 注文処理システム
    defmodule OrderProcessor do
      defstruct [:customer_type, :items, :validators]

      def new(customer_type) do
        %__MODULE__{
          customer_type: customer_type,
          items: [],
          validators: []
        }
      end

      def add_item(processor, name, price) do
        %{processor | items: [{name, price} | processor.items]}
      end

      def add_validator(processor, validator_type) do
        %{processor | validators: [validator_type | processor.validators]}
      end

      def validate(processor, data) do
        processor.validators
        |> Enum.map(&ValidatorFactory.create/1)
        |> Enum.all?(fn validator -> validator.(data) end)
      end

      def calculate_total(processor) do
        strategy = DiscountFactory.create(processor.customer_type)
        processor.items
        |> Enum.map(fn {_name, price} -> strategy.(price) end)
        |> Enum.sum()
      end

      def process(processor) do
        # パイプラインでの処理
        pipeline = PipelineBuilder.new()
        |> PipelineBuilder.add_error_handling(0.0)

        PipelineBuilder.execute(pipeline, fn _ ->
          calculate_total(processor)
        end, processor)
      end
    end
  end
end
