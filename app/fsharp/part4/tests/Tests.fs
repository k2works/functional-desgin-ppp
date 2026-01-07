module Tests

open System
open Xunit
open FunctionalDesign.Part4.StrategyPattern

// ============================================
// 1. PricingStrategy テスト
// ============================================

module PricingStrategyTests =

    [<Fact>]
    let ``通常料金は金額をそのまま返す`` () =
        let result = PricingStrategy.calculatePrice PricingStrategy.Regular 1000.0m
        Assert.Equal(1000.0m, result)

    [<Fact>]
    let ``10%割引が適用される`` () =
        let result = PricingStrategy.calculatePrice (PricingStrategy.Discount 0.10m) 1000.0m
        Assert.Equal(900.0m, result)

    [<Fact>]
    let ``ゴールド会員は20%割引`` () =
        let result = PricingStrategy.calculatePrice (PricingStrategy.Member MemberLevel.Gold) 1000.0m
        Assert.Equal(800.0m, result)

    [<Fact>]
    let ``シルバー会員は15%割引`` () =
        let result = PricingStrategy.calculatePrice (PricingStrategy.Member MemberLevel.Silver) 1000.0m
        Assert.Equal(850.0m, result)

    [<Fact>]
    let ``ブロンズ会員は10%割引`` () =
        let result = PricingStrategy.calculatePrice (PricingStrategy.Member MemberLevel.Bronze) 1000.0m
        Assert.Equal(900.0m, result)

    [<Fact>]
    let ``大量購入で閾値以上なら割引`` () =
        let result = PricingStrategy.calculatePrice (PricingStrategy.Bulk(5000.0m, 0.20m)) 6000.0m
        Assert.Equal(4800.0m, result)

    [<Fact>]
    let ``大量購入で閾値未満なら割引なし`` () =
        let result = PricingStrategy.calculatePrice (PricingStrategy.Bulk(5000.0m, 0.20m)) 3000.0m
        Assert.Equal(3000.0m, result)

// ============================================
// 2. ShoppingCart テスト
// ============================================

module ShoppingCartTests =

    [<Fact>]
    let ``カートの小計を計算できる`` () =
        let items =
            [ { Name = "Item A"; Price = 500.0m; Quantity = 1 }
              { Name = "Item B"; Price = 300.0m; Quantity = 2 } ]
        let cart = ShoppingCart.create items PricingStrategy.Regular
        let result = ShoppingCart.subtotal cart
        Assert.Equal(1100.0m, result)

    [<Fact>]
    let ``カートの合計を計算できる（通常料金）`` () =
        let items =
            [ { Name = "Item A"; Price = 500.0m; Quantity = 1 }
              { Name = "Item B"; Price = 500.0m; Quantity = 1 } ]
        let cart = ShoppingCart.create items PricingStrategy.Regular
        let result = ShoppingCart.total cart
        Assert.Equal(1000.0m, result)

    [<Fact>]
    let ``カートの合計を計算できる（割引）`` () =
        let items =
            [ { Name = "Item A"; Price = 500.0m; Quantity = 1 }
              { Name = "Item B"; Price = 500.0m; Quantity = 1 } ]
        let cart = ShoppingCart.create items (PricingStrategy.Discount 0.10m)
        let result = ShoppingCart.total cart
        Assert.Equal(900.0m, result)

    [<Fact>]
    let ``戦略を変更できる`` () =
        let items = [ { Name = "Item A"; Price = 1000.0m; Quantity = 1 } ]
        let cart = ShoppingCart.create items PricingStrategy.Regular
        let updatedCart = ShoppingCart.changeStrategy (PricingStrategy.Member MemberLevel.Gold) cart
        let result = ShoppingCart.total updatedCart
        Assert.Equal(800.0m, result)

    [<Fact>]
    let ``アイテムを追加できる`` () =
        let cart = ShoppingCart.create [] PricingStrategy.Regular
        let item = { Name = "New Item"; Price = 500.0m; Quantity = 1 }
        let updatedCart = ShoppingCart.addItem item cart
        Assert.Equal(1, updatedCart.Items.Length)

// ============================================
// 3. FunctionalStrategy テスト
// ============================================

module FunctionalStrategyTests =

    [<Fact>]
    let ``通常料金戦略が動作する`` () =
        let result = FunctionalStrategy.applyPricing FunctionalStrategy.regularPricing 1000.0m
        Assert.Equal(1000.0m, result)

    [<Fact>]
    let ``割引戦略が動作する`` () =
        let strategy = FunctionalStrategy.discountPricing 0.10m
        let result = FunctionalStrategy.applyPricing strategy 1000.0m
        Assert.Equal(900.0m, result)

    [<Fact>]
    let ``会員戦略が動作する`` () =
        let strategy = FunctionalStrategy.memberPricing MemberLevel.Gold
        let result = FunctionalStrategy.applyPricing strategy 1000.0m
        Assert.Equal(800.0m, result)

    [<Fact>]
    let ``大量購入戦略が動作する`` () =
        let strategy = FunctionalStrategy.bulkPricing 5000.0m 0.20m
        let result = FunctionalStrategy.applyPricing strategy 6000.0m
        Assert.Equal(4800.0m, result)

    [<Fact>]
    let ``税金戦略が動作する`` () =
        let strategy = FunctionalStrategy.taxStrategy 0.10m
        let result = FunctionalStrategy.applyPricing strategy 1000.0m
        Assert.Equal(1100.0m, result)

    [<Fact>]
    let ``戦略を合成できる（割引後に税金）`` () =
        let discount = FunctionalStrategy.discountPricing 0.10m
        let tax = FunctionalStrategy.taxStrategy 0.08m
        let combined = FunctionalStrategy.composeStrategies [ discount; tax ]
        let result = FunctionalStrategy.applyPricing combined 1000.0m
        Assert.Equal(972.0m, result)

    [<Fact>]
    let ``条件付き戦略が動作する（条件成立）`` () =
        let strategy =
            FunctionalStrategy.conditionalStrategy
                (fun amount -> amount >= 5000.0m)
                (FunctionalStrategy.discountPricing 0.20m)
                FunctionalStrategy.regularPricing
        let result = FunctionalStrategy.applyPricing strategy 6000.0m
        Assert.Equal(4800.0m, result)

    [<Fact>]
    let ``条件付き戦略が動作する（条件不成立）`` () =
        let strategy =
            FunctionalStrategy.conditionalStrategy
                (fun amount -> amount >= 5000.0m)
                (FunctionalStrategy.discountPricing 0.20m)
                FunctionalStrategy.regularPricing
        let result = FunctionalStrategy.applyPricing strategy 3000.0m
        Assert.Equal(3000.0m, result)

