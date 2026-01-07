module Tests

open System
open Xunit
open FunctionalDesign.Immutability
open FunctionalDesign.Composition
open FunctionalDesign.Polymorphism

// ============================================
// 第1章: 不変データ構造の基本
// ============================================

module PersonTests =

    [<Fact>]
    let ``Person レコードは不変`` () =
        let original = { Name = "田中"; Age = 30 }
        let updated = updateAge original 31
        Assert.Equal(30, original.Age) // 元は変わらない
        Assert.Equal(31, updated.Age)

    [<Fact>]
    let ``年齢を更新すると新しいレコードが返る`` () =
        let person = { Name = "鈴木"; Age = 25 }
        let updated = updateAge person 26
        Assert.NotSame(box person, box updated)

    [<Fact>]
    let ``名前を更新`` () =
        let person = { Name = "佐藤"; Age = 40 }
        let updated = updateName person "高橋"
        Assert.Equal("佐藤", person.Name)
        Assert.Equal("高橋", updated.Name)

// ============================================
// 2. 構造共有
// ============================================

module TeamTests =

    [<Fact>]
    let ``チームにメンバーを追加`` () =
        let team =
            { Name = "開発チーム"
              Members =
                [ { Name = "田中"; Role = "developer" }
                  { Name = "鈴木"; Role = "designer" } ] }

        let newTeam = addMember team { Name = "山田"; Role = "tester" }
        Assert.Equal(2, team.Members.Length) // 元は変わらない
        Assert.Equal(3, newTeam.Members.Length)

    [<Fact>]
    let ``チームからメンバーを削除`` () =
        let team =
            { Name = "チームA"
              Members =
                [ { Name = "A"; Role = "dev" }
                  { Name = "B"; Role = "qa" } ] }

        let newTeam = removeMember team "A"
        Assert.Equal(2, team.Members.Length)
        Assert.Equal(1, newTeam.Members.Length)
        Assert.Equal("B", newTeam.Members.[0].Name)

    [<Fact>]
    let ``チーム名は共有される`` () =
        let team = { Name = "チーム"; Members = [] }
        let newTeam = addMember team { Name = "新人"; Role = "intern" }
        Assert.Equal(team.Name, newTeam.Name)

// ============================================
// 3. データ変換パイプライン
// ============================================

module OrderTests =

    let sampleOrder =
        { Items =
            [ { Name = "商品A"; Price = 1000; Quantity = 2 }
              { Name = "商品B"; Price = 500; Quantity = 3 }
              { Name = "商品C"; Price = 2000; Quantity = 1 } ]
          Customer = { Name = "山田"; Membership = Gold } }

    [<Fact>]
    let ``小計を計算`` () =
        let item = { Name = "テスト"; Price = 100; Quantity = 3 }
        Assert.Equal(300, calculateSubtotal item)

    [<Fact>]
    let ``Gold 会員の割引率`` () =
        Assert.Equal(0.1, membershipDiscount Gold)

    [<Fact>]
    let ``Silver 会員の割引率`` () =
        Assert.Equal(0.05, membershipDiscount Silver)

    [<Fact>]
    let ``Bronze 会員の割引率`` () =
        Assert.Equal(0.02, membershipDiscount Bronze)

    [<Fact>]
    let ``Standard 会員の割引率`` () =
        Assert.Equal(0.0, membershipDiscount Standard)

    [<Fact>]
    let ``注文の合計を計算`` () =
        // 1000*2 + 500*3 + 2000*1 = 2000 + 1500 + 2000 = 5500
        Assert.Equal(5500, calculateTotal sampleOrder)

    [<Fact>]
    let ``Gold 会員の割引を適用`` () =
        let total = calculateTotal sampleOrder
        let discounted = applyDiscount sampleOrder total
        // 5500 * 0.9 = 4950
        Assert.Equal(4950.0, discounted)

    [<Fact>]
    let ``注文処理パイプライン`` () =
        let result = processOrder sampleOrder
        Assert.Equal(4950.0, result)

    [<Fact>]
    let ``Standard 会員は割引なし`` () =
        let order =
            { sampleOrder with
                Customer = { Name = "一般"; Membership = Standard } }

        let result = processOrder order
        Assert.Equal(5500.0, result)

// ============================================
// 4. 副作用の分離
// ============================================

