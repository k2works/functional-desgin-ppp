module Tests

open System
open Xunit
open FunctionalDesign.Part5.GossipingBusDrivers
open FunctionalDesign.Part5.PayrollSystem
open FunctionalDesign.Part5.VideoRentalSystem

// ============================================
// 第15章: ゴシップ好きなバスの運転手テスト
// ============================================

module GossipingBusDriversTests =

    // ============================================
    // 1. ドライバー操作テスト
    // ============================================

    [<Fact>]
    let ``ドライバーを作成できる`` () =
        let driver = Driver.create "D1" [1; 2; 3] (Set.ofList ["rumor-a"])
        Assert.Equal("D1", driver.Name)
        Assert.Equal<int list>([1; 2; 3], driver.Route)
        Assert.Equal(0, driver.Position)
        Assert.True(Set.contains "rumor-a" driver.Rumors)

    [<Fact>]
    let ``現在の停留所を取得できる`` () =
        let driver = Driver.create "D1" [1; 2; 3] Set.empty
        Assert.Equal(1, Driver.currentStop driver)

    [<Fact>]
    let ``ドライバーを移動できる`` () =
        let driver = Driver.create "D1" [1; 2; 3] Set.empty
        let moved = Driver.move driver
        Assert.Equal(2, Driver.currentStop moved)

    [<Fact>]
    let ``ルートは循環する`` () =
        let driver = Driver.create "D1" [1; 2; 3] Set.empty
        let moved = driver |> Driver.move |> Driver.move |> Driver.move
        Assert.Equal(1, Driver.currentStop moved)

    [<Fact>]
    let ``噂を追加できる`` () =
        let driver = Driver.create "D1" [1] (Set.ofList ["rumor-a"])
        let updated = Driver.addRumors (Set.ofList ["rumor-b"; "rumor-c"]) driver
        Assert.Equal(3, Set.count updated.Rumors)
        Assert.True(Set.contains "rumor-b" updated.Rumors)

    // ============================================
    // 2. ワールド操作テスト
    // ============================================

    [<Fact>]
    let ``全ドライバーを移動できる`` () =
        let world = [
            Driver.create "D1" [1; 2] Set.empty
            Driver.create "D2" [3; 4] Set.empty
        ]
        let moved = World.moveAll world
        Assert.Equal(2, Driver.currentStop moved.[0])
        Assert.Equal(4, Driver.currentStop moved.[1])

    [<Fact>]
    let ``停留所ごとにグループ化できる`` () =
        let world = [
            Driver.create "D1" [1; 2] Set.empty
            Driver.create "D2" [1; 3] Set.empty
            Driver.create "D3" [2; 4] Set.empty
        ]
        let groups = World.groupByStop world
        Assert.Equal(2, (Map.find 1 groups |> List.length))
        Assert.Equal(1, (Map.find 2 groups |> List.length))

    [<Fact>]
    let ``同じ停留所のドライバー間で噂を共有できる`` () =
        let drivers = [
            Driver.create "D1" [1] (Set.ofList ["rumor-a"])
            Driver.create "D2" [1] (Set.ofList ["rumor-b"])
        ]
        let shared = World.shareRumors drivers
        Assert.True(Set.contains "rumor-a" shared.[0].Rumors)
        Assert.True(Set.contains "rumor-b" shared.[0].Rumors)
        Assert.True(Set.contains "rumor-a" shared.[1].Rumors)
        Assert.True(Set.contains "rumor-b" shared.[1].Rumors)

    [<Fact>]
    let ``全噂共有の判定ができる`` () =
        let sharedWorld = [
            Driver.create "D1" [1] (Set.ofList ["a"; "b"])
            Driver.create "D2" [2] (Set.ofList ["a"; "b"])
        ]
        Assert.True(World.allRumorsShared sharedWorld)

        let notSharedWorld = [
            Driver.create "D1" [1] (Set.ofList ["a"])
            Driver.create "D2" [2] (Set.ofList ["b"])
        ]
        Assert.False(World.allRumorsShared notSharedWorld)

    // ============================================
    // 3. シミュレーションテスト
    // ============================================

    [<Fact>]
    let ``1ステップのシミュレーションを実行できる`` () =
        let world = [
            Driver.create "D1" [1; 2] (Set.ofList ["rumor-a"])
            Driver.create "D2" [2; 1] (Set.ofList ["rumor-b"])
        ]
        let afterDrive = drive world
        // 移動後、D1は2、D2は1にいるので噂は共有されない
        Assert.False(World.allRumorsShared afterDrive)

    [<Fact>]
    let ``同じ停留所で出会うと噂を共有する`` () =
        let world = [
            Driver.create "D1" [1; 2] (Set.ofList ["rumor-a"])
            Driver.create "D2" [1; 2] (Set.ofList ["rumor-b"])
        ]
        // 両者とも停留所1にいる状態で、移動後は停留所2で出会う
        let afterDrive = drive world
        Assert.True(Set.contains "rumor-a" afterDrive.[0].Rumors)
        Assert.True(Set.contains "rumor-b" afterDrive.[0].Rumors)

    [<Fact>]
    let ``全噂共有までの時間を計算できる`` () =
        let world = [
            Driver.create "D1" [3; 1; 2; 3] (Set.ofList ["rumor-a"])
            Driver.create "D2" [3; 2; 3; 1] (Set.ofList ["rumor-b"])
            Driver.create "D3" [4; 2; 3; 4; 5] (Set.ofList ["rumor-c"])
        ]
        match simulate world with
        | Completed minutes -> Assert.True(minutes > 0)
        | Never -> Assert.True(false, "Should complete")

    [<Fact>]
    let ``出会わないルートではNeverを返す`` () =
        let world = [
            Driver.create "D1" [1] (Set.ofList ["rumor-a"])
            Driver.create "D2" [2] (Set.ofList ["rumor-b"])
        ]
        match simulate world with
        | Never -> Assert.True(true)
        | Completed _ -> Assert.True(false, "Should never meet")

    [<Fact>]
    let ``1人だけの場合は即座に完了`` () =
        let world = [
            Driver.create "D1" [1; 2; 3] (Set.ofList ["rumor-a"])
        ]
        match simulate world with
        | Completed 1 -> Assert.True(true)
        | _ -> Assert.True(false, "Should complete in 1 minute")