// ============================================
// 4. ShippingStrategy テスト
// ============================================

module ShippingStrategyTests =

    [<Fact>]
    let ``標準配送の料金を計算できる`` () =
        let result = ShippingStrategy.calculateShipping ShippingStrategy.Standard 2.0m 10.0m 1000.0m
        Assert.Equal(70.0m, result) // 2*10 + 10*5 = 70

    [<Fact>]
    let ``速達配送の料金を計算できる`` () =
        let result = ShippingStrategy.calculateShipping ShippingStrategy.Express 2.0m 10.0m 1000.0m
        Assert.Equal(190.0m, result) // 2*20 + 10*15 = 190

    [<Fact>]
    let ``送料無料（閾値以上）`` () =
        let result = ShippingStrategy.calculateShipping (ShippingStrategy.FreeShipping 5000.0m) 2.0m 10.0m 6000.0m
        Assert.Equal(0.0m, result)

    [<Fact>]
    let ``送料無料（閾値未満）`` () =
        let result = ShippingStrategy.calculateShipping (ShippingStrategy.FreeShipping 5000.0m) 2.0m 10.0m 3000.0m
        Assert.Equal(70.0m, result)

    [<Fact>]
    let ``距離ベース配送の料金を計算できる`` () =
        let result = ShippingStrategy.calculateShipping (ShippingStrategy.DistanceBased 100.0m) 2.0m 10.0m 1000.0m
        Assert.Equal(1000.0m, result) // 10 * 100 = 1000

// ============================================
// 5. PaymentStrategy テスト
// ============================================

module PaymentStrategyTests =

    [<Fact>]
    let ``現金支払いが処理される`` () =
        let result = PaymentStrategy.processPayment PaymentStrategy.Cash 1000.0m 0
        Assert.Equal(1000.0m, result.AmountPaid)
        Assert.Equal(0.0m, result.Fee)
        Assert.Equal(10, result.PointsEarned)

    [<Fact>]
    let ``クレジットカード支払いが処理される`` () =
        let result = PaymentStrategy.processPayment (PaymentStrategy.CreditCard 0.02m) 1000.0m 0
        Assert.Equal(1020.0m, result.AmountPaid)
        Assert.Equal(20.0m, result.Fee)
        Assert.Equal(20, result.PointsEarned) // ポイント2倍

    [<Fact>]
    let ``ポイント支払いが処理される`` () =
        let result = PaymentStrategy.processPayment (PaymentStrategy.Points 1) 1000.0m 500
        Assert.Equal(500.0m, result.AmountPaid)
        Assert.Equal(500, result.PointsUsed)

// ============================================
// 6. SortingStrategy テスト
// ============================================

module SortingStrategyTests =

    let testPeople =
        [ { Name = "Charlie"; Age = 30; Score = 85.0m }
          { Name = "Alice"; Age = 25; Score = 95.0m }
          { Name = "Bob"; Age = 35; Score = 80.0m } ]

    [<Fact>]
    let ``名前でソートできる`` () =
        let result = SortingStrategy.sortByName testPeople
        Assert.Equal("Alice", result.[0].Name)
        Assert.Equal("Bob", result.[1].Name)
        Assert.Equal("Charlie", result.[2].Name)

    [<Fact>]
    let ``年齢でソートできる`` () =
        let result = SortingStrategy.sortByAge testPeople
        Assert.Equal(25, result.[0].Age)
        Assert.Equal(30, result.[1].Age)
        Assert.Equal(35, result.[2].Age)

    [<Fact>]
    let ``スコアで降順ソートできる`` () =
        let result = SortingStrategy.sortByScoreDesc testPeople
        Assert.Equal(95.0m, result.[0].Score)
        Assert.Equal(85.0m, result.[1].Score)
        Assert.Equal(80.0m, result.[2].Score)

    [<Fact>]
    let ``カスタムソート戦略を適用できる`` () =
        let customSort = fun people -> people |> List.sortBy (fun p -> -p.Age)
        let result = SortingStrategy.sortWith customSort testPeople
        Assert.Equal(35, result.[0].Age)

// ============================================
// 7. ValidationStrategy テスト
// ============================================

