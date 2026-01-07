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


// ============================================
// 第2章: 関数合成と高階関数
// ============================================

module Composition =

    // ============================================
    // 1. 関数合成の基本
    // ============================================

    /// 税金を追加する
    let addTax rate amount = amount * (1.0 + rate)

    /// 割引を適用する
    let applyDiscountRate rate amount = amount * (1.0 - rate)

    /// 円単位に丸める
    let roundToYen (amount: float) = int64 (System.Math.Round(amount))

    /// >> による関数合成（左から右）
    let calculateFinalPrice: float -> int64 =
        applyDiscountRate 0.2 >> addTax 0.1 >> roundToYen

    /// << による関数合成（右から左、数学的）
    let calculateFinalPriceCompose: float -> int64 =
        roundToYen << addTax 0.1 << applyDiscountRate 0.2

    // ============================================
    // 2. カリー化と部分適用
    // ============================================

    /// カリー化された挨拶関数
    let greet greeting name = sprintf "%s, %s!" greeting name

    /// 部分適用で特化した関数を作成
    let sayHello = greet "Hello"
    let sayGoodbye = greet "Goodbye"

    /// Emailレコード
    type Email =
        { From: string
          To: string
          Subject: string
          Body: string }

    /// カリー化されたメール送信関数
    let sendEmail from' to' subject body =
        { From = from'
          To = to'
          Subject = subject
          Body = body }

    /// 部分適用でシステムメール送信関数を作成
    let sendFromSystem = sendEmail "system@example.com"
    let sendNotification = sendFromSystem "user@example.com" "通知"

    // ============================================
    // 3. 複数の関数を並列適用 (juxt相当)
    // ============================================

    /// 数値リストの統計情報を取得する
    let getStats (numbers: int list) =
        (List.head numbers, List.last numbers, List.length numbers, List.min numbers, List.max numbers)

    /// juxt的な関数を作成する高階関数
    let juxt2 f1 f2 x = (f1 x, f2 x)
    let juxt3 f1 f2 f3 x = (f1 x, f2 x, f3 x)
    let juxt4 f1 f2 f3 f4 x = (f1 x, f2 x, f3 x, f4 x)
    let juxt5 f1 f2 f3 f4 f5 x = (f1 x, f2 x, f3 x, f4 x, f5 x)

    /// 人物分析結果
    type PersonAnalysis =
        { Name: string
          Age: int
          Category: string }

    /// 人物情報を分析する
    let analyzePerson (person: Map<string, obj>) =
        let name = person.["name"] :?> string
        let age = person.["age"] :?> int
        let category = if age >= 18 then "adult" else "minor"

        { Name = name
          Age = age
          Category = category }

    // ============================================
    // 4. 高階関数によるデータ処理
    // ============================================

    /// 処理をラップしてログを出力する高階関数
    let processWithLogging (f: 'a -> 'b) (input: 'a) : 'b =
        printfn "入力: %A" input
        let result = f input
        printfn "出力: %A" result
        result

    /// 処理結果を記録する（副作用なし版）
    type ProcessLog<'a, 'b> = { Input: 'a; Output: 'b }

    let processWithLog (f: 'a -> 'b) (input: 'a) : ProcessLog<'a, 'b> =
        let output = f input
        { Input = input; Output = output }

    /// リトライ機能を追加する高階関数
    let retry maxRetries (f: 'a -> 'b) (input: 'a) : 'b =
        let rec attempt attempts =
            try
                f input
            with
            | ex ->
                if attempts < maxRetries then
                    attempt (attempts + 1)
                else
                    reraise ()

        attempt 0

    /// TTL付きメモ化を行う高階関数
    let memoizeWithTtl (ttlMs: int64) (f: 'a -> 'b) : 'a -> 'b =
        let cache = System.Collections.Generic.Dictionary<'a, ('b * int64)>()

        fun input ->
            let now = System.DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()

            match cache.TryGetValue(input) with
            | true, (value, time) when now - time < ttlMs -> value
            | _ ->
                let result = f input
                cache.[input] <- (result, now)
                result

    /// 基本的なメモ化
    let memoize (f: 'a -> 'b) : 'a -> 'b =
        let cache = System.Collections.Generic.Dictionary<'a, 'b>()

        fun input ->
            match cache.TryGetValue(input) with
            | true, value -> value
            | false, _ ->
                let result = f input
                cache.[input] <- result
                result

    // ============================================
    // 5. パイプライン処理
    // ============================================

    /// 関数のリストを順次適用するパイプラインを作成する
    let pipeline (fns: ('a -> 'a) list) (input: 'a) : 'a =
        List.fold (fun acc f -> f acc) input fns

    /// 注文アイテム
    type OrderItem = { Price: int; Quantity: int }

    /// 顧客（パイプライン用）
    type PipelineCustomer = { Membership: string }

    /// 注文（パイプライン用）
    type PipelineOrder =
        { Items: OrderItem list
          Customer: PipelineCustomer
          Total: float
          Shipping: int }

    /// 注文を検証する
    let validateOrder (order: PipelineOrder) =
        if List.isEmpty order.Items then
            failwith "注文にアイテムがありません"
        else
            order

    /// 注文合計を計算する
    let calculateOrderTotal (order: PipelineOrder) =
        let total =
            order.Items |> List.map (fun item -> item.Price * item.Quantity) |> List.sum |> float

        { order with Total = total }

    /// 注文割引を適用する
    let applyOrderDiscount (order: PipelineOrder) =
        let discountRates =
            Map.ofList [ "gold", 0.1; "silver", 0.05; "bronze", 0.02 ]

        let discountRate =
            discountRates |> Map.tryFind order.Customer.Membership |> Option.defaultValue 0.0

        { order with
            Total = order.Total * (1.0 - discountRate) }

    /// 送料を追加する
    let addShipping (order: PipelineOrder) =
        let shipping = if order.Total >= 5000.0 then 0 else 500

        { order with
            Shipping = shipping
            Total = order.Total + float shipping }

    /// 注文処理パイプライン
    let processOrderPipeline =
        pipeline [ validateOrder; calculateOrderTotal; applyOrderDiscount; addShipping ]

    // ============================================
    // 6. 関数合成によるバリデーション
    // ============================================

    /// バリデーション結果
    type ValidationResult<'a> =
        { Valid: bool
          Value: 'a
          Error: string option }

    /// バリデータを作成する高階関数
    let validator (pred: 'a -> bool) (errorMsg: string) (value: 'a) : ValidationResult<'a> =
        if pred value then
            { Valid = true
              Value = value
              Error = None }
        else
            { Valid = false
              Value = value
              Error = Some errorMsg }

    /// 複数のバリデータを合成する
    let combineValidators (validators: ('a -> ValidationResult<'a>) list) (value: 'a) : ValidationResult<'a> =
        let initial = { Valid = true; Value = value; Error = None }

        validators
        |> List.fold
            (fun result v ->
                if result.Valid then
                    v result.Value
                else
                    result)
            initial

    /// 個別のバリデータ
    let validatePositive = validator (fun x -> x > 0) "値は正の数である必要があります"
    let validateUnder100 = validator (fun x -> x < 100) "値は100未満である必要があります"

    /// 数量バリデータ（合成）
    let validateQuantity = combineValidators [ validatePositive; validateUnder100 ]

    // ============================================
    // 7. 関数の変換
    // ============================================

    /// 引数の順序を反転する
    let flip f a b = f b a

    /// 2引数関数をカリー化する
    let curry f a b = f (a, b)

    /// カリー化された関数を元に戻す
    let uncurry f (a, b) = f a b

    /// 補関数（述語を反転）
    let complement pred x = not (pred x)

    // ============================================
    // 8. 関数合成のパターン
    // ============================================

    /// 複数の述語を AND で合成する
    let composePredicates (preds: ('a -> bool) list) (x: 'a) : bool = preds |> List.forall (fun pred -> pred x)

    /// 複数の述語を OR で合成する
    let composePredicatesOr (preds: ('a -> bool) list) (x: 'a) : bool = preds |> List.exists (fun pred -> pred x)

    /// 有効な年齢チェック
    let validAge =
        composePredicates [ (fun x -> x > 0); (fun x -> x <= 150) ]

    /// 顧客情報
    type CustomerInfo =
        { Membership: string
          PurchaseCount: int
          TotalSpent: int }

    /// プレミアム顧客チェック
    let premiumCustomer =
        composePredicatesOr
            [ (fun c -> c.Membership = "gold")
              (fun c -> c.PurchaseCount >= 100)
              (fun c -> c.TotalSpent >= 100000) ]

