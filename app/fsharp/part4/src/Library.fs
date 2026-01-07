namespace FunctionalDesign.Part4

// ============================================
// 第10章: Strategy パターン
// ============================================

module StrategyPattern =

    // ============================================
    // 1. 料金計算戦略（判別共用体版）
    // ============================================

    /// 会員レベル
    [<RequireQualifiedAccess>]
    type MemberLevel =
        | Gold
        | Silver
        | Bronze

    /// 料金計算戦略
    [<RequireQualifiedAccess>]
    type PricingStrategy =
        | Regular
        | Discount of rate: decimal
        | Member of level: MemberLevel
        | Bulk of threshold: decimal * bulkDiscount: decimal

    module PricingStrategy =
        /// 料金を計算する
        let calculatePrice (strategy: PricingStrategy) (amount: decimal) : decimal =
            match strategy with
            | PricingStrategy.Regular -> amount
            | PricingStrategy.Discount rate -> amount * (1.0m - rate)
            | PricingStrategy.Member level ->
                let rate =
                    match level with
                    | MemberLevel.Gold -> 0.20m
                    | MemberLevel.Silver -> 0.15m
                    | MemberLevel.Bronze -> 0.10m
                amount * (1.0m - rate)
            | PricingStrategy.Bulk(threshold, bulkDiscount) ->
                if amount >= threshold then
                    amount * (1.0m - bulkDiscount)
                else
                    amount

    // ============================================
    // 2. ショッピングカート（Context）
    // ============================================

    type CartItem =
        { Name: string
          Price: decimal
          Quantity: int }

    type ShoppingCart =
        { Items: CartItem list
          Strategy: PricingStrategy }

    module ShoppingCart =
        /// カートを作成
        let create (items: CartItem list) (strategy: PricingStrategy) : ShoppingCart =
            { Items = items; Strategy = strategy }

        /// カートの小計を計算
        let subtotal (cart: ShoppingCart) : decimal =
            cart.Items
            |> List.sumBy (fun item -> item.Price * decimal item.Quantity)

        /// カートの合計金額を計算
        let total (cart: ShoppingCart) : decimal =
            let sub = subtotal cart
            PricingStrategy.calculatePrice cart.Strategy sub

        /// 戦略を変更
        let changeStrategy (newStrategy: PricingStrategy) (cart: ShoppingCart) : ShoppingCart =
            { cart with Strategy = newStrategy }

        /// アイテムを追加
        let addItem (item: CartItem) (cart: ShoppingCart) : ShoppingCart =
            { cart with Items = item :: cart.Items }

    // ============================================
    // 3. 関数型アプローチ（高階関数版）
    // ============================================

    module FunctionalStrategy =
        /// 通常料金戦略
        let regularPricing: decimal -> decimal = id

        /// 割引料金戦略を作成
        let discountPricing (rate: decimal) : decimal -> decimal =
            fun amount -> amount * (1.0m - rate)

        /// 会員料金戦略を作成
        let memberPricing (level: MemberLevel) : decimal -> decimal =
            let rate =
                match level with
                | MemberLevel.Gold -> 0.20m
                | MemberLevel.Silver -> 0.15m
                | MemberLevel.Bronze -> 0.10m
            fun amount -> amount * (1.0m - rate)

        /// 大量購入戦略を作成
        let bulkPricing (threshold: decimal) (bulkDiscount: decimal) : decimal -> decimal =
            fun amount ->
                if amount >= threshold then
                    amount * (1.0m - bulkDiscount)
                else
                    amount

        /// 税金戦略を作成
        let taxStrategy (taxRate: decimal) : decimal -> decimal =
            fun amount -> amount * (1.0m + taxRate)

        /// 複数の戦略を合成
        let composeStrategies (strategies: (decimal -> decimal) list) : decimal -> decimal =
            fun amount -> List.fold (fun acc strategy -> strategy acc) amount strategies

        /// 条件付き戦略
        let conditionalStrategy
            (predicate: decimal -> bool)
            (thenStrategy: decimal -> decimal)
            (elseStrategy: decimal -> decimal)
            : decimal -> decimal =
            fun amount ->
                if predicate amount then
                    thenStrategy amount
                else
                    elseStrategy amount

        /// 料金戦略を適用
        let applyPricing (strategy: decimal -> decimal) (amount: decimal) : decimal =
            strategy amount

    // ============================================
    // 4. 配送料金戦略
    // ============================================

    [<RequireQualifiedAccess>]
    type ShippingStrategy =
        | Standard
        | Express
        | FreeShipping of minOrderAmount: decimal
        | DistanceBased of ratePerKm: decimal

    module ShippingStrategy =
        /// 配送料金を計算
        let calculateShipping (strategy: ShippingStrategy) (weight: decimal) (distance: decimal) (orderAmount: decimal) : decimal =
            match strategy with
            | ShippingStrategy.Standard ->
                weight * 10.0m + distance * 5.0m
            | ShippingStrategy.Express ->
                weight * 20.0m + distance * 15.0m
            | ShippingStrategy.FreeShipping minAmount ->
                if orderAmount >= minAmount then 0.0m
                else weight * 10.0m + distance * 5.0m
            | ShippingStrategy.DistanceBased ratePerKm ->
                distance * ratePerKm

    // ============================================
    // 5. 支払い方法戦略
    // ============================================

    [<RequireQualifiedAccess>]
    type PaymentStrategy =
        | Cash
        | CreditCard of fee: decimal
        | Points of pointsPerYen: int
        | Combined of primary: PaymentStrategy * secondary: PaymentStrategy * primaryAmount: decimal

    type PaymentResult =
        { AmountPaid: decimal
          Fee: decimal
          PointsUsed: int
          PointsEarned: int }

    module PaymentStrategy =
        /// 支払いを処理
        let rec processPayment (strategy: PaymentStrategy) (amount: decimal) (availablePoints: int) : PaymentResult =
            match strategy with
            | PaymentStrategy.Cash ->
                { AmountPaid = amount
                  Fee = 0.0m
                  PointsUsed = 0
                  PointsEarned = int (amount / 100.0m) }
            | PaymentStrategy.CreditCard fee ->
                let feeAmount = amount * fee
                { AmountPaid = amount + feeAmount
                  Fee = feeAmount
                  PointsUsed = 0
                  PointsEarned = int (amount / 100.0m) * 2 }
            | PaymentStrategy.Points pointsPerYen ->
                let pointsNeeded = int amount * pointsPerYen
                let pointsToUse = min pointsNeeded availablePoints
                let pointsCoverage = decimal pointsToUse / decimal pointsPerYen
                let remaining = amount - pointsCoverage
                { AmountPaid = remaining
                  Fee = 0.0m
                  PointsUsed = pointsToUse
                  PointsEarned = 0 }
            | PaymentStrategy.Combined(primary, secondary, primaryAmount) ->
                let primaryResult = processPayment primary (min primaryAmount amount) availablePoints
                let remainingAmount = amount - primaryAmount
                if remainingAmount > 0.0m then
                    let secondaryResult = processPayment secondary remainingAmount (availablePoints - primaryResult.PointsUsed)
                    { AmountPaid = primaryResult.AmountPaid + secondaryResult.AmountPaid
                      Fee = primaryResult.Fee + secondaryResult.Fee
                      PointsUsed = primaryResult.PointsUsed + secondaryResult.PointsUsed
                      PointsEarned = primaryResult.PointsEarned + secondaryResult.PointsEarned }
                else
                    primaryResult

    // ============================================
    // 6. ソート戦略
    // ============================================

    type Person =
        { Name: string
          Age: int
          Score: decimal }

    module SortingStrategy =
        /// 名前でソート
        let sortByName (people: Person list) : Person list =
            people |> List.sortBy (fun p -> p.Name)

        /// 年齢でソート
        let sortByAge (people: Person list) : Person list =
            people |> List.sortBy (fun p -> p.Age)

        /// スコアでソート（降順）
        let sortByScoreDesc (people: Person list) : Person list =
            people |> List.sortByDescending (fun p -> p.Score)

        /// カスタムソート戦略を適用
        let sortWith (sortFn: Person list -> Person list) (people: Person list) : Person list =
            sortFn people

    // ============================================
    // 7. バリデーション戦略
    // ============================================

    type ValidationResult =
        | Valid
        | Invalid of errors: string list

    module ValidationStrategy =
        /// バリデーション結果を合成
        let combine (result1: ValidationResult) (result2: ValidationResult) : ValidationResult =
            match result1, result2 with
            | Valid, Valid -> Valid
            | Valid, Invalid errors -> Invalid errors
            | Invalid errors, Valid -> Invalid errors
            | Invalid errors1, Invalid errors2 -> Invalid(errors1 @ errors2)

        /// 必須フィールドバリデーション
        let required (fieldName: string) (value: string) : ValidationResult =
            if System.String.IsNullOrWhiteSpace(value) then
                Invalid [ sprintf "%sは必須です" fieldName ]
            else
                Valid

        /// 最小長バリデーション
        let minLength (fieldName: string) (min: int) (value: string) : ValidationResult =
            if String.length value < min then
                Invalid [ sprintf "%sは%d文字以上必要です" fieldName min ]
            else
                Valid

        /// 最大長バリデーション
        let maxLength (fieldName: string) (max: int) (value: string) : ValidationResult =
            if String.length value > max then
                Invalid [ sprintf "%sは%d文字以下にしてください" fieldName max ]
            else
                Valid

        /// 範囲バリデーション
        let range (fieldName: string) (min: decimal) (max: decimal) (value: decimal) : ValidationResult =
            if value < min || value > max then
                Invalid [ sprintf "%sは%Mから%Mの範囲で指定してください" fieldName min max ]
            else
                Valid

        /// 複数のバリデーションを適用
        let validate (validators: ValidationResult list) : ValidationResult =
            validators |> List.fold combine Valid

    // ============================================
    // 8. ファイル圧縮戦略
    // ============================================

    [<RequireQualifiedAccess>]
    type CompressionStrategy =
        | NoCompression
        | Gzip
        | Zip
        | Lz4

    type CompressionResult =
        { OriginalSize: int64
          CompressedSize: int64
          Algorithm: string }

    module CompressionStrategy =
        /// 圧縮をシミュレート（実際の圧縮は行わない）
        let compress (strategy: CompressionStrategy) (data: byte array) : CompressionResult =
            let originalSize = int64 data.Length
            match strategy with
            | CompressionStrategy.NoCompression ->
                { OriginalSize = originalSize
                  CompressedSize = originalSize
                  Algorithm = "None" }
            | CompressionStrategy.Gzip ->
                { OriginalSize = originalSize
                  CompressedSize = int64 (float originalSize * 0.4)
                  Algorithm = "Gzip" }
            | CompressionStrategy.Zip ->
                { OriginalSize = originalSize
                  CompressedSize = int64 (float originalSize * 0.5)
                  Algorithm = "Zip" }
            | CompressionStrategy.Lz4 ->
                { OriginalSize = originalSize
                  CompressedSize = int64 (float originalSize * 0.6)
                  Algorithm = "Lz4" }

    // ============================================
    // 9. キャッシュ戦略
    // ============================================

    [<RequireQualifiedAccess>]
    type CacheStrategy =
        | NoCache
        | InMemory of maxSize: int
        | LRU of maxSize: int
        | TTL of seconds: int

    type Cache<'K, 'V when 'K: comparison> =
        { Strategy: CacheStrategy
          Data: Map<'K, 'V * System.DateTime>
          AccessOrder: 'K list }

    module CacheStrategy =
        /// 空のキャッシュを作成
        let empty (strategy: CacheStrategy) : Cache<'K, 'V> =
            { Strategy = strategy
              Data = Map.empty
              AccessOrder = [] }

        /// キャッシュに追加
        let put (key: 'K) (value: 'V) (cache: Cache<'K, 'V>) : Cache<'K, 'V> =
            let now = System.DateTime.UtcNow
            let newData = Map.add key (value, now) cache.Data
            let newOrder = key :: (cache.AccessOrder |> List.filter ((<>) key))
            match cache.Strategy with
            | CacheStrategy.NoCache -> cache
            | CacheStrategy.InMemory maxSize
            | CacheStrategy.LRU maxSize ->
                if Map.count newData > maxSize then
                    let keyToRemove = List.last newOrder
                    { cache with
                        Data = Map.remove keyToRemove newData
                        AccessOrder = newOrder |> List.take (List.length newOrder - 1) }
                else
                    { cache with Data = newData; AccessOrder = newOrder }
            | CacheStrategy.TTL _ ->
                { cache with Data = newData; AccessOrder = newOrder }

        /// キャッシュから取得
        let get (key: 'K) (cache: Cache<'K, 'V>) : 'V option =
            match cache.Strategy with
            | CacheStrategy.NoCache -> None
            | CacheStrategy.TTL seconds ->
                match Map.tryFind key cache.Data with
                | Some(value, timestamp) ->
                    let elapsed = (System.DateTime.UtcNow - timestamp).TotalSeconds
                    if elapsed < float seconds then Some value
                    else None
                | None -> None
            | _ ->
                Map.tryFind key cache.Data |> Option.map fst

    // ============================================
    // 10. ログ出力戦略
    // ============================================

    [<RequireQualifiedAccess>]
    type LogLevel =
        | Debug
        | Info
        | Warning
        | Error

    [<RequireQualifiedAccess>]
    type LoggingStrategy =
        | Console
        | File of path: string
        | Silent
        | Filtered of minLevel: LogLevel * inner: LoggingStrategy

    module LoggingStrategy =
        let private levelToInt level =
            match level with
            | LogLevel.Debug -> 0
            | LogLevel.Info -> 1
            | LogLevel.Warning -> 2
            | LogLevel.Error -> 3

        /// ログを出力
        let rec log (strategy: LoggingStrategy) (level: LogLevel) (message: string) : string option =
            match strategy with
            | LoggingStrategy.Silent -> None
            | LoggingStrategy.Console ->
                let formatted = sprintf "[%A] %s" level message
                printfn "%s" formatted
                Some formatted
            | LoggingStrategy.File _ ->
                let formatted = sprintf "[%s] [%A] %s" (System.DateTime.Now.ToString("o")) level message
                Some formatted
            | LoggingStrategy.Filtered(minLevel, inner) ->
                if levelToInt level >= levelToInt minLevel then
                    log inner level message
                else
                    None

// ============================================
// 第11章: Command パターン
// ============================================

module CommandPattern =

    // ============================================
    // 1. テキスト操作コマンド
    // ============================================

    /// テキストコマンド
    [<RequireQualifiedAccess>]
    type TextCommand =
        | Insert of position: int * text: string
        | Delete of startPos: int * endPos: int * deletedText: string
        | Replace of startPos: int * oldText: string * newText: string

    module TextCommand =
        /// コマンドを実行
        let execute (command: TextCommand) (document: string) : string =
            match command with
            | TextCommand.Insert(pos, text) ->
                let before = document.Substring(0, pos)
                let after = document.Substring(pos)
                before + text + after
            | TextCommand.Delete(startPos, endPos, _) ->
                let before = document.Substring(0, startPos)
                let after = document.Substring(endPos)
                before + after
            | TextCommand.Replace(startPos, oldText, newText) ->
                let before = document.Substring(0, startPos)
                let after = document.Substring(startPos + oldText.Length)
                before + newText + after

        /// コマンドを取り消し
        let undo (command: TextCommand) (document: string) : string =
            match command with
            | TextCommand.Insert(pos, text) ->
                let before = document.Substring(0, pos)
                let after = document.Substring(pos + text.Length)
                before + after
            | TextCommand.Delete(startPos, _, deletedText) ->
                let before = document.Substring(0, startPos)
                let after = document.Substring(startPos)
                before + deletedText + after
            | TextCommand.Replace(startPos, oldText, newText) ->
                let before = document.Substring(0, startPos)
                let after = document.Substring(startPos + newText.Length)
                before + oldText + after

    // ============================================
    // 2. キャンバス操作コマンド
    // ============================================

    type Shape =
        { Id: string
          ShapeType: string
          X: int
          Y: int
          Width: int
          Height: int }

    type Canvas = { Shapes: Shape list }

    /// キャンバスコマンド
    [<RequireQualifiedAccess>]
    type CanvasCommand =
        | AddShape of shape: Shape
        | RemoveShape of shapeId: string * removedShape: Shape option
        | MoveShape of shapeId: string * dx: int * dy: int
        | ResizeShape of shapeId: string * oldWidth: int * oldHeight: int * newWidth: int * newHeight: int

    module CanvasCommand =
        /// コマンドを実行
        let execute (command: CanvasCommand) (canvas: Canvas) : Canvas =
            match command with
            | CanvasCommand.AddShape shape ->
                { canvas with Shapes = shape :: canvas.Shapes }
            | CanvasCommand.RemoveShape(shapeId, _) ->
                { canvas with Shapes = canvas.Shapes |> List.filter (fun s -> s.Id <> shapeId) }
            | CanvasCommand.MoveShape(shapeId, dx, dy) ->
                { canvas with
                    Shapes =
                        canvas.Shapes
                        |> List.map (fun s ->
                            if s.Id = shapeId then
                                { s with X = s.X + dx; Y = s.Y + dy }
                            else
                                s) }
            | CanvasCommand.ResizeShape(shapeId, _, _, newWidth, newHeight) ->
                { canvas with
                    Shapes =
                        canvas.Shapes
                        |> List.map (fun s ->
                            if s.Id = shapeId then
                                { s with Width = newWidth; Height = newHeight }
                            else
                                s) }

        /// コマンドを取り消し
        let undo (command: CanvasCommand) (canvas: Canvas) : Canvas =
            match command with
            | CanvasCommand.AddShape shape ->
                { canvas with Shapes = canvas.Shapes |> List.filter (fun s -> s.Id <> shape.Id) }
            | CanvasCommand.RemoveShape(_, removedShape) ->
                match removedShape with
                | Some shape -> { canvas with Shapes = shape :: canvas.Shapes }
                | None -> canvas
            | CanvasCommand.MoveShape(shapeId, dx, dy) ->
                { canvas with
                    Shapes =
                        canvas.Shapes
                        |> List.map (fun s ->
                            if s.Id = shapeId then
                                { s with X = s.X - dx; Y = s.Y - dy }
                            else
                                s) }
            | CanvasCommand.ResizeShape(shapeId, oldWidth, oldHeight, _, _) ->
                { canvas with
                    Shapes =
                        canvas.Shapes
                        |> List.map (fun s ->
                            if s.Id = shapeId then
                                { s with Width = oldWidth; Height = oldHeight }
                            else
                                s) }

    // ============================================
    // 3. コマンド実行器（汎用）
    // ============================================

    type CommandExecutor<'TState, 'TCommand> =
        { State: 'TState
          UndoStack: 'TCommand list
          RedoStack: 'TCommand list
          ExecuteFn: 'TCommand -> 'TState -> 'TState
          UndoFn: 'TCommand -> 'TState -> 'TState }

    module CommandExecutor =
        /// 実行器を作成
        let create
            (initialState: 'TState)
            (executeFn: 'TCommand -> 'TState -> 'TState)
            (undoFn: 'TCommand -> 'TState -> 'TState)
            : CommandExecutor<'TState, 'TCommand> =
            { State = initialState
              UndoStack = []
              RedoStack = []
              ExecuteFn = executeFn
              UndoFn = undoFn }

        /// コマンドを実行
        let execute (command: 'TCommand) (executor: CommandExecutor<'TState, 'TCommand>) : CommandExecutor<'TState, 'TCommand> =
            let newState = executor.ExecuteFn command executor.State
            { executor with
                State = newState
                UndoStack = command :: executor.UndoStack
                RedoStack = [] }

        /// アンドゥ
        let undo (executor: CommandExecutor<'TState, 'TCommand>) : CommandExecutor<'TState, 'TCommand> =
            match executor.UndoStack with
            | [] -> executor
            | command :: rest ->
                let newState = executor.UndoFn command executor.State
                { executor with
                    State = newState
                    UndoStack = rest
                    RedoStack = command :: executor.RedoStack }

        /// リドゥ
        let redo (executor: CommandExecutor<'TState, 'TCommand>) : CommandExecutor<'TState, 'TCommand> =
            match executor.RedoStack with
            | [] -> executor
            | command :: rest ->
                let newState = executor.ExecuteFn command executor.State
                { executor with
                    State = newState
                    UndoStack = command :: executor.UndoStack
                    RedoStack = rest }

        /// アンドゥ可能かどうか
        let canUndo (executor: CommandExecutor<'TState, 'TCommand>) : bool =
            not (List.isEmpty executor.UndoStack)

        /// リドゥ可能かどうか
        let canRedo (executor: CommandExecutor<'TState, 'TCommand>) : bool =
            not (List.isEmpty executor.RedoStack)

        /// 現在の状態を取得
        let getState (executor: CommandExecutor<'TState, 'TCommand>) : 'TState =
            executor.State

    // ============================================
    // 4. テキストエディタ
    // ============================================

    module TextEditor =
        /// テキストエディタを作成
        let create (initialText: string) : CommandExecutor<string, TextCommand> =
            CommandExecutor.create initialText TextCommand.execute TextCommand.undo

    // ============================================
    // 5. キャンバスエディタ
    // ============================================

    module CanvasEditor =
        /// キャンバスエディタを作成
        let create () : CommandExecutor<Canvas, CanvasCommand> =
            CommandExecutor.create { Shapes = [] } CanvasCommand.execute CanvasCommand.undo

    // ============================================
    // 6. マクロコマンド
    // ============================================

    type MacroCommand<'TCommand> = { Commands: 'TCommand list }

    module MacroCommand =
        /// マクロコマンドを作成
        let create (commands: 'TCommand list) : MacroCommand<'TCommand> =
            { Commands = commands }

        /// マクロコマンドを実行
        let execute (executeFn: 'TCommand -> 'TState -> 'TState) (macro: MacroCommand<'TCommand>) (state: 'TState) : 'TState =
            List.fold (fun s cmd -> executeFn cmd s) state macro.Commands

        /// マクロコマンドを取り消し
        let undo (undoFn: 'TCommand -> 'TState -> 'TState) (macro: MacroCommand<'TCommand>) (state: 'TState) : 'TState =
            List.fold (fun s cmd -> undoFn cmd s) state (List.rev macro.Commands)

    // ============================================
    // 7. バッチ実行
    // ============================================

    module BatchExecutor =
        /// 複数のコマンドをバッチ実行
        let executeBatch (commands: 'TCommand list) (executor: CommandExecutor<'TState, 'TCommand>) : CommandExecutor<'TState, 'TCommand> =
            List.fold (fun exec cmd -> CommandExecutor.execute cmd exec) executor commands

        /// すべてのコマンドを取り消し
        let undoAll (executor: CommandExecutor<'TState, 'TCommand>) : CommandExecutor<'TState, 'TCommand> =
            let rec loop exec =
                if CommandExecutor.canUndo exec then
                    loop (CommandExecutor.undo exec)
                else
                    exec
            loop executor

    // ============================================
    // 8. コマンドキュー
    // ============================================

    type CommandQueue<'TCommand> = { Queue: 'TCommand list }

    module CommandQueue =
        /// 空のキューを作成
        let empty: CommandQueue<'TCommand> = { Queue = [] }

        /// コマンドをキューに追加
        let enqueue (command: 'TCommand) (queue: CommandQueue<'TCommand>) : CommandQueue<'TCommand> =
            { Queue = queue.Queue @ [ command ] }

        /// コマンドをデキュー
        let dequeue (queue: CommandQueue<'TCommand>) : ('TCommand option * CommandQueue<'TCommand>) =
            match queue.Queue with
            | [] -> (None, queue)
            | head :: tail -> (Some head, { Queue = tail })

        /// キューが空かどうか
        let isEmpty (queue: CommandQueue<'TCommand>) : bool =
            List.isEmpty queue.Queue

        /// キューのサイズ
        let size (queue: CommandQueue<'TCommand>) : int =
            List.length queue.Queue

        /// すべてのコマンドを実行
        let executeAll (executor: CommandExecutor<'TState, 'TCommand>) (queue: CommandQueue<'TCommand>) : CommandExecutor<'TState, 'TCommand> =
            List.fold (fun exec cmd -> CommandExecutor.execute cmd exec) executor queue.Queue

    // ============================================
    // 9. トランザクションコマンド
    // ============================================

    type TransactionResult<'TState> =
        | Committed of 'TState
        | RolledBack of 'TState * error: string

    module TransactionCommand =
        /// トランザクションとして実行
        let executeTransaction
            (commands: 'TCommand list)
            (executeFn: 'TCommand -> 'TState -> Result<'TState, string>)
            (state: 'TState)
            : TransactionResult<'TState> =
            let rec loop remaining currentState =
                match remaining with
                | [] -> Committed currentState
                | cmd :: rest ->
                    match executeFn cmd currentState with
                    | Ok newState -> loop rest newState
                    | Error err -> RolledBack(state, err)
            loop commands state

    // ============================================
    // 10. 計算機コマンド
    // ============================================

    [<RequireQualifiedAccess>]
    type CalculatorCommand =
        | Add of value: decimal
        | Subtract of value: decimal
        | Multiply of value: decimal
        | Divide of value: decimal
        | Clear

    module CalculatorCommand =
        let execute (command: CalculatorCommand) (value: decimal) : decimal =
            match command with
            | CalculatorCommand.Add v -> value + v
            | CalculatorCommand.Subtract v -> value - v
            | CalculatorCommand.Multiply v -> value * v
            | CalculatorCommand.Divide v -> if v <> 0.0m then value / v else value
            | CalculatorCommand.Clear -> 0.0m

        let undo (command: CalculatorCommand) (previousValue: decimal) (currentValue: decimal) : decimal =
            match command with
            | CalculatorCommand.Add v -> currentValue - v
            | CalculatorCommand.Subtract v -> currentValue + v
            | CalculatorCommand.Multiply v -> if v <> 0.0m then currentValue / v else currentValue
            | CalculatorCommand.Divide v -> currentValue * v
            | CalculatorCommand.Clear -> previousValue

    type CalculatorState =
        { Value: decimal
          History: (CalculatorCommand * decimal) list }

    module Calculator =
        let create () : CalculatorState =
            { Value = 0.0m; History = [] }

        let execute (command: CalculatorCommand) (state: CalculatorState) : CalculatorState =
            let previousValue = state.Value
            let newValue = CalculatorCommand.execute command state.Value
            { Value = newValue
              History = (command, previousValue) :: state.History }

        let undo (state: CalculatorState) : CalculatorState =
            match state.History with
            | [] -> state
            | (_, previousValue) :: rest ->
                { Value = previousValue; History = rest }

// ============================================
// 第12章: Visitor パターン
// ============================================

module VisitorPattern =

    // ============================================
    // 1. 図形の定義（Element）
    // ============================================

    /// 図形の判別共用体
    [<RequireQualifiedAccess>]
    type Shape =
        | Circle of center: (float * float) * radius: float
        | Square of topLeft: (float * float) * side: float
        | Rectangle of topLeft: (float * float) * width: float * height: float
        | Triangle of p1: (float * float) * p2: (float * float) * p3: (float * float)

    module Shape =
        /// 図形を移動
        let translate (dx: float) (dy: float) (shape: Shape) : Shape =
            match shape with
            | Shape.Circle((x, y), r) -> Shape.Circle((x + dx, y + dy), r)
            | Shape.Square((x, y), s) -> Shape.Square((x + dx, y + dy), s)
            | Shape.Rectangle((x, y), w, h) -> Shape.Rectangle((x + dx, y + dy), w, h)
            | Shape.Triangle((x1, y1), (x2, y2), (x3, y3)) ->
                Shape.Triangle((x1 + dx, y1 + dy), (x2 + dx, y2 + dy), (x3 + dx, y3 + dy))

        /// 図形を拡大/縮小
        let scale (factor: float) (shape: Shape) : Shape =
            match shape with
            | Shape.Circle(c, r) -> Shape.Circle(c, r * factor)
            | Shape.Square(tl, s) -> Shape.Square(tl, s * factor)
            | Shape.Rectangle(tl, w, h) -> Shape.Rectangle(tl, w * factor, h * factor)
            | Shape.Triangle(p1, p2, p3) ->
                // 重心を基準に拡大
                let cx = (fst p1 + fst p2 + fst p3) / 3.0
                let cy = (snd p1 + snd p2 + snd p3) / 3.0
                let scalePoint (x, y) =
                    (cx + (x - cx) * factor, cy + (y - cy) * factor)
                Shape.Triangle(scalePoint p1, scalePoint p2, scalePoint p3)

    // ============================================
    // 2. Visitor: JSON 変換
    // ============================================

    module JsonVisitor =
        /// 図形を JSON 文字列に変換
        let toJson (shape: Shape) : string =
            match shape with
            | Shape.Circle((x, y), r) ->
                sprintf """{"type":"circle","center":[%g,%g],"radius":%g}""" x y r
            | Shape.Square((x, y), s) ->
                sprintf """{"type":"square","topLeft":[%g,%g],"side":%g}""" x y s
            | Shape.Rectangle((x, y), w, h) ->
                sprintf """{"type":"rectangle","topLeft":[%g,%g],"width":%g,"height":%g}""" x y w h
            | Shape.Triangle((x1, y1), (x2, y2), (x3, y3)) ->
                sprintf """{"type":"triangle","points":[[%g,%g],[%g,%g],[%g,%g]]}""" x1 y1 x2 y2 x3 y3

        /// 複数の図形を JSON 配列に変換
        let shapesToJson (shapes: Shape list) : string =
            let jsonShapes = shapes |> List.map toJson |> String.concat ","
            sprintf "[%s]" jsonShapes

    // ============================================
    // 3. Visitor: XML 変換
    // ============================================

    module XmlVisitor =
        /// 図形を XML 文字列に変換
        let toXml (shape: Shape) : string =
            match shape with
            | Shape.Circle((x, y), r) ->
                sprintf """<circle><center x="%g" y="%g"/><radius>%g</radius></circle>""" x y r
            | Shape.Square((x, y), s) ->
                sprintf """<square><topLeft x="%g" y="%g"/><side>%g</side></square>""" x y s
            | Shape.Rectangle((x, y), w, h) ->
                sprintf """<rectangle><topLeft x="%g" y="%g"/><width>%g</width><height>%g</height></rectangle>""" x y w h
            | Shape.Triangle((x1, y1), (x2, y2), (x3, y3)) ->
                sprintf """<triangle><p1 x="%g" y="%g"/><p2 x="%g" y="%g"/><p3 x="%g" y="%g"/></triangle>""" x1 y1 x2 y2 x3 y3

        /// 複数の図形を XML に変換
        let shapesToXml (shapes: Shape list) : string =
            let xmlShapes = shapes |> List.map toXml |> String.concat ""
            sprintf "<shapes>%s</shapes>" xmlShapes

    // ============================================
    // 4. Visitor: 面積計算
    // ============================================

    module AreaVisitor =
        /// 図形の面積を計算
        let calculateArea (shape: Shape) : float =
            match shape with
            | Shape.Circle(_, r) -> System.Math.PI * r * r
            | Shape.Square(_, s) -> s * s
            | Shape.Rectangle(_, w, h) -> w * h
            | Shape.Triangle((x1, y1), (x2, y2), (x3, y3)) ->
                // ヘロンの公式
                let a = sqrt((x2 - x1) ** 2.0 + (y2 - y1) ** 2.0)
                let b = sqrt((x3 - x2) ** 2.0 + (y3 - y2) ** 2.0)
                let c = sqrt((x1 - x3) ** 2.0 + (y1 - y3) ** 2.0)
                let s = (a + b + c) / 2.0
                sqrt(s * (s - a) * (s - b) * (s - c))

        /// 複数の図形の合計面積を計算
        let totalArea (shapes: Shape list) : float =
            shapes |> List.sumBy calculateArea

    // ============================================
    // 5. Visitor: 周囲長計算
    // ============================================

    module PerimeterVisitor =
        /// 図形の周囲長を計算
        let calculatePerimeter (shape: Shape) : float =
            match shape with
            | Shape.Circle(_, r) -> 2.0 * System.Math.PI * r
            | Shape.Square(_, s) -> 4.0 * s
            | Shape.Rectangle(_, w, h) -> 2.0 * (w + h)
            | Shape.Triangle((x1, y1), (x2, y2), (x3, y3)) ->
                let a = sqrt((x2 - x1) ** 2.0 + (y2 - y1) ** 2.0)
                let b = sqrt((x3 - x2) ** 2.0 + (y3 - y2) ** 2.0)
                let c = sqrt((x1 - x3) ** 2.0 + (y1 - y3) ** 2.0)
                a + b + c

        /// 複数の図形の合計周囲長を計算
        let totalPerimeter (shapes: Shape list) : float =
            shapes |> List.sumBy calculatePerimeter

    // ============================================
    // 6. Visitor: 描画コマンド生成
    // ============================================

    type DrawCommand =
        { Command: string
          Parameters: Map<string, obj> }

    module DrawingVisitor =
        /// 図形の描画コマンドを生成
        let toDrawCommand (shape: Shape) : DrawCommand =
            match shape with
            | Shape.Circle((x, y), r) ->
                { Command = "drawCircle"
                  Parameters = Map.ofList [ ("cx", box x); ("cy", box y); ("r", box r) ] }
            | Shape.Square((x, y), s) ->
                { Command = "drawRect"
                  Parameters = Map.ofList [ ("x", box x); ("y", box y); ("width", box s); ("height", box s) ] }
            | Shape.Rectangle((x, y), w, h) ->
                { Command = "drawRect"
                  Parameters = Map.ofList [ ("x", box x); ("y", box y); ("width", box w); ("height", box h) ] }
            | Shape.Triangle((x1, y1), (x2, y2), (x3, y3)) ->
                { Command = "drawPolygon"
                  Parameters = Map.ofList [ ("points", box [| (x1, y1); (x2, y2); (x3, y3) |]) ] }

        /// 複数の図形の描画コマンドを生成
        let toDrawCommands (shapes: Shape list) : DrawCommand list =
            shapes |> List.map toDrawCommand

    // ============================================
    // 7. Visitor: バウンディングボックス計算
    // ============================================

    type BoundingBox =
        { MinX: float
          MinY: float
          MaxX: float
          MaxY: float }

    module BoundingBoxVisitor =
        /// 図形のバウンディングボックスを計算
        let calculateBoundingBox (shape: Shape) : BoundingBox =
            match shape with
            | Shape.Circle((x, y), r) ->
                { MinX = x - r; MinY = y - r; MaxX = x + r; MaxY = y + r }
            | Shape.Square((x, y), s) ->
                { MinX = x; MinY = y; MaxX = x + s; MaxY = y + s }
            | Shape.Rectangle((x, y), w, h) ->
                { MinX = x; MinY = y; MaxX = x + w; MaxY = y + h }
            | Shape.Triangle((x1, y1), (x2, y2), (x3, y3)) ->
                { MinX = min (min x1 x2) x3
                  MinY = min (min y1 y2) y3
                  MaxX = max (max x1 x2) x3
                  MaxY = max (max y1 y2) y3 }

        /// 複数の図形の統合バウンディングボックスを計算
        let combinedBoundingBox (shapes: Shape list) : BoundingBox option =
            match shapes with
            | [] -> None
            | shapes ->
                let boxes = shapes |> List.map calculateBoundingBox
                Some
                    { MinX = boxes |> List.map (fun b -> b.MinX) |> List.min
                      MinY = boxes |> List.map (fun b -> b.MinY) |> List.min
                      MaxX = boxes |> List.map (fun b -> b.MaxX) |> List.max
                      MaxY = boxes |> List.map (fun b -> b.MaxY) |> List.max }

    // ============================================
    // 8. 汎用 Visitor 関数
    // ============================================

    module GenericVisitor =
        /// 汎用的な visitor 関数
        let visit
            (onCircle: (float * float) -> float -> 'T)
            (onSquare: (float * float) -> float -> 'T)
            (onRectangle: (float * float) -> float -> float -> 'T)
            (onTriangle: (float * float) -> (float * float) -> (float * float) -> 'T)
            (shape: Shape)
            : 'T =
            match shape with
            | Shape.Circle(c, r) -> onCircle c r
            | Shape.Square(tl, s) -> onSquare tl s
            | Shape.Rectangle(tl, w, h) -> onRectangle tl w h
            | Shape.Triangle(p1, p2, p3) -> onTriangle p1 p2 p3

        /// 複数の図形に visitor を適用
        let visitAll
            (onCircle: (float * float) -> float -> 'T)
            (onSquare: (float * float) -> float -> 'T)
            (onRectangle: (float * float) -> float -> float -> 'T)
            (onTriangle: (float * float) -> (float * float) -> (float * float) -> 'T)
            (shapes: Shape list)
            : 'T list =
            shapes |> List.map (visit onCircle onSquare onRectangle onTriangle)

    // ============================================
    // 9. Expression Visitor（式の評価）
    // ============================================

    [<RequireQualifiedAccess>]
    type Expr =
        | Num of float
        | Add of Expr * Expr
        | Sub of Expr * Expr
        | Mul of Expr * Expr
        | Div of Expr * Expr
        | Neg of Expr
        | Var of string

    module ExprVisitor =
        /// 式を評価
        let rec evaluate (env: Map<string, float>) (expr: Expr) : float =
            match expr with
            | Expr.Num n -> n
            | Expr.Add(a, b) -> evaluate env a + evaluate env b
            | Expr.Sub(a, b) -> evaluate env a - evaluate env b
            | Expr.Mul(a, b) -> evaluate env a * evaluate env b
            | Expr.Div(a, b) -> evaluate env a / evaluate env b
            | Expr.Neg e -> -(evaluate env e)
            | Expr.Var name -> Map.tryFind name env |> Option.defaultValue 0.0

        /// 式を文字列に変換
        let rec toString (expr: Expr) : string =
            match expr with
            | Expr.Num n -> sprintf "%g" n
            | Expr.Add(a, b) -> sprintf "(%s + %s)" (toString a) (toString b)
            | Expr.Sub(a, b) -> sprintf "(%s - %s)" (toString a) (toString b)
            | Expr.Mul(a, b) -> sprintf "(%s * %s)" (toString a) (toString b)
            | Expr.Div(a, b) -> sprintf "(%s / %s)" (toString a) (toString b)
            | Expr.Neg e -> sprintf "-%s" (toString e)
            | Expr.Var name -> name

        /// 式を簡約
        let rec simplify (expr: Expr) : Expr =
            match expr with
            | Expr.Add(Expr.Num 0.0, e) -> simplify e
            | Expr.Add(e, Expr.Num 0.0) -> simplify e
            | Expr.Mul(Expr.Num 1.0, e) -> simplify e
            | Expr.Mul(e, Expr.Num 1.0) -> simplify e
            | Expr.Mul(Expr.Num 0.0, _) -> Expr.Num 0.0
            | Expr.Mul(_, Expr.Num 0.0) -> Expr.Num 0.0
            | Expr.Add(a, b) -> Expr.Add(simplify a, simplify b)
            | Expr.Sub(a, b) -> Expr.Sub(simplify a, simplify b)
            | Expr.Mul(a, b) -> Expr.Mul(simplify a, simplify b)
            | Expr.Div(a, b) -> Expr.Div(simplify a, simplify b)
            | Expr.Neg(Expr.Neg e) -> simplify e
            | Expr.Neg e -> Expr.Neg(simplify e)
            | _ -> expr

        /// 式に含まれる変数を抽出
        let rec variables (expr: Expr) : string Set =
            match expr with
            | Expr.Num _ -> Set.empty
            | Expr.Var name -> Set.singleton name
            | Expr.Add(a, b) | Expr.Sub(a, b) | Expr.Mul(a, b) | Expr.Div(a, b) ->
                Set.union (variables a) (variables b)
            | Expr.Neg e -> variables e

    // ============================================
    // 10. Tree Visitor
    // ============================================

    type Tree<'T> =
        | Leaf of 'T
        | Node of Tree<'T> list

    module TreeVisitor =
        /// ツリーの全ての葉の値を収集
        let rec collectLeaves (tree: Tree<'T>) : 'T list =
            match tree with
            | Leaf v -> [ v ]
            | Node children -> children |> List.collect collectLeaves

        /// ツリーの深さを計算
        let rec depth (tree: Tree<'T>) : int =
            match tree with
            | Leaf _ -> 1
            | Node [] -> 1
            | Node children -> 1 + (children |> List.map depth |> List.max)

        /// ツリーのノード数を計算
        let rec countNodes (tree: Tree<'T>) : int =
            match tree with
            | Leaf _ -> 1
            | Node children -> 1 + (children |> List.sumBy countNodes)

        /// ツリーを変換
        let rec map (f: 'T -> 'U) (tree: Tree<'T>) : Tree<'U> =
            match tree with
            | Leaf v -> Leaf(f v)
            | Node children -> Node(children |> List.map (map f))

        /// ツリーをフォールド
        let rec fold (leafFn: 'T -> 'Acc) (nodeFn: 'Acc list -> 'Acc) (tree: Tree<'T>) : 'Acc =
            match tree with
            | Leaf v -> leafFn v
            | Node children -> nodeFn (children |> List.map (fold leafFn nodeFn))

// ============================================
// 第13章: Abstract Factory パターン
// ============================================

module AbstractFactoryPattern =

    // ============================================
    // 1. 図形ファクトリ
    // ============================================

    /// スタイル情報
    type ShapeStyle =
        { OutlineColor: string option
          OutlineWidth: float option
          FillColor: string option
          Opacity: float option }

    module ShapeStyle =
        let empty =
            { OutlineColor = None
              OutlineWidth = None
              FillColor = None
              Opacity = None }

        let withOutline color width style =
            { style with OutlineColor = Some color; OutlineWidth = Some width }

        let withFill color style =
            { style with FillColor = Some color }

        let withOpacity opacity style =
            { style with Opacity = Some opacity }

    /// スタイル付き図形
    type StyledShape =
        { Shape: VisitorPattern.Shape
          Style: ShapeStyle }

    /// 図形ファクトリの型
    [<RequireQualifiedAccess>]
    type ShapeFactory =
        | Standard
        | Outlined of color: string * width: float
        | Filled of color: string
        | Custom of style: ShapeStyle

    module ShapeFactory =
        /// 円を作成
        let createCircle (factory: ShapeFactory) (center: float * float) (radius: float) : StyledShape =
            let shape = VisitorPattern.Shape.Circle(center, radius)
            let style =
                match factory with
                | ShapeFactory.Standard -> ShapeStyle.empty
                | ShapeFactory.Outlined(color, width) -> ShapeStyle.empty |> ShapeStyle.withOutline color width
                | ShapeFactory.Filled color -> ShapeStyle.empty |> ShapeStyle.withFill color
                | ShapeFactory.Custom style -> style
            { Shape = shape; Style = style }

        /// 正方形を作成
        let createSquare (factory: ShapeFactory) (topLeft: float * float) (side: float) : StyledShape =
            let shape = VisitorPattern.Shape.Square(topLeft, side)
            let style =
                match factory with
                | ShapeFactory.Standard -> ShapeStyle.empty
                | ShapeFactory.Outlined(color, width) -> ShapeStyle.empty |> ShapeStyle.withOutline color width
                | ShapeFactory.Filled color -> ShapeStyle.empty |> ShapeStyle.withFill color
                | ShapeFactory.Custom style -> style
            { Shape = shape; Style = style }

        /// 長方形を作成
        let createRectangle (factory: ShapeFactory) (topLeft: float * float) (width: float) (height: float) : StyledShape =
            let shape = VisitorPattern.Shape.Rectangle(topLeft, width, height)
            let style =
                match factory with
                | ShapeFactory.Standard -> ShapeStyle.empty
                | ShapeFactory.Outlined(color, width) -> ShapeStyle.empty |> ShapeStyle.withOutline color width
                | ShapeFactory.Filled color -> ShapeStyle.empty |> ShapeStyle.withFill color
                | ShapeFactory.Custom s -> s
            { Shape = shape; Style = style }

    // ============================================
    // 2. UI ファクトリ
    // ============================================

    /// ボタンコンポーネント
    type Button =
        { Label: string
          Platform: string
          Style: Map<string, string> }

    /// テキストフィールドコンポーネント
    type TextField =
        { Placeholder: string
          Platform: string
          Style: Map<string, string> }

    /// チェックボックスコンポーネント
    type Checkbox =
        { Label: string
          Checked: bool
          Platform: string
          Style: Map<string, string> }

    /// UI ファクトリの型
    [<RequireQualifiedAccess>]
    type UIFactory =
        | Windows
        | MacOS
        | Linux
        | Web

    module UIFactory =
        let private platformName = function
            | UIFactory.Windows -> "windows"
            | UIFactory.MacOS -> "macos"
            | UIFactory.Linux -> "linux"
            | UIFactory.Web -> "web"

        let private buttonStyle = function
            | UIFactory.Windows -> Map.ofList [ ("border", "1px solid gray"); ("padding", "5px 10px") ]
            | UIFactory.MacOS -> Map.ofList [ ("border", "none"); ("borderRadius", "5px"); ("padding", "8px 16px") ]
            | UIFactory.Linux -> Map.ofList [ ("border", "2px solid black"); ("padding", "4px 8px") ]
            | UIFactory.Web -> Map.ofList [ ("border", "1px solid #ccc"); ("borderRadius", "3px"); ("padding", "6px 12px") ]

        let private textFieldStyle = function
            | UIFactory.Windows -> Map.ofList [ ("border", "1px solid gray"); ("height", "22px") ]
            | UIFactory.MacOS -> Map.ofList [ ("border", "none"); ("borderRadius", "4px"); ("height", "24px") ]
            | UIFactory.Linux -> Map.ofList [ ("border", "2px solid black"); ("height", "20px") ]
            | UIFactory.Web -> Map.ofList [ ("border", "1px solid #ccc"); ("borderRadius", "3px"); ("height", "30px") ]

        /// ボタンを作成
        let createButton (factory: UIFactory) (label: string) : Button =
            { Label = label
              Platform = platformName factory
              Style = buttonStyle factory }

        /// テキストフィールドを作成
        let createTextField (factory: UIFactory) (placeholder: string) : TextField =
            { Placeholder = placeholder
              Platform = platformName factory
              Style = textFieldStyle factory }

        /// チェックボックスを作成
        let createCheckbox (factory: UIFactory) (label: string) (checked': bool) : Checkbox =
            { Label = label
              Checked = checked'
              Platform = platformName factory
              Style = Map.empty }

    // ============================================
    // 3. データベース接続ファクトリ
    // ============================================

    type DatabaseConnection =
        { ConnectionString: string
          DatabaseType: string
          MaxPoolSize: int }

    type DatabaseCommand =
        { Query: string
          DatabaseType: string
          Parameters: Map<string, obj> }

    [<RequireQualifiedAccess>]
    type DatabaseFactory =
        | SqlServer of connectionString: string
        | PostgreSQL of connectionString: string
        | MySQL of connectionString: string
        | SQLite of filePath: string

    module DatabaseFactory =
        /// 接続を作成
        let createConnection (factory: DatabaseFactory) : DatabaseConnection =
            match factory with
            | DatabaseFactory.SqlServer connStr ->
                { ConnectionString = connStr
                  DatabaseType = "SqlServer"
                  MaxPoolSize = 100 }
            | DatabaseFactory.PostgreSQL connStr ->
                { ConnectionString = connStr
                  DatabaseType = "PostgreSQL"
                  MaxPoolSize = 50 }
            | DatabaseFactory.MySQL connStr ->
                { ConnectionString = connStr
                  DatabaseType = "MySQL"
                  MaxPoolSize = 50 }
            | DatabaseFactory.SQLite path ->
                { ConnectionString = sprintf "Data Source=%s" path
                  DatabaseType = "SQLite"
                  MaxPoolSize = 1 }

        /// コマンドを作成
        let createCommand (factory: DatabaseFactory) (query: string) (parameters: Map<string, obj>) : DatabaseCommand =
            let dbType =
                match factory with
                | DatabaseFactory.SqlServer _ -> "SqlServer"
                | DatabaseFactory.PostgreSQL _ -> "PostgreSQL"
                | DatabaseFactory.MySQL _ -> "MySQL"
                | DatabaseFactory.SQLite _ -> "SQLite"
            { Query = query
              DatabaseType = dbType
              Parameters = parameters }

    // ============================================
    // 4. ドキュメントファクトリ
    // ============================================

    type DocumentParagraph = { Text: string; Style: Map<string, string> }
    type DocumentHeading = { Level: int; Text: string }
    type DocumentList = { Items: string list; Ordered: bool }

    [<RequireQualifiedAccess>]
    type DocumentFactory =
        | HTML
        | Markdown
        | PlainText

    module DocumentFactory =
        /// 段落を作成
        let createParagraph (factory: DocumentFactory) (text: string) : string =
            match factory with
            | DocumentFactory.HTML -> sprintf "<p>%s</p>" text
            | DocumentFactory.Markdown -> text + "\n"
            | DocumentFactory.PlainText -> text + "\n"

        /// 見出しを作成
        let createHeading (factory: DocumentFactory) (level: int) (text: string) : string =
            match factory with
            | DocumentFactory.HTML -> sprintf "<h%d>%s</h%d>" level text level
            | DocumentFactory.Markdown -> String.replicate level "#" + " " + text + "\n"
            | DocumentFactory.PlainText -> text.ToUpper() + "\n" + String.replicate (String.length text) "=" + "\n"

        /// リストを作成
        let createList (factory: DocumentFactory) (items: string list) (ordered: bool) : string =
            match factory with
            | DocumentFactory.HTML ->
                let tag = if ordered then "ol" else "ul"
                let itemsHtml = items |> List.map (sprintf "<li>%s</li>") |> String.concat ""
                sprintf "<%s>%s</%s>" tag itemsHtml tag
            | DocumentFactory.Markdown ->
                items
                |> List.mapi (fun i item ->
                    if ordered then sprintf "%d. %s" (i + 1) item
                    else sprintf "- %s" item)
                |> String.concat "\n"
            | DocumentFactory.PlainText ->
                items
                |> List.mapi (fun i item ->
                    if ordered then sprintf "%d. %s" (i + 1) item
                    else sprintf "* %s" item)
                |> String.concat "\n"

    // ============================================
    // 5. テーマファクトリ
    // ============================================

    type ThemeColors =
        { Primary: string
          Secondary: string
          Background: string
          Text: string
          Error: string
          Success: string }

    type ThemeFonts =
        { Heading: string
          Body: string
          Monospace: string }

    type Theme =
        { Name: string
          Colors: ThemeColors
          Fonts: ThemeFonts }

    [<RequireQualifiedAccess>]
    type ThemeFactory =
        | Light
        | Dark
        | HighContrast

    module ThemeFactory =
        /// テーマを作成
        let createTheme (factory: ThemeFactory) : Theme =
            match factory with
            | ThemeFactory.Light ->
                { Name = "Light"
                  Colors =
                    { Primary = "#007bff"
                      Secondary = "#6c757d"
                      Background = "#ffffff"
                      Text = "#212529"
                      Error = "#dc3545"
                      Success = "#28a745" }
                  Fonts =
                    { Heading = "Arial, sans-serif"
                      Body = "Helvetica, sans-serif"
                      Monospace = "Courier New, monospace" } }
            | ThemeFactory.Dark ->
                { Name = "Dark"
                  Colors =
                    { Primary = "#0d6efd"
                      Secondary = "#adb5bd"
                      Background = "#212529"
                      Text = "#f8f9fa"
                      Error = "#dc3545"
                      Success = "#198754" }
                  Fonts =
                    { Heading = "Arial, sans-serif"
                      Body = "Helvetica, sans-serif"
                      Monospace = "Courier New, monospace" } }
            | ThemeFactory.HighContrast ->
                { Name = "HighContrast"
                  Colors =
                    { Primary = "#ffff00"
                      Secondary = "#00ffff"
                      Background = "#000000"
                      Text = "#ffffff"
                      Error = "#ff0000"
                      Success = "#00ff00" }
                  Fonts =
                    { Heading = "Arial Black, sans-serif"
                      Body = "Arial, sans-serif"
                      Monospace = "Courier New, monospace" } }

    // ============================================
    // 6. 汎用ファクトリ関数
    // ============================================

    module GenericFactory =
        /// 汎用ファクトリ型
        type Factory<'TConfig, 'TProduct> = 'TConfig -> 'TProduct

        /// ファクトリを作成
        let create (config: 'TConfig) (factory: Factory<'TConfig, 'TProduct>) : 'TProduct =
            factory config

        /// ファクトリを合成
        let compose
            (factory1: Factory<'TConfig, 'TIntermediate>)
            (factory2: Factory<'TIntermediate, 'TProduct>)
            : Factory<'TConfig, 'TProduct> =
            fun config -> config |> factory1 |> factory2

        /// 条件付きファクトリ
        let conditional
            (predicate: 'TConfig -> bool)
            (thenFactory: Factory<'TConfig, 'TProduct>)
            (elseFactory: Factory<'TConfig, 'TProduct>)
            : Factory<'TConfig, 'TProduct> =
            fun config ->
                if predicate config then
                    thenFactory config
                else
                    elseFactory config