module ValidationStrategyTests =

    [<Fact>]
    let ``必須フィールドバリデーションが通る`` () =
        let result = ValidationStrategy.required "名前" "太郎"
        Assert.Equal(ValidationResult.Valid, result)

    [<Fact>]
    let ``必須フィールドバリデーションが失敗する`` () =
        let result = ValidationStrategy.required "名前" ""
        match result with
        | ValidationResult.Invalid errors -> Assert.Contains("名前は必須です", errors)
        | _ -> Assert.True(false, "Should be invalid")

    [<Fact>]
    let ``最小長バリデーションが通る`` () =
        let result = ValidationStrategy.minLength "パスワード" 8 "password123"
        Assert.Equal(ValidationResult.Valid, result)

    [<Fact>]
    let ``最小長バリデーションが失敗する`` () =
        let result = ValidationStrategy.minLength "パスワード" 8 "pass"
        match result with
        | ValidationResult.Invalid errors -> Assert.Contains("パスワードは8文字以上必要です", errors)
        | _ -> Assert.True(false, "Should be invalid")

    [<Fact>]
    let ``複数のバリデーションを組み合わせられる`` () =
        let result = ValidationStrategy.validate [
            ValidationStrategy.required "名前" "太郎"
            ValidationStrategy.minLength "名前" 2 "太郎"
        ]
        Assert.Equal(ValidationResult.Valid, result)

    [<Fact>]
    let ``複数のエラーが集約される`` () =
        let result = ValidationStrategy.validate [
            ValidationStrategy.required "名前" ""
            ValidationStrategy.minLength "パスワード" 8 "pass"
        ]
        match result with
        | ValidationResult.Invalid errors ->
            Assert.Equal(2, errors.Length)
        | _ -> Assert.True(false, "Should be invalid")

// ============================================
// 8. CompressionStrategy テスト
// ============================================

module CompressionStrategyTests =

    [<Fact>]
    let ``圧縮なしは同じサイズ`` () =
        let data = Array.zeroCreate<byte> 1000
        let result = CompressionStrategy.compress CompressionStrategy.NoCompression data
        Assert.Equal(1000L, result.OriginalSize)
        Assert.Equal(1000L, result.CompressedSize)
        Assert.Equal("None", result.Algorithm)

    [<Fact>]
    let ``Gzip圧縮が適用される`` () =
        let data = Array.zeroCreate<byte> 1000
        let result = CompressionStrategy.compress CompressionStrategy.Gzip data
        Assert.Equal(1000L, result.OriginalSize)
        Assert.Equal(400L, result.CompressedSize)
        Assert.Equal("Gzip", result.Algorithm)

    [<Fact>]
    let ``Zip圧縮が適用される`` () =
        let data = Array.zeroCreate<byte> 1000
        let result = CompressionStrategy.compress CompressionStrategy.Zip data
        Assert.Equal(500L, result.CompressedSize)
        Assert.Equal("Zip", result.Algorithm)

// ============================================
// 9. CacheStrategy テスト
// ============================================

module CacheStrategyTests =

    [<Fact>]
    let ``NoCacheは何も保存しない`` () =
        let cache = CacheStrategy.empty<string, int> CacheStrategy.NoCache
        let cache = CacheStrategy.put "key1" 100 cache
        let result = CacheStrategy.get "key1" cache
        Assert.True(result.IsNone)

    [<Fact>]
    let ``InMemoryキャッシュに保存できる`` () =
        let cache = CacheStrategy.empty<string, int> (CacheStrategy.InMemory 10)
        let cache = CacheStrategy.put "key1" 100 cache
        let result = CacheStrategy.get "key1" cache
        Assert.Equal(Some 100, result)

    [<Fact>]
    let ``InMemoryキャッシュの最大サイズを超えると古いエントリが削除される`` () =
        let cache = CacheStrategy.empty<string, int> (CacheStrategy.InMemory 2)
        let cache = CacheStrategy.put "key1" 100 cache
        let cache = CacheStrategy.put "key2" 200 cache
        let cache = CacheStrategy.put "key3" 300 cache
        // key1は削除されているはず
        Assert.True((CacheStrategy.get "key1" cache).IsNone)
        Assert.Equal(Some 200, CacheStrategy.get "key2" cache)
        Assert.Equal(Some 300, CacheStrategy.get "key3" cache)

// ============================================
// 10. LoggingStrategy テスト
// ============================================

module LoggingStrategyTests =

    [<Fact>]
    let ``Silentは何も出力しない`` () =
        let result = LoggingStrategy.log LoggingStrategy.Silent LogLevel.Info "test message"
        Assert.True(result.IsNone)

    [<Fact>]
    let ``Filteredはレベル以上のログのみ出力`` () =
        let strategy = LoggingStrategy.Filtered(LogLevel.Warning, LoggingStrategy.Silent)
        let result1 = LoggingStrategy.log strategy LogLevel.Info "info message"
        let result2 = LoggingStrategy.log strategy LogLevel.Warning "warning message"
        Assert.True(result1.IsNone)
        // Warning以上なので処理されるが、innerがSilentなのでNone
        Assert.True(result2.IsNone)

// ============================================
// Chapter 11: Command パターン テスト
// ============================================

open FunctionalDesign.Part4.CommandPattern

// ============================================
// 1. TextCommand テスト
// ============================================

module TextCommandTests =

    [<Fact>]
    let ``テキストを挿入できる`` () =
        let cmd = TextCommand.Insert(5, " World")
        let result = TextCommand.execute cmd "Hello"
        Assert.Equal("Hello World", result)

    [<Fact>]
    let ``テキスト挿入を取り消しできる`` () =
        let cmd = TextCommand.Insert(5, " World")
        let result = TextCommand.undo cmd "Hello World"
        Assert.Equal("Hello", result)

    [<Fact>]
    let ``テキストを削除できる`` () =
        let cmd = TextCommand.Delete(5, 11, " World")
        let result = TextCommand.execute cmd "Hello World"
        Assert.Equal("Hello", result)

    [<Fact>]
    let ``テキスト削除を取り消しできる`` () =
        let cmd = TextCommand.Delete(5, 11, " World")
        let result = TextCommand.undo cmd "Hello"
        Assert.Equal("Hello World", result)

    [<Fact>]
    let ``テキストを置換できる`` () =
        let cmd = TextCommand.Replace(6, "World", "F#")
        let result = TextCommand.execute cmd "Hello World"
        Assert.Equal("Hello F#", result)

    [<Fact>]
    let ``テキスト置換を取り消しできる`` () =
        let cmd = TextCommand.Replace(6, "World", "F#")
        let result = TextCommand.undo cmd "Hello F#"
        Assert.Equal("Hello World", result)

