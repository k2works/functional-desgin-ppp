defmodule Chapter13 do
  @moduledoc """
  # Chapter 13: Abstract Factory パターン

  Abstract Factory パターンは、関連するオブジェクトのファミリーを、
  その具体的なクラスを指定することなく生成するためのインターフェースを提供するパターンです。

  ## 主なトピック

  1. 図形ファクトリ（StandardFactory, OutlinedFactory, FilledFactory）
  2. UI ファクトリ（WindowsFactory, MacOSFactory, WebFactory）
  3. テーマファクトリ（LightTheme, DarkTheme）
  4. データベースファクトリ（MySQL, PostgreSQL, SQLite）
  """

  # ============================================================
  # 1. Shape Factory
  # ============================================================

  defmodule Shapes do
    @moduledoc "図形の定義"

    defmodule Circle do
      @enforce_keys [:center, :radius]
      defstruct [:center, :radius, :outline_color, :outline_width, :fill_color]

      @type t :: %__MODULE__{
        center: {number(), number()},
        radius: number(),
        outline_color: String.t() | nil,
        outline_width: number() | nil,
        fill_color: String.t() | nil
      }

      def new(center, radius), do: %__MODULE__{center: center, radius: radius}

      def to_string(%__MODULE__{center: {x, y}, radius: r} = c) do
        base = "Circle center: [#{x}, #{y}] radius: #{r}"
        with_style(base, c)
      end

      defp with_style(base, %{fill_color: fc, outline_color: oc, outline_width: ow}) do
        parts = [base]
        parts = if fc, do: parts ++ ["fill: #{fc}"], else: parts
        parts = if oc, do: parts ++ ["outline: #{oc}(#{ow})"], else: parts
        Enum.join(parts, " ")
      end
    end

    defmodule Square do
      @enforce_keys [:top_left, :side]
      defstruct [:top_left, :side, :outline_color, :outline_width, :fill_color]

      @type t :: %__MODULE__{
        top_left: {number(), number()},
        side: number(),
        outline_color: String.t() | nil,
        outline_width: number() | nil,
        fill_color: String.t() | nil
      }

      def new(top_left, side), do: %__MODULE__{top_left: top_left, side: side}

      def to_string(%__MODULE__{top_left: {x, y}, side: s} = sq) do
        base = "Square top-left: [#{x}, #{y}] side: #{s}"
        with_style(base, sq)
      end

      defp with_style(base, %{fill_color: fc, outline_color: oc, outline_width: ow}) do
        parts = [base]
        parts = if fc, do: parts ++ ["fill: #{fc}"], else: parts
        parts = if oc, do: parts ++ ["outline: #{oc}(#{ow})"], else: parts
        Enum.join(parts, " ")
      end
    end

    defmodule Rectangle do
      @enforce_keys [:top_left, :width, :height]
      defstruct [:top_left, :width, :height, :outline_color, :outline_width, :fill_color]

      @type t :: %__MODULE__{
        top_left: {number(), number()},
        width: number(),
        height: number(),
        outline_color: String.t() | nil,
        outline_width: number() | nil,
        fill_color: String.t() | nil
      }

      def new(top_left, width, height) do
        %__MODULE__{top_left: top_left, width: width, height: height}
      end

      def to_string(%__MODULE__{top_left: {x, y}, width: w, height: h} = r) do
        base = "Rectangle top-left: [#{x}, #{y}] width: #{w} height: #{h}"
        with_style(base, r)
      end

      defp with_style(base, %{fill_color: fc, outline_color: oc, outline_width: ow}) do
        parts = [base]
        parts = if fc, do: parts ++ ["fill: #{fc}"], else: parts
        parts = if oc, do: parts ++ ["outline: #{oc}(#{ow})"], else: parts
        Enum.join(parts, " ")
      end
    end
  end

  defprotocol ShapeFactory do
    @moduledoc "図形ファクトリのプロトコル"

    @doc "円を作成"
    @spec create_circle(t(), {number(), number()}, number()) :: struct()
    def create_circle(factory, center, radius)

    @doc "正方形を作成"
    @spec create_square(t(), {number(), number()}, number()) :: struct()
    def create_square(factory, top_left, side)

    @doc "長方形を作成"
    @spec create_rectangle(t(), {number(), number()}, number(), number()) :: struct()
    def create_rectangle(factory, top_left, width, height)
  end

  # StandardShapeFactory
  defmodule StandardShapeFactory do
    @moduledoc "標準の図形ファクトリ"
    defstruct []

    def new, do: %__MODULE__{}
  end

  defimpl ShapeFactory, for: StandardShapeFactory do
    alias Chapter13.Shapes.{Circle, Square, Rectangle}

    def create_circle(_factory, center, radius) do
      Circle.new(center, radius)
    end

    def create_square(_factory, top_left, side) do
      Square.new(top_left, side)
    end

    def create_rectangle(_factory, top_left, width, height) do
      Rectangle.new(top_left, width, height)
    end
  end

  # OutlinedShapeFactory
  defmodule OutlinedShapeFactory do
    @moduledoc "輪郭線付き図形ファクトリ"
    @enforce_keys [:outline_color, :outline_width]
    defstruct [:outline_color, :outline_width]

    def new(outline_color, outline_width) do
      %__MODULE__{outline_color: outline_color, outline_width: outline_width}
    end
  end

  defimpl ShapeFactory, for: OutlinedShapeFactory do
    alias Chapter13.Shapes.{Circle, Square, Rectangle}

    def create_circle(%OutlinedShapeFactory{outline_color: oc, outline_width: ow}, center, radius) do
      %{Circle.new(center, radius) | outline_color: oc, outline_width: ow}
    end

    def create_square(%OutlinedShapeFactory{outline_color: oc, outline_width: ow}, top_left, side) do
      %{Square.new(top_left, side) | outline_color: oc, outline_width: ow}
    end

    def create_rectangle(%OutlinedShapeFactory{outline_color: oc, outline_width: ow}, top_left, width, height) do
      %{Rectangle.new(top_left, width, height) | outline_color: oc, outline_width: ow}
    end
  end

  # FilledShapeFactory
  defmodule FilledShapeFactory do
    @moduledoc "塗りつぶし付き図形ファクトリ"
    @enforce_keys [:fill_color]
    defstruct [:fill_color]

    def new(fill_color), do: %__MODULE__{fill_color: fill_color}
  end

  defimpl ShapeFactory, for: FilledShapeFactory do
    alias Chapter13.Shapes.{Circle, Square, Rectangle}

    def create_circle(%FilledShapeFactory{fill_color: fc}, center, radius) do
      %{Circle.new(center, radius) | fill_color: fc}
    end

    def create_square(%FilledShapeFactory{fill_color: fc}, top_left, side) do
      %{Square.new(top_left, side) | fill_color: fc}
    end

    def create_rectangle(%FilledShapeFactory{fill_color: fc}, top_left, width, height) do
      %{Rectangle.new(top_left, width, height) | fill_color: fc}
    end
  end

  # StyledShapeFactory (combination)
  defmodule StyledShapeFactory do
    @moduledoc "スタイル付き図形ファクトリ（輪郭線と塗りつぶし）"
    @enforce_keys [:outline_color, :outline_width, :fill_color]
    defstruct [:outline_color, :outline_width, :fill_color]

    def new(outline_color, outline_width, fill_color) do
      %__MODULE__{
        outline_color: outline_color,
        outline_width: outline_width,
        fill_color: fill_color
      }
    end
  end

  defimpl ShapeFactory, for: StyledShapeFactory do
    alias Chapter13.Shapes.{Circle, Square, Rectangle}

    def create_circle(%StyledShapeFactory{} = f, center, radius) do
      %{Circle.new(center, radius) |
        outline_color: f.outline_color,
        outline_width: f.outline_width,
        fill_color: f.fill_color
      }
    end

    def create_square(%StyledShapeFactory{} = f, top_left, side) do
      %{Square.new(top_left, side) |
        outline_color: f.outline_color,
        outline_width: f.outline_width,
        fill_color: f.fill_color
      }
    end

    def create_rectangle(%StyledShapeFactory{} = f, top_left, width, height) do
      %{Rectangle.new(top_left, width, height) |
        outline_color: f.outline_color,
        outline_width: f.outline_width,
        fill_color: f.fill_color
      }
    end
  end

  # ============================================================
  # 2. UI Factory
  # ============================================================

  defmodule UIComponents do
    @moduledoc "UI コンポーネントの定義"

    defmodule Button do
      defstruct [:label, :platform, :style]

      def new(label, platform, style \\ %{}) do
        %__MODULE__{label: label, platform: platform, style: style}
      end

      def render(%__MODULE__{label: label, platform: :windows, style: style}) do
        bg = Map.get(style, :background, "#e1e1e1")
        "[Windows Button: #{label}] bg=#{bg}"
      end

      def render(%__MODULE__{label: label, platform: :macos, style: style}) do
        bg = Map.get(style, :background, "#007aff")
        "(Mac Button: #{label}) bg=#{bg}"
      end

      def render(%__MODULE__{label: label, platform: :web, style: style}) do
        bg = Map.get(style, :background, "#4285f4")
        "<button>#{label}</button> bg=#{bg}"
      end
    end

    defmodule TextField do
      defstruct [:placeholder, :platform, :style]

      def new(placeholder, platform, style \\ %{}) do
        %__MODULE__{placeholder: placeholder, platform: platform, style: style}
      end

      def render(%__MODULE__{placeholder: ph, platform: :windows}) do
        "[Windows TextField: #{ph}]"
      end

      def render(%__MODULE__{placeholder: ph, platform: :macos}) do
        "(Mac TextField: #{ph})"
      end

      def render(%__MODULE__{placeholder: ph, platform: :web}) do
        "<input placeholder=\"#{ph}\"/>"
      end
    end

    defmodule Checkbox do
      defstruct [:label, :checked, :platform, :style]

      def new(label, checked, platform, style \\ %{}) do
        %__MODULE__{label: label, checked: checked, platform: platform, style: style}
      end

      def render(%__MODULE__{label: label, checked: checked, platform: :windows}) do
        check = if checked, do: "[x]", else: "[ ]"
        "[Windows #{check} #{label}]"
      end

      def render(%__MODULE__{label: label, checked: checked, platform: :macos}) do
        check = if checked, do: "✓", else: "○"
        "(Mac #{check} #{label})"
      end

      def render(%__MODULE__{label: label, checked: checked, platform: :web}) do
        check = if checked, do: "checked", else: ""
        "<input type=\"checkbox\" #{check}/><label>#{label}</label>"
      end
    end
  end

  defprotocol UIFactory do
    @moduledoc "UI ファクトリのプロトコル"

    @doc "ボタンを作成"
    def create_button(factory, label)

    @doc "テキストフィールドを作成"
    def create_text_field(factory, placeholder)

    @doc "チェックボックスを作成"
    def create_checkbox(factory, label, checked)
  end

  # WindowsUIFactory
  defmodule WindowsUIFactory do
    @moduledoc "Windows UI ファクトリ"
    defstruct style: %{}

    def new(style \\ %{}), do: %__MODULE__{style: style}
  end

  defimpl UIFactory, for: WindowsUIFactory do
    alias Chapter13.UIComponents.{Button, TextField, Checkbox}

    def create_button(%WindowsUIFactory{style: style}, label) do
      Button.new(label, :windows, style)
    end

    def create_text_field(%WindowsUIFactory{style: style}, placeholder) do
      TextField.new(placeholder, :windows, style)
    end

    def create_checkbox(%WindowsUIFactory{style: style}, label, checked) do
      Checkbox.new(label, checked, :windows, style)
    end
  end

  # MacOSUIFactory
  defmodule MacOSUIFactory do
    @moduledoc "macOS UI ファクトリ"
    defstruct style: %{}

    def new(style \\ %{}), do: %__MODULE__{style: style}
  end

  defimpl UIFactory, for: MacOSUIFactory do
    alias Chapter13.UIComponents.{Button, TextField, Checkbox}

    def create_button(%MacOSUIFactory{style: style}, label) do
      Button.new(label, :macos, style)
    end

    def create_text_field(%MacOSUIFactory{style: style}, placeholder) do
      TextField.new(placeholder, :macos, style)
    end

    def create_checkbox(%MacOSUIFactory{style: style}, label, checked) do
      Checkbox.new(label, checked, :macos, style)
    end
  end

  # WebUIFactory
  defmodule WebUIFactory do
    @moduledoc "Web UI ファクトリ"
    defstruct style: %{}

    def new(style \\ %{}), do: %__MODULE__{style: style}
  end

  defimpl UIFactory, for: WebUIFactory do
    alias Chapter13.UIComponents.{Button, TextField, Checkbox}

    def create_button(%WebUIFactory{style: style}, label) do
      Button.new(label, :web, style)
    end

    def create_text_field(%WebUIFactory{style: style}, placeholder) do
      TextField.new(placeholder, :web, style)
    end

    def create_checkbox(%WebUIFactory{style: style}, label, checked) do
      Checkbox.new(label, checked, :web, style)
    end
  end

  # ============================================================
  # 3. Theme Factory
  # ============================================================

  defmodule ThemeComponents do
    @moduledoc "テーマコンポーネントの定義"

    defmodule Colors do
      defstruct [:primary, :secondary, :background, :text, :accent]

      def new(attrs), do: struct(__MODULE__, attrs)
    end

    defmodule Typography do
      defstruct [:font_family, :base_size, :heading_scale]

      def new(attrs), do: struct(__MODULE__, attrs)
    end

    defmodule Spacing do
      defstruct [:unit, :scale]

      def new(attrs), do: struct(__MODULE__, attrs)
    end
  end

  defprotocol ThemeFactory do
    @moduledoc "テーマファクトリのプロトコル"

    @doc "カラースキームを作成"
    def create_colors(factory)

    @doc "タイポグラフィを作成"
    def create_typography(factory)

    @doc "スペーシングを作成"
    def create_spacing(factory)
  end

  # LightThemeFactory
  defmodule LightThemeFactory do
    @moduledoc "ライトテーマファクトリ"
    defstruct []

    def new, do: %__MODULE__{}
  end

  defimpl ThemeFactory, for: LightThemeFactory do
    alias Chapter13.ThemeComponents.{Colors, Typography, Spacing}

    def create_colors(_factory) do
      Colors.new(%{
        primary: "#007aff",
        secondary: "#5856d6",
        background: "#ffffff",
        text: "#000000",
        accent: "#ff9500"
      })
    end

    def create_typography(_factory) do
      Typography.new(%{
        font_family: "San Francisco",
        base_size: 16,
        heading_scale: 1.25
      })
    end

    def create_spacing(_factory) do
      Spacing.new(%{unit: 8, scale: [0.5, 1, 2, 3, 4, 6, 8]})
    end
  end

  # DarkThemeFactory
  defmodule DarkThemeFactory do
    @moduledoc "ダークテーマファクトリ"
    defstruct []

    def new, do: %__MODULE__{}
  end

  defimpl ThemeFactory, for: DarkThemeFactory do
    alias Chapter13.ThemeComponents.{Colors, Typography, Spacing}

    def create_colors(_factory) do
      Colors.new(%{
        primary: "#0a84ff",
        secondary: "#5e5ce6",
        background: "#1c1c1e",
        text: "#ffffff",
        accent: "#ff9f0a"
      })
    end

    def create_typography(_factory) do
      Typography.new(%{
        font_family: "San Francisco",
        base_size: 16,
        heading_scale: 1.25
      })
    end

    def create_spacing(_factory) do
      Spacing.new(%{unit: 8, scale: [0.5, 1, 2, 3, 4, 6, 8]})
    end
  end

  # ============================================================
  # 4. Database Factory
  # ============================================================

  defmodule DatabaseComponents do
    @moduledoc "データベースコンポーネントの定義"

    defmodule Connection do
      defstruct [:driver, :host, :port, :database, :username, :password, :options]

      def new(attrs), do: struct(__MODULE__, attrs)

      def connection_string(%__MODULE__{driver: :mysql} = conn) do
        "mysql://#{conn.username}:#{conn.password}@#{conn.host}:#{conn.port}/#{conn.database}"
      end

      def connection_string(%__MODULE__{driver: :postgresql} = conn) do
        "postgresql://#{conn.username}:#{conn.password}@#{conn.host}:#{conn.port}/#{conn.database}"
      end

      def connection_string(%__MODULE__{driver: :sqlite} = conn) do
        "sqlite:#{conn.database}"
      end
    end

    defmodule Query do
      defstruct [:driver, :sql, :params]

      def new(driver, sql, params \\ []) do
        %__MODULE__{driver: driver, sql: sql, params: params}
      end
    end

    defmodule QueryBuilder do
      @moduledoc "クエリビルダー"

      defstruct [:driver, :table, :columns, :conditions, :order, :limit]

      def new(driver), do: %__MODULE__{driver: driver, columns: ["*"], conditions: []}

      def from(%__MODULE__{} = qb, table), do: %{qb | table: table}

      def select(%__MODULE__{} = qb, columns), do: %{qb | columns: columns}

      def where(%__MODULE__{conditions: conds} = qb, condition) do
        %{qb | conditions: conds ++ [condition]}
      end

      def order_by(%__MODULE__{} = qb, column, direction \\ :asc) do
        %{qb | order: {column, direction}}
      end

      def limit(%__MODULE__{} = qb, n), do: %{qb | limit: n}

      def build(%__MODULE__{driver: :mysql} = qb) do
        columns = Enum.join(qb.columns, ", ")
        sql = "SELECT #{columns} FROM #{qb.table}"
        sql = if qb.conditions != [], do: sql <> " WHERE " <> Enum.join(qb.conditions, " AND "), else: sql
        sql = if qb.order, do: sql <> " ORDER BY #{elem(qb.order, 0)} #{elem(qb.order, 1) |> to_string() |> String.upcase()}", else: sql
        sql = if qb.limit, do: sql <> " LIMIT #{qb.limit}", else: sql
        Query.new(:mysql, sql)
      end

      def build(%__MODULE__{driver: :postgresql} = qb) do
        columns = Enum.join(qb.columns, ", ")
        sql = "SELECT #{columns} FROM #{qb.table}"
        sql = if qb.conditions != [], do: sql <> " WHERE " <> Enum.join(qb.conditions, " AND "), else: sql
        sql = if qb.order, do: sql <> " ORDER BY #{elem(qb.order, 0)} #{elem(qb.order, 1) |> to_string() |> String.upcase()}", else: sql
        sql = if qb.limit, do: sql <> " LIMIT #{qb.limit}", else: sql
        Query.new(:postgresql, sql)
      end

      def build(%__MODULE__{driver: :sqlite} = qb) do
        columns = Enum.join(qb.columns, ", ")
        sql = "SELECT #{columns} FROM #{qb.table}"
        sql = if qb.conditions != [], do: sql <> " WHERE " <> Enum.join(qb.conditions, " AND "), else: sql
        sql = if qb.order, do: sql <> " ORDER BY #{elem(qb.order, 0)} #{elem(qb.order, 1) |> to_string() |> String.upcase()}", else: sql
        sql = if qb.limit, do: sql <> " LIMIT #{qb.limit}", else: sql
        Query.new(:sqlite, sql)
      end
    end
  end

  defprotocol DatabaseFactory do
    @moduledoc "データベースファクトリのプロトコル"

    @doc "接続を作成"
    def create_connection(factory, config)

    @doc "クエリビルダーを作成"
    def create_query_builder(factory)
  end

  # MySQLFactory
  defmodule MySQLFactory do
    @moduledoc "MySQL ファクトリ"
    defstruct []

    def new, do: %__MODULE__{}
  end

  defimpl DatabaseFactory, for: MySQLFactory do
    alias Chapter13.DatabaseComponents.{Connection, QueryBuilder}

    def create_connection(_factory, config) do
      Connection.new(%{
        driver: :mysql,
        host: Map.get(config, :host, "localhost"),
        port: Map.get(config, :port, 3306),
        database: Map.fetch!(config, :database),
        username: Map.fetch!(config, :username),
        password: Map.fetch!(config, :password),
        options: Map.get(config, :options, %{})
      })
    end

    def create_query_builder(_factory) do
      QueryBuilder.new(:mysql)
    end
  end

  # PostgreSQLFactory
  defmodule PostgreSQLFactory do
    @moduledoc "PostgreSQL ファクトリ"
    defstruct []

    def new, do: %__MODULE__{}
  end

  defimpl DatabaseFactory, for: PostgreSQLFactory do
    alias Chapter13.DatabaseComponents.{Connection, QueryBuilder}

    def create_connection(_factory, config) do
      Connection.new(%{
        driver: :postgresql,
        host: Map.get(config, :host, "localhost"),
        port: Map.get(config, :port, 5432),
        database: Map.fetch!(config, :database),
        username: Map.fetch!(config, :username),
        password: Map.fetch!(config, :password),
        options: Map.get(config, :options, %{})
      })
    end

    def create_query_builder(_factory) do
      QueryBuilder.new(:postgresql)
    end
  end

  # SQLiteFactory
  defmodule SQLiteFactory do
    @moduledoc "SQLite ファクトリ"
    defstruct []

    def new, do: %__MODULE__{}
  end

  defimpl DatabaseFactory, for: SQLiteFactory do
    alias Chapter13.DatabaseComponents.{Connection, QueryBuilder}

    def create_connection(_factory, config) do
      Connection.new(%{
        driver: :sqlite,
        host: nil,
        port: nil,
        database: Map.fetch!(config, :database),
        username: nil,
        password: nil,
        options: Map.get(config, :options, %{})
      })
    end

    def create_query_builder(_factory) do
      QueryBuilder.new(:sqlite)
    end
  end

  # ============================================================
  # 5. Factory Provider (Factory of Factories)
  # ============================================================

  defmodule FactoryProvider do
    @moduledoc """
    ファクトリのプロバイダー。
    設定に基づいて適切なファクトリを提供する。
    """

    @doc """
    図形ファクトリを取得する。

    ## Examples

        iex> factory = Chapter13.FactoryProvider.get_shape_factory(:standard)
        iex> circle = Chapter13.ShapeFactory.create_circle(factory, {0, 0}, 5)
        iex> circle.radius
        5
    """
    def get_shape_factory(:standard), do: StandardShapeFactory.new()
    def get_shape_factory(:outlined), do: OutlinedShapeFactory.new("black", 1)
    def get_shape_factory({:outlined, color, width}), do: OutlinedShapeFactory.new(color, width)
    def get_shape_factory(:filled), do: FilledShapeFactory.new("gray")
    def get_shape_factory({:filled, color}), do: FilledShapeFactory.new(color)
    def get_shape_factory({:styled, outline_color, outline_width, fill_color}) do
      StyledShapeFactory.new(outline_color, outline_width, fill_color)
    end

    @doc """
    UI ファクトリを取得する。
    """
    def get_ui_factory(:windows), do: WindowsUIFactory.new()
    def get_ui_factory(:macos), do: MacOSUIFactory.new()
    def get_ui_factory(:web), do: WebUIFactory.new()
    def get_ui_factory({platform, style}), do: get_ui_factory_with_style(platform, style)

    defp get_ui_factory_with_style(:windows, style), do: WindowsUIFactory.new(style)
    defp get_ui_factory_with_style(:macos, style), do: MacOSUIFactory.new(style)
    defp get_ui_factory_with_style(:web, style), do: WebUIFactory.new(style)

    @doc """
    テーマファクトリを取得する。
    """
    def get_theme_factory(:light), do: LightThemeFactory.new()
    def get_theme_factory(:dark), do: DarkThemeFactory.new()

    @doc """
    データベースファクトリを取得する。
    """
    def get_database_factory(:mysql), do: MySQLFactory.new()
    def get_database_factory(:postgresql), do: PostgreSQLFactory.new()
    def get_database_factory(:sqlite), do: SQLiteFactory.new()
  end
end
