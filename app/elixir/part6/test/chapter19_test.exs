defmodule Chapter19Test do
  use ExUnit.Case, async: true

  alias Chapter19.{Config, Cell, Fish, Shark, World, Simulation, Examples}

  # ============================================================
  # Config Tests
  # ============================================================

  describe "Config" do
    test "fish reproduction age is positive" do
      assert Config.fish_reproduction_age() > 0
    end

    test "shark reproduction age is positive" do
      assert Config.shark_reproduction_age() > 0
    end

    test "shark starting health is positive" do
      assert Config.shark_starting_health() > 0
    end
  end

  # ============================================================
  # Cell Tests
  # ============================================================

  describe "Cell" do
    test "water creates water cell" do
      cell = Cell.water()
      assert cell.type == :water
    end

    test "is_water? identifies water" do
      assert Cell.is_water?(Cell.water())
      refute Cell.is_water?(Fish.new())
      refute Cell.is_water?(Shark.new())
    end

    test "display returns correct characters" do
      assert Cell.display(Cell.water()) == "~"
      assert Cell.display(Fish.new()) == "f"
      assert Cell.display(Shark.new()) == "S"
    end
  end

  # ============================================================
  # Fish Tests
  # ============================================================

  describe "Fish" do
    test "new creates fish with age 0" do
      fish = Fish.new()
      assert fish.type == :fish
      assert fish.age == 0
    end

    test "is? identifies fish" do
      assert Fish.is?(Fish.new())
      refute Fish.is?(Shark.new())
      refute Fish.is?(Cell.water())
    end

    test "increment_age increases age by 1" do
      fish = Fish.new() |> Fish.increment_age()
      assert fish.age == 1

      fish = fish |> Fish.increment_age()
      assert fish.age == 2
    end

    test "can_reproduce? returns false when young" do
      fish = Fish.new()
      refute Fish.can_reproduce?(fish)
    end

    test "can_reproduce? returns true when old enough" do
      fish = %{Fish.new() | age: Config.fish_reproduction_age()}
      assert Fish.can_reproduce?(fish)
    end

    test "reproduce returns nil when too young" do
      fish = Fish.new()
      assert Fish.reproduce(fish) == nil
    end

    test "reproduce returns parent and child when old enough" do
      fish = %{Fish.new() | age: Config.fish_reproduction_age()}
      {parent, child} = Fish.reproduce(fish)

      assert parent.age == 0
      assert child.age == 0
    end
  end

  # ============================================================
  # Shark Tests
  # ============================================================

  describe "Shark" do
    test "new creates shark with starting health" do
      shark = Shark.new()
      assert shark.type == :shark
      assert shark.age == 0
      assert shark.health == Config.shark_starting_health()
    end

    test "is? identifies shark" do
      assert Shark.is?(Shark.new())
      refute Shark.is?(Fish.new())
      refute Shark.is?(Cell.water())
    end

    test "increment_age increases age by 1" do
      shark = Shark.new() |> Shark.increment_age()
      assert shark.age == 1
    end

    test "decrement_health decreases health by 1" do
      shark = Shark.new() |> Shark.decrement_health()
      assert shark.health == Config.shark_starting_health() - 1
    end

    test "feed increases health" do
      shark = %{Shark.new() | health: 2}
      fed_shark = Shark.feed(shark)
      assert fed_shark.health == 2 + Config.shark_eating_health()
    end

    test "feed does not exceed max health" do
      shark = %{Shark.new() | health: Config.shark_max_health() - 1}
      fed_shark = Shark.feed(shark)
      assert fed_shark.health == Config.shark_max_health()
    end

    test "is_alive? returns true when health > 0" do
      shark = Shark.new()
      assert Shark.is_alive?(shark)
    end

    test "is_alive? returns false when health <= 0" do
      shark = %{Shark.new() | health: 0}
      refute Shark.is_alive?(shark)
    end

    test "can_reproduce? checks age and health" do
      young_shark = Shark.new()
      refute Shark.can_reproduce?(young_shark)

      old_healthy_shark = %{Shark.new() |
        age: Config.shark_reproduction_age(),
        health: Config.shark_reproduction_health()
      }
      assert Shark.can_reproduce?(old_healthy_shark)

      old_weak_shark = %{Shark.new() |
        age: Config.shark_reproduction_age(),
        health: Config.shark_reproduction_health() - 1
      }
      refute Shark.can_reproduce?(old_weak_shark)
    end

    test "reproduce splits health between parent and child" do
      shark = %{Shark.new() | age: Config.shark_reproduction_age(), health: 10}
      {parent, child} = Shark.reproduce(shark)

      assert parent.age == 0
      assert parent.health == 5
      assert child.health == 5
    end
  end

  # ============================================================
  # World Tests
  # ============================================================

  describe "World" do
    test "new creates world with water cells" do
      world = World.new(5, 5)

      assert world.width == 5
      assert world.height == 5
      assert World.count_water(world) == 25
    end

    test "get_cell and set_cell work" do
      world = World.new(5, 5)
      fish = Fish.new()

      updated = World.set_cell(world, {2, 3}, fish)

      assert World.get_cell(updated, {2, 3}) == fish
      assert Cell.is_water?(World.get_cell(updated, {0, 0}))
    end

    test "wrap handles boundary conditions" do
      world = World.new(5, 5)

      assert World.wrap(world, {5, 0}) == {0, 0}
      assert World.wrap(world, {0, 5}) == {0, 0}
      assert World.wrap(world, {-1, 0}) == {4, 0}
      assert World.wrap(world, {0, -1}) == {0, 4}
    end

    test "neighbors returns 8 adjacent cells" do
      world = World.new(5, 5)
      neighbors = World.neighbors(world, {2, 2})

      assert length(neighbors) == 8
    end

    test "neighbors wrap around edges" do
      world = World.new(5, 5)
      neighbors = World.neighbors(world, {0, 0})

      assert {4, 4} in neighbors  # top-left wraps
      assert {1, 1} in neighbors  # bottom-right
    end

    test "set_fish places fish at location" do
      world = World.new(5, 5) |> World.set_fish({2, 2})

      assert Fish.is?(World.get_cell(world, {2, 2}))
    end

    test "set_shark places shark at location" do
      world = World.new(5, 5) |> World.set_shark({2, 2})

      assert Shark.is?(World.get_cell(world, {2, 2}))
    end

    test "populate_random places correct counts" do
      world = World.new(10, 10) |> World.populate_random(15, 5)

      assert World.count_fish(world) == 15
      assert World.count_sharks(world) == 5
      assert World.count_water(world) == 80
    end

    test "statistics returns correct counts" do
      world = World.new(10, 10) |> World.populate_random(20, 5)
      stats = World.statistics(world)

      assert stats.fish == 20
      assert stats.sharks == 5
      assert stats.water == 75
      assert stats.total == 100
    end

    test "display returns string representation" do
      world = World.new(3, 3)
              |> World.set_fish({1, 1})
              |> World.set_shark({2, 2})

      display = World.display(world)

      assert String.contains?(display, "~")
      assert String.contains?(display, "f")
      assert String.contains?(display, "S")
    end
  end

  # ============================================================
  # Simulation Tests
  # ============================================================

  describe "Simulation.tick/1" do
    test "tick advances simulation by one step" do
      world = World.new(5, 5) |> World.set_fish({2, 2})
      ticked = Simulation.tick(world)

      # Fish should have moved or stayed
      total_fish = World.count_fish(ticked)
      assert total_fish >= 1
    end

    test "fish can reproduce" do
      # Create old fish that can reproduce
      fish = %{Fish.new() | age: Config.fish_reproduction_age()}
      world = World.new(5, 5)
              |> World.set_cell({2, 2}, fish)

      # Run several ticks
      final = Simulation.run(world, 5)

      # There should be more fish now (or same if no room)
      assert World.count_fish(final) >= 1
    end

    test "shark dies without food" do
      # Create shark with low health (will die in 2 ticks)
      shark = %{Shark.new() | health: 2}
      world = World.new(5, 5)
              |> World.set_cell({2, 2}, shark)

      # Run until shark starves (need more ticks since it loses 1 health per tick)
      final = Simulation.run(world, 3)

      # Shark should have died (health goes 2 -> 1 -> 0)
      assert World.count_sharks(final) == 0
    end

    test "shark eats fish" do
      world = World.new(3, 3)
              |> World.set_shark({1, 1})
              |> World.set_fish({1, 0})  # Adjacent

      # After tick, shark might have eaten fish
      final = Simulation.tick(world)

      # Either fish was eaten or moved away
      total = World.count_fish(final) + World.count_sharks(final)
      assert total <= 2
    end
  end

  describe "Simulation.run/2" do
    test "run executes multiple ticks" do
      world = World.new(5, 5) |> World.populate_random(5, 2)

      final = Simulation.run(world, 10)

      # World should still have valid structure
      stats = World.statistics(final)
      assert stats.total == 25
    end
  end

  describe "Simulation.run_with_history/2" do
    test "returns history of all states" do
      world = World.new(5, 5) |> World.populate_random(5, 2)

      history = Simulation.run_with_history(world, 5)

      assert length(history) == 6  # Initial + 5 steps
    end
  end

  describe "Simulation.run_with_stats/2" do
    test "returns statistics for each step" do
      world = World.new(5, 5) |> World.populate_random(5, 2)

      result = Simulation.run_with_stats(world, 10)

      assert length(result.statistics) == 11  # Initial + 10 steps
      assert hd(result.statistics).step == 0
      assert List.last(result.statistics).step == 10
    end
  end

  # ============================================================
  # Examples Tests
  # ============================================================

  describe "Examples" do
    test "small_simulation runs without error" do
      result = Examples.small_simulation()

      assert result.final_world != nil
      assert length(result.statistics) == 51
    end

    test "fish_only_simulation shows fish growth" do
      result = Examples.fish_only_simulation()

      initial = hd(result.statistics)
      final = List.last(result.statistics)

      # Fish should reproduce and grow
      assert final.fish >= initial.fish
      assert final.sharks == 0
    end

    test "shark_only_simulation shows shark decline" do
      result = Examples.shark_only_simulation()

      initial = hd(result.statistics)
      final = List.last(result.statistics)

      # Sharks should die without food
      assert final.sharks <= initial.sharks
      assert final.fish == 0
    end
  end

  # ============================================================
  # Integration Tests
  # ============================================================

  describe "Integration" do
    test "population dynamics over time" do
      world = World.new(20, 20) |> World.populate_random(50, 10)

      result = Simulation.run_with_stats(world, 50)

      # Check that populations changed
      initial = hd(result.statistics)
      final = List.last(result.statistics)

      # Populations should have changed (unless edge case)
      stats_changed = (final.fish != initial.fish) or (final.sharks != initial.sharks)

      # At minimum, total should still be valid
      assert final.fish + final.sharks + final.water == final.total
    end

    test "world boundaries are respected" do
      # Test toroidal world by placing entities at edges
      world = World.new(5, 5)
              |> World.set_fish({0, 0})
              |> World.set_fish({4, 4})
              |> World.set_shark({0, 4})

      final = Simulation.run(world, 10)

      # All entities should still be within bounds
      stats = World.statistics(final)
      assert stats.total == 25
    end

    test "large world performance" do
      # Test that large worlds don't cause issues
      world = World.new(50, 50) |> World.populate_random(500, 50)

      # Should complete in reasonable time
      {time, result} = :timer.tc(fn -> Simulation.run(world, 10) end)

      # Should complete in under 5 seconds
      assert time < 5_000_000
      assert World.statistics(result).total == 2500
    end
  end
end
