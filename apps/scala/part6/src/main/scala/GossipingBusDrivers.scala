/**
 * 第15章: ゴシップ好きなバスの運転手
 *
 * バス運転手が停留所で出会ったときに噂を共有するシミュレーション。
 * 全ての運転手が全ての噂を知るまでに何分かかるかを計算します。
 */
object GossipingBusDrivers:

  // ============================================================
  // 1. データモデル
  // ============================================================

  /**
   * 噂を表す型
   */
  type Rumor = String

  /**
   * 停留所を表す型
   */
  type Stop = Int

  /**
   * ドライバーを表すケースクラス
   *
   * @param name ドライバーの名前
   * @param route 停留所の循環ルート（元のルート）
   * @param position 現在のルート位置
   * @param rumors 知っている噂の集合
   */
  case class Driver(
    name: String,
    route: Vector[Stop],
    position: Int,
    rumors: Set[Rumor]
  ):
    /**
     * 現在の停留所を取得
     */
    def currentStop: Stop = route(position % route.length)

    /**
     * 次の停留所に移動
     */
    def move: Driver = copy(position = position + 1)

    /**
     * 噂を追加
     */
    def addRumors(newRumors: Set[Rumor]): Driver = copy(rumors = rumors ++ newRumors)

  object Driver:
    /**
     * ドライバーを作成（初期位置は0）
     */
    def apply(name: String, route: Seq[Stop], rumors: Set[Rumor]): Driver =
      Driver(name, route.toVector, 0, rumors)

    /**
     * 初期噂を自動生成してドライバーを作成
     */
    def withAutoRumor(name: String, route: Seq[Stop]): Driver =
      Driver(name, route.toVector, 0, Set(s"rumor-$name"))

  // ============================================================
  // 2. ワールド（シミュレーション状態）
  // ============================================================

  /**
   * シミュレーション世界を表すケースクラス
   *
   * @param drivers 全ドライバーのリスト
   * @param time 経過時間（分）
   */
  case class World(drivers: Vector[Driver], time: Int = 0):

    /**
     * 全ドライバーを移動
     */
    def moveDrivers: World = copy(drivers = drivers.map(_.move))

    /**
     * 各停留所にいるドライバーをグループ化
     */
    def driversByStop: Map[Stop, Vector[Driver]] =
      drivers.groupBy(_.currentStop)

    /**
     * 同じ停留所にいるドライバー間で噂を共有
     */
    def spreadRumors: World =
      val newDrivers = driversByStop.values.flatMap { driversAtStop =>
        val allRumors = driversAtStop.flatMap(_.rumors).toSet
        driversAtStop.map(_.addRumors(allRumors))
      }.toVector
      // 元の順序を保持
      copy(drivers = drivers.map(d => newDrivers.find(_.name == d.name).getOrElse(d)))

    /**
     * 1ステップ実行（移動→噂の伝播）
     */
    def step: World =
      this.moveDrivers.spreadRumors.copy(time = time + 1)

    /**
     * 全ドライバーが同じ噂を持っているか確認
     */
    def allRumorsShared: Boolean =
      if drivers.isEmpty then true
      else drivers.map(_.rumors).distinct.length == 1

    /**
     * 全噂の集合
     */
    def allRumors: Set[Rumor] = drivers.flatMap(_.rumors).toSet

  object World:
    def apply(drivers: Driver*): World = World(drivers.toVector, 0)
    def fromSeq(drivers: Seq[Driver]): World = World(drivers.toVector, 0)

  // ============================================================
  // 3. シミュレーション
  // ============================================================

  /**
   * シミュレーション結果
   */
  sealed trait SimulationResult
  case class Completed(minutes: Int) extends SimulationResult
  case object Never extends SimulationResult

  /**
   * シミュレーションを実行
   *
   * @param world 初期状態
   * @param maxMinutes 最大シミュレーション時間（デフォルト480分=8時間）
   * @return シミュレーション結果
   */
  def simulate(world: World, maxMinutes: Int = 480): SimulationResult =
    @annotation.tailrec
    def loop(current: World): SimulationResult =
      if current.time > maxMinutes then Never
      else if current.allRumorsShared then Completed(current.time)
      else loop(current.step)

    // 最初のステップを実行してから判定開始
    if world.drivers.length <= 1 then Completed(0)
    else if world.allRumorsShared then Completed(0)  // 初期状態で完了している場合
    else loop(world.step)

  /**
   * シミュレーションを実行し、経過を記録
   */
  def simulateWithHistory(world: World, maxMinutes: Int = 480): (SimulationResult, List[World]) =
    @annotation.tailrec
    def loop(current: World, history: List[World]): (SimulationResult, List[World]) =
      if current.time > maxMinutes then (Never, history.reverse)
      else if current.allRumorsShared then (Completed(current.time), (current :: history).reverse)
      else loop(current.step, current :: history)

    if world.drivers.length <= 1 then (Completed(0), List(world))
    else loop(world.step, List(world))

  // ============================================================
  // 4. ヘルパー関数
  // ============================================================

  /**
   * ドライバーが特定の時間後にどの停留所にいるかを計算
   */
  def stopAtTime(driver: Driver, time: Int): Stop =
    driver.route((driver.position + time) % driver.route.length)

  /**
   * 2人のドライバーが出会う最初の時間を計算
   */
  def firstMeetingTime(d1: Driver, d2: Driver, maxTime: Int = 480): Option[Int] =
    (0 to maxTime).find { t =>
      stopAtTime(d1, t) == stopAtTime(d2, t)
    }

  /**
   * ルートの最小公倍数を計算（ルートが完全に一致するまでの時間）
   */
  def routeLcm(routes: Seq[Vector[Stop]]): Int =
    def gcd(a: Int, b: Int): Int = if b == 0 then a else gcd(b, a % b)
    def lcm(a: Int, b: Int): Int = a * b / gcd(a, b)
    routes.map(_.length).reduce(lcm)

  // ============================================================
  // 5. 拡張シミュレーション
  // ============================================================

  /**
   * 遅延付きドライバー（休憩を取る）
   */
  case class DelayedDriver(
    name: String,
    route: Vector[Stop],
    position: Int,
    rumors: Set[Rumor],
    delay: Int = 0,  // 現在の遅延（停留所に留まる時間）
    delayPattern: Vector[Int] = Vector.empty  // 各停留所での遅延パターン
  ):
    def currentStop: Stop = route(position % route.length)

    def move: DelayedDriver =
      if delay > 0 then
        copy(delay = delay - 1)
      else
        val nextPos = position + 1
        val nextDelay = if delayPattern.nonEmpty then
          delayPattern(nextPos % delayPattern.length)
        else 0
        copy(position = nextPos, delay = nextDelay)

    def addRumors(newRumors: Set[Rumor]): DelayedDriver =
      copy(rumors = rumors ++ newRumors)

  /**
   * 遅延付きワールド
   */
  case class DelayedWorld(drivers: Vector[DelayedDriver], time: Int = 0):
    def moveDrivers: DelayedWorld = copy(drivers = drivers.map(_.move))

    def driversByStop: Map[Stop, Vector[DelayedDriver]] =
      drivers.groupBy(_.currentStop)

    def spreadRumors: DelayedWorld =
      val newDrivers = driversByStop.values.flatMap { driversAtStop =>
        val allRumors = driversAtStop.flatMap(_.rumors).toSet
        driversAtStop.map(_.addRumors(allRumors))
      }.toVector
      copy(drivers = drivers.map(d => newDrivers.find(_.name == d.name).getOrElse(d)))

    def step: DelayedWorld =
      this.moveDrivers.spreadRumors.copy(time = time + 1)

    def allRumorsShared: Boolean =
      if drivers.isEmpty then true
      else drivers.map(_.rumors).distinct.length == 1

  def simulateDelayed(world: DelayedWorld, maxMinutes: Int = 480): SimulationResult =
    @annotation.tailrec
    def loop(current: DelayedWorld): SimulationResult =
      if current.time > maxMinutes then Never
      else if current.allRumorsShared then Completed(current.time)
      else loop(current.step)

    if world.drivers.length <= 1 then Completed(0)
    else if world.allRumorsShared then Completed(0)
    else loop(world.step)

  // ============================================================
  // 6. 統計情報
  // ============================================================

  /**
   * シミュレーション統計
   */
  case class SimulationStats(
    totalMinutes: Int,
    totalMeetings: Int,
    meetingsByStop: Map[Stop, Int],
    rumorSpreadTimeline: List[(Int, Int)]  // (時間, 噂の共有数)
  )

  /**
   * 統計情報付きシミュレーション
   */
  def simulateWithStats(world: World, maxMinutes: Int = 480): (SimulationResult, SimulationStats) =
    var meetings = 0
    var meetingsByStop = Map.empty[Stop, Int].withDefaultValue(0)
    var timeline = List.empty[(Int, Int)]

    @annotation.tailrec
    def loop(current: World): (SimulationResult, SimulationStats) =
      // 統計情報を収集
      val currentMeetings = current.driversByStop.values.count(_.length > 1)
      meetings += currentMeetings
      current.driversByStop.foreach { case (stop, drivers) =>
        if drivers.length > 1 then
          meetingsByStop = meetingsByStop.updated(stop, meetingsByStop(stop) + 1)
      }
      val sharedCount = current.drivers.head.rumors.size
      timeline = (current.time, sharedCount) :: timeline

      if current.time > maxMinutes then
        (Never, SimulationStats(current.time, meetings, meetingsByStop, timeline.reverse))
      else if current.allRumorsShared then
        (Completed(current.time), SimulationStats(current.time, meetings, meetingsByStop, timeline.reverse))
      else loop(current.step)

    if world.drivers.length <= 1 then
      (Completed(0), SimulationStats(0, 0, Map.empty, List.empty))
    else loop(world.step)

  // ============================================================
  // 7. ビルダーパターン
  // ============================================================

  /**
   * シミュレーションビルダー
   */
  class SimulationBuilder:
    private var drivers = Vector.empty[Driver]
    private var maxMinutes = 480

    def addDriver(name: String, route: Seq[Stop], rumors: Set[Rumor]): SimulationBuilder =
      drivers = drivers :+ Driver(name, route, rumors)
      this

    def addDriverWithAutoRumor(name: String, route: Seq[Stop]): SimulationBuilder =
      drivers = drivers :+ Driver.withAutoRumor(name, route)
      this

    def withMaxMinutes(minutes: Int): SimulationBuilder =
      maxMinutes = minutes
      this

    def build: World = World(drivers)

    def run: SimulationResult = simulate(World(drivers), maxMinutes)

    def runWithHistory: (SimulationResult, List[World]) =
      simulateWithHistory(World(drivers), maxMinutes)

    def runWithStats: (SimulationResult, SimulationStats) =
      simulateWithStats(World(drivers), maxMinutes)

  def builder: SimulationBuilder = new SimulationBuilder

  // ============================================================
  // 8. DSL for route definition
  // ============================================================

  /**
   * ルート定義用のDSL
   */
  object RouteDSL:
    /**
     * ルートを範囲で定義
     */
    def range(start: Int, end: Int): Seq[Stop] = start to end

    /**
     * ルートを逆順で定義
     */
    def reverse(route: Seq[Stop]): Seq[Stop] = route.reverse

    /**
     * ルートを往復で定義
     * [1,2,3] -> [1,2,3,2,1]
     */
    def roundTrip(route: Seq[Stop]): Seq[Stop] =
      if route.length <= 1 then route
      else route ++ route.reverse.tail

    /**
     * 複数のセグメントを結合
     */
    def concat(segments: Seq[Stop]*): Seq[Stop] = segments.flatten

  // ============================================================
  // 9. 関数型コンビネータ
  // ============================================================

  /**
   * 世界の変換関数の型
   */
  type WorldTransform = World => World

  /**
   * 変換を合成
   */
  def compose(transforms: WorldTransform*): WorldTransform =
    transforms.reduce(_ andThen _)

  /**
   * 条件付き変換
   */
  def when(condition: World => Boolean)(transform: WorldTransform): WorldTransform =
    world => if condition(world) then transform(world) else world

  /**
   * N回変換を適用
   */
  def repeat(n: Int)(transform: WorldTransform): WorldTransform =
    world => (1 to n).foldLeft(world)((w, _) => transform(w))

  /**
   * 条件が満たされるまで変換を適用
   */
  def until(condition: World => Boolean)(transform: WorldTransform): World => World =
    world =>
      @annotation.tailrec
      def loop(current: World): World =
        if condition(current) then current
        else loop(transform(current))
      loop(world)
