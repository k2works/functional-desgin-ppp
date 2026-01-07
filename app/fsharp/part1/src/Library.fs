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


// ============================================
// 第3章: 多態性とディスパッチ
// ============================================

module Polymorphism =

    // ============================================
    // 1. 判別共用体による多態性（代数的データ型）
    // ============================================

    /// 図形を表す判別共用体
    type Shape =
        | Rectangle of width: float * height: float
        | Circle of radius: float
        | Triangle of baseLength: float * height: float

    /// 図形の面積を計算する
    let calculateArea shape =
        match shape with
        | Rectangle(w, h) -> w * h
        | Circle r -> System.Math.PI * r * r
        | Triangle(b, h) -> b * h / 2.0

    /// 図形の周囲長を計算する
    let calculatePerimeter shape =
        match shape with
        | Rectangle(w, h) -> 2.0 * (w + h)
        | Circle r -> 2.0 * System.Math.PI * r
        | Triangle(b, h) ->
            // 底辺と高さから等脚三角形の周囲長を近似
            let side = sqrt ((b / 2.0) ** 2.0 + h ** 2.0)
            b + 2.0 * side

    // ============================================
    // 2. 複合ディスパッチ
    // ============================================

    /// 支払い方法
    type PaymentMethod =
        | CreditCard
        | BankTransfer
        | Cash

    /// 通貨
    type Currency =
        | JPY
        | USD
        | EUR

    /// 支払い情報
    type Payment =
        { Method: PaymentMethod
          Currency: Currency
          Amount: int }

    /// 支払い結果
    type PaymentResult =
        { Status: string
          Message: string
          Amount: int
          Converted: int option }

    /// 支払いを処理する（複合ディスパッチ）
    let processPayment payment =
        match payment.Method, payment.Currency with
        | CreditCard, JPY ->
            { Status = "processed"
              Message = "クレジットカード（円）で処理しました"
              Amount = payment.Amount
              Converted = None }
        | CreditCard, USD ->
            { Status = "processed"
              Message = "Credit card (USD) processed"
              Amount = payment.Amount
              Converted = Some(payment.Amount * 150) }
        | BankTransfer, JPY ->
            { Status = "pending"
              Message = "銀行振込を受け付けました"
              Amount = payment.Amount
              Converted = None }
        | _, _ ->
            { Status = "error"
              Message = "サポートされていない支払い方法です"
              Amount = payment.Amount
              Converted = None }

    // ============================================
    // 3. 階層的ディスパッチ（型階層の模倣）
    // ============================================

    /// 口座タイプ
    type AccountType =
        | Savings
        | PremiumSavings
        | Checking

    /// 口座
    type Account =
        { AccountType: AccountType
          Balance: int }

    /// 利率を取得
    let getInterestRate accountType =
        match accountType with
        | Savings -> 0.02
        | PremiumSavings -> 0.05
        | Checking -> 0.001

    /// 利息を計算
    let calculateInterest account =
        float account.Balance * getInterestRate account.AccountType

    // ============================================
    // 4. インターフェース（F# のオブジェクト指向機能）
    // ============================================

    /// バウンディングボックス
    type BoundingBox =
        { X: float
          Y: float
          Width: float
          Height: float }

    /// 描画可能インターフェース
    type IDrawable =
        abstract member Draw: unit -> string
        abstract member GetBoundingBox: unit -> BoundingBox

    /// 変換可能インターフェース
    type ITransformable<'T> =
        abstract member Translate: float * float -> 'T
        abstract member Scale: float -> 'T
        abstract member Rotate: float -> 'T

    // ============================================
    // 5. インターフェースを実装するレコード
    // ============================================

    /// 描画可能な長方形
    type DrawableRectangle =
        { X: float
          Y: float
          Width: float
          Height: float }

        interface IDrawable with
            member this.Draw() =
                sprintf "Rectangle at (%.1f,%.1f) with size %.1fx%.1f" this.X this.Y this.Width this.Height

            member this.GetBoundingBox() =
                { X = this.X
                  Y = this.Y
                  Width = this.Width
                  Height = this.Height }

        interface ITransformable<DrawableRectangle> with
            member this.Translate(dx, dy) =
                { this with X = this.X + dx; Y = this.Y + dy }

            member this.Scale(factor) =
                { this with
                    Width = this.Width * factor
                    Height = this.Height * factor }

            member this.Rotate(_) = this

    /// 描画可能な円
    type DrawableCircle =
        { X: float
          Y: float
          Radius: float }

        interface IDrawable with
            member this.Draw() =
                sprintf "Circle at (%.1f,%.1f) with radius %.1f" this.X this.Y this.Radius

            member this.GetBoundingBox() =
                { X = this.X - this.Radius
                  Y = this.Y - this.Radius
                  Width = this.Radius * 2.0
                  Height = this.Radius * 2.0 }

        interface ITransformable<DrawableCircle> with
            member this.Translate(dx, dy) =
                { this with X = this.X + dx; Y = this.Y + dy }

            member this.Scale(factor) =
                { this with Radius = this.Radius * factor }

            member this.Rotate(_) = this

    // ヘルパー関数（インターフェースメソッドを呼び出しやすくする）
    let draw (drawable: IDrawable) = drawable.Draw()

    let getBoundingBox (drawable: IDrawable) = drawable.GetBoundingBox()

    let translateRect (rect: DrawableRectangle) (dx, dy) =
        (rect :> ITransformable<DrawableRectangle>).Translate(dx, dy)

    let scaleRect (rect: DrawableRectangle) factor =
        (rect :> ITransformable<DrawableRectangle>).Scale(factor)

    let translateCircle (circle: DrawableCircle) (dx, dy) =
        (circle :> ITransformable<DrawableCircle>).Translate(dx, dy)

    let scaleCircle (circle: DrawableCircle) factor =
        (circle :> ITransformable<DrawableCircle>).Scale(factor)

    // ============================================
    // 6. アクティブパターン（既存型への拡張）
    // ============================================

    /// 文字列化アクティブパターン（Map用）
    let (|MapToString|) (m: Map<string, obj>) =
        let pairs = m |> Map.toSeq |> Seq.map (fun (k, v) -> sprintf "%s: %O" k v)
        "{" + System.String.Join(", ", pairs) + "}"

    /// 文字列化アクティブパターン（リスト用）
    let (|ListToString|) (l: 'a list) =
        "[" + System.String.Join(", ", l |> List.map string) + "]"

    /// 文字列化関数
    let stringify value =
        match box value with
        | :? Map<string, obj> as m ->
            let (MapToString s) = m
            s
        | :? (int list) as l ->
            let (ListToString s) = l
            s
        | :? string as s -> s
        | :? int as i -> string i
        | null -> "nil"
        | _ -> sprintf "%O" value

    // ============================================
    // 7. コンポーネントパターン（ライフサイクル管理）
    // ============================================

    /// ライフサイクルインターフェース
    type ILifecycle<'T> =
        abstract member Start: unit -> 'T
        abstract member Stop: unit -> 'T

    /// データベース接続
    type DatabaseConnection =
        { Host: string
          Port: int
          Connected: bool }

        static member Create(host, port) =
            { Host = host
              Port = port
              Connected = false }

        interface ILifecycle<DatabaseConnection> with
            member this.Start() =
                printfn "データベースに接続中: %s : %d" this.Host this.Port
                { this with Connected = true }

            member this.Stop() =
                printfn "データベース接続を切断中"
                { this with Connected = false }

    /// Webサーバー
    type WebServer =
        { Port: int
          Db: DatabaseConnection
          Running: bool }

        static member Create(port, db) =
            { Port = port
              Db = db
              Running = false }

        interface ILifecycle<WebServer> with
            member this.Start() =
                printfn "Webサーバーを起動中 ポート: %d" this.Port
                let startedDb = (this.Db :> ILifecycle<DatabaseConnection>).Start()

                { this with
                    Db = startedDb
                    Running = true }

            member this.Stop() =
                printfn "Webサーバーを停止中"
                let stoppedDb = (this.Db :> ILifecycle<DatabaseConnection>).Stop()

                { this with
                    Db = stoppedDb
                    Running = false }

    // ヘルパー関数
    let startDb (db: DatabaseConnection) =
        (db :> ILifecycle<DatabaseConnection>).Start()

    let stopDb (db: DatabaseConnection) =
        (db :> ILifecycle<DatabaseConnection>).Stop()

    let startServer (server: WebServer) =
        (server :> ILifecycle<WebServer>).Start()

    let stopServer (server: WebServer) =
        (server :> ILifecycle<WebServer>).Stop()

    // ============================================
    // 8. 条件分岐の置き換え（Strategy パターン）
    // ============================================

    /// 通知結果
    type NotificationResult =
        { NotificationType: string
          To: string
          Body: string
          Status: string
          Subject: string option }

    /// 通知送信インターフェース
    type INotificationSender =
        abstract member SendNotification: string -> NotificationResult
        abstract member DeliveryTime: string

    /// メール通知
    type EmailNotification =
        { To: string
          Subject: string }

        interface INotificationSender with
            member this.SendNotification(message) =
                { NotificationType = "email"
                  To = this.To
                  Body = message
                  Status = "sent"
                  Subject = Some this.Subject }

            member this.DeliveryTime = "1-2分"

    /// SMS通知
    type SMSNotification =
        { PhoneNumber: string }

        interface INotificationSender with
            member this.SendNotification(message) =
                let truncated =
                    if message.Length > 160 then
                        message.Substring(0, 157)
                    else
                        message

                { NotificationType = "sms"
                  To = this.PhoneNumber
                  Body = truncated
                  Status = "sent"
                  Subject = None }

            member this.DeliveryTime = "数秒"

    /// プッシュ通知
    type PushNotification =
        { DeviceToken: string }

        interface INotificationSender with
            member this.SendNotification(message) =
                { NotificationType = "push"
                  To = this.DeviceToken
                  Body = message
                  Status = "sent"
                  Subject = None }

            member this.DeliveryTime = "即時"

    /// 通知を作成するファクトリ関数
    let createNotification notificationType (opts: Map<string, string>) : INotificationSender =
        match notificationType with
        | "email" ->
            { To = opts |> Map.tryFind "to" |> Option.defaultValue ""
              Subject = opts |> Map.tryFind "subject" |> Option.defaultValue "通知" }
        | "sms" ->
            { PhoneNumber = opts |> Map.tryFind "phone" |> Option.defaultValue "" }
        | "push" ->
            { DeviceToken = opts |> Map.tryFind "device" |> Option.defaultValue "" }
        | _ -> failwithf "未知の通知タイプ: %s" notificationType

    // ヘルパー関数
    let send (sender: INotificationSender) message =
        sender.SendNotification(message)

    let getDeliveryTime (sender: INotificationSender) = sender.DeliveryTime

    // ============================================
    // 9. 式ツリーパターン（Expression Problem の解決）
    // ============================================

    /// 式を表す判別共用体
    type Expr =
        | Num of int
        | Add of Expr * Expr
        | Mul of Expr * Expr
        | Neg of Expr

    /// 式を評価する
    let rec eval expr =
        match expr with
        | Num n -> n
        | Add(e1, e2) -> eval e1 + eval e2
        | Mul(e1, e2) -> eval e1 * eval e2
        | Neg e -> -(eval e)

    /// 式を文字列化する
    let rec exprToString expr =
        match expr with
        | Num n -> string n
        | Add(e1, e2) -> sprintf "(%s + %s)" (exprToString e1) (exprToString e2)
        | Mul(e1, e2) -> sprintf "(%s * %s)" (exprToString e1) (exprToString e2)
        | Neg e -> sprintf "(-%s)" (exprToString e)

    /// 式を簡約する（定数畳み込み）
    let rec simplify expr =
        match expr with
        | Add(Num 0, e)
        | Add(e, Num 0) -> simplify e
        | Mul(Num 0, _)
        | Mul(_, Num 0) -> Num 0
        | Mul(Num 1, e)
        | Mul(e, Num 1) -> simplify e
        | Neg(Neg e) -> simplify e
        | Add(e1, e2) -> Add(simplify e1, simplify e2)
        | Mul(e1, e2) -> Mul(simplify e1, simplify e2)
        | Neg e -> Neg(simplify e)
        | e -> e


