namespace FunctionalDesign.Part5

// ============================================
// 第15章: ゴシップ好きなバスの運転手
// ============================================

module GossipingBusDrivers =

    // ============================================
    // 1. データモデル
    // ============================================

    /// 噂の型（文字列の集合）
    type Rumors = Set<string>

    /// ドライバーの型
    type Driver =
        { Name: string
          Route: int list       // 元のルート（循環用）
          Position: int         // 現在のルート位置
          Rumors: Rumors }

    // ============================================
    // 2. ドライバー操作
    // ============================================

    module Driver =
        /// ドライバーを作成
        let create (name: string) (route: int list) (rumors: Rumors) : Driver =
            { Name = name
              Route = route
              Position = 0
              Rumors = rumors }

        /// 現在の停留所を取得
        let currentStop (driver: Driver) : int =
            driver.Route.[driver.Position % driver.Route.Length]

        /// 次の停留所に移動
        let move (driver: Driver) : Driver =
            { driver with Position = driver.Position + 1 }

        /// 噂を追加
        let addRumors (newRumors: Rumors) (driver: Driver) : Driver =
            { driver with Rumors = Set.union driver.Rumors newRumors }

    // ============================================
    // 3. ワールド操作
    // ============================================

    /// ワールド = ドライバーのリスト
    type World = Driver list

    module World =
        /// 全ドライバーを移動
        let moveAll (world: World) : World =
            List.map Driver.move world

        /// 停留所ごとにドライバーをグループ化
        let groupByStop (world: World) : Map<int, Driver list> =
            world
            |> List.groupBy Driver.currentStop
            |> Map.ofList

        /// 同じ停留所にいるドライバー間で噂を共有
        let shareRumors (drivers: Driver list) : Driver list =
            let allRumors =
                drivers
                |> List.map (fun d -> d.Rumors)
                |> Set.unionMany
            drivers
            |> List.map (Driver.addRumors allRumors)

        /// 全停留所で噂を伝播
        let spreadRumors (world: World) : World =
            world
            |> groupByStop
            |> Map.toList
            |> List.map snd
            |> List.map shareRumors
            |> List.concat

        /// 全ドライバーが同じ噂を持っているか確認
        let allRumorsShared (world: World) : bool =
            match world with
            | [] -> true
            | first :: rest ->
                rest |> List.forall (fun d -> d.Rumors = first.Rumors)

    // ============================================
    // 4. シミュレーション
    // ============================================

    /// シミュレーション結果
    type SimulationResult =
        | Completed of minutes: int
        | Never

    /// 1ステップのシミュレーション
    let drive (world: World) : World =
        world
        |> World.moveAll
        |> World.spreadRumors

    /// 全噂が共有されるまでシミュレーション
    let driveTillAllRumorsSpread (maxMinutes: int) (world: World) : SimulationResult =
        let rec loop (w: World) (time: int) =
            if time > maxMinutes then
                Never
            elif World.allRumorsShared w then
                Completed time
            else
                loop (drive w) (time + 1)
        loop (drive world) 1

    /// 480分（8時間）を上限としてシミュレーション
    let simulate (world: World) : SimulationResult =
        driveTillAllRumorsSpread 480 world


// ============================================
// 第16章: 給与計算システム
// ============================================

