module Tests

open Xunit
open FsCheck.Xunit
open FunctionalDesign.Part3.CompositePattern

// ============================================
// 1. Point と BoundingBox テスト
// ============================================

module PointTests =

    [<Fact>]
    let ``Point.create で座標を作成できる`` () =
        let p = Point.create 10.0 20.0
        Assert.Equal(10.0, p.X)
        Assert.Equal(20.0, p.Y)

    [<Fact>]
    let ``Point の加算が正しく動作する`` () =
        let p1 = Point.create 10.0 20.0
        let p2 = Point.create 5.0 3.0
        let result = p1 + p2
        Assert.Equal(15.0, result.X)
        Assert.Equal(23.0, result.Y)

    [<Fact>]
    let ``Point のスカラー乗算が正しく動作する`` () =
        let p = Point.create 10.0 20.0
        let result = p * 2.0
        Assert.Equal(20.0, result.X)
        Assert.Equal(40.0, result.Y)

module BoundingBoxTests =

    [<Fact>]
    let ``BoundingBox.union で2つのボックスを結合できる`` () =
        let bb1 = BoundingBox.create (Point.create 0.0 0.0) (Point.create 10.0 10.0)
        let bb2 = BoundingBox.create (Point.create 5.0 5.0) (Point.create 20.0 15.0)
        let result = BoundingBox.union bb1 bb2
        Assert.Equal(0.0, result.Min.X)
        Assert.Equal(0.0, result.Min.Y)
        Assert.Equal(20.0, result.Max.X)
        Assert.Equal(15.0, result.Max.Y)

    [<Fact>]
    let ``BoundingBox.width と height が正しく計算される`` () =
        let bb = BoundingBox.create (Point.create 5.0 10.0) (Point.create 15.0 30.0)
        Assert.Equal(10.0, BoundingBox.width bb)
        Assert.Equal(20.0, BoundingBox.height bb)

// ============================================
// 2. Shape テスト
// ============================================