// ============================================
// 2. CanvasCommand テスト
// ============================================

module CanvasCommandTests =

    let testShape = { Id = "shape1"; ShapeType = "Rectangle"; X = 10; Y = 20; Width = 100; Height = 50 }

    [<Fact>]
    let ``図形を追加できる`` () =
        let canvas = { Shapes = [] }
        let cmd = CanvasCommand.AddShape testShape
        let result = CanvasCommand.execute cmd canvas
        Assert.Equal(1, result.Shapes.Length)
        Assert.Equal("shape1", result.Shapes.[0].Id)

    [<Fact>]
    let ``図形追加を取り消しできる`` () =
        let canvas = { Shapes = [ testShape ] }
        let cmd = CanvasCommand.AddShape testShape
        let result = CanvasCommand.undo cmd canvas
        Assert.Equal(0, result.Shapes.Length)

    [<Fact>]
    let ``図形を移動できる`` () =
        let canvas = { Shapes = [ testShape ] }
        let cmd = CanvasCommand.MoveShape("shape1", 10, 5)
        let result = CanvasCommand.execute cmd canvas
        Assert.Equal(20, result.Shapes.[0].X)
        Assert.Equal(25, result.Shapes.[0].Y)

    [<Fact>]
    let ``図形移動を取り消しできる`` () =
        let movedShape = { testShape with X = 20; Y = 25 }
        let canvas = { Shapes = [ movedShape ] }
        let cmd = CanvasCommand.MoveShape("shape1", 10, 5)
        let result = CanvasCommand.undo cmd canvas
        Assert.Equal(10, result.Shapes.[0].X)
        Assert.Equal(20, result.Shapes.[0].Y)

    [<Fact>]
    let ``図形をリサイズできる`` () =
        let canvas = { Shapes = [ testShape ] }
        let cmd = CanvasCommand.ResizeShape("shape1", 100, 50, 200, 100)
        let result = CanvasCommand.execute cmd canvas
        Assert.Equal(200, result.Shapes.[0].Width)
        Assert.Equal(100, result.Shapes.[0].Height)

// ============================================
// 3. CommandExecutor テスト
// ============================================

module CommandExecutorTests =

    [<Fact>]
    let ``コマンドを実行できる`` () =
        let editor = TextEditor.create "Hello"
        let editor = CommandExecutor.execute (TextCommand.Insert(5, " World")) editor
        Assert.Equal("Hello World", CommandExecutor.getState editor)

    [<Fact>]
    let ``アンドゥできる`` () =
        let editor = TextEditor.create "Hello"
        let editor = CommandExecutor.execute (TextCommand.Insert(5, " World")) editor
        let editor = CommandExecutor.undo editor
        Assert.Equal("Hello", CommandExecutor.getState editor)

    [<Fact>]
    let ``リドゥできる`` () =
        let editor = TextEditor.create "Hello"
        let editor = CommandExecutor.execute (TextCommand.Insert(5, " World")) editor
        let editor = CommandExecutor.undo editor
        let editor = CommandExecutor.redo editor
        Assert.Equal("Hello World", CommandExecutor.getState editor)

    [<Fact>]
    let ``アンドゥ可能かどうかを確認できる`` () =
        let editor = TextEditor.create "Hello"
        Assert.False(CommandExecutor.canUndo editor)
        let editor = CommandExecutor.execute (TextCommand.Insert(5, " World")) editor
        Assert.True(CommandExecutor.canUndo editor)

    [<Fact>]
    let ``リドゥ可能かどうかを確認できる`` () =
        let editor = TextEditor.create "Hello"
        let editor = CommandExecutor.execute (TextCommand.Insert(5, " World")) editor
        Assert.False(CommandExecutor.canRedo editor)
        let editor = CommandExecutor.undo editor
        Assert.True(CommandExecutor.canRedo editor)

    [<Fact>]
    let ``複数のコマンドを実行してアンドゥできる`` () =
        let editor = TextEditor.create "Hello"
        let editor = CommandExecutor.execute (TextCommand.Insert(5, " World")) editor
        let editor = CommandExecutor.execute (TextCommand.Insert(11, "!")) editor
        Assert.Equal("Hello World!", CommandExecutor.getState editor)
        let editor = CommandExecutor.undo editor
        Assert.Equal("Hello World", CommandExecutor.getState editor)
        let editor = CommandExecutor.undo editor
        Assert.Equal("Hello", CommandExecutor.getState editor)

// ============================================
// 4. BatchExecutor テスト
// ============================================

module BatchExecutorTests =

    [<Fact>]
    let ``バッチ実行できる`` () =
        let editor = TextEditor.create "Hello"
        let commands = [
            TextCommand.Insert(5, " World")
            TextCommand.Insert(11, "!")
        ]
        let editor = BatchExecutor.executeBatch commands editor
        Assert.Equal("Hello World!", CommandExecutor.getState editor)

    [<Fact>]
    let ``すべてを取り消しできる`` () =
        let editor = TextEditor.create "Hello"
        let commands = [
            TextCommand.Insert(5, " World")
            TextCommand.Insert(11, "!")
        ]
        let editor = BatchExecutor.executeBatch commands editor
        let editor = BatchExecutor.undoAll editor
        Assert.Equal("Hello", CommandExecutor.getState editor)

