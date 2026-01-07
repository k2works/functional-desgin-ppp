package abstractfactorypattern

import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers

class AbstractFactoryPatternSpec extends AnyFunSpec with Matchers:

  // ============================================
  // 1. Shape 基本テスト
  // ============================================

  describe("Shape") {
    describe("Circle") {
      val circle = Circle(Point(10, 20), 5)

      it("translate は中心を移動する") {
        val moved = circle.translate(5, 10)
        moved.center shouldBe Point(15, 30)
      }

      it("scale は半径を拡大する") {
        val scaled = circle.scale(2)
        scaled.radius shouldBe 10
      }

      it("withStyle はスタイルを変更する") {
        val newStyle = ShapeStyle(Color.Red, 2.0, Color.Blue)
        val styled = circle.withStyle(newStyle)
        styled.style shouldBe newStyle
      }
    }

    describe("Square") {
      val square = Square(Point(0, 0), 10)

      it("translate は左上を移動する") {
        val moved = square.translate(5, 5)
        moved.topLeft shouldBe Point(5, 5)
      }

      it("scale は辺を拡大する") {
        val scaled = square.scale(2)
        scaled.side shouldBe 20
      }
    }

    describe("Rectangle") {
      val rect = Rectangle(Point(0, 0), 10, 20)

      it("scale は幅と高さを拡大する") {
        val scaled = rect.scale(2)
        scaled.width shouldBe 20
        scaled.height shouldBe 40
      }
    }
  }

  // ============================================
  // 2. ShapeFactory テスト
  // ============================================

  describe("ShapeFactory") {
    describe("StandardShapeFactory") {
      val factory = StandardShapeFactory

      it("円を作成する") {
        val circle = factory.createCircle(Point(10, 20), 5)
        circle.center shouldBe Point(10, 20)
        circle.radius shouldBe 5
        circle.style shouldBe ShapeStyle()
      }

      it("正方形を作成する") {
        val square = factory.createSquare(Point(0, 0), 10)
        square.topLeft shouldBe Point(0, 0)
        square.side shouldBe 10
      }

      it("長方形を作成する") {
        val rect = factory.createRectangle(Point(0, 0), 10, 20)
        rect.width shouldBe 10
        rect.height shouldBe 20
      }

      it("三角形を作成する") {
        val triangle = factory.createTriangle(Point(0, 0), Point(10, 0), Point(5, 10))
        triangle.p1 shouldBe Point(0, 0)
      }
    }

    describe("OutlinedShapeFactory") {
      val factory = OutlinedShapeFactory(Color.Red, 3.0)

      it("輪郭線スタイル付きの円を作成する") {
        val circle = factory.createCircle(Point(10, 20), 5)
        circle.style.strokeColor shouldBe Color.Red
        circle.style.strokeWidth shouldBe 3.0
      }

      it("輪郭線スタイル付きの正方形を作成する") {
        val square = factory.createSquare(Point(0, 0), 10)
        square.style.strokeColor shouldBe Color.Red
        square.style.strokeWidth shouldBe 3.0
      }
    }

    describe("FilledShapeFactory") {
      val factory = FilledShapeFactory(Color.Blue)

      it("塗りつぶしスタイル付きの円を作成する") {
        val circle = factory.createCircle(Point(10, 20), 5)
        circle.style.fillColor shouldBe Color.Blue
      }

      it("塗りつぶしと輪郭線スタイル付きの図形を作成する") {
        val factory2 = FilledShapeFactory(Color.Green, Color.Red, 2.0)
        val rect = factory2.createRectangle(Point(0, 0), 10, 20)
        rect.style.fillColor shouldBe Color.Green
        rect.style.strokeColor shouldBe Color.Red
        rect.style.strokeWidth shouldBe 2.0
      }
    }

    describe("ファクトリの切り替え") {
      def createShapes(factory: ShapeFactory): List[Shape] =
        List(
          factory.createCircle(Point(0, 0), 5),
          factory.createSquare(Point(10, 10), 10),
          factory.createRectangle(Point(20, 20), 10, 5)
        )

      it("StandardFactory で図形を作成する") {
        val shapes = createShapes(StandardShapeFactory)
        shapes.length shouldBe 3
        shapes.head.style shouldBe ShapeStyle()
      }

      it("OutlinedFactory で図形を作成する") {
        val shapes = createShapes(OutlinedShapeFactory(Color.Black, 2.0))
        shapes.length shouldBe 3
        shapes.head.style.strokeWidth shouldBe 2.0
      }

      it("FilledFactory で図形を作成する") {
        val shapes = createShapes(FilledShapeFactory(Color.Red))
        shapes.length shouldBe 3
        shapes.head.style.fillColor shouldBe Color.Red
      }
    }
  }

  // ============================================
  // 3. UIFactory テスト
  // ============================================

  describe("UIFactory") {
    describe("WindowsUIFactory") {
      val factory = WindowsUIFactory()

      it("ボタンを作成する") {
        val button = factory.createButton("OK")
        button.label shouldBe "OK"
        button.render should include("OK")
        button.render should include("[")
      }

      it("テキストフィールドを作成する") {
        val field = factory.createTextField("Name")
        field.placeholder shouldBe "Name"
        field.render should include("|")
      }

      it("チェックボックスを作成する") {
        val checkbox = factory.createCheckbox("Accept", false)
        checkbox.label shouldBe "Accept"
        checkbox.checked shouldBe false
        checkbox.render should include("[ ]")
        
        val toggled = checkbox.toggle
        toggled.checked shouldBe true
        toggled.render should include("[X]")
      }

      it("ダークテーマをサポートする") {
        val darkFactory = WindowsUIFactory(Theme.Dark)
        val button = darkFactory.createButton("Dark")
        button.theme shouldBe Theme.Dark
      }
    }

    describe("MacOSUIFactory") {
      val factory = MacOSUIFactory()

      it("ボタンを作成する") {
        val button = factory.createButton("OK")
        button.render should include("(")
        button.render should include(")")
      }

      it("チェックボックスを作成する") {
        val checkbox = factory.createCheckbox("Accept", true)
        checkbox.render should include("(✓)")
      }
    }

    describe("WebUIFactory") {
      val factory = WebUIFactory()

      it("ボタンを作成する") {
        val button = factory.createButton("Submit")
        button.render should include("<button")
        button.render should include("Submit")
        button.render should include("</button>")
      }

      it("テキストフィールドを作成する") {
        val field = factory.createTextField("Email")
        field.render should include("<input")
        field.render should include("placeholder=\"Email\"")
      }

      it("チェックボックスを作成する") {
        val checkbox = factory.createCheckbox("Subscribe", false)
        checkbox.render should include("<input type=\"checkbox\"")
        checkbox.render should include("<label>")
      }

      it("テキストフィールドに値を設定できる") {
        val field = factory.createTextField("Name")
        val updated = field.setValue("John")
        updated.value shouldBe "John"
        updated.render should include("value=\"John\"")
      }
    }

    describe("ファクトリの切り替え") {
      def createForm(factory: UIFactory): Map[String, String] =
        Map(
          "button" -> factory.createButton("Submit").render,
          "field" -> factory.createTextField("Email").render,
          "checkbox" -> factory.createCheckbox("Accept").render
        )

      it("異なるプラットフォームで異なる UI を生成する") {
        val windowsForm = createForm(WindowsUIFactory())
        val macForm = createForm(MacOSUIFactory())
        val webForm = createForm(WebUIFactory())

        windowsForm("button") should include("[")
        macForm("button") should include("(")
        webForm("button") should include("<button")
      }
    }
  }

  // ============================================
  // 4. DatabaseFactory テスト
  // ============================================

  describe("DatabaseFactory") {
    describe("PostgreSQLFactory") {
      val factory = PostgreSQLFactory

      it("接続を作成する") {
        val conn = factory.createConnection("mydb")
        conn.database shouldBe "mydb"
        conn.isConnected shouldBe false
        
        val connected = conn.connect()
        connected.isConnected shouldBe true
      }

      it("クエリビルダーを作成する") {
        val builder = factory.createQueryBuilder()
        val query = builder
          .select("id", "name")
          .from("users")
          .where("active = true")
          .orderBy("name")
          .limit(10)
          .build
        
        query shouldBe "SELECT id, name FROM users WHERE active = true ORDER BY name ASC LIMIT 10"
      }

      it("データベースタイプを返す") {
        factory.databaseType shouldBe "PostgreSQL"
      }
    }

    describe("MySQLFactory") {
      val factory = MySQLFactory

      it("クエリビルダーを作成する（バッククォート付き）") {
        val builder = factory.createQueryBuilder()
        val query = builder
          .select("id", "name")
          .from("users")
          .build
        
        query should include("`users`")
      }
    }

    describe("SQLiteFactory") {
      val factory = SQLiteFactory

      it("接続を作成する") {
        val conn = factory.createConnection("test.db")
        conn.database shouldBe "test.db"
      }

      it("クエリを実行する") {
        val conn = factory.createConnection("test.db").connect()
        val result = conn.execute("SELECT 1")
        result.rows.head.head.toString should include("SQLite")
      }
    }

    describe("ファクトリの切り替え") {
      def executeQuery(factory: DatabaseFactory, db: String): QueryResult =
        val conn = factory.createConnection(db).connect()
        val query = factory.createQueryBuilder()
          .select("*")
          .from("users")
          .build
        conn.execute(query)

      it("異なるデータベースで同じ操作を実行できる") {
        val pgResult = executeQuery(PostgreSQLFactory, "pg_db")
        val mysqlResult = executeQuery(MySQLFactory, "mysql_db")
        val sqliteResult = executeQuery(SQLiteFactory, "sqlite.db")

        pgResult.rows.head.head.toString should include("PostgreSQL")
        mysqlResult.rows.head.head.toString should include("MySQL")
        sqliteResult.rows.head.head.toString should include("SQLite")
      }
    }
  }

  // ============================================
  // 5. 関数型アプローチ
  // ============================================

  describe("FunctionalFactory") {
    import FunctionalFactory._

    it("設定からスタイルを生成する") {
      val config = FactoryConfig(Color.Red, 2.0, Color.Blue)
      config.style.strokeColor shouldBe Color.Red
      config.style.strokeWidth shouldBe 2.0
      config.style.fillColor shouldBe Color.Blue
    }

    it("図形作成関数を生成する") {
      val config = FactoryConfig(fillColor = Color.Green)
      val createCircle = circleCreator(config) _
      
      val circle = createCircle(Point(10, 20), 5)
      circle.center shouldBe Point(10, 20)
      circle.style.fillColor shouldBe Color.Green
    }

    it("ファクトリを合成する") {
      val config = composeFactory(
        FactoryConfig(),
        withStroke(Color.Red, 2.0),
        withFill(Color.Blue)
      )
      
      config.strokeColor shouldBe Color.Red
      config.strokeWidth shouldBe 2.0
      config.fillColor shouldBe Color.Blue
    }

    it("合成したファクトリで図形を作成する") {
      val config = composeFactory(
        FactoryConfig(),
        withStroke(Color.Black, 3.0),
        withFill(Color.Green)
      )
      
      val square = squareCreator(config)(Point(0, 0), 10)
      square.style.strokeColor shouldBe Color.Black
      square.style.strokeWidth shouldBe 3.0
      square.style.fillColor shouldBe Color.Green
    }
  }

  // ============================================
  // 6. ファクトリレジストリ
  // ============================================

  describe("FactoryRegistry") {
    it("ShapeFactory を取得する") {
      val factory = FactoryRegistry.getShapeFactory("standard")
      factory shouldBe defined
      factory.get shouldBe StandardShapeFactory
    }

    it("UIFactory を取得する") {
      val factory = FactoryRegistry.getUIFactory("windows")
      factory shouldBe defined
    }

    it("DatabaseFactory を取得する") {
      val factory = FactoryRegistry.getDatabaseFactory("postgresql")
      factory shouldBe defined
      factory.get.databaseType shouldBe "PostgreSQL"
    }

    it("存在しないファクトリは None を返す") {
      FactoryRegistry.getShapeFactory("unknown") shouldBe None
    }

    it("カスタムファクトリを登録できる") {
      val customFactory = FilledShapeFactory(Color.Red, Color.Black, 5.0)
      FactoryRegistry.registerShapeFactory("custom", customFactory)
      
      val retrieved = FactoryRegistry.getShapeFactory("custom")
      retrieved shouldBe defined
    }
  }
