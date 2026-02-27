defmodule Chapter22Test do
  use ExUnit.Case, async: true

  alias Chapter22.ClassToModule.{BankAccount, Configuration, ShapeFactory}
  alias Chapter22.InheritanceToComposition.{Speakable, Dog, Cat, User, DataProcessor}
  alias Chapter22.MutableToImmutable.{ShoppingCart, OrderState, EventSourced}
  alias Chapter22.PatternTransformation.{StrategyToFunction, ObserverToMessages,
                                          DecoratorToComposition, CommandToData,
                                          VisitorToPatternMatch}
  alias Chapter22.PracticalMigration.{UserManagement, OrderProcessing}

  # ============================================================
  # クラスからモジュールへ
  # ============================================================

  describe "ClassToModule - BankAccount" do
    test "creates new account" do
      account = BankAccount.new("Alice", 100)
      assert BankAccount.owner(account) == "Alice"
      assert BankAccount.balance(account) == 100
    end

    test "deposit increases balance" do
      account = BankAccount.new("Alice", 100)
      |> BankAccount.deposit(50)

      assert BankAccount.balance(account) == 150
    end

    test "withdraw returns ok tuple on success" do
      account = BankAccount.new("Alice", 100)
      {:ok, updated} = BankAccount.withdraw(account, 30)

      assert BankAccount.balance(updated) == 70
    end

    test "withdraw returns error on insufficient funds" do
      account = BankAccount.new("Alice", 100)
      assert {:error, :insufficient_funds} = BankAccount.withdraw(account, 150)
    end

    test "original account unchanged after operations" do
      original = BankAccount.new("Alice", 100)
      _updated = BankAccount.deposit(original, 50)

      assert BankAccount.balance(original) == 100
    end
  end

  describe "ClassToModule - Configuration" do
    test "provides configuration values" do
      assert Configuration.timeout() == 5000
      assert Configuration.max_retries() == 3
    end
  end

  describe "ClassToModule - ShapeFactory" do
    test "creates shapes" do
      circle = ShapeFactory.create(:circle, 5)
      assert circle.type == :circle
      assert circle.radius == 5

      rect = ShapeFactory.create(:rectangle, 4, 3)
      assert rect.type == :rectangle
    end

    test "calculates area" do
      assert_in_delta ShapeFactory.area(ShapeFactory.create(:circle, 5)), 78.54, 0.01
      assert ShapeFactory.area(ShapeFactory.create(:rectangle, 4, 3)) == 12
      assert ShapeFactory.area(ShapeFactory.create(:square, 5)) == 25
    end
  end

  # ============================================================
  # 継承からコンポジションへ
  # ============================================================

  describe "InheritanceToComposition - Protocol" do
    test "Dog speaks" do
      dog = Dog.new("Buddy")
      assert Speakable.speak(dog) == "Woof!"
    end

    test "Cat speaks" do
      cat = Cat.new("Whiskers")
      assert Speakable.speak(cat) == "Meow!"
    end
  end

  describe "InheritanceToComposition - Behaviour" do
    test "User to_json" do
      user = User.new(1, "Alice", "alice@test.com")
      json = User.to_json(user)

      assert String.contains?(json, "\"id\":1")
      assert String.contains?(json, "\"name\":\"Alice\"")
    end

    test "User from_json" do
      json = ~s({"id":1,"name":"Alice","email":"alice@test.com"})
      {:ok, user} = User.from_json(json)

      assert user.id == 1
      assert user.name == "Alice"
      assert user.email == "alice@test.com"
    end
  end

  describe "InheritanceToComposition - DataProcessor" do
    test "uses default processors" do
      assert DataProcessor.process("data") == {:ok, "data"}
    end

    test "uses custom processors" do
      result = DataProcessor.process("hello",
        parser: fn d -> {:ok, String.upcase(d)} end,
        transformer: fn {:ok, d} -> {:ok, d <> "!"} end
      )

      assert result == {:ok, "HELLO!"}
    end
  end

  # ============================================================
  # ミュータブル状態からイミュータブル変換へ
  # ============================================================

  describe "MutableToImmutable - ShoppingCart" do
    test "creates empty cart" do
      cart = ShoppingCart.new()
      assert cart.items == []
    end

    test "adds items" do
      cart = ShoppingCart.new()
      |> ShoppingCart.add_item(%{id: 1, name: "Apple", price: 100, quantity: 2})
      |> ShoppingCart.add_item(%{id: 2, name: "Banana", price: 50, quantity: 3})

      assert length(cart.items) == 2
    end

    test "removes items" do
      cart = ShoppingCart.new()
      |> ShoppingCart.add_item(%{id: 1, name: "Apple", price: 100, quantity: 1})
      |> ShoppingCart.add_item(%{id: 2, name: "Banana", price: 50, quantity: 1})
      |> ShoppingCart.remove_item(1)

      assert length(cart.items) == 1
      assert hd(cart.items).id == 2
    end

    test "calculates total" do
      cart = ShoppingCart.new()
      |> ShoppingCart.add_item(%{id: 1, price: 100, quantity: 2})
      |> ShoppingCart.add_item(%{id: 2, price: 50, quantity: 3})

      assert ShoppingCart.total(cart) == 350
    end

    test "original cart unchanged" do
      original = ShoppingCart.new()
      _updated = ShoppingCart.add_item(original, %{id: 1, price: 100, quantity: 1})

      assert original.items == []
    end
  end

  describe "MutableToImmutable - OrderState" do
    test "valid transitions" do
      order = %{status: :pending}

      {:ok, confirmed} = OrderState.transition(order, :confirm)
      assert confirmed.status == :confirmed

      {:ok, shipped} = OrderState.transition(confirmed, :ship)
      assert shipped.status == :shipped

      {:ok, delivered} = OrderState.transition(shipped, :deliver)
      assert delivered.status == :delivered
    end

    test "invalid transitions return error" do
      order = %{status: :pending}
      assert {:error, {:invalid_transition, :pending, :deliver}} =
        OrderState.transition(order, :deliver)
    end

    test "cancel from pending" do
      order = %{status: :pending}
      {:ok, cancelled} = OrderState.transition(order, :cancel)
      assert cancelled.status == :cancelled
    end
  end

  describe "MutableToImmutable - EventSourced" do
    test "creates account" do
      account = EventSourced.Account.new("ACC001")
      assert account.balance == 0
      assert account.events == []
    end

    test "deposit increases balance and records event" do
      {:ok, account} = EventSourced.Account.new("ACC001")
      |> EventSourced.Account.deposit(100)

      assert account.balance == 100
      assert length(account.events) == 1
    end

    test "withdraw decreases balance" do
      {:ok, account} = EventSourced.Account.new("ACC001")
      |> EventSourced.Account.deposit(100)

      {:ok, updated} = EventSourced.Account.withdraw(account, 30)
      assert updated.balance == 70
    end

    test "withdraw fails on insufficient funds" do
      {:ok, account} = EventSourced.Account.new("ACC001")
      |> EventSourced.Account.deposit(100)

      assert {:error, :insufficient_funds} = EventSourced.Account.withdraw(account, 150)
    end

    test "history returns events in order" do
      {:ok, account} = EventSourced.Account.new("ACC001")
      |> EventSourced.Account.deposit(100)

      {:ok, account} = EventSourced.Account.withdraw(account, 30)

      history = EventSourced.Account.history(account)
      assert length(history) == 2
      assert elem(hd(history), 0) == :deposited
    end
  end

  # ============================================================
  # デザインパターンの変換
  # ============================================================

  describe "PatternTransformation - StrategyToFunction" do
    test "default sort" do
      items = [3, 1, 2]
      assert StrategyToFunction.sort(items) == [1, 2, 3]
    end

    test "custom comparator" do
      items = [%{name: "B"}, %{name: "A"}, %{name: "C"}]
      sorted = StrategyToFunction.sort(items, StrategyToFunction.by_name())

      assert Enum.map(sorted, & &1.name) == ["A", "B", "C"]
    end
  end

  describe "PatternTransformation - ObserverToMessages" do
    setup do
      {:ok, pid} = ObserverToMessages.start_link()
      on_exit(fn -> ObserverToMessages.stop(pid) end)
      %{pid: pid}
    end

    test "subscribes and receives notifications", %{pid: pid} do
      test_pid = self()
      {:ok, _id} = ObserverToMessages.subscribe(pid, test_pid)

      ObserverToMessages.notify(pid, :test_event)

      assert_receive {:event, :test_event}
    end

    test "unsubscribe stops notifications", %{pid: pid} do
      test_pid = self()
      {:ok, id} = ObserverToMessages.subscribe(pid, test_pid)
      ObserverToMessages.unsubscribe(pid, id)

      ObserverToMessages.notify(pid, :test_event)

      refute_receive {:event, :test_event}, 100
    end
  end

  describe "PatternTransformation - DecoratorToComposition" do
    test "basic log" do
      result = DecoratorToComposition.log("hello")
      assert result == "[LOG] hello"
    end

    test "composed logger" do
      logger = DecoratorToComposition.create_logger()
      result = logger.("test message")

      assert String.contains?(result, "[LOG]")
      assert String.contains?(result, "[info]")
      assert String.contains?(result, "test message")
    end
  end

  describe "PatternTransformation - CommandToData" do
    test "execute create_user" do
      {:ok, user} = CommandToData.execute({:create_user, "Alice", "alice@test.com"})

      assert user.name == "Alice"
      assert user.email == "alice@test.com"
    end

    test "execute_batch" do
      commands = [
        {:create_user, "Alice", "alice@test.com"},
        {:create_user, "Bob", "bob@test.com"}
      ]

      results = CommandToData.execute_batch(commands)
      assert length(results) == 2
      assert Enum.all?(results, fn {:ok, _} -> true; _ -> false end)
    end

    test "execute_with_undo returns undo command" do
      {:ok, user, undo} = CommandToData.execute_with_undo({:create_user, "Alice", "alice@test.com"})

      assert user.name == "Alice"
      assert elem(undo, 0) == :delete_user
    end
  end

  describe "PatternTransformation - VisitorToPatternMatch" do
    test "eval expression" do
      # (2 + 3) * 4 = 20
      expr = {:mul, {:add, {:number, 2}, {:number, 3}}, {:number, 4}}
      assert VisitorToPatternMatch.eval(expr) == 20
    end

    test "stringify expression" do
      expr = {:add, {:number, 1}, {:number, 2}}
      assert VisitorToPatternMatch.stringify(expr) == "(1 + 2)"
    end

    test "optimize expression" do
      # x + 0 = x
      expr = {:add, {:number, 5}, {:number, 0}}
      assert VisitorToPatternMatch.optimize(expr) == {:number, 5}

      # x * 1 = x
      expr2 = {:mul, {:number, 5}, {:number, 1}}
      assert VisitorToPatternMatch.optimize(expr2) == {:number, 5}

      # x * 0 = 0
      expr3 = {:mul, {:number, 5}, {:number, 0}}
      assert VisitorToPatternMatch.optimize(expr3) == {:number, 0}
    end
  end

  # ============================================================
  # 実践的な移行例
  # ============================================================

  describe "PracticalMigration - UserManagement" do
    alias UserManagement.{User, Transformations, Queries, Repository, Service}

    setup do
      {:ok, _pid} = Repository.start_link(name: :test_user_repo)
      on_exit(fn -> Repository.stop(:test_user_repo) end)
      :ok
    end

    test "User creation" do
      user = User.new(name: "Alice", email: "alice@test.com", role: :user)

      assert user.name == "Alice"
      assert user.active == true
      assert user.created_at != nil
    end

    test "Transformations" do
      user = User.new(name: "Alice", role: :user)

      deactivated = Transformations.deactivate(user)
      assert deactivated.active == false

      {:ok, admin} = Transformations.change_role(user, :admin)
      assert admin.role == :admin

      {:ok, updated} = Transformations.update_email(user, "new@test.com")
      assert updated.email == "new@test.com"
    end

    test "Queries" do
      users = [
        User.new(name: "Alice", role: :admin, active: true),
        User.new(name: "Bob", role: :user, active: false),
        User.new(name: "Charlie", role: :user, active: true)
      ]

      active = Queries.active_users(users)
      assert length(active) == 2

      admins = Queries.admins(users)
      assert length(admins) == 1
      assert hd(admins).name == "Alice"
    end

    test "Service creates user" do
      {:ok, user} = Service.create_user(
        %{name: "Alice", email: "alice@test.com", role: :user},
        :test_user_repo
      )

      assert user.name == "Alice"
      assert Repository.get(user.id, :test_user_repo) != nil
    end

    test "Service updates email" do
      {:ok, user} = Service.create_user(
        %{name: "Alice", email: "old@test.com", role: :user},
        :test_user_repo
      )

      {:ok, updated} = Service.update_email(user.id, "new@test.com", :test_user_repo)
      assert updated.email == "new@test.com"
    end

    test "Service promotes to admin" do
      {:ok, user} = Service.create_user(
        %{name: "Alice", role: :user},
        :test_user_repo
      )

      {:ok, admin} = Service.promote_to_admin(user.id, :test_user_repo)
      assert admin.role == :admin
    end
  end

  describe "PracticalMigration - OrderProcessing" do
    alias OrderProcessing.{Money, Order, OrderStateMachine}

    test "Money operations" do
      m1 = Money.new(100)
      m2 = Money.new(50)

      {:ok, sum} = Money.add(m1, m2)
      assert sum.amount == 150

      multiplied = Money.multiply(m1, 3)
      assert multiplied.amount == 300
    end

    test "Money format" do
      jpy = Money.new(1000, :jpy)
      usd = Money.new(1000, :usd)

      assert Money.format(jpy) == "¥1000"
      assert Money.format(usd) == "$10.0"
    end

    test "Order creation" do
      order = Order.new(1)

      assert order.customer_id == 1
      assert order.status == :pending
      assert order.items == []
    end

    test "Order add_item" do
      order = Order.new(1)
      |> Order.add_item(%{id: 1, name: "Product", price: Money.new(100), quantity: 2})

      assert length(order.items) == 1
      assert order.total.amount == 200
    end

    test "OrderStateMachine transitions" do
      order = Order.new(1)

      {:ok, confirmed} = OrderStateMachine.confirm(order)
      assert confirmed.status == :confirmed

      {:ok, shipped} = OrderStateMachine.ship(confirmed)
      assert shipped.status == :shipped

      {:ok, delivered} = OrderStateMachine.deliver(shipped)
      assert delivered.status == :delivered
    end

    test "OrderStateMachine cancel" do
      order = Order.new(1)
      {:ok, cancelled} = OrderStateMachine.cancel(order)
      assert cancelled.status == :cancelled
    end

    test "OrderStateMachine invalid transition" do
      order = %{status: :delivered}
      assert {:error, :invalid_state} = OrderStateMachine.cancel(order)
    end
  end
end