// ============================================
// 5. MacroCommand テスト
// ============================================

module MacroCommandTests =

    [<Fact>]
    let ``マクロコマンドを実行できる`` () =
        let macro = MacroCommand.create [
            TextCommand.Insert(5, " World")
            TextCommand.Insert(11, "!")
        ]
        let result = MacroCommand.execute TextCommand.execute macro "Hello"
        Assert.Equal("Hello World!", result)

    [<Fact>]
    let ``マクロコマンドを取り消しできる`` () =
        let macro = MacroCommand.create [
            TextCommand.Insert(5, " World")
            TextCommand.Insert(11, "!")
        ]
        let result = MacroCommand.undo TextCommand.undo macro "Hello World!"
        Assert.Equal("Hello", result)

// ============================================
// 6. CommandQueue テスト
// ============================================

module CommandQueueTests =

    [<Fact>]
    let ``キューにコマンドを追加できる`` () =
        let queue = CommandQueue.empty<TextCommand>
        let queue = CommandQueue.enqueue (TextCommand.Insert(5, " World")) queue
        Assert.Equal(1, CommandQueue.size queue)

    [<Fact>]
    let ``キューからコマンドを取り出せる`` () =
        let queue = CommandQueue.empty<TextCommand>
        let queue = CommandQueue.enqueue (TextCommand.Insert(5, " World")) queue
        let (cmd, queue) = CommandQueue.dequeue queue
        Assert.True(cmd.IsSome)
        Assert.True(CommandQueue.isEmpty queue)

    [<Fact>]
    let ``キューのすべてのコマンドを実行できる`` () =
        let queue = CommandQueue.empty<TextCommand>
        let queue = CommandQueue.enqueue (TextCommand.Insert(5, " World")) queue
        let queue = CommandQueue.enqueue (TextCommand.Insert(11, "!")) queue
        let editor = TextEditor.create "Hello"
        let editor = CommandQueue.executeAll editor queue
        Assert.Equal("Hello World!", CommandExecutor.getState editor)

// ============================================
// 7. Calculator テスト
// ============================================

module CalculatorTests =

    [<Fact>]
    let ``加算できる`` () =
        let calc = Calculator.create ()
        let calc = Calculator.execute (CalculatorCommand.Add 10.0m) calc
        Assert.Equal(10.0m, calc.Value)

    [<Fact>]
    let ``減算できる`` () =
        let calc = Calculator.create ()
        let calc = Calculator.execute (CalculatorCommand.Add 10.0m) calc
        let calc = Calculator.execute (CalculatorCommand.Subtract 3.0m) calc
        Assert.Equal(7.0m, calc.Value)

    [<Fact>]
    let ``乗算できる`` () =
        let calc = Calculator.create ()
        let calc = Calculator.execute (CalculatorCommand.Add 5.0m) calc
        let calc = Calculator.execute (CalculatorCommand.Multiply 3.0m) calc
        Assert.Equal(15.0m, calc.Value)

    [<Fact>]
    let ``除算できる`` () =
        let calc = Calculator.create ()
        let calc = Calculator.execute (CalculatorCommand.Add 12.0m) calc
        let calc = Calculator.execute (CalculatorCommand.Divide 4.0m) calc
        Assert.Equal(3.0m, calc.Value)

    [<Fact>]
    let ``計算をアンドゥできる`` () =
        let calc = Calculator.create ()
        let calc = Calculator.execute (CalculatorCommand.Add 10.0m) calc
        let calc = Calculator.execute (CalculatorCommand.Multiply 2.0m) calc
        Assert.Equal(20.0m, calc.Value)
        let calc = Calculator.undo calc
        Assert.Equal(10.0m, calc.Value)

    [<Fact>]
    let ``クリアできる`` () =
        let calc = Calculator.create ()
        let calc = Calculator.execute (CalculatorCommand.Add 10.0m) calc
        let calc = Calculator.execute (CalculatorCommand.Clear) calc
        Assert.Equal(0.0m, calc.Value)

// ============================================
// Chapter 12: Visitor パターン テスト
// ============================================

open FunctionalDesign.Part4.VisitorPattern

// ============================================
// 1. Shape テスト
// ============================================

module ShapeTests =

    [<Fact>]
    let ``円を移動できる`` () =
        let circle = Shape.Circle((10.0, 20.0), 5.0)
        let moved = Shape.translate 5.0 10.0 circle
        match moved with
        | Shape.Circle((x, y), r) ->
            Assert.Equal(15.0, x)
            Assert.Equal(30.0, y)
            Assert.Equal(5.0, r)
        | _ -> Assert.True(false, "Should be circle")

    [<Fact>]
    let ``円を拡大できる`` () =
        let circle = Shape.Circle((10.0, 20.0), 5.0)
        let scaled = Shape.scale 2.0 circle
        match scaled with
        | Shape.Circle(_, r) -> Assert.Equal(10.0, r)
        | _ -> Assert.True(false, "Should be circle")

    [<Fact>]
    let ``正方形を移動できる`` () =
        let square = Shape.Square((0.0, 0.0), 10.0)
        let moved = Shape.translate 5.0 5.0 square
        match moved with
        | Shape.Square((x, y), s) ->
            Assert.Equal(5.0, x)
            Assert.Equal(5.0, y)
            Assert.Equal(10.0, s)
        | _ -> Assert.True(false, "Should be square")

// ============================================
// 2. JsonVisitor テスト
// ============================================