module ShapeTests =

    [<Fact>]
    let ``Circle を作成できる`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        match circle with
        | Shape.Circle(center, radius) ->
            Assert.Equal(10.0, center.X)
            Assert.Equal(5.0, radius)
        | _ -> Assert.Fail("Expected Circle")

    [<Fact>]
    let ``Circle を移動できる`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let moved = Shape.translate 5.0 3.0 circle
        match moved with
        | Shape.Circle(center, _) ->
            Assert.Equal(15.0, center.X)
            Assert.Equal(13.0, center.Y)
        | _ -> Assert.Fail("Expected Circle")

    [<Fact>]
    let ``Circle を拡大できる`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let scaled = Shape.scale 2.0 circle
        match scaled with
        | Shape.Circle(_, radius) -> Assert.Equal(10.0, radius)
        | _ -> Assert.Fail("Expected Circle")

    [<Fact>]
    let ``Circle の面積が正しく計算される`` () =
        let circle = Shape.Circle(Point.create 0.0 0.0, 5.0)
        let expected = System.Math.PI * 25.0
        Assert.Equal(expected, Shape.area circle, 5)

    [<Fact>]
    let ``Square を作成できる`` () =
        let square = Shape.Square(Point.create 0.0 0.0, 10.0)
        match square with
        | Shape.Square(topLeft, side) ->
            Assert.Equal(0.0, topLeft.X)
            Assert.Equal(10.0, side)
        | _ -> Assert.Fail("Expected Square")

    [<Fact>]
    let ``Square の面積が正しく計算される`` () =
        let square = Shape.Square(Point.create 0.0 0.0, 10.0)
        Assert.Equal(100.0, Shape.area square)

    [<Fact>]
    let ``Rectangle の面積が正しく計算される`` () =
        let rect = Shape.Rectangle(Point.create 0.0 0.0, 10.0, 5.0)
        Assert.Equal(50.0, Shape.area rect)

    [<Fact>]
    let ``CompositeShape を作成して図形を追加できる`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let square = Shape.Square(Point.create 0.0 0.0, 10.0)
        let composite =
            Shape.emptyComposite
            |> Shape.add circle
            |> Shape.add square
        Assert.Equal(2, Shape.count composite)

    [<Fact>]
    let ``CompositeShape を移動すると全ての子要素が移動する`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let square = Shape.Square(Point.create 0.0 0.0, 10.0)
        let composite =
            Shape.emptyComposite
            |> Shape.add circle
            |> Shape.add square
        let moved = Shape.translate 5.0 5.0 composite
        match moved with
        | Shape.Composite shapes ->
            match shapes.[0] with
            | Shape.Circle(center, _) ->
                Assert.Equal(15.0, center.X)
                Assert.Equal(15.0, center.Y)
            | _ -> Assert.Fail("Expected Circle")
            match shapes.[1] with
            | Shape.Square(topLeft, _) ->
                Assert.Equal(5.0, topLeft.X)
                Assert.Equal(5.0, topLeft.Y)
            | _ -> Assert.Fail("Expected Square")
        | _ -> Assert.Fail("Expected Composite")

    [<Fact>]
    let ``CompositeShape の面積は子要素の合計`` () =
        let circle = Shape.Circle(Point.create 0.0 0.0, 5.0)
        let square = Shape.Square(Point.create 0.0 0.0, 10.0)
        let composite =
            Shape.emptyComposite
            |> Shape.add circle
            |> Shape.add square
        let expected = System.Math.PI * 25.0 + 100.0
        Assert.Equal(expected, Shape.area composite, 5)

    [<Fact>]
    let ``Shape.flatten でネストした Composite を平坦化できる`` () =
        let c1 = Shape.Circle(Point.create 0.0 0.0, 5.0)
        let c2 = Shape.Circle(Point.create 10.0 10.0, 3.0)
        let inner = Shape.emptyComposite |> Shape.add c1
        let outer = Shape.emptyComposite |> Shape.add inner |> Shape.add c2
        let flattened = Shape.flatten outer
        Assert.Equal(2, List.length flattened)

    [<Fact>]
    let ``Circle の boundingBox が正しい`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let bb = Shape.boundingBox circle
        Assert.Equal(5.0, bb.Min.X)
        Assert.Equal(5.0, bb.Min.Y)
        Assert.Equal(15.0, bb.Max.X)
        Assert.Equal(15.0, bb.Max.Y)

    [<Fact>]
    let ``CompositeShape の boundingBox は全ての子を含む`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let square = Shape.Square(Point.create 0.0 0.0, 3.0)
        let composite =
            Shape.emptyComposite
            |> Shape.add circle
            |> Shape.add square
        let bb = Shape.boundingBox composite
        Assert.Equal(0.0, bb.Min.X)
        Assert.Equal(0.0, bb.Min.Y)
        Assert.Equal(15.0, bb.Max.X)
        Assert.Equal(15.0, bb.Max.Y)

// ============================================
// 3. Switchable テスト
// ============================================

module SwitchableTests =

    [<Fact>]
    let ``Light を作成できる`` () =
        let light = Switchable.Light(false, "Ceiling")
        Assert.Equal("Ceiling", Switchable.getName light)
        Assert.False(Switchable.isOn light)

    [<Fact>]
    let ``Light を turnOn できる`` () =
        let light = Switchable.Light(false, "Ceiling")
        let onLight = Switchable.turnOn light
        Assert.True(Switchable.isOn onLight)

    [<Fact>]
    let ``Light を turnOff できる`` () =
        let light = Switchable.Light(true, "Ceiling")
        let offLight = Switchable.turnOff light
        Assert.False(Switchable.isOn offLight)

    [<Fact>]
    let ``DimmableLight を作成できる`` () =
        let light = Switchable.DimmableLight(0, "Bedside")
        Assert.False(Switchable.isOn light)

    [<Fact>]
    let ``DimmableLight を turnOn すると intensity が 100 になる`` () =
        let light = Switchable.DimmableLight(0, "Bedside")
        let onLight = Switchable.turnOn light
        match onLight with
        | Switchable.DimmableLight(intensity, _) -> Assert.Equal(100, intensity)
        | _ -> Assert.Fail("Expected DimmableLight")

    [<Fact>]
    let ``DimmableLight の intensity を設定できる`` () =
        let light = Switchable.DimmableLight(0, "Bedside")
        let dimmed = Switchable.setIntensity 50 light
        match dimmed with
        | Switchable.DimmableLight(intensity, _) -> Assert.Equal(50, intensity)
        | _ -> Assert.Fail("Expected DimmableLight")

    [<Fact>]
    let ``Fan を作成できる`` () =
        let fan = Switchable.Fan(false, 0, "Ceiling Fan")
        Assert.False(Switchable.isOn fan)

    [<Fact>]
    let ``Fan の speed を設定できる`` () =
        let fan = Switchable.Fan(true, 1, "Ceiling Fan")
        let highSpeed = Switchable.setSpeed 3 fan
        match highSpeed with
        | Switchable.Fan(_, speed, _) -> Assert.Equal(3, speed)
        | _ -> Assert.Fail("Expected Fan")

    [<Fact>]
    let ``CompositeSwitchable を作成してスイッチを追加できる`` () =
        let light = Switchable.Light(false, "Light")
        let fan = Switchable.Fan(false, 0, "Fan")
        let room =
            Switchable.emptyComposite "Room"
            |> Switchable.add light
            |> Switchable.add fan
        match room with
        | Switchable.Composite(switchables, _) -> Assert.Equal(2, List.length switchables)
        | _ -> Assert.Fail("Expected Composite")

    [<Fact>]
    let ``CompositeSwitchable を turnOn すると全ての子がオンになる`` () =
        let light = Switchable.Light(false, "Light")
        let dimLight = Switchable.DimmableLight(0, "DimLight")
        let room =
            Switchable.emptyComposite "Room"
            |> Switchable.add light
            |> Switchable.add dimLight
        let onRoom = Switchable.turnOn room
        Assert.True(Switchable.allOn onRoom)

    [<Fact>]
    let ``CompositeSwitchable の isOn は子の1つでもオンなら true`` () =
        let light = Switchable.Light(true, "Light")
        let offLight = Switchable.Light(false, "OffLight")
        let room =
            Switchable.emptyComposite "Room"
            |> Switchable.add light
            |> Switchable.add offLight
        Assert.True(Switchable.isOn room)
        Assert.False(Switchable.allOn room)

    [<Fact>]
    let ``ネストした CompositeSwitchable で turnOn が全てに適用される`` () =
        let light1 = Switchable.Light(false, "Light1")
        let light2 = Switchable.Light(false, "Light2")
        let bedroom =
            Switchable.emptyComposite "Bedroom"
            |> Switchable.add light1
        let house =
            Switchable.emptyComposite "House"
            |> Switchable.add bedroom
            |> Switchable.add light2
        let onHouse = Switchable.turnOn house
        Assert.True(Switchable.allOn onHouse)

// ============================================
// 4. FileSystemEntry テスト
// ============================================

module FileSystemTests =

    [<Fact>]
    let ``File を作成できる`` () =
        let file = FileSystemEntry.File("readme.txt", 1024L, ".txt")
        Assert.Equal("readme.txt", FileSystemEntry.name file)
        Assert.Equal(1024L, FileSystemEntry.size file)

    [<Fact>]
    let ``Directory を作成できる`` () =
        let dir = FileSystemEntry.Directory("docs", [])
        Assert.Equal("docs", FileSystemEntry.name dir)
        Assert.Equal(0L, FileSystemEntry.size dir)

    [<Fact>]
    let ``Directory にファイルを追加できる`` () =
        let file = FileSystemEntry.File("readme.txt", 1024L, ".txt")
        let dir = FileSystemEntry.Directory("docs", [])
        let updated = FileSystemEntry.add file dir
        match updated with
        | FileSystemEntry.Directory(_, children) -> Assert.Equal(1, List.length children)
        | _ -> Assert.Fail("Expected Directory")

    [<Fact>]
    let ``Directory のサイズは含まれるファイルの合計`` () =
        let file1 = FileSystemEntry.File("a.txt", 1000L, ".txt")
        let file2 = FileSystemEntry.File("b.txt", 2000L, ".txt")
        let dir = FileSystemEntry.Directory("docs", [ file1; file2 ])
        Assert.Equal(3000L, FileSystemEntry.size dir)

    [<Fact>]
    let ``ネストしたディレクトリのサイズが正しく計算される`` () =
        let file1 = FileSystemEntry.File("a.txt", 1000L, ".txt")
        let file2 = FileSystemEntry.File("b.txt", 2000L, ".txt")
        let subDir = FileSystemEntry.Directory("sub", [ file2 ])
        let rootDir = FileSystemEntry.Directory("root", [ file1; subDir ])
        Assert.Equal(3000L, FileSystemEntry.size rootDir)

    [<Fact>]
    let ``fileCount でファイル数を取得できる`` () =
        let file1 = FileSystemEntry.File("a.txt", 1000L, ".txt")
        let file2 = FileSystemEntry.File("b.txt", 2000L, ".txt")
        let subDir = FileSystemEntry.Directory("sub", [ file2 ])
        let rootDir = FileSystemEntry.Directory("root", [ file1; subDir ])
        Assert.Equal(2, FileSystemEntry.fileCount rootDir)

    [<Fact>]
    let ``directoryCount でディレクトリ数を取得できる`` () =
        let file1 = FileSystemEntry.File("a.txt", 1000L, ".txt")
        let subDir = FileSystemEntry.Directory("sub", [ file1 ])
        let rootDir = FileSystemEntry.Directory("root", [ subDir ])
        Assert.Equal(2, FileSystemEntry.directoryCount rootDir)

    [<Fact>]
    let ``findByExtension で拡張子でファイルを検索できる`` () =
        let txtFile = FileSystemEntry.File("readme.txt", 1000L, ".txt")
        let mdFile = FileSystemEntry.File("docs.md", 2000L, ".md")
        let dir = FileSystemEntry.Directory("root", [ txtFile; mdFile ])
        let results = FileSystemEntry.findByExtension ".txt" dir
        Assert.Equal(1, List.length results)

    [<Fact>]
    let ``allFiles で全てのファイルを取得できる`` () =
        let file1 = FileSystemEntry.File("a.txt", 1000L, ".txt")
        let file2 = FileSystemEntry.File("b.txt", 2000L, ".txt")
        let subDir = FileSystemEntry.Directory("sub", [ file2 ])
        let rootDir = FileSystemEntry.Directory("root", [ file1; subDir ])
        let files = FileSystemEntry.allFiles rootDir
        Assert.Equal(2, List.length files)

// ============================================
// 5. MenuItem テスト
// ============================================

module MenuItemTests =

    [<Fact>]
    let ``Item を作成できる`` () =
        let item = MenuItem.Item("Hamburger", 500m, "Main")
        Assert.Equal("Hamburger", MenuItem.name item)
        Assert.Equal(500m, MenuItem.price item)

    [<Fact>]
    let ``SetMenu を作成できる`` () =
        let burger = MenuItem.Item("Hamburger", 500m, "Main")
        let fries = MenuItem.Item("Fries", 200m, "Side")
        let drink = MenuItem.Item("Cola", 150m, "Drink")
        let setMenu = MenuItem.SetMenu("Lunch Set", [ burger; fries; drink ], 0.1)
        Assert.Equal("Lunch Set", MenuItem.name setMenu)

    [<Fact>]
    let ``SetMenu の価格は割引が適用される`` () =
        let burger = MenuItem.Item("Hamburger", 500m, "Main")
        let fries = MenuItem.Item("Fries", 200m, "Side")
        let drink = MenuItem.Item("Cola", 150m, "Drink")
        let setMenu = MenuItem.SetMenu("Lunch Set", [ burger; fries; drink ], 0.1)
        // 850 * 0.9 = 765
        Assert.Equal(765m, MenuItem.price setMenu)

    [<Fact>]
    let ``SetMenu に項目を追加できる`` () =
        let burger = MenuItem.Item("Hamburger", 500m, "Main")
        let setMenu = MenuItem.SetMenu("Set", [ burger ], 0.1)
        let fries = MenuItem.Item("Fries", 200m, "Side")
        let updated = MenuItem.addToSet fries setMenu
        Assert.Equal(2, MenuItem.itemCount updated)

    [<Fact>]
    let ``itemCount でアイテム数を取得できる`` () =
        let burger = MenuItem.Item("Hamburger", 500m, "Main")
        let fries = MenuItem.Item("Fries", 200m, "Side")
        let setMenu = MenuItem.SetMenu("Lunch Set", [ burger; fries ], 0.1)
        Assert.Equal(2, MenuItem.itemCount setMenu)

    [<Fact>]
    let ``allItems でセットを展開して全アイテムを取得できる`` () =
        let burger = MenuItem.Item("Hamburger", 500m, "Main")
        let fries = MenuItem.Item("Fries", 200m, "Side")
        let innerSet = MenuItem.SetMenu("Inner", [ burger ], 0.0)
        let outerSet = MenuItem.SetMenu("Outer", [ innerSet; fries ], 0.1)
        let items = MenuItem.allItems outerSet
        Assert.Equal(2, List.length items)

    [<Fact>]
    let ``ネストしたSetMenuの価格が正しく計算される`` () =
        let burger = MenuItem.Item("Hamburger", 500m, "Main")
        let innerSet = MenuItem.SetMenu("Inner", [ burger ], 0.1)  // 500 * 0.9 = 450
        let fries = MenuItem.Item("Fries", 200m, "Side")
        let outerSet = MenuItem.SetMenu("Outer", [ innerSet; fries ], 0.1)  // (450 + 200) * 0.9 = 585
        Assert.Equal(585m, MenuItem.price outerSet)

// ============================================
// 6. Expression テスト
// ============================================

module ExpressionTests =

    [<Fact>]
    let ``Number を評価できる`` () =
        let expr = Expression.Number 42.0
        Assert.Equal(42.0, Expression.evaluate expr)

    [<Fact>]
    let ``Variable に値があれば評価できる`` () =
        let expr = Expression.Variable("x", Some 10.0)
        Assert.Equal(10.0, Expression.evaluate expr)

    [<Fact>]
    let ``Variable に値がなければ例外が発生する`` () =
        let expr = Expression.Variable("x", None)
        Assert.Throws<System.Exception>(fun () -> Expression.evaluate expr |> ignore)

    [<Fact>]
    let ``Add を評価できる`` () =
        let expr = Expression.Add(Expression.Number 2.0, Expression.Number 3.0)
        Assert.Equal(5.0, Expression.evaluate expr)

    [<Fact>]
    let ``Subtract を評価できる`` () =
        let expr = Expression.Subtract(Expression.Number 5.0, Expression.Number 3.0)
        Assert.Equal(2.0, Expression.evaluate expr)

    [<Fact>]
    let ``Multiply を評価できる`` () =
        let expr = Expression.Multiply(Expression.Number 4.0, Expression.Number 3.0)
        Assert.Equal(12.0, Expression.evaluate expr)

    [<Fact>]
    let ``Divide を評価できる`` () =
        let expr = Expression.Divide(Expression.Number 10.0, Expression.Number 2.0)
        Assert.Equal(5.0, Expression.evaluate expr)

    [<Fact>]
    let ``0で割ると例外が発生する`` () =
        let expr = Expression.Divide(Expression.Number 10.0, Expression.Number 0.0)
        Assert.Throws<System.Exception>(fun () -> Expression.evaluate expr |> ignore)

    [<Fact>]
    let ``Negate を評価できる`` () =
        let expr = Expression.Negate(Expression.Number 5.0)
        Assert.Equal(-5.0, Expression.evaluate expr)

    [<Fact>]
    let ``複合式 (2 + 3) * 4 を評価できる`` () =
        let expr =
            Expression.Multiply(
                Expression.Add(Expression.Number 2.0, Expression.Number 3.0),
                Expression.Number 4.0
            )
        Assert.Equal(20.0, Expression.evaluate expr)

    [<Fact>]
    let ``simplify で 0 + x が x になる`` () =
        let expr = Expression.Add(Expression.Number 0.0, Expression.Variable("x", None))
        let simplified = Expression.simplify expr
        match simplified with
        | Expression.Variable(name, _) -> Assert.Equal("x", name)
        | _ -> Assert.Fail("Expected Variable")

    [<Fact>]
    let ``simplify で x + 0 が x になる`` () =
        let expr = Expression.Add(Expression.Variable("x", None), Expression.Number 0.0)
        let simplified = Expression.simplify expr
        match simplified with
        | Expression.Variable(name, _) -> Assert.Equal("x", name)
        | _ -> Assert.Fail("Expected Variable")

    [<Fact>]
    let ``simplify で x * 1 が x になる`` () =
        let expr = Expression.Multiply(Expression.Variable("x", None), Expression.Number 1.0)
        let simplified = Expression.simplify expr
        match simplified with
        | Expression.Variable(name, _) -> Assert.Equal("x", name)
        | _ -> Assert.Fail("Expected Variable")

    [<Fact>]
    let ``simplify で x * 0 が 0 になる`` () =
        let expr = Expression.Multiply(Expression.Variable("x", None), Expression.Number 0.0)
        let simplified = Expression.simplify expr
        match simplified with
        | Expression.Number n -> Assert.Equal(0.0, n)
        | _ -> Assert.Fail("Expected Number 0")

    [<Fact>]
    let ``simplify で数値同士の計算が実行される`` () =
        let expr = Expression.Add(Expression.Number 2.0, Expression.Number 3.0)
        let simplified = Expression.simplify expr
        match simplified with
        | Expression.Number n -> Assert.Equal(5.0, n)
        | _ -> Assert.Fail("Expected Number")

    [<Fact>]
    let ``variables で変数を取得できる`` () =
        let expr =
            Expression.Add(
                Expression.Variable("x", None),
                Expression.Multiply(Expression.Variable("y", None), Expression.Number 2.0)
            )
        let vars = Expression.variables expr
        Assert.True(Set.contains "x" vars)
        Assert.True(Set.contains "y" vars)
        Assert.Equal(2, Set.count vars)

    [<Fact>]
    let ``bind で変数に値をバインドできる`` () =
        let expr = Expression.Add(Expression.Variable("x", None), Expression.Variable("y", None))
        let bindings = Map.ofList [ ("x", 10.0); ("y", 20.0) ]
        let bound = Expression.bind bindings expr
        Assert.Equal(30.0, Expression.evaluate bound)

    [<Fact>]
    let ``toString で式を文字列に変換できる`` () =
        let expr = Expression.Add(Expression.Number 2.0, Expression.Number 3.0)
        let str = Expression.toString expr
        Assert.Equal("(2 + 3)", str)

    [<Fact>]
    let ``二重否定は元の値になる（simplify）`` () =
        let expr = Expression.Negate(Expression.Negate(Expression.Variable("x", None)))
        let simplified = Expression.simplify expr
        match simplified with
        | Expression.Variable(name, _) -> Assert.Equal("x", name)
        | _ -> Assert.Fail("Expected Variable")

// ============================================
// 7. OrganizationMember テスト
// ============================================

module OrganizationMemberTests =

    [<Fact>]
    let ``Employee を作成できる`` () =
        let emp = OrganizationMember.Employee("Alice", 50000m, "Developer")
        Assert.Equal("Alice", OrganizationMember.name emp)
        Assert.Equal(50000m, OrganizationMember.totalSalary emp)

    [<Fact>]
    let ``Department を作成できる`` () =
        let dept = OrganizationMember.Department("Engineering", [], Some "Bob")
        Assert.Equal("Engineering", OrganizationMember.name dept)

    [<Fact>]
    let ``Department にメンバーを追加できる`` () =
        let emp = OrganizationMember.Employee("Alice", 50000m, "Developer")
        let dept = OrganizationMember.Department("Engineering", [], Some "Bob")
        let updated = OrganizationMember.addMember emp dept
        Assert.Equal(1, OrganizationMember.employeeCount updated)

    [<Fact>]
    let ``Department の総給与は所属員の合計`` () =
        let emp1 = OrganizationMember.Employee("Alice", 50000m, "Developer")
        let emp2 = OrganizationMember.Employee("Bob", 60000m, "Developer")
        let dept = OrganizationMember.Department("Engineering", [ emp1; emp2 ], None)
        Assert.Equal(110000m, OrganizationMember.totalSalary dept)

    [<Fact>]
    let ``ネストした Department の総給与が正しく計算される`` () =
        let emp1 = OrganizationMember.Employee("Alice", 50000m, "Developer")
        let emp2 = OrganizationMember.Employee("Bob", 60000m, "Manager")
        let subDept = OrganizationMember.Department("Team A", [ emp1 ], None)
        let dept = OrganizationMember.Department("Engineering", [ subDept; emp2 ], None)
        Assert.Equal(110000m, OrganizationMember.totalSalary dept)

    [<Fact>]
    let ``employeeCount で従業員数を取得できる`` () =
        let emp1 = OrganizationMember.Employee("Alice", 50000m, "Developer")
        let emp2 = OrganizationMember.Employee("Bob", 60000m, "Developer")
        let subDept = OrganizationMember.Department("Team A", [ emp1 ], None)
        let dept = OrganizationMember.Department("Engineering", [ subDept; emp2 ], None)
        Assert.Equal(2, OrganizationMember.employeeCount dept)

    [<Fact>]
    let ``departmentCount で部門数を取得できる`` () =
        let emp1 = OrganizationMember.Employee("Alice", 50000m, "Developer")
        let subDept = OrganizationMember.Department("Team A", [ emp1 ], None)
        let dept = OrganizationMember.Department("Engineering", [ subDept ], None)
        Assert.Equal(1, OrganizationMember.departmentCount dept)

    [<Fact>]
    let ``findByRole で役職で従業員を検索できる`` () =
        let dev1 = OrganizationMember.Employee("Alice", 50000m, "Developer")
        let dev2 = OrganizationMember.Employee("Bob", 55000m, "Developer")
        let mgr = OrganizationMember.Employee("Carol", 70000m, "Manager")
        let dept = OrganizationMember.Department("Engineering", [ dev1; dev2; mgr ], None)
        let developers = OrganizationMember.findByRole "Developer" dept
        Assert.Equal(2, List.length developers)

    [<Fact>]
    let ``allEmployees で全ての従業員を取得できる`` () =
        let emp1 = OrganizationMember.Employee("Alice", 50000m, "Developer")
        let emp2 = OrganizationMember.Employee("Bob", 60000m, "Manager")
        let subDept = OrganizationMember.Department("Team A", [ emp1 ], None)
        let dept = OrganizationMember.Department("Engineering", [ subDept; emp2 ], None)
        let employees = OrganizationMember.allEmployees dept
        Assert.Equal(2, List.length employees)

// ============================================
// 8. プロパティベーステスト
// ============================================

module ShapePropertyTests =

    [<Property>]
    let ``translate して -translate すると元に戻る`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let moved = circle |> Shape.translate 5.0 3.0 |> Shape.translate -5.0 -3.0
        match moved with
        | Shape.Circle(center, _) ->
            abs(center.X - 10.0) < 0.0001 && abs(center.Y - 10.0) < 0.0001
        | _ -> false

    [<Property>]
    let ``scale 2.0 して scale 0.5 すると元に戻る`` () =
        let circle = Shape.Circle(Point.create 10.0 10.0, 5.0)
        let scaled = circle |> Shape.scale 2.0 |> Shape.scale 0.5
        match scaled with
        | Shape.Circle(_, radius) -> abs(radius - 5.0) < 0.0001
        | _ -> false

    [<Property>]
    let ``CompositeShape の面積は常に子要素の面積の合計`` () =
        let c1 = Shape.Circle(Point.create 0.0 0.0, 3.0)
        let c2 = Shape.Circle(Point.create 10.0 10.0, 2.0)
        let composite = Shape.emptyComposite |> Shape.add c1 |> Shape.add c2
        let compositeArea = Shape.area composite
        let sumArea = Shape.area c1 + Shape.area c2
        abs(compositeArea - sumArea) < 0.0001