module InvoiceTests =

    [<Fact>]
    let ``税金を計算`` () =
        Assert.Equal(100.0, calculateTax 1000 0.1)

    [<Fact>]
    let ``請求書を作成`` () =
        let items =
            [ { Name = "A"; Price = 1000; Quantity = 1 }
              { Name = "B"; Price = 500; Quantity = 2 } ]

        let invoice = calculateInvoice items 0.1
        Assert.Equal(2000, invoice.Subtotal) // 1000 + 1000
        Assert.Equal(200.0, invoice.Tax) // 2000 * 0.1
        Assert.Equal(2200.0, invoice.Total) // 2000 + 200

    [<Fact>]
    let ``請求書は純粋関数`` () =
        let items = [ { Name = "X"; Price = 100; Quantity = 1 } ]
        let invoice1 = calculateInvoice items 0.08
        let invoice2 = calculateInvoice items 0.08
        Assert.Equal(invoice1.Total, invoice2.Total)

// ============================================
// 5. 履歴管理（Undo/Redo）
// ============================================

module HistoryTests =

    [<Fact>]
    let ``空の履歴を作成`` () =
        let history: History<string> = createHistory ()
        Assert.True(history.Current.IsNone)
        Assert.Empty(history.Past)
        Assert.Empty(history.Future)

    [<Fact>]
    let ``状態をプッシュ`` () =
        let history: History<string> = createHistory () |> pushState "Hello"
        Assert.Equal<string option>(Some "Hello", currentState history)

    [<Fact>]
    let ``複数の状態をプッシュ`` () =
        let history: History<string> =
            createHistory ()
            |> pushState "A"
            |> pushState "B"
            |> pushState "C"

        Assert.Equal<string option>(Some "C", currentState history)
        Assert.Equal(2, history.Past.Length)

    [<Fact>]
    let ``Undo で前の状態に戻る`` () =
        let history: History<string> =
            createHistory ()
            |> pushState "A"
            |> pushState "B"
            |> pushState "C"
            |> undo

        Assert.Equal<string option>(Some "B", currentState history)

    [<Fact>]
    let ``複数回 Undo`` () =
        let history: History<string> =
            createHistory ()
            |> pushState "A"
            |> pushState "B"
            |> pushState "C"
            |> undo
            |> undo

        Assert.Equal<string option>(Some "A", currentState history)

    [<Fact>]
    let ``空の履歴で Undo しても変化なし`` () =
        let history: History<string> = createHistory () |> undo
        Assert.True(history.Current.IsNone)

    [<Fact>]
    let ``Redo で Undo を取り消す`` () =
        let history: History<string> =
            createHistory ()
            |> pushState "A"
            |> pushState "B"
            |> undo
            |> redo

        Assert.Equal<string option>(Some "B", currentState history)

    [<Fact>]
    let ``新しい状態をプッシュすると Future がクリア`` () =
        let history: History<string> =
            createHistory ()
            |> pushState "A"
            |> pushState "B"
            |> undo
            |> pushState "C"

        Assert.Equal<string option>(Some "C", currentState history)
        Assert.Empty(history.Future)

    [<Fact>]
    let ``Future が空のとき Redo しても変化なし`` () =
        let history: History<string> = createHistory () |> pushState "A" |> redo
        Assert.Equal<string option>(Some "A", currentState history)

// ============================================
// 6. 効率的な変換
// ============================================

module EfficientTransformTests =

    [<Fact>]
    let ``数量0のアイテムを除外`` () =
        let items =
            [ { Name = "A"; Price = 100; Quantity = 0 }
              { Name = "B"; Price = 200; Quantity = 1 } ]

        let result = processItemsEfficiently items
        Assert.Single(result) |> ignore

    [<Fact>]
    let ``小計100以下を除外`` () =
        let items =
            [ { Name = "A"; Price = 50; Quantity = 1 } // 50
              { Name = "B"; Price = 50; Quantity = 3 } // 150
              { Name = "C"; Price = 200; Quantity = 1 } ] // 200

        let result = processItemsEfficiently items
        Assert.Equal(2, result.Length)

// ============================================
// 7. 不変リストの操作
// ============================================

module ListOperationTests =

    [<Fact>]
    let ``先頭に追加`` () =
        let list = [ 2; 3; 4 ]
        let result = prepend 1 list
        Assert.Equal<int list>([ 1; 2; 3; 4 ], result)
        Assert.Equal<int list>([ 2; 3; 4 ], list) // 元は変わらない

    [<Fact>]
    let ``末尾に追加`` () =
        let list = [ 1; 2; 3 ]
        let result = append 4 list
        Assert.Equal<int list>([ 1; 2; 3; 4 ], result)

    [<Fact>]
    let ``リストを結合`` () =
        let result = concat [ 1; 2 ] [ 3; 4 ]
        Assert.Equal<int list>([ 1; 2; 3; 4 ], result)

    [<Fact>]
    let ``フィルタリング`` () =
        let result = filterBy (fun x -> x > 2) [ 1; 2; 3; 4 ]
        Assert.Equal<int list>([ 3; 4 ], result)

    [<Fact>]
    let ``マッピング`` () =
        let result = mapWith (fun x -> x * 2) [ 1; 2; 3 ]
        Assert.Equal<int list>([ 2; 4; 6 ], result)

    [<Fact>]
    let ``畳み込み`` () =
        let result = foldWith (+) 0 [ 1; 2; 3; 4 ]
        Assert.Equal(10, result)