module JsonVisitorTests =

    [<Fact>]
    let ``円をJSONに変換できる`` () =
        let circle = Shape.Circle((10.0, 20.0), 5.0)
        let json = JsonVisitor.toJson circle
        Assert.Contains("circle", json)
        Assert.Contains("center", json)
        Assert.Contains("radius", json)

    [<Fact>]
    let ``正方形をJSONに変換できる`` () =
        let square = Shape.Square((0.0, 0.0), 10.0)
        let json = JsonVisitor.toJson square
        Assert.Contains("square", json)
        Assert.Contains("side", json)

    [<Fact>]
    let ``長方形をJSONに変換できる`` () =
        let rect = Shape.Rectangle((0.0, 0.0), 20.0, 10.0)
        let json = JsonVisitor.toJson rect
        Assert.Contains("rectangle", json)
        Assert.Contains("width", json)
        Assert.Contains("height", json)

    [<Fact>]
    let ``複数の図形をJSON配列に変換できる`` () =
        let shapes = [
            Shape.Circle((0.0, 0.0), 5.0)
            Shape.Square((10.0, 10.0), 5.0)
        ]
        let json = JsonVisitor.shapesToJson shapes
        Assert.StartsWith("[", json)
        Assert.EndsWith("]", json)
        Assert.Contains("circle", json)
        Assert.Contains("square", json)

// ============================================
// 3. XmlVisitor テスト
// ============================================

module XmlVisitorTests =

    [<Fact>]
    let ``円をXMLに変換できる`` () =
        let circle = Shape.Circle((10.0, 20.0), 5.0)
        let xml = XmlVisitor.toXml circle
        Assert.Contains("<circle>", xml)
        Assert.Contains("<center", xml)
        Assert.Contains("<radius>", xml)

    [<Fact>]
    let ``正方形をXMLに変換できる`` () =
        let square = Shape.Square((0.0, 0.0), 10.0)
        let xml = XmlVisitor.toXml square
        Assert.Contains("<square>", xml)
        Assert.Contains("<side>", xml)

    [<Fact>]
    let ``複数の図形をXMLに変換できる`` () =
        let shapes = [
            Shape.Circle((0.0, 0.0), 5.0)
            Shape.Square((10.0, 10.0), 5.0)
        ]
        let xml = XmlVisitor.shapesToXml shapes
        Assert.Contains("<shapes>", xml)
        Assert.Contains("</shapes>", xml)

// ============================================
// 4. AreaVisitor テスト
// ============================================

module AreaVisitorTests =

    [<Fact>]
    let ``円の面積を計算できる`` () =
        let circle = Shape.Circle((0.0, 0.0), 5.0)
        let area = AreaVisitor.calculateArea circle
        Assert.Equal(System.Math.PI * 25.0, area, 5)

    [<Fact>]
    let ``正方形の面積を計算できる`` () =
        let square = Shape.Square((0.0, 0.0), 10.0)
        let area = AreaVisitor.calculateArea square
        Assert.Equal(100.0, area)

    [<Fact>]
    let ``長方形の面積を計算できる`` () =
        let rect = Shape.Rectangle((0.0, 0.0), 20.0, 10.0)
        let area = AreaVisitor.calculateArea rect
        Assert.Equal(200.0, area)

    [<Fact>]
    let ``合計面積を計算できる`` () =
        let shapes = [
            Shape.Square((0.0, 0.0), 10.0)  // 100
            Shape.Rectangle((0.0, 0.0), 20.0, 5.0)  // 100
        ]
        let total = AreaVisitor.totalArea shapes
        Assert.Equal(200.0, total)

// ============================================
// 5. PerimeterVisitor テスト
// ============================================

module PerimeterVisitorTests =

    [<Fact>]
    let ``円の周囲長を計算できる`` () =
        let circle = Shape.Circle((0.0, 0.0), 5.0)
        let perimeter = PerimeterVisitor.calculatePerimeter circle
        Assert.Equal(2.0 * System.Math.PI * 5.0, perimeter, 5)

    [<Fact>]
    let ``正方形の周囲長を計算できる`` () =
        let square = Shape.Square((0.0, 0.0), 10.0)
        let perimeter = PerimeterVisitor.calculatePerimeter square
        Assert.Equal(40.0, perimeter)

    [<Fact>]
    let ``長方形の周囲長を計算できる`` () =
        let rect = Shape.Rectangle((0.0, 0.0), 20.0, 10.0)
        let perimeter = PerimeterVisitor.calculatePerimeter rect
        Assert.Equal(60.0, perimeter)

// ============================================
// 6. BoundingBoxVisitor テスト
// ============================================

module BoundingBoxVisitorTests =

    [<Fact>]
    let ``円のバウンディングボックスを計算できる`` () =
        let circle = Shape.Circle((10.0, 10.0), 5.0)
        let box = BoundingBoxVisitor.calculateBoundingBox circle
        Assert.Equal(5.0, box.MinX)
        Assert.Equal(5.0, box.MinY)
        Assert.Equal(15.0, box.MaxX)
        Assert.Equal(15.0, box.MaxY)

    [<Fact>]
    let ``正方形のバウンディングボックスを計算できる`` () =
        let square = Shape.Square((5.0, 5.0), 10.0)
        let box = BoundingBoxVisitor.calculateBoundingBox square
        Assert.Equal(5.0, box.MinX)
        Assert.Equal(5.0, box.MinY)
        Assert.Equal(15.0, box.MaxX)
        Assert.Equal(15.0, box.MaxY)

    [<Fact>]
    let ``複数の図形の統合バウンディングボックスを計算できる`` () =
        let shapes = [
            Shape.Circle((0.0, 0.0), 5.0)
            Shape.Square((10.0, 10.0), 10.0)
        ]
        let box = BoundingBoxVisitor.combinedBoundingBox shapes
        Assert.True(box.IsSome)
        let b = box.Value
        Assert.Equal(-5.0, b.MinX)
        Assert.Equal(-5.0, b.MinY)
        Assert.Equal(20.0, b.MaxX)
        Assert.Equal(20.0, b.MaxY)

