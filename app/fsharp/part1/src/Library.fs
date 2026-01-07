namespace FunctionalDesign

// ============================================
// 第1章: 不変性とデータ変換
// ============================================

module Immutability =

    // ============================================
    // 1. 不変データ構造の基本
    // ============================================

    /// Person レコード（デフォルトで不変）
    type Person = { Name: string; Age: int }

    /// 年齢を更新（新しいレコードを返す）
    let updateAge person newAge = { person with Age = newAge }

    /// 名前を更新
    let updateName person newName = { person with Name = newName }

    // ============================================
    // 2. 構造共有
    // ============================================

    /// チームメンバー
    type Member = { Name: string; Role: string }

    /// チーム
    type Team = { Name: string; Members: Member list }

    /// メンバーを追加（新しいチームを返す）
    let addMember team newMember =
        { team with Members = team.Members @ [ newMember ] }

    /// メンバーを削除
    let removeMember team memberName =
        { team with
            Members = team.Members |> List.filter (fun m -> m.Name <> memberName) }

    // ============================================
    // 3. データ変換パイプライン
    // ============================================

    /// 注文アイテム
    type Item = { Name: string; Price: int; Quantity: int }

    /// 会員種別
    type Membership =
        | Gold
        | Silver
        | Bronze
        | Standard

    /// 顧客
    type Customer = { Name: string; Membership: Membership }

    /// 注文
    type Order = { Items: Item list; Customer: Customer }

    /// 小計を計算
    let calculateSubtotal item = item.Price * item.Quantity

    /// 会員種別に応じた割引率を取得
    let membershipDiscount =
        function
        | Gold -> 0.1
        | Silver -> 0.05
        | Bronze -> 0.02
        | Standard -> 0.0

    /// 注文の合計金額を計算
    let calculateTotal order =
        order.Items |> List.map calculateSubtotal |> List.sum

    /// 割引後の金額を計算
    let applyDiscount order total =
        let discountRate = membershipDiscount order.Customer.Membership
        float total * (1.0 - discountRate)

    /// 注文処理パイプライン
    let processOrder order =
        order |> calculateTotal |> applyDiscount order

    // ============================================
    // 4. 副作用の分離
    // ============================================

    /// 請求書
    type Invoice =
        { Subtotal: int
          Tax: float
          Total: float }

    /// 税金を計算（純粋関数）
    let calculateTax amount taxRate = float amount * taxRate

    /// 請求書を作成（純粋関数）
    let calculateInvoice items taxRate =
        let subtotal = items |> List.map calculateSubtotal |> List.sum
        let tax = calculateTax subtotal taxRate
        let total = float subtotal + tax

        { Subtotal = subtotal
          Tax = tax
          Total = total }

    // ============================================
    // 5. 履歴管理（Undo/Redo）
    // ============================================

    /// 履歴
    type History<'T> =
        { Current: 'T option
          Past: 'T list
          Future: 'T list }

    /// 空の履歴を作成
    let createHistory () = { Current = None; Past = []; Future = [] }

    /// 新しい状態をプッシュ（パイプライン向け引数順）
    let pushState newState history =
        let newPast =
            match history.Current with
            | Some current -> current :: history.Past
            | None -> history.Past

        { Current = Some newState
          Past = newPast
          Future = [] }

    /// Undo
    let undo history =
        match history.Past with
        | [] -> history
        | previous :: rest ->
            let newFuture =
                match history.Current with
                | Some current -> current :: history.Future
                | None -> history.Future

            { Current = Some previous
              Past = rest
              Future = newFuture }

    /// Redo
    let redo history =
        match history.Future with
        | [] -> history
        | next :: rest ->
            let newPast =
                match history.Current with
                | Some current -> current :: history.Past
                | None -> history.Past

            { Current = Some next
              Past = newPast
              Future = rest }

    /// 現在の状態を取得
    let currentState history = history.Current

    // ============================================
    // 6. 効率的な変換（Seq による遅延評価）
    // ============================================

    /// アイテムを処理（遅延評価）
    let processItemsEfficiently items =
        items
        |> Seq.filter (fun item -> item.Quantity > 0)
        |> Seq.map (fun item -> {| item with Subtotal = calculateSubtotal item |})
        |> Seq.filter (fun item -> item.Subtotal > 100)
        |> Seq.toList

    // ============================================
    // 7. 不変リストの操作
    // ============================================

    /// リストの先頭に追加
    let prepend item list = item :: list

    /// リストの末尾に追加
    let append item list = list @ [ item ]

    /// リストを結合
    let concat list1 list2 = list1 @ list2

    /// 条件でフィルタリング
    let filterBy predicate list = List.filter predicate list

    /// マッピング
    let mapWith f list = List.map f list

    /// 畳み込み
    let foldWith folder initial list = List.fold folder initial list

    // ============================================
    // 8. 不変Map（Dictionary）の操作
    // ============================================

    /// エントリを追加
    let addEntry key value map = Map.add key value map

    /// エントリを削除
    let removeEntry key map = Map.remove key map

    /// 値を取得
    let tryGetValue key map = Map.tryFind key map

    /// キーが存在するか
    let containsKey key map = Map.containsKey key map

    /// 値を更新
    let updateValue key updater map =
        match Map.tryFind key map with
        | Some value -> Map.add key (updater value) map
        | None -> map

