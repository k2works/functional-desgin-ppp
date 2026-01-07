/**
 * 第7章: Composite パターン - テストコード
 */
package compositepattern

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers

class CompositePatternSpec extends AnyFunSuite with Matchers:

  // ============================================
  // 1. Shape のテスト
  // ============================================
  
  test("Circle: translateは中心を移動する") {
    val circle = Circle(Point(10, 10), 5)
    val moved = circle.translate(3, 4)
    moved.center shouldBe Point(13, 14)
    moved.radius shouldBe 5
  }
  
  test("Circle: scaleは半径を拡大/縮小する") {
    val circle = Circle(Point(10, 10), 5)
    val scaled = circle.scale(2)
    scaled.radius shouldBe 10
    scaled.center shouldBe Point(10, 10)
  }
  
  test("Circle: areaは面積を計算する") {
    val circle = Circle(Point(0, 0), 2)
    circle.area should be ((math.Pi * 4) +- 0.001)
  }
  
  test("Circle: boundingBoxはバウンディングボックスを返す") {
    val circle = Circle(Point(10, 10), 5)
    val bb = circle.boundingBox
    bb.topLeft shouldBe Point(5, 5)
    bb.bottomRight shouldBe Point(15, 15)
  }
  
  test("Square: translateは左上を移動する") {
    val square = Square(Point(0, 0), 10)
    val moved = square.translate(5, 5)
    moved.topLeft shouldBe Point(5, 5)
    moved.side shouldBe 10
  }
  
  test("Square: scaleは辺を拡大/縮小する") {
    val square = Square(Point(0, 0), 10)
    val scaled = square.scale(2)
    scaled.side shouldBe 20
  }
  
  test("Square: areaは面積を計算する") {
    val square = Square(Point(0, 0), 5)
    square.area shouldBe 25
  }
  
  test("Rectangle: translateは左上を移動する") {
    val rect = Rectangle(Point(0, 0), 10, 5)
    val moved = rect.translate(3, 4)
    moved.topLeft shouldBe Point(3, 4)
  }
  
  test("Rectangle: scaleは幅と高さを拡大/縮小する") {
    val rect = Rectangle(Point(0, 0), 10, 5)
    val scaled = rect.scale(2)
    scaled.width shouldBe 20
    scaled.height shouldBe 10
  }
  
  test("Rectangle: areaは面積を計算する") {
    val rect = Rectangle(Point(0, 0), 10, 5)
    rect.area shouldBe 50
  }
  
  test("Triangle: areaは面積を計算する") {
    val triangle = Triangle(Point(0, 0), Point(4, 0), Point(2, 3))
    triangle.area should be (6.0 +- 0.001)
  }
  
  test("Triangle: translateは全ての頂点を移動する") {
    val triangle = Triangle(Point(0, 0), Point(4, 0), Point(2, 3))
    val moved = triangle.translate(1, 1)
    moved.p1 shouldBe Point(1, 1)
    moved.p2 shouldBe Point(5, 1)
    moved.p3 shouldBe Point(3, 4)
  }
  
  test("CompositeShape: addは図形を追加する") {
    val composite = CompositeShape()
      .add(Circle(Point(0, 0), 5))
      .add(Square(Point(10, 10), 5))
    composite.count shouldBe 2
  }
  
  test("CompositeShape: removeは図形を削除する") {
    val circle = Circle(Point(0, 0), 5)
    val square = Square(Point(10, 10), 5)
    val composite = CompositeShape()
      .add(circle)
      .add(square)
      .remove(circle)
    composite.count shouldBe 1
  }
  
  test("CompositeShape: translateは全ての子要素を移動する") {
    val composite = CompositeShape()
      .add(Circle(Point(0, 0), 5))
      .add(Square(Point(10, 10), 5))
    val moved = composite.translate(5, 5)
    
    moved.shapes(0).asInstanceOf[Circle].center shouldBe Point(5, 5)
    moved.shapes(1).asInstanceOf[Square].topLeft shouldBe Point(15, 15)
  }
  
  test("CompositeShape: scaleは全ての子要素を拡大/縮小する") {
    val composite = CompositeShape()
      .add(Circle(Point(0, 0), 5))
      .add(Square(Point(10, 10), 10))
    val scaled = composite.scale(2)
    
    scaled.shapes(0).asInstanceOf[Circle].radius shouldBe 10
    scaled.shapes(1).asInstanceOf[Square].side shouldBe 20
  }
  
  test("CompositeShape: areaは全ての子要素の面積の合計を返す") {
    val composite = CompositeShape()
      .add(Square(Point(0, 0), 10))  // 100
      .add(Rectangle(Point(0, 0), 5, 4))  // 20
    composite.area shouldBe 120
  }
  
  test("CompositeShape: boundingBoxは全ての子要素を含むバウンディングボックスを返す") {
    val composite = CompositeShape()
      .add(Circle(Point(0, 0), 5))   // (-5,-5) to (5,5)
      .add(Square(Point(10, 10), 5)) // (10,10) to (15,15)
    val bb = composite.boundingBox
    bb.topLeft shouldBe Point(-5, -5)
    bb.bottomRight shouldBe Point(15, 15)
  }
  
  test("CompositeShape: ネストした複合図形をサポートする") {
    val inner = CompositeShape()
      .add(Circle(Point(0, 0), 5))
    val outer = CompositeShape()
      .add(inner)
      .add(Square(Point(10, 10), 5))
    
    outer.count shouldBe 2
    outer.flatten.length shouldBe 2
  }
  
  test("CompositeShape: flattenはネストした図形をフラット化する") {
    val inner = CompositeShape()
      .add(Circle(Point(0, 0), 5))
      .add(Circle(Point(10, 10), 3))
    val outer = CompositeShape()
      .add(inner)
      .add(Square(Point(20, 20), 5))
    
    outer.flatten.length shouldBe 3
    outer.flatten.count(_.isInstanceOf[Circle]) shouldBe 2
    outer.flatten.count(_.isInstanceOf[Square]) shouldBe 1
  }

  // ============================================
  // 2. Switchable のテスト
  // ============================================
  
  test("Light: turnOnはオンにする") {
    val light = Light()
    val on = light.turnOn
    on.isOn shouldBe true
    on.on shouldBe true
  }
  
  test("Light: turnOffはオフにする") {
    val light = Light(on = true)
    val off = light.turnOff
    off.isOn shouldBe false
    off.on shouldBe false
  }
  
  test("DimmableLight: turnOnは明るさを100にする") {
    val light = DimmableLight()
    val on = light.turnOn
    on.intensity shouldBe 100
    on.isOn shouldBe true
  }
  
  test("DimmableLight: turnOffは明るさを0にする") {
    val light = DimmableLight(intensity = 50)
    val off = light.turnOff
    off.intensity shouldBe 0
    off.isOn shouldBe false
  }
  
  test("DimmableLight: setIntensityは明るさを設定する") {
    val light = DimmableLight()
    light.setIntensity(50).intensity shouldBe 50
    light.setIntensity(150).intensity shouldBe 100  // 上限
    light.setIntensity(-10).intensity shouldBe 0   // 下限
  }
  
  test("Fan: turnOnは中速でオンにする") {
    val fan = Fan()
    val on = fan.turnOn
    on.speed shouldBe 3
    on.isOn shouldBe true
  }
  
  test("Fan: setSpeedは速度を設定する") {
    val fan = Fan()
    fan.setSpeed(5).speed shouldBe 5
    fan.setSpeed(10).speed shouldBe 5  // 上限
    fan.setSpeed(-1).speed shouldBe 0  // 下限
  }
  
  test("CompositeSwitchable: addはスイッチを追加する") {
    val composite = CompositeSwitchable()
      .add(Light())
      .add(Fan())
    composite.count shouldBe 2
  }
  
  test("CompositeSwitchable: turnOnは全ての子要素をオンにする") {
    val composite = CompositeSwitchable()
      .add(Light())
      .add(DimmableLight())
      .add(Fan())
    val on = composite.turnOn
    
    on.allOn shouldBe true
    on.switchables.forall(_.isOn) shouldBe true
  }
  
  test("CompositeSwitchable: turnOffは全ての子要素をオフにする") {
    val composite = CompositeSwitchable()
      .add(Light(on = true))
      .add(DimmableLight(intensity = 100))
      .add(Fan(speed = 3))
    val off = composite.turnOff
    
    off.isOn shouldBe false
    off.switchables.forall(!_.isOn) shouldBe true
  }
  
  test("CompositeSwitchable: isOnは一つでもオンならtrue") {
    val composite = CompositeSwitchable()
      .add(Light(on = true))
      .add(Fan(speed = 0))
    composite.isOn shouldBe true
  }
  
  test("CompositeSwitchable: allOnは全てオンならtrue") {
    val allOn = CompositeSwitchable()
      .add(Light(on = true))
      .add(Fan(speed = 3))
    allOn.allOn shouldBe true
    
    val notAllOn = CompositeSwitchable()
      .add(Light(on = true))
      .add(Fan(speed = 0))
    notAllOn.allOn shouldBe false
  }
  
  test("CompositeSwitchable: ネストした複合スイッチをサポートする") {
    val bedroom = CompositeSwitchable(name = "Bedroom")
      .add(Light(name = "Ceiling"))
      .add(DimmableLight(name = "Bedside"))
    
    val livingRoom = CompositeSwitchable(name = "LivingRoom")
      .add(Light(name = "Main"))
      .add(Fan(name = "Ceiling Fan"))
    
    val house = CompositeSwitchable(name = "House")
      .add(bedroom)
      .add(livingRoom)
    
    val allOn = house.turnOn
    allOn.flatten.forall(_.isOn) shouldBe true
  }

  // ============================================
  // 3. FileSystem のテスト
  // ============================================
  
  test("File: sizeはファイルサイズを返す") {
    val file = File("test.txt", 100)
    file.size shouldBe 100
  }
  
  test("File: pathはファイルパスを返す") {
    val file = File("test.txt", 100, "home/user")
    file.path shouldBe "home/user/test.txt"
  }
  
  test("Directory: addはエントリを追加する") {
    val dir = Directory("root")
      .add(File("file1.txt", 100))
      .add(File("file2.txt", 200))
    dir.children.length shouldBe 2
  }
  
  test("Directory: sizeは全エントリのサイズの合計を返す") {
    val dir = Directory("root")
      .add(File("file1.txt", 100))
      .add(File("file2.txt", 200))
    dir.size shouldBe 300
  }
  
  test("Directory: ネストしたディレクトリのサイズを正しく計算する") {
    val subDir = Directory("subdir")
      .add(File("sub.txt", 50))
    
    val rootDir = Directory("root")
      .add(File("root.txt", 100))
      .add(subDir)
    
    rootDir.size shouldBe 150
  }
  
  test("Directory: fileCountはファイル数を返す") {
    val subDir = Directory("subdir")
      .add(File("sub1.txt", 50))
      .add(File("sub2.txt", 50))
    
    val rootDir = Directory("root")
      .add(File("root.txt", 100))
      .add(subDir)
    
    rootDir.fileCount shouldBe 3
  }
  
  test("Directory: directoryCountはディレクトリ数を返す") {
    val subDir1 = Directory("subdir1")
    val subDir2 = Directory("subdir2")
      .add(Directory("nested"))
    
    val rootDir = Directory("root")
      .add(subDir1)
      .add(subDir2)
    
    rootDir.directoryCount shouldBe 3
  }
  
  test("Directory: findは条件に一致するエントリを返す") {
    val dir = Directory("root")
      .add(File("test.txt", 100))
      .add(File("data.csv", 200))
      .add(File("test.csv", 150))
    
    val txtFiles = dir.find(e => e.name.endsWith(".txt"))
    txtFiles.length shouldBe 1
    
    val csvFiles = dir.find(e => e.name.endsWith(".csv"))
    csvFiles.length shouldBe 2
  }
  
  test("Directory: listAllは全てのパスをリストする") {
    val rootDir = Directory("root")
      .add(File("root.txt", 100))
      .add(Directory("subdir")
        .add(File("nested.txt", 50)))
    
    val paths = rootDir.listAll
    paths should contain("root/root.txt")
    paths should contain("root/subdir")
    // ネストしたファイルのパスも確認
    paths.exists(_.contains("nested.txt")) shouldBe true
  }

  // ============================================
  // 4. Menu のテスト
  // ============================================
  
  test("SingleItem: priceは価格を返す") {
    val item = SingleItem("Burger", BigDecimal(500), false, "Beef burger")
    item.price shouldBe BigDecimal(500)
  }
  
  test("SetMenu: priceは割引後の合計価格を返す") {
    val set = SetMenu("Lunch Set", discount = BigDecimal(100))
      .add(SingleItem("Burger", BigDecimal(500), false, ""))
      .add(SingleItem("Drink", BigDecimal(200), true, ""))
    
    set.originalPrice shouldBe BigDecimal(700)
    set.price shouldBe BigDecimal(600)
  }
  
  test("SetMenu: isVegetarianは全てベジタリアンならtrue") {
    val vegSet = SetMenu("Veg Set")
      .add(SingleItem("Salad", BigDecimal(300), true, ""))
      .add(SingleItem("Juice", BigDecimal(200), true, ""))
    vegSet.isVegetarian shouldBe true
    
    val mixSet = SetMenu("Mix Set")
      .add(SingleItem("Salad", BigDecimal(300), true, ""))
      .add(SingleItem("Burger", BigDecimal(500), false, ""))
    mixSet.isVegetarian shouldBe false
  }
  
  test("SetMenu: discountRateは割引率を返す") {
    val set = SetMenu("Set", discount = BigDecimal(100))
      .add(SingleItem("Item1", BigDecimal(500), false, ""))
      .add(SingleItem("Item2", BigDecimal(500), false, ""))
    
    set.discountRate shouldBe 10.0 +- 0.01
  }
  
  test("SetMenu: ネストしたセットメニューをサポートする") {
    val innerSet = SetMenu("Inner Set", discount = BigDecimal(50))
      .add(SingleItem("Item1", BigDecimal(300), false, ""))
      .add(SingleItem("Item2", BigDecimal(200), false, ""))
    
    val outerSet = SetMenu("Outer Set", discount = BigDecimal(100))
      .add(innerSet)
      .add(SingleItem("Item3", BigDecimal(400), false, ""))
    
    // Inner: 500 - 50 = 450, Outer: 450 + 400 - 100 = 750
    outerSet.price shouldBe BigDecimal(750)
  }

  // ============================================
  // 5. Expression のテスト
  // ============================================
  
  test("Number: evaluateは値を返す") {
    Number(42).evaluate shouldBe 42.0
  }
  
  test("Variable: evaluateは値を返す（バインドされている場合）") {
    Variable("x", Some(10)).evaluate shouldBe 10.0
  }
  
  test("Variable: evaluateは例外をスローする（バインドされていない場合）") {
    assertThrows[IllegalStateException] {
      Variable("x").evaluate
    }
  }
  
  test("Add: evaluateは加算結果を返す") {
    Add(Number(2), Number(3)).evaluate shouldBe 5.0
  }
  
  test("Subtract: evaluateは減算結果を返す") {
    Subtract(Number(5), Number(3)).evaluate shouldBe 2.0
  }
  
  test("Multiply: evaluateは乗算結果を返す") {
    Multiply(Number(4), Number(3)).evaluate shouldBe 12.0
  }
  
  test("Divide: evaluateは除算結果を返す") {
    Divide(Number(10), Number(2)).evaluate shouldBe 5.0
  }
  
  test("Divide: evaluateはゼロ除算で例外をスローする") {
    assertThrows[ArithmeticException] {
      Divide(Number(10), Number(0)).evaluate
    }
  }
  
  test("Expression: 複合式を評価できる") {
    // (2 + 3) * 4 = 20
    val expr = Multiply(Add(Number(2), Number(3)), Number(4))
    expr.evaluate shouldBe 20.0
  }
  
  test("Expression: variablesは未束縛変数を返す") {
    val expr = Add(Variable("x"), Multiply(Variable("y"), Number(2)))
    expr.variables shouldBe Set("x", "y")
  }
  
  test("Expression: bindは変数に値を束縛する") {
    val expr = Add(Variable("x"), Variable("y"))
    val bound = Expression.bind(expr, Map("x" -> 10.0, "y" -> 20.0))
    bound.evaluate shouldBe 30.0
  }
  
  test("Expression: simplifyは式を簡略化する") {
    // x + 0 = x
    Add(Variable("x"), Number(0)).simplify shouldBe Variable("x")
    
    // 0 + x = x
    Add(Number(0), Variable("x")).simplify shouldBe Variable("x")
    
    // x * 1 = x
    Multiply(Variable("x"), Number(1)).simplify shouldBe Variable("x")
    
    // x * 0 = 0
    Multiply(Variable("x"), Number(0)).simplify shouldBe Number(0)
    
    // 2 + 3 = 5
    Add(Number(2), Number(3)).simplify shouldBe Number(5)
  }
  
  test("Expression: simplifyは再帰的に簡略化する") {
    // (x + 0) * 1 = x
    val expr = Multiply(Add(Variable("x"), Number(0)), Number(1))
    expr.simplify shouldBe Variable("x")
  }
  
  test("Expression: toStringは式を文字列化する") {
    val expr = Add(Number(2), Multiply(Number(3), Number(4)))
    expr.toString shouldBe "(2.0 + (3.0 * 4.0))"
  }
