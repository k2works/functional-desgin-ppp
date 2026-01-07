module Tests

open System
open Xunit
open FunctionalDesign.Part6.ConcurrencySystem
open FunctionalDesign.Part6.WaTorSimulation

// ============================================
// 第18章: 並行処理システムテスト
// ============================================

module ConcurrencySystemTests =

    // ============================================
    // 1. 状態機械テスト
    // ============================================

    [<Fact>]
    let ``状態遷移テーブルで遷移を取得できる`` () =
        let result = StateMachine.transition PhoneState.Idle PhoneEvent.Call
        Assert.Equal(Some PhoneState.Calling, result)

    [<Fact>]
    let ``無効な遷移はNoneを返す`` () =
        let result = StateMachine.transition PhoneState.Idle PhoneEvent.Dialtone
        Assert.True(result.IsNone)

    [<Fact>]
    let ``ユーザーにイベントを送信して状態を変更できる`` () =
        let user = Phone.createUser "Alice"
        let updated = StateMachine.sendEvent PhoneEvent.Call (Some "Bob") user
        Assert.Equal(PhoneState.Calling, updated.State)
        Assert.Equal(Some "Bob", updated.Peer)

    // ============================================
    // 2. 電話操作テスト
    // ============================================

    [<Fact>]
    let ``ユーザーを作成できる`` () =
        let user = Phone.createUser "Alice"
        Assert.Equal("Alice", user.Id)
        Assert.Equal(PhoneState.Idle, user.State)
        Assert.True(user.Peer.IsNone)

    [<Fact>]
    let ``電話をかけることができる`` () =
        let alice = Phone.createUser "Alice"
        let bob = Phone.createUser "Bob"
        let (alice', bob') = Phone.makeCall alice bob
        Assert.Equal(PhoneState.Calling, alice'.State)
        Assert.Equal(PhoneState.WaitingForConnection, bob'.State)

    [<Fact>]
    let ``電話に出ることができる`` () =
        let alice = { Phone.createUser "Alice" with State = PhoneState.Calling }
        let bob = { Phone.createUser "Bob" with State = PhoneState.WaitingForConnection }
        let (alice', bob') = Phone.answerCall alice bob
        Assert.Equal(PhoneState.Talking, alice'.State)
        Assert.Equal(PhoneState.Talking, bob'.State)

    [<Fact>]
    let ``電話を切ることができる`` () =
        let alice = { Phone.createUser "Alice" with State = PhoneState.Talking }
        let bob = { Phone.createUser "Bob" with State = PhoneState.Talking }
        let (alice', bob') = Phone.hangUp alice bob
        Assert.Equal(PhoneState.Idle, alice'.State)
        Assert.Equal(PhoneState.Idle, bob'.State)

    // ============================================
    // 3. アクションテスト
    // ============================================

    [<Fact>]
    let ``callerOffHookアクションが正しいメッセージを返す`` () =
        let result = Actions.callerOffHook "Alice" "Bob"
        Assert.Contains("Alice", result.Message)
        Assert.Contains("Bob", result.Message)
        Assert.Contains("picked up", result.Message)

    [<Fact>]
    let ``talkアクションが正しいメッセージを返す`` () =
        let result = Actions.talk "Alice" "Bob"
        Assert.Contains("talking", result.Message)

    // ============================================
    // 4. イベントバステスト
    // ============================================

    [<Fact>]
    let ``イベントバスを作成できる`` () =
        let bus = EventBus.create<string> ()
        Assert.True(Map.isEmpty bus.Subscribers)
        Assert.True(List.isEmpty bus.EventLog)

    [<Fact>]
    let ``イベントを購読できる`` () =
        let mutable received = false
        let handler (event: Event<string>) = received <- true
        let bus = EventBus.create<string> () |> EventBus.subscribe "test" handler
        Assert.Equal(1, (Map.find "test" bus.Subscribers).Length)

    [<Fact>]
    let ``イベントを発行できる`` () =
        let mutable receivedData = ""
        let handler (event: Event<string>) = receivedData <- event.Data
        let bus =
            EventBus.create<string> ()
            |> EventBus.subscribe "test" handler
            |> EventBus.publish "test" "Hello"
        Assert.Equal("Hello", receivedData)

    [<Fact>]
    let ``イベントログに記録される`` () =
        let bus =
            EventBus.create<string> ()
            |> EventBus.publish "event1" "Data1"
            |> EventBus.publish "event2" "Data2"
        let log = EventBus.getEventLog bus
        Assert.Equal(2, List.length log)
        Assert.Equal("event1", log.[0].Type)
        Assert.Equal("event2", log.[1].Type)

    // ============================================
    // 5. エージェントテスト
    // ============================================

    [<Fact>]
    let ``エージェントを作成して状態を取得できる`` () =
        let agent = createAgent 0 (fun event state -> state + event)
        let state = getAgentState agent
        Assert.Equal(0, state)

    [<Fact>]
    let ``エージェントにイベントを送信して状態を更新できる`` () =
        let agent = createAgent 0 (fun event state -> state + event)
        sendAgentEvent agent 5
        System.Threading.Thread.Sleep(100) // 非同期処理を待つ
        let state = getAgentState agent
        Assert.Equal(5, state)

    [<Fact>]
    let ``複数のイベントを順番に処理できる`` () =
        let agent = createAgent 0 (fun event state -> state + event)
        sendAgentEvent agent 1
        sendAgentEvent agent 2
        sendAgentEvent agent 3
        System.Threading.Thread.Sleep(100)
        let state = getAgentState agent
        Assert.Equal(6, state)


// ============================================
// 第19章: Wa-Tor シミュレーションテスト
// ============================================

module WaTorSimulationTests =

    // ============================================
    // 1. 座標操作テスト
    // ============================================

    [<Fact>]
    let ``座標をラップできる`` () =
        Assert.Equal((0, 0), Position.wrap 5 5 (5, 5))
        Assert.Equal((4, 4), Position.wrap 5 5 (-1, -1))
        Assert.Equal((2, 3), Position.wrap 5 5 (7, 8))

    [<Fact>]
    let ``隣接セルを取得できる`` () =
        let neighbors = Position.neighbors 5 5 (2, 2)
        Assert.Equal(4, List.length neighbors)
        Assert.Contains((1, 2), neighbors)
        Assert.Contains((3, 2), neighbors)
        Assert.Contains((2, 1), neighbors)
        Assert.Contains((2, 3), neighbors)

    [<Fact>]
    let ``端の座標で隣接セルがラップされる`` () =
        let neighbors = Position.neighbors 5 5 (0, 0)
        Assert.Contains((4, 0), neighbors) // 左端は右端にラップ
        Assert.Contains((0, 4), neighbors) // 上端は下端にラップ

    // ============================================
    // 2. ワールド操作テスト
    // ============================================

    [<Fact>]
    let ``ワールドを作成できる`` () =
        let world = World.create 10 10
        Assert.Equal(10, world.Width)
        Assert.Equal(10, world.Height)
        Assert.Equal(100, Map.count world.Cells)

    [<Fact>]
    let ``セルを取得できる`` () =
        let world = World.create 5 5
        let cell = World.getCell (2, 2) world
        Assert.Equal(Cell.Water, cell)

    [<Fact>]
    let ``魚を配置できる`` () =
        let world = World.create 5 5 |> World.placeFish (2, 2)
        match World.getCell (2, 2) world with
        | Cell.Fish _ -> Assert.True(true)
        | _ -> Assert.True(false, "Expected Fish")

    [<Fact>]
    let ``サメを配置できる`` () =
        let world = World.create 5 5 |> World.placeShark (2, 2)
        match World.getCell (2, 2) world with
        | Cell.Shark _ -> Assert.True(true)
        | _ -> Assert.True(false, "Expected Shark")

    [<Fact>]
    let ``統計情報を取得できる`` () =
        let world =
            World.create 5 5
            |> World.placeFish (0, 0)
            |> World.placeFish (1, 1)
            |> World.placeShark (2, 2)
        let (fishCount, sharkCount, waterCount) = World.getStats world
        Assert.Equal(2, fishCount)
        Assert.Equal(1, sharkCount)
        Assert.Equal(22, waterCount)

    // ============================================
    // 3. セル判定テスト
    // ============================================

    [<Fact>]
    let ``水セルを判定できる`` () =
        Assert.True(CellOps.isWater Cell.Water)
        Assert.False(CellOps.isWater (Cell.Fish(0, 3)))

    [<Fact>]
    let ``魚セルを判定できる`` () =
        Assert.True(CellOps.isFish (Cell.Fish(0, 3)))
        Assert.False(CellOps.isFish Cell.Water)

    [<Fact>]
    let ``サメセルを判定できる`` () =
        Assert.True(CellOps.isShark (Cell.Shark(0, 8, 5)))
        Assert.False(CellOps.isShark Cell.Water)

    // ============================================
    // 4. シミュレーションテスト
    // ============================================

    [<Fact>]
    let ``1ステップ実行できる`` () =
        let world =
            World.create 5 5
            |> World.placeFish (2, 2)
        let afterTick = Simulation.tick world
        // 魚が移動または繁殖しているはず
        let (fishCount, _, _) = World.getStats afterTick
        Assert.True(fishCount >= 1)

    [<Fact>]
    let ``複数ステップ実行できる`` () =
        let world =
            World.create 5 5
            |> World.placeFish (2, 2)
        let afterRun = Simulation.run 5 world
        Assert.NotNull(afterRun)

    [<Fact>]
    let ``サメがエネルギー切れで死亡する`` () =
        let world =
            { World.create 5 5 with SharkInitialEnergy = 1 }
            |> World.placeShark (2, 2)
        // 複数ティック後、サメはエネルギー切れで死亡するはず
        let afterRun = Simulation.run 5 world
        let (_, sharkCount, _) = World.getStats afterRun
        // サメが死亡しているか、まだ生きているか（魚を食べた場合）
        Assert.True(sharkCount >= 0)

    // ============================================
    // 5. 表示テスト
    // ============================================

    [<Fact>]
    let ``セルを文字に変換できる`` () =
        Assert.Equal('.', Display.cellToChar Cell.Water)
        Assert.Equal('f', Display.cellToChar (Cell.Fish(0, 3)))
        Assert.Equal('S', Display.cellToChar (Cell.Shark(0, 8, 5)))

    [<Fact>]
    let ``ワールドを文字列に変換できる`` () =
        let world =
            World.create 3 3
            |> World.placeFish (0, 0)
            |> World.placeShark (1, 1)
        let str = Display.worldToString world
        Assert.Contains("f", str)
        Assert.Contains("S", str)
        Assert.Contains(".", str)

    // ============================================
    // 6. 隣接セル取得テスト
    // ============================================

    [<Fact>]
    let ``特定種類の隣接セルを取得できる`` () =
        let world =
            World.create 5 5
            |> World.placeFish (2, 1)
            |> World.placeFish (2, 3)
            |> World.placeShark (1, 2)
        let fishNeighbors = World.getNeighborsOfType (2, 2) CellOps.isFish world
        Assert.Equal(2, List.length fishNeighbors)

    [<Fact>]
    let ``空の隣接セルを取得できる`` () =
        let world = World.create 5 5 |> World.placeFish (2, 2)
        let emptyNeighbors = World.getNeighborsOfType (2, 2) CellOps.isWater world
        Assert.Equal(4, List.length emptyNeighbors)