// ============================================
// 8. 不変Mapの操作
// ============================================

module MapOperationTests =

    [<Fact>]
    let ``エントリを追加`` () =
        let map = Map.empty |> addEntry "a" 1
        Assert.Equal<int option>(Some 1, tryGetValue "a" map)

    [<Fact>]
    let ``エントリを削除`` () =
        let map = Map.empty |> addEntry "a" 1 |> removeEntry "a"
        Assert.Equal<int option>(None, tryGetValue "a" map)

    [<Fact>]
    let ``キーの存在確認`` () =
        let map = Map.empty |> addEntry "key" "value"
        Assert.True(containsKey "key" map)
        Assert.False(containsKey "other" map)

    [<Fact>]
    let ``値を更新`` () =
        let map = Map.empty |> addEntry "count" 1
        let updated = updateValue "count" (fun v -> v + 1) map
        Assert.Equal<int option>(Some 2, tryGetValue "count" updated)

    [<Fact>]
    let ``存在しないキーの更新は変化なし`` () =
        let map = Map.empty |> addEntry "a" 1
        let result = updateValue "b" (fun v -> v + 1) map
        Assert.Equal<int option>(None, tryGetValue "b" result)

    [<Fact>]
    let ``元のMapは変更されない`` () =
        let original = Map.empty |> addEntry "x" 10
        let modified = addEntry "y" 20 original
        Assert.False(containsKey "y" original)
        Assert.True(containsKey "y" modified)


// ============================================
// 第2章: 関数合成と高階関数
// ============================================

// ============================================
// 1. 関数合成の基本
// ============================================

module CompositionBasicsTests =

    [<Fact>]
    let ``addTax は税金を追加する`` () =
        let result = addTax 0.1 1000.0
        Assert.Equal(1100.0, result)

    [<Fact>]
    let ``applyDiscountRate は割引を適用する`` () =
        let result = applyDiscountRate 0.2 1000.0
        Assert.Equal(800.0, result)

    [<Fact>]
    let ``roundToYen は円単位に丸める`` () =
        Assert.Equal(880L, roundToYen 880.4)
        Assert.Equal(881L, roundToYen 880.6)
        Assert.Equal(880L, roundToYen 880.5) // 銀行家の丸め（偶数への丸め）

    [<Fact>]
    let ``関数合成（左から右）で最終価格を計算`` () =
        // 1000 → 20%割引(800) → 10%税込(880) → 丸め(880)
        let result = calculateFinalPrice 1000.0
        Assert.Equal(880L, result)

    [<Fact>]
    let ``関数合成（右から左）で同じ結果を得る`` () =
        let result = calculateFinalPriceCompose 1000.0
        Assert.Equal(880L, result)

    [<Fact>]
    let ``パイプライン演算子で関数を適用`` () =
        let result =
            1000.0
            |> applyDiscountRate 0.2
            |> addTax 0.1
            |> roundToYen

        Assert.Equal(880L, result)

// ============================================
// 2. カリー化と部分適用
// ============================================

module CurryingTests =

    [<Fact>]
    let ``greet は挨拶メッセージを作成`` () =
        let result = greet "Hello" "田中"
        Assert.Equal("Hello, 田中!", result)

    [<Fact>]
    let ``部分適用で sayHello を作成`` () =
        let result = sayHello "田中"
        Assert.Equal("Hello, 田中!", result)

    [<Fact>]
    let ``部分適用で sayGoodbye を作成`` () =
        let result = sayGoodbye "鈴木"
        Assert.Equal("Goodbye, 鈴木!", result)

    [<Fact>]
    let ``sendEmail でメールを作成`` () =
        let email = sendEmail "from@test.com" "to@test.com" "件名" "本文"

        Assert.Equal("from@test.com", email.From)
        Assert.Equal("to@test.com", email.To)
        Assert.Equal("件名", email.Subject)
        Assert.Equal("本文", email.Body)

    [<Fact>]
    let ``部分適用でシステムメールを作成`` () =
        let email = sendFromSystem "user@test.com" "通知" "本文"
        Assert.Equal("system@example.com", email.From)
        Assert.Equal("user@test.com", email.To)

    [<Fact>]
    let ``部分適用で通知メールを作成`` () =
        let email = sendNotification "メッセージ本文"
        Assert.Equal("system@example.com", email.From)
        Assert.Equal("user@example.com", email.To)
        Assert.Equal("通知", email.Subject)
        Assert.Equal("メッセージ本文", email.Body)

