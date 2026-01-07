import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import org.scalatest.BeforeAndAfterEach
import ConcurrencySystem.*
import scala.concurrent.{Await, Future}
import scala.concurrent.duration.*
import scala.concurrent.ExecutionContext.Implicits.global

class ConcurrencySystemSpec extends AnyFunSpec with Matchers with BeforeAndAfterEach:

  // ============================================================
  // 1. 状態機械
  // ============================================================

  describe("PhoneStateMachine"):

    describe("状態遷移"):
      it("Idle -> Calling (Call)"):
        val result = PhoneStateMachine.transition(PhoneState.Idle, PhoneEvent.Call)
        result shouldBe defined
        result.get.nextState shouldBe PhoneState.Calling
        result.get.action shouldBe ActionType.CallerOffHook

      it("Idle -> WaitingForConnection (Ring)"):
        val result = PhoneStateMachine.transition(PhoneState.Idle, PhoneEvent.Ring)
        result shouldBe defined
        result.get.nextState shouldBe PhoneState.WaitingForConnection
        result.get.action shouldBe ActionType.CalleeOffHook

      it("Calling -> Dialing (Dialtone)"):
        val result = PhoneStateMachine.transition(PhoneState.Calling, PhoneEvent.Dialtone)
        result shouldBe defined
        result.get.nextState shouldBe PhoneState.Dialing
        result.get.action shouldBe ActionType.Dial

      it("Dialing -> WaitingForConnection (Ringback)"):
        val result = PhoneStateMachine.transition(PhoneState.Dialing, PhoneEvent.Ringback)
        result shouldBe defined
        result.get.nextState shouldBe PhoneState.WaitingForConnection
        result.get.action shouldBe ActionType.None

      it("WaitingForConnection -> Talking (Connected)"):
        val result = PhoneStateMachine.transition(PhoneState.WaitingForConnection, PhoneEvent.Connected)
        result shouldBe defined
        result.get.nextState shouldBe PhoneState.Talking
        result.get.action shouldBe ActionType.Talk

      it("Talking -> Idle (Disconnect)"):
        val result = PhoneStateMachine.transition(PhoneState.Talking, PhoneEvent.Disconnect)
        result shouldBe defined
        result.get.nextState shouldBe PhoneState.Idle

      it("無効な遷移は None を返す"):
        val result = PhoneStateMachine.transition(PhoneState.Idle, PhoneEvent.Connected)
        result shouldBe None

    describe("遷移の有効性チェック"):
      it("有効な遷移"):
        PhoneStateMachine.isValidTransition(PhoneState.Idle, PhoneEvent.Call) shouldBe true

      it("無効な遷移"):
        PhoneStateMachine.isValidTransition(PhoneState.Talking, PhoneEvent.Call) shouldBe false

  // ============================================================
  // 2. ユーザーエージェント
  // ============================================================

  describe("UserAgent"):

    it("初期状態は Idle"):
      val handler = new SilentActionHandler
      val agent = new UserAgent("Alice", handler)
      agent.getState shouldBe PhoneState.Idle

    it("Call イベントで Calling 状態に遷移"):
      val handler = new SilentActionHandler
      val agent = new UserAgent("Alice", handler)

      agent.sendEvent(PhoneEvent.Call, Some("Bob")) shouldBe true
      agent.getState shouldBe PhoneState.Calling
      agent.getPeer shouldBe Some("Bob")

    it("アクションが実行される"):
      val handler = new SilentActionHandler
      val agent = new UserAgent("Alice", handler)

      agent.sendEvent(PhoneEvent.Call, Some("Bob"))

      handler.getActions should contain ((("Alice", "Bob", ActionType.CallerOffHook)))

    it("無効な遷移は失敗"):
      val handler = new SilentActionHandler
      val agent = new UserAgent("Alice", handler)

      agent.sendEvent(PhoneEvent.Connected) shouldBe false
      agent.getState shouldBe PhoneState.Idle

    it("リセットできる"):
      val handler = new SilentActionHandler
      val agent = new UserAgent("Alice", handler)

      agent.sendEvent(PhoneEvent.Call, Some("Bob"))
      agent.reset()

      agent.getState shouldBe PhoneState.Idle
      agent.getPeer shouldBe None

  // ============================================================
  // 3. 電話システム
  // ============================================================

  describe("PhoneSystem"):

    it("ユーザーを作成できる"):
      val system = new PhoneSystem(new SilentActionHandler)
      val alice = system.createUser("Alice")

      alice.userId shouldBe "Alice"
      system.getUser("Alice") shouldBe Some(alice)

    it("電話をかけられる"):
      val handler = new SilentActionHandler
      val system = new PhoneSystem(handler)
      system.createUser("Alice")
      system.createUser("Bob")

      system.makeCall("Alice", "Bob") shouldBe true

      system.getUser("Alice").get.getState shouldBe PhoneState.Calling
      system.getUser("Bob").get.getState shouldBe PhoneState.WaitingForConnection

    it("電話に出られる"):
      val handler = new SilentActionHandler
      val system = new PhoneSystem(handler)
      system.createUser("Alice")
      system.createUser("Bob")

      system.makeCall("Alice", "Bob")
      system.answerCall("Alice", "Bob") shouldBe true

      system.getUser("Alice").get.getState shouldBe PhoneState.Talking
      system.getUser("Bob").get.getState shouldBe PhoneState.Talking

    it("電話を切れる"):
      val handler = new SilentActionHandler
      val system = new PhoneSystem(handler)
      system.createUser("Alice")
      system.createUser("Bob")

      system.makeCall("Alice", "Bob")
      system.answerCall("Alice", "Bob")
      system.hangUp("Alice", "Bob") shouldBe true

      system.getUser("Alice").get.getState shouldBe PhoneState.Idle
      system.getUser("Bob").get.getState shouldBe PhoneState.Idle

    it("存在しないユーザーへの通話は失敗"):
      val system = new PhoneSystem(new SilentActionHandler)
      system.createUser("Alice")

      system.makeCall("Alice", "Bob") shouldBe false

  // ============================================================
  // 4. イベントバス
  // ============================================================

  describe("EventBus"):

    it("イベントを購読できる"):
      val bus = new EventBus
      var received: Option[Event] = None

      bus.subscribe("test-event", e => received = Some(e))
      bus.publish("test-event", Map("key" -> "value"))

      received shouldBe defined
      received.get.eventType shouldBe "test-event"
      received.get.data shouldBe Map("key" -> "value")

    it("複数のハンドラを登録できる"):
      val bus = new EventBus
      var count = 0

      bus.subscribe("test-event", _ => count += 1)
      bus.subscribe("test-event", _ => count += 1)
      bus.publish("test-event")

      count shouldBe 2

    it("イベントログに記録される"):
      val bus = new EventBus
      bus.subscribe("test-event", _ => ())

      bus.publish("event-1", Map("a" -> 1))
      bus.publish("event-2", Map("b" -> 2))

      bus.getEventLog should have length 2
      bus.getEventLog.map(_.eventType) shouldBe List("event-1", "event-2")

    it("非同期で発行できる"):
      val bus = new EventBus
      var received = false

      bus.subscribe("async-event", _ => received = true)
      val future = bus.publishAsync("async-event")
      Await.result(future, 1.second)

      received shouldBe true

    it("ハンドラのエラーは他のハンドラに影響しない"):
      val bus = new EventBus
      var count = 0

      bus.subscribe("error-event", _ => throw new RuntimeException("Error"))
      bus.subscribe("error-event", _ => count += 1)
      bus.publish("error-event")

      count shouldBe 1

  // ============================================================
  // 5. 汎用状態機械
  // ============================================================

  describe("StateMachine"):

    enum TrafficLight:
      case Red, Yellow, Green

    enum TrafficEvent:
      case Next

    import TrafficLight.*
    import TrafficEvent.*

    it("汎用状態機械を作成できる"):
      val sm = StateMachine.builder[TrafficLight, TrafficEvent](Red)
        .addTransition(Red, Next, Green)
        .addTransition(Green, Next, Yellow)
        .addTransition(Yellow, Next, Red)
        .build

      sm.getState shouldBe Red

    it("状態遷移できる"):
      val sm = StateMachine.builder[TrafficLight, TrafficEvent](Red)
        .addTransition(Red, Next, Green)
        .addTransition(Green, Next, Yellow)
        .addTransition(Yellow, Next, Red)
        .build

      sm.send(Next) shouldBe true
      sm.getState shouldBe Green

      sm.send(Next)
      sm.getState shouldBe Yellow

      sm.send(Next)
      sm.getState shouldBe Red

    it("アクションを実行できる"):
      var actionExecuted = false
      val sm = StateMachine.builder[TrafficLight, TrafficEvent](Red)
        .addTransition(Red, Next, Green, Some(() => actionExecuted = true))
        .build

      sm.send(Next)
      actionExecuted shouldBe true

  // ============================================================
  // 6. Pub/Sub
  // ============================================================

  describe("Topic"):

    it("メッセージを購読できる"):
      val topic = new Topic[String]("test-topic")
      var received: Option[String] = None

      topic.subscribe("sub1", msg => received = Some(msg))
      topic.publish("Hello")

      received shouldBe Some("Hello")

    it("複数の購読者にメッセージを配信できる"):
      val topic = new Topic[String]("test-topic")
      var count = 0

      topic.subscribe("sub1", _ => count += 1)
      topic.subscribe("sub2", _ => count += 1)
      topic.publish("Hello")

      count shouldBe 2

    it("購読解除できる"):
      val topic = new Topic[String]("test-topic")
      var count = 0

      topic.subscribe("sub1", _ => count += 1)
      topic.unsubscribe("sub1")
      topic.publish("Hello")

      count shouldBe 0

  describe("MessageBroker"):

    it("トピックを取得できる"):
      val broker = new MessageBroker
      val topic = broker.getTopic[String]("news")

      topic should not be null

    it("同じ名前のトピックは同一インスタンス"):
      val broker = new MessageBroker
      val topic1 = broker.getTopic[String]("news")
      val topic2 = broker.getTopic[String]("news")

      topic1 shouldBe topic2

    it("トピック名一覧を取得できる"):
      val broker = new MessageBroker
      broker.getTopic[String]("topic1")
      broker.getTopic[Int]("topic2")

      broker.topicNames should contain allOf ("topic1", "topic2")

  // ============================================================
  // 7. タスクキュー
  // ============================================================

  describe("TaskQueue"):

    it("タスクを投入して結果を取得できる"):
      val queue = new TaskQueue[Int]()
      queue.start()

      try
        val future = queue.submit("task1", () => 42)
        val result = Await.result(future, 1.second)
        result shouldBe 42
      finally
        queue.stop()

    it("複数のタスクを並行処理できる"):
      val queue = new TaskQueue[Int](workers = 2)
      queue.start()

      try
        val futures = (1 to 10).map { i =>
          queue.submit(s"task-$i", () => {
            Thread.sleep(10)
            i * 2
          })
        }
        val results = Await.result(Future.sequence(futures), 5.seconds)
        results.sum shouldBe (1 to 10).map(_ * 2).sum
      finally
        queue.stop()

  // ============================================================
  // 8. アトミックカウンター
  // ============================================================

  describe("AtomicCounter"):

    it("カウンターを操作できる"):
      val counter = new AtomicCounter()

      counter.get shouldBe 0
      counter.increment shouldBe 1
      counter.increment shouldBe 2
      counter.decrement shouldBe 1
      counter.add(10) shouldBe 11

    it("初期値を設定できる"):
      val counter = new AtomicCounter(100)
      counter.get shouldBe 100

    it("リセットできる"):
      val counter = new AtomicCounter(10)
      counter.increment
      counter.reset()
      counter.get shouldBe 10

  // ============================================================
  // 9. 並行マップ
  // ============================================================

  describe("ConcurrentMap"):

    it("値を追加・取得できる"):
      val map = new ConcurrentMap[String, Int]
      map.put("a", 1)
      map.put("b", 2)

      map.get("a") shouldBe Some(1)
      map.get("b") shouldBe Some(2)
      map.get("c") shouldBe None

    it("値を削除できる"):
      val map = new ConcurrentMap[String, Int]
      map.put("a", 1)
      map.remove("a")

      map.get("a") shouldBe None

    it("getOrElseUpdate で遅延初期化できる"):
      val map = new ConcurrentMap[String, Int]
      var initialized = false

      map.getOrElseUpdate("a", { initialized = true; 42 })
      initialized shouldBe true

      initialized = false
      map.getOrElseUpdate("a", { initialized = true; 100 })
      initialized shouldBe false
      map.get("a") shouldBe Some(42)

  // ============================================================
  // 10. アクションハンドラ
  // ============================================================

  describe("LoggingActionHandler"):

    it("ログを記録する"):
      val handler = new LoggingActionHandler
      handler.handle("Alice", "Bob", ActionType.CallerOffHook)

      handler.getLogs should have length 1
      handler.getLogs.head should include("Alice")
      handler.getLogs.head should include("Bob")

    it("None アクションはログに記録しない"):
      val handler = new LoggingActionHandler
      handler.handle("Alice", "Bob", ActionType.None)

      handler.getLogs shouldBe empty

  describe("SilentActionHandler"):

    it("アクションを記録する"):
      val handler = new SilentActionHandler
      handler.handle("Alice", "Bob", ActionType.Dial)

      handler.getActions should have length 1
      handler.getActions.head shouldBe (("Alice", "Bob", ActionType.Dial))
