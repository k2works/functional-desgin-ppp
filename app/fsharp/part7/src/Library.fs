namespace FunctionalDesign.Part7

// ============================================
// 第20章: パターン間の相互作用
// ============================================

module PatternInteractions =

    // ============================================
    // 1. Composite + Decorator パターン
    // ============================================

    /// 図形の基本型
    [<RequireQualifiedAccess>]
    type ShapeType =
        | Circle
        | Rectangle
        | Composite
        | Journaled
        | Colored
        | Bordered

    /// 図形
    type Shape =
        | Circle of x: float * y: float * radius: float
        | Rectangle of x: float * y: float * width: float * height: float
        | Composite of shapes: Shape list
        | Journaled of shape: Shape * journal: string list
        | Colored of shape: Shape * color: string
        | Bordered of shape: Shape * borderWidth: float

    module Shape =
        /// 円を作成
        let circle x y radius = Circle(x, y, radius)

        /// 矩形を作成
        let rectangle x y width height = Rectangle(x, y, width, height)

        /// 複合図形を作成
        let composite shapes = Composite shapes

        /// ジャーナル付き図形を作成
        let journaled shape = Journaled(shape, [])

        /// 色付き図形を作成
        let colored color shape = Colored(shape, color)

        /// 枠付き図形を作成
        let bordered width shape = Bordered(shape, width)

        /// 図形を移動
        let rec move dx dy shape =
            match shape with
            | Circle(x, y, r) -> Circle(x + dx, y + dy, r)
            | Rectangle(x, y, w, h) -> Rectangle(x + dx, y + dy, w, h)
            | Composite shapes -> Composite(shapes |> List.map (move dx dy))
            | Journaled(s, journal) ->
                Journaled(move dx dy s, sprintf "moved(%.1f, %.1f)" dx dy :: journal)
            | Colored(s, c) -> Colored(move dx dy s, c)
            | Bordered(s, w) -> Bordered(move dx dy s, w)

        /// 図形を拡大/縮小
        let rec scale factor shape =
            match shape with
            | Circle(x, y, r) -> Circle(x, y, r * factor)
            | Rectangle(x, y, w, h) -> Rectangle(x, y, w * factor, h * factor)
            | Composite shapes -> Composite(shapes |> List.map (scale factor))
            | Journaled(s, journal) ->
                Journaled(scale factor s, sprintf "scaled(%.1f)" factor :: journal)
            | Colored(s, c) -> Colored(scale factor s, c)
            | Bordered(s, w) -> Bordered(scale factor s, w * factor)

        /// 面積を計算
        let rec area shape =
            match shape with
            | Circle(_, _, r) -> System.Math.PI * r * r
            | Rectangle(_, _, w, h) -> w * h
            | Composite shapes -> shapes |> List.sumBy area
            | Journaled(s, _) -> area s
            | Colored(s, _) -> area s
            | Bordered(s, _) -> area s

        /// ジャーナルを取得
        let rec getJournal shape =
            match shape with
            | Journaled(_, journal) -> journal
            | _ -> []

    // ============================================
    // 2. Command + Observer パターン
    // ============================================

    /// 観察者の型
    type Observer<'T> = 'T -> unit

    /// オブザーバブル
    type Observable<'T> =
        { Observers: Observer<'T> list }

    module Observable =
        let create () = { Observers = [] }

        let subscribe (observer: Observer<'T>) (observable: Observable<'T>) =
            { observable with Observers = observer :: observable.Observers }

        let notify (value: 'T) (observable: Observable<'T>) =
            observable.Observers |> List.iter (fun obs -> obs value)

    /// コマンド
    type Command<'TState> =
        | Execute of execute: ('TState -> 'TState) * description: string
        | Undo of undo: ('TState -> 'TState) * description: string

    /// コマンド実行器
    type CommandExecutor<'TState> =
        { State: 'TState
          History: (Command<'TState> * 'TState) list
          Observable: Observable<'TState> }

    module CommandExecutor =
        let create (initialState: 'TState) =
            { State = initialState
              History = []
              Observable = Observable.create () }

        let execute (command: Command<'TState>) (executor: CommandExecutor<'TState>) =
            match command with
            | Execute(exec, _) ->
                let newState = exec executor.State
                Observable.notify newState executor.Observable
                { executor with
                    State = newState
                    History = (command, executor.State) :: executor.History }
            | _ -> executor

        let undo (executor: CommandExecutor<'TState>) =
            match executor.History with
            | (_, prevState) :: rest ->
                Observable.notify prevState executor.Observable
                { executor with State = prevState; History = rest }
            | [] -> executor

        let subscribe (observer: Observer<'TState>) (executor: CommandExecutor<'TState>) =
            { executor with Observable = Observable.subscribe observer executor.Observable }

    // ============================================
    // 3. Strategy + Factory パターン
    // ============================================

    /// 価格計算戦略
    type PricingStrategy =
        | Regular
        | Discount of rate: decimal
        | Member of level: string
        | Bulk of threshold: decimal * rate: decimal

    module PricingStrategy =
        let calculate (strategy: PricingStrategy) (amount: decimal) : decimal =
            match strategy with
            | Regular -> amount
            | Discount rate -> amount * (1m - rate)
            | Member level ->
                match level with
                | "gold" -> amount * 0.8m
                | "silver" -> amount * 0.85m
                | _ -> amount * 0.9m
            | Bulk(threshold, rate) ->
                if amount >= threshold then amount * (1m - rate)
                else amount

    /// 戦略ファクトリ
    module PricingFactory =
        let createFromCustomer (customerType: string) (purchaseAmount: decimal) : PricingStrategy =
            match customerType with
            | "guest" -> Regular
            | "member" -> Member "bronze"
            | "vip" -> Member "gold"
            | "wholesale" when purchaseAmount > 10000m -> Bulk(10000m, 0.15m)
            | _ -> Regular


// ============================================
// 第21章: ベストプラクティス
// ============================================

module BestPractices =

    // ============================================
    // 1. データ中心設計
    // ============================================

    /// ユーザー
    type User =
        { Id: string
          Name: string
          Email: string
          CreatedAt: System.DateTime }

    /// 注文
    type Order =
        { Id: string
          UserId: string
          Items: OrderItem list
          Status: OrderStatus
          CreatedAt: System.DateTime }

    and OrderItem =
        { ProductId: string
          Quantity: int
          Price: decimal }

    and OrderStatus =
        | Pending
        | Confirmed
        | Shipped
        | Delivered
        | Cancelled

    module User =
        let create id name email =
            { Id = id
              Name = name
              Email = email
              CreatedAt = System.DateTime.UtcNow }

    module Order =
        let create id userId items =
            { Id = id
              UserId = userId
              Items = items
              Status = Pending
              CreatedAt = System.DateTime.UtcNow }

        let calculateItemTotal (item: OrderItem) =
            decimal item.Quantity * item.Price

        let calculateTotal (order: Order) =
            order.Items |> List.sumBy calculateItemTotal

        let applyDiscount (rate: decimal) (total: decimal) =
            total * (1m - rate)

    // ============================================
    // 2. パイプライン処理
    // ============================================

    module Pipeline =
        /// 注文処理パイプライン
        let processOrder (discountRate: decimal) (order: Order) =
            order
            |> Order.calculateTotal
            |> Order.applyDiscount discountRate

        /// 注文を確認状態に変更
        let confirm (order: Order) =
            { order with Status = Confirmed }

        /// 注文を発送状態に変更
        let ship (order: Order) =
            match order.Status with
            | Confirmed -> { order with Status = Shipped }
            | _ -> order

        /// 注文を配達完了状態に変更
        let deliver (order: Order) =
            match order.Status with
            | Shipped -> { order with Status = Delivered }
            | _ -> order

    // ============================================
    // 3. Result 型によるエラーハンドリング
    // ============================================

    module Validation =
        type ValidationError =
            | InvalidEmail of string
            | InvalidName of string
            | InvalidQuantity of string
            | InvalidPrice of string

        let validateEmail (email: string) : Result<string, ValidationError> =
            if email.Contains("@") then Ok email
            else Error (InvalidEmail "Email must contain @")

        let validateName (name: string) : Result<string, ValidationError> =
            if String.length name >= 2 then Ok name
            else Error (InvalidName "Name must be at least 2 characters")

        let validateQuantity (qty: int) : Result<int, ValidationError> =
            if qty > 0 then Ok qty
            else Error (InvalidQuantity "Quantity must be positive")

        let validatePrice (price: decimal) : Result<decimal, ValidationError> =
            if price > 0m then Ok price
            else Error (InvalidPrice "Price must be positive")

        /// Result を連鎖させるヘルパー
        let bind (f: 'a -> Result<'b, 'e>) (result: Result<'a, 'e>) : Result<'b, 'e> =
            match result with
            | Ok v -> f v
            | Error e -> Error e

        /// 複数の検証を組み合わせる
        let validateOrderItem (productId: string) (qty: int) (price: decimal) =
            validateQuantity qty
            |> bind (fun q ->
                validatePrice price
                |> Result.map (fun p -> { ProductId = productId; Quantity = q; Price = p }))

    // ============================================
    // 4. 副作用の分離
    // ============================================

    /// 純粋な計算部分
    module Pure =
        let calculateTax (rate: decimal) (amount: decimal) =
            amount * rate

        let formatCurrency (amount: decimal) =
            sprintf "$%.2f" amount

        let generateInvoiceText (order: Order) (total: decimal) (tax: decimal) =
            let lines =
                order.Items
                |> List.map (fun item ->
                    sprintf "%s x %d @ $%.2f = $%.2f"
                        item.ProductId item.Quantity item.Price
                        (decimal item.Quantity * item.Price))
            let header = sprintf "Invoice for Order %s" order.Id
            let subtotal = sprintf "Subtotal: $%.2f" total
            let taxLine = sprintf "Tax: $%.2f" tax
            let totalLine = sprintf "Total: $%.2f" (total + tax)
            String.concat "\n" (header :: lines @ [subtotal; taxLine; totalLine])

    /// 副作用を持つ部分（境界）
    module Effects =
        /// ログ出力（副作用）
        let log (message: string) =
            printfn "[LOG] %s" message

        /// 通知送信（副作用）
        type Notification =
            { Recipient: string
              Subject: string
              Body: string }

        let sendNotification (notification: Notification) =
            printfn "[NOTIFICATION] To: %s, Subject: %s" notification.Recipient notification.Subject


// ============================================
// 第22章: OO から FP への移行
// ============================================

module OOToFPMigration =

    // ============================================
    // 1. OO スタイル（Before）
    // ============================================

    /// OO スタイルの銀行口座（可変状態を持つ）
    type AccountOO(id: string, initialBalance: decimal) =
        let mutable balance = initialBalance
        let mutable transactions: (string * decimal * System.DateTime) list = []

        member _.Id = id
        member _.Balance = balance

        member _.Deposit(amount: decimal) =
            if amount > 0m then
                balance <- balance + amount
                transactions <- ("deposit", amount, System.DateTime.UtcNow) :: transactions
                true
            else false

        member _.Withdraw(amount: decimal) =
            if amount > 0m && balance >= amount then
                balance <- balance - amount
                transactions <- ("withdrawal", amount, System.DateTime.UtcNow) :: transactions
                true
            else false

        member _.GetTransactions() = transactions

    // ============================================
    // 2. FP スタイル（After）
    // ============================================

    /// トランザクション
    type Transaction =
        { Type: TransactionType
          Amount: decimal
          Timestamp: System.DateTime }

    and TransactionType =
        | Deposit
        | Withdrawal

    /// 口座（イミュータブル）
    type Account =
        { Id: string
          Balance: decimal
          Transactions: Transaction list }

    module Account =
        /// 口座を作成
        let create (id: string) (initialBalance: decimal) : Account =
            { Id = id
              Balance = initialBalance
              Transactions = [] }

        /// 入金（新しい口座を返す）
        let deposit (amount: decimal) (account: Account) : Result<Account, string> =
            if amount > 0m then
                let tx = { Type = Deposit; Amount = amount; Timestamp = System.DateTime.UtcNow }
                Ok { account with
                        Balance = account.Balance + amount
                        Transactions = tx :: account.Transactions }
            else Error "Amount must be positive"

        /// 出金（新しい口座を返す）
        let withdraw (amount: decimal) (account: Account) : Result<Account, string> =
            if amount <= 0m then
                Error "Amount must be positive"
            elif amount > account.Balance then
                Error "Insufficient balance"
            else
                let tx = { Type = Withdrawal; Amount = amount; Timestamp = System.DateTime.UtcNow }
                Ok { account with
                        Balance = account.Balance - amount
                        Transactions = tx :: account.Transactions }

        /// 残高照会
        let getBalance (account: Account) : decimal =
            account.Balance

        /// トランザクション履歴
        let getTransactions (account: Account) : Transaction list =
            account.Transactions

    // ============================================
    // 3. 移行パターン
    // ============================================

    /// 継承からコンポジションへ
    module InheritanceToComposition =

        // Before: 継承ベース
        // abstract class Animal
        //   def speak(): String
        // class Dog extends Animal
        //   override def speak() = "Woof"
        // class Cat extends Animal
        //   override def speak() = "Meow"

        // After: 判別共用体 + パターンマッチング
        type Animal =
            | Dog of name: string
            | Cat of name: string
            | Bird of name: string

        let speak (animal: Animal) : string =
            match animal with
            | Dog _ -> "Woof"
            | Cat _ -> "Meow"
            | Bird _ -> "Tweet"

        let getName (animal: Animal) : string =
            match animal with
            | Dog name -> name
            | Cat name -> name
            | Bird name -> name

    /// インターフェースから関数レコードへ
    module InterfaceToFunctionRecord =

        // Before: インターフェース
        // interface IRepository<T>
        //   def findById(id: String): Option<T>
        //   def save(entity: T): T
        //   def delete(id: String): Boolean

        // After: 関数のレコード
        type Repository<'T> =
            { FindById: string -> 'T option
              Save: 'T -> 'T
              Delete: string -> bool }

        /// インメモリリポジトリを作成
        let createInMemoryRepo<'T> (getId: 'T -> string) : Repository<'T> =
            let mutable data: Map<string, 'T> = Map.empty
            { FindById = fun id -> Map.tryFind id data
              Save = fun entity ->
                  let id = getId entity
                  data <- Map.add id entity data
                  entity
              Delete = fun id ->
                  if Map.containsKey id data then
                      data <- Map.remove id data
                      true
                  else false }

    /// 可変状態からイベントソーシングへ
    module MutableToEventSourcing =

        /// イベント
        type AccountEvent =
            | AccountCreated of id: string * initialBalance: decimal
            | MoneyDeposited of amount: decimal
            | MoneyWithdrawn of amount: decimal

        /// 状態を再構築
        let applyEvent (state: Account) (event: AccountEvent) : Account =
            match event with
            | AccountCreated(id, balance) ->
                { Id = id; Balance = balance; Transactions = [] }
            | MoneyDeposited amount ->
                let tx = { Type = Deposit; Amount = amount; Timestamp = System.DateTime.UtcNow }
                { state with Balance = state.Balance + amount; Transactions = tx :: state.Transactions }
            | MoneyWithdrawn amount ->
                let tx = { Type = Withdrawal; Amount = amount; Timestamp = System.DateTime.UtcNow }
                { state with Balance = state.Balance - amount; Transactions = tx :: state.Transactions }

        /// イベントリストから状態を再構築
        let replay (events: AccountEvent list) : Account =
            let initial = { Id = ""; Balance = 0m; Transactions = [] }
            List.fold applyEvent initial events
