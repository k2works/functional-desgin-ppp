defmodule Chapter15Test do
  use ExUnit.Case, async: true
  doctest Chapter15

  alias Chapter15.{Driver, World, Simulation, Solver, Examples}

  # ============================================================
  # Driver Tests
  # ============================================================

  describe "Driver" do
    test "new/3 creates a driver with name, route, and rumors" do
      driver = Driver.new("Alice", [1, 2, 3], [:rumor_a])
      assert driver.name == "Alice"
      assert driver.rumors == MapSet.new([:rumor_a])
    end

    test "route is an infinite cycle" do
      driver = Driver.new("Bob", [1, 2], [])
      route_sample = Enum.take(driver.route, 5)
      assert route_sample == [1, 2, 1, 2, 1]
    end

    test "current_stop/1 returns the first stop in the route" do
      driver = Driver.new("Alice", [5, 6, 7], [])
      assert Driver.current_stop(driver) == 5
    end

    test "move/1 advances to the next stop" do
      driver = Driver.new("Alice", [1, 2, 3], [])
      assert Driver.current_stop(driver) == 1

      moved = Driver.move(driver)
      assert Driver.current_stop(moved) == 2

      moved_twice = Driver.move(moved)
      assert Driver.current_stop(moved_twice) == 3
    end

    test "move/1 cycles back to the beginning" do
      driver = Driver.new("Alice", [1, 2], [])

      moved =
        driver
        |> Driver.move()
        |> Driver.move()

      assert Driver.current_stop(moved) == 1
    end

    test "set_rumors/2 updates the driver's rumors" do
      driver = Driver.new("Alice", [1], [:a])
      updated = Driver.set_rumors(driver, MapSet.new([:a, :b, :c]))
      assert updated.rumors == MapSet.new([:a, :b, :c])
    end

    test "summary/1 returns driver summary" do
      driver = Driver.new("Alice", [5, 6, 7], [:a, :b, :c])
      summary = Driver.summary(driver)

      assert summary.name == "Alice"
      assert summary.current_stop == 5
      assert summary.rumor_count == 3
    end
  end

  # ============================================================
  # World Tests
  # ============================================================

  describe "World.move_drivers/1" do
    test "moves all drivers to their next stops" do
      drivers = [
        Driver.new("Alice", [1, 2], []),
        Driver.new("Bob", [3, 4], [])
      ]

      moved = World.move_drivers(drivers)

      assert Driver.current_stop(Enum.at(moved, 0)) == 2
      assert Driver.current_stop(Enum.at(moved, 1)) == 4
    end
  end

  describe "World.get_stops/1" do
    test "groups drivers by their current stop" do
      drivers = [
        Driver.new("Alice", [1, 2], []),
        Driver.new("Bob", [1, 3], []),
        Driver.new("Carol", [2, 3], [])
      ]

      stops = World.get_stops(drivers)

      # Alice and Bob at stop 1
      assert length(Map.get(stops, 1, [])) == 2
      # Carol at stop 2
      assert length(Map.get(stops, 2, [])) == 1
    end

    test "handles empty driver list" do
      assert World.get_stops([]) == %{}
    end
  end

  describe "World.merge_rumors/1" do
    test "merges rumors from all drivers at the same stop" do
      drivers = [
        Driver.new("Alice", [1], [:rumor_a]),
        Driver.new("Bob", [1], [:rumor_b])
      ]

      merged = World.merge_rumors(drivers)

      expected_rumors = MapSet.new([:rumor_a, :rumor_b])
      assert Enum.all?(merged, fn d -> d.rumors == expected_rumors end)
    end

    test "handles three or more drivers" do
      drivers = [
        Driver.new("Alice", [1], [:a]),
        Driver.new("Bob", [1], [:b]),
        Driver.new("Carol", [1], [:c])
      ]

      merged = World.merge_rumors(drivers)

      expected_rumors = MapSet.new([:a, :b, :c])
      assert Enum.all?(merged, fn d -> d.rumors == expected_rumors end)
    end

    test "handles overlapping rumors" do
      drivers = [
        Driver.new("Alice", [1], [:a, :b]),
        Driver.new("Bob", [1], [:b, :c])
      ]

      merged = World.merge_rumors(drivers)

      expected_rumors = MapSet.new([:a, :b, :c])
      assert Enum.all?(merged, fn d -> d.rumors == expected_rumors end)
    end
  end

  describe "World.spread_rumors/1" do
    test "spreads rumors at all stops" do
      drivers = [
        Driver.new("Alice", [1], [:a]),
        Driver.new("Bob", [1], [:b]),
        Driver.new("Carol", [2], [:c]),
        Driver.new("Dave", [2], [:d])
      ]

      spread = World.spread_rumors(drivers)

      # Alice and Bob should share :a and :b
      alice = Enum.find(spread, &(&1.name == "Alice"))
      bob = Enum.find(spread, &(&1.name == "Bob"))
      assert alice.rumors == MapSet.new([:a, :b])
      assert bob.rumors == MapSet.new([:a, :b])

      # Carol and Dave should share :c and :d
      carol = Enum.find(spread, &(&1.name == "Carol"))
      dave = Enum.find(spread, &(&1.name == "Dave"))
      assert carol.rumors == MapSet.new([:c, :d])
      assert dave.rumors == MapSet.new([:c, :d])
    end
  end

  describe "World.drive/1" do
    test "moves drivers and spreads rumors" do
      drivers = [
        Driver.new("Alice", [1, 2], [:a]),
        Driver.new("Bob", [2, 1], [:b])
      ]

      # Initially: Alice at 1, Bob at 2
      # After drive: Alice at 2, Bob at 1 (they pass each other)
      driven = World.drive(drivers)

      alice = Enum.find(driven, &(&1.name == "Alice"))
      bob = Enum.find(driven, &(&1.name == "Bob"))

      assert Driver.current_stop(alice) == 2
      assert Driver.current_stop(bob) == 1
    end

    test "drivers meeting at same stop share rumors" do
      drivers = [
        Driver.new("Alice", [1, 2], [:a]),
        Driver.new("Bob", [3, 2], [:b])
      ]

      # After one step: Alice at 2, Bob at 2 (they meet)
      driven = World.drive(drivers)

      alice = Enum.find(driven, &(&1.name == "Alice"))
      bob = Enum.find(driven, &(&1.name == "Bob"))

      assert alice.rumors == MapSet.new([:a, :b])
      assert bob.rumors == MapSet.new([:a, :b])
    end
  end

  describe "World.all_rumors_shared?/1" do
    test "returns true when all drivers have the same rumors" do
      drivers = [
        Driver.new("Alice", [1], [:a, :b]),
        Driver.new("Bob", [2], [:a, :b])
      ]

      assert World.all_rumors_shared?(drivers)
    end

    test "returns false when drivers have different rumors" do
      drivers = [
        Driver.new("Alice", [1], [:a]),
        Driver.new("Bob", [2], [:b])
      ]

      refute World.all_rumors_shared?(drivers)
    end

    test "returns true for empty list" do
      assert World.all_rumors_shared?([])
    end

    test "returns true for single driver" do
      drivers = [Driver.new("Alice", [1], [:a])]
      assert World.all_rumors_shared?(drivers)
    end
  end

  describe "World.count_unique_rumors/1" do
    test "counts total unique rumors across all drivers" do
      drivers = [
        Driver.new("D1", [1], [:a, :b]),
        Driver.new("D2", [2], [:b, :c])
      ]

      assert World.count_unique_rumors(drivers) == 3
    end

    test "handles empty list" do
      assert World.count_unique_rumors([]) == 0
    end
  end

  describe "World.summary/1" do
    test "returns world summary" do
      drivers = [
        Driver.new("D1", [1], [:a, :b]),
        Driver.new("D2", [1], [:a, :b])
      ]

      summary = World.summary(drivers)

      assert length(summary.drivers) == 2
      assert summary.total_unique_rumors == 2
      assert summary.all_shared? == true
    end
  end

  # ============================================================
  # Simulation Tests
  # ============================================================

  describe "Simulation.run_until_spread/1" do
    test "returns step count when all rumors are shared" do
      drivers = [
        Driver.new("D1", [3, 1, 2, 3], [:r1]),
        Driver.new("D2", [3, 2, 3, 1], [:r2]),
        Driver.new("D3", [4, 2, 3, 4, 5], [:r3])
      ]

      result = Simulation.run_until_spread(drivers)
      assert is_integer(result)
      assert result > 0
      assert result < 480
    end

    test "returns :never when drivers never meet" do
      drivers = [
        Driver.new("D1", [1], [:r1]),
        Driver.new("D2", [2], [:r2])
      ]

      assert Simulation.run_until_spread(drivers) == :never
    end

    test "handles case where all start at same stop" do
      drivers = [
        Driver.new("D1", [1, 2], [:r1]),
        Driver.new("D2", [1, 3], [:r2])
      ]

      # After first move, they spread rumors at their original positions
      # This is tricky because drive() moves first, then spreads
      result = Simulation.run_until_spread(drivers)
      assert result != :never
    end
  end

  describe "Simulation.run_steps/2" do
    test "runs specified number of steps" do
      drivers = [
        Driver.new("D1", [1, 2, 3], [:r1]),
        Driver.new("D2", [1, 3, 2], [:r2])
      ]

      result = Simulation.run_steps(drivers, 3)

      # After 3 steps, positions should have cycled
      d1 = Enum.find(result, &(&1.name == "D1"))
      d2 = Enum.find(result, &(&1.name == "D2"))

      # Route cycles back: 1->2->3->1 (3 moves = back to 1)
      assert Driver.current_stop(d1) == 1
      assert Driver.current_stop(d2) == 1
    end
  end

  describe "Simulation.step_stream/1" do
    test "generates infinite stream of states" do
      drivers = [
        Driver.new("D1", [1, 2], [:r1]),
        Driver.new("D2", [2, 1], [:r2])
      ]

      stream = Simulation.step_stream(drivers)
      states = Enum.take(stream, 5)

      assert length(states) == 5
    end
  end

  describe "Simulation.run_with_history/1" do
    test "returns history of simulation" do
      drivers = [
        Driver.new("D1", [3, 1, 2, 3], [:r1]),
        Driver.new("D2", [3, 2, 3, 1], [:r2])
      ]

      result = Simulation.run_with_history(drivers)

      assert is_list(result.history)
      assert length(result.history) > 1
      assert is_integer(result.steps)
      assert is_boolean(result.converged)
    end
  end

  # ============================================================
  # Solver Tests
  # ============================================================

  describe "Solver.solve/1" do
    test "solves problem from routes list" do
      routes = [[3, 1, 2, 3], [3, 2, 3, 1], [4, 2, 3, 4, 5]]
      result = Solver.solve(routes)

      assert is_integer(result)
      assert result > 0
    end

    test "returns :never for non-meeting routes" do
      routes = [[1], [2]]
      assert Solver.solve(routes) == :never
    end
  end

  describe "Solver.parse_and_solve/1" do
    test "parses input and solves" do
      input = """
      3 1 2 3
      3 2 3 1
      4 2 3 4 5
      """

      result = Solver.parse_and_solve(input)
      assert is_integer(result)
      assert result > 0
    end

    test "handles single line input" do
      input = "1 2 3"
      result = Solver.parse_and_solve(input)
      # Single driver always has all their own rumors
      # Actually with one driver, run_until_spread checks after first drive
      # and a single driver always has all rumors shared (with itself)
      assert result == 1
    end
  end

  describe "Solver.solve_verbose/1" do
    test "returns detailed solution info" do
      routes = [[3, 1, 2, 3], [3, 2, 3, 1]]
      result = Solver.solve_verbose(routes)

      assert result.routes == routes
      assert result.driver_count == 2
      assert result.rumor_count == 2
      assert is_integer(result.steps) or result.steps == 0
      assert is_boolean(result.converged)
      assert is_map(result.final_state)
    end
  end

  # ============================================================
  # Examples Tests
  # ============================================================

  describe "Examples" do
    test "example_never_meet returns :never" do
      assert Examples.example_never_meet() == :never
    end

    test "example_three_drivers returns step count" do
      result = Examples.example_three_drivers()
      assert is_integer(result)
      assert result > 0
      assert result < 480
    end

    test "example_instant_meet converges quickly" do
      result = Examples.example_instant_meet()
      # All start at same stop, should converge in 1 step
      assert is_integer(result)
      assert result <= 5  # Should be very fast
    end

    test "solve_from_input works" do
      result = Examples.solve_from_input()
      assert is_integer(result)
      assert result > 0
    end
  end

  # ============================================================
  # Integration Tests
  # ============================================================

  describe "Integration" do
    test "complete simulation workflow" do
      # Create drivers with routes that will meet
      # Using the same routes as example_three_drivers which is proven to work
      drivers = [
        Driver.new("D1", [3, 1, 2, 3], [:gossip_1]),
        Driver.new("D2", [3, 2, 3, 1], [:gossip_2]),
        Driver.new("D3", [4, 2, 3, 4, 5], [:gossip_3])
      ]

      # Check initial state
      assert World.count_unique_rumors(drivers) == 3
      refute World.all_rumors_shared?(drivers)

      # Run simulation
      steps = Simulation.run_until_spread(drivers)

      # Verify convergence
      assert is_integer(steps)
      assert steps > 0

      # Run steps and verify final state
      final = Simulation.run_steps(drivers, steps)
      assert World.all_rumors_shared?(final)

      # Each driver should have all 3 rumors
      Enum.each(final, fn driver ->
        assert MapSet.size(driver.rumors) == 3
      end)
    end

    test "large scale simulation" do
      # 10 drivers with different routes
      routes = [
        [1, 2, 3, 4, 5],
        [5, 4, 3, 2, 1],
        [1, 3, 5, 2, 4],
        [2, 4, 1, 3, 5],
        [3, 1, 4, 2, 5],
        [1, 5, 2, 4, 3],
        [4, 2, 5, 3, 1],
        [5, 1, 4, 2, 3],
        [2, 3, 4, 5, 1],
        [3, 5, 1, 4, 2]
      ]

      result = Solver.solve(routes)

      # Should eventually converge
      assert is_integer(result)
      assert result > 0
      assert result < 480
    end
  end
end
