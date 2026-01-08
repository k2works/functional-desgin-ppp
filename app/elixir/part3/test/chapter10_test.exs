defmodule Chapter10Test do
  use ExUnit.Case
  doctest Chapter10

  alias Chapter10.{
    BasicProcess,
    Counter,
    KeyValueStore,
    BankAccount,
    AsyncTasks,
    ParallelPatterns,
    WorkerPool,
    Synchronization,
    EventBus
  }

  # ============================================================
  # 1. 基本的なプロセス
  # ============================================================

  describe "BasicProcess" do
    test "エコープロセスはメッセージをエコーする" do
      pid = BasicProcess.start_echo()

      send(pid, {:echo, self(), "hello"})

      assert_receive {:echoed, "hello"}, 1000

      send(pid, :stop)
    end

    test "計算プロセスは加算を行う" do
      pid = BasicProcess.start_calculator()

      send(pid, {:add, self(), 2, 3})
      assert_receive {:result, 5}, 1000

      send(pid, {:multiply, self(), 4, 5})
      assert_receive {:result, 20}, 1000

      send(pid, :stop)
    end
  end

  # ============================================================
  # 2. Counter (Agent)
  # ============================================================

  describe "Counter" do
    test "初期値でカウンターを開始する" do
      {:ok, counter} = Counter.start(10)
      assert Counter.get(counter) == 10
      Agent.stop(counter)
    end

    test "インクリメントする" do
      {:ok, counter} = Counter.start(0)
      Counter.increment(counter)
      Counter.increment(counter)
      assert Counter.get(counter) == 2
      Agent.stop(counter)
    end

    test "デクリメントする" do
      {:ok, counter} = Counter.start(10)
      Counter.decrement(counter)
      assert Counter.get(counter) == 9
      Agent.stop(counter)
    end

    test "値を加算する" do
      {:ok, counter} = Counter.start(0)
      Counter.add(counter, 5)
      Counter.add(counter, 3)
      assert Counter.get(counter) == 8
      Agent.stop(counter)
    end

    test "リセットする" do
      {:ok, counter} = Counter.start(100)
      Counter.reset(counter)
      assert Counter.get(counter) == 0
      Agent.stop(counter)
    end

    test "並行アクセスでも安全" do
      {:ok, counter} = Counter.start(0)

      tasks = for _ <- 1..100 do
        Task.async(fn -> Counter.increment(counter) end)
      end

      Enum.each(tasks, &Task.await/1)

      assert Counter.get(counter) == 100
      Agent.stop(counter)
    end
  end

  # ============================================================
  # 3. KeyValueStore (Agent)
  # ============================================================

  describe "KeyValueStore" do
    test "値を設定・取得する" do
      {:ok, store} = KeyValueStore.start()
      KeyValueStore.put(store, "name", "Alice")
      assert KeyValueStore.get(store, "name") == "Alice"
      Agent.stop(store)
    end

    test "存在しないキーは nil を返す" do
      {:ok, store} = KeyValueStore.start()
      assert KeyValueStore.get(store, "missing") == nil
      Agent.stop(store)
    end

    test "値を削除する" do
      {:ok, store} = KeyValueStore.start()
      KeyValueStore.put(store, "key", "value")
      KeyValueStore.delete(store, "key")
      assert KeyValueStore.get(store, "key") == nil
      Agent.stop(store)
    end

    test "すべてのキーを取得する" do
      {:ok, store} = KeyValueStore.start()
      KeyValueStore.put(store, "a", 1)
      KeyValueStore.put(store, "b", 2)
      keys = KeyValueStore.keys(store)
      assert "a" in keys
      assert "b" in keys
      Agent.stop(store)
    end

    test "すべての値を取得する" do
      {:ok, store} = KeyValueStore.start()
      KeyValueStore.put(store, "a", 1)
      KeyValueStore.put(store, "b", 2)
      values = KeyValueStore.values(store)
      assert 1 in values
      assert 2 in values
      Agent.stop(store)
    end
  end

  # ============================================================
  # 4. BankAccount (GenServer)
  # ============================================================

  describe "BankAccount" do
    test "口座を開設する" do
      {:ok, account} = BankAccount.open("ACC001", 1000)
      assert BankAccount.balance(account) == 1000
      GenServer.stop(account)
    end

    test "入金する" do
      {:ok, account} = BankAccount.open("ACC001", 0)
      assert {:ok, 500} = BankAccount.deposit(account, 500)
      assert BankAccount.balance(account) == 500
      GenServer.stop(account)
    end

    test "出金する" do
      {:ok, account} = BankAccount.open("ACC001", 1000)
      assert {:ok, 700} = BankAccount.withdraw(account, 300)
      assert BankAccount.balance(account) == 700
      GenServer.stop(account)
    end

    test "残高不足で出金できない" do
      {:ok, account} = BankAccount.open("ACC001", 100)
      assert {:error, "残高不足"} = BankAccount.withdraw(account, 200)
      assert BankAccount.balance(account) == 100
      GenServer.stop(account)
    end

    test "送金する" do
      {:ok, from} = BankAccount.open("ACC001", 1000)
      {:ok, to} = BankAccount.open("ACC002", 0)

      assert :ok = BankAccount.transfer(from, to, 300)

      assert BankAccount.balance(from) == 700
      assert BankAccount.balance(to) == 300

      GenServer.stop(from)
      GenServer.stop(to)
    end

    test "残高不足で送金できない" do
      {:ok, from} = BankAccount.open("ACC001", 100)
      {:ok, to} = BankAccount.open("ACC002", 0)

      assert {:error, "残高不足"} = BankAccount.transfer(from, to, 200)

      assert BankAccount.balance(from) == 100
      assert BankAccount.balance(to) == 0

      GenServer.stop(from)
      GenServer.stop(to)
    end
  end

  # ============================================================
  # 5. AsyncTasks
  # ============================================================

  describe "AsyncTasks" do
    test "非同期計算を実行する" do
      task = AsyncTasks.async_compute(fn -> 1 + 1 end)
      assert AsyncTasks.await(task) == 2
    end

    test "複数のタスクを並列実行する" do
      tasks = [
        fn -> 1 end,
        fn -> 2 end,
        fn -> 3 end
      ]

      results = AsyncTasks.parallel_execute(tasks)
      assert results == [1, 2, 3]
    end

    test "タイムアウト付きで実行する" do
      assert {:ok, :fast} = AsyncTasks.with_timeout(fn -> :fast end, 1000)
      assert {:error, :timeout} = AsyncTasks.with_timeout(fn -> Process.sleep(500); :slow end, 100)
    end

    test "parallel_map はリストを並列処理する" do
      results = AsyncTasks.parallel_map([1, 2, 3], fn x -> x * 2 end)
      assert results == [2, 4, 6]
    end

    test "race は最初に完了したタスクの結果を返す" do
      tasks = [
        fn -> Process.sleep(100); :slow end,
        fn -> :fast end
      ]

      result = AsyncTasks.race(tasks)
      assert result == :fast
    end
  end

  # ============================================================
  # 6. ParallelPatterns
  # ============================================================

  describe "ParallelPatterns" do
    test "map_reduce パターン" do
      data = [1, 2, 3, 4, 5]
      result = ParallelPatterns.map_reduce(data, &(&1 * 2), &Enum.sum/1)
      assert result == 30
    end

    test "pipeline パターン" do
      stages = [
        fn x -> x * 2 end,
        fn x -> x + 1 end
      ]

      results = ParallelPatterns.pipeline([1, 2, 3], stages)
      assert results == [3, 5, 7]
    end

    test "fan_out_fan_in パターン" do
      workers = [
        fn x -> x + 1 end,
        fn x -> x * 2 end,
        fn x -> x - 1 end
      ]

      results = ParallelPatterns.fan_out_fan_in(10, workers)
      assert Enum.sort(results) == [9, 11, 20]
    end

    test "batch_process パターン" do
      data = Enum.to_list(1..10)
      results = ParallelPatterns.batch_process(data, 3, &Enum.sum/1)
      assert results == [6, 15, 24, 10]
    end
  end

  # ============================================================
  # 7. WorkerPool
  # ============================================================

  describe "WorkerPool" do
    test "ワーカープールでタスクを実行する" do
      {:ok, pool} = WorkerPool.start(3)

      result = WorkerPool.submit(pool, 5, fn x -> x * 2 end)
      assert result == 10

      WorkerPool.stop(pool)
    end

    test "複数のタスクを並列実行する" do
      {:ok, pool} = WorkerPool.start(3)

      results = WorkerPool.submit_all(pool, [1, 2, 3, 4, 5], fn x -> x * 2 end)
      assert Enum.sort(results) == [2, 4, 6, 8, 10]

      WorkerPool.stop(pool)
    end
  end

  # ============================================================
  # 8. Synchronization
  # ============================================================

  describe "Synchronization" do
    test "barrier はすべてのタスクが完了するまで待機する" do
      results = Synchronization.barrier([
        fn -> Process.sleep(10); 1 end,
        fn -> 2 end,
        fn -> 3 end
      ])

      assert Enum.sort(results) == [1, 2, 3]
    end

    test "セマフォは同時実行数を制限する" do
      {:ok, sem} = Synchronization.semaphore(2)

      # 2つまで同時取得可能
      assert :ok = Synchronization.acquire(sem)
      assert :ok = Synchronization.acquire(sem)

      # リリースすると再び取得可能
      Synchronization.release(sem)
      assert :ok = Synchronization.acquire(sem)

      Agent.stop(sem)
    end

    test "リソースプールはリソースを貸し出す" do
      {:ok, pool} = Synchronization.resource_pool([:r1, :r2])

      {:ok, r1} = Synchronization.borrow(pool)
      {:ok, r2} = Synchronization.borrow(pool)
      assert {:error, :empty} = Synchronization.borrow(pool)

      Synchronization.return(pool, r1)
      {:ok, r3} = Synchronization.borrow(pool)
      assert r3 == r1

      Agent.stop(pool)
    end
  end

  # ============================================================
  # 9. EventBus
  # ============================================================

  describe "EventBus" do
    test "イベントを購読・発行する" do
      {:ok, bus} = EventBus.start()

      EventBus.subscribe(bus, :user_created, self())
      EventBus.publish(bus, :user_created, %{id: 1, name: "Alice"})

      assert_receive {:event, :user_created, %{id: 1, name: "Alice"}}, 1000

      Agent.stop(bus)
    end

    test "複数の購読者にイベントを配信する" do
      {:ok, bus} = EventBus.start()

      # 2つのプロセスで購読
      EventBus.subscribe(bus, :event, self())
      EventBus.subscribe(bus, :event, self())

      EventBus.publish(bus, :event, :data)

      # 2回受信するはず
      assert_receive {:event, :event, :data}, 1000
      assert_receive {:event, :event, :data}, 1000

      Agent.stop(bus)
    end

    test "購読を解除する" do
      {:ok, bus} = EventBus.start()

      EventBus.subscribe(bus, :event, self())
      EventBus.unsubscribe(bus, :event, self())
      EventBus.publish(bus, :event, :data)

      refute_receive {:event, :event, :data}, 100

      Agent.stop(bus)
    end
  end
end
