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
