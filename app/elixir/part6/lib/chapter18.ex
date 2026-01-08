defmodule Chapter18 do
  @moduledoc """
  # Chapter 18: 並行処理システム

  Elixir のプロセスと Agent を使った並行処理システムを実装します。
  イベント駆動アーキテクチャと状態機械パターンを活用します。

  ## 主なトピック

  1. イベントバス（購読/発行パターン）
  2. 状態機械（電話通話システム）
  3. アクター間通信
  """

  # ============================================================
  # 1. イベントバス
  # ============================================================

  defmodule EventBus do
    @moduledoc "イベントバス（Pub/Sub パターン）"

    use GenServer

    defstruct subscribers: %{}, event_log: []

    # Client API

    @doc "イベントバスを開始"
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, %__MODULE__{}, opts)
    end

    @doc "イベントバスを停止"
    def stop(bus) do
      if Process.alive?(bus) do
        GenServer.stop(bus)
      else
        :ok
      end
    end

    @doc "イベントを購読"
    def subscribe(bus, event_type, handler) when is_function(handler, 1) do
      GenServer.cast(bus, {:subscribe, event_type, handler})
    end

    @doc "購読を解除"
    def unsubscribe(bus, event_type, handler) do
      GenServer.cast(bus, {:unsubscribe, event_type, handler})
    end

    @doc "イベントを発行"
    def publish(bus, event_type, data) do
      GenServer.cast(bus, {:publish, event_type, data})
    end

    @doc "イベントを同期的に発行"
    def publish_sync(bus, event_type, data) do
      GenServer.call(bus, {:publish, event_type, data})
    end

    @doc "イベントログを取得"
    def get_event_log(bus) do
      GenServer.call(bus, :get_event_log)
    end

    @doc "イベントログをクリア"
    def clear_event_log(bus) do
      GenServer.cast(bus, :clear_event_log)
    end

    @doc "購読者を取得"
    def get_subscribers(bus, event_type) do
      GenServer.call(bus, {:get_subscribers, event_type})
    end

    # Server Callbacks

    @impl true
    def init(state) do
      {:ok, state}
    end

    @impl true
    def handle_cast({:subscribe, event_type, handler}, state) do
      handlers = Map.get(state.subscribers, event_type, [])
      new_subscribers = Map.put(state.subscribers, event_type, [handler | handlers])
      {:noreply, %{state | subscribers: new_subscribers}}
    end

    @impl true
    def handle_cast({:unsubscribe, event_type, handler}, state) do
      handlers = Map.get(state.subscribers, event_type, [])
      new_handlers = Enum.reject(handlers, &(&1 == handler))
      new_subscribers = Map.put(state.subscribers, event_type, new_handlers)
      {:noreply, %{state | subscribers: new_subscribers}}
    end

    @impl true
    def handle_cast({:publish, event_type, data}, state) do
      event = %{
        type: event_type,
        data: data,
        timestamp: System.system_time(:millisecond)
      }

      handlers = Map.get(state.subscribers, event_type, [])
      Enum.each(handlers, fn handler ->
        try do
          handler.(event)
        rescue
          e -> IO.puts("Handler error: #{inspect(e)}")
        end
      end)

      new_log = [event | state.event_log]
      {:noreply, %{state | event_log: new_log}}
    end

    @impl true
    def handle_cast(:clear_event_log, state) do
      {:noreply, %{state | event_log: []}}
    end

    @impl true
    def handle_call({:publish, event_type, data}, _from, state) do
      event = %{
        type: event_type,
        data: data,
        timestamp: System.system_time(:millisecond)
      }

      handlers = Map.get(state.subscribers, event_type, [])
      results = Enum.map(handlers, fn handler ->
        try do
          handler.(event)
        rescue
          e -> {:error, e}
        end
      end)

      new_log = [event | state.event_log]
      {:reply, results, %{state | event_log: new_log}}
    end

    @impl true
    def handle_call(:get_event_log, _from, state) do
      {:reply, Enum.reverse(state.event_log), state}
    end

    @impl true
    def handle_call({:get_subscribers, event_type}, _from, state) do
      {:reply, Map.get(state.subscribers, event_type, []), state}
    end
  end

  # ============================================================
  # 2. 状態機械
  # ============================================================

  defmodule StateMachine do
    @moduledoc "状態機械（電話通話システム）"

    use GenServer

    @user_states %{
      idle: %{
        call: {:calling, :caller_off_hook},
        ring: {:waiting_for_connection, :callee_off_hook},
        disconnect: {:idle, nil}
      },
      calling: %{
        dialtone: {:dialing, :dial}
      },
      dialing: %{
        ringback: {:waiting_for_connection, nil}
      },
      waiting_for_connection: %{
        connected: {:talking, :talk}
      },
      talking: %{
        disconnect: {:idle, nil}
      }
    }

    defstruct [:user_id, :state, :peer, :action_log]

    # Client API

    @doc "ユーザーエージェントを作成"
    def start_link(user_id, opts \\ []) do
      GenServer.start_link(__MODULE__, user_id, opts)
    end

    @doc "エージェントを停止"
    def stop(agent) do
      if Process.alive?(agent) do
        GenServer.stop(agent)
      else
        :ok
      end
    end

    @doc "現在の状態を取得"
    def get_state(agent) do
      GenServer.call(agent, :get_state)
    end

    @doc "ユーザーIDを取得"
    def get_user_id(agent) do
      GenServer.call(agent, :get_user_id)
    end

    @doc "アクションログを取得"
    def get_action_log(agent) do
      GenServer.call(agent, :get_action_log)
    end

    @doc "イベントを送信"
    def send_event(agent, event, event_data \\ %{}) do
      GenServer.cast(agent, {:event, event, event_data})
    end

    @doc "状態をリセット"
    def reset(agent) do
      GenServer.cast(agent, :reset)
    end

    # Server Callbacks

    @impl true
    def init(user_id) do
      state = %__MODULE__{
        user_id: user_id,
        state: :idle,
        peer: nil,
        action_log: []
      }
      {:ok, state}
    end

    @impl true
    def handle_call(:get_state, _from, state) do
      {:reply, state.state, state}
    end

    @impl true
    def handle_call(:get_user_id, _from, state) do
      {:reply, state.user_id, state}
    end

    @impl true
    def handle_call(:get_action_log, _from, state) do
      {:reply, Enum.reverse(state.action_log), state}
    end

    @impl true
    def handle_cast({:event, event, event_data}, state) do
      case get_transition(state.state, event) do
        nil ->
          log_entry = {:invalid_transition, state.state, event}
          new_state = %{state | action_log: [log_entry | state.action_log]}
          {:noreply, new_state}

        {next_state, action_key} ->
          peer = Map.get(event_data, :peer, state.peer)
          action_result = execute_action(action_key, state.user_id, peer)

          log_entry = {state.state, event, next_state, action_result}
          new_state = %{state |
            state: next_state,
            peer: peer,
            action_log: [log_entry | state.action_log]
          }
          {:noreply, new_state}
      end
    end

    @impl true
    def handle_cast(:reset, state) do
      {:noreply, %{state | state: :idle, peer: nil, action_log: []}}
    end

    # Private functions

    defp get_transition(current_state, event) do
      @user_states
      |> Map.get(current_state, %{})
      |> Map.get(event)
    end

    defp execute_action(nil, _from_user, _to_user), do: nil
    defp execute_action(:caller_off_hook, from_user, to_user) do
      "#{from_user} picked up the phone to call #{to_user}"
    end
    defp execute_action(:callee_off_hook, from_user, to_user) do
      "#{from_user} answered the call from #{to_user}"
    end
    defp execute_action(:dial, from_user, to_user) do
      "#{from_user} is dialing #{to_user}"
    end
    defp execute_action(:talk, from_user, to_user) do
      "#{from_user} is now talking with #{to_user}"
    end
  end

  # ============================================================
  # 3. 電話システム
  # ============================================================

  defmodule PhoneSystem do
    @moduledoc "電話通話システム"

    alias Chapter18.StateMachine

    @doc "電話をかける"
    def make_call(caller, callee) do
      callee_id = StateMachine.get_user_id(callee)
      caller_id = StateMachine.get_user_id(caller)

      StateMachine.send_event(caller, :call, %{peer: callee_id})
      StateMachine.send_event(callee, :ring, %{peer: caller_id})

      # 少し待機してイベントが処理されるのを待つ
      Process.sleep(10)
    end

    @doc "ダイヤルトーンを受信して発信"
    def dial(caller) do
      StateMachine.send_event(caller, :dialtone)
      Process.sleep(10)
    end

    @doc "呼び出し音"
    def ringback(caller) do
      StateMachine.send_event(caller, :ringback)
      Process.sleep(10)
    end

    @doc "通話開始"
    def connect(caller, callee) do
      StateMachine.send_event(caller, :connected)
      StateMachine.send_event(callee, :connected)
      Process.sleep(10)
    end

    @doc "電話に出る（完全なシーケンス）"
    def answer_call(caller, callee) do
      dial(caller)
      ringback(caller)
      connect(caller, callee)
    end

    @doc "電話を切る"
    def hang_up(caller, callee) do
      StateMachine.send_event(caller, :disconnect)
      StateMachine.send_event(callee, :disconnect)
      Process.sleep(10)
    end

    @doc "完全な通話シーケンス"
    def complete_call(caller, callee) do
      make_call(caller, callee)
      answer_call(caller, callee)
    end
  end

  # ============================================================
  # 4. メッセージキュー
  # ============================================================

  defmodule MessageQueue do
    @moduledoc "メッセージキュー"

    use GenServer

    defstruct queue: :queue.new(), processors: [], processing: false

    # Client API

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, %__MODULE__{}, opts)
    end

    def stop(queue) do
      if Process.alive?(queue) do
        GenServer.stop(queue)
      else
        :ok
      end
    end

    @doc "メッセージをエンキュー"
    def enqueue(queue, message) do
      GenServer.cast(queue, {:enqueue, message})
    end

    @doc "メッセージをデキュー"
    def dequeue(queue) do
      GenServer.call(queue, :dequeue)
    end

    @doc "プロセッサを登録"
    def register_processor(queue, processor) when is_function(processor, 1) do
      GenServer.cast(queue, {:register_processor, processor})
    end

    @doc "処理を開始"
    def start_processing(queue) do
      GenServer.cast(queue, :start_processing)
    end

    @doc "処理を停止"
    def stop_processing(queue) do
      GenServer.cast(queue, :stop_processing)
    end

    @doc "キューのサイズを取得"
    def size(queue) do
      GenServer.call(queue, :size)
    end

    # Server Callbacks

    @impl true
    def init(state) do
      {:ok, state}
    end

    @impl true
    def handle_cast({:enqueue, message}, state) do
      new_queue = :queue.in(message, state.queue)
      new_state = %{state | queue: new_queue}

      if state.processing do
        send(self(), :process_next)
      end

      {:noreply, new_state}
    end

    @impl true
    def handle_cast({:register_processor, processor}, state) do
      {:noreply, %{state | processors: [processor | state.processors]}}
    end

    @impl true
    def handle_cast(:start_processing, state) do
      send(self(), :process_next)
      {:noreply, %{state | processing: true}}
    end

    @impl true
    def handle_cast(:stop_processing, state) do
      {:noreply, %{state | processing: false}}
    end

    @impl true
    def handle_call(:dequeue, _from, state) do
      case :queue.out(state.queue) do
        {:empty, _} ->
          {:reply, {:error, :empty}, state}
        {{:value, message}, new_queue} ->
          {:reply, {:ok, message}, %{state | queue: new_queue}}
      end
    end

    @impl true
    def handle_call(:size, _from, state) do
      {:reply, :queue.len(state.queue), state}
    end

    @impl true
    def handle_info(:process_next, state) do
      if state.processing do
        case :queue.out(state.queue) do
          {:empty, _} ->
            {:noreply, state}
          {{:value, message}, new_queue} ->
            Enum.each(state.processors, fn processor ->
              try do
                processor.(message)
              rescue
                _ -> :error
              end
            end)

            if not :queue.is_empty(new_queue) do
              send(self(), :process_next)
            end

            {:noreply, %{state | queue: new_queue}}
        end
      else
        {:noreply, state}
      end
    end
  end

  # ============================================================
  # 5. ワーカープール
  # ============================================================

  defmodule WorkerPool do
    @moduledoc "ワーカープール"

    use GenServer

    defstruct [:size, :workers, :task_queue, :results]

    # Client API

    def start_link(size, opts \\ []) do
      GenServer.start_link(__MODULE__, size, opts)
    end

    def stop(pool) do
      if Process.alive?(pool) do
        GenServer.stop(pool)
      else
        :ok
      end
    end

    @doc "タスクを送信"
    def submit(pool, task) when is_function(task, 0) do
      GenServer.call(pool, {:submit, task})
    end

    @doc "全タスクを送信して結果を待つ"
    def map(pool, items, func) do
      refs = Enum.map(items, fn item ->
        submit(pool, fn -> func.(item) end)
      end)

      Enum.map(refs, fn ref ->
        receive do
          {:result, ^ref, result} -> result
        after
          5000 -> {:error, :timeout}
        end
      end)
    end

    @doc "ワーカー数を取得"
    def worker_count(pool) do
      GenServer.call(pool, :worker_count)
    end

    # Server Callbacks

    @impl true
    def init(size) do
      state = %__MODULE__{
        size: size,
        workers: [],
        task_queue: :queue.new(),
        results: %{}
      }
      {:ok, state}
    end

    @impl true
    def handle_call({:submit, task}, {from_pid, _}, state) do
      ref = make_ref()
      task_entry = {ref, from_pid, task}

      # タスクを即座に実行（シンプルな実装）
      spawn(fn ->
        result = task.()
        send(from_pid, {:result, ref, result})
      end)

      {:reply, ref, state}
    end

    @impl true
    def handle_call(:worker_count, _from, state) do
      {:reply, state.size, state}
    end
  end

  # ============================================================
  # 6. 並行カウンター（Agent ベース）
  # ============================================================

  defmodule Counter do
    @moduledoc "並行安全なカウンター"

    def start_link(initial_value \\ 0) do
      Agent.start_link(fn -> initial_value end)
    end

    def stop(counter) do
      if Process.alive?(counter) do
        Agent.stop(counter)
      else
        :ok
      end
    end

    def get(counter) do
      Agent.get(counter, & &1)
    end

    def increment(counter) do
      Agent.update(counter, &(&1 + 1))
    end

    def increment_by(counter, n) do
      Agent.update(counter, &(&1 + n))
    end

    def decrement(counter) do
      Agent.update(counter, &(&1 - 1))
    end

    def reset(counter) do
      Agent.update(counter, fn _ -> 0 end)
    end

    @doc "アトミックな get と update"
    def get_and_increment(counter) do
      Agent.get_and_update(counter, fn value ->
        {value, value + 1}
      end)
    end
  end
end
