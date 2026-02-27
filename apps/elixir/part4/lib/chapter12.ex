defmodule Chapter12 do
  @moduledoc """
  # Chapter 12: Visitor パターン

  Visitor パターンは、データ構造と操作を分離し、
  既存のデータ構造を変更することなく新しい操作を追加できるようにするパターンです。

  ## 主なトピック

  1. 図形（Shape）の定義
  2. JSON 変換 Visitor
  3. XML 変換 Visitor
  4. 面積計算 Visitor
  5. 周囲長計算 Visitor
  6. 複合 Visitor パターン
  """

  # ============================================================
  # 1. Element: 図形の定義
  # ============================================================

  defmodule Shape do
    @moduledoc """
    図形の共通プロトコル。
    各図形は translate（移動）と scale（拡大縮小）を実装する。
    """

    @type point :: {number(), number()}

    defprotocol Transformable do
      @doc "図形を移動する"
      @spec translate(t(), number(), number()) :: t()
      def translate(shape, dx, dy)

      @doc "図形を拡大/縮小する"
      @spec scale(t(), number()) :: t()
      def scale(shape, factor)
    end
  end

  # Circle: 円
  defmodule Circle do
    @moduledoc "円を表す構造体"
    @enforce_keys [:center, :radius]
    defstruct [:center, :radius]

    @type t :: %__MODULE__{
      center: {number(), number()},
      radius: number()
    }

    @doc """
    円を作成する。

    ## Examples

        iex> Chapter12.Circle.new({10, 20}, 5)
        %Chapter12.Circle{center: {10, 20}, radius: 5}
    """
    def new(center, radius), do: %__MODULE__{center: center, radius: radius}
  end

  defimpl Shape.Transformable, for: Circle do
    def translate(%Circle{center: {x, y}} = circle, dx, dy) do
      %{circle | center: {x + dx, y + dy}}
    end

    def scale(%Circle{radius: r} = circle, factor) do
      %{circle | radius: r * factor}
    end
  end

  # Square: 正方形
  defmodule Square do
    @moduledoc "正方形を表す構造体"
    @enforce_keys [:top_left, :side]
    defstruct [:top_left, :side]

    @type t :: %__MODULE__{
      top_left: {number(), number()},
      side: number()
    }

    @doc """
    正方形を作成する。

    ## Examples

        iex> Chapter12.Square.new({0, 0}, 10)
        %Chapter12.Square{top_left: {0, 0}, side: 10}
    """
    def new(top_left, side), do: %__MODULE__{top_left: top_left, side: side}
  end

  defimpl Shape.Transformable, for: Square do
    def translate(%Square{top_left: {x, y}} = square, dx, dy) do
      %{square | top_left: {x + dx, y + dy}}
    end

    def scale(%Square{side: s} = square, factor) do
      %{square | side: s * factor}
    end
  end

  # Rectangle: 長方形
  defmodule Rectangle do
    @moduledoc "長方形を表す構造体"
    @enforce_keys [:top_left, :width, :height]
    defstruct [:top_left, :width, :height]

    @type t :: %__MODULE__{
      top_left: {number(), number()},
      width: number(),
      height: number()
    }

    @doc """
    長方形を作成する。

    ## Examples

        iex> Chapter12.Rectangle.new({0, 0}, 20, 10)
        %Chapter12.Rectangle{top_left: {0, 0}, width: 20, height: 10}
    """
    def new(top_left, width, height) do
      %__MODULE__{top_left: top_left, width: width, height: height}
    end
  end

  defimpl Shape.Transformable, for: Rectangle do
    def translate(%Rectangle{top_left: {x, y}} = rect, dx, dy) do
      %{rect | top_left: {x + dx, y + dy}}
    end

    def scale(%Rectangle{width: w, height: h} = rect, factor) do
      %{rect | width: w * factor, height: h * factor}
    end
  end

  # Triangle: 三角形
  defmodule Triangle do
    @moduledoc "三角形を表す構造体"
    @enforce_keys [:p1, :p2, :p3]
    defstruct [:p1, :p2, :p3]

    @type t :: %__MODULE__{
      p1: {number(), number()},
      p2: {number(), number()},
      p3: {number(), number()}
    }

    @doc """
    三角形を作成する。

    ## Examples

        iex> Chapter12.Triangle.new({0, 0}, {10, 0}, {5, 10})
        %Chapter12.Triangle{p1: {0, 0}, p2: {10, 0}, p3: {5, 10}}
    """
    def new(p1, p2, p3), do: %__MODULE__{p1: p1, p2: p2, p3: p3}
  end

  defimpl Shape.Transformable, for: Triangle do
    def translate(%Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}} = tri, dx, dy) do
      %{tri |
        p1: {x1 + dx, y1 + dy},
        p2: {x2 + dx, y2 + dy},
        p3: {x3 + dx, y3 + dy}
      }
    end

    def scale(%Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}} = tri, factor) do
      # 重心を基準にスケール
      cx = (x1 + x2 + x3) / 3
      cy = (y1 + y2 + y3) / 3

      scale_point = fn {x, y} ->
        {cx + (x - cx) * factor, cy + (y - cy) * factor}
      end

      %{tri |
        p1: scale_point.({x1, y1}),
        p2: scale_point.({x2, y2}),
        p3: scale_point.({x3, y3})
      }
    end
  end

  # ============================================================
  # 2. Visitor Protocol
  # ============================================================

  defprotocol ShapeVisitor do
    @moduledoc """
    図形に対する Visitor プロトコル。
    各操作（JSON変換、面積計算など）はこのプロトコルを実装する。
    """

    @doc "図形を訪問して処理を行う"
    @spec visit(t(), struct()) :: any()
    def visit(visitor, shape)
  end

  # ============================================================
  # 3. JSON Visitor
  # ============================================================

  defmodule JsonVisitor do
    @moduledoc """
    図形を JSON 文字列に変換する Visitor。
    """

    defstruct []

    def new, do: %__MODULE__{}

    @doc """
    図形を JSON 形式に変換する。

    ## Examples

        iex> circle = Chapter12.Circle.new({10, 20}, 5)
        iex> visitor = Chapter12.JsonVisitor.new()
        iex> Chapter12.ShapeVisitor.visit(visitor, circle)
        ~s({"type":"circle","center":[10,20],"radius":5})
    """
    def to_json(shape) do
      ShapeVisitor.visit(new(), shape)
    end
  end

  defimpl ShapeVisitor, for: JsonVisitor do
    def visit(_visitor, %Circle{center: {x, y}, radius: r}) do
      ~s({"type":"circle","center":[#{x},#{y}],"radius":#{r}})
    end

    def visit(_visitor, %Square{top_left: {x, y}, side: s}) do
      ~s({"type":"square","topLeft":[#{x},#{y}],"side":#{s}})
    end

    def visit(_visitor, %Rectangle{top_left: {x, y}, width: w, height: h}) do
      ~s({"type":"rectangle","topLeft":[#{x},#{y}],"width":#{w},"height":#{h}})
    end

    def visit(_visitor, %Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}}) do
      ~s({"type":"triangle","points":[[#{x1},#{y1}],[#{x2},#{y2}],[#{x3},#{y3}]]})
    end
  end

  # ============================================================
  # 4. XML Visitor
  # ============================================================

  defmodule XmlVisitor do
    @moduledoc """
    図形を XML 文字列に変換する Visitor。
    """

    defstruct []

    def new, do: %__MODULE__{}

    @doc """
    図形を XML 形式に変換する。

    ## Examples

        iex> circle = Chapter12.Circle.new({10, 20}, 5)
        iex> visitor = Chapter12.XmlVisitor.new()
        iex> Chapter12.ShapeVisitor.visit(visitor, circle)
        ~s(<circle><center x="10" y="20"/><radius>5</radius></circle>)
    """
    def to_xml(shape) do
      ShapeVisitor.visit(new(), shape)
    end
  end

  defimpl ShapeVisitor, for: XmlVisitor do
    def visit(_visitor, %Circle{center: {x, y}, radius: r}) do
      ~s(<circle><center x="#{x}" y="#{y}"/><radius>#{r}</radius></circle>)
    end

    def visit(_visitor, %Square{top_left: {x, y}, side: s}) do
      ~s(<square><topLeft x="#{x}" y="#{y}"/><side>#{s}</side></square>)
    end

    def visit(_visitor, %Rectangle{top_left: {x, y}, width: w, height: h}) do
      ~s(<rectangle><topLeft x="#{x}" y="#{y}"/><width>#{w}</width><height>#{h}</height></rectangle>)
    end

    def visit(_visitor, %Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}}) do
      ~s(<triangle><p1 x="#{x1}" y="#{y1}"/><p2 x="#{x2}" y="#{y2}"/><p3 x="#{x3}" y="#{y3}"/></triangle>)
    end
  end

  # ============================================================
  # 5. Area Visitor
  # ============================================================

  defmodule AreaVisitor do
    @moduledoc """
    図形の面積を計算する Visitor。
    """

    defstruct []

    def new, do: %__MODULE__{}

    @doc """
    図形の面積を計算する。

    ## Examples

        iex> circle = Chapter12.Circle.new({0, 0}, 1)
        iex> Float.round(Chapter12.AreaVisitor.calculate_area(circle), 4)
        3.1416
    """
    def calculate_area(shape) do
      ShapeVisitor.visit(new(), shape)
    end

    @doc """
    複数の図形の合計面積を計算する。
    """
    def total_area(shapes) do
      Enum.reduce(shapes, 0, fn shape, acc ->
        acc + calculate_area(shape)
      end)
    end
  end

  defimpl ShapeVisitor, for: AreaVisitor do
    def visit(_visitor, %Circle{radius: r}) do
      :math.pi() * r * r
    end

    def visit(_visitor, %Square{side: s}) do
      s * s
    end

    def visit(_visitor, %Rectangle{width: w, height: h}) do
      w * h
    end

    def visit(_visitor, %Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}}) do
      # Shoelace formula
      abs((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2)
    end
  end

  # ============================================================
  # 6. Perimeter Visitor
  # ============================================================

  defmodule PerimeterVisitor do
    @moduledoc """
    図形の周囲長を計算する Visitor。
    """

    defstruct []

    def new, do: %__MODULE__{}

    @doc """
    図形の周囲長を計算する。

    ## Examples

        iex> circle = Chapter12.Circle.new({0, 0}, 1)
        iex> Float.round(Chapter12.PerimeterVisitor.calculate_perimeter(circle), 4)
        6.2832
    """
    def calculate_perimeter(shape) do
      ShapeVisitor.visit(new(), shape)
    end

    @doc """
    複数の図形の合計周囲長を計算する。
    """
    def total_perimeter(shapes) do
      Enum.reduce(shapes, 0, fn shape, acc ->
        acc + calculate_perimeter(shape)
      end)
    end
  end

  defimpl ShapeVisitor, for: PerimeterVisitor do
    def visit(_visitor, %Circle{radius: r}) do
      2 * :math.pi() * r
    end

    def visit(_visitor, %Square{side: s}) do
      4 * s
    end

    def visit(_visitor, %Rectangle{width: w, height: h}) do
      2 * (w + h)
    end

    def visit(_visitor, %Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}}) do
      distance = fn {xa, ya}, {xb, yb} ->
        :math.sqrt(:math.pow(xb - xa, 2) + :math.pow(yb - ya, 2))
      end

      distance.({x1, y1}, {x2, y2}) +
        distance.({x2, y2}, {x3, y3}) +
        distance.({x3, y3}, {x1, y1})
    end
  end

  # ============================================================
  # 7. SVG Visitor
  # ============================================================

  defmodule SvgVisitor do
    @moduledoc """
    図形を SVG 要素に変換する Visitor。
    """

    defstruct fill: "none", stroke: "black", stroke_width: 1

    def new(opts \\ []) do
      %__MODULE__{
        fill: Keyword.get(opts, :fill, "none"),
        stroke: Keyword.get(opts, :stroke, "black"),
        stroke_width: Keyword.get(opts, :stroke_width, 1)
      }
    end

    @doc """
    図形を SVG 要素に変換する。
    """
    def to_svg(shape, opts \\ []) do
      ShapeVisitor.visit(new(opts), shape)
    end
  end

  defimpl ShapeVisitor, for: SvgVisitor do
    def visit(%SvgVisitor{fill: f, stroke: s, stroke_width: sw}, %Circle{center: {cx, cy}, radius: r}) do
      ~s(<circle cx="#{cx}" cy="#{cy}" r="#{r}" fill="#{f}" stroke="#{s}" stroke-width="#{sw}"/>)
    end

    def visit(%SvgVisitor{fill: f, stroke: s, stroke_width: sw}, %Square{top_left: {x, y}, side: side}) do
      ~s(<rect x="#{x}" y="#{y}" width="#{side}" height="#{side}" fill="#{f}" stroke="#{s}" stroke-width="#{sw}"/>)
    end

    def visit(%SvgVisitor{fill: f, stroke: s, stroke_width: sw}, %Rectangle{top_left: {x, y}, width: w, height: h}) do
      ~s(<rect x="#{x}" y="#{y}" width="#{w}" height="#{h}" fill="#{f}" stroke="#{s}" stroke-width="#{sw}"/>)
    end

    def visit(%SvgVisitor{fill: f, stroke: s, stroke_width: sw}, %Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}}) do
      points = "#{x1},#{y1} #{x2},#{y2} #{x3},#{y3}"
      ~s(<polygon points="#{points}" fill="#{f}" stroke="#{s}" stroke-width="#{sw}"/>)
    end
  end

  # ============================================================
  # 8. Bounding Box Visitor
  # ============================================================

  defmodule BoundingBoxVisitor do
    @moduledoc """
    図形のバウンディングボックスを計算する Visitor。
    """

    defstruct []

    @type bounding_box :: {number(), number(), number(), number()}  # {min_x, min_y, max_x, max_y}

    def new, do: %__MODULE__{}

    @doc """
    図形のバウンディングボックスを計算する。
    {min_x, min_y, max_x, max_y} のタプルを返す。

    ## Examples

        iex> rect = Chapter12.Rectangle.new({10, 20}, 30, 40)
        iex> Chapter12.BoundingBoxVisitor.calculate_bbox(rect)
        {10, 20, 40, 60}
    """
    def calculate_bbox(shape) do
      ShapeVisitor.visit(new(), shape)
    end

    @doc """
    複数の図形を含む最小のバウンディングボックスを計算する。
    """
    def combined_bbox(shapes) do
      bboxes = Enum.map(shapes, &calculate_bbox/1)

      Enum.reduce(bboxes, nil, fn
        bbox, nil -> bbox
        {min_x, min_y, max_x, max_y}, {acc_min_x, acc_min_y, acc_max_x, acc_max_y} ->
          {
            min(min_x, acc_min_x),
            min(min_y, acc_min_y),
            max(max_x, acc_max_x),
            max(max_y, acc_max_y)
          }
      end)
    end
  end

  defimpl ShapeVisitor, for: BoundingBoxVisitor do
    def visit(_visitor, %Circle{center: {cx, cy}, radius: r}) do
      {cx - r, cy - r, cx + r, cy + r}
    end

    def visit(_visitor, %Square{top_left: {x, y}, side: s}) do
      {x, y, x + s, y + s}
    end

    def visit(_visitor, %Rectangle{top_left: {x, y}, width: w, height: h}) do
      {x, y, x + w, y + h}
    end

    def visit(_visitor, %Triangle{p1: {x1, y1}, p2: {x2, y2}, p3: {x3, y3}}) do
      {
        min(x1, min(x2, x3)),
        min(y1, min(y2, y3)),
        max(x1, max(x2, x3)),
        max(y1, max(y2, y3))
      }
    end
  end

  # ============================================================
  # 9. Composite Visitor（複数 Visitor の適用）
  # ============================================================

  defmodule CompositeVisitor do
    @moduledoc """
    複数の Visitor を一度に適用するユーティリティ。
    """

    @doc """
    複数の Visitor を図形に適用し、結果をマップで返す。

    ## Examples

        iex> circle = Chapter12.Circle.new({0, 0}, 5)
        iex> results = Chapter12.CompositeVisitor.apply_all(circle, [
        ...>   {:json, Chapter12.JsonVisitor.new()},
        ...>   {:area, Chapter12.AreaVisitor.new()}
        ...> ])
        iex> results[:json]
        ~s({"type":"circle","center":[0,0],"radius":5})
    """
    def apply_all(shape, visitors) do
      Map.new(visitors, fn {key, visitor} ->
        {key, ShapeVisitor.visit(visitor, shape)}
      end)
    end

    @doc """
    複数の図形に Visitor を適用し、結果のリストを返す。
    """
    def map_shapes(shapes, visitor) do
      Enum.map(shapes, fn shape ->
        ShapeVisitor.visit(visitor, shape)
      end)
    end
  end

  # ============================================================
  # 10. 拡張例：描画コンテキスト
  # ============================================================

  defmodule DrawingContext do
    @moduledoc """
    図形の描画コンテキストを管理する。
    複数の図形を保持し、様々な操作を適用できる。
    """

    defstruct shapes: []

    def new(shapes \\ []), do: %__MODULE__{shapes: shapes}

    @doc "図形を追加"
    def add_shape(%__MODULE__{shapes: shapes} = ctx, shape) do
      %{ctx | shapes: shapes ++ [shape]}
    end

    @doc "すべての図形を JSON に変換"
    def to_json(%__MODULE__{shapes: shapes}) do
      json_items = Enum.map(shapes, &JsonVisitor.to_json/1)
      "[" <> Enum.join(json_items, ",") <> "]"
    end

    @doc "すべての図形を SVG に変換"
    def to_svg(%__MODULE__{shapes: shapes}, opts \\ []) do
      width = Keyword.get(opts, :width, 100)
      height = Keyword.get(opts, :height, 100)

      elements = Enum.map(shapes, &SvgVisitor.to_svg(&1, opts))
      content = Enum.join(elements, "\n  ")

      ~s(<svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">\n  #{content}\n</svg>)
    end

    @doc "合計面積を計算"
    def total_area(%__MODULE__{shapes: shapes}) do
      AreaVisitor.total_area(shapes)
    end

    @doc "合計周囲長を計算"
    def total_perimeter(%__MODULE__{shapes: shapes}) do
      PerimeterVisitor.total_perimeter(shapes)
    end

    @doc "バウンディングボックスを計算"
    def bounding_box(%__MODULE__{shapes: shapes}) do
      BoundingBoxVisitor.combined_bbox(shapes)
    end

    @doc "すべての図形を移動"
    def translate_all(%__MODULE__{shapes: shapes} = ctx, dx, dy) do
      new_shapes = Enum.map(shapes, &Shape.Transformable.translate(&1, dx, dy))
      %{ctx | shapes: new_shapes}
    end

    @doc "すべての図形を拡大縮小"
    def scale_all(%__MODULE__{shapes: shapes} = ctx, factor) do
      new_shapes = Enum.map(shapes, &Shape.Transformable.scale(&1, factor))
      %{ctx | shapes: new_shapes}
    end
  end
end