// ============================================
// 3. 複数の関数を並列適用
// ============================================

module JuxtTests =

    [<Fact>]
    let ``getStats で統計情報を取得`` () =
        let numbers = [ 3; 1; 4; 1; 5; 9; 2; 6 ]
        let (first, last, count, min, max) = getStats numbers
        Assert.Equal(3, first)
        Assert.Equal(6, last)
        Assert.Equal(8, count)
        Assert.Equal(1, min)
        Assert.Equal(9, max)

    [<Fact>]
    let ``juxt2 で2つの関数を適用`` () =
        let result = juxt2 (fun x -> x * 2) (fun x -> x + 10) 5
        Assert.Equal((10, 15), result)

    [<Fact>]
    let ``juxt3 で3つの関数を適用`` () =
        let result = juxt3 List.head List.last List.length [ 1; 2; 3 ]
        Assert.Equal((1, 3, 3), result)

    [<Fact>]
    let ``analyzePerson で成人を分析`` () =
        let person = Map.ofList [ "name", box "田中"; "age", box 25 ]
        let result = analyzePerson person

        Assert.Equal("田中", result.Name)
        Assert.Equal(25, result.Age)
        Assert.Equal("adult", result.Category)

    [<Fact>]
    let ``analyzePerson で未成年を分析`` () =
        let person = Map.ofList [ "name", box "鈴木"; "age", box 15 ]
        let result = analyzePerson person

        Assert.Equal("鈴木", result.Name)
        Assert.Equal(15, result.Age)
        Assert.Equal("minor", result.Category)

// ============================================
// 4. 高階関数によるデータ処理
// ============================================

module HigherOrderFunctionsTests =

    [<Fact>]
    let ``processWithLog で処理を記録`` () =
        let log = processWithLog (fun x -> x * 2) 5
        Assert.Equal(5, log.Input)
        Assert.Equal(10, log.Output)

    [<Fact>]
    let ``memoize でキャッシュされる`` () =
        let mutable callCount = 0

        let expensiveFunction x =
            callCount <- callCount + 1
            x * 2

        let memoized = memoize expensiveFunction
        let _ = memoized 5
        let _ = memoized 5
        let _ = memoized 5
        Assert.Equal(1, callCount) // 1回だけ呼ばれる

    [<Fact>]
    let ``memoize は異なる引数で再計算`` () =
        let mutable callCount = 0

        let fn x =
            callCount <- callCount + 1
            x * 2

        let memoized = memoize fn
        let _ = memoized 1
        let _ = memoized 2
        let _ = memoized 3
        Assert.Equal(3, callCount)

    [<Fact>]
    let ``retry は成功するまでリトライ`` () =
        let mutable attempts = 0

        let unreliableFunction _ =
            attempts <- attempts + 1

            if attempts < 3 then
                failwith "エラー"
            else
                "成功"

        let result = retry 5 unreliableFunction ()
        Assert.Equal("成功", result)
        Assert.Equal(3, attempts)

    [<Fact>]
    let ``retry は最大リトライ回数を超えると例外`` () =
        let fn _ = failwith "常に失敗"
        Assert.Throws<Exception>(fun () -> retry 3 fn () |> ignore)

// ============================================
// 5. パイプライン処理
// ============================================

