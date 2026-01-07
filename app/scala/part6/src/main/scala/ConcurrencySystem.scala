/**
 * 第18章: 並行処理システム
 *
 * 状態機械パターンとイベント駆動アーキテクチャの実装。
 * Scala の並行処理プリミティブを使用した電話通話システム。
 */
import scala.collection.concurrent.TrieMap
import java.util.concurrent.atomic.AtomicReference
import scala.concurrent.{Future, Promise, ExecutionContext}
import scala.util.{Try, Success, Failure}

object ConcurrencySystem:

  // ============================================================
  // 1. 基本型定義
  // ============================================================

  type UserId = String
  type EventType = String

  // ============================================================
  // 2. 状態機械
  // ============================================================

  /**
   * 電話の状態
   */
  enum PhoneState:
    case Idle
    case Calling
    case Dialing
    case WaitingForConnection
    case Talking

  /**
   * 電話イベント
   */
  enum PhoneEvent:
    case Call
    case Ring
    case Dialtone
    case Ringback
    case Connected
    case Disconnect

  /**
   * アクションタイプ
   */
  enum ActionType:
    case CallerOffHook
    case CalleeOffHook
    case Dial
    case Talk
    case None

  /**
   * 状態遷移結果
   */
  case class Transition(
    nextState: PhoneState,
    action: ActionType
  )

  /**
   * 状態機械の定義
   */
  object PhoneStateMachine:
    import PhoneState.*
    import PhoneEvent.*
    import ActionType.*

    private val transitions: Map[(PhoneState, PhoneEvent), Transition] = Map(
      (Idle, Call) -> Transition(Calling, CallerOffHook),
      (Idle, Ring) -> Transition(WaitingForConnection, CalleeOffHook),
      (Idle, Disconnect) -> Transition(Idle, None),
      (Calling, Dialtone) -> Transition(Dialing, Dial),
      (Dialing, Ringback) -> Transition(WaitingForConnection, None),
      (WaitingForConnection, Connected) -> Transition(Talking, Talk),
      (Talking, Disconnect) -> Transition(Idle, None)
    )

    def transition(state: PhoneState, event: PhoneEvent): Option[Transition] =
      transitions.get((state, event))

    def isValidTransition(state: PhoneState, event: PhoneEvent): Boolean =
      transitions.contains((state, event))

  // ============================================================
  // 3. アクション
  // ============================================================

  /**
   * アクションハンドラ
   */
  trait ActionHandler:
    def handle(fromUser: UserId, toUser: UserId, action: ActionType): Unit

  /**
   * ログ出力アクションハンドラ
   */
  class LoggingActionHandler extends ActionHandler:
    private var logs: List[String] = Nil

    def handle(fromUser: UserId, toUser: UserId, action: ActionType): Unit =
      val message = action match
        case ActionType.CallerOffHook => s"$fromUser picked up the phone to call $toUser"
        case ActionType.CalleeOffHook => s"$fromUser answered the call from $toUser"
        case ActionType.Dial => s"$fromUser is dialing $toUser"
        case ActionType.Talk => s"$fromUser is now talking with $toUser"
        case ActionType.None => ""

      if message.nonEmpty then
        logs = logs :+ message
        println(message)

    def getLogs: List[String] = logs
    def clear(): Unit = logs = Nil

  /**
   * サイレントアクションハンドラ（テスト用）
   */
  class SilentActionHandler extends ActionHandler:
    private var actions: List[(UserId, UserId, ActionType)] = Nil

    def handle(fromUser: UserId, toUser: UserId, action: ActionType): Unit =
      if action != ActionType.None then
        actions = actions :+ (fromUser, toUser, action)

    def getActions: List[(UserId, UserId, ActionType)] = actions
    def clear(): Unit = actions = Nil

  // ============================================================
  // 4. ユーザーエージェント（AtomicReference版）
  // ============================================================

  /**
   * ユーザー状態
   */
  case class UserState(
    userId: UserId,
    state: PhoneState = PhoneState.Idle,
    peer: Option[UserId] = None
  )

  /**
   * ユーザーエージェント
   */
  class UserAgent(val userId: UserId, actionHandler: ActionHandler):
    private val stateRef = new AtomicReference(UserState(userId))

    def getState: PhoneState = stateRef.get().state
    def getPeer: Option[UserId] = stateRef.get().peer
    def getUserState: UserState = stateRef.get()

    /**
     * イベントを送信（同期的に状態遷移）
     */
    def sendEvent(event: PhoneEvent, peer: Option[UserId] = None): Boolean =
      var success = false
      var done = false
      while !done do
        val current = stateRef.get()
        PhoneStateMachine.transition(current.state, event) match
          case Some(trans) =>
            val newPeer = peer.orElse(current.peer)
            val newState = current.copy(state = trans.nextState, peer = newPeer)
            if stateRef.compareAndSet(current, newState) then
              if trans.action != ActionType.None then
                actionHandler.handle(userId, newPeer.getOrElse("unknown"), trans.action)
              success = true
              done = true
          case None =>
            done = true
      success

    def reset(): Unit =
      stateRef.set(UserState(userId))

  // ============================================================
  // 5. 電話システム
  // ============================================================

  /**
   * 電話システム
   */
  class PhoneSystem(actionHandler: ActionHandler = new LoggingActionHandler):
    private val users = TrieMap.empty[UserId, UserAgent]

    def createUser(userId: UserId): UserAgent =
      val agent = new UserAgent(userId, actionHandler)
      users.put(userId, agent)
      agent

    def getUser(userId: UserId): Option[UserAgent] =
      users.get(userId)

    def removeUser(userId: UserId): Option[UserAgent] =
      users.remove(userId)

    /**
     * 電話をかける
     */
    def makeCall(callerId: UserId, calleeId: UserId): Boolean =
      (for
        caller <- users.get(callerId)
        callee <- users.get(calleeId)
      yield
        val callerSuccess = caller.sendEvent(PhoneEvent.Call, Some(calleeId))
        val calleeSuccess = callee.sendEvent(PhoneEvent.Ring, Some(callerId))
        callerSuccess && calleeSuccess
      ).getOrElse(false)

    /**
     * 電話に出る
     */
    def answerCall(callerId: UserId, calleeId: UserId): Boolean =
      (for
        caller <- users.get(callerId)
        callee <- users.get(calleeId)
      yield
        caller.sendEvent(PhoneEvent.Dialtone) &&
        caller.sendEvent(PhoneEvent.Ringback) &&
        caller.sendEvent(PhoneEvent.Connected) &&
        callee.sendEvent(PhoneEvent.Connected)
      ).getOrElse(false)

    /**
     * 電話を切る
     */
    def hangUp(callerId: UserId, calleeId: UserId): Boolean =
      (for
        caller <- users.get(callerId)
        callee <- users.get(calleeId)
      yield
        caller.sendEvent(PhoneEvent.Disconnect) &&
        callee.sendEvent(PhoneEvent.Disconnect)
      ).getOrElse(false)

    def clear(): Unit = users.clear()

  // ============================================================
  // 6. イベントバス
  // ============================================================

  /**
   * イベント
   */
  case class Event(
    eventType: EventType,
    data: Map[String, Any],
    timestamp: Long = System.currentTimeMillis()
  )

  /**
   * イベントハンドラ
   */
  type EventHandler = Event => Unit

  /**
   * イベントバス
   */
  class EventBus:
    private val subscribers = TrieMap.empty[EventType, List[EventHandler]]
    private var eventLog: List[Event] = Nil
    private val logLock = new Object

    /**
     * イベントを購読
     */
    def subscribe(eventType: EventType, handler: EventHandler): Unit =
      subscribers.updateWith(eventType) {
        case Some(handlers) => Some(handlers :+ handler)
        case None => Some(List(handler))
      }

    /**
     * 購読解除
     */
    def unsubscribe(eventType: EventType, handler: EventHandler): Unit =
      subscribers.updateWith(eventType) {
        case Some(handlers) => Some(handlers.filterNot(_ == handler))
        case None => None
      }

    /**
     * イベントを発行（同期）
     */
    def publish(eventType: EventType, data: Map[String, Any] = Map.empty): Event =
      val event = Event(eventType, data)
      logLock.synchronized {
        eventLog = eventLog :+ event
      }
      subscribers.get(eventType).foreach { handlers =>
        handlers.foreach { handler =>
          try handler(event)
          catch case e: Exception => println(s"Handler error: ${e.getMessage}")
        }
      }
      event

    /**
     * イベントを発行（非同期）
     */
    def publishAsync(eventType: EventType, data: Map[String, Any] = Map.empty)(using ec: ExecutionContext): Future[Event] =
      Future {
        publish(eventType, data)
      }

    def getEventLog: List[Event] = logLock.synchronized { eventLog }
    def clearLog(): Unit = logLock.synchronized { eventLog = Nil }
    def clear(): Unit =
      subscribers.clear()
      clearLog()

  // ============================================================
  // 7. 汎用状態機械
  // ============================================================

  /**
   * 汎用状態機械
   */
  class StateMachine[S, E](
    initialState: S,
    transitions: Map[(S, E), (S, Option[() => Unit])]
  ):
    private val stateRef = new AtomicReference(initialState)

    def getState: S = stateRef.get()

    def send(event: E): Boolean =
      var success = false
      var done = false
      while !done do
        val current = stateRef.get()
        transitions.get((current, event)) match
          case Some((nextState, action)) =>
            if stateRef.compareAndSet(current, nextState) then
              action.foreach(_())
              success = true
              done = true
          case None =>
            done = true
      success

    def reset(): Unit = stateRef.set(initialState)

  object StateMachine:
    def builder[S, E](initialState: S): StateMachineBuilder[S, E] =
      StateMachineBuilder(initialState, Map.empty)

    case class StateMachineBuilder[S, E](
      initialState: S,
      transitions: Map[(S, E), (S, Option[() => Unit])]
    ):
      def addTransition(from: S, event: E, to: S, action: Option[() => Unit] = None): StateMachineBuilder[S, E] =
        copy(transitions = transitions + ((from, event) -> (to, action)))

      def build: StateMachine[S, E] =
        new StateMachine(initialState, transitions)

  // ============================================================
  // 8. Actor風の実装
  // ============================================================

  /**
   * メッセージ
   */
  trait Message

  /**
   * Actor
   */
  abstract class Actor[M <: Message]:
    private val mailbox = new java.util.concurrent.LinkedBlockingQueue[M]()
    @volatile private var running = false
    private var thread: Thread = null

    def receive(message: M): Unit

    def send(message: M): Unit =
      mailbox.put(message)

    def start(): Unit =
      if !running then
        running = true
        thread = new Thread(() => {
          while running do
            try
              val message = mailbox.take()
              receive(message)
            catch
              case _: InterruptedException => running = false
        })
        thread.start()

    def stop(): Unit =
      running = false
      if thread != null then thread.interrupt()

    def isRunning: Boolean = running

  // ============================================================
  // 9. タスクキュー
  // ============================================================

  /**
   * タスク
   */
  case class Task[T](
    id: String,
    computation: () => T,
    promise: Promise[T] = Promise[T]()
  ):
    def future: Future[T] = promise.future

  /**
   * タスクキュー
   */
  class TaskQueue[T](workers: Int = 4)(using ec: ExecutionContext):
    private val queue = new java.util.concurrent.LinkedBlockingQueue[Task[T]]()
    @volatile private var running = false
    private var workerThreads: List[Thread] = Nil

    def submit(id: String, computation: () => T): Future[T] =
      val task = Task(id, computation)
      queue.put(task)
      task.future

    def start(): Unit =
      if !running then
        running = true
        workerThreads = (1 to workers).map { i =>
          val t = new Thread(() => {
            while running do
              try
                val task = queue.poll(100, java.util.concurrent.TimeUnit.MILLISECONDS)
                if task != null then
                  try
                    val result = task.computation()
                    task.promise.success(result)
                  catch
                    case e: Exception => task.promise.failure(e)
              catch
                case _: InterruptedException => ()
          }, s"TaskQueue-Worker-$i")
          t.start()
          t
        }.toList

    def stop(): Unit =
      running = false
      workerThreads.foreach(_.interrupt())

    def isRunning: Boolean = running
    def pendingTasks: Int = queue.size()

  // ============================================================
  // 10. Pub/Sub システム
  // ============================================================

  /**
   * トピック
   */
  class Topic[T](name: String):
    private val subscribers = TrieMap.empty[String, T => Unit]

    def subscribe(subscriberId: String, handler: T => Unit): Unit =
      subscribers.put(subscriberId, handler)

    def unsubscribe(subscriberId: String): Unit =
      subscribers.remove(subscriberId)

    def publish(message: T): Unit =
      subscribers.values.foreach { handler =>
        try handler(message)
        catch case e: Exception => println(s"Handler error: ${e.getMessage}")
      }

    def subscriberCount: Int = subscribers.size

  /**
   * メッセージブローカー
   */
  class MessageBroker:
    private val topics = TrieMap.empty[String, Topic[Any]]

    def getTopic[T](name: String): Topic[T] =
      topics.getOrElseUpdate(name, new Topic[Any](name)).asInstanceOf[Topic[T]]

    def removeTopic(name: String): Unit =
      topics.remove(name)

    def topicNames: Set[String] = topics.keySet.toSet

  // ============================================================
  // 11. 遅延実行
  // ============================================================

  /**
   * スケジューラー
   */
  class Scheduler(using ec: ExecutionContext):
    import java.util.concurrent.{ScheduledExecutorService, Executors, TimeUnit}

    private val executor: ScheduledExecutorService = Executors.newScheduledThreadPool(2)

    /**
     * 遅延実行
     */
    def delay[T](delayMs: Long)(computation: => T): Future[T] =
      val promise = Promise[T]()
      executor.schedule(
        new Runnable {
          def run(): Unit =
            try promise.success(computation)
            catch case e: Exception => promise.failure(e)
        },
        delayMs,
        TimeUnit.MILLISECONDS
      )
      promise.future

    /**
     * 定期実行
     */
    def repeat(initialDelayMs: Long, periodMs: Long)(action: => Unit): java.util.concurrent.ScheduledFuture[_] =
      executor.scheduleAtFixedRate(
        new Runnable { def run(): Unit = action },
        initialDelayMs,
        periodMs,
        TimeUnit.MILLISECONDS
      )

    def shutdown(): Unit =
      executor.shutdown()

  // ============================================================
  // 12. 並行カウンター
  // ============================================================

  /**
   * アトミックカウンター
   */
  class AtomicCounter(initial: Long = 0):
    private val counter = new java.util.concurrent.atomic.AtomicLong(initial)

    def get: Long = counter.get()
    def increment: Long = counter.incrementAndGet()
    def decrement: Long = counter.decrementAndGet()
    def add(delta: Long): Long = counter.addAndGet(delta)
    def reset(): Unit = counter.set(initial)

  /**
   * 並行マップ
   */
  class ConcurrentMap[K, V]:
    private val map = TrieMap.empty[K, V]

    def put(key: K, value: V): Option[V] = map.put(key, value)
    def get(key: K): Option[V] = map.get(key)
    def remove(key: K): Option[V] = map.remove(key)
    def contains(key: K): Boolean = map.contains(key)
    def size: Int = map.size
    def keys: Iterable[K] = map.keys
    def values: Iterable[V] = map.values
    def clear(): Unit = map.clear()

    def getOrElseUpdate(key: K, default: => V): V =
      map.getOrElseUpdate(key, default)

    def updateWith(key: K)(f: Option[V] => Option[V]): Option[V] =
      map.updateWith(key)(f)
