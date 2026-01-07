import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import PatternInteractions.*

class PatternInteractionsSpec extends AnyFunSpec with Matchers:

  describe("基本図形"):
    describe("Circle"):
      it("円を作成できる"):
        val circle = Circle(0, 0, 10)
        circle.x shouldBe 0
        circle.y shouldBe 0
        circle.radius shouldBe 10

      it("円を移動できる"):
        val circle = Circle(0, 0, 10).move(5, 3)
        circle.x shouldBe 5
        circle.y shouldBe 3

      it("円を拡大できる"):
        val circle = Circle(0, 0, 10).scale(2)
        circle.radius shouldBe 20

      it("円の面積を計算できる"):
        val circle = Circle(0, 0, 10)
        circle.area shouldBe (Math.PI * 100) +- 0.001

      it("円を描画できる"):
        val circle = Circle(0, 0, 10)
        circle.draw should include("Circle")

    describe("Rectangle"):
      it("矩形を作成できる"):
        val rect = Rectangle(0, 0, 10, 20)
        rect.width shouldBe 10
        rect.height shouldBe 20

      it("矩形を移動できる"):
        val rect = Rectangle(0, 0, 10, 20).move(5, 3)
        rect.x shouldBe 5
        rect.y shouldBe 3

      it("矩形を拡大できる"):
        val rect = Rectangle(0, 0, 10, 20).scale(2)
        rect.width shouldBe 20
        rect.height shouldBe 40

      it("矩形の面積を計算できる"):
        val rect = Rectangle(0, 0, 10, 20)
        rect.area shouldBe 200

    describe("Triangle"):
      it("三角形を作成できる"):
        val tri = Triangle(0, 0, 10, 0, 5, 10)
        tri.area shouldBe 50

      it("三角形を移動できる"):
        val tri = Triangle(0, 0, 10, 0, 5, 10).move(5, 5)
        tri.x1 shouldBe 5
        tri.y1 shouldBe 5

  describe("Composite パターン"):
    it("複合図形を作成できる"):
      val composite = CompositeShape()
      composite.shapes shouldBe empty

    it("図形を追加できる"):
      val composite = CompositeShape()
        .add(Circle(0, 0, 10))
        .add(Rectangle(0, 0, 10, 20))
      composite.shapes.length shouldBe 2

    it("図形を削除できる"):
      val circle = Circle(0, 0, 10)
      val composite = CompositeShape()
        .add(circle)
        .add(Rectangle(0, 0, 10, 20))
        .remove(circle)
      composite.shapes.length shouldBe 1

    it("複合図形を移動できる"):
      val composite = CompositeShape(Circle(0, 0, 10), Rectangle(0, 0, 10, 20))
        .move(5, 3)
      composite.shapes(0).asInstanceOf[Circle].x shouldBe 5
      composite.shapes(1).asInstanceOf[Rectangle].x shouldBe 5

    it("複合図形を拡大できる"):
      val composite = CompositeShape(Circle(0, 0, 10), Rectangle(0, 0, 10, 20))
        .scale(2)
      composite.shapes(0).asInstanceOf[Circle].radius shouldBe 20
      composite.shapes(1).asInstanceOf[Rectangle].width shouldBe 20

    it("複合図形の面積を計算できる"):
      val composite = CompositeShape(Circle(0, 0, 10), Rectangle(0, 0, 10, 20))
      composite.area shouldBe (Math.PI * 100 + 200) +- 0.001

  describe("Decorator パターン"):
    describe("JournaledShape"):
      it("操作履歴を記録する"):
        val journaled = JournaledShape(Circle(0, 0, 10))
          .move(5, 3)
          .scale(2)
        journaled.getJournal.length shouldBe 2

      it("履歴の内容を確認できる"):
        val journaled = JournaledShape(Circle(0, 0, 10))
          .move(5, 3)
        journaled.getJournal.head.operation should include("move")

      it("drawに履歴数が含まれる"):
        val journaled = JournaledShape(Circle(0, 0, 10))
          .move(5, 3)
        journaled.draw should include("1 ops")

    describe("ColoredShape"):
      it("色を設定できる"):
        val colored = ColoredShape(Circle(0, 0, 10), "red")
        colored.color shouldBe "red"

      it("drawに色が含まれる"):
        val colored = ColoredShape(Circle(0, 0, 10), "red")
        colored.draw should include("[red]")

      it("色を変更できる"):
        val colored = ColoredShape(Circle(0, 0, 10), "red").withColor("blue")
        colored.color shouldBe "blue"

    describe("BorderedShape"):
      it("枠幅を設定できる"):
        val bordered = BorderedShape(Circle(0, 0, 10), 3)
        bordered.borderWidth shouldBe 3

      it("drawに枠幅が含まれる"):
        val bordered = BorderedShape(Circle(0, 0, 10), 3)
        bordered.draw should include("3px")

  describe("Composite + Decorator"):
    it("複合図形にデコレータを適用できる"):
      val composite = CompositeShape(Circle(0, 0, 10), Rectangle(0, 0, 10, 20))
      val journaled = JournaledShape(composite)
      val afterMove = journaled.move(5, 3)
      afterMove.getJournal.length shouldBe 1

    it("デコレータ付き図形をCompositeに含められる"):
      val coloredCircle = ColoredShape(Circle(0, 0, 10), "red")
      val borderedRect = BorderedShape(Rectangle(0, 0, 10, 20), 2)
      val composite = CompositeShape(coloredCircle, borderedRect)
      composite.draw should include("[red]")
      composite.draw should include("2px")

    it("多重デコレータを適用できる"):
      val decorated = JournaledShape(
        BorderedShape(
          ColoredShape(Circle(0, 0, 10), "blue"),
          3
        )
      )
      decorated.draw should include("Journaled")
      decorated.draw should include("3px")
      decorated.draw should include("[blue]")

  describe("Observer パターン"):
    it("オブザーバーを登録できる"):
      val subject = new Subject
      var notified = false
      subject.addObserver(_ => notified = true)
      subject.notifyObservers(StateChanged("test"))
      notified shouldBe true

    it("複数のオブザーバーに通知できる"):
      val subject = new Subject
      var count = 0
      subject.addObserver(_ => count += 1)
      subject.addObserver(_ => count += 1)
      subject.notifyObservers(StateChanged("test"))
      count shouldBe 2

    it("オブザーバーを削除できる"):
      val subject = new Subject
      var count = 0
      val observer: Observer = _ => count += 1
      subject.addObserver(observer)
      subject.removeObserver(observer)
      subject.notifyObservers(StateChanged("test"))
      count shouldBe 0

  describe("Command パターン"):
    describe("Canvas"):
      it("図形を追加できる"):
        val canvas = Canvas().addShape(Circle(0, 0, 10))
        canvas.shapes.length shouldBe 1

      it("図形を削除できる"):
        val canvas = Canvas()
          .addShape(Circle(0, 0, 10))
          .addShape(Rectangle(0, 0, 10, 20))
          .removeShape(0)
        canvas.shapes.length shouldBe 1

      it("図形を更新できる"):
        val canvas = Canvas()
          .addShape(Circle(0, 0, 10))
          .updateShape(0, Circle(5, 5, 20))
        canvas.shapes(0).asInstanceOf[Circle].radius shouldBe 20

    describe("AddShapeCommand"):
      it("図形を追加できる"):
        val cmd = AddShapeCommand(Circle(0, 0, 10))
        val canvas = cmd.execute(Canvas())
        canvas.shapes.length shouldBe 1

      it("Undoで図形を削除できる"):
        val cmd = AddShapeCommand(Circle(0, 0, 10))
        val canvas = cmd.execute(Canvas())
        val undone = cmd.undo(canvas)
        undone.shapes.length shouldBe 0

    describe("MoveShapeCommand"):
      it("図形を移動できる"):
        val canvas = Canvas().addShape(Circle(0, 0, 10))
        val cmd = MoveShapeCommand(0, 5, 3)
        val moved = cmd.execute(canvas)
        moved.shapes(0).asInstanceOf[Circle].x shouldBe 5

      it("Undoで元に戻せる"):
        val canvas = Canvas().addShape(Circle(0, 0, 10))
        val cmd = MoveShapeCommand(0, 5, 3)
        val moved = cmd.execute(canvas)
        val undone = cmd.undo(moved)
        undone.shapes(0).asInstanceOf[Circle].x shouldBe 0

    describe("ScaleShapeCommand"):
      it("図形を拡大できる"):
        val canvas = Canvas().addShape(Circle(0, 0, 10))
        val cmd = ScaleShapeCommand(0, 2)
        val scaled = cmd.execute(canvas)
        scaled.shapes(0).asInstanceOf[Circle].radius shouldBe 20

      it("Undoで元に戻せる"):
        val canvas = Canvas().addShape(Circle(0, 0, 10))
        val cmd = ScaleShapeCommand(0, 2)
        val scaled = cmd.execute(canvas)
        val undone = cmd.undo(scaled)
        undone.shapes(0).asInstanceOf[Circle].radius shouldBe 10

    describe("MacroCommand"):
      it("複数のコマンドを実行できる"):
        val canvas = Canvas()
        val macroCmd = MacroCommand(
          AddShapeCommand(Circle(0, 0, 10)),
          AddShapeCommand(Rectangle(0, 0, 10, 20))
        )
        val executed = macroCmd.execute(canvas)
        executed.shapes.length shouldBe 2

      it("Undoで全て元に戻せる"):
        val canvas = Canvas()
        val macroCmd = MacroCommand(
          AddShapeCommand(Circle(0, 0, 10)),
          AddShapeCommand(Rectangle(0, 0, 10, 20))
        )
        val executed = macroCmd.execute(canvas)
        val undone = macroCmd.undo(executed)
        undone.shapes.length shouldBe 0

  describe("Command + Observer"):
    it("コマンド実行時にオブザーバーに通知される"):
      val obsCanvas = new ObservableCanvas
      var notified = false
      obsCanvas.subject.addObserver {
        case CommandExecuted(_, _) => notified = true
        case _ =>
      }
      obsCanvas.executeCommand(AddShapeCommand(Circle(0, 0, 10)))
      notified shouldBe true

    it("Undo時にオブザーバーに通知される"):
      val obsCanvas = new ObservableCanvas
      var undoNotified = false
      obsCanvas.subject.addObserver {
        case CommandUndone(_) => undoNotified = true
        case _ =>
      }
      obsCanvas.executeCommand(AddShapeCommand(Circle(0, 0, 10)))
      obsCanvas.undoLast()
      undoNotified shouldBe true

    it("Redo時にオブザーバーに通知される"):
      val obsCanvas = new ObservableCanvas
      var redoNotified = false
      obsCanvas.subject.addObserver {
        case CommandRedone(_) => redoNotified = true
        case _ =>
      }
      obsCanvas.executeCommand(AddShapeCommand(Circle(0, 0, 10)))
      obsCanvas.undoLast()
      obsCanvas.redoLast()
      redoNotified shouldBe true

    it("履歴を管理できる"):
      val obsCanvas = new ObservableCanvas
      obsCanvas.executeCommand(AddShapeCommand(Circle(0, 0, 10)))
      obsCanvas.executeCommand(MoveShapeCommand(0, 5, 3))
      obsCanvas.getHistory.length shouldBe 2
      obsCanvas.canUndo shouldBe true

    it("Undo/Redoが正しく動作する"):
      val obsCanvas = new ObservableCanvas
      obsCanvas.executeCommand(AddShapeCommand(Circle(0, 0, 10)))
      obsCanvas.executeCommand(MoveShapeCommand(0, 5, 3))

      obsCanvas.getCanvas.shapes(0).asInstanceOf[Circle].x shouldBe 5

      obsCanvas.undoLast()
      obsCanvas.getCanvas.shapes(0).asInstanceOf[Circle].x shouldBe 0

      obsCanvas.redoLast()
      obsCanvas.getCanvas.shapes(0).asInstanceOf[Circle].x shouldBe 5

  describe("Strategy パターン"):
    val canvas = Canvas()
      .addShape(Circle(0, 0, 10))
      .addShape(Rectangle(0, 0, 10, 20))

    describe("TextRenderStrategy"):
      it("テキストで描画できる"):
        val text = TextRenderStrategy.render(canvas)
        text should include("[0]")
        text should include("Circle")

    describe("JsonRenderStrategy"):
      it("JSONで描画できる"):
        val json = JsonRenderStrategy.render(canvas)
        json should include("\"shapes\"")
        json should include("\"type\":\"circle\"")

    describe("SvgRenderStrategy"):
      it("SVGで描画できる"):
        val svg = SvgRenderStrategy.render(canvas)
        svg should include("<svg")
        svg should include("<circle")
        svg should include("<rect")

  describe("Factory パターン"):
    describe("SimpleShapeFactory"):
      it("シンプルな図形を作成できる"):
        val circle = SimpleShapeFactory.createCircle(0, 0, 10)
        circle shouldBe a[Circle]

    describe("ColoredShapeFactory"):
      it("色付き図形を作成できる"):
        val factory = new ColoredShapeFactory("red")
        val circle = factory.createCircle(0, 0, 10)
        circle shouldBe a[ColoredShape]
        circle.asInstanceOf[ColoredShape].color shouldBe "red"

    describe("JournaledShapeFactory"):
      it("ジャーナル付き図形を作成できる"):
        val factory = new JournaledShapeFactory
        val circle = factory.createCircle(0, 0, 10)
        circle shouldBe a[JournaledShape]

  describe("Visitor パターン"):
    describe("AreaVisitor"):
      it("円の面積を計算できる"):
        val area = ShapeVisitor.visit(Circle(0, 0, 10), AreaVisitor)
        area shouldBe (Math.PI * 100) +- 0.001

      it("複合図形の面積を計算できる"):
        val composite = CompositeShape(Circle(0, 0, 10), Rectangle(0, 0, 10, 20))
        val area = ShapeVisitor.visit(composite, AreaVisitor)
        area shouldBe (Math.PI * 100 + 200) +- 0.001

      it("デコレータ付き図形の面積を計算できる"):
        val decorated = ColoredShape(Circle(0, 0, 10), "red")
        val area = ShapeVisitor.visit(decorated, AreaVisitor)
        area shouldBe (Math.PI * 100) +- 0.001

    describe("BoundingBoxVisitor"):
      it("円の境界ボックスを計算できる"):
        val bb = ShapeVisitor.visit(Circle(0, 0, 10), BoundingBoxVisitor)
        bb.minX shouldBe -10
        bb.maxX shouldBe 10

      it("複合図形の境界ボックスを計算できる"):
        val composite = CompositeShape(Circle(0, 0, 10), Rectangle(20, 20, 10, 10))
        val bb = ShapeVisitor.visit(composite, BoundingBoxVisitor)
        bb.minX shouldBe -10
        bb.maxX shouldBe 30

  describe("DSL"):
    import DSL.*

    it("DSLで図形を作成できる"):
      val c = circle(0, 0, 10)
      c shouldBe a[Circle]

    it("DSLでデコレータを適用できる"):
      val decorated = circle(0, 0, 10).withColor("red").withBorder(3)
      decorated shouldBe a[BorderedShape]

    it("DSLで複合図形を作成できる"):
      val comp = composite(circle(0, 0, 10), rectangle(0, 0, 10, 20))
      comp.shapes.length shouldBe 2

  describe("LogObserver"):
    it("ログを記録する"):
      val obsCanvas = new ObservableCanvas
      val logObserver = new LogObserver
      obsCanvas.subject.addObserver(logObserver.observer)

      obsCanvas.executeCommand(AddShapeCommand(Circle(0, 0, 10)))
      obsCanvas.executeCommand(MoveShapeCommand(0, 5, 3))
      obsCanvas.undoLast()

      logObserver.getLogs.length shouldBe 3
      logObserver.getLogs(0) should include("Executed")
      logObserver.getLogs(2) should include("Undone")