module ExpressionPropertyTests =

    [<Property>]
    let ``数値式の simplify は元の値を維持`` (n: float) =
        if System.Double.IsNaN(n) || System.Double.IsInfinity(n) then
            true
        else
            let expr = Expression.Number n
            let simplified = Expression.simplify expr
            match simplified with
            | Expression.Number v -> abs(v - n) < 0.0001
            | _ -> false

    [<Property>]
    let ``0 + n = n`` (n: float) =
        if System.Double.IsNaN(n) || System.Double.IsInfinity(n) then
            true
        else
            let expr = Expression.Add(Expression.Number 0.0, Expression.Number n)
            let simplified = Expression.simplify expr
            match simplified with
            | Expression.Number v -> abs(v - n) < 0.0001
            | _ -> false


// ============================================
// 第8章: Decorator パターン テスト
// ============================================

open FunctionalDesign.Part3.DecoratorPattern

// ============================================
// 1. JournaledShape テスト
// ============================================

module JournaledShapeTests =

    [<Fact>]
    let ``JournaledShape を作成できる`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let js = JournaledShape.create circle
        Assert.Empty(JournaledShape.getJournal js)

    [<Fact>]
    let ``translate がジャーナルに記録される`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let js =
            JournaledShape.create circle
            |> JournaledShape.translate 2.0 3.0
        let journal = JournaledShape.getJournal js
        Assert.Single(journal) |> ignore
        match journal.[0] with
        | Translate(dx, dy) ->
            Assert.Equal(2.0, dx)
            Assert.Equal(3.0, dy)
        | _ -> Assert.Fail("Expected Translate")

    [<Fact>]
    let ``scale がジャーナルに記録される`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let js =
            JournaledShape.create circle
            |> JournaledShape.scale 2.0
        let journal = JournaledShape.getJournal js
        Assert.Single(journal) |> ignore
        match journal.[0] with
        | Scale factor -> Assert.Equal(2.0, factor)
        | _ -> Assert.Fail("Expected Scale")

    [<Fact>]
    let ``複数の操作がジャーナルに記録される`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let js =
            JournaledShape.create circle
            |> JournaledShape.translate 2.0 3.0
            |> JournaledShape.scale 5.0
        let journal = JournaledShape.getJournal js
        Assert.Equal(2, List.length journal)

    [<Fact>]
    let ``実際の形状が更新される`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let js =
            JournaledShape.create circle
            |> JournaledShape.translate 2.0 3.0
            |> JournaledShape.scale 2.0
        match JournaledShape.getShape js with
        | Shape.Circle(cx, cy, r) ->
            Assert.Equal(2.0, cx)
            Assert.Equal(3.0, cy)
            Assert.Equal(10.0, r)
        | _ -> Assert.Fail("Expected Circle")

    [<Fact>]
    let ``clearJournal でジャーナルがクリアされる`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let js =
            JournaledShape.create circle
            |> JournaledShape.translate 2.0 3.0
            |> JournaledShape.clearJournal
        Assert.Empty(JournaledShape.getJournal js)

    [<Fact>]
    let ``replay でジャーナルを再生できる`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let entries = [ Translate(2.0, 3.0); Scale(2.0) ]
        let js =
            JournaledShape.create circle
            |> JournaledShape.replay entries
        match JournaledShape.getShape js with
        | Shape.Circle(cx, cy, r) ->
            Assert.Equal(2.0, cx)
            Assert.Equal(3.0, cy)
            Assert.Equal(10.0, r)
        | _ -> Assert.Fail("Expected Circle")

    [<Fact>]
    let ``area がデコレートされた形状の面積を返す`` () =
        let circle = Shape.Circle(0.0, 0.0, 5.0)
        let js = JournaledShape.create circle
        let expected = System.Math.PI * 25.0
        Assert.Equal(expected, JournaledShape.area js, 5)

// ============================================
// 2. 関数デコレータテスト
// ============================================

module FunctionDecoratorsTests =

    [<Fact>]
    let ``withLogging がログを記録する`` () =
        let collector = LogCollector()
        let add10 = fun x -> x + 10
        let logged = withLogging "add10" collector add10
        let result = logged 5
        Assert.Equal(15, result)
        let logs = collector.GetLogs()
        Assert.Equal(2, List.length logs)
        Assert.Contains("called with", logs.[0])
        Assert.Contains("returned", logs.[1])

    [<Fact>]
    let ``withRetry が成功するまでリトライする`` () =
        let mutable attempts = 0
        let unreliable x =
            attempts <- attempts + 1
            if attempts < 3 then failwith "Error"
            else x * 2
        let withRetryFn = withRetry 5 unreliable
        let result = withRetryFn 5
        Assert.Equal(10, result)
        Assert.Equal(3, attempts)

    [<Fact>]
    let ``withRetry がリトライ上限に達すると例外を投げる`` () =
        let alwaysFails _ = failwith "Always fails"
        let withRetryFn = withRetry 3 alwaysFails
        Assert.Throws<System.Exception>(fun () -> withRetryFn 5 |> ignore)

    [<Fact>]
    let ``withCache がキャッシュする`` () =
        let mutable callCount = 0
        let expensive x =
            callCount <- callCount + 1
            x * 2
        let cached = withCache () expensive
        let _ = cached 5
        let _ = cached 5
        let _ = cached 5
        Assert.Equal(1, callCount)

    [<Fact>]
    let ``withCache が異なる引数をキャッシュする`` () =
        let mutable callCount = 0
        let expensive x =
            callCount <- callCount + 1
            x * 2
        let cached = withCache () expensive
        let _ = cached 5
        let _ = cached 6
        let _ = cached 5
        Assert.Equal(2, callCount)

    [<Fact>]
    let ``withValidation が有効な入力を通す`` () =
        let double' = fun x -> x * 2
        let validated = withValidation (fun x -> x > 0) "Must be positive" double'
        Assert.Equal(10, validated 5)

    [<Fact>]
    let ``withValidation が無効な入力で例外を投げる`` () =
        let double' = fun x -> x * 2
        let validated = withValidation (fun x -> x > 0) "Must be positive" double'
        Assert.Throws<System.ArgumentException>(fun () -> validated -5 |> ignore)

    [<Fact>]
    let ``withOptionResult が成功時に Some を返す`` () =
        let double' = fun x -> x * 2
        let optioned = withOptionResult double'
        Assert.Equal(Some 10, optioned 5)

    [<Fact>]
    let ``withOptionResult が失敗時に None を返す`` () =
        let failing _ = failwith "Error"
        let optioned = withOptionResult failing
        Assert.Equal(None, optioned 5)

    [<Fact>]
    let ``withEitherResult が成功時に Ok を返す`` () =
        let double' = fun x -> x * 2
        let eithered = withEitherResult double'
        match eithered 5 with
        | Ok v -> Assert.Equal(10, v)
        | Error _ -> Assert.Fail("Expected Ok")

    [<Fact>]
    let ``withEitherResult が失敗時に Error を返す`` () =
        let failing _ = failwith "Error"
        let eithered = withEitherResult failing
        match eithered 5 with
        | Ok _ -> Assert.Fail("Expected Error")
        | Error _ -> Assert.True(true)

    [<Fact>]
    let ``withDefault が失敗時にデフォルト値を返す`` () =
        let failing _ = failwith "Error"
        let defaulted = withDefault 42 failing
        Assert.Equal(42, defaulted 5)

    [<Fact>]
    let ``withTiming が実行時間を記録する`` () =
        let collector = LogCollector()
        let slow x =
            System.Threading.Thread.Sleep(10)
            x * 2
        let timed = withTiming collector "slow" slow
        let _ = timed 5
        let logs = collector.GetLogs()
        Assert.Single(logs) |> ignore
        Assert.Contains("took", logs.[0])

// ============================================
// 3. デコレータ合成テスト
// ============================================

module DecoratorCompositionTests =

    [<Fact>]
    let ``composeDecorators が複数のデコレータを合成する`` () =
        let collector = LogCollector()
        let double' = fun x -> x * 2
        let decorators = [
            withLogging "double" collector
            withValidation (fun x -> x > 0) "Must be positive"
        ]
        let composed = composeDecorators decorators double'
        let result = composed 5
        Assert.Equal(10, result)
        Assert.Equal(2, collector.GetLogs() |> List.length)

// ============================================
// 4. AuditedList テスト
// ============================================

module AuditedListTests =

    [<Fact>]
    let ``AuditedList.empty が空のリストを作成する`` () =
        let list = AuditedList.empty<int>
        Assert.Empty(AuditedList.items list)
        Assert.Empty(AuditedList.operations list)

    [<Fact>]
    let ``add が要素を追加して操作を記録する`` () =
        let list =
            AuditedList.empty
            |> AuditedList.add 1
            |> AuditedList.add 2
        Assert.Equal<int list>([ 1; 2 ], AuditedList.items list)
        Assert.Equal(2, AuditedList.operations list |> List.length)

    [<Fact>]
    let ``remove が要素を削除して操作を記録する`` () =
        let list =
            AuditedList.empty
            |> AuditedList.add 1
            |> AuditedList.add 2
            |> AuditedList.remove 1
        Assert.Equal<int list>([ 2 ], AuditedList.items list)
        Assert.Equal(3, AuditedList.operations list |> List.length)

    [<Fact>]
    let ``map が操作を記録する`` () =
        let list =
            AuditedList.empty
            |> AuditedList.add 1
            |> AuditedList.add 2
            |> AuditedList.map (fun x -> x * 2)
        Assert.Equal<int list>([ 2; 4 ], AuditedList.items list)
        Assert.Contains("map", AuditedList.operations list)

    [<Fact>]
    let ``filter が操作を記録する`` () =
        let list =
            AuditedList.empty
            |> AuditedList.add 1
            |> AuditedList.add 2
            |> AuditedList.add 3
            |> AuditedList.filter (fun x -> x > 1)
        Assert.Equal<int list>([ 2; 3 ], AuditedList.items list)
        Assert.Contains("filter", AuditedList.operations list)

    [<Fact>]
    let ``clearOperations が操作履歴をクリアする`` () =
        let list =
            AuditedList.empty
            |> AuditedList.add 1
            |> AuditedList.add 2
            |> AuditedList.clearOperations
        Assert.Equal<int list>([ 1; 2 ], AuditedList.items list)
        Assert.Empty(AuditedList.operations list)

// ============================================
// 5. HTTPクライアントデコレータテスト
// ============================================

module HttpClientDecoratorTests =

    [<Fact>]
    let ``SimpleHttpClient がレスポンスを返す`` () =
        let client = SimpleHttpClient() :> IHttpClient
        let response = client.Get("http://example.com")
        Assert.Equal(200, response.StatusCode)
        Assert.Contains("example.com", response.Body)

    [<Fact>]
    let ``LoggingHttpClient がログを記録する`` () =
        let collector = LogCollector()
        let inner = SimpleHttpClient() :> IHttpClient
        let client = LoggingHttpClient(inner, collector) :> IHttpClient
        let _ = client.Get("http://example.com")
        let logs = collector.GetLogs()
        Assert.Equal(2, List.length logs)
        Assert.Contains("GET", logs.[0])
        Assert.Contains("Response", logs.[1])

    [<Fact>]
    let ``CachingHttpClient がキャッシュする`` () =
        let mutable callCount = 0
        let inner =
            { new IHttpClient with
                member _.Get(url) =
                    callCount <- callCount + 1
                    { StatusCode = 200; Body = url } }
        let client = CachingHttpClient(inner) :> IHttpClient
        let _ = client.Get("http://example.com")
        let _ = client.Get("http://example.com")
        Assert.Equal(1, callCount)

    [<Fact>]
    let ``デコレータを組み合わせられる`` () =
        let collector = LogCollector()
        let inner = SimpleHttpClient() :> IHttpClient
        let cached = CachingHttpClient(inner) :> IHttpClient
        let logged = LoggingHttpClient(cached, collector) :> IHttpClient
        let _ = logged.Get("http://example.com")
        let _ = logged.Get("http://example.com")
        // ログは2回の呼び出しで4件（各呼び出しにつき2件）
        Assert.Equal(4, collector.GetLogs() |> List.length)

// ============================================
// 6. FunctionBuilder テスト
// ============================================

module FunctionBuilderTests =

    [<Fact>]
    let ``FunctionBuilder でデコレータを適用できる`` () =
        let collector = LogCollector()
        let double' x = x * 2
        let fn =
            FunctionBuilder.create collector double'
            |> fun b -> b.WithLogging("double")
            |> fun b -> b.Build()
        let result = fn 5
        Assert.Equal(10, result)
        Assert.Equal(2, collector.GetLogs() |> List.length)

    [<Fact>]
    let ``FunctionBuilder で複数のデコレータを適用できる`` () =
        let collector = LogCollector()
        let double' x = x * 2
        let fn =
            FunctionBuilder.create collector double'
            |> fun b -> b.WithValidation((fun x -> x > 0), "Must be positive")
            |> fun b -> b.WithLogging("double")
            |> fun b -> b.Build()
        let result = fn 5
        Assert.Equal(10, result)

// ============================================
// 7. TransactionalOperation テスト
// ============================================

module TransactionalOperationTests =

    [<Fact>]
    let ``トランザクションを開始できる`` () =
        let tx =
            TransactionalOperation.create ()
            |> TransactionalOperation.begin' 10
        Assert.Equal(TransactionState.InProgress, tx.State)
        Assert.Equal(Some 10, TransactionalOperation.getValue tx)

    [<Fact>]
    let ``操作を追加できる`` () =
        let tx =
            TransactionalOperation.create ()
            |> TransactionalOperation.begin' 10
            |> TransactionalOperation.addOperation (fun x -> x + 5)
        Assert.Equal(Some 15, TransactionalOperation.getValue tx)

    [<Fact>]
    let ``コミットできる`` () =
        let tx =
            TransactionalOperation.create ()
            |> TransactionalOperation.begin' 10
            |> TransactionalOperation.addOperation (fun x -> x + 5)
            |> TransactionalOperation.commit
        Assert.Equal(TransactionState.Committed, tx.State)
        Assert.Equal(Some 15, TransactionalOperation.getValue tx)

    [<Fact>]
    let ``ロールバックで元の値に戻る`` () =
        let tx =
            TransactionalOperation.create ()
            |> TransactionalOperation.begin' 10
            |> TransactionalOperation.addOperation (fun x -> x + 5)
            |> TransactionalOperation.addOperation (fun x -> x * 2)
            |> TransactionalOperation.rollback
        Assert.Equal(TransactionState.RolledBack, tx.State)
        Assert.Equal(Some 10, TransactionalOperation.getValue tx)

    [<Fact>]
    let ``開始前は操作を追加できない`` () =
        let tx =
            TransactionalOperation.create ()
            |> TransactionalOperation.addOperation (fun x -> x + 5)
        Assert.Equal(TransactionState.NotStarted, tx.State)
        Assert.Equal(None, TransactionalOperation.getValue tx)


// ============================================
// 第9章: Adapter パターン テスト
// ============================================

open FunctionalDesign.Part3.AdapterPattern

// ============================================
// 1. VariableLightAdapter テスト
// ============================================

module VariableLightAdapterTests =

    [<Fact>]
    let ``VariableLight を作成できる`` () =
        let light = VariableLight.Create(50)
        Assert.Equal(50, light.Intensity)

    [<Fact>]
    let ``VariableLight の強度を設定できる`` () =
        let light = VariableLight.Create(50)
        let updated = light.SetIntensity(80)
        Assert.Equal(80, updated.Intensity)

    [<Fact>]
    let ``VariableLight の強度は0-100にクランプされる`` () =
        let light = VariableLight.Create(50)
        Assert.Equal(0, light.SetIntensity(-10).Intensity)
        Assert.Equal(100, light.SetIntensity(150).Intensity)

    [<Fact>]
    let ``VariableLightAdapter を作成できる`` () =
        let light = VariableLight.Create(0)
        let adapter = VariableLightAdapter.create light
        Assert.Equal(0, VariableLightAdapter.getIntensity adapter)

    [<Fact>]
    let ``VariableLightAdapter.turnOn で最大強度になる`` () =
        let light = VariableLight.Create(0)
        let adapter = VariableLightAdapter.create light :> ISwitchable
        let on = adapter.TurnOn() :?> VariableLightAdapter
        Assert.True(adapter.TurnOn().IsOn)
        Assert.Equal(100, VariableLightAdapter.getIntensity on)

    [<Fact>]
    let ``VariableLightAdapter.turnOff で最小強度になる`` () =
        let light = VariableLight.Create(100)
        let adapter = VariableLightAdapter.create light :> ISwitchable
        let off = adapter.TurnOff() :?> VariableLightAdapter
        Assert.False(adapter.TurnOff().IsOn)
        Assert.Equal(0, VariableLightAdapter.getIntensity off)

// ============================================
// 2. UserFormatAdapter テスト
// ============================================

module UserFormatAdapterTests =

    [<Fact>]
    let ``旧フォーマットを新フォーマットに変換できる`` () =
        let old = { FirstName = "太郎"; LastName = "山田"; EmailAddress = "taro@example.com"; PhoneNumber = "090-1234-5678" }
        let newUser = UserFormatAdapter.adaptOldToNew old
        Assert.Equal("山田 太郎", newUser.Name)
        Assert.Equal("taro@example.com", newUser.Email)
        Assert.Equal("090-1234-5678", newUser.Phone)
        Assert.True(newUser.Metadata.ContainsKey("migrated"))

    [<Fact>]
    let ``新フォーマットを旧フォーマットに変換できる`` () =
        let newUser = { Name = "山田 太郎"; Email = "taro@example.com"; Phone = "090-1234-5678"; Metadata = Map.empty }
        let old = UserFormatAdapter.adaptNewToOld newUser
        Assert.Equal("太郎", old.FirstName)
        Assert.Equal("山田", old.LastName)
        Assert.Equal("taro@example.com", old.EmailAddress)

    [<Fact>]
    let ``往復変換で元のデータに戻る`` () =
        let original = { FirstName = "太郎"; LastName = "山田"; EmailAddress = "taro@example.com"; PhoneNumber = "090-1234-5678" }
        let roundTrip = original |> UserFormatAdapter.adaptOldToNew |> UserFormatAdapter.adaptNewToOld
        Assert.Equal(original.FirstName, roundTrip.FirstName)
        Assert.Equal(original.LastName, roundTrip.LastName)
        Assert.Equal(original.EmailAddress, roundTrip.EmailAddress)

// ============================================
// 3. TemperatureAdapter テスト
// ============================================

module TemperatureAdapterTests =

    [<Fact>]
    let ``摂氏0度は華氏32度`` () =
        let (Fahrenheit f) = TemperatureAdapter.celsiusToFahrenheit (Celsius 0.0)
        Assert.Equal(32.0, f, 2)

    [<Fact>]
    let ``摂氏100度は華氏212度`` () =
        let (Fahrenheit f) = TemperatureAdapter.celsiusToFahrenheit (Celsius 100.0)
        Assert.Equal(212.0, f, 2)

    [<Fact>]
    let ``華氏32度は摂氏0度`` () =
        let (Celsius c) = TemperatureAdapter.fahrenheitToCelsius (Fahrenheit 32.0)
        Assert.Equal(0.0, c, 2)

    [<Fact>]
    let ``摂氏0度はケルビン273.15`` () =
        let (Kelvin k) = TemperatureAdapter.celsiusToKelvin (Celsius 0.0)
        Assert.Equal(273.15, k, 2)

    [<Fact>]
    let ``ケルビン273.15は摂氏0度`` () =
        let (Celsius c) = TemperatureAdapter.kelvinToCelsius (Kelvin 273.15)
        Assert.Equal(0.0, c, 2)

    [<Fact>]
    let ``往復変換で元の値に戻る`` () =
        let original = Celsius 25.0
        let (Celsius result) =
            original
            |> TemperatureAdapter.celsiusToFahrenheit
            |> TemperatureAdapter.fahrenheitToCelsius
        Assert.Equal(25.0, result, 2)

// ============================================
// 4. DateTimeAdapter テスト
// ============================================

module DateTimeAdapterTests =

    [<Fact>]
    let ``UnixタイムスタンプをDateTimeに変換できる`` () =
        let dt = DateTimeAdapter.fromUnixTimestamp 0L
        Assert.Equal(1970, dt.Year)
        Assert.Equal(1, dt.Month)
        Assert.Equal(1, dt.Day)

    [<Fact>]
    let ``DateTimeをUnixタイムスタンプに変換できる`` () =
        let dt = System.DateTime(1970, 1, 1, 0, 0, 0, System.DateTimeKind.Utc)
        let timestamp = DateTimeAdapter.toUnixTimestamp dt
        Assert.Equal(0L, timestamp)

    [<Fact>]
    let ``ISO 8601文字列をパースできる`` () =
        let result = DateTimeAdapter.fromIso8601 "2023-06-15T10:30:00Z"
        Assert.True(result.IsSome)
        Assert.Equal(2023, result.Value.Year)
        Assert.Equal(6, result.Value.Month)
        Assert.Equal(15, result.Value.Day)

    [<Fact>]
    let ``無効な文字列はNoneを返す`` () =
        let result = DateTimeAdapter.fromIso8601 "invalid"
        Assert.True(result.IsNone)

    [<Fact>]
    let ``カスタムフォーマットでパースできる`` () =
        let result = DateTimeAdapter.fromCustomFormat "yyyy/MM/dd" "2023/06/15"
        Assert.True(result.IsSome)
        Assert.Equal(2023, result.Value.Year)

// ============================================
// 5. CurrencyAdapter テスト
// ============================================

module CurrencyAdapterTests =

    [<Fact>]
    let ``USDはそのままUSD`` () =
        let (USD result) = CurrencyAdapter.toUSD (USD 100m)
        Assert.Equal(100m, result)

    [<Fact>]
    let ``EURをUSDに変換できる`` () =
        let (USD result) = CurrencyAdapter.toUSD (EUR 85m)
        Assert.Equal(100m, result)

    [<Fact>]
    let ``USDからEURに変換できる`` () =
        let (EUR result) = CurrencyAdapter.fromUSD (USD 100m) "EUR"
        Assert.Equal(85m, result)

    [<Fact>]
    let ``金額を取得できる`` () =
        Assert.Equal(100m, CurrencyAdapter.getAmount (USD 100m))
        Assert.Equal(85m, CurrencyAdapter.getAmount (EUR 85m))
        Assert.Equal(110m, CurrencyAdapter.getAmount (JPY 110m))

// ============================================
// 6. FilePathAdapter テスト
// ============================================

module FilePathAdapterTests =

    [<Fact>]
    let ``WindowsパスをUnixパスに変換できる`` () =
        let result = FilePathAdapter.windowsToUnix @"C:\Users\test\file.txt"
        Assert.Equal("C:/Users/test/file.txt", result)

    [<Fact>]
    let ``UnixパスをWindowsパスに変換できる`` () =
        let result = FilePathAdapter.unixToWindows "/home/test/file.txt"
        Assert.Equal(@"\home\test\file.txt", result)

    [<Fact>]
    let ``パスコンポーネントを取得できる`` () =
        let components = FilePathAdapter.getComponents "/home/test/file.txt"
        Assert.Equal<string list>([ "home"; "test"; "file.txt" ], components)

    [<Fact>]
    let ``コンポーネントからパスを構築できる`` () =
        let path = FilePathAdapter.fromComponents '/' [ "home"; "test"; "file.txt" ]
        Assert.Equal("home/test/file.txt", path)

// ============================================
// 7. LogLevelAdapter テスト
// ============================================

module LogLevelAdapterTests =

    [<Fact>]
    let ``アプリログレベルを外部に変換できる`` () =
        Assert.Equal(ExternalLogLevel.Verbose, LogLevelAdapter.appToExternal AppLogLevel.Trace)
        Assert.Equal(ExternalLogLevel.Debug, LogLevelAdapter.appToExternal AppLogLevel.Debug)
        Assert.Equal(ExternalLogLevel.Information, LogLevelAdapter.appToExternal AppLogLevel.Info)
        Assert.Equal(ExternalLogLevel.Warning, LogLevelAdapter.appToExternal AppLogLevel.Warning)
        Assert.Equal(ExternalLogLevel.Error, LogLevelAdapter.appToExternal AppLogLevel.Error)
        Assert.Equal(ExternalLogLevel.Critical, LogLevelAdapter.appToExternal AppLogLevel.Fatal)

    [<Fact>]
    let ``外部ログレベルをアプリに変換できる`` () =
        Assert.Equal(AppLogLevel.Trace, LogLevelAdapter.externalToApp ExternalLogLevel.Verbose)
        Assert.Equal(AppLogLevel.Debug, LogLevelAdapter.externalToApp ExternalLogLevel.Debug)
        Assert.Equal(AppLogLevel.Info, LogLevelAdapter.externalToApp ExternalLogLevel.Information)

// ============================================
// 8. CollectionAdapter テスト
// ============================================

module CollectionAdapterTests =

    [<Fact>]
    let ``ArrayをListに変換できる`` () =
        let arr = [| 1; 2; 3 |]
        let list = CollectionAdapter.arrayToList arr
        Assert.Equal<int list>([ 1; 2; 3 ], list)

    [<Fact>]
    let ``ListをArrayに変換できる`` () =
        let list = [ 1; 2; 3 ]
        let arr = CollectionAdapter.listToArray list
        Assert.Equal<int array>([| 1; 2; 3 |], arr)

    [<Fact>]
    let ``MapをDictionaryに変換できる`` () =
        let map = Map.ofList [ ("a", 1); ("b", 2) ]
        let dict = CollectionAdapter.mapToDict map
        Assert.Equal(1, dict.["a"])
        Assert.Equal(2, dict.["b"])

    [<Fact>]
    let ``DictionaryをMapに変換できる`` () =
        let dict = System.Collections.Generic.Dictionary<string, int>()
        dict.["a"] <- 1
        dict.["b"] <- 2
        let map = CollectionAdapter.dictToMap dict
        Assert.Equal(Some 1, Map.tryFind "a" map)
        Assert.Equal(Some 2, Map.tryFind "b" map)

// ============================================
// 9. ResultAdapter テスト
// ============================================

module ResultAdapterTests =

    [<Fact>]
    let ``Some を Ok に変換できる`` () =
        let result = ResultAdapter.optionToResult "error" (Some 42)
        Assert.Equal(Ok 42, result)

    [<Fact>]
    let ``None を Error に変換できる`` () =
        let result = ResultAdapter.optionToResult "error" None
        Assert.Equal(Error "error", result)

    [<Fact>]
    let ``Ok を Some に変換できる`` () =
        let option = ResultAdapter.resultToOption (Ok 42)
        Assert.Equal(Some 42, option)

    [<Fact>]
    let ``Error を None に変換できる`` () =
        let option = ResultAdapter.resultToOption (Error "error")
        Assert.Equal(None, option)

    [<Fact>]
    let ``tryToResult が成功時に Ok を返す`` () =
        let result = ResultAdapter.tryToResult (fun () -> 42)
        match result with
        | Ok v -> Assert.Equal(42, v)
        | Error _ -> Assert.Fail("Expected Ok")

    [<Fact>]
    let ``tryToResult が失敗時に Error を返す`` () =
        let result = ResultAdapter.tryToResult (fun () -> failwith "error")
        match result with
        | Ok _ -> Assert.Fail("Expected Error")
        | Error _ -> Assert.True(true)