// ============================================
// 7. ExprVisitor テスト
// ============================================

module ExprVisitorTests =

    [<Fact>]
    let ``式を評価できる`` () =
        let expr = Expr.Add(Expr.Num 3.0, Expr.Mul(Expr.Num 2.0, Expr.Num 4.0))
        let result = ExprVisitor.evaluate Map.empty expr
        Assert.Equal(11.0, result)

    [<Fact>]
    let ``変数を含む式を評価できる`` () =
        let expr = Expr.Add(Expr.Var "x", Expr.Num 5.0)
        let env = Map.ofList [ ("x", 10.0) ]
        let result = ExprVisitor.evaluate env expr
        Assert.Equal(15.0, result)

    [<Fact>]
    let ``式を文字列に変換できる`` () =
        let expr = Expr.Add(Expr.Num 3.0, Expr.Num 4.0)
        let str = ExprVisitor.toString expr
        Assert.Contains("3", str)
        Assert.Contains("+", str)
        Assert.Contains("4", str)

    [<Fact>]
    let ``式を簡約できる`` () =
        let expr = Expr.Add(Expr.Num 0.0, Expr.Var "x")
        let simplified = ExprVisitor.simplify expr
        match simplified with
        | Expr.Var name -> Assert.Equal("x", name)
        | _ -> Assert.True(false, "Should be simplified to Var")

    [<Fact>]
    let ``式の変数を抽出できる`` () =
        let expr = Expr.Add(Expr.Var "x", Expr.Mul(Expr.Var "y", Expr.Var "x"))
        let vars = ExprVisitor.variables expr
        Assert.Equal(2, Set.count vars)
        Assert.True(Set.contains "x" vars)
        Assert.True(Set.contains "y" vars)

// ============================================
// 8. TreeVisitor テスト
// ============================================

module TreeVisitorTests =

    [<Fact>]
    let ``葉の値を収集できる`` () =
        let tree = Node [ Leaf 1; Node [ Leaf 2; Leaf 3 ]; Leaf 4 ]
        let leaves = TreeVisitor.collectLeaves tree
        Assert.Equal<int list>([ 1; 2; 3; 4 ], leaves)

    [<Fact>]
    let ``ツリーの深さを計算できる`` () =
        let tree = Node [ Leaf 1; Node [ Leaf 2; Node [ Leaf 3 ] ] ]
        let d = TreeVisitor.depth tree
        Assert.Equal(4, d)

    [<Fact>]
    let ``ツリーのノード数を計算できる`` () =
        let tree = Node [ Leaf 1; Leaf 2; Node [ Leaf 3 ] ]
        let count = TreeVisitor.countNodes tree
        Assert.Equal(5, count)

    [<Fact>]
    let ``ツリーを変換できる`` () =
        let tree = Node [ Leaf 1; Leaf 2 ]
        let mapped = TreeVisitor.map (fun x -> x * 2) tree
        let leaves = TreeVisitor.collectLeaves mapped
        Assert.Equal<int list>([ 2; 4 ], leaves)

    [<Fact>]
    let ``ツリーをフォールドできる`` () =
        let tree = Node [ Leaf 1; Leaf 2; Node [ Leaf 3; Leaf 4 ] ]
        let sum = TreeVisitor.fold id List.sum tree
        Assert.Equal(10, sum)

// ============================================
// Chapter 13: Abstract Factory パターン テスト
// ============================================

open FunctionalDesign.Part4.AbstractFactoryPattern

// ============================================
// 1. ShapeFactory テスト
// ============================================

module ShapeFactoryTests =

    [<Fact>]
    let ``StandardFactoryで円を作成できる`` () =
        let factory = ShapeFactory.Standard
        let shape = ShapeFactory.createCircle factory (10.0, 20.0) 5.0
        match shape.Shape with
        | FunctionalDesign.Part4.VisitorPattern.Shape.Circle((x, y), r) ->
            Assert.Equal(10.0, x)
            Assert.Equal(20.0, y)
            Assert.Equal(5.0, r)
        | _ -> Assert.True(false, "Should be circle")
        Assert.True(shape.Style.OutlineColor.IsNone)
        Assert.True(shape.Style.FillColor.IsNone)

    [<Fact>]
    let ``OutlinedFactoryで輪郭線付き図形を作成できる`` () =
        let factory = ShapeFactory.Outlined("black", 2.0)
        let shape = ShapeFactory.createSquare factory (0.0, 0.0) 10.0
        Assert.Equal(Some "black", shape.Style.OutlineColor)
        Assert.Equal(Some 2.0, shape.Style.OutlineWidth)

    [<Fact>]
    let ``FilledFactoryで塗りつぶし図形を作成できる`` () =
        let factory = ShapeFactory.Filled "red"
        let shape = ShapeFactory.createRectangle factory (0.0, 0.0) 20.0 10.0
        Assert.Equal(Some "red", shape.Style.FillColor)

    [<Fact>]
    let ``CustomFactoryでカスタムスタイルを適用できる`` () =
        let customStyle =
            ShapeStyle.empty
            |> ShapeStyle.withOutline "blue" 3.0
            |> ShapeStyle.withFill "yellow"
            |> ShapeStyle.withOpacity 0.8
        let factory = ShapeFactory.Custom customStyle
        let shape = ShapeFactory.createCircle factory (0.0, 0.0) 10.0
        Assert.Equal(Some "blue", shape.Style.OutlineColor)
        Assert.Equal(Some "yellow", shape.Style.FillColor)
        Assert.Equal(Some 0.8, shape.Style.Opacity)