module PipelineTests =

    [<Fact>]
    let ``pipeline で関数を順次適用`` () =
        let add1 x = x + 1
        let double x = x * 2
        let square x = x * x
        let result = pipeline [ add1; double; square ] 3
        // 3 → 4 → 8 → 64
        Assert.Equal(64, result)

    [<Fact>]
    let ``validateOrder は空の注文で例外`` () =
        let order =
            { Items = []
              Customer = { Membership = "gold" }
              Total = 0.0
              Shipping = 0 }

        Assert.Throws<Exception>(fun () -> validateOrder order |> ignore)

    [<Fact>]
    let ``calculateOrderTotal で合計を計算`` () =
        let order =
            { Items =
                [ { Price = 1000; Quantity = 2 }
                  { Price = 500; Quantity = 3 } ]
              Customer = { Membership = "standard" }
              Total = 0.0
              Shipping = 0 }

        let result = calculateOrderTotal order
        // 1000*2 + 500*3 = 2000 + 1500 = 3500
        Assert.Equal(3500.0, result.Total)

    [<Fact>]
    let ``applyOrderDiscount で Gold 割引を適用`` () =
        let order =
            { Items = []
              Customer = { Membership = "gold" }
              Total = 1000.0
              Shipping = 0 }

        let result = applyOrderDiscount order
        Assert.Equal(900.0, result.Total) // 10%割引

    [<Fact>]
    let ``addShipping で送料を追加（5000円未満）`` () =
        let order =
            { Items = []
              Customer = { Membership = "standard" }
              Total = 3000.0
              Shipping = 0 }

        let result = addShipping order
        Assert.Equal(500, result.Shipping)
        Assert.Equal(3500.0, result.Total)

    [<Fact>]
    let ``addShipping で送料無料（5000円以上）`` () =
        let order =
            { Items = []
              Customer = { Membership = "standard" }
              Total = 5000.0
              Shipping = 0 }

        let result = addShipping order
        Assert.Equal(0, result.Shipping)
        Assert.Equal(5000.0, result.Total)

    [<Fact>]
    let ``processOrderPipeline で注文を処理`` () =
        let order =
            { Items =
                [ { Price = 1000; Quantity = 2 }
                  { Price = 500; Quantity = 3 } ]
              Customer = { Membership = "gold" }
              Total = 0.0
              Shipping = 0 }

        let result = processOrderPipeline order
        // 3500 * 0.9 = 3150 + 500 = 3650
        Assert.Equal(3650.0, result.Total)
        Assert.Equal(500, result.Shipping)

// ============================================
// 6. バリデーション
// ============================================

module ValidationTests =

    [<Fact>]
    let ``validator で有効な値を検証`` () =
        let result = validator (fun x -> x > 0) "正の数が必要" 10
        Assert.True(result.Valid)
        Assert.Equal(10, result.Value)
        Assert.True(result.Error.IsNone)

    [<Fact>]
    let ``validator で無効な値を検証`` () =
        let result = validator (fun x -> x > 0) "正の数が必要" -1
        Assert.False(result.Valid)
        Assert.Equal(-1, result.Value)
        Assert.Equal(Some "正の数が必要", result.Error)

    [<Fact>]
    let ``validateQuantity で有効な数量`` () =
        let result = validateQuantity 50
        Assert.True(result.Valid)
        Assert.Equal(50, result.Value)

    [<Fact>]
    let ``validateQuantity で負の数は無効`` () =
        let result = validateQuantity -1
        Assert.False(result.Valid)
        Assert.Equal(Some "値は正の数である必要があります", result.Error)

    [<Fact>]
    let ``validateQuantity で100以上は無効`` () =
        let result = validateQuantity 100
        Assert.False(result.Valid)
        Assert.Equal(Some "値は100未満である必要があります", result.Error)

    [<Fact>]
    let ``combineValidators で複数のバリデータを適用`` () =
        let isEven = validator (fun x -> x % 2 = 0) "偶数が必要"
        let isPositive = validator (fun x -> x > 0) "正の数が必要"
        let combined = combineValidators [ isPositive; isEven ]

        Assert.True((combined 4).Valid)
        Assert.False((combined 3).Valid) // 奇数
        Assert.False((combined -2).Valid) // 負

// ============================================
// 7. 関数の変換
// ============================================

module FunctionTransformTests =

    [<Fact>]
    let ``flip で引数の順序を反転`` () =
        let subtract a b = a - b
        let flipped = flip subtract
        Assert.Equal(2, flipped 3 5) // 5 - 3

    [<Fact>]
    let ``curry でタプル関数をカリー化`` () =
        let addTuple (a, b) = a + b
        let curried = curry addTuple
        Assert.Equal(8, curried 3 5)

    [<Fact>]
    let ``uncurry でカリー化された関数を戻す`` () =
        let addCurried a b = a + b
        let uncurried = uncurry addCurried
        Assert.Equal(8, uncurried (3, 5))

    [<Fact>]
    let ``complement で述語を反転`` () =
        let isEven x = x % 2 = 0
        let isOdd = complement isEven
        Assert.True(isOdd 3)
        Assert.False(isOdd 4)

// ============================================
// 8. 述語合成
// ============================================

