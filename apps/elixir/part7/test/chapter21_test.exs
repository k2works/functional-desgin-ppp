defmodule Chapter21Test do
  use ExUnit.Case, async: true

  alias Chapter21.Immutability.{GoodExample, DataOperations}
  alias Chapter21.Pipelines.{PipelinedCalls, Composition, Transformations}
  alias Chapter21.ErrorHandling.{TaggedTuples, Railway, ExceptionsVsReturns}
  alias Chapter21.Testability.{DependencyInjection, PropertyBased, NoMockNeeded}
  alias Chapter21.Performance.{LazyEvaluation, TailRecursion, DataStructures}
  alias Chapter21.CodeOrganization.{SmallFunctions, SeparationOfConcerns, Documentation}
  alias Chapter21.PracticalPatterns.{Options, Builder, StatePattern, Memoization}

  # ============================================================
  # 不変性と純粋関数
  # ============================================================

  describe "Immutability" do
    test "greeting_for_hour is pure" do
      assert GoodExample.greeting_for_hour(8) == "Good morning"
      assert GoodExample.greeting_for_hour(14) == "Good afternoon"
      assert GoodExample.greeting_for_hour(20) == "Good evening"
    end

    test "update_user creates new map" do
      user = %{name: "Alice", age: 30}
      updated = DataOperations.update_user(user, %{age: 31})

      assert updated.age == 31
      assert user.age == 30  # 元のデータは変わらない
    end

    test "update_nested modifies nested structure" do
      data = %{user: %{profile: %{name: "Alice"}}}
      updated = DataOperations.update_nested(data, [:user, :profile, :name], &String.upcase/1)

      assert updated.user.profile.name == "ALICE"
    end

    test "prepend is efficient" do
      list = [2, 3, 4]
      result = DataOperations.prepend(list, 1)
      assert result == [1, 2, 3, 4]
    end
  end

  # ============================================================
  # パイプラインと関数合成
  # ============================================================

  describe "Pipelines" do
    test "process transforms data correctly" do
      data = "  apple , banana,  , cherry  "
      result = PipelinedCalls.process(data)
      assert result == "APPLE | BANANA | CHERRY"
    end

    test "compose combines functions" do
      double = fn x -> x * 2 end
      add_one = fn x -> x + 1 end
      composed = Composition.compose(double, add_one)

      # double(add_one(5)) = double(6) = 12
      assert composed.(5) == 12
    end

    test "pipe_compose applies functions in order" do
      functions = [
        fn x -> x + 1 end,
        fn x -> x * 2 end,
        fn x -> x - 3 end
      ]
      pipeline = Composition.pipe_compose(functions)

      # ((5 + 1) * 2) - 3 = 9
      assert pipeline.(5) == 9
    end

    test "transform_users filters and formats" do
      users = [
        %{name: "Charlie", email: "c@test.com", active: true},
        %{name: "Alice", email: "a@test.com", active: true},
        %{name: "Bob", email: "b@test.com", active: false}
      ]

      result = Transformations.transform_users(users)
      assert result == ["Alice <a@test.com>", "Charlie <c@test.com>"]
    end
  end

  # ============================================================
  # エラーハンドリング
  # ============================================================

  describe "ErrorHandling - TaggedTuples" do
    test "divide returns ok/error" do
      assert {:ok, 5.0} = TaggedTuples.divide(10, 2)
      assert {:error, :division_by_zero} = TaggedTuples.divide(10, 0)
    end

    test "find_user returns ok/error" do
      users = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]

      assert {:ok, %{name: "Alice"}} = TaggedTuples.find_user(users, 1)
      assert {:error, :not_found} = TaggedTuples.find_user(users, 99)
    end

    test "process_order with with construct" do
      users = [%{id: 1, name: "Alice"}]
      orders = [%{id: 101, user_id: 1, total: 100}]

      assert {:ok, %{user: _, order: _}} = TaggedTuples.process_order(101, 1, users, orders)
      assert {:error, :not_found} = TaggedTuples.process_order(101, 99, users, orders)
      assert {:error, :order_not_found} = TaggedTuples.process_order(999, 1, users, orders)
    end
  end

  describe "ErrorHandling - Railway" do
    test "bind passes through ok" do
      result = Railway.bind({:ok, 5}, fn x -> {:ok, x * 2} end)
      assert result == {:ok, 10}
    end

    test "bind short-circuits on error" do
      result = Railway.bind({:error, :fail}, fn x -> {:ok, x * 2} end)
      assert result == {:error, :fail}
    end

    test "pipeline chains functions" do
      functions = [
        fn x -> {:ok, x + 1} end,
        fn x -> {:ok, x * 2} end
      ]
      assert Railway.pipeline(5, functions) == {:ok, 12}
    end

    test "pipeline stops on error" do
      functions = [
        fn x -> {:ok, x + 1} end,
        fn _ -> {:error, :failed} end,
        fn x -> {:ok, x * 2} end
      ]
      assert Railway.pipeline(5, functions) == {:error, :failed}
    end

    test "bimap transforms both tracks" do
      assert Railway.bimap({:ok, 5}, &(&1 * 2), &(&1)) == {:ok, 10}
      assert Railway.bimap({:error, "err"}, &(&1), &String.upcase/1) == {:error, "ERR"}
    end
  end

  describe "ErrorHandling - ExceptionsVsReturns" do
    test "assert_positive! raises on invalid" do
      assert ExceptionsVsReturns.assert_positive!(5) == 5
      assert_raise ArgumentError, fn ->
        ExceptionsVsReturns.assert_positive!(-1)
      end
    end

    test "parse_integer returns result" do
      assert ExceptionsVsReturns.parse_integer("42") == {:ok, 42}
      assert ExceptionsVsReturns.parse_integer("abc") == {:error, :invalid_format}
      assert ExceptionsVsReturns.parse_integer("42abc") == {:error, :invalid_format}
    end
  end

  # ============================================================
  # テスタビリティ
  # ============================================================

  describe "Testability - DependencyInjection" do
    test "fetch_user with mock client" do
      mock_client = fn _url -> {:ok, ~s({"name":"Alice"})} end
      result = DependencyInjection.fetch_user(1, mock_client)

      assert {:ok, %{"name" => "Alice"}} = result
    end

    test "is_weekend? with injected clock" do
      # 土曜日
      saturday_clock = fn -> ~D[2024-01-06] end
      assert DependencyInjection.is_weekend?(saturday_clock)

      # 月曜日
      monday_clock = fn -> ~D[2024-01-08] end
      refute DependencyInjection.is_weekend?(monday_clock)
    end

    test "roll_dice with deterministic random" do
      fixed_random = fn _max -> 6 end
      assert DependencyInjection.roll_dice(fixed_random) == 6
    end
  end

  describe "Testability - PropertyBased" do
    test "encode/decode roundtrip" do
      original = "Hello, World!"
      encoded = PropertyBased.encode(original)
      decoded = PropertyBased.decode(encoded)

      assert decoded == original
    end

    test "normalize_email is idempotent" do
      email = "  Test@Example.COM  "
      once = PropertyBased.normalize_email(email)
      twice = PropertyBased.normalize_email(once)

      assert once == twice
      assert once == "test@example.com"
    end

    test "concat_strings is associative" do
      a = "Hello"
      b = ", "
      c = "World"

      left = PropertyBased.concat_strings(PropertyBased.concat_strings(a, b), c)
      right = PropertyBased.concat_strings(a, PropertyBased.concat_strings(b, c))

      assert left == right
    end
  end

  describe "Testability - NoMockNeeded" do
    test "process_data is pure transformation" do
      input = "line1\n\nline2\nline3"
      result = NoMockNeeded.process_data(input)

      assert result == ["LINE1", "LINE2", "LINE3"]
    end
  end

  # ============================================================
  # パフォーマンス最適化
  # ============================================================

  describe "Performance - LazyEvaluation" do
    test "fibonacci_stream generates sequence" do
      fibs = LazyEvaluation.fibonacci_stream()
             |> Enum.take(10)

      assert fibs == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
    end

    test "lazy_transform takes limited results" do
      result = LazyEvaluation.lazy_transform(1..1000)
      assert length(result) == 10
      assert Enum.all?(result, &(rem(&1, 2) == 0))
    end
  end

  describe "Performance - TailRecursion" do
    test "sum functions give same result" do
      list = Enum.to_list(1..100)

      assert TailRecursion.sum_bad(list) == 5050
      assert TailRecursion.sum_good(list) == 5050
    end

    test "reverse works correctly" do
      assert TailRecursion.reverse([1, 2, 3]) == [3, 2, 1]
      assert TailRecursion.reverse([]) == []
    end
  end

  describe "Performance - DataStructures" do
    test "MapSet membership is efficient" do
      items = Enum.to_list(1..1000)

      assert DataStructures.member_check_efficient(items, 500)
      refute DataStructures.member_check_efficient(items, 1001)
    end

    test "build_index creates map" do
      items = [%{id: 1, name: "A"}, %{id: 2, name: "B"}]
      index = DataStructures.build_index(items, & &1.id)

      assert index[1].name == "A"
      assert index[2].name == "B"
    end
  end

  # ============================================================
  # コード構成
  # ============================================================

  describe "CodeOrganization - SmallFunctions" do
    test "validate_email checks format" do
      assert {:ok, "test@example.com"} = SmallFunctions.validate_email("test@example.com")
      assert {:error, :invalid_format} = SmallFunctions.validate_email("invalid")
    end

    test "validate_email blocks certain domains" do
      assert {:error, :blocked_domain} = SmallFunctions.validate_email("test@spam.com")
    end

    test "validate_email checks length" do
      long_email = String.duplicate("a", 250) <> "@test.com"
      assert {:error, :too_long} = SmallFunctions.validate_email(long_email)
    end
  end

  describe "CodeOrganization - SeparationOfConcerns" do
    alias SeparationOfConcerns.{User, UserService, UserFormatter}

    test "UserService checks access" do
      admin = User.new(id: 1, name: "Admin", email: "admin@test.com", role: :admin)
      user = User.new(id: 2, name: "User", email: "user@test.com", role: :user)

      assert UserService.can_access?(admin, :admin_panel)
      refute UserService.can_access?(user, :admin_panel)
      assert UserService.can_access?(user, :dashboard)
    end

    test "UserFormatter formats user" do
      user = User.new(id: 1, name: "Alice", email: "alice@test.com", role: :user)

      assert UserFormatter.to_display_name(user) == "Alice"
      assert UserFormatter.to_email_format(user) == "Alice <alice@test.com>"
    end
  end

  describe "CodeOrganization - Documentation" do
    test "find_user with doctest example" do
      users = [%{id: 1, name: "Alice", role: :admin}]
      assert {:ok, %{id: 1, name: "Alice", role: :admin}} = Documentation.find_user(users, 1)
    end
  end

  # ============================================================
  # 実践的なパターン
  # ============================================================

  describe "PracticalPatterns - Options" do
    test "with_defaults merges options" do
      opts = Options.with_defaults(timeout: 10000)

      assert Keyword.get(opts, :timeout) == 10000
      assert Keyword.get(opts, :retries) == 3  # default
      assert Keyword.get(opts, :format) == :json  # default
    end

    test "fetch_data uses options" do
      assert {:ok, _} = Options.fetch_data("http://example.com")
      assert {:ok, _} = Options.fetch_data("http://example.com", timeout: 1000)
    end
  end

  describe "PracticalPatterns - Builder" do
    test "builds valid data" do
      result = Builder.new()
      |> Builder.set(:name, "Alice")
      |> Builder.set(:age, 30)
      |> Builder.build()

      assert {:ok, %{name: "Alice", age: 30}} = result
    end

    test "validates during build" do
      name_required = fn fields ->
        if Map.has_key?(fields, :name), do: :ok, else: {:error, :name_required}
      end

      result = Builder.new()
      |> Builder.set(:age, 30)
      |> Builder.add_validation(name_required)
      |> Builder.build()

      assert {:error, [{:error, :name_required}]} = result
    end
  end

  describe "PracticalPatterns - StatePattern" do
    test "run_with_state threads state" do
      operations = [
        fn state -> {:ok, Map.put(state, :a, 1)} end,
        fn state -> {:ok, Map.put(state, :b, 2)} end
      ]

      assert {:ok, %{a: 1, b: 2}} = StatePattern.run_with_state(%{}, operations)
    end

    test "counter_example demonstrates state" do
      assert {:ok, %{count: 4}} = StatePattern.counter_example()
    end

    test "run_with_state short-circuits on error" do
      operations = [
        fn state -> {:ok, Map.put(state, :a, 1)} end,
        fn _ -> {:error, :failed} end,
        fn state -> {:ok, Map.put(state, :b, 2)} end
      ]

      assert {:error, :failed} = StatePattern.run_with_state(%{}, operations)
    end
  end

  describe "PracticalPatterns - Memoization" do
    setup do
      Memoization.start_link()
      on_exit(fn -> Memoization.stop() end)
      :ok
    end

    test "memoize caches results" do
      counter = Agent.start_link(fn -> 0 end) |> elem(1)

      compute = fn ->
        Agent.update(counter, &(&1 + 1))
        "computed"
      end

      # 最初の呼び出し
      assert Memoization.memoize(:key1, compute) == "computed"
      # キャッシュから
      assert Memoization.memoize(:key1, compute) == "computed"
      assert Memoization.memoize(:key1, compute) == "computed"

      # 関数は1回だけ実行される
      assert Agent.get(counter, & &1) == 1

      Agent.stop(counter)
    end

    test "clear removes cache" do
      Memoization.memoize(:key, fn -> "value" end)
      Memoization.clear()

      # 再度計算される
      counter = Agent.start_link(fn -> 0 end) |> elem(1)
      Memoization.memoize(:key, fn ->
        Agent.update(counter, &(&1 + 1))
        "new_value"
      end)

      assert Agent.get(counter, & &1) == 1
      Agent.stop(counter)
    end
  end
end
