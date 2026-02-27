defmodule Chapter20Test do
  use ExUnit.Case, async: true

  alias Chapter20.VisitorIterator
  alias Chapter20.VisitorIterator.{TreeNode, Iterator, Visitor}
  alias Chapter20.StrategyFactory.{DiscountFactory, ValidatorFactory, PriceCalculator}
  alias Chapter20.ObserverState.OrderStateMachine
  alias Chapter20.DecoratorPipeline
  alias Chapter20.DecoratorPipeline.{CacheDecorator, PipelineBuilder}
  alias Chapter20.CompositeVisitor.{FileSystem, Expression}
  alias Chapter20.IntegratedExample.OrderProcessor

  # ============================================================
  # Visitor + Iterator パターンのテスト
  # ============================================================

  describe "VisitorIterator" do
    setup do
      #       4
      #      / \
      #     2   6
      #    / \ / \
      #   1  3 5  7
      tree = TreeNode.node(4,
        TreeNode.node(2, TreeNode.leaf(1), TreeNode.leaf(3)),
        TreeNode.node(6, TreeNode.leaf(5), TreeNode.leaf(7))
      )
      %{tree: tree}
    end

    test "preorder traversal", %{tree: tree} do
      assert Iterator.preorder(tree) == [4, 2, 1, 3, 6, 5, 7]
    end

    test "inorder traversal", %{tree: tree} do
      assert Iterator.inorder(tree) == [1, 2, 3, 4, 5, 6, 7]
    end

    test "postorder traversal", %{tree: tree} do
      assert Iterator.postorder(tree) == [1, 3, 2, 5, 7, 6, 4]
    end

    test "levelorder traversal", %{tree: tree} do
      assert Iterator.levelorder(tree) == [4, 2, 6, 1, 3, 5, 7]
    end

    test "visitor sum", %{tree: tree} do
      values = Iterator.inorder(tree)
      assert Visitor.sum(values) == 28
    end

    test "visitor max", %{tree: tree} do
      values = Iterator.inorder(tree)
      assert Visitor.max(values) == 7
    end

    test "visitor min", %{tree: tree} do
      values = Iterator.inorder(tree)
      assert Visitor.min(values) == 1
    end

    test "visitor map", %{tree: tree} do
      values = Iterator.inorder(tree)
      assert Visitor.map(values, &(&1 * 2)) == [2, 4, 6, 8, 10, 12, 14]
    end

    test "visitor filter", %{tree: tree} do
      values = Iterator.inorder(tree)
      assert Visitor.filter(values, &(&1 > 3)) == [4, 5, 6, 7]
    end

    test "traverse_and_visit combination", %{tree: tree} do
      result = VisitorIterator.traverse_and_visit(
        tree,
        fn t -> Iterator.inorder(t) end,
        fn vals -> Visitor.sum(vals) end
      )
      assert result == 28
    end
  end

  # ============================================================
  # Strategy + Factory パターンのテスト
  # ============================================================

  describe "StrategyFactory - Discount" do
    test "regular customer gets no discount" do
      strategy = DiscountFactory.create(:regular)
      assert strategy.(100.0) == 100.0
    end

    test "premium customer gets 10% discount" do
      strategy = DiscountFactory.create(:premium)
      assert strategy.(100.0) == 90.0
    end

    test "VIP customer gets 20% discount" do
      strategy = DiscountFactory.create(:vip)
      assert strategy.(100.0) == 80.0
    end

    test "seasonal discount with custom rate" do
      strategy = DiscountFactory.create({:seasonal, 0.15})
      assert strategy.(100.0) == 85.0
    end

    test "combined discounts" do
      strategy = DiscountFactory.create({:combined, [:premium, {:seasonal, 0.1}]})
      # 100 * 0.9 * 0.9 = 81
      assert strategy.(100.0) == 81.0
    end

    test "PriceCalculator with customer type" do
      assert PriceCalculator.calculate(100.0, :regular) == 100.0
      assert PriceCalculator.calculate(100.0, :vip) == 80.0
    end

    test "PriceCalculator total" do
      items = [{"item1", 100.0}, {"item2", 50.0}]
      assert PriceCalculator.calculate_total(items, :premium) == 135.0
    end
  end

  describe "StrategyFactory - Validator" do
    test "email validator" do
      validator = ValidatorFactory.create(:email)
      assert validator.("test@example.com") == true
      assert validator.("invalid-email") == false
    end

    test "phone validator" do
      validator = ValidatorFactory.create(:phone)
      assert validator.("03-1234-5678") == true
      assert validator.("1234567890") == false
    end

    test "age validator" do
      validator = ValidatorFactory.create(:age)
      assert validator.(25) == true
      assert validator.(-1) == false
      assert validator.(200) == false
    end

    test "range validator" do
      validator = ValidatorFactory.create({:range, 1, 10})
      assert validator.(5) == true
      assert validator.(0) == false
      assert validator.(11) == false
    end

    test "pattern validator" do
      validator = ValidatorFactory.create({:pattern, ~r/^\d{4}$/})
      assert validator.("1234") == true
      assert validator.("12345") == false
    end
  end

  # ============================================================
  # Observer + State パターンのテスト
  # ============================================================

  describe "ObserverState - OrderStateMachine" do
    setup do
      {:ok, pid} = OrderStateMachine.start_link("ORDER-001")
      on_exit(fn -> OrderStateMachine.stop(pid) end)
      %{pid: pid}
    end

    test "initial state is pending", %{pid: pid} do
      assert OrderStateMachine.current_state(pid) == :pending
    end

    test "valid transitions", %{pid: pid} do
      assert {:ok, :confirmed} = OrderStateMachine.transition(pid, :confirmed)
      assert {:ok, :shipped} = OrderStateMachine.transition(pid, :shipped)
      assert {:ok, :delivered} = OrderStateMachine.transition(pid, :delivered)
    end

    test "invalid transition returns error", %{pid: pid} do
      assert {:error, :invalid_transition} = OrderStateMachine.transition(pid, :delivered)
    end

    test "cancellation from pending", %{pid: pid} do
      assert {:ok, :cancelled} = OrderStateMachine.transition(pid, :cancelled)
    end

    test "history tracking", %{pid: pid} do
      OrderStateMachine.transition(pid, :confirmed)
      OrderStateMachine.transition(pid, :shipped)

      history = OrderStateMachine.history(pid)
      states = Enum.map(history, fn {state, _time} -> state end)
      assert states == [:pending, :confirmed, :shipped]
    end

    test "observer notification", %{pid: pid} do
      test_pid = self()

      OrderStateMachine.subscribe(pid, fn event ->
        send(test_pid, {:state_changed, event})
      end)

      OrderStateMachine.transition(pid, :confirmed)

      assert_receive {:state_changed, event}
      assert event.old_state == :pending
      assert event.new_state == :confirmed
      assert event.order_id == "ORDER-001"
    end

    test "multiple observers", %{pid: pid} do
      test_pid = self()

      OrderStateMachine.subscribe(pid, fn _ -> send(test_pid, :observer1) end)
      OrderStateMachine.subscribe(pid, fn _ -> send(test_pid, :observer2) end)

      OrderStateMachine.transition(pid, :confirmed)

      assert_receive :observer1
      assert_receive :observer2
    end

    test "unsubscribe observer", %{pid: pid} do
      test_pid = self()

      {:ok, id} = OrderStateMachine.subscribe(pid, fn _ -> send(test_pid, :notified) end)
      OrderStateMachine.unsubscribe(pid, id)

      OrderStateMachine.transition(pid, :confirmed)

      refute_receive :notified, 100
    end
  end

  # ============================================================
  # Decorator + Pipeline パターンのテスト
  # ============================================================

  describe "DecoratorPipeline" do
    test "with_error_handling catches errors" do
      failing_func = fn _ -> raise "test error" end
      decorated = DecoratorPipeline.with_error_handling(failing_func, :default)

      assert {:error, _, :default} = decorated.("input")
    end

    test "with_error_handling passes through success" do
      success_func = fn x -> x * 2 end
      decorated = DecoratorPipeline.with_error_handling(success_func)

      assert {:ok, 10} = decorated.(5)
    end

    test "with_timing returns elapsed time" do
      slow_func = fn x ->
        Process.sleep(10)
        x
      end
      decorated = DecoratorPipeline.with_timing(slow_func)

      {result, elapsed} = decorated.("test")
      assert result == "test"
      assert elapsed >= 10_000  # at least 10ms in microseconds
    end

    test "with_retry retries on failure" do
      # 3回目で成功する関数
      counter = Agent.start_link(fn -> 0 end) |> elem(1)
      flaky_func = fn x ->
        count = Agent.get_and_update(counter, fn c -> {c + 1, c + 1} end)
        if count < 3, do: raise("not yet"), else: x
      end

      decorated = DecoratorPipeline.with_retry(flaky_func, 5, 10)
      assert {:ok, "success"} = decorated.("success")

      Agent.stop(counter)
    end
  end

  describe "CacheDecorator" do
    setup do
      {:ok, cache} = CacheDecorator.start_link()
      on_exit(fn -> CacheDecorator.stop(cache) end)
      %{cache: cache}
    end

    test "caches results", %{cache: cache} do
      counter = Agent.start_link(fn -> 0 end) |> elem(1)
      expensive_func = fn x ->
        Agent.update(counter, &(&1 + 1))
        x * 2
      end

      cached_func = CacheDecorator.with_cache(expensive_func, cache)

      assert cached_func.(5) == 10
      assert cached_func.(5) == 10  # Should use cache
      assert cached_func.(5) == 10  # Should use cache

      # Function should only be called once
      assert Agent.get(counter, & &1) == 1

      Agent.stop(counter)
    end
  end

  describe "PipelineBuilder" do
    test "builds and executes pipeline" do
      pipeline = PipelineBuilder.new()
      |> PipelineBuilder.add_error_handling(:error_default)

      result = PipelineBuilder.execute(pipeline, fn x -> x * 2 end, 5)
      assert result == {:ok, 10}
    end

    test "handles errors in pipeline" do
      pipeline = PipelineBuilder.new()
      |> PipelineBuilder.add_error_handling(:default_value)

      result = PipelineBuilder.execute(pipeline, fn _ -> raise "error" end, 5)
      assert {:error, _, :default_value} = result
    end
  end

  # ============================================================
  # Composite + Visitor パターンのテスト
  # ============================================================

  describe "CompositeVisitor - FileSystem" do
    setup do
      fs = FileSystem.Directory.new("root", [
        FileSystem.File.new("readme.txt", 100),
        FileSystem.Directory.new("src", [
          FileSystem.File.new("main.ex", 500),
          FileSystem.File.new("helper.ex", 200)
        ]),
        FileSystem.Directory.new("test", [
          FileSystem.File.new("main_test.ex", 300)
        ])
      ])
      %{fs: fs}
    end

    test "total_size", %{fs: fs} do
      assert FileSystem.total_size(fs) == 1100
    end

    test "file_count", %{fs: fs} do
      assert FileSystem.file_count(fs) == 4
    end

    test "dir_count", %{fs: fs} do
      assert FileSystem.dir_count(fs) == 3
    end

    test "all_files", %{fs: fs} do
      files = FileSystem.all_files(fs)
      assert Enum.sort(files) == ["helper.ex", "main.ex", "main_test.ex", "readme.txt"]
    end

    test "find_files by pattern", %{fs: fs} do
      found = FileSystem.find_files(fs, ~r/\.ex$/)
      names = Enum.map(found, & &1.name)
      assert Enum.sort(names) == ["helper.ex", "main.ex", "main_test.ex"]
    end

    test "display shows tree structure", %{fs: fs} do
      output = FileSystem.display(fs)
      assert String.contains?(output, "📁 root/")
      assert String.contains?(output, "📄 readme.txt")
      assert String.contains?(output, "📁 src/")
    end

    test "custom visitor", %{fs: fs} do
      {result, _children} = FileSystem.accept(fs, fn
        :file, file -> {:file, file.name}
        :directory, dir -> {:dir, dir.name}
      end)
      assert result == {:dir, "root"}
    end
  end

  describe "CompositeVisitor - Expression" do
    setup do
      # (2 + 3) * 4
      expr = Expression.BinaryOp.new(:mul,
        Expression.BinaryOp.new(:add,
          Expression.Number.new(2),
          Expression.Number.new(3)
        ),
        Expression.Number.new(4)
      )
      %{expr: expr}
    end

    test "evaluate expression", %{expr: expr} do
      assert Expression.evaluate(expr) == 20
    end

    test "stringify expression", %{expr: expr} do
      assert Expression.stringify(expr) == "((2 + 3) * 4)"
    end

    test "node_count", %{expr: expr} do
      assert Expression.node_count(expr) == 5
    end

    test "depth", %{expr: expr} do
      assert Expression.depth(expr) == 3
    end

    test "unary operation" do
      # -(5 + 3)
      expr = Expression.UnaryOp.new(:neg,
        Expression.BinaryOp.new(:add,
          Expression.Number.new(5),
          Expression.Number.new(3)
        )
      )
      assert Expression.evaluate(expr) == -8
      assert Expression.stringify(expr) == "(-(5 + 3))"
    end
  end

  # ============================================================
  # 統合テスト
  # ============================================================

  describe "IntegratedExample - OrderProcessor" do
    test "creates processor with customer type" do
      processor = OrderProcessor.new(:vip)
      assert processor.customer_type == :vip
    end

    test "adds items" do
      processor = OrderProcessor.new(:regular)
      |> OrderProcessor.add_item("item1", 100.0)
      |> OrderProcessor.add_item("item2", 50.0)

      assert length(processor.items) == 2
    end

    test "calculates total with discount" do
      processor = OrderProcessor.new(:premium)
      |> OrderProcessor.add_item("item1", 100.0)
      |> OrderProcessor.add_item("item2", 100.0)

      # 200 * 0.9 = 180
      assert OrderProcessor.calculate_total(processor) == 180.0
    end

    test "validates data" do
      processor = OrderProcessor.new(:regular)
      |> OrderProcessor.add_validator(:email)

      assert OrderProcessor.validate(processor, "test@example.com") == true
      assert OrderProcessor.validate(processor, "invalid") == false
    end

    test "processes order with pipeline" do
      processor = OrderProcessor.new(:vip)
      |> OrderProcessor.add_item("product", 100.0)

      result = OrderProcessor.process(processor)
      assert result == {:ok, 80.0}
    end
  end
end
