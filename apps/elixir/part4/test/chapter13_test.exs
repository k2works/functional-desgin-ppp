defmodule Chapter13Test do
  use ExUnit.Case, async: true

  alias Chapter13.{ShapeFactory, UIFactory, ThemeFactory, DatabaseFactory, FactoryProvider}
  alias Chapter13.Shapes.{Circle, Square, Rectangle}
  alias Chapter13.UIComponents.{Button, TextField, Checkbox}
  alias Chapter13.ThemeComponents.{Colors, Typography, Spacing}
  alias Chapter13.DatabaseComponents.{Connection, QueryBuilder}

  # ============================================================
  # 1. Shape Factory テスト
  # ============================================================

  describe "StandardShapeFactory" do
    setup do
      {:ok, factory: Chapter13.StandardShapeFactory.new()}
    end

    test "creates circle", %{factory: factory} do
      circle = ShapeFactory.create_circle(factory, {10, 20}, 5)
      assert circle.center == {10, 20}
      assert circle.radius == 5
      assert circle.outline_color == nil
      assert circle.fill_color == nil
    end

    test "creates square", %{factory: factory} do
      square = ShapeFactory.create_square(factory, {0, 0}, 10)
      assert square.top_left == {0, 0}
      assert square.side == 10
    end

    test "creates rectangle", %{factory: factory} do
      rect = ShapeFactory.create_rectangle(factory, {5, 10}, 20, 15)
      assert rect.top_left == {5, 10}
      assert rect.width == 20
      assert rect.height == 15
    end
  end

  describe "OutlinedShapeFactory" do
    setup do
      {:ok, factory: Chapter13.OutlinedShapeFactory.new("black", 2)}
    end

    test "creates circle with outline", %{factory: factory} do
      circle = ShapeFactory.create_circle(factory, {10, 20}, 5)
      assert circle.center == {10, 20}
      assert circle.radius == 5
      assert circle.outline_color == "black"
      assert circle.outline_width == 2
    end

    test "creates square with outline", %{factory: factory} do
      square = ShapeFactory.create_square(factory, {0, 0}, 10)
      assert square.outline_color == "black"
      assert square.outline_width == 2
    end

    test "creates rectangle with outline", %{factory: factory} do
      rect = ShapeFactory.create_rectangle(factory, {5, 10}, 20, 15)
      assert rect.outline_color == "black"
      assert rect.outline_width == 2
    end
  end

  describe "FilledShapeFactory" do
    setup do
      {:ok, factory: Chapter13.FilledShapeFactory.new("red")}
    end

    test "creates circle with fill", %{factory: factory} do
      circle = ShapeFactory.create_circle(factory, {10, 20}, 5)
      assert circle.fill_color == "red"
    end

    test "creates square with fill", %{factory: factory} do
      square = ShapeFactory.create_square(factory, {0, 0}, 10)
      assert square.fill_color == "red"
    end

    test "creates rectangle with fill", %{factory: factory} do
      rect = ShapeFactory.create_rectangle(factory, {5, 10}, 20, 15)
      assert rect.fill_color == "red"
    end
  end

  describe "StyledShapeFactory" do
    setup do
      {:ok, factory: Chapter13.StyledShapeFactory.new("black", 2, "blue")}
    end

    test "creates circle with outline and fill", %{factory: factory} do
      circle = ShapeFactory.create_circle(factory, {10, 20}, 5)
      assert circle.outline_color == "black"
      assert circle.outline_width == 2
      assert circle.fill_color == "blue"
    end

    test "creates square with outline and fill", %{factory: factory} do
      square = ShapeFactory.create_square(factory, {0, 0}, 10)
      assert square.outline_color == "black"
      assert square.outline_width == 2
      assert square.fill_color == "blue"
    end
  end

  describe "Shape to_string" do
    test "circle to_string without style" do
      circle = Circle.new({10, 20}, 5)
      assert Circle.to_string(circle) == "Circle center: [10, 20] radius: 5"
    end

    test "circle to_string with fill" do
      circle = %{Circle.new({10, 20}, 5) | fill_color: "red"}
      assert Circle.to_string(circle) =~ "fill: red"
    end

    test "square to_string" do
      square = Square.new({0, 0}, 10)
      assert Square.to_string(square) == "Square top-left: [0, 0] side: 10"
    end

    test "rectangle to_string" do
      rect = Rectangle.new({5, 10}, 20, 15)
      assert Rectangle.to_string(rect) == "Rectangle top-left: [5, 10] width: 20 height: 15"
    end
  end

  # ============================================================
  # 2. UI Factory テスト
  # ============================================================

  describe "WindowsUIFactory" do
    setup do
      {:ok, factory: Chapter13.WindowsUIFactory.new()}
    end

    test "creates Windows button", %{factory: factory} do
      button = UIFactory.create_button(factory, "Click Me")
      assert button.label == "Click Me"
      assert button.platform == :windows
    end

    test "creates Windows text field", %{factory: factory} do
      field = UIFactory.create_text_field(factory, "Enter text...")
      assert field.placeholder == "Enter text..."
      assert field.platform == :windows
    end

    test "creates Windows checkbox", %{factory: factory} do
      checkbox = UIFactory.create_checkbox(factory, "Accept", true)
      assert checkbox.label == "Accept"
      assert checkbox.checked == true
      assert checkbox.platform == :windows
    end

    test "renders Windows button", %{factory: factory} do
      button = UIFactory.create_button(factory, "OK")
      rendered = Button.render(button)
      assert rendered =~ "Windows Button"
      assert rendered =~ "OK"
    end
  end

  describe "MacOSUIFactory" do
    setup do
      {:ok, factory: Chapter13.MacOSUIFactory.new()}
    end

    test "creates macOS button", %{factory: factory} do
      button = UIFactory.create_button(factory, "Click Me")
      assert button.platform == :macos
    end

    test "renders macOS button", %{factory: factory} do
      button = UIFactory.create_button(factory, "OK")
      rendered = Button.render(button)
      assert rendered =~ "Mac Button"
    end

    test "renders macOS checkbox checked", %{factory: factory} do
      checkbox = UIFactory.create_checkbox(factory, "Accept", true)
      rendered = Checkbox.render(checkbox)
      assert rendered =~ "✓"
    end

    test "renders macOS checkbox unchecked", %{factory: factory} do
      checkbox = UIFactory.create_checkbox(factory, "Accept", false)
      rendered = Checkbox.render(checkbox)
      assert rendered =~ "○"
    end
  end

  describe "WebUIFactory" do
    setup do
      {:ok, factory: Chapter13.WebUIFactory.new()}
    end

    test "creates web button", %{factory: factory} do
      button = UIFactory.create_button(factory, "Click Me")
      assert button.platform == :web
    end

    test "renders web button as HTML", %{factory: factory} do
      button = UIFactory.create_button(factory, "Submit")
      rendered = Button.render(button)
      assert rendered =~ "<button>Submit</button>"
    end

    test "renders web text field as HTML", %{factory: factory} do
      field = UIFactory.create_text_field(factory, "Name")
      rendered = TextField.render(field)
      assert rendered =~ "<input"
      assert rendered =~ "placeholder=\"Name\""
    end

    test "renders web checkbox as HTML", %{factory: factory} do
      checkbox = UIFactory.create_checkbox(factory, "Terms", true)
      rendered = Checkbox.render(checkbox)
      assert rendered =~ "<input type=\"checkbox\""
      assert rendered =~ "checked"
      assert rendered =~ "<label>Terms</label>"
    end
  end

  describe "UI Factory with style" do
    test "Windows button with custom style" do
      factory = Chapter13.WindowsUIFactory.new(%{background: "#ff0000"})
      button = UIFactory.create_button(factory, "Red")
      rendered = Button.render(button)
      assert rendered =~ "bg=#ff0000"
    end
  end

  # ============================================================
  # 3. Theme Factory テスト
  # ============================================================

  describe "LightThemeFactory" do
    setup do
      {:ok, factory: Chapter13.LightThemeFactory.new()}
    end

    test "creates light colors", %{factory: factory} do
      colors = ThemeFactory.create_colors(factory)
      assert colors.background == "#ffffff"
      assert colors.text == "#000000"
    end

    test "creates typography", %{factory: factory} do
      typography = ThemeFactory.create_typography(factory)
      assert typography.font_family == "San Francisco"
      assert typography.base_size == 16
    end

    test "creates spacing", %{factory: factory} do
      spacing = ThemeFactory.create_spacing(factory)
      assert spacing.unit == 8
      assert is_list(spacing.scale)
    end
  end

  describe "DarkThemeFactory" do
    setup do
      {:ok, factory: Chapter13.DarkThemeFactory.new()}
    end

    test "creates dark colors", %{factory: factory} do
      colors = ThemeFactory.create_colors(factory)
      assert colors.background == "#1c1c1e"
      assert colors.text == "#ffffff"
    end

    test "creates typography", %{factory: factory} do
      typography = ThemeFactory.create_typography(factory)
      assert typography.font_family == "San Francisco"
    end
  end

  # ============================================================
  # 4. Database Factory テスト
  # ============================================================

  describe "MySQLFactory" do
    setup do
      config = %{database: "testdb", username: "user", password: "pass"}
      {:ok, factory: Chapter13.MySQLFactory.new(), config: config}
    end

    test "creates MySQL connection", %{factory: factory, config: config} do
      conn = DatabaseFactory.create_connection(factory, config)
      assert conn.driver == :mysql
      assert conn.port == 3306
      assert conn.database == "testdb"
    end

    test "generates MySQL connection string", %{factory: factory, config: config} do
      conn = DatabaseFactory.create_connection(factory, config)
      conn_str = Connection.connection_string(conn)
      assert conn_str =~ "mysql://"
      assert conn_str =~ "user:pass"
      assert conn_str =~ ":3306/"
    end

    test "creates MySQL query builder", %{factory: factory} do
      qb = DatabaseFactory.create_query_builder(factory)
      assert qb.driver == :mysql
    end

    test "builds MySQL SELECT query", %{factory: factory} do
      qb = DatabaseFactory.create_query_builder(factory)
        |> QueryBuilder.from("users")
        |> QueryBuilder.select(["id", "name"])
        |> QueryBuilder.where("active = 1")
        |> QueryBuilder.order_by("name", :asc)
        |> QueryBuilder.limit(10)

      query = QueryBuilder.build(qb)
      assert query.driver == :mysql
      assert query.sql == "SELECT id, name FROM users WHERE active = 1 ORDER BY name ASC LIMIT 10"
    end
  end

  describe "PostgreSQLFactory" do
    setup do
      config = %{database: "testdb", username: "user", password: "pass"}
      {:ok, factory: Chapter13.PostgreSQLFactory.new(), config: config}
    end

    test "creates PostgreSQL connection", %{factory: factory, config: config} do
      conn = DatabaseFactory.create_connection(factory, config)
      assert conn.driver == :postgresql
      assert conn.port == 5432
    end

    test "generates PostgreSQL connection string", %{factory: factory, config: config} do
      conn = DatabaseFactory.create_connection(factory, config)
      conn_str = Connection.connection_string(conn)
      assert conn_str =~ "postgresql://"
    end

    test "builds PostgreSQL SELECT query", %{factory: factory} do
      qb = DatabaseFactory.create_query_builder(factory)
        |> QueryBuilder.from("products")
        |> QueryBuilder.where("price > 100")

      query = QueryBuilder.build(qb)
      assert query.driver == :postgresql
      assert query.sql == "SELECT * FROM products WHERE price > 100"
    end
  end

  describe "SQLiteFactory" do
    setup do
      config = %{database: "/path/to/db.sqlite"}
      {:ok, factory: Chapter13.SQLiteFactory.new(), config: config}
    end

    test "creates SQLite connection", %{factory: factory, config: config} do
      conn = DatabaseFactory.create_connection(factory, config)
      assert conn.driver == :sqlite
      assert conn.host == nil
      assert conn.port == nil
    end

    test "generates SQLite connection string", %{factory: factory, config: config} do
      conn = DatabaseFactory.create_connection(factory, config)
      conn_str = Connection.connection_string(conn)
      assert conn_str == "sqlite:/path/to/db.sqlite"
    end

    test "builds SQLite SELECT query", %{factory: factory} do
      qb = DatabaseFactory.create_query_builder(factory)
        |> QueryBuilder.from("items")

      query = QueryBuilder.build(qb)
      assert query.driver == :sqlite
      assert query.sql == "SELECT * FROM items"
    end
  end

  # ============================================================
  # 5. Factory Provider テスト
  # ============================================================

  describe "FactoryProvider - Shape Factories" do
    test "gets standard factory" do
      factory = FactoryProvider.get_shape_factory(:standard)
      circle = ShapeFactory.create_circle(factory, {0, 0}, 5)
      assert circle.outline_color == nil
    end

    test "gets outlined factory with default" do
      factory = FactoryProvider.get_shape_factory(:outlined)
      circle = ShapeFactory.create_circle(factory, {0, 0}, 5)
      assert circle.outline_color == "black"
    end

    test "gets outlined factory with params" do
      factory = FactoryProvider.get_shape_factory({:outlined, "red", 3})
      circle = ShapeFactory.create_circle(factory, {0, 0}, 5)
      assert circle.outline_color == "red"
      assert circle.outline_width == 3
    end

    test "gets filled factory" do
      factory = FactoryProvider.get_shape_factory({:filled, "blue"})
      circle = ShapeFactory.create_circle(factory, {0, 0}, 5)
      assert circle.fill_color == "blue"
    end

    test "gets styled factory" do
      factory = FactoryProvider.get_shape_factory({:styled, "black", 2, "red"})
      circle = ShapeFactory.create_circle(factory, {0, 0}, 5)
      assert circle.outline_color == "black"
      assert circle.fill_color == "red"
    end
  end

  describe "FactoryProvider - UI Factories" do
    test "gets Windows factory" do
      factory = FactoryProvider.get_ui_factory(:windows)
      button = UIFactory.create_button(factory, "Test")
      assert button.platform == :windows
    end

    test "gets macOS factory" do
      factory = FactoryProvider.get_ui_factory(:macos)
      button = UIFactory.create_button(factory, "Test")
      assert button.platform == :macos
    end

    test "gets Web factory" do
      factory = FactoryProvider.get_ui_factory(:web)
      button = UIFactory.create_button(factory, "Test")
      assert button.platform == :web
    end

    test "gets factory with style" do
      factory = FactoryProvider.get_ui_factory({:windows, %{background: "red"}})
      button = UIFactory.create_button(factory, "Test")
      assert button.style.background == "red"
    end
  end

  describe "FactoryProvider - Theme Factories" do
    test "gets light theme factory" do
      factory = FactoryProvider.get_theme_factory(:light)
      colors = ThemeFactory.create_colors(factory)
      assert colors.background == "#ffffff"
    end

    test "gets dark theme factory" do
      factory = FactoryProvider.get_theme_factory(:dark)
      colors = ThemeFactory.create_colors(factory)
      assert colors.background == "#1c1c1e"
    end
  end

  describe "FactoryProvider - Database Factories" do
    test "gets MySQL factory" do
      factory = FactoryProvider.get_database_factory(:mysql)
      qb = DatabaseFactory.create_query_builder(factory)
      assert qb.driver == :mysql
    end

    test "gets PostgreSQL factory" do
      factory = FactoryProvider.get_database_factory(:postgresql)
      qb = DatabaseFactory.create_query_builder(factory)
      assert qb.driver == :postgresql
    end

    test "gets SQLite factory" do
      factory = FactoryProvider.get_database_factory(:sqlite)
      qb = DatabaseFactory.create_query_builder(factory)
      assert qb.driver == :sqlite
    end
  end

  # ============================================================
  # Doctest
  # ============================================================

  doctest Chapter13.FactoryProvider
end