module PredicateCompositionTests =

    [<Fact>]
    let ``composePredicates で AND 合成`` () =
        let isPositive x = x > 0
        let isEven x = x % 2 = 0
        let isPositiveEven = composePredicates [ isPositive; isEven ]

        Assert.True(isPositiveEven 4)
        Assert.False(isPositiveEven 3) // 奇数
        Assert.False(isPositiveEven -2) // 負

    [<Fact>]
    let ``composePredicatesOr で OR 合成`` () =
        let isZero x = x = 0
        let isPositive x = x > 0
        let isNonNegative = composePredicatesOr [ isZero; isPositive ]

        Assert.True(isNonNegative 0)
        Assert.True(isNonNegative 5)
        Assert.False(isNonNegative -1)

    [<Fact>]
    let ``validAge で有効な年齢をチェック`` () =
        Assert.True(validAge 25)
        Assert.True(validAge 1)
        Assert.True(validAge 150)
        Assert.False(validAge 0)
        Assert.False(validAge -1)
        Assert.False(validAge 200)

    [<Fact>]
    let ``premiumCustomer で Gold 会員を判定`` () =
        let customer =
            { Membership = "gold"
              PurchaseCount = 0
              TotalSpent = 0 }

        Assert.True(premiumCustomer customer)

    [<Fact>]
    let ``premiumCustomer で購入回数100以上を判定`` () =
        let customer =
            { Membership = "bronze"
              PurchaseCount = 100
              TotalSpent = 0 }

        Assert.True(premiumCustomer customer)

    [<Fact>]
    let ``premiumCustomer で累計10万以上を判定`` () =
        let customer =
            { Membership = "bronze"
              PurchaseCount = 10
              TotalSpent = 100000 }

        Assert.True(premiumCustomer customer)

    [<Fact>]
    let ``premiumCustomer で非プレミアムを判定`` () =
        let customer =
            { Membership = "bronze"
              PurchaseCount = 10
              TotalSpent = 1000 }

        Assert.False(premiumCustomer customer)


// ============================================
// 第3章: 多態性とディスパッチ
// ============================================

// ============================================
// 1. 判別共用体による多態性
// ============================================

module ShapeTests =

    [<Fact>]
    let ``Rectangle の面積を計算`` () =
        let shape = Rectangle(4.0, 5.0)
        Assert.Equal(20.0, calculateArea shape)

    [<Fact>]
    let ``Circle の面積を計算`` () =
        let shape = Circle(3.0)
        let expected = System.Math.PI * 9.0
        Assert.Equal(expected, calculateArea shape, 5)

    [<Fact>]
    let ``Triangle の面積を計算`` () =
        let shape = Triangle(6.0, 5.0)
        Assert.Equal(15.0, calculateArea shape)

    [<Fact>]
    let ``Rectangle の周囲長を計算`` () =
        let shape = Rectangle(4.0, 5.0)
        Assert.Equal(18.0, calculatePerimeter shape)

    [<Fact>]
    let ``Circle の周囲長を計算`` () =
        let shape = Circle(3.0)
        let expected = 2.0 * System.Math.PI * 3.0
        Assert.Equal(expected, calculatePerimeter shape, 5)

// ============================================
// 2. 複合ディスパッチ
// ============================================

module PaymentTests =

    [<Fact>]
    let ``クレジットカード（円）の処理`` () =
        let payment =
            { Method = CreditCard
              Currency = JPY
              Amount = 1000 }

        let result = processPayment payment
        Assert.Equal("processed", result.Status)
        Assert.Equal("クレジットカード（円）で処理しました", result.Message)
        Assert.Equal(1000, result.Amount)

    [<Fact>]
    let ``クレジットカード（ドル）の処理`` () =
        let payment =
            { Method = CreditCard
              Currency = USD
              Amount = 100 }

        let result = processPayment payment
        Assert.Equal("processed", result.Status)
        Assert.Equal("Credit card (USD) processed", result.Message)
        Assert.Equal(Some 15000, result.Converted)

    [<Fact>]
    let ``銀行振込（円）の処理`` () =
        let payment =
            { Method = BankTransfer
              Currency = JPY
              Amount = 5000 }

        let result = processPayment payment
        Assert.Equal("pending", result.Status)
        Assert.Equal("銀行振込を受け付けました", result.Message)

    [<Fact>]
    let ``サポートされていない支払い方法`` () =
        let payment =
            { Method = Cash
              Currency = EUR
              Amount = 100 }

        let result = processPayment payment
        Assert.Equal("error", result.Status)
        Assert.Equal("サポートされていない支払い方法です", result.Message)

// ============================================
// 3. 階層的ディスパッチ
// ============================================

module AccountTests =

    [<Fact>]
    let ``普通預金の利息計算`` () =
        let account = { AccountType = Savings; Balance = 10000 }
        Assert.Equal(200.0, calculateInterest account)

    [<Fact>]
    let ``プレミアム普通預金の利息計算`` () =
        let account =
            { AccountType = PremiumSavings
              Balance = 10000 }

        Assert.Equal(500.0, calculateInterest account)

    [<Fact>]
    let ``当座預金の利息計算`` () =
        let account =
            { AccountType = Checking
              Balance = 10000 }

        Assert.Equal(10.0, calculateInterest account)

    [<Fact>]
    let ``利率の取得`` () =
        Assert.Equal(0.02, getInterestRate Savings)
        Assert.Equal(0.05, getInterestRate PremiumSavings)
        Assert.Equal(0.001, getInterestRate Checking)

