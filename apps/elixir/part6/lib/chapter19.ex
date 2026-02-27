defmodule Chapter19 do
  @moduledoc """
  # Chapter 19: Wa-Tor シミュレーション

  Wa-Tor（トーラス状の世界）は、捕食者（サメ）と被食者（魚）の
  生態系シミュレーションです。無限ループするトーラス状の世界で
  魚とサメが移動、繁殖、捕食を行います。

  ## 主なトピック

  1. トーラス状のワールド
  2. 魚と shark の行動（移動、繁殖）
  3. 捕食と体力管理
  4. シミュレーション実行
  """

  # ============================================================
  # 1. 設定
  # ============================================================

  defmodule Config do
    @moduledoc "シミュレーションの設定"

    @fish_reproduction_age 3
    @shark_reproduction_age 10
    @shark_starting_health 5
    @shark_max_health 20
    @shark_eating_health 3
    @shark_reproduction_health 3

    def fish_reproduction_age, do: @fish_reproduction_age
    def shark_reproduction_age, do: @shark_reproduction_age
    def shark_starting_health, do: @shark_starting_health
    def shark_max_health, do: @shark_max_health
    def shark_eating_health, do: @shark_eating_health
    def shark_reproduction_health, do: @shark_reproduction_health
  end

  # ============================================================
  # 2. セルタイプ
  # ============================================================

  defmodule Cell do
    @moduledoc "セルの基本構造"

    @type cell_type :: :water | :fish | :shark

    def water, do: %{type: :water}
    def is_water?(%{type: :water}), do: true
    def is_water?(_), do: false

    def display(%{type: :water}), do: "~"
    def display(%{type: :fish}), do: "f"
    def display(%{type: :shark}), do: "S"
  end

  # ============================================================
  # 3. 魚
  # ============================================================

  defmodule Fish do
    @moduledoc "魚（被食者）"

    alias Chapter19.{Cell, Config}

    def new do
      %{type: :fish, age: 0}
    end

    def is?(%{type: :fish}), do: true
    def is?(_), do: false

    def increment_age(fish) do
      %{fish | age: fish.age + 1}
    end

    def can_reproduce?(fish) do
      fish.age >= Config.fish_reproduction_age()
    end

    def reproduce(fish) do
      if can_reproduce?(fish) do
        {%{fish | age: 0}, new()}
      else
        nil
      end
    end
  end

  # ============================================================
  # 4. サメ
  # ============================================================

  defmodule Shark do
    @moduledoc "サメ（捕食者）"

    alias Chapter19.{Cell, Config}

    def new do
      %{type: :shark, age: 0, health: Config.shark_starting_health()}
    end

    def is?(%{type: :shark}), do: true
    def is?(_), do: false

    def increment_age(shark) do
      %{shark | age: shark.age + 1}
    end

    def decrement_health(shark) do
      %{shark | health: shark.health - 1}
    end

    def feed(shark) do
      new_health = min(Config.shark_max_health(), shark.health + Config.shark_eating_health())
      %{shark | health: new_health}
    end

    def is_alive?(shark) do
      shark.health > 0
    end

    def can_reproduce?(shark) do
      shark.age >= Config.shark_reproduction_age() and
        shark.health >= Config.shark_reproduction_health()
    end

    def reproduce(shark) do
      if can_reproduce?(shark) do
        half_health = div(shark.health, 2)
        parent = %{shark | age: 0, health: half_health}
        child = %{new() | health: half_health}
        {parent, child}
      else
        nil
      end
    end
  end

  # ============================================================
  # 5. ワールド
  # ============================================================

  defmodule World do
    @moduledoc "トーラス状のワールド"

    alias Chapter19.{Cell, Fish, Shark}

    defstruct [:width, :height, :cells]

    @doc "ワールドを作成"
    def new(width, height) do
      cells =
        for x <- 0..(width - 1),
            y <- 0..(height - 1),
            into: %{} do
          {{x, y}, Cell.water()}
        end

      %__MODULE__{width: width, height: height, cells: cells}
    end

    @doc "セルを取得"
    def get_cell(%__MODULE__{cells: cells}, {x, y}) do
      Map.get(cells, {x, y})
    end

    @doc "セルを設定"
    def set_cell(%__MODULE__{cells: cells} = world, {x, y}, cell) do
      %{world | cells: Map.put(cells, {x, y}, cell)}
    end

    @doc "座標をトーラス上でラップ"
    def wrap(%__MODULE__{width: w, height: h}, {x, y}) do
      {rem(x + w, w), rem(y + h, h)}
    end

    @doc "隣接セルの座標を取得（8方向）"
    def neighbors(world, {x, y}) do
      deltas = for dx <- [-1, 0, 1], dy <- [-1, 0, 1], not (dx == 0 and dy == 0), do: {dx, dy}

      Enum.map(deltas, fn {dx, dy} ->
        wrap(world, {x + dx, y + dy})
      end)
    end

    @doc "魚を配置"
    def set_fish(world, loc) do
      set_cell(world, loc, Fish.new())
    end

    @doc "サメを配置"
    def set_shark(world, loc) do
      set_cell(world, loc, Shark.new())
    end

    @doc "ランダムに魚とサメを配置"
    def populate_random(world, fish_count, shark_count) do
      all_locs = Map.keys(world.cells)
      shuffled = Enum.shuffle(all_locs)

      fish_locs = Enum.take(shuffled, fish_count)
      shark_locs = Enum.take(Enum.drop(shuffled, fish_count), shark_count)

      world
      |> then(fn w -> Enum.reduce(fish_locs, w, &set_fish(&2, &1)) end)
      |> then(fn w -> Enum.reduce(shark_locs, w, &set_shark(&2, &1)) end)
    end

    @doc "魚の数をカウント"
    def count_fish(%__MODULE__{cells: cells}) do
      cells |> Map.values() |> Enum.count(&Fish.is?/1)
    end

    @doc "サメの数をカウント"
    def count_sharks(%__MODULE__{cells: cells}) do
      cells |> Map.values() |> Enum.count(&Shark.is?/1)
    end

    @doc "水の数をカウント"
    def count_water(%__MODULE__{cells: cells}) do
      cells |> Map.values() |> Enum.count(&Cell.is_water?/1)
    end

    @doc "統計情報を取得"
    def statistics(world) do
      %{
        fish: count_fish(world),
        sharks: count_sharks(world),
        water: count_water(world),
        total: map_size(world.cells)
      }
    end

    @doc "ワールドを文字列として表示"
    def display(%__MODULE__{width: w, height: h} = world) do
      rows = for y <- 0..(h - 1) do
        row = for x <- 0..(w - 1) do
          Cell.display(get_cell(world, {x, y}))
        end
        Enum.join(row, "")
      end
      Enum.join(rows, "\n")
    end
  end

  # ============================================================
  # 6. シミュレーション
  # ============================================================

  defmodule Simulation do
    @moduledoc "シミュレーション実行"

    alias Chapter19.{Cell, Fish, Shark, World}

    @doc "1ステップ実行"
    def tick(world) do
      # 全セルをシャッフルして処理（順序のバイアスを避ける）
      locs = Enum.shuffle(Map.keys(world.cells))

      Enum.reduce(locs, world, fn loc, acc_world ->
        tick_cell(acc_world, loc)
      end)
    end

    @doc "複数ステップ実行"
    def run(world, steps) do
      Enum.reduce(1..steps, world, fn _, acc -> tick(acc) end)
    end

    @doc "履歴付きで実行"
    def run_with_history(world, steps) do
      {history, final} =
        Enum.reduce(1..steps, {[world], world}, fn _, {hist, w} ->
          next = tick(w)
          {[next | hist], next}
        end)

      Enum.reverse(history)
    end

    @doc "統計履歴付きで実行"
    def run_with_stats(world, steps) do
      {stats, final} =
        Enum.reduce(0..steps, {[], world}, fn step, {acc_stats, w} ->
          stat = Map.put(World.statistics(w), :step, step)
          if step == steps do
            {[stat | acc_stats], w}
          else
            next = tick(w)
            {[stat | acc_stats], next}
          end
        end)

      %{
        final_world: final,
        statistics: Enum.reverse(stats)
      }
    end

    # セルの更新
    defp tick_cell(world, loc) do
      cell = World.get_cell(world, loc)

      cond do
        Fish.is?(cell) -> tick_fish(world, loc, cell)
        Shark.is?(cell) -> tick_shark(world, loc, cell)
        true -> world
      end
    end

    # 魚の更新
    defp tick_fish(world, loc, fish) do
      aged_fish = Fish.increment_age(fish)

      # 繁殖を試みる
      case Fish.reproduce(aged_fish) do
        {parent, child} ->
          case find_empty_neighbor(world, loc) do
            nil -> World.set_cell(world, loc, aged_fish)
            empty_loc ->
              world
              |> World.set_cell(loc, parent)
              |> World.set_cell(empty_loc, child)
          end

        nil ->
          # 移動を試みる
          case find_empty_neighbor(world, loc) do
            nil -> World.set_cell(world, loc, aged_fish)
            empty_loc ->
              world
              |> World.set_cell(loc, Cell.water())
              |> World.set_cell(empty_loc, aged_fish)
          end
      end
    end

    # サメの更新
    defp tick_shark(world, loc, shark) do
      # 体力チェック - 既に死んでいる場合は水に
      if not Shark.is_alive?(shark) do
        World.set_cell(world, loc, Cell.water())
      else
        aged_shark = shark |> Shark.increment_age() |> Shark.decrement_health()

        # 体力が尽きたら死亡
        if not Shark.is_alive?(aged_shark) do
          World.set_cell(world, loc, Cell.water())
        else
          # 捕食を試みる
          case find_fish_neighbor(world, loc) do
            nil ->
              # 魚がいない場合、繁殖または移動
              handle_shark_movement(world, loc, aged_shark)

            fish_loc ->
              fed_shark = Shark.feed(aged_shark)
              world
              |> World.set_cell(loc, Cell.water())
              |> World.set_cell(fish_loc, fed_shark)
          end
        end
      end
    end

    defp handle_shark_movement(world, loc, shark) do
      # 繁殖を試みる
      case Shark.reproduce(shark) do
        {parent, child} ->
          case find_empty_neighbor(world, loc) do
            nil -> World.set_cell(world, loc, shark)
            empty_loc ->
              world
              |> World.set_cell(loc, parent)
              |> World.set_cell(empty_loc, child)
          end

        nil ->
          # 移動を試みる
          case find_empty_neighbor(world, loc) do
            nil -> World.set_cell(world, loc, shark)
            empty_loc ->
              world
              |> World.set_cell(loc, Cell.water())
              |> World.set_cell(empty_loc, shark)
          end
      end
    end

    # 空の隣接セルを探す
    defp find_empty_neighbor(world, loc) do
      world
      |> World.neighbors(loc)
      |> Enum.filter(fn neighbor_loc ->
        Cell.is_water?(World.get_cell(world, neighbor_loc))
      end)
      |> case do
        [] -> nil
        neighbors -> Enum.random(neighbors)
      end
    end

    # 魚がいる隣接セルを探す
    defp find_fish_neighbor(world, loc) do
      world
      |> World.neighbors(loc)
      |> Enum.filter(fn neighbor_loc ->
        Fish.is?(World.get_cell(world, neighbor_loc))
      end)
      |> case do
        [] -> nil
        neighbors -> Enum.random(neighbors)
      end
    end

    # 早期リターン用のマクロ的なパターン
    defp return(value), do: value
  end

  # ============================================================
  # 7. サンプルシナリオ
  # ============================================================

  defmodule Examples do
    @moduledoc "サンプルシナリオ"

    alias Chapter19.{World, Simulation}

    @doc "小さな世界で短いシミュレーション"
    def small_simulation do
      world = World.new(10, 10)
              |> World.populate_random(20, 5)

      result = Simulation.run_with_stats(world, 50)
      result
    end

    @doc "中規模のシミュレーション"
    def medium_simulation do
      world = World.new(20, 20)
              |> World.populate_random(80, 20)

      Simulation.run_with_stats(world, 100)
    end

    @doc "魚だけのシミュレーション（増殖テスト）"
    def fish_only_simulation do
      world = World.new(10, 10)
              |> World.populate_random(10, 0)

      Simulation.run_with_stats(world, 30)
    end

    @doc "サメだけのシミュレーション（死滅テスト）"
    def shark_only_simulation do
      world = World.new(10, 10)
              |> World.populate_random(0, 10)

      Simulation.run_with_stats(world, 20)
    end

    @doc "バランスの取れたシミュレーション"
    def balanced_simulation do
      world = World.new(30, 30)
              |> World.populate_random(200, 30)

      Simulation.run_with_stats(world, 200)
    end
  end
end