// ============================================
// 第16章: 給与計算システムテスト
// ============================================

module PayrollSystemTests =

    // ============================================
    // 1. 従業員作成テスト
    // ============================================

    [<Fact>]
    let ``月給制従業員を作成できる`` () =
        let emp = Employee.createSalaried "E001" "Alice" 5000.0m
        Assert.Equal("E001", emp.Id)
        Assert.Equal("Alice", emp.Name)
        Assert.Equal(EmployeeType.Salaried, emp.Type)
        Assert.Equal(Some 5000.0m, emp.Salary)

    [<Fact>]
    let ``時給制従業員を作成できる`` () =
        let emp = Employee.createHourly "E002" "Bob" 25.0m
        Assert.Equal(EmployeeType.Hourly, emp.Type)
        Assert.Equal(Some 25.0m, emp.HourlyRate)

    [<Fact>]
    let ``歩合制従業員を作成できる`` () =
        let emp = Employee.createCommissioned "E003" "Charlie" 2000.0m 0.10m
        Assert.Equal(EmployeeType.Commissioned, emp.Type)
        Assert.Equal(Some 2000.0m, emp.Salary)
        Assert.Equal(Some 0.10m, emp.CommissionRate)

    // ============================================
    // 2. タイムカード・売上レシートテスト
    // ============================================

    [<Fact>]
    let ``タイムカードを追加できる`` () =
        let emp = Employee.createHourly "E001" "Bob" 25.0m
        let tc = { Date = DateTime(2024, 1, 15); Hours = 8.0m }
        let updated = Employee.addTimeCard tc emp
        Assert.Equal(1, List.length updated.TimeCards)

    [<Fact>]
    let ``売上レシートを追加できる`` () =
        let emp = Employee.createCommissioned "E001" "Charlie" 2000.0m 0.10m
        let receipt = { Date = DateTime(2024, 1, 15); Amount = 1000.0m }
        let updated = Employee.addSalesReceipt receipt emp
        Assert.Equal(1, List.length updated.SalesReceipts)

    // ============================================
    // 3. 給与計算テスト
    // ============================================

    [<Fact>]
    let ``月給制の給与を計算できる`` () =
        let emp = Employee.createSalaried "E001" "Alice" 5000.0m
        let pay = Payroll.calculatePay emp
        Assert.Equal(5000.0m, pay)

    [<Fact>]
    let ``時給制の通常時間給与を計算できる`` () =
        let emp =
            Employee.createHourly "E001" "Bob" 25.0m
            |> Employee.addTimeCard { Date = DateTime(2024, 1, 15); Hours = 8.0m }
        let pay = Payroll.calculatePay emp
        Assert.Equal(200.0m, pay) // 25 * 8 = 200

    [<Fact>]
    let ``時給制の残業を含む給与を計算できる`` () =
        let emp =
            Employee.createHourly "E001" "Bob" 20.0m
            |> Employee.addTimeCard { Date = DateTime(2024, 1, 15); Hours = 10.0m }
        let pay = Payroll.calculatePay emp
        // 8時間 * 20 = 160 + 2時間 * 20 * 1.5 = 60 = 220
        Assert.Equal(220.0m, pay)

    [<Fact>]
    let ``歩合制の給与を計算できる`` () =
        let emp =
            Employee.createCommissioned "E001" "Charlie" 2000.0m 0.10m
            |> Employee.addSalesReceipt { Date = DateTime(2024, 1, 15); Amount = 5000.0m }
        let pay = Payroll.calculatePay emp
        // 2000 + 5000 * 0.10 = 2500
        Assert.Equal(2500.0m, pay)

    // ============================================
    // 4. 給与明細テスト
    // ============================================

    [<Fact>]
    let ``給与明細を生成できる`` () =
        let emp = Employee.createSalaried "E001" "Alice" 5000.0m
        let payDate = DateTime(2024, 1, 31)
        let slip = Payslip.generate payDate emp
        Assert.Equal("E001", slip.EmployeeId)
        Assert.Equal("Alice", slip.EmployeeName)
        Assert.Equal(5000.0m, slip.GrossPay)
        Assert.Equal(payDate, slip.PayDate)

    [<Fact>]
    let ``複数従業員の給与明細を生成できる`` () =
        let employees = [
            Employee.createSalaried "E001" "Alice" 5000.0m
            Employee.createSalaried "E002" "Bob" 4000.0m
        ]
        let payDate = DateTime(2024, 1, 31)
        let slips = Payslip.generateAll payDate employees
        Assert.Equal(2, List.length slips)


