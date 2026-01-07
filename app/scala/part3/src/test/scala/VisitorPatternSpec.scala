package visitorpattern

import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers

class VisitorPatternSpec extends AnyFunSpec with Matchers:

  // ============================================
  // 1. 図形の基本操作
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

      it("translate は左上を移動する") {
        val moved = rect.translate(5, 5)
        moved.topLeft shouldBe Point(5, 5)
      }

      it("scale は幅と高さを拡大する") {
        val scaled = rect.scale(2)
        scaled.width shouldBe 20
        scaled.height shouldBe 40
      }
    }

    describe("Triangle") {
      val triangle = Triangle(Point(0, 0), Point(10, 0), Point(5, 10))

      it("translate は全ての頂点を移動する") {
        val moved = triangle.translate(5, 5)
        moved.p1 shouldBe Point(5, 5)
        moved.p2 shouldBe Point(15, 5)
        moved.p3 shouldBe Point(10, 15)
      }
    }

    describe("CompositeShape") {
      val composite = CompositeShape(List(
        Circle(Point(0, 0), 5),
        Square(Point(10, 10), 5)
      ))

      it("translate は全ての子を移動する") {
        val moved = composite.translate(5, 5).asInstanceOf[CompositeShape]
        moved.shapes(0).asInstanceOf[Circle].center shouldBe Point(5, 5)
        moved.shapes(1).asInstanceOf[Square].topLeft shouldBe Point(15, 15)
      }
    }
  }

  // ============================================
  // 2. AreaVisitor
  // ============================================

  describe("AreaVisitor") {
    it("円の面積を計算する") {
      val circle = Circle(Point(0, 0), 5)
      circle.accept(AreaVisitor) shouldBe (math.Pi * 25) +- 0.001
    }

    it("正方形の面積を計算する") {
      val square = Square(Point(0, 0), 10)
      square.accept(AreaVisitor) shouldBe 100.0
    }

    it("長方形の面積を計算する") {
      val rect = Rectangle(Point(0, 0), 10, 20)
      rect.accept(AreaVisitor) shouldBe 200.0
    }

    it("三角形の面積を計算する") {
      val triangle = Triangle(Point(0, 0), Point(10, 0), Point(0, 10))
      triangle.accept(AreaVisitor) shouldBe 50.0
    }

    it("複合図形の面積を計算する") {
      val composite = CompositeShape(List(
        Square(Point(0, 0), 10),
        Rectangle(Point(0, 0), 5, 10)
      ))
      composite.accept(AreaVisitor) shouldBe 150.0
    }
  }

  // ============================================
  // 3. PerimeterVisitor
  // ============================================

  describe("PerimeterVisitor") {
    it("円の周囲長を計算する") {
      val circle = Circle(Point(0, 0), 5)
      circle.accept(PerimeterVisitor) shouldBe (2 * math.Pi * 5) +- 0.001
    }

    it("正方形の周囲長を計算する") {
      val square = Square(Point(0, 0), 10)
      square.accept(PerimeterVisitor) shouldBe 40.0
    }

    it("長方形の周囲長を計算する") {
      val rect = Rectangle(Point(0, 0), 10, 20)
      rect.accept(PerimeterVisitor) shouldBe 60.0
    }

    it("三角形の周囲長を計算する") {
      val triangle = Triangle(Point(0, 0), Point(3, 0), Point(0, 4))
      triangle.accept(PerimeterVisitor) shouldBe 12.0 +- 0.001
    }
  }

  // ============================================
  // 4. JsonVisitor
  // ============================================

  describe("JsonVisitor") {
    it("円を JSON に変換する") {
      val circle = Circle(Point(10, 20), 5)
      val json = circle.accept(JsonVisitor)
      json should include("\"type\":\"circle\"")
      json should include("\"center\":{\"x\":10.0,\"y\":20.0}")
      json should include("\"radius\":5.0")
    }

    it("正方形を JSON に変換する") {
      val square = Square(Point(0, 0), 10)
      val json = square.accept(JsonVisitor)
      json should include("\"type\":\"square\"")
      json should include("\"side\":10.0")
    }

    it("複合図形を JSON に変換する") {
      val composite = CompositeShape(List(
        Circle(Point(0, 0), 5),
        Square(Point(10, 10), 5)
      ))
      val json = composite.accept(JsonVisitor)
      json should include("\"type\":\"composite\"")
      json should include("\"shapes\":[")
    }
  }

  // ============================================
  // 5. XmlVisitor
  // ============================================

  describe("XmlVisitor") {
    it("円を XML に変換する") {
      val circle = Circle(Point(10, 20), 5)
      val xml = circle.accept(XmlVisitor)
      xml should include("<circle>")
      xml should include("<center x=\"10.0\" y=\"20.0\"/>")
      xml should include("<radius>5.0</radius>")
    }

    it("正方形を XML に変換する") {
      val square = Square(Point(0, 0), 10)
      val xml = square.accept(XmlVisitor)
      xml should include("<square>")
      xml should include("<side>10.0</side>")
    }
  }

  // ============================================
  // 6. BoundingBoxVisitor
  // ============================================

  describe("BoundingBoxVisitor") {
    it("円のバウンディングボックスを計算する") {
      val circle = Circle(Point(10, 10), 5)
      val bb = circle.accept(BoundingBoxVisitor)
      bb shouldBe BoundingBox(5, 5, 15, 15)
    }

    it("正方形のバウンディングボックスを計算する") {
      val square = Square(Point(0, 0), 10)
      val bb = square.accept(BoundingBoxVisitor)
      bb shouldBe BoundingBox(0, 0, 10, 10)
    }

    it("複合図形のバウンディングボックスを計算する") {
      val composite = CompositeShape(List(
        Circle(Point(0, 0), 5),
        Square(Point(10, 10), 5)
      ))
      val bb = composite.accept(BoundingBoxVisitor)
      bb.minX shouldBe -5
      bb.minY shouldBe -5
      bb.maxX shouldBe 15
      bb.maxY shouldBe 15
    }
  }

  // ============================================
  // 7. DrawVisitor
  // ============================================

  describe("DrawVisitor") {
    it("円から描画コマンドを生成する") {
      val circle = Circle(Point(10, 20), 5)
      val cmd = circle.accept(DrawVisitor)
      cmd shouldBe DrawCircle(Point(10, 20), 5)
    }

    it("正方形から描画コマンドを生成する") {
      val square = Square(Point(0, 0), 10)
      val cmd = square.accept(DrawVisitor)
      cmd shouldBe DrawRect(Point(0, 0), 10, 10)
    }

    it("三角形から描画コマンドを生成する") {
      val triangle = Triangle(Point(0, 0), Point(10, 0), Point(5, 10))
      val cmd = triangle.accept(DrawVisitor)
      cmd shouldBe DrawPolygon(List(Point(0, 0), Point(10, 0), Point(5, 10)))
    }

    it("複合図形からグループコマンドを生成する") {
      val composite = CompositeShape(List(
        Circle(Point(0, 0), 5),
        Square(Point(10, 10), 5)
      ))
      val cmd = composite.accept(DrawVisitor)
      cmd shouldBe a[DrawGroup]
      cmd.asInstanceOf[DrawGroup].commands.length shouldBe 2
    }
  }

  // ============================================
  // 8. 型クラスベースの Visitor
  // ============================================

  describe("型クラスベースの Visitor") {
    import Serializable.given
    import HasArea.given
    import HasPerimeter.given

    it("Circle を JSON に変換する") {
      val circle = Circle(Point(10, 20), 5)
      circle.toJson should include("\"type\":\"circle\"")
    }

    it("Square を XML に変換する") {
      val square = Square(Point(0, 0), 10)
      square.toXml should include("<square>")
    }

    it("Circle の面積を計算する") {
      val circle = Circle(Point(0, 0), 5)
      circle.area shouldBe (math.Pi * 25) +- 0.001
    }

    it("Rectangle の周囲長を計算する") {
      val rect = Rectangle(Point(0, 0), 10, 20)
      rect.perimeter shouldBe 60.0
    }
  }

  // ============================================
  // 9. パターンマッチベースの Visitor
  // ============================================

  describe("PatternMatchVisitor") {
    it("面積を計算する") {
      val circle = Circle(Point(0, 0), 5)
      PatternMatchVisitor.calculateArea(circle) shouldBe (math.Pi * 25) +- 0.001
    }

    it("周囲長を計算する") {
      val square = Square(Point(0, 0), 10)
      PatternMatchVisitor.calculatePerimeter(square) shouldBe 40.0
    }

    it("JSON に変換する") {
      val rect = Rectangle(Point(0, 0), 10, 20)
      val json = PatternMatchVisitor.toJson(rect)
      json should include("\"type\":\"rectangle\"")
    }

    it("複合図形を処理する") {
      val composite = CompositeShape(List(
        Square(Point(0, 0), 10),
        Square(Point(0, 0), 5)
      ))
      PatternMatchVisitor.calculateArea(composite) shouldBe 125.0
    }
  }

  // ============================================
  // 10. 式木 Visitor
  // ============================================

  describe("ExprVisitor") {
    val expr = Add(Mul(Num(2), Var("x")), Num(3))

    describe("EvalVisitor") {
      it("式を評価する") {
        val env = Map("x" -> 5.0)
        expr.accept(EvalVisitor(env)) shouldBe 13.0
      }

      it("変数がない場合は 0 として評価する") {
        expr.accept(EvalVisitor()) shouldBe 3.0
      }
    }

    describe("PrintVisitor") {
      it("式を文字列化する") {
        expr.accept(PrintVisitor) shouldBe "((2.0 * x) + 3.0)"
      }
    }

    describe("VarCollector") {
      it("変数を収集する") {
        val expr2 = Add(Var("x"), Mul(Var("y"), Var("x")))
        expr2.accept(VarCollector) shouldBe Set("x", "y")
      }
    }

    describe("SimplifyVisitor") {
      it("0 との加算を簡約する") {
        Add(Num(0), Var("x")).accept(SimplifyVisitor) shouldBe Var("x")
        Add(Var("x"), Num(0)).accept(SimplifyVisitor) shouldBe Var("x")
      }

      it("0 との減算を簡約する") {
        Sub(Var("x"), Num(0)).accept(SimplifyVisitor) shouldBe Var("x")
      }

      it("同じ式の減算を 0 にする") {
        Sub(Var("x"), Var("x")).accept(SimplifyVisitor) shouldBe Num(0)
      }

      it("0 との乗算を 0 にする") {
        Mul(Num(0), Var("x")).accept(SimplifyVisitor) shouldBe Num(0)
        Mul(Var("x"), Num(0)).accept(SimplifyVisitor) shouldBe Num(0)
      }

      it("1 との乗算を簡約する") {
        Mul(Num(1), Var("x")).accept(SimplifyVisitor) shouldBe Var("x")
        Mul(Var("x"), Num(1)).accept(SimplifyVisitor) shouldBe Var("x")
      }

      it("定数式を計算する") {
        Add(Num(2), Num(3)).accept(SimplifyVisitor) shouldBe Num(5)
        Mul(Num(2), Num(3)).accept(SimplifyVisitor) shouldBe Num(6)
      }
    }
  }

  // ============================================
  // 11. ファイルシステム Visitor
  // ============================================

  describe("FileVisitor") {
    val fileSystem = Directory("root", List(
      File("file1.txt", 100),
      File("file2.txt", 200),
      Directory("subdir", List(
        File("file3.txt", 150),
        File("file4.txt", 50)
      ))
    ))

    describe("SizeVisitor") {
      it("ファイルサイズを返す") {
        File("test.txt", 100).accept(SizeVisitor) shouldBe 100
      }

      it("ディレクトリの合計サイズを計算する") {
        fileSystem.accept(SizeVisitor) shouldBe 500
      }
    }

    describe("FileCountVisitor") {
      it("ファイル数を数える") {
        fileSystem.accept(FileCountVisitor) shouldBe 4
      }
    }

    describe("PathListVisitor") {
      it("パス一覧を取得する") {
        val paths = fileSystem.accept(new PathListVisitor())
        paths should contain("/root")
        paths should contain("/root/file1.txt")
        paths should contain("/root/subdir")
        paths should contain("/root/subdir/file3.txt")
      }
    }

    describe("SearchVisitor") {
      it("条件に一致するファイルを検索する") {
        val largeFilePredicate: FileEntry => Boolean = {
          case f: File => f.size > 100
          case _ => false
        }
        val largeFiles = fileSystem.accept(new SearchVisitor(largeFilePredicate))
        largeFiles.map(_.name) should contain allOf ("file2.txt", "file3.txt")
      }

      it("ディレクトリを検索する") {
        val dirs = fileSystem.accept(new SearchVisitor(_.isInstanceOf[Directory]))
        dirs.length shouldBe 2
      }
    }
  }
