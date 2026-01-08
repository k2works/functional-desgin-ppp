defmodule Chapter15 do
  @moduledoc """
  # Chapter 15: ゴシップ好きなバスの運転手

  バス運転手が停留所で噂を共有するシミュレーションです。
  無限ストリーム（Stream.cycle）を使って循環ルートを表現し、
  集合演算（MapSet）で噂の伝播をモデル化します。

  ## 主なトピック

  1. ドライバーの作成と移動
  2. 停留所での噂の伝播
  3. シミュレーションの実行
  4. 収束判定
  """

  # ============================================================
  # 1. ドライバーの作成と操作
  # ============================================================

  defmodule Driver do
    @moduledoc "バス運転手の構造体"

    defstruct [:name, :route, :rumors]

    @type t :: %__MODULE__{
      name: String.t(),
      route: Enumerable.t(),
      rumors: MapSet.t()
    }

    @doc """
    ドライバーを作成する。

    ## Examples

        iex> driver = Chapter15.Driver.new("Alice", [1, 2, 3], [:rumor_a])
        iex> driver.name
        "Alice"
        iex> driver.rumors
        MapSet.new([:rumor_a])
    """
    def new(name, route, rumors) when is_list(route) do
      %__MODULE__{
        name: name,
        route: Stream.cycle(route),
        rumors: MapSet.new(rumors)
      }
    end

    @doc """
    ドライバーの現在の停留所を取得。

    ## Examples

        iex> driver = Chapter15.Driver.new("Alice", [1, 2, 3], [])
        iex> Chapter15.Driver.current_stop(driver)
        1
    """
    def current_stop(%__MODULE__{route: route}) do
      Enum.at(route, 0)
    end

    @doc """
    ドライバーを次の停留所に移動。

    ## Examples

        iex> driver = Chapter15.Driver.new("Alice", [1, 2, 3], [])
        iex> moved = Chapter15.Driver.move(driver)
        iex> Chapter15.Driver.current_stop(moved)
        2
    """
    def move(%__MODULE__{route: route} = driver) do
      %{driver | route: Stream.drop(route, 1)}
    end

    @doc """
    ドライバーの噂を更新。
    """
    def set_rumors(%__MODULE__{} = driver, rumors) do
      %{driver | rumors: rumors}
    end

    @doc """
    ドライバーのサマリーを取得。
    """
    def summary(%__MODULE__{} = driver) do
      %{
        name: driver.name,
        current_stop: current_stop(driver),
        rumor_count: MapSet.size(driver.rumors)
      }
    end
  end

  # ============================================================
  # 2. ワールド（世界）の操作
  # ============================================================

  defmodule World do
    @moduledoc "シミュレーションワールド"

    alias Chapter15.Driver

    @doc """
    全ドライバーを次の停留所に移動。

    ## Examples

        iex> drivers = [
        ...>   Chapter15.Driver.new("Alice", [1, 2], []),
        ...>   Chapter15.Driver.new("Bob", [3, 4], [])
        ...> ]
        iex> moved = Chapter15.World.move_drivers(drivers)
        iex> Chapter15.Driver.current_stop(hd(moved))
        2
    """
    def move_drivers(drivers) do
      Enum.map(drivers, &Driver.move/1)
    end

    @doc """
    各停留所にいるドライバーをマップとして取得。

    ## Examples

        iex> drivers = [
        ...>   Chapter15.Driver.new("Alice", [1, 2], []),
        ...>   Chapter15.Driver.new("Bob", [1, 3], []),
        ...>   Chapter15.Driver.new("Carol", [2, 3], [])
        ...> ]
        iex> stops = Chapter15.World.get_stops(drivers)
        iex> length(Map.get(stops, 1, []))
        2
    """
    def get_stops(drivers) do
      Enum.reduce(drivers, %{}, fn driver, stops ->
        stop = Driver.current_stop(driver)
        Map.update(stops, stop, [driver], &[driver | &1])
      end)
    end

    @doc """
    同じ停留所にいるドライバー間で噂を共有。
    """
    def merge_rumors(drivers) when is_list(drivers) do
      all_rumors = Enum.reduce(drivers, MapSet.new(), fn driver, acc ->
        MapSet.union(acc, driver.rumors)
      end)

      Enum.map(drivers, &Driver.set_rumors(&1, all_rumors))
    end

    @doc """
    全停留所で噂を伝播。
    """
    def spread_rumors(drivers) do
      stops = get_stops(drivers)

      stops
      |> Map.values()
      |> Enum.flat_map(&merge_rumors/1)
    end

    @doc """
    1ステップ分のシミュレーション。
    1. 全ドライバーを移動
    2. 同じ停留所にいるドライバー間で噂を共有
    """
    def drive(drivers) do
      drivers
      |> move_drivers()
      |> spread_rumors()
    end

    @doc """
    全ドライバーが同じ噂を持っているか確認。

    ## Examples

        iex> shared = [
        ...>   Chapter15.Driver.new("Alice", [1], [:a, :b]),
        ...>   Chapter15.Driver.new("Bob", [2], [:a, :b])
        ...> ]
        iex> Chapter15.World.all_rumors_shared?(shared)
        true

        iex> not_shared = [
        ...>   Chapter15.Driver.new("Alice", [1], [:a]),
        ...>   Chapter15.Driver.new("Bob", [2], [:b])
        ...> ]
        iex> Chapter15.World.all_rumors_shared?(not_shared)
        false
    """
    def all_rumors_shared?(drivers) do
      rumors_list = Enum.map(drivers, & &1.rumors)

      case rumors_list do
        [] -> true
        [first | rest] -> Enum.all?(rest, &(&1 == first))
      end
    end

    @doc """
    ワールド内のユニークな噂の総数。
    """
    def count_unique_rumors(drivers) do
      drivers
      |> Enum.reduce(MapSet.new(), fn driver, acc ->
        MapSet.union(acc, driver.rumors)
      end)
      |> MapSet.size()
    end

    @doc """
    ワールドの状態をサマリーとして取得。
    """
    def summary(drivers) do
      %{
        drivers: Enum.map(drivers, &Driver.summary/1),
        total_unique_rumors: count_unique_rumors(drivers),
        all_shared?: all_rumors_shared?(drivers)
      }
    end
  end

  # ============================================================
  # 3. シミュレーション
  # ============================================================

  defmodule Simulation do
    @moduledoc "シミュレーション実行"

    alias Chapter15.World

    @max_steps 480  # 8時間（480分）

    @doc """
    全ての噂が共有されるまでシミュレーション。
    480分（8時間）以内に共有されなければ :never を返す。

    ## Examples

        iex> world = [
        ...>   Chapter15.Driver.new("D1", [3, 1, 2, 3], [:r1]),
        ...>   Chapter15.Driver.new("D2", [3, 2, 3, 1], [:r2]),
        ...>   Chapter15.Driver.new("D3", [4, 2, 3, 4, 5], [:r3])
        ...> ]
        iex> result = Chapter15.Simulation.run_until_spread(world)
        iex> is_integer(result) and result < 480
        true
    """
    def run_until_spread(drivers) do
      run_until_spread(World.drive(drivers), 1)
    end

    defp run_until_spread(_drivers, step) when step > @max_steps, do: :never
    defp run_until_spread(drivers, step) do
      if World.all_rumors_shared?(drivers) do
        step
      else
        run_until_spread(World.drive(drivers), step + 1)
      end
    end

    @doc """
    指定ステップ数だけシミュレーションを実行。
    """
    def run_steps(drivers, steps) do
      Enum.reduce(1..steps, drivers, fn _, acc -> World.drive(acc) end)
    end

    @doc """
    シミュレーションの各ステップを生成するストリーム。
    """
    def step_stream(drivers) do
      Stream.iterate(drivers, &World.drive/1)
    end

    @doc """
    シミュレーションを実行し、各ステップの状態を記録。
    """
    def run_with_history(drivers, max_steps \\ @max_steps) do
      {history, final_step} =
        Enum.reduce_while(1..max_steps, {[drivers], 0}, fn step, {hist, _} ->
          current = hd(hist)
          next = World.drive(current)

          if World.all_rumors_shared?(next) do
            {:halt, {[next | hist], step}}
          else
            {:cont, {[next | hist], step}}
          end
        end)

      %{
        history: Enum.reverse(history),
        steps: final_step,
        converged: World.all_rumors_shared?(hd(history))
      }
    end
  end

  # ============================================================
  # 4. 問題ソルバー
  # ============================================================

  defmodule Solver do
    @moduledoc "ゴシップ問題のソルバー"

    alias Chapter15.{Driver, Simulation}

    @doc """
    ルートのリストから問題を解く。

    ## Examples

        iex> routes = [[3, 1, 2, 3], [3, 2, 3, 1], [4, 2, 3, 4, 5]]
        iex> result = Chapter15.Solver.solve(routes)
        iex> is_integer(result) and result > 0
        true
    """
    def solve(routes) when is_list(routes) do
      drivers =
        routes
        |> Enum.with_index(1)
        |> Enum.map(fn {route, idx} ->
          rumor = String.to_atom("rumor_#{idx}")
          Driver.new("Driver_#{idx}", route, [rumor])
        end)

      Simulation.run_until_spread(drivers)
    end

    @doc """
    問題の入力をパースして解く。
    入力形式: "1 2 3\n4 5 6\n7 8"（行ごとにルート）
    """
    def parse_and_solve(input) when is_binary(input) do
      routes =
        input
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(fn line ->
          line
          |> String.split()
          |> Enum.map(&String.to_integer/1)
        end)

      solve(routes)
    end

    @doc """
    デバッグ用: 問題を解きながら詳細を出力。
    """
    def solve_verbose(routes) when is_list(routes) do
      drivers =
        routes
        |> Enum.with_index(1)
        |> Enum.map(fn {route, idx} ->
          rumor = String.to_atom("rumor_#{idx}")
          Driver.new("Driver_#{idx}", route, [rumor])
        end)

      result = Simulation.run_with_history(drivers)

      %{
        routes: routes,
        driver_count: length(drivers),
        rumor_count: length(routes),
        steps: result.steps,
        converged: result.converged,
        final_state: Chapter15.World.summary(List.last(result.history))
      }
    end
  end

  # ============================================================
  # 5. サンプルデータ
  # ============================================================

  defmodule Examples do
    @moduledoc "サンプル問題"

    alias Chapter15.{Driver, Simulation, Solver}

    @doc """
    例1: 2人のドライバーが出会わないケース。
    """
    def example_never_meet do
      drivers = [
        Driver.new("D1", [1, 2], [:r1]),
        Driver.new("D2", [3, 4], [:r2])
      ]

      Simulation.run_until_spread(drivers)
    end

    @doc """
    例2: 3人のドライバーが最終的に全噂を共有するケース。
    """
    def example_three_drivers do
      drivers = [
        Driver.new("D1", [3, 1, 2, 3], [:r1]),
        Driver.new("D2", [3, 2, 3, 1], [:r2]),
        Driver.new("D3", [4, 2, 3, 4, 5], [:r3])
      ]

      Simulation.run_until_spread(drivers)
    end

    @doc """
    例3: 1ステップで全員が出会うケース。
    """
    def example_instant_meet do
      drivers = [
        Driver.new("D1", [1, 2], [:r1]),
        Driver.new("D2", [1, 3], [:r2]),
        Driver.new("D3", [1, 4], [:r3])
      ]

      # 全員が最初から停留所1にいる
      # 移動後、D1->2, D2->3, D3->4 に分散
      # しかし最初の移動前に同じ場所にいるので噂は共有される
      Simulation.run_until_spread(drivers)
    end

    @doc """
    問題を解く（入力形式のテスト用）。
    """
    def solve_from_input do
      input = """
      3 1 2 3
      3 2 3 1
      4 2 3 4 5
      """

      Solver.parse_and_solve(input)
    end
  end
end
