defmodule Chapter14Test do
  # Not async due to shared Agent state in MemoryRepository
  use ExUnit.Case, async: false

  alias Chapter14.{Switchable, Switch, Light, Fan, Motor}
  alias Chapter14.{Repository, MemoryRepository, MockRepository}
  alias Chapter14.{Logger, ConsoleLogger, MemoryLogger}
  alias Chapter14.{Notifier, EmailNotifier, SMSNotifier, PushNotifier, CompositeNotifier}
  alias Chapter14.{UserService, NotificationService, Container, Application}

  # ============================================================
  # 1. Switchable パターンのテスト
  # ============================================================

  describe "Light" do
    test "creates off by default" do
      light = Light.new()
      assert light.state == :off
      assert Switchable.on?(light) == false
    end

    test "turn_on turns on the light" do
      light = Light.new() |> Switchable.turn_on()
      assert light.state == :on
      assert Switchable.on?(light) == true
    end

    test "turn_off turns off the light" do
      light = Light.new() |> Switchable.turn_on() |> Switchable.turn_off()
      assert light.state == :off
      assert Switchable.on?(light) == false
    end

    test "set_brightness works when on" do
      light = Light.new() |> Switchable.turn_on() |> Light.set_brightness(50)
      assert light.brightness == 50
    end

    test "set_brightness does nothing when off" do
      light = Light.new() |> Light.set_brightness(50)
      assert light.brightness == 100  # default
    end
  end

  describe "Fan" do
    test "creates off by default" do
      fan = Fan.new()
      assert fan.state == :off
      assert fan.speed == nil
    end

    test "turn_on sets default speed" do
      fan = Fan.new() |> Switchable.turn_on()
      assert fan.state == :on
      assert fan.speed == :low
    end

    test "turn_off clears speed" do
      fan = Fan.new() |> Switchable.turn_on() |> Switchable.turn_off()
      assert fan.state == :off
      assert fan.speed == nil
    end

    test "set_speed changes speed when on" do
      fan = Fan.new() |> Switchable.turn_on() |> Fan.set_speed(:high)
      assert fan.speed == :high
    end

    test "set_speed does nothing when off" do
      fan = Fan.new() |> Fan.set_speed(:high)
      assert fan.speed == nil
    end
  end

  describe "Motor" do
    test "creates off by default" do
      motor = Motor.new()
      assert motor.state == :off
      assert motor.direction == nil
      assert motor.rpm == 0
    end

    test "turn_on sets default direction and rpm" do
      motor = Motor.new() |> Switchable.turn_on()
      assert motor.state == :on
      assert motor.direction == :forward
      assert motor.rpm == 1000
    end

    test "reverse changes direction when on" do
      motor = Motor.new() |> Switchable.turn_on() |> Motor.reverse()
      assert motor.direction == :reverse

      motor = Motor.reverse(motor)
      assert motor.direction == :forward
    end

    test "reverse does nothing when off" do
      motor = Motor.new() |> Motor.reverse()
      assert motor.direction == nil
    end

    test "set_rpm changes rpm when on" do
      motor = Motor.new() |> Switchable.turn_on() |> Motor.set_rpm(2000)
      assert motor.rpm == 2000
    end
  end

  describe "Switch (Client)" do
    test "engage turns on device" do
      light = Light.new() |> Switch.engage()
      assert Switch.status(light) == :on
    end

    test "disengage turns off device" do
      light = Light.new() |> Switch.engage() |> Switch.disengage()
      assert Switch.status(light) == :off
    end

    test "toggle switches state" do
      light = Light.new()
      assert Switch.status(light) == :off

      light = Switch.toggle(light)
      assert Switch.status(light) == :on

      light = Switch.toggle(light)
      assert Switch.status(light) == :off
    end

    test "works with different devices" do
      light = Light.new() |> Switch.engage()
      fan = Fan.new() |> Switch.engage()
      motor = Motor.new() |> Switch.engage()

      assert Switch.status(light) == :on
      assert Switch.status(fan) == :on
      assert Switch.status(motor) == :on
    end
  end

  # ============================================================
  # 2. Repository パターンのテスト
  # ============================================================

  describe "MemoryRepository" do
    setup do
      repo = MemoryRepository.new()
      on_exit(fn -> MemoryRepository.stop(repo) end)
      {:ok, repo: repo}
    end

    test "saves and finds entity", %{repo: repo} do
      entity = %{name: "Test"}
      {:ok, saved} = Repository.save(repo, entity)
      assert saved.id != nil

      {:ok, found} = Repository.find_by_id(repo, saved.id)
      assert found.name == "Test"
    end

    test "find_by_id returns error for missing", %{repo: repo} do
      assert {:error, :not_found} = Repository.find_by_id(repo, "nonexistent")
    end

    test "find_all returns all entities", %{repo: repo} do
      Repository.save(repo, %{name: "A"})
      Repository.save(repo, %{name: "B"})

      all = Repository.find_all(repo)
      assert length(all) == 2
    end

    test "delete removes entity", %{repo: repo} do
      {:ok, saved} = Repository.save(repo, %{name: "Test"})
      {:ok, deleted} = Repository.delete(repo, saved.id)
      assert deleted.name == "Test"

      assert {:error, :not_found} = Repository.find_by_id(repo, saved.id)
    end

    test "delete returns error for missing", %{repo: repo} do
      assert {:error, :not_found} = Repository.delete(repo, "nonexistent")
    end
  end

  describe "MockRepository" do
    test "returns preconfigured data" do
      data = %{"1" => %{id: "1", name: "Test"}}
      repo = MockRepository.new(data)

      {:ok, found} = Repository.find_by_id(repo, "1")
      assert found.name == "Test"
    end

    test "find_all returns all data" do
      data = %{
        "1" => %{id: "1", name: "A"},
        "2" => %{id: "2", name: "B"}
      }
      repo = MockRepository.new(data)

      all = Repository.find_all(repo)
      assert length(all) == 2
    end
  end

  # ============================================================
  # 3. Logger パターンのテスト
  # ============================================================

  describe "ConsoleLogger" do
    test "creates with default level" do
      logger = ConsoleLogger.new()
      assert logger.level == :debug
    end

    test "should_log? respects log level" do
      logger = ConsoleLogger.new(:warn)
      refute ConsoleLogger.should_log?(logger, :debug)
      refute ConsoleLogger.should_log?(logger, :info)
      assert ConsoleLogger.should_log?(logger, :warn)
      assert ConsoleLogger.should_log?(logger, :error)
    end
  end

  describe "MemoryLogger" do
    test "logs messages" do
      logger = MemoryLogger.new()
        |> Logger.debug("Debug message")
        |> Logger.info("Info message")
        |> Logger.warn("Warn message")
        |> Logger.error("Error message")

      entries = MemoryLogger.get_entries(logger)
      assert length(entries) == 4
      assert Enum.at(entries, 0) == {:debug, "Debug message"}
      assert Enum.at(entries, 1) == {:info, "Info message"}
      assert Enum.at(entries, 2) == {:warn, "Warn message"}
      assert Enum.at(entries, 3) == {:error, "Error message"}
    end

    test "clear removes all entries" do
      logger = MemoryLogger.new()
        |> Logger.info("Message")
        |> MemoryLogger.clear()

      entries = MemoryLogger.get_entries(logger)
      assert length(entries) == 0
    end
  end

  # ============================================================
  # 4. Notifier パターンのテスト
  # ============================================================

  describe "EmailNotifier" do
    test "sends email notification" do
      notifier = EmailNotifier.new("sender@example.com")
      {:ok, notifier} = Notifier.notify(notifier, "user@example.com", "Hello!")

      sent = EmailNotifier.get_sent(notifier)
      assert length(sent) == 1
      assert hd(sent).from == "sender@example.com"
      assert hd(sent).to == "user@example.com"
      assert hd(sent).body == "Hello!"
    end
  end

  describe "SMSNotifier" do
    test "sends SMS notification" do
      notifier = SMSNotifier.new("+1234567890")
      {:ok, notifier} = Notifier.notify(notifier, "+0987654321", "Hello!")

      sent = SMSNotifier.get_sent(notifier)
      assert length(sent) == 1
      assert hd(sent).from == "+1234567890"
      assert hd(sent).to == "+0987654321"
    end

    test "truncates message to 160 chars" do
      notifier = SMSNotifier.new()
      long_message = String.duplicate("a", 200)
      {:ok, notifier} = Notifier.notify(notifier, "+1", long_message)

      sent = SMSNotifier.get_sent(notifier)
      assert String.length(hd(sent).body) == 160
    end
  end

  describe "PushNotifier" do
    test "sends push notification" do
      notifier = PushNotifier.new("my-app")
      {:ok, notifier} = Notifier.notify(notifier, "device-token-123", "New message!")

      sent = PushNotifier.get_sent(notifier)
      assert length(sent) == 1
      assert hd(sent).app_id == "my-app"
      assert hd(sent).device_token == "device-token-123"
    end
  end

  describe "CompositeNotifier" do
    test "sends to multiple channels" do
      email = EmailNotifier.new()
      sms = SMSNotifier.new()
      composite = CompositeNotifier.new([email, sms])

      {:ok, updated} = Notifier.notify(composite, "user@example.com", "Hello!")

      [updated_email, updated_sms] = updated.notifiers
      assert length(EmailNotifier.get_sent(updated_email)) == 1
      assert length(SMSNotifier.get_sent(updated_sms)) == 1
    end
  end

  # ============================================================
  # 5. Service Layer のテスト
  # ============================================================

  describe "UserService" do
    setup do
      repo = MemoryRepository.new()
      logger = MemoryLogger.new()
      service = UserService.new(repo, logger)
      on_exit(fn -> MemoryRepository.stop(repo) end)
      {:ok, service: service, repo: repo}
    end

    test "creates user", %{service: service} do
      {:ok, user, _service} = UserService.create_user(service, "John", "john@example.com")

      assert user.name == "John"
      assert user.email == "john@example.com"
      assert user.id != nil
    end

    test "gets user by id", %{service: service} do
      {:ok, user, service} = UserService.create_user(service, "John", "john@example.com")
      {:ok, found, _service} = UserService.get_user(service, user.id)

      assert found.name == "John"
    end

    test "get_user returns error for missing", %{service: service} do
      assert {:error, :not_found} = UserService.get_user(service, "nonexistent")
    end

    test "gets all users", %{service: service} do
      {:ok, _, service} = UserService.create_user(service, "John", "john@example.com")
      {:ok, _, service} = UserService.create_user(service, "Jane", "jane@example.com")
      {:ok, users, _service} = UserService.get_all_users(service)

      assert length(users) == 2
    end

    test "deletes user", %{service: service} do
      {:ok, user, service} = UserService.create_user(service, "John", "john@example.com")
      {:ok, deleted, _service} = UserService.delete_user(service, user.id)

      assert deleted.name == "John"
    end
  end

  describe "NotificationService" do
    test "sends notification to user" do
      notifier = EmailNotifier.new()
      logger = MemoryLogger.new()
      service = NotificationService.new(notifier, logger)

      user = %{email: "user@example.com"}
      {:ok, updated} = NotificationService.notify_user(service, user, "Hello!")

      sent = EmailNotifier.get_sent(updated.notifier)
      assert length(sent) == 1
    end

    test "broadcasts to multiple users" do
      notifier = EmailNotifier.new()
      logger = MemoryLogger.new()
      service = NotificationService.new(notifier, logger)

      users = [
        %{email: "user1@example.com"},
        %{email: "user2@example.com"},
        %{email: "user3@example.com"}
      ]

      {:ok, updated} = NotificationService.broadcast(service, users, "Broadcast!")

      sent = EmailNotifier.get_sent(updated.notifier)
      assert length(sent) == 3
    end
  end

  # ============================================================
  # 6. Container のテスト
  # ============================================================

  describe "Container" do
    test "registers and resolves services" do
      container = Container.new()
        |> Container.register(:logger, MemoryLogger.new())

      {:ok, logger} = Container.resolve(container, :logger)
      assert %MemoryLogger{} = logger
    end

    test "resolve returns error for missing" do
      container = Container.new()
      assert {:error, {:not_found, :missing}} = Container.resolve(container, :missing)
    end

    test "resolve! raises for missing" do
      container = Container.new()
      assert_raise RuntimeError, fn ->
        Container.resolve!(container, :missing)
      end
    end

    test "register_factory creates service lazily" do
      container = Container.new()
        |> Container.register(:config, %{name: "Test"})
        |> Container.register_factory(:service, fn c ->
          {:ok, config} = Container.resolve(c, :config)
          %{config: config}
        end)

      {:ok, service} = Container.resolve_with_factory(container, :service)
      assert service.config.name == "Test"
    end
  end

  describe "Application" do
    test "creates development container" do
      container = Application.development_container()

      {:ok, repo} = Container.resolve(container, :repository)
      assert %MemoryRepository{} = repo

      {:ok, logger} = Container.resolve(container, :logger)
      assert %ConsoleLogger{} = logger

      {:ok, user_service} = Container.resolve_with_factory(container, :user_service)
      assert %UserService{} = user_service

      # Cleanup
      MemoryRepository.stop(repo)
    end

    test "creates test container" do
      container = Application.test_container()

      {:ok, repo} = Container.resolve(container, :repository)
      assert %MockRepository{} = repo

      {:ok, logger} = Container.resolve(container, :logger)
      assert %MemoryLogger{} = logger
    end
  end
end
