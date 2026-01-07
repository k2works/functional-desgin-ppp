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