module PayrollSystem =

    open System

    // ============================================
    // 1. データモデル
    // ============================================

    /// 従業員の種類
    [<RequireQualifiedAccess>]
    type EmployeeType =
        | Salaried       // 月給制
        | Hourly         // 時給制
        | Commissioned   // 歩合制

    /// タイムカードエントリ
    type TimeCard =
        { Date: DateTime
          Hours: decimal }

    /// 売上レシート
    type SalesReceipt =
        { Date: DateTime
          Amount: decimal }

    /// 従業員
    type Employee =
        { Id: string
          Name: string
          Type: EmployeeType
          Salary: decimal option          // 月給（Salaried, Commissionedの場合）
          HourlyRate: decimal option      // 時給（Hourlyの場合）
          CommissionRate: decimal option  // 歩合率（Commissionedの場合）
          TimeCards: TimeCard list
          SalesReceipts: SalesReceipt list }

    // ============================================
    // 2. 従業員作成
    // ============================================

    module Employee =
        /// 月給制従業員を作成
        let createSalaried (id: string) (name: string) (salary: decimal) : Employee =
            { Id = id
              Name = name
              Type = EmployeeType.Salaried
              Salary = Some salary
              HourlyRate = None
              CommissionRate = None
              TimeCards = []
              SalesReceipts = [] }

        /// 時給制従業員を作成
        let createHourly (id: string) (name: string) (hourlyRate: decimal) : Employee =
            { Id = id
              Name = name
              Type = EmployeeType.Hourly
              Salary = None
              HourlyRate = Some hourlyRate
              CommissionRate = None
              TimeCards = []
              SalesReceipts = [] }

        /// 歩合制従業員を作成
        let createCommissioned (id: string) (name: string) (salary: decimal) (commissionRate: decimal) : Employee =
            { Id = id
              Name = name
              Type = EmployeeType.Commissioned
              Salary = Some salary
              HourlyRate = None
              CommissionRate = Some commissionRate
              TimeCards = []
              SalesReceipts = [] }

        /// タイムカードを追加
        let addTimeCard (timeCard: TimeCard) (employee: Employee) : Employee =
            { employee with TimeCards = timeCard :: employee.TimeCards }

        /// 売上レシートを追加
        let addSalesReceipt (receipt: SalesReceipt) (employee: Employee) : Employee =
            { employee with SalesReceipts = receipt :: employee.SalesReceipts }

    // ============================================
    // 3. 給与計算
    // ============================================

    module Payroll =
        /// 時給制の給与計算（8時間を超えると1.5倍）
        let calculateHourlyPay (hourlyRate: decimal) (timeCards: TimeCard list) : decimal =
            timeCards
            |> List.sumBy (fun tc ->
                let regularHours = min tc.Hours 8.0m
                let overtimeHours = max (tc.Hours - 8.0m) 0.0m
                (regularHours * hourlyRate) + (overtimeHours * hourlyRate * 1.5m))

        /// 歩合制の給与計算
        let calculateCommissionPay (baseSalary: decimal) (commissionRate: decimal) (receipts: SalesReceipt list) : decimal =
            let totalSales = receipts |> List.sumBy (fun r -> r.Amount)
            baseSalary + (totalSales * commissionRate)

        /// 従業員の給与を計算
        let calculatePay (employee: Employee) : decimal =
            match employee.Type with
            | EmployeeType.Salaried ->
                employee.Salary |> Option.defaultValue 0m
            | EmployeeType.Hourly ->
                let rate = employee.HourlyRate |> Option.defaultValue 0m
                calculateHourlyPay rate employee.TimeCards
            | EmployeeType.Commissioned ->
                let salary = employee.Salary |> Option.defaultValue 0m
                let rate = employee.CommissionRate |> Option.defaultValue 0m
                calculateCommissionPay salary rate employee.SalesReceipts

    // ============================================
    // 4. 給与明細
    // ============================================

    /// 給与明細
    type Payslip =
        { EmployeeId: string
          EmployeeName: string
          EmployeeType: EmployeeType
          GrossPay: decimal
          PayDate: DateTime }

    module Payslip =
        /// 給与明細を生成
        let generate (payDate: DateTime) (employee: Employee) : Payslip =
            { EmployeeId = employee.Id
              EmployeeName = employee.Name
              EmployeeType = employee.Type
              GrossPay = Payroll.calculatePay employee
              PayDate = payDate }

        /// 複数従業員の給与明細を生成
        let generateAll (payDate: DateTime) (employees: Employee list) : Payslip list =
            employees |> List.map (generate payDate)


// ============================================
// 第17章: ビデオレンタルシステム
// ============================================

