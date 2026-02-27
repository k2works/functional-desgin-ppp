namespace FunctionalDesign.Part6

// ============================================
// 第18章: 並行処理システム
// ============================================

module ConcurrencySystem =

    // ============================================
    // 1. 状態機械パターン
    // ============================================

    /// 電話の状態
    [<RequireQualifiedAccess>]
    type PhoneState =
        | Idle
        | Calling
        | Dialing
        | WaitingForConnection
        | Talking

    /// 電話イベント
    [<RequireQualifiedAccess>]
    type PhoneEvent =
        | Call
        | Ring
        | Dialtone
        | Ringback
        | Connected
        | Disconnect

    /// ユーザー情報
    type User =
        { Id: string
          State: PhoneState
          Peer: string option }

    // ============================================
    // 2. 状態遷移
    // ============================================

    module StateMachine =
        /// 状態遷移テーブル
        let transitions : Map<PhoneState * PhoneEvent, PhoneState> =
            [
                (PhoneState.Idle, PhoneEvent.Call), PhoneState.Calling
                (PhoneState.Idle, PhoneEvent.Ring), PhoneState.WaitingForConnection
                (PhoneState.Idle, PhoneEvent.Disconnect), PhoneState.Idle
                (PhoneState.Calling, PhoneEvent.Dialtone), PhoneState.Dialing
                (PhoneState.Dialing, PhoneEvent.Ringback), PhoneState.WaitingForConnection
                (PhoneState.WaitingForConnection, PhoneEvent.Connected), PhoneState.Talking
                (PhoneState.Talking, PhoneEvent.Disconnect), PhoneState.Idle
            ] |> Map.ofList

        /// 状態遷移を実行
        let transition (state: PhoneState) (event: PhoneEvent) : PhoneState option =
            Map.tryFind (state, event) transitions

        /// ユーザーにイベントを送信
        let sendEvent (event: PhoneEvent) (peer: string option) (user: User) : User =
            match transition user.State event with
            | Some newState ->
                { user with State = newState; Peer = peer |> Option.orElse user.Peer }
            | None -> user

    // ============================================
    // 3. アクション
    // ============================================

    /// アクションの結果
    type ActionResult =
        { Message: string
          FromUser: string
          ToUser: string }

    module Actions =
        let callerOffHook (fromUser: string) (toUser: string) : ActionResult =
            { Message = sprintf "%s picked up the phone to call %s" fromUser toUser
              FromUser = fromUser
              ToUser = toUser }

        let calleeOffHook (fromUser: string) (toUser: string) : ActionResult =
            { Message = sprintf "%s answered the call from %s" fromUser toUser
              FromUser = fromUser
              ToUser = toUser }

        let dial (fromUser: string) (toUser: string) : ActionResult =
            { Message = sprintf "%s is dialing %s" fromUser toUser
              FromUser = fromUser
              ToUser = toUser }

        let talk (fromUser: string) (toUser: string) : ActionResult =
            { Message = sprintf "%s is now talking with %s" fromUser toUser
              FromUser = fromUser
              ToUser = toUser }

    // ============================================
    // 4. 電話操作
    // ============================================

    module Phone =
        /// ユーザーを作成
        let createUser (id: string) : User =
            { Id = id; State = PhoneState.Idle; Peer = None }

        /// 電話をかける
        let makeCall (caller: User) (callee: User) : User * User =
            let updatedCaller = StateMachine.sendEvent PhoneEvent.Call (Some callee.Id) caller
            let updatedCallee = StateMachine.sendEvent PhoneEvent.Ring (Some caller.Id) callee
            (updatedCaller, updatedCallee)

        /// 電話に出る
        let answerCall (caller: User) (callee: User) : User * User =
            let caller1 = StateMachine.sendEvent PhoneEvent.Dialtone None caller
            let caller2 = StateMachine.sendEvent PhoneEvent.Ringback None caller1
            let caller3 = StateMachine.sendEvent PhoneEvent.Connected None caller2
            let callee1 = StateMachine.sendEvent PhoneEvent.Connected None callee
            (caller3, callee1)

        /// 電話を切る
        let hangUp (caller: User) (callee: User) : User * User =
            let updatedCaller = StateMachine.sendEvent PhoneEvent.Disconnect None caller
            let updatedCallee = StateMachine.sendEvent PhoneEvent.Disconnect None callee
            (updatedCaller, updatedCallee)

    // ============================================
    // 5. イベントバス
    // ============================================

    /// イベント
    type Event<'T> =
        { Type: string
          Data: 'T
          Timestamp: System.DateTime }

    /// イベントバス
    type EventBus<'T> =
        { Subscribers: Map<string, (Event<'T> -> unit) list>
          EventLog: Event<'T> list }

    module EventBus =
        /// イベントバスを作成
        let create<'T> () : EventBus<'T> =
            { Subscribers = Map.empty; EventLog = [] }

        /// 購読を追加
        let subscribe (eventType: string) (handler: Event<'T> -> unit) (bus: EventBus<'T>) : EventBus<'T> =
            let handlers = Map.tryFind eventType bus.Subscribers |> Option.defaultValue []
            { bus with Subscribers = Map.add eventType (handler :: handlers) bus.Subscribers }

        /// イベントを発行
        let publish (eventType: string) (data: 'T) (bus: EventBus<'T>) : EventBus<'T> =
            let event = { Type = eventType; Data = data; Timestamp = System.DateTime.UtcNow }
            let handlers = Map.tryFind eventType bus.Subscribers |> Option.defaultValue []
            handlers |> List.iter (fun handler -> handler event)
            { bus with EventLog = event :: bus.EventLog }

        /// イベントログを取得
        let getEventLog (bus: EventBus<'T>) : Event<'T> list =
            List.rev bus.EventLog

    // ============================================
    // 6. 非同期処理（MailboxProcessor）
    // ============================================

    /// メッセージ
    type AgentMessage<'TState, 'TEvent> =
        | GetState of AsyncReplyChannel<'TState>
        | SendEvent of 'TEvent

    /// エージェントを作成
    let createAgent<'TState, 'TEvent> (initialState: 'TState) (update: 'TEvent -> 'TState -> 'TState) =
        MailboxProcessor.Start(fun inbox ->
            let rec loop state = async {
                let! msg = inbox.Receive()
                match msg with
                | GetState channel ->
                    channel.Reply state
                    return! loop state
                | SendEvent event ->
                    let newState = update event state
                    return! loop newState
            }
            loop initialState)

    /// 状態を取得
    let getAgentState (agent: MailboxProcessor<AgentMessage<'TState, 'TEvent>>) : 'TState =
        agent.PostAndReply(fun channel -> GetState channel)

    /// イベントを送信
    let sendAgentEvent (agent: MailboxProcessor<AgentMessage<'TState, 'TEvent>>) (event: 'TEvent) : unit =
        agent.Post(SendEvent event)


// ============================================
// 第19章: Wa-Tor シミュレーション
// ============================================

module WaTorSimulation =

    // ============================================
    // 1. データモデル
    // ============================================

    /// セルの種類
    [<RequireQualifiedAccess>]
    type Cell =
        | Water
        | Fish of age: int * breedTime: int
        | Shark of age: int * breedTime: int * energy: int

    /// 座標
    type Position = int * int

    /// ワールド
    type World =
        { Width: int
          Height: int
          Cells: Map<Position, Cell>
          FishBreedTime: int
          SharkBreedTime: int
          SharkInitialEnergy: int
          SharkEnergyFromFish: int }

    // ============================================
    // 2. 座標操作
    // ============================================

    module Position =
        /// トーラス上で座標をラップ
        let wrap (width: int) (height: int) ((x, y): Position) : Position =
            ((x % width + width) % width, (y % height + height) % height)

        /// 隣接セルの座標を取得（4方向）
        let neighbors (width: int) (height: int) ((x, y): Position) : Position list =
            [(x - 1, y); (x + 1, y); (x, y - 1); (x, y + 1)]
            |> List.map (wrap width height)

    // ============================================
    // 3. ワールド操作
    // ============================================

    module World =
        /// ワールドを作成
        let create (width: int) (height: int) : World =
            let positions = [ for x in 0..width-1 do for y in 0..height-1 -> (x, y) ]
            let cells = positions |> List.map (fun pos -> (pos, Cell.Water)) |> Map.ofList
            { Width = width
              Height = height
              Cells = cells
              FishBreedTime = 3
              SharkBreedTime = 8
              SharkInitialEnergy = 5
              SharkEnergyFromFish = 3 }

        /// セルを取得
        let getCell (pos: Position) (world: World) : Cell =
            Map.tryFind pos world.Cells |> Option.defaultValue Cell.Water

        /// セルを設定
        let setCell (pos: Position) (cell: Cell) (world: World) : World =
            { world with Cells = Map.add pos cell world.Cells }

        /// 隣接セルを取得
        let getNeighbors (pos: Position) (world: World) : (Position * Cell) list =
            Position.neighbors world.Width world.Height pos
            |> List.map (fun p -> (p, getCell p world))

        /// 特定のセル種類の隣接セルを取得
        let getNeighborsOfType (pos: Position) (predicate: Cell -> bool) (world: World) : Position list =
            getNeighbors pos world
            |> List.filter (fun (_, cell) -> predicate cell)
            |> List.map fst

        /// 魚を配置
        let placeFish (pos: Position) (world: World) : World =
            setCell pos (Cell.Fish(0, world.FishBreedTime)) world

        /// サメを配置
        let placeShark (pos: Position) (world: World) : World =
            setCell pos (Cell.Shark(0, world.SharkBreedTime, world.SharkInitialEnergy)) world

        /// 統計情報を取得
        let getStats (world: World) : int * int * int =
            let cells = Map.toList world.Cells |> List.map snd
            let fishCount = cells |> List.filter (function Cell.Fish _ -> true | _ -> false) |> List.length
            let sharkCount = cells |> List.filter (function Cell.Shark _ -> true | _ -> false) |> List.length
            let waterCount = cells |> List.filter (function Cell.Water -> true | _ -> false) |> List.length
            (fishCount, sharkCount, waterCount)

    // ============================================
    // 4. セル操作
    // ============================================

    module CellOps =
        let isWater = function Cell.Water -> true | _ -> false
        let isFish = function Cell.Fish _ -> true | _ -> false
        let isShark = function Cell.Shark _ -> true | _ -> false

    // ============================================
    // 5. シミュレーションルール
    // ============================================

    module Rules =
        let random = System.Random()

        /// ランダムに1つ選択
        let pickRandom (items: 'a list) : 'a option =
            if List.isEmpty items then None
            else Some items.[random.Next(items.Length)]

        /// 魚のティック処理
        let fishTick (pos: Position) (age: int) (breedTime: int) (world: World) : (Position * Cell) list =
            let emptyNeighbors = World.getNeighborsOfType pos CellOps.isWater world
            match pickRandom emptyNeighbors with
            | Some newPos ->
                if age + 1 >= breedTime then
                    // 繁殖: 現在位置に子を残し、新位置に移動
                    [ (pos, Cell.Fish(0, world.FishBreedTime))
                      (newPos, Cell.Fish(0, world.FishBreedTime)) ]
                else
                    // 移動のみ
                    [ (pos, Cell.Water)
                      (newPos, Cell.Fish(age + 1, breedTime)) ]
            | None ->
                // 移動できない: その場で年を取る
                [ (pos, Cell.Fish(age + 1, breedTime)) ]

        /// サメのティック処理
        let sharkTick (pos: Position) (age: int) (breedTime: int) (energy: int) (world: World) : (Position * Cell) list =
            if energy <= 0 then
                // エネルギー切れで死亡
                [ (pos, Cell.Water) ]
            else
                let fishNeighbors = World.getNeighborsOfType pos CellOps.isFish world
                let emptyNeighbors = World.getNeighborsOfType pos CellOps.isWater world

                match pickRandom fishNeighbors with
                | Some fishPos ->
                    // 魚を食べる
                    let newEnergy = energy + world.SharkEnergyFromFish
                    if age + 1 >= breedTime then
                        [ (pos, Cell.Shark(0, world.SharkBreedTime, world.SharkInitialEnergy))
                          (fishPos, Cell.Shark(0, breedTime, newEnergy)) ]
                    else
                        [ (pos, Cell.Water)
                          (fishPos, Cell.Shark(age + 1, breedTime, newEnergy)) ]
                | None ->
                    match pickRandom emptyNeighbors with
                    | Some newPos ->
                        // 移動
                        if age + 1 >= breedTime then
                            [ (pos, Cell.Shark(0, world.SharkBreedTime, world.SharkInitialEnergy))
                              (newPos, Cell.Shark(0, breedTime, energy - 1)) ]
                        else
                            [ (pos, Cell.Water)
                              (newPos, Cell.Shark(age + 1, breedTime, energy - 1)) ]
                    | None ->
                        // 移動できない
                        [ (pos, Cell.Shark(age + 1, breedTime, energy - 1)) ]

    // ============================================
    // 6. シミュレーション
    // ============================================

    module Simulation =
        /// 1ステップ実行
        let tick (world: World) : World =
            let mutable newWorld = world

            // 魚を処理
            for pos in Map.toList world.Cells |> List.map fst do
                match World.getCell pos newWorld with
                | Cell.Fish(age, breedTime) ->
                    let updates = Rules.fishTick pos age breedTime newWorld
                    for (p, c) in updates do
                        newWorld <- World.setCell p c newWorld
                | _ -> ()

            // サメを処理
            for pos in Map.toList world.Cells |> List.map fst do
                match World.getCell pos newWorld with
                | Cell.Shark(age, breedTime, energy) ->
                    let updates = Rules.sharkTick pos age breedTime energy newWorld
                    for (p, c) in updates do
                        newWorld <- World.setCell p c newWorld
                | _ -> ()

            newWorld

        /// 複数ステップ実行
        let run (steps: int) (world: World) : World =
            let rec loop n w =
                if n <= 0 then w
                else loop (n - 1) (tick w)
            loop steps world

    // ============================================
    // 7. 表示
    // ============================================

    module Display =
        let cellToChar = function
            | Cell.Water -> '.'
            | Cell.Fish _ -> 'f'
            | Cell.Shark _ -> 'S'

        let worldToString (world: World) : string =
            let sb = System.Text.StringBuilder()
            for y in 0..world.Height-1 do
                for x in 0..world.Width-1 do
                    sb.Append(cellToChar (World.getCell (x, y) world)) |> ignore
                sb.AppendLine() |> ignore
            sb.ToString()