// ============================================
// 4-5. インターフェースを実装するレコード
// ============================================

module DrawableTests =

    [<Fact>]
    let ``Rectangle を描画`` () =
        let rect =
            { DrawableRectangle.X = 10.0
              Y = 20.0
              Width = 100.0
              Height = 50.0 }

        let result = draw rect
        Assert.Equal("Rectangle at (10.0,20.0) with size 100.0x50.0", result)

    [<Fact>]
    let ``Rectangle のバウンディングボックス`` () =
        let rect =
            { DrawableRectangle.X = 10.0
              Y = 20.0
              Width = 100.0
              Height = 50.0 }

        let bbox = getBoundingBox rect
        Assert.Equal(10.0, bbox.X)
        Assert.Equal(20.0, bbox.Y)
        Assert.Equal(100.0, bbox.Width)
        Assert.Equal(50.0, bbox.Height)

    [<Fact>]
    let ``Circle を描画`` () =
        let circle =
            { DrawableCircle.X = 50.0
              Y = 50.0
              Radius = 25.0 }

        let result = draw circle
        Assert.Equal("Circle at (50.0,50.0) with radius 25.0", result)

    [<Fact>]
    let ``Circle のバウンディングボックス`` () =
        let circle =
            { DrawableCircle.X = 50.0
              Y = 50.0
              Radius = 25.0 }

        let bbox = getBoundingBox circle
        Assert.Equal(25.0, bbox.X)
        Assert.Equal(25.0, bbox.Y)
        Assert.Equal(50.0, bbox.Width)
        Assert.Equal(50.0, bbox.Height)

    [<Fact>]
    let ``Rectangle を移動`` () =
        let rect =
            { DrawableRectangle.X = 10.0
              Y = 20.0
              Width = 100.0
              Height = 50.0 }

        let moved = translateRect rect (5.0, 10.0)
        Assert.Equal(15.0, moved.X)
        Assert.Equal(30.0, moved.Y)

    [<Fact>]
    let ``Rectangle を拡大`` () =
        let rect =
            { DrawableRectangle.X = 10.0
              Y = 20.0
              Width = 100.0
              Height = 50.0 }

        let scaled = scaleRect rect 2.0
        Assert.Equal(200.0, scaled.Width)
        Assert.Equal(100.0, scaled.Height)

    [<Fact>]
    let ``Circle を移動`` () =
        let circle =
            { DrawableCircle.X = 50.0
              Y = 50.0
              Radius = 25.0 }

        let moved = translateCircle circle (10.0, 20.0)
        Assert.Equal(60.0, moved.X)
        Assert.Equal(70.0, moved.Y)

    [<Fact>]
    let ``Circle を拡大`` () =
        let circle =
            { DrawableCircle.X = 50.0
              Y = 50.0
              Radius = 25.0 }

        let scaled = scaleCircle circle 2.0
        Assert.Equal(50.0, scaled.Radius)

// ============================================
// 6. アクティブパターン
// ============================================

module StringifyTests =

    [<Fact>]
    let ``Map を文字列化`` () =
        let m = Map.ofList [ "name", box "田中"; "age", box 30 ]
        let result = stringify m
        Assert.Contains("name: 田中", result)
        Assert.Contains("age: 30", result)

    [<Fact>]
    let ``リストを文字列化`` () =
        let l = [ 1; 2; 3 ]
        let result = stringify l
        Assert.Equal("[1, 2, 3]", result)

    [<Fact>]
    let ``文字列を文字列化`` () =
        Assert.Equal("hello", stringify "hello")

    [<Fact>]
    let ``整数を文字列化`` () =
        Assert.Equal("42", stringify 42)

// ============================================
// 7. コンポーネントパターン
// ============================================

module LifecycleTests =

    [<Fact>]
    let ``DatabaseConnection を開始`` () =
        let db = DatabaseConnection.Create("localhost", 5432)
        Assert.False(db.Connected)

        let started = startDb db
        Assert.True(started.Connected)

    [<Fact>]
    let ``DatabaseConnection を停止`` () =
        let db = DatabaseConnection.Create("localhost", 5432)
        let started = startDb db
        let stopped = stopDb started
        Assert.False(stopped.Connected)

    [<Fact>]
    let ``WebServer を開始`` () =
        let db = DatabaseConnection.Create("localhost", 5432)
        let server = WebServer.Create(8080, db)
        Assert.False(server.Running)
        Assert.False(server.Db.Connected)

        let started = startServer server
        Assert.True(started.Running)
        Assert.True(started.Db.Connected)

    [<Fact>]
    let ``WebServer を停止`` () =
        let db = DatabaseConnection.Create("localhost", 5432)
        let server = WebServer.Create(8080, db)
        let started = startServer server
        let stopped = stopServer started
        Assert.False(stopped.Running)
        Assert.False(stopped.Db.Connected)

