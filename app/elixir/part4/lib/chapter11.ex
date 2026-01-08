defmodule Chapter11 do
  @moduledoc """
  # Chapter 11: Command パターン

  Command パターンは、リクエストをオブジェクト（データ）としてカプセル化し、
  異なるリクエストでクライアントをパラメータ化したり、
  操作の履歴を記録したり、Undo/Redo 機能を実装できるようにするパターンです。

  ## 主なトピック

  1. コマンドのデータ化
  2. テキスト操作コマンド（Insert, Delete, Replace）
  3. キャンバス操作コマンド（AddShape, MoveShape, RemoveShape）
  4. コマンド実行器（Undo/Redo 対応）
  5. バッチ処理とマクロコマンド
  """

  # ============================================================
  # 1. Command インターフェース（Protocol）
  # ============================================================

  defprotocol Command do
    @moduledoc """
    コマンドのプロトコル。
    execute と undo の2つの操作を定義する。
    """

    @doc "コマンドを実行し、新しい状態を返す"
    @spec execute(t(), any()) :: any()
    def execute(command, state)

    @doc "コマンドを取り消し、以前の状態を返す"
    @spec undo(t(), any()) :: any()
    def undo(command, state)
  end

  # ============================================================
  # 2. テキスト操作コマンド
  # ============================================================

  defmodule TextCommands do
    @moduledoc "テキスト編集用のコマンド群"

    # InsertCommand: テキスト挿入
    defmodule InsertCommand do
      @moduledoc "指定位置にテキストを挿入するコマンド"
      @enforce_keys [:position, :text]
      defstruct [:position, :text]

      @type t :: %__MODULE__{
        position: non_neg_integer(),
        text: String.t()
      }

      @doc """
      挿入コマンドを作成する。

      ## Examples

          iex> Chapter11.TextCommands.InsertCommand.new(5, " World")
          %Chapter11.TextCommands.InsertCommand{position: 5, text: " World"}
      """
      def new(position, text), do: %__MODULE__{position: position, text: text}
    end

    defimpl Command, for: InsertCommand do
      def execute(%InsertCommand{position: pos, text: text}, document) do
        before = String.slice(document, 0, pos)
        after_text = String.slice(document, pos..-1//1)
        before <> text <> after_text
      end

      def undo(%InsertCommand{position: pos, text: text}, document) do
        len = String.length(text)
        before = String.slice(document, 0, pos)
        after_text = String.slice(document, (pos + len)..-1//1)
        before <> after_text
      end
    end

    # DeleteCommand: テキスト削除
    defmodule DeleteCommand do
      @moduledoc "指定範囲のテキストを削除するコマンド"
      @enforce_keys [:start_position, :end_position, :deleted_text]
      defstruct [:start_position, :end_position, :deleted_text]

      @type t :: %__MODULE__{
        start_position: non_neg_integer(),
        end_position: non_neg_integer(),
        deleted_text: String.t()
      }

      @doc """
      削除コマンドを作成する。

      ## Examples

          iex> Chapter11.TextCommands.DeleteCommand.new(5, 11, " World")
          %Chapter11.TextCommands.DeleteCommand{start_position: 5, end_position: 11, deleted_text: " World"}
      """
      def new(start_pos, end_pos, deleted_text) do
        %__MODULE__{
          start_position: start_pos,
          end_position: end_pos,
          deleted_text: deleted_text
        }
      end
    end

    defimpl Command, for: DeleteCommand do
      def execute(%DeleteCommand{start_position: start_pos, end_position: end_pos}, document) do
        before = String.slice(document, 0, start_pos)
        after_text = String.slice(document, end_pos..-1//1)
        before <> after_text
      end

      def undo(%DeleteCommand{start_position: start_pos, deleted_text: text}, document) do
        before = String.slice(document, 0, start_pos)
        after_text = String.slice(document, start_pos..-1//1)
        before <> text <> after_text
      end
    end

    # ReplaceCommand: テキスト置換
    defmodule ReplaceCommand do
      @moduledoc "指定位置のテキストを置換するコマンド"
      @enforce_keys [:start_position, :old_text, :new_text]
      defstruct [:start_position, :old_text, :new_text]

      @type t :: %__MODULE__{
        start_position: non_neg_integer(),
        old_text: String.t(),
        new_text: String.t()
      }

      @doc """
      置換コマンドを作成する。

      ## Examples

          iex> Chapter11.TextCommands.ReplaceCommand.new(0, "Hello", "Hi")
          %Chapter11.TextCommands.ReplaceCommand{start_position: 0, old_text: "Hello", new_text: "Hi"}
      """
      def new(start_pos, old_text, new_text) do
        %__MODULE__{
          start_position: start_pos,
          old_text: old_text,
          new_text: new_text
        }
      end
    end

    defimpl Command, for: ReplaceCommand do
      def execute(%ReplaceCommand{start_position: start_pos, old_text: old, new_text: new}, doc) do
        old_len = String.length(old)
        before = String.slice(doc, 0, start_pos)
        after_text = String.slice(doc, (start_pos + old_len)..-1//1)
        before <> new <> after_text
      end

      def undo(%ReplaceCommand{start_position: start_pos, old_text: old, new_text: new}, doc) do
        new_len = String.length(new)
        before = String.slice(doc, 0, start_pos)
        after_text = String.slice(doc, (start_pos + new_len)..-1//1)
        before <> old <> after_text
      end
    end
  end

  # ============================================================
  # 3. キャンバス操作コマンド
  # ============================================================

  defmodule CanvasCommands do
    @moduledoc "キャンバス（図形描画）用のコマンド群"

    defmodule Shape do
      @moduledoc "図形の共通構造"
      @enforce_keys [:id, :type, :x, :y]
      defstruct [:id, :type, :x, :y, :width, :height, :radius, :color]

      @type t :: %__MODULE__{
        id: String.t(),
        type: :rectangle | :circle | :line,
        x: number(),
        y: number(),
        width: number() | nil,
        height: number() | nil,
        radius: number() | nil,
        color: String.t() | nil
      }

      def rectangle(id, x, y, width, height, color \\ "black") do
        %__MODULE__{id: id, type: :rectangle, x: x, y: y, width: width, height: height, color: color}
      end

      def circle(id, x, y, radius, color \\ "black") do
        %__MODULE__{id: id, type: :circle, x: x, y: y, radius: radius, color: color}
      end
    end

    defmodule Canvas do
      @moduledoc "キャンバスの状態"
      defstruct shapes: []

      @type t :: %__MODULE__{shapes: [Shape.t()]}

      def new, do: %__MODULE__{}
      def new(shapes), do: %__MODULE__{shapes: shapes}
    end

    # AddShapeCommand: 図形追加
    defmodule AddShapeCommand do
      @moduledoc "キャンバスに図形を追加するコマンド"
      @enforce_keys [:shape]
      defstruct [:shape]

      @type t :: %__MODULE__{shape: Shape.t()}

      def new(shape), do: %__MODULE__{shape: shape}
    end

    defimpl Command, for: AddShapeCommand do
      alias Chapter11.CanvasCommands.Canvas

      def execute(%AddShapeCommand{shape: shape}, %Canvas{shapes: shapes} = canvas) do
        %{canvas | shapes: shapes ++ [shape]}
      end

      def undo(%AddShapeCommand{shape: shape}, %Canvas{shapes: shapes} = canvas) do
        %{canvas | shapes: Enum.reject(shapes, &(&1.id == shape.id))}
      end
    end

    # MoveShapeCommand: 図形移動
    defmodule MoveShapeCommand do
      @moduledoc "キャンバス上の図形を移動するコマンド"
      @enforce_keys [:shape_id, :dx, :dy]
      defstruct [:shape_id, :dx, :dy]

      @type t :: %__MODULE__{
        shape_id: String.t(),
        dx: number(),
        dy: number()
      }

      def new(shape_id, dx, dy), do: %__MODULE__{shape_id: shape_id, dx: dx, dy: dy}
    end

    defimpl Command, for: MoveShapeCommand do
      alias Chapter11.CanvasCommands.Canvas

      def execute(%MoveShapeCommand{shape_id: id, dx: dx, dy: dy}, %Canvas{shapes: shapes} = canvas) do
        new_shapes = Enum.map(shapes, fn shape ->
          if shape.id == id do
            %{shape | x: shape.x + dx, y: shape.y + dy}
          else
            shape
          end
        end)
        %{canvas | shapes: new_shapes}
      end

      def undo(%MoveShapeCommand{shape_id: id, dx: dx, dy: dy}, %Canvas{shapes: shapes} = canvas) do
        new_shapes = Enum.map(shapes, fn shape ->
          if shape.id == id do
            %{shape | x: shape.x - dx, y: shape.y - dy}
          else
            shape
          end
        end)
        %{canvas | shapes: new_shapes}
      end
    end

    # RemoveShapeCommand: 図形削除
    defmodule RemoveShapeCommand do
      @moduledoc "キャンバスから図形を削除するコマンド"
      @enforce_keys [:shape]
      defstruct [:shape]

      @type t :: %__MODULE__{shape: Shape.t()}

      def new(shape), do: %__MODULE__{shape: shape}
    end

    defimpl Command, for: RemoveShapeCommand do
      alias Chapter11.CanvasCommands.Canvas

      def execute(%RemoveShapeCommand{shape: shape}, %Canvas{shapes: shapes} = canvas) do
        %{canvas | shapes: Enum.reject(shapes, &(&1.id == shape.id))}
      end

      def undo(%RemoveShapeCommand{shape: shape}, %Canvas{shapes: shapes} = canvas) do
        %{canvas | shapes: shapes ++ [shape]}
      end
    end

    # ChangeColorCommand: 色変更
    defmodule ChangeColorCommand do
      @moduledoc "図形の色を変更するコマンド"
      @enforce_keys [:shape_id, :old_color, :new_color]
      defstruct [:shape_id, :old_color, :new_color]

      @type t :: %__MODULE__{
        shape_id: String.t(),
        old_color: String.t(),
        new_color: String.t()
      }

      def new(shape_id, old_color, new_color) do
        %__MODULE__{shape_id: shape_id, old_color: old_color, new_color: new_color}
      end
    end

    defimpl Command, for: ChangeColorCommand do
      alias Chapter11.CanvasCommands.Canvas

      def execute(%ChangeColorCommand{shape_id: id, new_color: color}, %Canvas{shapes: shapes} = canvas) do
        new_shapes = Enum.map(shapes, fn shape ->
          if shape.id == id, do: %{shape | color: color}, else: shape
        end)
        %{canvas | shapes: new_shapes}
      end

      def undo(%ChangeColorCommand{shape_id: id, old_color: color}, %Canvas{shapes: shapes} = canvas) do
        new_shapes = Enum.map(shapes, fn shape ->
          if shape.id == id, do: %{shape | color: color}, else: shape
        end)
        %{canvas | shapes: new_shapes}
      end
    end
  end

  # ============================================================
  # 4. コマンド実行器（Undo/Redo 対応）
  # ============================================================

  defmodule CommandExecutor do
    @moduledoc """
    コマンドの実行と履歴管理を行う実行器。
    Undo/Redo 機能をサポートする。
    """

    defstruct [:state, undo_stack: [], redo_stack: []]

    @type t :: %__MODULE__{
      state: any(),
      undo_stack: [Command.t()],
      redo_stack: [Command.t()]
    }

    @doc """
    新しい実行器を作成する。

    ## Examples

        iex> executor = Chapter11.CommandExecutor.new("Hello")
        iex> executor.state
        "Hello"
    """
    @spec new(any()) :: t()
    def new(initial_state) do
      %__MODULE__{state: initial_state}
    end

    @doc """
    コマンドを実行し、履歴に追加する。

    ## Examples

        iex> executor = Chapter11.CommandExecutor.new("Hello")
        iex> cmd = Chapter11.TextCommands.InsertCommand.new(5, " World")
        iex> executor = Chapter11.CommandExecutor.execute(executor, cmd)
        iex> executor.state
        "Hello World"
    """
    @spec execute(t(), Command.t()) :: t()
    def execute(%__MODULE__{state: state, undo_stack: undo_stack} = executor, command) do
      new_state = Command.execute(command, state)
      %{executor |
        state: new_state,
        undo_stack: [command | undo_stack],
        redo_stack: []
      }
    end

    @doc """
    最後のコマンドを取り消す。

    ## Examples

        iex> executor = Chapter11.CommandExecutor.new("Hello")
        iex> cmd = Chapter11.TextCommands.InsertCommand.new(5, " World")
        iex> executor = Chapter11.CommandExecutor.execute(executor, cmd)
        iex> executor = Chapter11.CommandExecutor.undo(executor)
        iex> executor.state
        "Hello"
    """
    @spec undo(t()) :: t()
    def undo(%__MODULE__{undo_stack: []} = executor), do: executor
    def undo(%__MODULE__{state: state, undo_stack: [cmd | rest], redo_stack: redo} = executor) do
      new_state = Command.undo(cmd, state)
      %{executor |
        state: new_state,
        undo_stack: rest,
        redo_stack: [cmd | redo]
      }
    end

    @doc """
    最後に取り消したコマンドを再実行する。

    ## Examples

        iex> executor = Chapter11.CommandExecutor.new("Hello")
        iex> cmd = Chapter11.TextCommands.InsertCommand.new(5, " World")
        iex> executor = Chapter11.CommandExecutor.execute(executor, cmd)
        iex> executor = Chapter11.CommandExecutor.undo(executor)
        iex> executor = Chapter11.CommandExecutor.redo(executor)
        iex> executor.state
        "Hello World"
    """
    @spec redo(t()) :: t()
    def redo(%__MODULE__{redo_stack: []} = executor), do: executor
    def redo(%__MODULE__{state: state, undo_stack: undo, redo_stack: [cmd | rest]} = executor) do
      new_state = Command.execute(cmd, state)
      %{executor |
        state: new_state,
        undo_stack: [cmd | undo],
        redo_stack: rest
      }
    end

    @doc "Undo 可能かどうか"
    @spec can_undo?(t()) :: boolean()
    def can_undo?(%__MODULE__{undo_stack: stack}), do: stack != []

    @doc "Redo 可能かどうか"
    @spec can_redo?(t()) :: boolean()
    def can_redo?(%__MODULE__{redo_stack: stack}), do: stack != []

    @doc "現在の状態を取得"
    @spec get_state(t()) :: any()
    def get_state(%__MODULE__{state: state}), do: state
  end

  # ============================================================
  # 5. バッチ処理とマクロコマンド
  # ============================================================

  defmodule MacroCommand do
    @moduledoc """
    複数のコマンドを1つのコマンドとして扱うマクロコマンド。
    """

    @enforce_keys [:commands]
    defstruct [:commands]

    @type t :: %__MODULE__{commands: [Command.t()]}

    @doc """
    マクロコマンドを作成する。

    ## Examples

        iex> cmd1 = Chapter11.TextCommands.InsertCommand.new(0, "Hello")
        iex> cmd2 = Chapter11.TextCommands.InsertCommand.new(5, " World")
        iex> macro = Chapter11.MacroCommand.new([cmd1, cmd2])
        iex> length(macro.commands)
        2
    """
    def new(commands), do: %__MODULE__{commands: commands}
  end

  defimpl Command, for: MacroCommand do
    def execute(%MacroCommand{commands: commands}, state) do
      Enum.reduce(commands, state, fn cmd, acc ->
        Command.execute(cmd, acc)
      end)
    end

    def undo(%MacroCommand{commands: commands}, state) do
      Enum.reduce(Enum.reverse(commands), state, fn cmd, acc ->
        Command.undo(cmd, acc)
      end)
    end
  end

  defmodule BatchExecutor do
    @moduledoc """
    バッチ処理用のユーティリティ関数群。
    """

    alias Chapter11.CommandExecutor

    @doc """
    複数のコマンドをまとめて実行する。

    ## Examples

        iex> executor = Chapter11.CommandExecutor.new("Hello")
        iex> commands = [
        ...>   Chapter11.TextCommands.InsertCommand.new(5, " World"),
        ...>   Chapter11.TextCommands.InsertCommand.new(11, "!")
        ...> ]
        iex> executor = Chapter11.BatchExecutor.execute_batch(executor, commands)
        iex> executor.state
        "Hello World!"
    """
    @spec execute_batch(CommandExecutor.t(), [Command.t()]) :: CommandExecutor.t()
    def execute_batch(executor, commands) do
      Enum.reduce(commands, executor, &CommandExecutor.execute(&2, &1))
    end

    @doc """
    すべてのコマンドを取り消す。

    ## Examples

        iex> executor = Chapter11.CommandExecutor.new("Hello")
        iex> commands = [
        ...>   Chapter11.TextCommands.InsertCommand.new(5, " World"),
        ...>   Chapter11.TextCommands.InsertCommand.new(11, "!")
        ...> ]
        iex> executor = Chapter11.BatchExecutor.execute_batch(executor, commands)
        iex> executor = Chapter11.BatchExecutor.undo_all(executor)
        iex> executor.state
        "Hello"
    """
    @spec undo_all(CommandExecutor.t()) :: CommandExecutor.t()
    def undo_all(%CommandExecutor{} = executor) do
      if CommandExecutor.can_undo?(executor) do
        undo_all(CommandExecutor.undo(executor))
      else
        executor
      end
    end

    @doc """
    すべてのコマンドを再実行する。

    ## Examples

        iex> executor = Chapter11.CommandExecutor.new("Hello")
        iex> cmd = Chapter11.TextCommands.InsertCommand.new(5, " World")
        iex> executor = Chapter11.CommandExecutor.execute(executor, cmd)
        iex> executor = Chapter11.CommandExecutor.undo(executor)
        iex> executor = Chapter11.BatchExecutor.redo_all(executor)
        iex> executor.state
        "Hello World"
    """
    @spec redo_all(CommandExecutor.t()) :: CommandExecutor.t()
    def redo_all(%CommandExecutor{} = executor) do
      if CommandExecutor.can_redo?(executor) do
        redo_all(CommandExecutor.redo(executor))
      else
        executor
      end
    end
  end

  # ============================================================
  # 6. コマンドキュー（遅延実行）
  # ============================================================

  defmodule CommandQueue do
    @moduledoc """
    コマンドをキューに入れて遅延実行するための機能。
    """

    defstruct commands: []

    @type t :: %__MODULE__{commands: [Command.t()]}

    @doc "空のキューを作成"
    def new, do: %__MODULE__{}

    @doc "コマンドをキューに追加"
    @spec enqueue(t(), Command.t()) :: t()
    def enqueue(%__MODULE__{commands: cmds} = queue, command) do
      %{queue | commands: cmds ++ [command]}
    end

    @doc "キュー内のすべてのコマンドを実行"
    @spec flush(t(), any()) :: {any(), t()}
    def flush(%__MODULE__{commands: cmds}, state) do
      final_state = Enum.reduce(cmds, state, fn cmd, acc ->
        Command.execute(cmd, acc)
      end)
      {final_state, %__MODULE__{}}
    end

    @doc "キューの長さを取得"
    @spec length(t()) :: non_neg_integer()
    def length(%__MODULE__{commands: cmds}), do: Kernel.length(cmds)

    @doc "キューをクリア"
    @spec clear(t()) :: t()
    def clear(%__MODULE__{}), do: %__MODULE__{}
  end

  # ============================================================
  # 7. コマンドログ（履歴記録）
  # ============================================================

  defmodule CommandLogger do
    @moduledoc """
    コマンドの実行履歴を記録するロガー。
    """

    use Agent

    @doc "ロガーを開始"
    def start_link(opts \\ []) do
      Agent.start_link(fn -> [] end, opts)
    end

    @doc "コマンド実行をログに記録"
    def log(logger, command, action, timestamp \\ DateTime.utc_now()) do
      entry = %{
        command: command,
        action: action,
        timestamp: timestamp
      }
      Agent.update(logger, &[entry | &1])
    end

    @doc "ログを取得"
    def get_logs(logger) do
      Agent.get(logger, &Enum.reverse(&1))
    end

    @doc "ログをクリア"
    def clear(logger) do
      Agent.update(logger, fn _ -> [] end)
    end
  end
end
