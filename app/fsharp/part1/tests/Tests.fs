module Tests

open System
open Xunit
open FunctionalDesign.Immutability

// ============================================
// 1. 不変データ構造の基本
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