// ============================================
// 8. Strategy パターン（通知）
// ============================================

module NotificationTests =

    [<Fact>]
    let ``メール通知を送信`` () =
        let sender = createNotification "email" (Map.ofList [ "to", "user@example.com" ])
        let result = send sender "重要なお知らせ"

        Assert.Equal("email", result.NotificationType)
        Assert.Equal("user@example.com", result.To)
        Assert.Equal("重要なお知らせ", result.Body)
        Assert.Equal("sent", result.Status)
        Assert.Equal(Some "通知", result.Subject)

    [<Fact>]
    let ``SMS通知を送信`` () =
        let sender = createNotification "sms" (Map.ofList [ "phone", "090-1234-5678" ])
        let result = send sender "短いメッセージ"

        Assert.Equal("sms", result.NotificationType)
        Assert.Equal("090-1234-5678", result.To)
        Assert.Equal("短いメッセージ", result.Body)
        Assert.True(result.Subject.IsNone)

    [<Fact>]
    let ``SMS通知は160文字で切り詰め`` () =
        let sender = createNotification "sms" (Map.ofList [ "phone", "090-1234-5678" ])
        let longMessage = String.replicate 200 "a"
        let result = send sender longMessage

        Assert.Equal(157, result.Body.Length)

    [<Fact>]
    let ``プッシュ通知を送信`` () =
        let sender = createNotification "push" (Map.ofList [ "device", "device-token-123" ])
        let result = send sender "プッシュ通知"

        Assert.Equal("push", result.NotificationType)
        Assert.Equal("device-token-123", result.To)
        Assert.Equal("プッシュ通知", result.Body)

    [<Fact>]
    let ``配信時間を取得`` () =
        let email = createNotification "email" (Map.ofList [ "to", "test@example.com" ])
        let sms = createNotification "sms" (Map.ofList [ "phone", "090-0000-0000" ])
        let push = createNotification "push" (Map.ofList [ "device", "token" ])

        Assert.Equal("1-2分", getDeliveryTime email)
        Assert.Equal("数秒", getDeliveryTime sms)
        Assert.Equal("即時", getDeliveryTime push)

    [<Fact>]
    let ``未知の通知タイプは例外`` () =
        Assert.Throws<Exception>(fun () -> createNotification "unknown" Map.empty |> ignore)

// ============================================
// 9. 式ツリーパターン
// ============================================

module ExprTests =

    [<Fact>]
    let ``数値を評価`` () =
        Assert.Equal(42, eval (Num 42))

    [<Fact>]
    let ``加算を評価`` () =
        let expr = Add(Num 2, Num 3)
        Assert.Equal(5, eval expr)

    [<Fact>]
    let ``乗算を評価`` () =
        let expr = Mul(Num 4, Num 5)
        Assert.Equal(20, eval expr)

    [<Fact>]
    let ``否定を評価`` () =
        let expr = Neg(Num 10)
        Assert.Equal(-10, eval expr)

    [<Fact>]
    let ``複合式を評価`` () =
        // (2 + 3) * 4 = 20
        let expr = Mul(Add(Num 2, Num 3), Num 4)
        Assert.Equal(20, eval expr)

    [<Fact>]
    let ``式を文字列化`` () =
        let expr = Add(Num 2, Mul(Num 3, Num 4))
        Assert.Equal("(2 + (3 * 4))", exprToString expr)

    [<Fact>]
    let ``0との加算を簡約`` () =
        let expr = Add(Num 0, Num 5)
        let simplified = simplify expr
        Assert.Equal(Num 5, simplified)

    [<Fact>]
    let ``0との乗算を簡約`` () =
        let expr = Mul(Num 0, Num 5)
        let simplified = simplify expr
        Assert.Equal(Num 0, simplified)

    [<Fact>]
    let ``1との乗算を簡約`` () =
        let expr = Mul(Num 1, Num 5)
        let simplified = simplify expr
        Assert.Equal(Num 5, simplified)

    [<Fact>]
    let ``二重否定を簡約`` () =
        let expr = Neg(Neg(Num 5))
        let simplified = simplify expr
        Assert.Equal(Num 5, simplified)