// ============================================
// 2. UIFactory テスト
// ============================================

module UIFactoryTests =

    [<Fact>]
    let ``Windowsファクトリでボタンを作成できる`` () =
        let factory = UIFactory.Windows
        let button = UIFactory.createButton factory "OK"
        Assert.Equal("OK", button.Label)
        Assert.Equal("windows", button.Platform)
        Assert.True(button.Style.ContainsKey "border")

    [<Fact>]
    let ``MacOSファクトリでボタンを作成できる`` () =
        let factory = UIFactory.MacOS
        let button = UIFactory.createButton factory "Submit"
        Assert.Equal("Submit", button.Label)
        Assert.Equal("macos", button.Platform)
        Assert.True(button.Style.ContainsKey "borderRadius")

    [<Fact>]
    let ``Webファクトリでテキストフィールドを作成できる`` () =
        let factory = UIFactory.Web
        let field = UIFactory.createTextField factory "Enter name"
        Assert.Equal("Enter name", field.Placeholder)
        Assert.Equal("web", field.Platform)

    [<Fact>]
    let ``Linuxファクトリでチェックボックスを作成できる`` () =
        let factory = UIFactory.Linux
        let checkbox = UIFactory.createCheckbox factory "Accept" true
        Assert.Equal("Accept", checkbox.Label)
        Assert.True(checkbox.Checked)
        Assert.Equal("linux", checkbox.Platform)

// ============================================
// 3. DatabaseFactory テスト
// ============================================

module DatabaseFactoryTests =

    [<Fact>]
    let ``SqlServerファクトリで接続を作成できる`` () =
        let factory = DatabaseFactory.SqlServer "Server=localhost;Database=test"
        let conn = DatabaseFactory.createConnection factory
        Assert.Equal("SqlServer", conn.DatabaseType)
        Assert.Equal(100, conn.MaxPoolSize)

    [<Fact>]
    let ``PostgreSQLファクトリで接続を作成できる`` () =
        let factory = DatabaseFactory.PostgreSQL "Host=localhost;Database=test"
        let conn = DatabaseFactory.createConnection factory
        Assert.Equal("PostgreSQL", conn.DatabaseType)
        Assert.Equal(50, conn.MaxPoolSize)

    [<Fact>]
    let ``SQLiteファクトリで接続を作成できる`` () =
        let factory = DatabaseFactory.SQLite "/path/to/db.sqlite"
        let conn = DatabaseFactory.createConnection factory
        Assert.Equal("SQLite", conn.DatabaseType)
        Assert.Equal(1, conn.MaxPoolSize)
        Assert.Contains("Data Source=", conn.ConnectionString)

    [<Fact>]
    let ``コマンドを作成できる`` () =
        let factory = DatabaseFactory.PostgreSQL "Host=localhost"
        let cmd = DatabaseFactory.createCommand factory "SELECT * FROM users" Map.empty
        Assert.Equal("SELECT * FROM users", cmd.Query)
        Assert.Equal("PostgreSQL", cmd.DatabaseType)

// ============================================
// 4. DocumentFactory テスト
// ============================================

module DocumentFactoryTests =

    [<Fact>]
    let ``HTMLファクトリで段落を作成できる`` () =
        let factory = DocumentFactory.HTML
        let result = DocumentFactory.createParagraph factory "Hello World"
        Assert.Equal("<p>Hello World</p>", result)

    [<Fact>]
    let ``Markdownファクトリで見出しを作成できる`` () =
        let factory = DocumentFactory.Markdown
        let result = DocumentFactory.createHeading factory 2 "Title"
        Assert.StartsWith("## ", result)

    [<Fact>]
    let ``PlainTextファクトリで見出しを作成できる`` () =
        let factory = DocumentFactory.PlainText
        let result = DocumentFactory.createHeading factory 1 "Title"
        Assert.Contains("TITLE", result)
        Assert.Contains("=", result)

    [<Fact>]
    let ``HTMLファクトリで順序付きリストを作成できる`` () =
        let factory = DocumentFactory.HTML
        let result = DocumentFactory.createList factory [ "One"; "Two" ] true
        Assert.Contains("<ol>", result)
        Assert.Contains("<li>One</li>", result)

    [<Fact>]
    let ``Markdownファクトリで順序なしリストを作成できる`` () =
        let factory = DocumentFactory.Markdown
        let result = DocumentFactory.createList factory [ "Apple"; "Banana" ] false
        Assert.Contains("- Apple", result)
        Assert.Contains("- Banana", result)

// ============================================
// 5. ThemeFactory テスト
// ============================================

module ThemeFactoryTests =

    [<Fact>]
    let ``Lightテーマを作成できる`` () =
        let factory = ThemeFactory.Light
        let theme = ThemeFactory.createTheme factory
        Assert.Equal("Light", theme.Name)
        Assert.Equal("#ffffff", theme.Colors.Background)
        Assert.Equal("#212529", theme.Colors.Text)

    [<Fact>]
    let ``Darkテーマを作成できる`` () =
        let factory = ThemeFactory.Dark
        let theme = ThemeFactory.createTheme factory
        Assert.Equal("Dark", theme.Name)
        Assert.Equal("#212529", theme.Colors.Background)
        Assert.Equal("#f8f9fa", theme.Colors.Text)

    [<Fact>]
    let ``HighContrastテーマを作成できる`` () =
        let factory = ThemeFactory.HighContrast
        let theme = ThemeFactory.createTheme factory
        Assert.Equal("HighContrast", theme.Name)
        Assert.Equal("#000000", theme.Colors.Background)
        Assert.Equal("#ffffff", theme.Colors.Text)
