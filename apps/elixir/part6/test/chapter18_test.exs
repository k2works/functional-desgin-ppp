defmodule Chapter18Test do
  use ExUnit.Case, async: false

  alias Chapter18.{EventBus, StateMachine, PhoneSystem, MessageQueue, WorkerPool, Counter}

  # ============================================================
  # EventBus Tests
  # ============================================================

  describe "EventBus" do
    setup do
      {:ok, bus} = EventBus.start_link()
      on_exit(fn -> EventBus.stop(bus) end)
      %{bus: bus}
    end

    test "subscribe and publish", %{bus: bus} do
      test_pid = self()

      handler = fn event ->
        send(test_pid, {:received, event})
      end

      EventBus.subscribe(bus, :test_event, handler)
      Process.sleep(10)

      EventBus.publish(bus, :test_event, %{message: "Hello"})

      assert_receive {:received, event}, 100
      assert event.type == :test_event
      assert event.data.message == "Hello"
    end

    test "multiple subscribers", %{bus: bus} do
      test_pid = self()

      handler1 = fn event -> send(test_pid, {:handler1, event}) end
      handler2 = fn event -> send(test_pid, {:handler2, event}) end

      EventBus.subscribe(bus, :multi_event, handler1)
      EventBus.subscribe(bus, :multi_event, handler2)
      Process.sleep(10)

      EventBus.publish(bus, :multi_event, %{})

      assert_receive {:handler1, _}, 100
      assert_receive {:handler2, _}, 100
    end

    test "unsubscribe", %{bus: bus} do
      test_pid = self()

      handler = fn event -> send(test_pid, {:received, event}) end

      EventBus.subscribe(bus, :unsub_event, handler)
      Process.sleep(10)

      EventBus.unsubscribe(bus, :unsub_event, handler)
      Process.sleep(10)

      EventBus.publish(bus, :unsub_event, %{})

      refute_receive {:received, _}, 50
    end

    test "get_event_log", %{bus: bus} do
      EventBus.publish_sync(bus, :event1, %{n: 1})
      EventBus.publish_sync(bus, :event2, %{n: 2})

      log = EventBus.get_event_log(bus)

      assert length(log) == 2
      assert Enum.at(log, 0).type == :event1
      assert Enum.at(log, 1).type == :event2
    end

    test "clear_event_log", %{bus: bus} do
      EventBus.publish_sync(bus, :event1, %{})
      EventBus.clear_event_log(bus)
      Process.sleep(10)

      log = EventBus.get_event_log(bus)
      assert length(log) == 0
    end

    test "get_subscribers", %{bus: bus} do
      handler = fn _ -> :ok end

      EventBus.subscribe(bus, :sub_test, handler)
      Process.sleep(10)

      subscribers = EventBus.get_subscribers(bus, :sub_test)
      assert length(subscribers) == 1
    end

    test "handler errors don't crash bus", %{bus: bus} do
      bad_handler = fn _ -> raise "Intentional error" end

      EventBus.subscribe(bus, :error_event, bad_handler)
      Process.sleep(10)

      # Should not crash
      EventBus.publish(bus, :error_event, %{})
      Process.sleep(10)

      # Bus should still work
      log = EventBus.get_event_log(bus)
      assert length(log) == 1
    end
  end

  # ============================================================
  # StateMachine Tests
  # ============================================================

  describe "StateMachine" do
    setup do
      {:ok, agent} = StateMachine.start_link("Alice")
      on_exit(fn -> StateMachine.stop(agent) end)
      %{agent: agent}
    end

    test "initial state is idle", %{agent: agent} do
      assert StateMachine.get_state(agent) == :idle
    end

    test "get_user_id returns user id", %{agent: agent} do
      assert StateMachine.get_user_id(agent) == "Alice"
    end

    test "call event transitions from idle to calling", %{agent: agent} do
      StateMachine.send_event(agent, :call, %{peer: "Bob"})
      Process.sleep(10)

      assert StateMachine.get_state(agent) == :calling
    end

    test "ring event transitions from idle to waiting_for_connection", %{agent: agent} do
      StateMachine.send_event(agent, :ring, %{peer: "Bob"})
      Process.sleep(10)

      assert StateMachine.get_state(agent) == :waiting_for_connection
    end

    test "complete call sequence", %{agent: agent} do
      # idle -> calling
      StateMachine.send_event(agent, :call, %{peer: "Bob"})
      Process.sleep(10)
      assert StateMachine.get_state(agent) == :calling

      # calling -> dialing
      StateMachine.send_event(agent, :dialtone)
      Process.sleep(10)
      assert StateMachine.get_state(agent) == :dialing

      # dialing -> waiting_for_connection
      StateMachine.send_event(agent, :ringback)
      Process.sleep(10)
      assert StateMachine.get_state(agent) == :waiting_for_connection

      # waiting_for_connection -> talking
      StateMachine.send_event(agent, :connected)
      Process.sleep(10)
      assert StateMachine.get_state(agent) == :talking

      # talking -> idle
      StateMachine.send_event(agent, :disconnect)
      Process.sleep(10)
      assert StateMachine.get_state(agent) == :idle
    end

    test "invalid transition is logged", %{agent: agent} do
      # Try invalid event from idle
      StateMachine.send_event(agent, :dialtone)
      Process.sleep(10)

      log = StateMachine.get_action_log(agent)
      assert length(log) == 1

      {type, _, _} = hd(log)
      assert type == :invalid_transition
    end

    test "reset returns to idle", %{agent: agent} do
      StateMachine.send_event(agent, :call, %{peer: "Bob"})
      Process.sleep(10)
      assert StateMachine.get_state(agent) == :calling

      StateMachine.reset(agent)
      Process.sleep(10)

      assert StateMachine.get_state(agent) == :idle
    end

    test "action_log records transitions", %{agent: agent} do
      StateMachine.send_event(agent, :call, %{peer: "Bob"})
      StateMachine.send_event(agent, :dialtone)
      Process.sleep(20)

      log = StateMachine.get_action_log(agent)
      assert length(log) == 2
    end
  end

  # ============================================================
  # PhoneSystem Tests
  # ============================================================

  describe "PhoneSystem" do
    setup do
      {:ok, caller} = StateMachine.start_link("Alice")
      {:ok, callee} = StateMachine.start_link("Bob")

      on_exit(fn ->
        StateMachine.stop(caller)
        StateMachine.stop(callee)
      end)

      %{caller: caller, callee: callee}
    end

    test "make_call initiates call", %{caller: caller, callee: callee} do
      PhoneSystem.make_call(caller, callee)

      assert StateMachine.get_state(caller) == :calling
      assert StateMachine.get_state(callee) == :waiting_for_connection
    end

    test "complete_call establishes connection", %{caller: caller, callee: callee} do
      PhoneSystem.complete_call(caller, callee)

      assert StateMachine.get_state(caller) == :talking
      assert StateMachine.get_state(callee) == :talking
    end

    test "hang_up ends call", %{caller: caller, callee: callee} do
      PhoneSystem.complete_call(caller, callee)
      PhoneSystem.hang_up(caller, callee)

      assert StateMachine.get_state(caller) == :idle
      assert StateMachine.get_state(callee) == :idle
    end
  end

  # ============================================================
  # MessageQueue Tests
  # ============================================================

  describe "MessageQueue" do
    setup do
      {:ok, queue} = MessageQueue.start_link()
      on_exit(fn -> MessageQueue.stop(queue) end)
      %{queue: queue}
    end

    test "enqueue and dequeue", %{queue: queue} do
      MessageQueue.enqueue(queue, "message1")
      MessageQueue.enqueue(queue, "message2")

      assert {:ok, "message1"} = MessageQueue.dequeue(queue)
      assert {:ok, "message2"} = MessageQueue.dequeue(queue)
      assert {:error, :empty} = MessageQueue.dequeue(queue)
    end

    test "size returns queue length", %{queue: queue} do
      assert MessageQueue.size(queue) == 0

      MessageQueue.enqueue(queue, "msg1")
      MessageQueue.enqueue(queue, "msg2")
      MessageQueue.enqueue(queue, "msg3")

      # Wait for messages to be processed
      Process.sleep(10)

      assert MessageQueue.size(queue) == 3
    end

    test "processor is called for each message", %{queue: queue} do
      test_pid = self()

      processor = fn msg ->
        send(test_pid, {:processed, msg})
      end

      MessageQueue.register_processor(queue, processor)
      MessageQueue.start_processing(queue)
      Process.sleep(10)

      MessageQueue.enqueue(queue, "msg1")
      MessageQueue.enqueue(queue, "msg2")

      assert_receive {:processed, "msg1"}, 100
      assert_receive {:processed, "msg2"}, 100
    end

    test "stop_processing stops processing", %{queue: queue} do
      test_pid = self()

      processor = fn msg ->
        send(test_pid, {:processed, msg})
      end

      MessageQueue.register_processor(queue, processor)
      MessageQueue.start_processing(queue)
      Process.sleep(10)

      MessageQueue.stop_processing(queue)
      Process.sleep(10)

      MessageQueue.enqueue(queue, "msg1")

      refute_receive {:processed, _}, 50
    end
  end

  # ============================================================
  # WorkerPool Tests
  # ============================================================

  describe "WorkerPool" do
    setup do
      {:ok, pool} = WorkerPool.start_link(4)
      on_exit(fn -> WorkerPool.stop(pool) end)
      %{pool: pool}
    end

    test "submit executes task", %{pool: pool} do
      ref = WorkerPool.submit(pool, fn -> 1 + 1 end)

      assert_receive {:result, ^ref, 2}, 100
    end

    test "map processes all items", %{pool: pool} do
      results = WorkerPool.map(pool, [1, 2, 3, 4, 5], fn x -> x * 2 end)

      assert results == [2, 4, 6, 8, 10]
    end

    test "worker_count returns pool size", %{pool: pool} do
      assert WorkerPool.worker_count(pool) == 4
    end

    test "parallel execution", %{pool: pool} do
      # Submit tasks that take some time
      start = System.monotonic_time(:millisecond)

      results = WorkerPool.map(pool, [1, 2, 3, 4], fn x ->
        Process.sleep(50)
        x * 2
      end)

      elapsed = System.monotonic_time(:millisecond) - start

      assert results == [2, 4, 6, 8]
      # Should complete faster than sequential (4 * 50ms)
      assert elapsed < 200
    end
  end

  # ============================================================
  # Counter Tests
  # ============================================================

  describe "Counter" do
    setup do
      {:ok, counter} = Counter.start_link(0)
      on_exit(fn -> Counter.stop(counter) end)
      %{counter: counter}
    end

    test "initial value", %{counter: counter} do
      assert Counter.get(counter) == 0
    end

    test "increment", %{counter: counter} do
      Counter.increment(counter)
      assert Counter.get(counter) == 1

      Counter.increment(counter)
      assert Counter.get(counter) == 2
    end

    test "increment_by", %{counter: counter} do
      Counter.increment_by(counter, 5)
      assert Counter.get(counter) == 5
    end

    test "decrement", %{counter: counter} do
      Counter.increment_by(counter, 10)
      Counter.decrement(counter)

      assert Counter.get(counter) == 9
    end

    test "reset", %{counter: counter} do
      Counter.increment_by(counter, 100)
      Counter.reset(counter)

      assert Counter.get(counter) == 0
    end

    test "get_and_increment", %{counter: counter} do
      assert Counter.get_and_increment(counter) == 0
      assert Counter.get_and_increment(counter) == 1
      assert Counter.get_and_increment(counter) == 2
      assert Counter.get(counter) == 3
    end

    test "concurrent increments", %{counter: counter} do
      tasks = for _ <- 1..100 do
        Task.async(fn -> Counter.increment(counter) end)
      end

      Enum.each(tasks, &Task.await/1)

      assert Counter.get(counter) == 100
    end
  end

  # ============================================================
  # Integration Tests
  # ============================================================

  describe "Integration" do
    test "event bus with state machine" do
      {:ok, bus} = EventBus.start_link()
      {:ok, caller} = StateMachine.start_link("Alice")
      {:ok, callee} = StateMachine.start_link("Bob")

      # Subscribe to call events
      call_handler = fn event ->
        if event.data.type == :incoming do
          StateMachine.send_event(callee, :ring, %{peer: event.data.caller})
        end
      end

      EventBus.subscribe(bus, :call, call_handler)
      Process.sleep(10)

      # Initiate call via event bus
      StateMachine.send_event(caller, :call, %{peer: "Bob"})
      EventBus.publish(bus, :call, %{type: :incoming, caller: "Alice"})
      Process.sleep(50)

      assert StateMachine.get_state(caller) == :calling
      assert StateMachine.get_state(callee) == :waiting_for_connection

      EventBus.stop(bus)
      StateMachine.stop(caller)
      StateMachine.stop(callee)
    end

    test "message queue with counter" do
      {:ok, queue} = MessageQueue.start_link()
      {:ok, counter} = Counter.start_link(0)

      processor = fn _msg ->
        Counter.increment(counter)
      end

      MessageQueue.register_processor(queue, processor)
      MessageQueue.start_processing(queue)
      Process.sleep(10)

      # Enqueue multiple messages
      for i <- 1..10 do
        MessageQueue.enqueue(queue, {:message, i})
      end

      # Wait for processing
      Process.sleep(100)

      assert Counter.get(counter) == 10

      MessageQueue.stop(queue)
      Counter.stop(counter)
    end
  end
end