// ============================================
// 第17章: ビデオレンタルシステムテスト
// ============================================

module VideoRentalSystemTests =

    // ============================================
    // 1. 料金計算テスト
    // ============================================

    [<Fact>]
    let ``通常ビデオの基本料金は2ドル`` () =
        let price = Pricing.regularPrice 2
        Assert.Equal(2.0m, price)

    [<Fact>]
    let ``通常ビデオは3日目から追加料金`` () =
        let price = Pricing.regularPrice 4
        Assert.Equal(5.0m, price) // 2 + (4-2) * 1.5 = 5

    [<Fact>]
    let ``新作ビデオは1日3ドル`` () =
        let price = Pricing.newReleasePrice 3
        Assert.Equal(9.0m, price) // 3 * 3 = 9

    [<Fact>]
    let ``子供向けビデオの基本料金は1.5ドル`` () =
        let price = Pricing.childrensPrice 3
        Assert.Equal(1.5m, price)

    [<Fact>]
    let ``子供向けビデオは4日目から追加料金`` () =
        let price = Pricing.childrensPrice 5
        Assert.Equal(4.5m, price) // 1.5 + (5-3) * 1.5 = 4.5

    // ============================================
    // 2. ポイント計算テスト
    // ============================================

    [<Fact>]
    let ``通常レンタルは1ポイント`` () =
        let rental = Rental.create (Movie.createRegular "Movie") 3
        Assert.Equal(1, Points.calculateRentalPoints rental)

    [<Fact>]
    let ``新作2日以上は2ポイント`` () =
        let rental = Rental.create (Movie.createNewRelease "Movie") 2
        Assert.Equal(2, Points.calculateRentalPoints rental)

    [<Fact>]
    let ``新作1日は1ポイント`` () =
        let rental = Rental.create (Movie.createNewRelease "Movie") 1
        Assert.Equal(1, Points.calculateRentalPoints rental)

    // ============================================
    // 3. 明細書生成テスト
    // ============================================

    [<Fact>]
    let ``顧客の明細書を生成できる`` () =
        let customer =
            Customer.create "John"
            |> Customer.addRental (Rental.create (Movie.createRegular "Jaws") 2)
            |> Customer.addRental (Rental.create (Movie.createNewRelease "Dune") 3)
        let statement = Statement.generate customer
        Assert.Equal("John", statement.CustomerName)
        Assert.Equal(2, List.length statement.Lines)
        Assert.Equal(11.0m, statement.TotalAmount) // 2 + 9 = 11
        Assert.Equal(3, statement.FrequentRenterPoints) // 1 + 2 = 3

    [<Fact>]
    let ``明細書をテキスト形式でフォーマットできる`` () =
        let customer =
            Customer.create "John"
            |> Customer.addRental (Rental.create (Movie.createRegular "Jaws") 2)
        let statement = Statement.generate customer
        let text = Statement.formatText statement
        Assert.Contains("Rental Record for John", text)
        Assert.Contains("Jaws", text)
        Assert.Contains("2.00", text)

    [<Fact>]
    let ``明細書をHTML形式でフォーマットできる`` () =
        let customer =
            Customer.create "John"
            |> Customer.addRental (Rental.create (Movie.createRegular "Jaws") 2)
        let statement = Statement.generate customer
        let html = Statement.formatHtml statement
        Assert.Contains("<h1>Rental Record for John</h1>", html)
        Assert.Contains("<td>Jaws</td>", html)

    // ============================================
    // 4. 統合テスト
    // ============================================

    [<Fact>]
    let ``複数レンタルの合計金額とポイントを計算できる`` () =
        let customer =
            Customer.create "Mary"
            |> Customer.addRental (Rental.create (Movie.createRegular "Titanic") 3)      // 3.5
            |> Customer.addRental (Rental.create (Movie.createNewRelease "Avatar") 1)    // 3.0
            |> Customer.addRental (Rental.create (Movie.createChildrens "Frozen") 4)     // 3.0
        let statement = Statement.generate customer
        Assert.Equal(9.5m, statement.TotalAmount)
        Assert.Equal(3, statement.FrequentRenterPoints) // 1 + 1 + 1 = 3

    [<Fact>]
    let ``レンタルがない顧客の明細書を生成できる`` () =
        let customer = Customer.create "Empty"
        let statement = Statement.generate customer
        Assert.Equal(0.0m, statement.TotalAmount)
        Assert.Equal(0, statement.FrequentRenterPoints)
