defmodule Chapter10 do
  @moduledoc """
  # Chapter 10: Concurrency Patterns

  このモジュールでは、Elixir の並行処理パターンを学びます。
  関数型プログラミングとアクターモデルを組み合わせた
  安全で効率的な並行プログラミングを実装します。

  ## 主なトピック

  1. プロセスとメッセージパッシング
  2. Agent（状態管理）
  3. GenServer（汎用サーバー）
  4. Task（非同期処理）
  5. 並列処理パターン
  6. スーパーバイザー
  """

  # ============================================================
  # 1. 基本的なプロセスとメッセージパッシング
  # ============================================================

  defmodule BasicProcess do
    @moduledoc """
    基本的なプロセス操作の例。
    """

    @doc """
    単純なエコープロセスを起動する。

    ## Examples

        iex> pid = Chapter10.BasicProcess.start_echo()
        iex> send(pid, {:echo, self(), "hello"})
        iex> receive do
        ...>   {:echoed, msg} -> msg
        ...> after
        ...>   1000 -> :timeout
        ...> end
        "hello"
    """
    @spec start_echo() :: pid()
    def start_echo do
      spawn(fn -> echo_loop() end)
    end

    defp echo_loop do
      receive do
        {:echo, from, message} ->
          send(from, {:echoed, message})
          echo_loop()
        :stop ->
          :ok
      end
    end

    @doc """
    計算を行うプロセスを起動する。

    ## Examples

        iex> pid = Chapter10.BasicProcess.start_calculator()
        iex> send(pid, {:add, self(), 2, 3})
        iex> receive do
        ...>   {:result, result} -> result
        ...> after
        ...>   1000 -> :timeout
        ...> end
        5
    """
    @spec start_calculator() :: pid()
    def start_calculator do
      spawn(fn -> calculator_loop() end)
    end

    defp calculator_loop do
      receive do
        {:add, from, a, b} ->
          send(from, {:result, a + b})
          calculator_loop()
        {:multiply, from, a, b} ->
          send(from, {:result, a * b})
          calculator_loop()
        :stop ->
          :ok
      end
    end
  end

  # ============================================================
  # 2. Agent による状態管理
  # ============================================================

  defmodule Counter do
    @moduledoc """
    Agent を使用したカウンター。
    関数型の状態管理パターン。
    """

    @doc """
    カウンターを開始する。

    ## Examples

        iex> {:ok, counter} = Chapter10.Counter.start(0)
        iex> Chapter10.Counter.get(counter)
        0
    """
    @spec start(integer()) :: {:ok, pid()}
    def start(initial_value \\ 0) do
      Agent.start_link(fn -> initial_value end)
    end

    @doc """
    現在の値を取得する。

    ## Examples

        iex> {:ok, counter} = Chapter10.Counter.start(10)
        iex> Chapter10.Counter.get(counter)
        10
    """
    @spec get(pid()) :: integer()
    def get(counter) do
      Agent.get(counter, & &1)
    end

    @doc """
    カウンターをインクリメントする。

    ## Examples

        iex> {:ok, counter} = Chapter10.Counter.start(0)
        iex> Chapter10.Counter.increment(counter)
        iex> Chapter10.Counter.get(counter)
        1
    """
    @spec increment(pid()) :: :ok
    def increment(counter) do
      Agent.update(counter, &(&1 + 1))
    end

    @doc """
    カウンターをデクリメントする。

    ## Examples

        iex> {:ok, counter} = Chapter10.Counter.start(10)
        iex> Chapter10.Counter.decrement(counter)
        iex> Chapter10.Counter.get(counter)
        9
    """
    @spec decrement(pid()) :: :ok
    def decrement(counter) do
      Agent.update(counter, &(&1 - 1))
    end

    @doc """
    指定した値を加算する。

    ## Examples

        iex> {:ok, counter} = Chapter10.Counter.start(0)
        iex> Chapter10.Counter.add(counter, 5)
        iex> Chapter10.Counter.get(counter)
        5
    """
    @spec add(pid(), integer()) :: :ok
    def add(counter, value) do
      Agent.update(counter, &(&1 + value))
    end

    @doc """
    カウンターをリセットする。

    ## Examples

        iex> {:ok, counter} = Chapter10.Counter.start(100)
        iex> Chapter10.Counter.reset(counter)
        iex> Chapter10.Counter.get(counter)
        0
    """
    @spec reset(pid()) :: :ok
    def reset(counter) do
      Agent.update(counter, fn _ -> 0 end)
    end
  end

  defmodule KeyValueStore do
    @moduledoc """
    Agent を使用したキーバリューストア。
    """

    @doc """
    ストアを開始する。

    ## Examples

        iex> {:ok, store} = Chapter10.KeyValueStore.start()
        iex> Chapter10.KeyValueStore.get(store, "key")
        nil
    """
    @spec start() :: {:ok, pid()}
    def start do
      Agent.start_link(fn -> %{} end)
    end

    @doc """
    値を設定する。

    ## Examples

        iex> {:ok, store} = Chapter10.KeyValueStore.start()
        iex> Chapter10.KeyValueStore.put(store, "name", "Alice")
        iex> Chapter10.KeyValueStore.get(store, "name")
        "Alice"
    """
    @spec put(pid(), any(), any()) :: :ok
    def put(store, key, value) do
      Agent.update(store, &Map.put(&1, key, value))
    end

    @doc """
    値を取得する。

    ## Examples

        iex> {:ok, store} = Chapter10.KeyValueStore.start()
        iex> Chapter10.KeyValueStore.put(store, "key", "value")
        iex> Chapter10.KeyValueStore.get(store, "key")
        "value"
    """
    @spec get(pid(), any()) :: any()
    def get(store, key) do
      Agent.get(store, &Map.get(&1, key))
    end

    @doc """
    値を削除する。

    ## Examples

        iex> {:ok, store} = Chapter10.KeyValueStore.start()
        iex> Chapter10.KeyValueStore.put(store, "key", "value")
        iex> Chapter10.KeyValueStore.delete(store, "key")
        iex> Chapter10.KeyValueStore.get(store, "key")
        nil
    """
    @spec delete(pid(), any()) :: :ok
    def delete(store, key) do
      Agent.update(store, &Map.delete(&1, key))
    end

    @doc """
    すべてのキーを取得する。

    ## Examples

        iex> {:ok, store} = Chapter10.KeyValueStore.start()
        iex> Chapter10.KeyValueStore.put(store, "a", 1)
        iex> Chapter10.KeyValueStore.put(store, "b", 2)
        iex> keys = Chapter10.KeyValueStore.keys(store)
        iex> "a" in keys and "b" in keys
        true
    """
    @spec keys(pid()) :: [any()]
    def keys(store) do
      Agent.get(store, &Map.keys(&1))
    end

    @doc """
    すべての値を取得する。

    ## Examples

        iex> {:ok, store} = Chapter10.KeyValueStore.start()
        iex> Chapter10.KeyValueStore.put(store, "a", 1)
        iex> Chapter10.KeyValueStore.put(store, "b", 2)
        iex> values = Chapter10.KeyValueStore.values(store)
        iex> 1 in values and 2 in values
        true
    """
    @spec values(pid()) :: [any()]
    def values(store) do
      Agent.get(store, &Map.values(&1))
    end
  end

  # ============================================================
  # 3. GenServer パターン
  # ============================================================

  defmodule BankAccount do
    @moduledoc """
    GenServer を使用した銀行口座。
    状態とビジネスロジックをカプセル化。
    """
    use GenServer

    # Client API

    @doc """
    口座を開設する。

    ## Examples

        iex> {:ok, account} = Chapter10.BankAccount.open("ACC001", 1000)
        iex> Chapter10.BankAccount.balance(account)
        1000
    """
    @spec open(String.t(), non_neg_integer()) :: {:ok, pid()}
    def open(account_id, initial_balance \\ 0) do
      GenServer.start_link(__MODULE__, %{id: account_id, balance: initial_balance})
    end

    @doc """
    残高を取得する。
    """
    @spec balance(pid()) :: non_neg_integer()
    def balance(account) do
      GenServer.call(account, :balance)
    end

    @doc """
    入金する。

    ## Examples

        iex> {:ok, account} = Chapter10.BankAccount.open("ACC001", 0)
        iex> Chapter10.BankAccount.deposit(account, 500)
        {:ok, 500}
        iex> Chapter10.BankAccount.balance(account)
        500
    """
    @spec deposit(pid(), pos_integer()) :: {:ok, non_neg_integer()} | {:error, String.t()}
    def deposit(account, amount) do
      GenServer.call(account, {:deposit, amount})
    end

    @doc """
    出金する。

    ## Examples

        iex> {:ok, account} = Chapter10.BankAccount.open("ACC001", 1000)
        iex> Chapter10.BankAccount.withdraw(account, 300)
        {:ok, 700}
        iex> Chapter10.BankAccount.withdraw(account, 1000)
        {:error, "残高不足"}
    """
    @spec withdraw(pid(), pos_integer()) :: {:ok, non_neg_integer()} | {:error, String.t()}
    def withdraw(account, amount) do
      GenServer.call(account, {:withdraw, amount})
    end

    @doc """
    別の口座に送金する。

    ## Examples

        iex> {:ok, from} = Chapter10.BankAccount.open("ACC001", 1000)
        iex> {:ok, to} = Chapter10.BankAccount.open("ACC002", 0)
        iex> Chapter10.BankAccount.transfer(from, to, 300)
        :ok
        iex> Chapter10.BankAccount.balance(from)
        700
        iex> Chapter10.BankAccount.balance(to)
        300
    """
    @spec transfer(pid(), pid(), pos_integer()) :: :ok | {:error, String.t()}
    def transfer(from, to, amount) do
      case withdraw(from, amount) do
        {:ok, _} ->
          deposit(to, amount)
          :ok
        {:error, _} = error ->
          error
      end
    end

    # Server Callbacks

    @impl true
    def init(state) do
      {:ok, state}
    end

    @impl true
    def handle_call(:balance, _from, state) do
      {:reply, state.balance, state}
    end

    @impl true
    def handle_call({:deposit, amount}, _from, state) when amount > 0 do
      new_balance = state.balance + amount
      {:reply, {:ok, new_balance}, %{state | balance: new_balance}}
    end

    @impl true
    def handle_call({:deposit, _amount}, _from, state) do
      {:reply, {:error, "金額は正の数である必要があります"}, state}
    end

    @impl true
    def handle_call({:withdraw, amount}, _from, state) when amount > 0 do
      if state.balance >= amount do
        new_balance = state.balance - amount
        {:reply, {:ok, new_balance}, %{state | balance: new_balance}}
      else
        {:reply, {:error, "残高不足"}, state}
      end
    end

    @impl true
    def handle_call({:withdraw, _amount}, _from, state) do
      {:reply, {:error, "金額は正の数である必要があります"}, state}
    end
  end

  # ============================================================
  # 4. Task による非同期処理
  # ============================================================

  defmodule AsyncTasks do
    @moduledoc """
    Task を使用した非同期処理パターン。
    """

    @doc """
    非同期でタスクを実行し、結果を待つ。

    ## Examples

        iex> task = Chapter10.AsyncTasks.async_compute(fn -> 1 + 1 end)
        iex> Chapter10.AsyncTasks.await(task)
        2
    """
    @spec async_compute((() -> any())) :: Task.t()
    def async_compute(fun) do
      Task.async(fun)
    end

    @spec await(Task.t()) :: any()
    def await(task) do
      Task.await(task)
    end

    @doc """
    複数のタスクを並列実行する。

    ## Examples

        iex> tasks = [fn -> 1 end, fn -> 2 end, fn -> 3 end]
        iex> Chapter10.AsyncTasks.parallel_execute(tasks)
        [1, 2, 3]
    """
    @spec parallel_execute([(() -> any())]) :: [any()]
    def parallel_execute(functions) do
      functions
      |> Enum.map(&Task.async/1)
      |> Enum.map(&Task.await/1)
    end

    @doc """
    タイムアウト付きで非同期タスクを実行する。

    ## Examples

        iex> result = Chapter10.AsyncTasks.with_timeout(fn -> :ok end, 1000)
        iex> result
        {:ok, :ok}
    """
    @spec with_timeout((() -> any()), pos_integer()) :: {:ok, any()} | {:error, :timeout}
    def with_timeout(fun, timeout_ms) do
      task = Task.async(fun)
      case Task.yield(task, timeout_ms) || Task.shutdown(task) do
        {:ok, result} -> {:ok, result}
        nil -> {:error, :timeout}
      end
    end

    @doc """
    リストの各要素に対して並列で関数を適用する。

    ## Examples

        iex> Chapter10.AsyncTasks.parallel_map([1, 2, 3], fn x -> x * 2 end)
        [2, 4, 6]
    """
    @spec parallel_map([a], (a -> b)) :: [b] when a: any(), b: any()
    def parallel_map(list, fun) do
      list
      |> Enum.map(fn item -> Task.async(fn -> fun.(item) end) end)
      |> Enum.map(&Task.await/1)
    end

    @doc """
    最初に完了したタスクの結果を返す。

    ## Examples

        iex> tasks = [
        ...>   fn -> Process.sleep(100); :slow end,
        ...>   fn -> :fast end
        ...> ]
        iex> Chapter10.AsyncTasks.race(tasks)
        :fast
    """
    @spec race([(() -> any())]) :: any()
    def race(functions) do
      parent = self()

      pids = Enum.map(functions, fn fun ->
        spawn(fn ->
          result = fun.()
          send(parent, {:result, self(), result})
        end)
      end)

      receive do
        {:result, _pid, result} ->
          # 他のプロセスを終了
          Enum.each(pids, fn pid ->
            if Process.alive?(pid), do: Process.exit(pid, :kill)
          end)
          result
      end
    end
  end

  # ============================================================
  # 5. 並列処理パターン
  # ============================================================

  defmodule ParallelPatterns do
    @moduledoc """
    よくある並列処理パターンの実装。
    """

    @doc """
    Map-Reduce パターン。

    ## Examples

        iex> data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        iex> Chapter10.ParallelPatterns.map_reduce(data, &(&1 * 2), &Enum.sum/1)
        110
    """
    @spec map_reduce([a], (a -> b), ([b] -> c)) :: c when a: any(), b: any(), c: any()
    def map_reduce(data, mapper, reducer) do
      data
      |> Task.async_stream(mapper, ordered: false)
      |> Enum.map(fn {:ok, result} -> result end)
      |> reducer.()
    end

    @doc """
    パイプラインパターン（ステージごとに処理）。

    ## Examples

        iex> stages = [
        ...>   fn x -> x * 2 end,
        ...>   fn x -> x + 1 end,
        ...>   fn x -> x * 3 end
        ...> ]
        iex> Chapter10.ParallelPatterns.pipeline([1, 2, 3], stages)
        [9, 15, 21]
    """
    @spec pipeline([a], [(a -> a)]) :: [a] when a: any()
    def pipeline(data, stages) do
      Enum.reduce(stages, data, fn stage, acc ->
        Task.async_stream(acc, stage)
        |> Enum.map(fn {:ok, result} -> result end)
      end)
    end

    @doc """
    ファンアウト・ファンイン パターン。
    一つのデータを複数のワーカーで処理し、結果を集約する。

    ## Examples

        iex> workers = [
        ...>   fn x -> x + 1 end,
        ...>   fn x -> x * 2 end,
        ...>   fn x -> x - 1 end
        ...> ]
        iex> results = Chapter10.ParallelPatterns.fan_out_fan_in(10, workers)
        iex> Enum.sort(results)
        [9, 11, 20]
    """
    @spec fan_out_fan_in(a, [(a -> b)]) :: [b] when a: any(), b: any()
    def fan_out_fan_in(data, workers) do
      workers
      |> Enum.map(fn worker -> Task.async(fn -> worker.(data) end) end)
      |> Enum.map(&Task.await/1)
    end

    @doc """
    バッチ処理パターン。
    データを指定サイズのバッチに分割して処理する。

    ## Examples

        iex> data = Enum.to_list(1..10)
        iex> Chapter10.ParallelPatterns.batch_process(data, 3, &Enum.sum/1)
        [6, 15, 24, 10]
    """
    @spec batch_process([a], pos_integer(), ([a] -> b)) :: [b] when a: any(), b: any()
    def batch_process(data, batch_size, processor) do
      data
      |> Enum.chunk_every(batch_size)
      |> Task.async_stream(processor)
      |> Enum.map(fn {:ok, result} -> result end)
    end
  end

  # ============================================================
  # 6. ワーカープール
  # ============================================================

  defmodule WorkerPool do
    @moduledoc """
    シンプルなワーカープールの実装。
    """

    @doc """
    ワーカープールを開始する。

    ## Examples

        iex> {:ok, pool} = Chapter10.WorkerPool.start(3)
        iex> results = Chapter10.WorkerPool.submit_all(pool, [1, 2, 3], &(&1 * 2))
        iex> Enum.sort(results)
        [2, 4, 6]
    """
    @spec start(pos_integer()) :: {:ok, pid()}
    def start(pool_size) do
      Agent.start_link(fn ->
        %{
          workers: for(_ <- 1..pool_size, do: spawn_worker()),
          queue: :queue.new()
        }
      end)
    end

    defp spawn_worker do
      spawn(fn -> worker_loop() end)
    end

    defp worker_loop do
      receive do
        {:work, from, data, fun} ->
          result = fun.(data)
          send(from, {:result, result})
          worker_loop()
        :stop ->
          :ok
      end
    end

    @doc """
    プールにタスクを送信する。
    """
    @spec submit(pid(), any(), (any() -> any())) :: any()
    def submit(pool, data, fun) do
      worker = Agent.get(pool, fn state ->
        Enum.random(state.workers)
      end)

      send(worker, {:work, self(), data, fun})

      receive do
        {:result, result} -> result
      end
    end

    @doc """
    複数のタスクを並列で送信する。
    """
    @spec submit_all(pid(), [any()], (any() -> any())) :: [any()]
    def submit_all(pool, items, fun) do
      workers = Agent.get(pool, fn state -> state.workers end)

      tasks = Enum.with_index(items)
      |> Enum.map(fn {item, index} ->
        worker = Enum.at(workers, rem(index, length(workers)))
        Task.async(fn ->
          send(worker, {:work, self(), item, fun})
          receive do
            {:result, result} -> result
          end
        end)
      end)

      Enum.map(tasks, &Task.await/1)
    end

    @doc """
    プールを停止する。
    """
    @spec stop(pid()) :: :ok
    def stop(pool) do
      workers = Agent.get(pool, fn state -> state.workers end)
      Enum.each(workers, fn worker -> send(worker, :stop) end)
      Agent.stop(pool)
      :ok
    end
  end

  # ============================================================
  # 7. 並行状態の同期
  # ============================================================

  defmodule Synchronization do
    @moduledoc """
    並行処理における同期パターン。
    """

    @doc """
    バリア同期：すべてのタスクが完了するまで待機。

    ## Examples

        iex> results = Chapter10.Synchronization.barrier([
        ...>   fn -> Process.sleep(10); 1 end,
        ...>   fn -> 2 end,
        ...>   fn -> 3 end
        ...> ])
        iex> Enum.sort(results)
        [1, 2, 3]
    """
    @spec barrier([(() -> any())]) :: [any()]
    def barrier(tasks) do
      tasks
      |> Enum.map(&Task.async/1)
      |> Enum.map(&Task.await/1)
    end

    @doc """
    セマフォ：同時実行数を制限。

    ## Examples

        iex> {:ok, sem} = Chapter10.Synchronization.semaphore(2)
        iex> Chapter10.Synchronization.acquire(sem)
        :ok
        iex> Chapter10.Synchronization.release(sem)
        :ok
    """
    @spec semaphore(pos_integer()) :: {:ok, pid()}
    def semaphore(max_permits) do
      Agent.start_link(fn -> max_permits end)
    end

    @spec acquire(pid()) :: :ok
    def acquire(sem) do
      case Agent.get_and_update(sem, fn
        0 -> {0, 0}
        n -> {n, n - 1}
      end) do
        0 ->
          Process.sleep(10)
          acquire(sem)
        _ ->
          :ok
      end
    end

    @spec release(pid()) :: :ok
    def release(sem) do
      Agent.update(sem, &(&1 + 1))
    end

    @doc """
    リソースプール：リソースを借りて使用後に返却。

    ## Examples

        iex> {:ok, pool} = Chapter10.Synchronization.resource_pool([:r1, :r2, :r3])
        iex> {:ok, resource} = Chapter10.Synchronization.borrow(pool)
        iex> resource in [:r1, :r2, :r3]
        true
        iex> Chapter10.Synchronization.return(pool, resource)
        :ok
    """
    @spec resource_pool([any()]) :: {:ok, pid()}
    def resource_pool(resources) do
      Agent.start_link(fn -> resources end)
    end

    @spec borrow(pid()) :: {:ok, any()} | {:error, :empty}
    def borrow(pool) do
      Agent.get_and_update(pool, fn
        [] -> {{:error, :empty}, []}
        [head | tail] -> {{:ok, head}, tail}
      end)
    end

    @spec return(pid(), any()) :: :ok
    def return(pool, resource) do
      Agent.update(pool, fn resources -> [resource | resources] end)
    end
  end

  # ============================================================
  # 8. イベント処理
  # ============================================================

  defmodule EventBus do
    @moduledoc """
    シンプルなイベントバスの実装。
    """

    @doc """
    イベントバスを開始する。

    ## Examples

        iex> {:ok, bus} = Chapter10.EventBus.start()
        iex> Chapter10.EventBus.subscribe(bus, :user_created, self())
        iex> Chapter10.EventBus.publish(bus, :user_created, %{id: 1, name: "Alice"})
        iex> receive do
        ...>   {:event, :user_created, %{name: name}} -> name
        ...> after
        ...>   1000 -> :timeout
        ...> end
        "Alice"
    """
    @spec start() :: {:ok, pid()}
    def start do
      Agent.start_link(fn -> %{} end)
    end

    @doc """
    イベントを購読する。
    """
    @spec subscribe(pid(), atom(), pid()) :: :ok
    def subscribe(bus, event_type, subscriber) do
      Agent.update(bus, fn subscriptions ->
        current = Map.get(subscriptions, event_type, [])
        Map.put(subscriptions, event_type, [subscriber | current])
      end)
    end

    @doc """
    イベントを発行する。
    """
    @spec publish(pid(), atom(), any()) :: :ok
    def publish(bus, event_type, payload) do
      subscribers = Agent.get(bus, fn subscriptions ->
        Map.get(subscriptions, event_type, [])
      end)

      Enum.each(subscribers, fn subscriber ->
        send(subscriber, {:event, event_type, payload})
      end)

      :ok
    end

    @doc """
    購読を解除する。
    """
    @spec unsubscribe(pid(), atom(), pid()) :: :ok
    def unsubscribe(bus, event_type, subscriber) do
      Agent.update(bus, fn subscriptions ->
        current = Map.get(subscriptions, event_type, [])
        Map.put(subscriptions, event_type, List.delete(current, subscriber))
      end)
    end
  end
end
