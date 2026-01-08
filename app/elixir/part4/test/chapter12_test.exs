defmodule Chapter12Test do
  use ExUnit.Case, async: true

  alias Chapter12.{Circle, Square, Rectangle, Triangle}
  alias Chapter12.Shape.Transformable
  alias Chapter12.{ShapeVisitor, JsonVisitor, XmlVisitor, AreaVisitor, PerimeterVisitor}
  alias Chapter12.{SvgVisitor, BoundingBoxVisitor, CompositeVisitor, DrawingContext}

  # ============================================================
  # 1. 図形の定義テスト
  # ============================================================

  describe "Circle" do
    test "creates a circle" do
      circle = Circle.new({10, 20}, 5)
      assert circle.center == {10, 20}
      assert circle.radius == 5
    end

    test "translates circle" do
      circle = Circle.new({10, 20}, 5)
      moved = Transformable.translate(circle, 3, 4)
      assert moved.center == {13, 24}
      assert moved.radius == 5
    end

    test "scales circle" do
      circle = Circle.new({10, 20}, 5)
      scaled = Transformable.scale(circle, 2)
      assert scaled.center == {10, 20}
      assert scaled.radius == 10
    end
  end

  describe "Square" do
    test "creates a square" do
      square = Square.new({0, 0}, 10)
      assert square.top_left == {0, 0}
      assert square.side == 10
    end

    test "translates square" do
      square = Square.new({0, 0}, 10)
      moved = Transformable.translate(square, 5, 5)
      assert moved.top_left == {5, 5}
      assert moved.side == 10
    end

    test "scales square" do
      square = Square.new({0, 0}, 10)
      scaled = Transformable.scale(square, 1.5)
      assert scaled.top_left == {0, 0}
      assert scaled.side == 15
    end
  end

  describe "Rectangle" do
    test "creates a rectangle" do
      rect = Rectangle.new({0, 0}, 20, 10)
      assert rect.top_left == {0, 0}
      assert rect.width == 20
      assert rect.height == 10
    end

    test "translates rectangle" do
      rect = Rectangle.new({0, 0}, 20, 10)
      moved = Transformable.translate(rect, 5, 10)
      assert moved.top_left == {5, 10}
      assert moved.width == 20
      assert moved.height == 10
    end

    test "scales rectangle" do
      rect = Rectangle.new({0, 0}, 20, 10)
      scaled = Transformable.scale(rect, 2)
      assert scaled.top_left == {0, 0}
      assert scaled.width == 40
      assert scaled.height == 20
    end
  end

  describe "Triangle" do
    test "creates a triangle" do
      tri = Triangle.new({0, 0}, {10, 0}, {5, 10})
      assert tri.p1 == {0, 0}
      assert tri.p2 == {10, 0}
      assert tri.p3 == {5, 10}
    end

    test "translates triangle" do
      tri = Triangle.new({0, 0}, {10, 0}, {5, 10})
      moved = Transformable.translate(tri, 5, 5)
      assert moved.p1 == {5, 5}
      assert moved.p2 == {15, 5}
      assert moved.p3 == {10, 15}
    end

    test "scales triangle" do
      tri = Triangle.new({0, 0}, {6, 0}, {3, 6})
      scaled = Transformable.scale(tri, 2)
      # After scaling by 2 from centroid (3, 2)
      # p1: (0, 0) -> (3 + (0-3)*2, 2 + (0-2)*2) = (-3, -2)
      assert scaled.p1 == {-3.0, -2.0}
    end
  end

  # ============================================================
  # 2. JSON Visitor テスト
  # ============================================================

  describe "JsonVisitor" do
    test "converts circle to JSON" do
      circle = Circle.new({10, 20}, 5)
      json = JsonVisitor.to_json(circle)
      assert json == ~s({"type":"circle","center":[10,20],"radius":5})
    end

    test "converts square to JSON" do
      square = Square.new({0, 0}, 10)
      json = JsonVisitor.to_json(square)
      assert json == ~s({"type":"square","topLeft":[0,0],"side":10})
    end

    test "converts rectangle to JSON" do
      rect = Rectangle.new({5, 10}, 20, 15)
      json = JsonVisitor.to_json(rect)
      assert json == ~s({"type":"rectangle","topLeft":[5,10],"width":20,"height":15})
    end

    test "converts triangle to JSON" do
      tri = Triangle.new({0, 0}, {10, 0}, {5, 10})
      json = JsonVisitor.to_json(tri)
      assert json == ~s({"type":"triangle","points":[[0,0],[10,0],[5,10]]})
    end

    test "visitor protocol works directly" do
      circle = Circle.new({10, 20}, 5)
      visitor = JsonVisitor.new()
      json = ShapeVisitor.visit(visitor, circle)
      assert json == ~s({"type":"circle","center":[10,20],"radius":5})
    end
  end

  # ============================================================
  # 3. XML Visitor テスト
  # ============================================================

  describe "XmlVisitor" do
    test "converts circle to XML" do
      circle = Circle.new({10, 20}, 5)
      xml = XmlVisitor.to_xml(circle)
      assert xml == ~s(<circle><center x="10" y="20"/><radius>5</radius></circle>)
    end

    test "converts square to XML" do
      square = Square.new({0, 0}, 10)
      xml = XmlVisitor.to_xml(square)
      assert xml == ~s(<square><topLeft x="0" y="0"/><side>10</side></square>)
    end

    test "converts rectangle to XML" do
      rect = Rectangle.new({5, 10}, 20, 15)
      xml = XmlVisitor.to_xml(rect)
      assert xml == ~s(<rectangle><topLeft x="5" y="10"/><width>20</width><height>15</height></rectangle>)
    end

    test "converts triangle to XML" do
      tri = Triangle.new({0, 0}, {10, 0}, {5, 10})
      xml = XmlVisitor.to_xml(tri)
      assert xml == ~s(<triangle><p1 x="0" y="0"/><p2 x="10" y="0"/><p3 x="5" y="10"/></triangle>)
    end
  end

  # ============================================================
  # 4. Area Visitor テスト
  # ============================================================

  describe "AreaVisitor" do
    test "calculates circle area" do
      circle = Circle.new({0, 0}, 1)
      area = AreaVisitor.calculate_area(circle)
      assert_in_delta area, :math.pi(), 0.0001
    end

    test "calculates circle area with radius 5" do
      circle = Circle.new({0, 0}, 5)
      area = AreaVisitor.calculate_area(circle)
      assert_in_delta area, :math.pi() * 25, 0.0001
    end

    test "calculates square area" do
      square = Square.new({0, 0}, 10)
      area = AreaVisitor.calculate_area(square)
      assert area == 100
    end

    test "calculates rectangle area" do
      rect = Rectangle.new({0, 0}, 20, 10)
      area = AreaVisitor.calculate_area(rect)
      assert area == 200
    end

    test "calculates triangle area" do
      tri = Triangle.new({0, 0}, {10, 0}, {5, 10})
      area = AreaVisitor.calculate_area(tri)
      assert area == 50  # base=10, height=10, area = 10*10/2 = 50
    end

    test "calculates total area of multiple shapes" do
      shapes = [
        Square.new({0, 0}, 10),      # 100
        Rectangle.new({0, 0}, 5, 4)  # 20
      ]
      total = AreaVisitor.total_area(shapes)
      assert total == 120
    end
  end

  # ============================================================
  # 5. Perimeter Visitor テスト
  # ============================================================

  describe "PerimeterVisitor" do
    test "calculates circle perimeter" do
      circle = Circle.new({0, 0}, 1)
      perimeter = PerimeterVisitor.calculate_perimeter(circle)
      assert_in_delta perimeter, 2 * :math.pi(), 0.0001
    end

    test "calculates square perimeter" do
      square = Square.new({0, 0}, 10)
      perimeter = PerimeterVisitor.calculate_perimeter(square)
      assert perimeter == 40
    end

    test "calculates rectangle perimeter" do
      rect = Rectangle.new({0, 0}, 20, 10)
      perimeter = PerimeterVisitor.calculate_perimeter(rect)
      assert perimeter == 60
    end

    test "calculates triangle perimeter" do
      tri = Triangle.new({0, 0}, {3, 0}, {0, 4})
      perimeter = PerimeterVisitor.calculate_perimeter(tri)
      # 3 + 4 + 5 (3-4-5 right triangle)
      assert_in_delta perimeter, 12, 0.0001
    end

    test "calculates total perimeter of multiple shapes" do
      shapes = [
        Square.new({0, 0}, 10),     # 40
        Square.new({0, 0}, 5)       # 20
      ]
      total = PerimeterVisitor.total_perimeter(shapes)
      assert total == 60
    end
  end

  # ============================================================
  # 6. SVG Visitor テスト
  # ============================================================

  describe "SvgVisitor" do
    test "converts circle to SVG" do
      circle = Circle.new({50, 50}, 25)
      svg = SvgVisitor.to_svg(circle)
      assert svg == ~s(<circle cx="50" cy="50" r="25" fill="none" stroke="black" stroke-width="1"/>)
    end

    test "converts circle to SVG with custom options" do
      circle = Circle.new({50, 50}, 25)
      svg = SvgVisitor.to_svg(circle, fill: "red", stroke: "blue", stroke_width: 2)
      assert svg == ~s(<circle cx="50" cy="50" r="25" fill="red" stroke="blue" stroke-width="2"/>)
    end

    test "converts square to SVG" do
      square = Square.new({10, 20}, 30)
      svg = SvgVisitor.to_svg(square)
      assert svg == ~s(<rect x="10" y="20" width="30" height="30" fill="none" stroke="black" stroke-width="1"/>)
    end

    test "converts rectangle to SVG" do
      rect = Rectangle.new({10, 20}, 40, 30)
      svg = SvgVisitor.to_svg(rect)
      assert svg == ~s(<rect x="10" y="20" width="40" height="30" fill="none" stroke="black" stroke-width="1"/>)
    end

    test "converts triangle to SVG" do
      tri = Triangle.new({0, 0}, {10, 0}, {5, 10})
      svg = SvgVisitor.to_svg(tri)
      assert svg == ~s(<polygon points="0,0 10,0 5,10" fill="none" stroke="black" stroke-width="1"/>)
    end
  end

  # ============================================================
  # 7. BoundingBox Visitor テスト
  # ============================================================

  describe "BoundingBoxVisitor" do
    test "calculates circle bounding box" do
      circle = Circle.new({50, 50}, 25)
      bbox = BoundingBoxVisitor.calculate_bbox(circle)
      assert bbox == {25, 25, 75, 75}
    end

    test "calculates square bounding box" do
      square = Square.new({10, 20}, 30)
      bbox = BoundingBoxVisitor.calculate_bbox(square)
      assert bbox == {10, 20, 40, 50}
    end

    test "calculates rectangle bounding box" do
      rect = Rectangle.new({10, 20}, 40, 30)
      bbox = BoundingBoxVisitor.calculate_bbox(rect)
      assert bbox == {10, 20, 50, 50}
    end

    test "calculates triangle bounding box" do
      tri = Triangle.new({0, 0}, {10, 0}, {5, 10})
      bbox = BoundingBoxVisitor.calculate_bbox(tri)
      assert bbox == {0, 0, 10, 10}
    end

    test "calculates combined bounding box" do
      shapes = [
        Circle.new({10, 10}, 5),       # {5, 5, 15, 15}
        Rectangle.new({20, 20}, 10, 10) # {20, 20, 30, 30}
      ]
      bbox = BoundingBoxVisitor.combined_bbox(shapes)
      assert bbox == {5, 5, 30, 30}
    end
  end

  # ============================================================
  # 8. CompositeVisitor テスト
  # ============================================================

  describe "CompositeVisitor" do
    test "applies multiple visitors to a shape" do
      circle = Circle.new({0, 0}, 5)

      results = CompositeVisitor.apply_all(circle, [
        {:json, JsonVisitor.new()},
        {:area, AreaVisitor.new()},
        {:perimeter, PerimeterVisitor.new()}
      ])

      assert results[:json] == ~s({"type":"circle","center":[0,0],"radius":5})
      assert_in_delta results[:area], :math.pi() * 25, 0.0001
      assert_in_delta results[:perimeter], 2 * :math.pi() * 5, 0.0001
    end

    test "maps visitor over multiple shapes" do
      shapes = [
        Circle.new({0, 0}, 1),
        Square.new({0, 0}, 2)
      ]

      areas = CompositeVisitor.map_shapes(shapes, AreaVisitor.new())
      assert_in_delta Enum.at(areas, 0), :math.pi(), 0.0001
      assert Enum.at(areas, 1) == 4
    end
  end

  # ============================================================
  # 9. DrawingContext テスト
  # ============================================================

  describe "DrawingContext" do
    test "creates empty context" do
      ctx = DrawingContext.new()
      assert ctx.shapes == []
    end

    test "adds shapes" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Circle.new({0, 0}, 5))
        |> DrawingContext.add_shape(Square.new({10, 10}, 10))

      assert length(ctx.shapes) == 2
    end

    test "converts to JSON" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Circle.new({0, 0}, 5))
        |> DrawingContext.add_shape(Square.new({10, 10}, 10))

      json = DrawingContext.to_json(ctx)
      assert json =~ "circle"
      assert json =~ "square"
      assert String.starts_with?(json, "[")
      assert String.ends_with?(json, "]")
    end

    test "converts to SVG" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Circle.new({50, 50}, 25))

      svg = DrawingContext.to_svg(ctx, width: 200, height: 200)
      assert svg =~ "<svg"
      assert svg =~ "width=\"200\""
      assert svg =~ "<circle"
      assert svg =~ "</svg>"
    end

    test "calculates total area" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Square.new({0, 0}, 10))
        |> DrawingContext.add_shape(Rectangle.new({0, 0}, 5, 4))

      total = DrawingContext.total_area(ctx)
      assert total == 120
    end

    test "calculates total perimeter" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Square.new({0, 0}, 10))

      total = DrawingContext.total_perimeter(ctx)
      assert total == 40
    end

    test "calculates bounding box" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Circle.new({10, 10}, 5))
        |> DrawingContext.add_shape(Square.new({20, 20}, 10))

      bbox = DrawingContext.bounding_box(ctx)
      assert bbox == {5, 5, 30, 30}
    end

    test "translates all shapes" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Circle.new({10, 10}, 5))
        |> DrawingContext.translate_all(5, 5)

      [circle] = ctx.shapes
      assert circle.center == {15, 15}
    end

    test "scales all shapes" do
      ctx = DrawingContext.new()
        |> DrawingContext.add_shape(Square.new({0, 0}, 10))
        |> DrawingContext.scale_all(2)

      [square] = ctx.shapes
      assert square.side == 20
    end
  end

  # ============================================================
  # Doctest
  # ============================================================

  doctest Chapter12.Circle
  doctest Chapter12.Square
  doctest Chapter12.Rectangle
  doctest Chapter12.Triangle
  doctest Chapter12.JsonVisitor
  doctest Chapter12.XmlVisitor
  doctest Chapter12.AreaVisitor
  doctest Chapter12.PerimeterVisitor
  doctest Chapter12.BoundingBoxVisitor
  doctest Chapter12.CompositeVisitor
end
