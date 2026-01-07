module Tests

open System
open Xunit
open FunctionalDesign.Part7.PatternInteractions
open FunctionalDesign.Part7.BestPractices
open FunctionalDesign.Part7.OOToFPMigration

// ============================================
// 第20章: パターン間の相互作用テスト
// ============================================

module PatternInteractionsTests =

    // ============================================
    // 1. Composite + Decorator テスト
    // ============================================

    [<Fact>]
    let ``円を作成して面積を計算できる`` () =
        let circle = Shape.circle 0.0 0.0 5.0
        let area = Shape.area circle
        Assert.True(area > 78.0 && area < 79.0) // π * 5^2 ≈ 78.54

    [<Fact>]
    let ``矩形を作成して面積を計算できる`` () =
        let rect = Shape.rectangle 0.0 0.0 10.0 5.0
        let area = Shape.area rect
        Assert.Equal(50.0, area)

    [<Fact>]
    let ``複合図形の面積を計算できる`` () =
        let shapes = Shape.composite [
            Shape.circle 0.0 0.0 1.0
            Shape.rectangle 0.0 0.0 2.0 2.0
        ]
        let area = Shape.area shapes
        Assert.True(area > 7.0 && area < 8.0) // π + 4 ≈ 7.14

    [<Fact>]
    let ``図形を移動できる`` () =
        let circle = Shape.circle 0.0 0.0 5.0
        let moved = Shape.move 10.0 20.0 circle
        match moved with
        | Circle(x, y, _) ->
            Assert.Equal(10.0, x)
            Assert.Equal(20.0, y)
        | _ -> Assert.True(false, "Expected Circle")

    [<Fact>]
    let ``図形を拡大できる`` () =
        let circle = Shape.circle 0.0 0.0 5.0
        let scaled = Shape.scale 2.0 circle
        match scaled with
        | Circle(_, _, r) -> Assert.Equal(10.0, r)
        | _ -> Assert.True(false, "Expected Circle")

    [<Fact>]
    let ``ジャーナル付き図形で履歴を記録できる`` () =
        let circle = Shape.circle 0.0 0.0 5.0 |> Shape.journaled
        let moved = Shape.move 10.0 0.0 circle
        let scaled = Shape.scale 2.0 moved
        let journal = Shape.getJournal scaled
        Assert.Equal(2, List.length journal)

    [<Fact>]
    let ``色付き図形を作成できる`` () =
        let colored = Shape.circle 0.0 0.0 5.0 |> Shape.colored "red"
        match colored with
        | Colored(_, color) -> Assert.Equal("red", color)
        | _ -> Assert.True(false, "Expected Colored")

    [<Fact>]
    let ``枠付き図形を作成できる`` () =
        let bordered = Shape.rectangle 0.0 0.0 10.0 5.0 |> Shape.bordered 2.0
        match bordered with
        | Bordered(_, width) -> Assert.Equal(2.0, width)
        | _ -> Assert.True(false, "Expected Bordered")

    // ============================================
    // 2. Command + Observer テスト
    // ============================================

    [<Fact>]
    let ``コマンドを実行して状態を変更できる`` () =
        let executor = CommandExecutor.create 0
        let addCommand = Execute((fun s -> s + 10), "add 10")
        let executor' = CommandExecutor.execute addCommand executor
        Assert.Equal(10, executor'.State)

    [<Fact>]
    let ``コマンドをアンドゥできる`` () =
        let executor = CommandExecutor.create 0
        let addCommand = Execute((fun s -> s + 10), "add 10")
        let executor' =
            executor
            |> CommandExecutor.execute addCommand
            |> CommandExecutor.undo
        Assert.Equal(0, executor'.State)

    [<Fact>]
    let ``オブザーバーに通知される`` () =
        let mutable notified = false
        let observer = fun _ -> notified <- true
        let executor =
            CommandExecutor.create 0
            |> CommandExecutor.subscribe observer
        let addCommand = Execute((fun s -> s + 10), "add 10")
        let _ = CommandExecutor.execute addCommand executor
        Assert.True(notified)

    // ============================================
    // 3. Strategy + Factory テスト
    // ============================================

    [<Fact>]
    let ``通常戦略は金額をそのまま返す`` () =
        let result = PricingStrategy.calculate Regular 1000m
        Assert.Equal(1000m, result)

    [<Fact>]
    let ``割引戦略が適用される`` () =
        let result = PricingStrategy.calculate (Discount 0.10m) 1000m
        Assert.Equal(900m, result)

    [<Fact>]
    let ``ゴールド会員は20%割引`` () =
        let result = PricingStrategy.calculate (Member "gold") 1000m
        Assert.Equal(800m, result)

    [<Fact>]
    let ``ファクトリがVIP顧客にゴールド戦略を返す`` () =
        let strategy = PricingFactory.createFromCustomer "vip" 0m
        match strategy with
        | Member level -> Assert.Equal("gold", level)
        | _ -> Assert.True(false, "Expected Member gold")

    [<Fact>]
    let ``ファクトリが大口注文にBulk戦略を返す`` () =
        let strategy = PricingFactory.createFromCustomer "wholesale" 15000m
        match strategy with
        | Bulk(threshold, rate) ->
            Assert.Equal(10000m, threshold)
            Assert.Equal(0.15m, rate)
        | _ -> Assert.True(false, "Expected Bulk")


// ============================================
// 第21章: ベストプラクティステスト
// ============================================

module BestPracticesTests =

    // ============================================
    // 1. データ中心設計テスト
    // ============================================

    [<Fact>]
    let ``ユーザーを作成できる`` () =
        let user = User.create "U001" "Alice" "alice@example.com"
        Assert.Equal("U001", user.Id)
        Assert.Equal("Alice", user.Name)

    [<Fact>]
    let ``注文の合計金額を計算できる`` () =
        let items = [
            { ProductId = "P001"; Quantity = 2; Price = 100m }
            { ProductId = "P002"; Quantity = 3; Price = 50m }
        ]
        let order = Order.create "O001" "U001" items
        let total = Order.calculateTotal order
        Assert.Equal(350m, total) // 2*100 + 3*50 = 350

    [<Fact>]
    let ``割引を適用できる`` () =
        let total = Order.applyDiscount 0.10m 1000m
        Assert.Equal(900m, total)

    // ============================================
    // 2. パイプラインテスト
    // ============================================

    [<Fact>]
    let ``注文を処理できる`` () =
        let items = [ { ProductId = "P001"; Quantity = 1; Price = 100m } ]
        let order = Order.create "O001" "U001" items
        let total = Pipeline.processOrder 0.10m order
        Assert.Equal(90m, total) // 100 * 0.9 = 90

    [<Fact>]
    let ``注文のステータスを変更できる`` () =
        let items = [ { ProductId = "P001"; Quantity = 1; Price = 100m } ]
        let order = Order.create "O001" "U001" items
        let confirmed = Pipeline.confirm order
        let shipped = Pipeline.ship confirmed
        Assert.Equal(Shipped, shipped.Status)

    [<Fact>]
    let ``未確認の注文は発送できない`` () =
        let items = [ { ProductId = "P001"; Quantity = 1; Price = 100m } ]
        let order = Order.create "O001" "U001" items
        let shipped = Pipeline.ship order
        Assert.Equal(Pending, shipped.Status)

    // ============================================
    // 3. バリデーションテスト
    // ============================================

    [<Fact>]
    let ``有効なメールアドレスを検証できる`` () =
        let result = Validation.validateEmail "test@example.com"
        Assert.True(Result.isOk result)

    [<Fact>]
    let ``無効なメールアドレスはエラーになる`` () =
        let result = Validation.validateEmail "invalid"
        Assert.True(Result.isError result)

    [<Fact>]
    let ``有効な名前を検証できる`` () =
        let result = Validation.validateName "Alice"
        Assert.True(Result.isOk result)

    [<Fact>]
    let ``短すぎる名前はエラーになる`` () =
        let result = Validation.validateName "A"
        Assert.True(Result.isError result)

    [<Fact>]
    let ``有効な数量を検証できる`` () =
        let result = Validation.validateQuantity 5
        Assert.True(Result.isOk result)

    [<Fact>]
    let ``0以下の数量はエラーになる`` () =
        let result = Validation.validateQuantity 0
        Assert.True(Result.isError result)

    // ============================================
    // 4. 純粋関数テスト
    // ============================================

    [<Fact>]
    let ``税金を計算できる`` () =
        let tax = Pure.calculateTax 0.10m 1000m
        Assert.Equal(100m, tax)

    [<Fact>]
    let ``金額をフォーマットできる`` () =
        let formatted = Pure.formatCurrency 1234.56m
        Assert.Equal("$1234.56", formatted)


// ============================================
// 第22章: OO から FP への移行テスト
// ============================================

module OOToFPMigrationTests =

    // ============================================
    // 1. OO スタイルテスト
    // ============================================

    [<Fact>]
    let ``OOスタイルで入金できる`` () =
        let account = AccountOO("A001", 1000m)
        let result = account.Deposit(500m)
        Assert.True(result)
        Assert.Equal(1500m, account.Balance)

    [<Fact>]
    let ``OOスタイルで出金できる`` () =
        let account = AccountOO("A001", 1000m)
        let result = account.Withdraw(300m)
        Assert.True(result)
        Assert.Equal(700m, account.Balance)

    // ============================================
    // 2. FP スタイルテスト
    // ============================================

    [<Fact>]
    let ``FPスタイルで口座を作成できる`` () =
        let account = Account.create "A001" 1000m
        Assert.Equal("A001", account.Id)
        Assert.Equal(1000m, account.Balance)

    [<Fact>]
    let ``FPスタイルで入金できる`` () =
        let account = Account.create "A001" 1000m
        match Account.deposit 500m account with
        | Ok newAccount ->
            Assert.Equal(1500m, newAccount.Balance)
            Assert.Equal(1000m, account.Balance) // 元の口座は変更されない
        | Error _ -> Assert.True(false, "Should succeed")

    [<Fact>]
    let ``FPスタイルで出金できる`` () =
        let account = Account.create "A001" 1000m
        match Account.withdraw 300m account with
        | Ok newAccount -> Assert.Equal(700m, newAccount.Balance)
        | Error _ -> Assert.True(false, "Should succeed")

    [<Fact>]
    let ``FPスタイルで残高不足の場合エラーになる`` () =
        let account = Account.create "A001" 100m
        match Account.withdraw 500m account with
        | Error msg -> Assert.Contains("Insufficient", msg)
        | Ok _ -> Assert.True(false, "Should fail")

    [<Fact>]
    let ``FPスタイルでトランザクション履歴を取得できる`` () =
        let account = Account.create "A001" 1000m
        match Account.deposit 100m account with
        | Ok acc ->
            match Account.withdraw 50m acc with
            | Ok acc2 ->
                let transactions = Account.getTransactions acc2
                Assert.Equal(2, List.length transactions)
            | Error _ -> Assert.True(false)
        | Error _ -> Assert.True(false)

    // ============================================
    // 3. 継承からコンポジションへのテスト
    // ============================================

    [<Fact>]
    let ``動物が鳴く`` () =
        let dog = InheritanceToComposition.Animal.Dog "Buddy"
        let cat = InheritanceToComposition.Animal.Cat "Whiskers"
        let bird = InheritanceToComposition.Animal.Bird "Tweety"

        Assert.Equal("Woof", InheritanceToComposition.speak dog)
        Assert.Equal("Meow", InheritanceToComposition.speak cat)
        Assert.Equal("Tweet", InheritanceToComposition.speak bird)

    [<Fact>]
    let ``動物の名前を取得できる`` () =
        let dog = InheritanceToComposition.Animal.Dog "Buddy"
        Assert.Equal("Buddy", InheritanceToComposition.getName dog)

    // ============================================
    // 4. インターフェースから関数レコードへのテスト
    // ============================================

    [<Fact>]
    let ``関数レコードリポジトリで保存・取得できる`` () =
        let repo = InterfaceToFunctionRecord.createInMemoryRepo<User> (fun u -> u.Id)
        let user = User.create "U001" "Alice" "alice@example.com"
        let saved = repo.Save user
        let found = repo.FindById "U001"

        Assert.Equal("Alice", saved.Name)
        Assert.True(found.IsSome)
        Assert.Equal("Alice", found.Value.Name)

    [<Fact>]
    let ``関数レコードリポジトリで削除できる`` () =
        let repo = InterfaceToFunctionRecord.createInMemoryRepo<User> (fun u -> u.Id)
        let user = User.create "U001" "Alice" "alice@example.com"
        repo.Save user |> ignore
        let deleted = repo.Delete "U001"
        let found = repo.FindById "U001"

        Assert.True(deleted)
        Assert.True(found.IsNone)

    // ============================================
    // 5. イベントソーシングテスト
    // ============================================

    [<Fact>]
    let ``イベントから状態を再構築できる`` () =
        let events = [
            MutableToEventSourcing.AccountEvent.AccountCreated("A001", 1000m)
            MutableToEventSourcing.AccountEvent.MoneyDeposited 500m
            MutableToEventSourcing.AccountEvent.MoneyWithdrawn 200m
        ]
        let account = MutableToEventSourcing.replay events
        Assert.Equal("A001", account.Id)
        Assert.Equal(1300m, account.Balance) // 1000 + 500 - 200
        Assert.Equal(2, List.length account.Transactions)
