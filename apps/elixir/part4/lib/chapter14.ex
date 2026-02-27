defmodule Chapter14 do
  @moduledoc """
  # Chapter 14: Abstract Server パターン

  Abstract Server パターンは、依存関係逆転の原則（DIP）を実現するパターンです。
  高レベルモジュールが低レベルモジュールの詳細に依存するのではなく、
  両者が抽象に依存することで疎結合を実現します。

  ## 主なトピック

  1. Switchable プロトコル（スイッチとデバイス）
  2. Repository プロトコル（データアクセス抽象化）
  3. Logger プロトコル（ログ出力抽象化）
  4. Notifier プロトコル（通知抽象化）
  5. Service Layer パターン
  """

  # ============================================================
  # 1. Switchable パターン
  # ============================================================

  defprotocol Switchable do
    @moduledoc "スイッチ可能なデバイスのプロトコル"

    @doc "デバイスをオンにする"
    @spec turn_on(t()) :: t()
    def turn_on(device)

    @doc "デバイスをオフにする"
    @spec turn_off(t()) :: t()
    def turn_off(device)

    @doc "デバイスがオンかどうか"
    @spec on?(t()) :: boolean()
    def on?(device)
  end

  # Concrete Server: Light
  defmodule Light do
    @moduledoc "照明デバイス"
    defstruct state: :off, brightness: 100

    @type t :: %__MODULE__{
      state: :on | :off,
      brightness: 0..100
    }

    def new, do: %__MODULE__{}
    def new(brightness), do: %__MODULE__{brightness: brightness}

    def set_brightness(%__MODULE__{state: :on} = light, brightness)
        when brightness >= 0 and brightness <= 100 do
      %{light | brightness: brightness}
    end
    def set_brightness(light, _), do: light
  end

  defimpl Switchable, for: Light do
    def turn_on(%Light{} = light), do: %{light | state: :on}
    def turn_off(%Light{} = light), do: %{light | state: :off}
    def on?(%Light{state: state}), do: state == :on
  end

  # Concrete Server: Fan
  defmodule Fan do
    @moduledoc "扇風機デバイス"
    defstruct state: :off, speed: nil

    @type t :: %__MODULE__{
      state: :on | :off,
      speed: :low | :medium | :high | nil
    }

    def new, do: %__MODULE__{}

    def set_speed(%__MODULE__{state: :on} = fan, speed)
        when speed in [:low, :medium, :high] do
      %{fan | speed: speed}
    end
    def set_speed(fan, _), do: fan
  end

  defimpl Switchable, for: Fan do
    def turn_on(%Fan{} = fan), do: %{fan | state: :on, speed: :low}
    def turn_off(%Fan{} = fan), do: %{fan | state: :off, speed: nil}
    def on?(%Fan{state: state}), do: state == :on
  end

  # Concrete Server: Motor
  defmodule Motor do
    @moduledoc "モーターデバイス"
    defstruct state: :off, direction: nil, rpm: 0

    @type t :: %__MODULE__{
      state: :on | :off,
      direction: :forward | :reverse | nil,
      rpm: non_neg_integer()
    }

    def new, do: %__MODULE__{}

    def reverse(%__MODULE__{state: :on, direction: dir} = motor) do
      new_dir = if dir == :forward, do: :reverse, else: :forward
      %{motor | direction: new_dir}
    end
    def reverse(motor), do: motor

    def set_rpm(%__MODULE__{state: :on} = motor, rpm) when rpm >= 0 do
      %{motor | rpm: rpm}
    end
    def set_rpm(motor, _), do: motor
  end

  defimpl Switchable, for: Motor do
    def turn_on(%Motor{} = motor), do: %{motor | state: :on, direction: :forward, rpm: 1000}
    def turn_off(%Motor{} = motor), do: %{motor | state: :off, direction: nil, rpm: 0}
    def on?(%Motor{state: state}), do: state == :on
  end

  # Client: Switch
  defmodule Switch do
    @moduledoc """
    スイッチクライアント。
    Switchable プロトコルを通じてデバイスを操作する。
    """

    @doc "スイッチを入れる"
    def engage(device), do: Switchable.turn_on(device)

    @doc "スイッチを切る"
    def disengage(device), do: Switchable.turn_off(device)

    @doc "スイッチを切り替える"
    def toggle(device) do
      if Switchable.on?(device) do
        Switchable.turn_off(device)
      else
        Switchable.turn_on(device)
      end
    end

    @doc "デバイスの状態を取得"
    def status(device), do: if(Switchable.on?(device), do: :on, else: :off)
  end

  # ============================================================
  # 2. Repository パターン
  # ============================================================

  defprotocol Repository do
    @moduledoc "データリポジトリのプロトコル"

    @doc "IDでエンティティを取得"
    @spec find_by_id(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
    def find_by_id(repo, id)

    @doc "全てのエンティティを取得"
    @spec find_all(t()) :: [map()]
    def find_all(repo)

    @doc "エンティティを保存"
    @spec save(t(), map()) :: {:ok, map()}
    def save(repo, entity)

    @doc "エンティティを削除"
    @spec delete(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
    def delete(repo, id)
  end

  # Concrete Server: MemoryRepository
  defmodule MemoryRepository do
    @moduledoc "インメモリリポジトリ"

    defstruct [:agent]

    def new do
      {:ok, agent} = Agent.start_link(fn -> %{} end)
      %__MODULE__{agent: agent}
    end

    def stop(%__MODULE__{agent: agent}) do
      if Process.alive?(agent) do
        Agent.stop(agent)
      else
        :ok
      end
    end
  end

  defimpl Repository, for: MemoryRepository do
    def find_by_id(%MemoryRepository{agent: agent}, id) do
      case Agent.get(agent, &Map.get(&1, id)) do
        nil -> {:error, :not_found}
        entity -> {:ok, entity}
      end
    end

    def find_all(%MemoryRepository{agent: agent}) do
      Agent.get(agent, &Map.values(&1))
    end

    def save(%MemoryRepository{agent: agent}, entity) do
      id = Map.get(entity, :id) || generate_id()
      entity_with_id = Map.put(entity, :id, id)
      Agent.update(agent, &Map.put(&1, id, entity_with_id))
      {:ok, entity_with_id}
    end

    def delete(%MemoryRepository{agent: agent}, id) do
      case Agent.get(agent, &Map.get(&1, id)) do
        nil ->
          {:error, :not_found}
        entity ->
          Agent.update(agent, &Map.delete(&1, id))
          {:ok, entity}
      end
    end

    defp generate_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  # Concrete Server: MockRepository (for testing)
  defmodule MockRepository do
    @moduledoc "モックリポジトリ（テスト用）"

    defstruct data: %{}, calls: []

    def new(data \\ %{}), do: %__MODULE__{data: data}

    def get_calls(%__MODULE__{calls: calls}), do: Enum.reverse(calls)
  end

  defimpl Repository, for: MockRepository do
    def find_by_id(%MockRepository{data: data} = _repo, id) do
      # Note: In a real mock, we'd track calls but since structs are immutable,
      # we'd need to use Agent or return updated repo
      case Map.get(data, id) do
        nil -> {:error, :not_found}
        entity -> {:ok, entity}
      end
    end

    def find_all(%MockRepository{data: data}) do
      Map.values(data)
    end

    def save(%MockRepository{data: _data} = _repo, entity) do
      id = Map.get(entity, :id) || "mock-id"
      entity_with_id = Map.put(entity, :id, id)
      # Note: Mock doesn't actually persist, just returns result
      {:ok, entity_with_id}
    end

    def delete(%MockRepository{data: data} = _repo, id) do
      case Map.get(data, id) do
        nil -> {:error, :not_found}
        entity -> {:ok, entity}
      end
    end
  end

  # ============================================================
  # 3. Logger パターン
  # ============================================================

  defprotocol Logger do
    @moduledoc "ロガーのプロトコル"

    @doc "デバッグログ"
    @spec debug(t(), String.t()) :: t()
    def debug(logger, message)

    @doc "情報ログ"
    @spec info(t(), String.t()) :: t()
    def info(logger, message)

    @doc "警告ログ"
    @spec warn(t(), String.t()) :: t()
    def warn(logger, message)

    @doc "エラーログ"
    @spec error(t(), String.t()) :: t()
    def error(logger, message)
  end

  # Concrete Server: ConsoleLogger
  defmodule ConsoleLogger do
    @moduledoc "コンソールロガー"
    defstruct level: :debug

    @levels [:debug, :info, :warn, :error]

    def new(level \\ :debug), do: %__MODULE__{level: level}

    def should_log?(%__MODULE__{level: min_level}, level) do
      min_idx = Enum.find_index(@levels, &(&1 == min_level))
      level_idx = Enum.find_index(@levels, &(&1 == level))
      level_idx >= min_idx
    end
  end

  defimpl Logger, for: ConsoleLogger do
    def debug(logger, message) do
      if ConsoleLogger.should_log?(logger, :debug) do
        IO.puts("[DEBUG] #{message}")
      end
      logger
    end

    def info(logger, message) do
      if ConsoleLogger.should_log?(logger, :info) do
        IO.puts("[INFO] #{message}")
      end
      logger
    end

    def warn(logger, message) do
      if ConsoleLogger.should_log?(logger, :warn) do
        IO.puts("[WARN] #{message}")
      end
      logger
    end

    def error(logger, message) do
      if ConsoleLogger.should_log?(logger, :error) do
        IO.puts("[ERROR] #{message}")
      end
      logger
    end
  end

  # Concrete Server: MemoryLogger (for testing)
  defmodule MemoryLogger do
    @moduledoc "メモリロガー（テスト用）"
    defstruct entries: []

    def new, do: %__MODULE__{}

    def get_entries(%__MODULE__{entries: entries}), do: Enum.reverse(entries)

    def clear(%__MODULE__{}), do: %__MODULE__{}
  end

  defimpl Logger, for: MemoryLogger do
    def debug(%MemoryLogger{entries: entries} = logger, message) do
      %{logger | entries: [{:debug, message} | entries]}
    end

    def info(%MemoryLogger{entries: entries} = logger, message) do
      %{logger | entries: [{:info, message} | entries]}
    end

    def warn(%MemoryLogger{entries: entries} = logger, message) do
      %{logger | entries: [{:warn, message} | entries]}
    end

    def error(%MemoryLogger{entries: entries} = logger, message) do
      %{logger | entries: [{:error, message} | entries]}
    end
  end

  # ============================================================
  # 4. Notifier パターン
  # ============================================================

  defprotocol Notifier do
    @moduledoc "通知のプロトコル"

    @doc "通知を送信"
    @spec notify(t(), String.t(), String.t()) :: {:ok, t()} | {:error, term()}
    def notify(notifier, recipient, message)
  end

  # Concrete Server: EmailNotifier
  defmodule EmailNotifier do
    @moduledoc "メール通知"
    defstruct from: "noreply@example.com", sent: []

    def new(from \\ "noreply@example.com"), do: %__MODULE__{from: from}

    def get_sent(%__MODULE__{sent: sent}), do: Enum.reverse(sent)
  end

  defimpl Notifier, for: EmailNotifier do
    def notify(%EmailNotifier{from: from, sent: sent} = notifier, recipient, message) do
      email = %{from: from, to: recipient, subject: "Notification", body: message}
      {:ok, %{notifier | sent: [email | sent]}}
    end
  end

  # Concrete Server: SMSNotifier
  defmodule SMSNotifier do
    @moduledoc "SMS通知"
    defstruct sender: "+1234567890", sent: []

    def new(sender \\ "+1234567890"), do: %__MODULE__{sender: sender}

    def get_sent(%__MODULE__{sent: sent}), do: Enum.reverse(sent)
  end

  defimpl Notifier, for: SMSNotifier do
    def notify(%SMSNotifier{sender: sender, sent: sent} = notifier, recipient, message) do
      # SMS has character limit
      truncated = String.slice(message, 0, 160)
      sms = %{from: sender, to: recipient, body: truncated}
      {:ok, %{notifier | sent: [sms | sent]}}
    end
  end

  # Concrete Server: PushNotifier
  defmodule PushNotifier do
    @moduledoc "プッシュ通知"
    defstruct app_id: "default", sent: []

    def new(app_id \\ "default"), do: %__MODULE__{app_id: app_id}

    def get_sent(%__MODULE__{sent: sent}), do: Enum.reverse(sent)
  end

  defimpl Notifier, for: PushNotifier do
    def notify(%PushNotifier{app_id: app_id, sent: sent} = notifier, recipient, message) do
      push = %{app_id: app_id, device_token: recipient, body: message}
      {:ok, %{notifier | sent: [push | sent]}}
    end
  end

  # CompositeNotifier
  defmodule CompositeNotifier do
    @moduledoc "複合通知（複数チャネルに同時送信）"
    defstruct notifiers: []

    def new(notifiers), do: %__MODULE__{notifiers: notifiers}

    def add(%__MODULE__{notifiers: ns} = cn, notifier) do
      %{cn | notifiers: ns ++ [notifier]}
    end
  end

  defimpl Notifier, for: CompositeNotifier do
    def notify(%CompositeNotifier{notifiers: notifiers} = composite, recipient, message) do
      updated_notifiers = Enum.map(notifiers, fn n ->
        case Chapter14.Notifier.notify(n, recipient, message) do
          {:ok, updated} -> updated
          {:error, _} -> n
        end
      end)
      {:ok, %{composite | notifiers: updated_notifiers}}
    end
  end

  # ============================================================
  # 5. Service Layer
  # ============================================================

  defmodule UserService do
    @moduledoc """
    ユーザーサービス。
    Repository と Logger に依存するが、具体的な実装は知らない。
    """

    defstruct [:repo, :logger]

    def new(repo, logger), do: %__MODULE__{repo: repo, logger: logger}

    @doc "ユーザーを作成"
    def create_user(%__MODULE__{repo: repo, logger: logger} = service, name, email) do
      logger = Logger.info(logger, "Creating user: #{name}")
      user = %{name: name, email: email, created_at: DateTime.utc_now()}

      case Repository.save(repo, user) do
        {:ok, saved} ->
          Logger.info(logger, "User created: #{saved.id}")
          {:ok, saved, %{service | logger: logger}}
        error ->
          Logger.error(logger, "Failed to create user: #{inspect(error)}")
          error
      end
    end

    @doc "ユーザーを取得"
    def get_user(%__MODULE__{repo: repo, logger: logger} = service, id) do
      logger = Logger.debug(logger, "Getting user: #{id}")

      case Repository.find_by_id(repo, id) do
        {:ok, user} ->
          {:ok, user, %{service | logger: logger}}
        {:error, :not_found} = error ->
          Logger.warn(logger, "User not found: #{id}")
          error
      end
    end

    @doc "全ユーザーを取得"
    def get_all_users(%__MODULE__{repo: repo, logger: logger} = service) do
      logger = Logger.debug(logger, "Getting all users")
      users = Repository.find_all(repo)
      {:ok, users, %{service | logger: logger}}
    end

    @doc "ユーザーを削除"
    def delete_user(%__MODULE__{repo: repo, logger: logger} = service, id) do
      logger = Logger.info(logger, "Deleting user: #{id}")

      case Repository.delete(repo, id) do
        {:ok, deleted} ->
          Logger.info(logger, "User deleted: #{id}")
          {:ok, deleted, %{service | logger: logger}}
        {:error, :not_found} = error ->
          Logger.warn(logger, "User not found for deletion: #{id}")
          error
      end
    end
  end

  # ============================================================
  # 6. Notification Service
  # ============================================================

  defmodule NotificationService do
    @moduledoc """
    通知サービス。
    Notifier と Logger に依存する。
    """

    defstruct [:notifier, :logger]

    def new(notifier, logger), do: %__MODULE__{notifier: notifier, logger: logger}

    @doc "ユーザーに通知を送信"
    def notify_user(%__MODULE__{notifier: notifier, logger: logger} = service, user, message) do
      recipient = Map.get(user, :email) || Map.get(user, :phone) || Map.get(user, :device_token)
      logger = Logger.info(logger, "Sending notification to: #{recipient}")

      case Notifier.notify(notifier, recipient, message) do
        {:ok, updated_notifier} ->
          logger = Logger.info(logger, "Notification sent successfully")
          {:ok, %{service | notifier: updated_notifier, logger: logger}}
        {:error, reason} = error ->
          Logger.error(logger, "Failed to send notification: #{inspect(reason)}")
          error
      end
    end

    @doc "複数ユーザーに通知を送信"
    def broadcast(%__MODULE__{} = service, users, message) do
      Enum.reduce(users, {:ok, service}, fn user, acc ->
        case acc do
          {:ok, srv} -> notify_user(srv, user, message)
          error -> error
        end
      end)
    end
  end

  # ============================================================
  # 7. Dependency Injection Container
  # ============================================================

  defmodule Container do
    @moduledoc """
    依存性注入コンテナ。
    Abstract Server の具体的な実装を管理する。
    """

    defstruct services: %{}

    def new, do: %__MODULE__{}

    @doc "サービスを登録"
    def register(%__MODULE__{services: services} = container, key, service) do
      %{container | services: Map.put(services, key, service)}
    end

    @doc "サービスを取得"
    def resolve(%__MODULE__{services: services}, key) do
      case Map.get(services, key) do
        nil -> {:error, {:not_found, key}}
        service -> {:ok, service}
      end
    end

    @doc "サービスを取得（存在しない場合はエラー）"
    def resolve!(%__MODULE__{} = container, key) do
      case resolve(container, key) do
        {:ok, service} -> service
        {:error, _} -> raise "Service not found: #{inspect(key)}"
      end
    end

    @doc "ファクトリ関数でサービスを登録"
    def register_factory(%__MODULE__{services: services} = container, key, factory)
        when is_function(factory, 1) do
      %{container | services: Map.put(services, key, {:factory, factory})}
    end

    @doc "ファクトリを考慮してサービスを解決"
    def resolve_with_factory(%__MODULE__{services: services} = container, key) do
      case Map.get(services, key) do
        nil -> {:error, {:not_found, key}}
        {:factory, factory} -> {:ok, factory.(container)}
        service -> {:ok, service}
      end
    end
  end

  # ============================================================
  # 8. Example: Complete System
  # ============================================================

  defmodule Application do
    @moduledoc """
    アプリケーションのセットアップ例。
    """

    @doc "開発環境用のコンテナを作成"
    def development_container do
      Container.new()
      |> Container.register(:repository, MemoryRepository.new())
      |> Container.register(:logger, ConsoleLogger.new(:debug))
      |> Container.register(:notifier, EmailNotifier.new("dev@example.com"))
      |> Container.register_factory(:user_service, fn container ->
        repo = Container.resolve!(container, :repository)
        logger = Container.resolve!(container, :logger)
        UserService.new(repo, logger)
      end)
      |> Container.register_factory(:notification_service, fn container ->
        notifier = Container.resolve!(container, :notifier)
        logger = Container.resolve!(container, :logger)
        NotificationService.new(notifier, logger)
      end)
    end

    @doc "テスト環境用のコンテナを作成"
    def test_container do
      Container.new()
      |> Container.register(:repository, MockRepository.new())
      |> Container.register(:logger, MemoryLogger.new())
      |> Container.register(:notifier, EmailNotifier.new("test@example.com"))
      |> Container.register_factory(:user_service, fn container ->
        repo = Container.resolve!(container, :repository)
        logger = Container.resolve!(container, :logger)
        UserService.new(repo, logger)
      end)
    end
  end
end
