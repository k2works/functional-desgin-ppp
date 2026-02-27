/**
 * 第19章: Wa-Tor シミュレーション
 *
 * セルオートマトンによる捕食者-被食者モデルの実装。
 * 魚（被食者）とサメ（捕食者）の生態系シミュレーション。
 */
import scala.util.Random

object WatorSimulation:

  // ============================================================
  // 1. 設定パラメータ
  // ============================================================

  object Config:
    // 魚の設定
    val fishReproductionAge: Int = 6

    // サメの設定
    val sharkReproductionAge: Int = 5
    val sharkReproductionHealth: Int = 8
    val sharkStartingHealth: Int = 5
    val sharkEatingHealth: Int = 5
    val sharkMaxHealth: Int = 10

  // ============================================================
  // 2. 座標と方向
  // ============================================================

  case class Position(x: Int, y: Int):
    def +(other: Position): Position = Position(x + other.x, y + other.y)

  object Direction:
    val deltas: Seq[Position] = for
      dx <- Seq(-1, 0, 1)
      dy <- Seq(-1, 0, 1)
      if !(dx == 0 && dy == 0)
    yield Position(dx, dy)

  // ============================================================
  // 3. セルの定義
  // ============================================================

  /**
   * セルの基底trait
   */
  sealed trait Cell:
    def display: Char

  /**
   * 水（空のセル）
   */
  case object Water extends Cell:
    def display: Char = '.'

  /**
   * 動物の共通属性
   */
  sealed trait Animal extends Cell:
    def age: Int
    def withAge(newAge: Int): Animal
    def incrementAge: Animal = withAge(age + 1)
    def reproductionAge: Int

  /**
   * 魚（被食者）
   */
  case class Fish(age: Int = 0) extends Animal:
    def display: Char = 'f'
    def withAge(newAge: Int): Fish = copy(age = newAge)
    def reproductionAge: Int = Config.fishReproductionAge

  /**
   * サメ（捕食者）
   */
  case class Shark(age: Int = 0, health: Int = Config.sharkStartingHealth) extends Animal:
    def display: Char = 'S'
    def withAge(newAge: Int): Shark = copy(age = newAge)
    def reproductionAge: Int = Config.sharkReproductionAge

    def withHealth(newHealth: Int): Shark = copy(health = newHealth)
    def decrementHealth: Shark = copy(health = health - 1)
    def feed: Shark =
      val newHealth = math.min(Config.sharkMaxHealth, health + Config.sharkEatingHealth)
      copy(health = newHealth)

  // ============================================================
  // 4. ワールド
  // ============================================================

  /**
   * シミュレーションワールド
   */
  case class World(
    width: Int,
    height: Int,
    cells: Map[Position, Cell],
    generation: Int = 0
  ):
    /**
     * 座標をトーラス上でラップ
     */
    def wrap(pos: Position): Position =
      Position(
        ((pos.x % width) + width) % width,
        ((pos.y % height) + height) % height
      )

    /**
     * セルを取得
     */
    def getCell(pos: Position): Cell =
      cells.getOrElse(wrap(pos), Water)

    /**
     * セルを設定
     */
    def setCell(pos: Position, cell: Cell): World =
      copy(cells = cells + (wrap(pos) -> cell))

    /**
     * 隣接セルの座標を取得（8方向）
     */
    def neighbors(pos: Position): Seq[Position] =
      Direction.deltas.map(d => wrap(pos + d))

    /**
     * 隣接する空のセルを取得
     */
    def emptyNeighbors(pos: Position): Seq[Position] =
      neighbors(pos).filter(p => getCell(p) == Water)

    /**
     * 隣接する魚のセルを取得
     */
    def fishNeighbors(pos: Position): Seq[Position] =
      neighbors(pos).filter(p => getCell(p).isInstanceOf[Fish])

    /**
     * ワールドの表示
     */
    def display: String =
      (0 until height).map { y =>
        (0 until width).map { x =>
          getCell(Position(x, y)).display
        }.mkString
      }.mkString("\n")

    /**
     * 統計情報
     */
    def statistics: Statistics =
      val cellList = cells.values.toList
      Statistics(
        fish = cellList.count(_.isInstanceOf[Fish]),
        sharks = cellList.count(_.isInstanceOf[Shark]),
        water = cellList.count(_ == Water),
        generation = generation
      )

    /**
     * 全座標を取得
     */
    def allPositions: Seq[Position] =
      for
        x <- 0 until width
        y <- 0 until height
      yield Position(x, y)

  case class Statistics(
    fish: Int,
    sharks: Int,
    water: Int,
    generation: Int
  ):
    def total: Int = fish + sharks + water

  object World:
    /**
     * 空のワールドを作成
     */
    def apply(width: Int, height: Int): World =
      val cells = (for
        x <- 0 until width
        y <- 0 until height
      yield Position(x, y) -> (Water: Cell)).toMap
      World(width, height, cells)

    /**
     * ランダムに生物を配置
     */
    def populateRandom(world: World, fishCount: Int, sharkCount: Int, random: Random = new Random): World =
      val positions = random.shuffle(world.allPositions.toList)
      val (fishPositions, rest) = positions.splitAt(fishCount)
      val sharkPositions = rest.take(sharkCount)

      val withFish = fishPositions.foldLeft(world) { (w, pos) =>
        w.setCell(pos, Fish())
      }
      sharkPositions.foldLeft(withFish) { (w, pos) =>
        w.setCell(pos, Shark())
      }

  // ============================================================
  // 5. アクション結果
  // ============================================================

  /**
   * セルの更新結果
   */
  sealed trait CellUpdate
  case class Move(from: Position, to: Position, cell: Cell) extends CellUpdate
  case class Reproduce(parent: Position, child: Position, parentCell: Cell, childCell: Cell) extends CellUpdate
  case class Eat(from: Position, to: Position, cell: Cell) extends CellUpdate
  case class Die(at: Position) extends CellUpdate
  case object NoChange extends CellUpdate

  // ============================================================
  // 6. シミュレーションロジック
  // ============================================================

  object Simulation:
    /**
     * 動物の移動を試みる
     */
    def tryMove(animal: Animal, pos: Position, world: World, random: Random): Option[Move] =
      val empty = world.emptyNeighbors(pos)
      if empty.isEmpty then None
      else
        val target = empty(random.nextInt(empty.length))
        Some(Move(pos, target, animal))

    /**
     * 動物の繁殖を試みる
     */
    def tryReproduce(animal: Animal, pos: Position, world: World, random: Random): Option[Reproduce] =
      if animal.age < animal.reproductionAge then None
      else
        val empty = world.emptyNeighbors(pos)
        if empty.isEmpty then None
        else
          val childPos = empty(random.nextInt(empty.length))
          val child = animal match
            case _: Fish => Fish()
            case _: Shark => Shark()
          Some(Reproduce(pos, childPos, animal.withAge(0), child))

    /**
     * サメの捕食を試みる
     */
    def tryEat(shark: Shark, pos: Position, world: World, random: Random): Option[Eat] =
      val fishCells = world.fishNeighbors(pos)
      if fishCells.isEmpty then None
      else
        val target = fishCells(random.nextInt(fishCells.length))
        Some(Eat(pos, target, shark.feed))

    /**
     * 魚のティック処理
     */
    def tickFish(fish: Fish, pos: Position, world: World, random: Random): CellUpdate =
      val agedFish = fish.incrementAge.asInstanceOf[Fish]

      // 優先順位: 繁殖 > 移動
      tryReproduce(agedFish, pos, world, random)
        .orElse(tryMove(agedFish, pos, world, random))
        .getOrElse(NoChange)

    /**
     * サメのティック処理
     */
    def tickShark(shark: Shark, pos: Position, world: World, random: Random): CellUpdate =
      // 体力が尽きたら死亡
      if shark.health <= 1 then
        return Die(pos)

      val agedShark = shark.incrementAge.asInstanceOf[Shark].decrementHealth

      // 優先順位: 繁殖 > 捕食 > 移動
      tryReproduce(agedShark, pos, world, random)
        .orElse(tryEat(agedShark, pos, world, random))
        .orElse(tryMove(agedShark, pos, world, random))
        .getOrElse(NoChange)

    /**
     * セルのティック処理
     */
    def tickCell(cell: Cell, pos: Position, world: World, random: Random): CellUpdate =
      cell match
        case Water => NoChange
        case fish: Fish => tickFish(fish, pos, world, random)
        case shark: Shark => tickShark(shark, pos, world, random)

    /**
     * 更新を適用
     */
    def applyUpdate(world: World, update: CellUpdate): World =
      update match
        case Move(from, to, cell) =>
          world.setCell(from, Water).setCell(to, cell)
        case Reproduce(parent, child, parentCell, childCell) =>
          world.setCell(parent, parentCell).setCell(child, childCell)
        case Eat(from, to, cell) =>
          world.setCell(from, Water).setCell(to, cell)
        case Die(at) =>
          world.setCell(at, Water)
        case NoChange =>
          world

    /**
     * ワールドの1ステップを実行
     */
    def tick(world: World, random: Random = new Random): World =
      val positions = random.shuffle(world.allPositions.toList)
      val processed = scala.collection.mutable.Set.empty[Position]

      val newWorld = positions.foldLeft(world) { (w, pos) =>
        if processed.contains(pos) then w
        else
          val cell = w.getCell(pos)
          val update = tickCell(cell, pos, w, random)

          update match
            case Move(from, to, _) =>
              processed += from
              processed += to
            case Reproduce(parent, child, _, _) =>
              processed += parent
              processed += child
            case Eat(from, to, _) =>
              processed += from
              processed += to
            case Die(at) =>
              processed += at
            case NoChange =>
              ()

          applyUpdate(w, update)
      }

      newWorld.copy(generation = newWorld.generation + 1)

    /**
     * N ステップ実行
     */
    def run(world: World, steps: Int, random: Random = new Random): World =
      (0 until steps).foldLeft(world)((w, _) => tick(w, random))

    /**
     * 履歴付きで実行
     */
    def runWithHistory(world: World, steps: Int, random: Random = new Random): List[World] =
      (0 until steps).scanLeft(world)((w, _) => tick(w, random)).toList

  // ============================================================
  // 7. シミュレーションビルダー
  // ============================================================

  class SimulationBuilder:
    private var width: Int = 10
    private var height: Int = 10
    private var fishCount: Int = 0
    private var sharkCount: Int = 0
    private var initialCells: Map[Position, Cell] = Map.empty
    private var seed: Option[Long] = None

    def withSize(w: Int, h: Int): SimulationBuilder =
      width = w
      height = h
      this

    def withFish(count: Int): SimulationBuilder =
      fishCount = count
      this

    def withSharks(count: Int): SimulationBuilder =
      sharkCount = count
      this

    def withCell(pos: Position, cell: Cell): SimulationBuilder =
      initialCells = initialCells + (pos -> cell)
      this

    def withSeed(s: Long): SimulationBuilder =
      seed = Some(s)
      this

    def build: World =
      val random = seed.map(new Random(_)).getOrElse(new Random)
      val baseWorld = World(width, height)

      // 初期セルを配置
      val withInitial = initialCells.foldLeft(baseWorld) { case (w, (pos, cell)) =>
        w.setCell(pos, cell)
      }

      // ランダムに生物を追加
      if fishCount > 0 || sharkCount > 0 then
        World.populateRandom(withInitial, fishCount, sharkCount, random)
      else
        withInitial

  object SimulationBuilder:
    def apply(): SimulationBuilder = new SimulationBuilder

  // ============================================================
  // 8. DSL
  // ============================================================

  object DSL:
    def world(width: Int, height: Int): World = World(width, height)

    def fish: Fish = Fish()
    def fish(age: Int): Fish = Fish(age)

    def shark: Shark = Shark()
    def shark(age: Int, health: Int): Shark = Shark(age, health)

    def at(pos: Position): Position = pos
    def pos(x: Int, y: Int): Position = Position(x, y)

    extension (w: World)
      def place(cell: Cell, pos: Position): World = w.setCell(pos, cell)
      def placeFish(pos: Position): World = w.setCell(pos, Fish())
      def placeShark(pos: Position): World = w.setCell(pos, Shark())
      def populate(fishCount: Int, sharkCount: Int): World =
        World.populateRandom(w, fishCount, sharkCount)
      def step: World = Simulation.tick(w)
      def steps(n: Int): World = Simulation.run(w, n)
      def history(n: Int): List[World] = Simulation.runWithHistory(w, n)

  // ============================================================
  // 9. 関数型コンビネータ
  // ============================================================

  object Combinators:
    /**
     * 条件が満たされるまでシミュレーションを実行
     */
    def runUntil(world: World, predicate: World => Boolean, maxSteps: Int = 1000): (World, Int) =
      var current = world
      var steps = 0
      while steps < maxSteps && !predicate(current) do
        current = Simulation.tick(current)
        steps += 1
      (current, steps)

    /**
     * 統計情報を収集しながらシミュレーションを実行
     */
    def runWithStats(world: World, steps: Int): List[(Int, Statistics)] =
      val history = Simulation.runWithHistory(world, steps)
      history.zipWithIndex.map { case (w, i) => (i, w.statistics) }

    /**
     * 絶滅判定
     */
    def isExtinct(world: World): Boolean =
      val stats = world.statistics
      stats.fish == 0 || stats.sharks == 0

    /**
     * 安定判定（個体数が一定範囲内）
     */
    def isStable(world: World, minFish: Int, maxFish: Int, minSharks: Int, maxSharks: Int): Boolean =
      val stats = world.statistics
      stats.fish >= minFish && stats.fish <= maxFish &&
      stats.sharks >= minSharks && stats.sharks <= maxSharks

  // ============================================================
  // 10. 可視化ヘルパー
  // ============================================================

  object Visualizer:
    /**
     * ASCIIアートで表示
     */
    def toAscii(world: World): String = world.display

    /**
     * 統計情報を文字列で表示
     */
    def statsToString(stats: Statistics): String =
      s"Gen: ${stats.generation}, Fish: ${stats.fish}, Sharks: ${stats.sharks}"

    /**
     * ヒストグラムを表示
     */
    def histogram(history: List[Statistics], maxWidth: Int = 50): String =
      if history.isEmpty then return ""

      val maxCount = math.max(history.map(_.fish).max, history.map(_.sharks).max)
      if maxCount == 0 then return "No data"

      history.zipWithIndex.map { case (stats, i) =>
        val fishBar = "f" * (stats.fish * maxWidth / maxCount)
        val sharkBar = "S" * (stats.sharks * maxWidth / maxWidth)
        f"$i%3d: $fishBar | $sharkBar"
      }.mkString("\n")
