import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import WatorSimulation.*

import scala.util.Random

class WatorSimulationSpec extends AnyFunSpec with Matchers:

  describe("Position"):
    it("座標の加算ができる"):
      val p1 = Position(1, 2)
      val p2 = Position(3, 4)
      (p1 + p2) shouldBe Position(4, 6)

  describe("Cell"):
    describe("Water"):
      it("表示文字は '.'"):
        Water.display shouldBe '.'

    describe("Fish"):
      it("表示文字は 'f'"):
        Fish().display shouldBe 'f'

      it("初期年齢は0"):
        Fish().age shouldBe 0

      it("年齢を設定できる"):
        Fish(age = 5).age shouldBe 5

      it("年齢をインクリメントできる"):
        Fish(age = 3).incrementAge shouldBe Fish(age = 4)

    describe("Shark"):
      it("表示文字は 'S'"):
        Shark().display shouldBe 'S'

      it("初期年齢は0"):
        Shark().age shouldBe 0

      it("初期体力はConfig値"):
        Shark().health shouldBe Config.sharkStartingHealth

      it("年齢を設定できる"):
        Shark(age = 5).age shouldBe 5

      it("体力を減らせる"):
        Shark(health = 5).decrementHealth.health shouldBe 4

      it("捕食で体力が回復する"):
        val shark = Shark(health = 3).feed
        shark.health shouldBe math.min(Config.sharkMaxHealth, 3 + Config.sharkEatingHealth)

      it("最大体力を超えない"):
        val shark = Shark(health = Config.sharkMaxHealth - 1).feed
        shark.health shouldBe Config.sharkMaxHealth

  describe("World"):
    describe("作成"):
      it("空のワールドを作成できる"):
        val world = World(5, 5)
        world.width shouldBe 5
        world.height shouldBe 5
        world.cells.size shouldBe 25

      it("すべてのセルは水"):
        val world = World(3, 3)
        world.allPositions.foreach { pos =>
          world.getCell(pos) shouldBe Water
        }

    describe("座標のラップ"):
      it("正の座標はそのまま"):
        val world = World(5, 5)
        world.wrap(Position(2, 3)) shouldBe Position(2, 3)

      it("負の座標はラップする"):
        val world = World(5, 5)
        world.wrap(Position(-1, -1)) shouldBe Position(4, 4)

      it("幅を超える座標はラップする"):
        val world = World(5, 5)
        world.wrap(Position(6, 7)) shouldBe Position(1, 2)

    describe("セルの操作"):
      it("セルを取得できる"):
        val world = World(5, 5).setCell(Position(2, 2), Fish())
        world.getCell(Position(2, 2)) shouldBe a[Fish]

      it("セルを設定できる"):
        val world = World(5, 5)
        val updated = world.setCell(Position(1, 1), Shark())
        updated.getCell(Position(1, 1)) shouldBe a[Shark]

      it("ラップした座標で設定できる"):
        val world = World(5, 5).setCell(Position(6, 6), Fish())
        world.getCell(Position(1, 1)) shouldBe a[Fish]

    describe("隣接セル"):
      it("8方向の隣接セルを取得できる"):
        val world = World(5, 5)
        val neighbors = world.neighbors(Position(2, 2))
        neighbors.length shouldBe 8

      it("端の隣接セルはラップする"):
        val world = World(5, 5)
        val neighbors = world.neighbors(Position(0, 0))
        neighbors should contain(Position(4, 4))
        neighbors should contain(Position(4, 0))
        neighbors should contain(Position(0, 4))

      it("空の隣接セルを取得できる"):
        val world = World(3, 3)
          .setCell(Position(1, 0), Fish())
          .setCell(Position(0, 1), Shark())
        val empty = world.emptyNeighbors(Position(1, 1))
        empty should contain(Position(2, 0))
        empty should not contain Position(1, 0)

      it("隣接する魚を取得できる"):
        val world = World(3, 3)
          .setCell(Position(1, 0), Fish())
          .setCell(Position(0, 1), Fish())
          .setCell(Position(2, 1), Shark())
        val fishCells = world.fishNeighbors(Position(1, 1))
        fishCells should contain(Position(1, 0))
        fishCells should contain(Position(0, 1))
        fishCells should not contain Position(2, 1)

    describe("表示"):
      it("ワールドを文字列で表示できる"):
        val world = World(3, 3)
          .setCell(Position(1, 1), Fish())
          .setCell(Position(0, 0), Shark())
        val display = world.display
        display should include("S")
        display should include("f")
        display should include(".")

    describe("統計情報"):
      it("統計情報を取得できる"):
        val world = World(5, 5)
          .setCell(Position(0, 0), Fish())
          .setCell(Position(1, 1), Fish())
          .setCell(Position(2, 2), Shark())
        val stats = world.statistics
        stats.fish shouldBe 2
        stats.sharks shouldBe 1
        stats.water shouldBe 22

    describe("ランダム配置"):
      it("魚とサメをランダムに配置できる"):
        val world = World.populateRandom(World(10, 10), 20, 5, new Random(42))
        val stats = world.statistics
        stats.fish shouldBe 20
        stats.sharks shouldBe 5

  describe("Simulation"):
    describe("tryMove"):
      it("空の隣接セルがあれば移動できる"):
        val world = World(3, 3).setCell(Position(1, 1), Fish())
        val result = Simulation.tryMove(Fish(), Position(1, 1), world, new Random(42))
        result shouldBe defined

      it("空の隣接セルがなければ移動できない"):
        val world = World(1, 1).setCell(Position(0, 0), Fish())
        val result = Simulation.tryMove(Fish(), Position(0, 0), world, new Random(42))
        result shouldBe None

    describe("tryReproduce"):
      it("繁殖可能年齢に達していれば繁殖できる"):
        val world = World(3, 3).setCell(Position(1, 1), Fish(age = 6))
        val result = Simulation.tryReproduce(Fish(age = 6), Position(1, 1), world, new Random(42))
        result shouldBe defined

      it("繁殖可能年齢未満なら繁殖しない"):
        val world = World(3, 3).setCell(Position(1, 1), Fish(age = 3))
        val result = Simulation.tryReproduce(Fish(age = 3), Position(1, 1), world, new Random(42))
        result shouldBe None

      it("空の隣接セルがなければ繁殖できない"):
        // 周囲をすべて埋める
        var world = World(3, 3)
        for
          x <- 0 until 3
          y <- 0 until 3
        do
          world = world.setCell(Position(x, y), Fish())

        val result = Simulation.tryReproduce(Fish(age = 10), Position(1, 1), world, new Random(42))
        result shouldBe None

    describe("tryEat"):
      it("隣接する魚がいれば捕食できる"):
        val world = World(3, 3)
          .setCell(Position(1, 1), Shark())
          .setCell(Position(1, 0), Fish())
        val result = Simulation.tryEat(Shark(), Position(1, 1), world, new Random(42))
        result shouldBe defined
        result.get.cell.asInstanceOf[Shark].health shouldBe (Config.sharkStartingHealth + Config.sharkEatingHealth).min(Config.sharkMaxHealth)

      it("隣接する魚がいなければ捕食できない"):
        val world = World(3, 3).setCell(Position(1, 1), Shark())
        val result = Simulation.tryEat(Shark(), Position(1, 1), world, new Random(42))
        result shouldBe None

    describe("tickFish"):
      it("魚は年齢が増加する"):
        val world = World(3, 3).setCell(Position(1, 1), Fish(age = 0))
        val update = Simulation.tickFish(Fish(age = 0), Position(1, 1), world, new Random(42))
        update match
          case Move(_, _, cell) =>
            cell.asInstanceOf[Fish].age shouldBe 1
          case Reproduce(_, _, parentCell, _) =>
            parentCell.asInstanceOf[Fish].age shouldBe 0 // リセット
          case NoChange =>
            // 移動できない場合
          case _ => fail("Unexpected update type")

    describe("tickShark"):
      it("体力が0以下になると死亡する"):
        val update = Simulation.tickShark(Shark(health = 1), Position(1, 1), World(3, 3), new Random(42))
        update shouldBe Die(Position(1, 1))

      it("体力が減少する"):
        val world = World(3, 3).setCell(Position(1, 1), Shark(health = 5))
        val update = Simulation.tickShark(Shark(health = 5, age = 0), Position(1, 1), world, new Random(42))
        update match
          case Move(_, _, cell) =>
            cell.asInstanceOf[Shark].health shouldBe 4
          case Reproduce(_, _, parentCell, _) =>
            parentCell.asInstanceOf[Shark].health shouldBe 4
          case NoChange =>
            // 移動できない場合
          case _ => fail("Unexpected update type")

    describe("applyUpdate"):
      it("Move更新を適用できる"):
        val world = World(3, 3).setCell(Position(1, 1), Fish())
        val updated = Simulation.applyUpdate(world, Move(Position(1, 1), Position(2, 2), Fish(age = 1)))
        updated.getCell(Position(1, 1)) shouldBe Water
        updated.getCell(Position(2, 2)) shouldBe a[Fish]

      it("Reproduce更新を適用できる"):
        val world = World(3, 3).setCell(Position(1, 1), Fish(age = 6))
        val updated = Simulation.applyUpdate(world, Reproduce(Position(1, 1), Position(2, 2), Fish(age = 0), Fish()))
        updated.getCell(Position(1, 1)) shouldBe a[Fish]
        updated.getCell(Position(2, 2)) shouldBe a[Fish]

      it("Eat更新を適用できる"):
        val world = World(3, 3)
          .setCell(Position(1, 1), Shark())
          .setCell(Position(2, 2), Fish())
        val updated = Simulation.applyUpdate(world, Eat(Position(1, 1), Position(2, 2), Shark().feed))
        updated.getCell(Position(1, 1)) shouldBe Water
        updated.getCell(Position(2, 2)) shouldBe a[Shark]

      it("Die更新を適用できる"):
        val world = World(3, 3).setCell(Position(1, 1), Shark())
        val updated = Simulation.applyUpdate(world, Die(Position(1, 1)))
        updated.getCell(Position(1, 1)) shouldBe Water

    describe("tick"):
      it("世代が増加する"):
        val world = World(3, 3)
        val updated = Simulation.tick(world)
        updated.generation shouldBe 1

      it("複数ステップ実行できる"):
        val world = World.populateRandom(World(10, 10), 10, 2, new Random(42))
        val updated = Simulation.run(world, 10, new Random(42))
        updated.generation shouldBe 10

      it("履歴付きで実行できる"):
        val world = World.populateRandom(World(10, 10), 10, 2, new Random(42))
        val history = Simulation.runWithHistory(world, 5, new Random(42))
        history.length shouldBe 6 // 初期状態 + 5ステップ

  describe("SimulationBuilder"):
    it("ビルダーでシミュレーションを構築できる"):
      val world = SimulationBuilder()
        .withSize(10, 10)
        .withFish(20)
        .withSharks(5)
        .withSeed(42)
        .build

      world.width shouldBe 10
      world.height shouldBe 10
      val stats = world.statistics
      stats.fish shouldBe 20
      stats.sharks shouldBe 5

    it("セルを直接配置できる"):
      val world = SimulationBuilder()
        .withSize(5, 5)
        .withCell(Position(2, 2), Fish(age = 5))
        .withCell(Position(3, 3), Shark(age = 3, health = 8))
        .build

      world.getCell(Position(2, 2)) shouldBe Fish(age = 5)
      world.getCell(Position(3, 3)) shouldBe Shark(age = 3, health = 8)

  describe("DSL"):
    import DSL.*

    it("DSLでワールドを作成できる"):
      val w = world(5, 5)
      w.width shouldBe 5

    it("DSLで魚を配置できる"):
      val w = world(5, 5).placeFish(pos(2, 2))
      w.getCell(pos(2, 2)) shouldBe a[Fish]

    it("DSLでサメを配置できる"):
      val w = world(5, 5).placeShark(pos(2, 2))
      w.getCell(pos(2, 2)) shouldBe a[Shark]

    it("DSLでステップを実行できる"):
      val w = world(5, 5).step
      w.generation shouldBe 1

    it("DSLで複数ステップを実行できる"):
      val w = world(5, 5).steps(10)
      w.generation shouldBe 10

    it("DSLで履歴を取得できる"):
      val h = world(5, 5).history(5)
      h.length shouldBe 6

  describe("Combinators"):
    import Combinators.*

    it("条件が満たされるまで実行できる"):
      val world = World.populateRandom(World(10, 10), 50, 10, new Random(42))
      val (result, steps) = runUntil(world, w => w.statistics.sharks == 0, maxSteps = 100)
      // サメが絶滅するまで実行
      steps should be <= 100

    it("統計情報を収集できる"):
      val world = World.populateRandom(World(10, 10), 10, 2, new Random(42))
      val stats = runWithStats(world, 5)
      stats.length shouldBe 6
      stats.head._1 shouldBe 0

    it("絶滅判定ができる"):
      val world = World(5, 5).setCell(Position(0, 0), Fish())
      isExtinct(world) shouldBe true // サメがいない

      val world2 = World(5, 5)
        .setCell(Position(0, 0), Fish())
        .setCell(Position(1, 1), Shark())
      isExtinct(world2) shouldBe false

    it("安定判定ができる"):
      val world = World.populateRandom(World(10, 10), 30, 5, new Random(42))
      isStable(world, 20, 40, 3, 10) shouldBe true
      isStable(world, 50, 60, 3, 10) shouldBe false

  describe("Visualizer"):
    import Visualizer.*

    it("ASCIIアートで表示できる"):
      val world = World(3, 3)
        .setCell(Position(1, 1), Fish())
        .setCell(Position(0, 0), Shark())
      val ascii = toAscii(world)
      ascii should include("S")
      ascii should include("f")

    it("統計情報を文字列で表示できる"):
      val stats = Statistics(10, 5, 85, 42)
      val str = statsToString(stats)
      str should include("42")
      str should include("10")
      str should include("5")

  describe("シミュレーションシナリオ"):
    it("魚だけのワールドでは魚が繁殖する"):
      val world = World.populateRandom(World(10, 10), 10, 0, new Random(42))
      val result = Simulation.run(world, 20, new Random(42))
      result.statistics.fish should be >= 10

    it("サメだけのワールドではサメは餓死する"):
      val world = World.populateRandom(World(5, 5), 0, 5, new Random(42))
      val result = Simulation.run(world, 20, new Random(42))
      result.statistics.sharks should be < 5

    it("捕食者と被食者の相互作用"):
      val random = new Random(42)
      val world = World.populateRandom(World(20, 20), 100, 20, random)
      val history = Simulation.runWithHistory(world, 50, random)

      // シミュレーションが動作することを確認
      history.length shouldBe 51
      // 個体数が変動することを確認
      val fishCounts = history.map(_.statistics.fish)
      fishCounts.distinct.size should be > 1