module VideoRentalSystem =

    open System

    // ============================================
    // 1. データモデル
    // ============================================

    /// ビデオの種類
    [<RequireQualifiedAccess>]
    type MovieType =
        | Regular       // 通常
        | NewRelease    // 新作
        | Childrens     // 子供向け

    /// ビデオ
    type Movie =
        { Title: string
          Type: MovieType }

    /// レンタル記録
    type Rental =
        { Movie: Movie
          Days: int }

    /// 顧客
    type Customer =
        { Name: string
          Rentals: Rental list }

    // ============================================
    // 2. 料金計算
    // ============================================

    module Pricing =
        /// 通常ビデオの料金計算
        let regularPrice (days: int) : decimal =
            let baseFee = 2.0m
            if days > 2 then
                baseFee + (decimal (days - 2) * 1.5m)
            else
                baseFee

        /// 新作ビデオの料金計算
        let newReleasePrice (days: int) : decimal =
            decimal days * 3.0m

        /// 子供向けビデオの料金計算
        let childrensPrice (days: int) : decimal =
            let baseFee = 1.5m
            if days > 3 then
                baseFee + (decimal (days - 3) * 1.5m)
            else
                baseFee

        /// レンタル料金を計算
        let calculateRentalPrice (rental: Rental) : decimal =
            match rental.Movie.Type with
            | MovieType.Regular -> regularPrice rental.Days
            | MovieType.NewRelease -> newReleasePrice rental.Days
            | MovieType.Childrens -> childrensPrice rental.Days

    // ============================================
    // 3. ポイント計算
    // ============================================

    module Points =
        /// レンタルポイントを計算
        let calculateRentalPoints (rental: Rental) : int =
            match rental.Movie.Type with
            | MovieType.NewRelease when rental.Days > 1 -> 2
            | _ -> 1

    // ============================================
    // 4. 明細書生成
    // ============================================

    /// 明細行
    type StatementLine =
        { MovieTitle: string
          Amount: decimal }

    /// 明細書
    type Statement =
        { CustomerName: string
          Lines: StatementLine list
          TotalAmount: decimal
          FrequentRenterPoints: int }

    module Statement =
        /// 明細行を生成
        let createLine (rental: Rental) : StatementLine =
            { MovieTitle = rental.Movie.Title
              Amount = Pricing.calculateRentalPrice rental }

        /// 明細書を生成
        let generate (customer: Customer) : Statement =
            let lines = customer.Rentals |> List.map createLine
            let total = lines |> List.sumBy (fun l -> l.Amount)
            let points = customer.Rentals |> List.sumBy Points.calculateRentalPoints
            { CustomerName = customer.Name
              Lines = lines
              TotalAmount = total
              FrequentRenterPoints = points }

        /// 明細書をテキスト形式でフォーマット
        let formatText (statement: Statement) : string =
            let header = sprintf "Rental Record for %s\n" statement.CustomerName
            let lines =
                statement.Lines
                |> List.map (fun l -> sprintf "\t%s\t%.2f\n" l.MovieTitle l.Amount)
                |> String.concat ""
            let footer =
                sprintf "Amount owed is %.2f\nYou earned %d frequent renter points"
                    statement.TotalAmount
                    statement.FrequentRenterPoints
            header + lines + footer

        /// 明細書をHTML形式でフォーマット
        let formatHtml (statement: Statement) : string =
            let header = sprintf "<h1>Rental Record for %s</h1>\n<table>\n" statement.CustomerName
            let lines =
                statement.Lines
                |> List.map (fun l -> sprintf "<tr><td>%s</td><td>%.2f</td></tr>\n" l.MovieTitle l.Amount)
                |> String.concat ""
            let footer =
                sprintf "</table>\n<p>Amount owed is %.2f</p>\n<p>You earned %d frequent renter points</p>"
                    statement.TotalAmount
                    statement.FrequentRenterPoints
            header + lines + footer

    // ============================================
    // 5. ユーティリティ
    // ============================================

    module Movie =
        let createRegular title = { Title = title; Type = MovieType.Regular }
        let createNewRelease title = { Title = title; Type = MovieType.NewRelease }
        let createChildrens title = { Title = title; Type = MovieType.Childrens }

    module Customer =
        let create name = { Name = name; Rentals = [] }
        let addRental rental customer =
            { customer with Rentals = rental :: customer.Rentals }

    module Rental =
        let create movie days = { Movie = movie; Days = days }
