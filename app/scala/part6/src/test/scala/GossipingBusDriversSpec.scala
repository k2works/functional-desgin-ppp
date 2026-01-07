import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers
import GossipingBusDrivers.*

class GossipingBusDriversSpec extends AnyFunSpec with Matchers:

  // ============================================================
  // 1. Driver データモデル
  // ============================================================

  describe("Driver"):

    describe("作成"):
      it("ルートと噂を持つドライバーを作成できる"):
        val driver = Driver("D1", Seq(1, 2, 3), Set("rumor-a"))
        driver.name shouldBe "D1"
        driver.route shouldBe Vector(1, 2, 3)
        driver.rumors shouldBe Set("rumor-a")

      it("自動噂付きドライバーを作成できる"):
        val driver = Driver.withAutoRumor("D1", Seq(1, 2, 3))
        driver.rumors shouldBe Set("rumor-D1")

    describe("現在の停留所"):
      it("初期位置の停留所を取得できる"):
        val driver = Driver("D1", Seq(1, 2, 3), Set.empty)
        driver.currentStop shouldBe 1

      it("移動後の停留所を取得できる"):
        val driver = Driver("D1", Seq(1, 2, 3), Set.empty).move
        driver.currentStop shouldBe 2

    describe("移動"):
      it("次の停留所に移動できる"):
        val driver = Driver("D1", Seq(1, 2, 3), Set.empty)
        driver.move.currentStop shouldBe 2
        driver.move.move.currentStop shouldBe 3

      it("ルートは循環する"):
        val driver = Driver("D1", Seq(1, 2, 3), Set.empty)
        val afterCycle = driver.move.move.move
        afterCycle.currentStop shouldBe 1

    describe("噂の追加"):
      it("噂を追加できる"):
        val driver = Driver("D1", Seq(1), Set("a"))
        val updated = driver.addRumors(Set("b", "c"))
        updated.rumors shouldBe Set("a", "b", "c")

      it("同じ噂は重複しない"):
        val driver = Driver("D1", Seq(1), Set("a"))
        val updated = driver.addRumors(Set("a", "b"))
        updated.rumors shouldBe Set("a", "b")

  // ============================================================
  // 2. World データモデル
  // ============================================================

  describe("World"):

    describe("ドライバーのグループ化"):
      it("同じ停留所のドライバーをグループ化できる"):
        val world = World(
          Driver("D1", Seq(1, 2), Set.empty),
          Driver("D2", Seq(1, 3), Set.empty),
          Driver("D3", Seq(2, 3), Set.empty)
        )
        val byStop = world.driversByStop
        byStop(1).map(_.name) should contain theSameElementsAs Vector("D1", "D2")
        byStop(2).map(_.name) should contain theSameElementsAs Vector("D3")

    describe("移動"):
      it("全ドライバーを移動できる"):
        val world = World(
          Driver("D1", Seq(1, 2), Set.empty),
          Driver("D2", Seq(3, 4), Set.empty)
        )
        val moved = world.moveDrivers
        moved.drivers.map(_.currentStop) should contain theSameElementsAs Vector(2, 4)

    describe("噂の伝播"):
      it("同じ停留所にいるドライバー間で噂が共有される"):
        val world = World(
          Driver("D1", Seq(1), Set("a")),
          Driver("D2", Seq(1), Set("b"))
        )
        val spread = world.spreadRumors
        spread.drivers.foreach { d =>
          d.rumors shouldBe Set("a", "b")
        }

      it("異なる停留所のドライバーは噂を共有しない"):
        val world = World(
          Driver("D1", Seq(1), Set("a")),
          Driver("D2", Seq(2), Set("b"))
        )
        val spread = world.spreadRumors
        spread.drivers.find(_.name == "D1").get.rumors shouldBe Set("a")
        spread.drivers.find(_.name == "D2").get.rumors shouldBe Set("b")

    describe("ステップ実行"):
      it("移動と噂伝播を1ステップで実行できる"):
        val world = World(
          Driver("D1", Seq(1, 2), Set("a")),
          Driver("D2", Seq(3, 2), Set("b"))
        )
        val stepped = world.step
        stepped.time shouldBe 1
        // 移動後、D1は2、D2は2で出会う
        stepped.drivers.find(_.name == "D1").get.currentStop shouldBe 2
        stepped.drivers.find(_.name == "D2").get.currentStop shouldBe 2
        stepped.drivers.foreach { d =>
          d.rumors shouldBe Set("a", "b")
        }

    describe("完了判定"):
      it("全ドライバーが同じ噂を持つと完了"):
        val world = World(
          Driver("D1", Seq(1), Set("a", "b")),
          Driver("D2", Seq(2), Set("a", "b"))
        )
        world.allRumorsShared shouldBe true

      it("噂が異なると未完了"):
        val world = World(
          Driver("D1", Seq(1), Set("a")),
          Driver("D2", Seq(2), Set("b"))
        )
        world.allRumorsShared shouldBe false

      it("空のワールドは完了とみなす"):
        val world = World(Vector.empty, 0)
        world.allRumorsShared shouldBe true

  // ============================================================
  // 3. シミュレーション
  // ============================================================

  describe("シミュレーション"):

    describe("基本シナリオ"):
      it("同じ停留所から始まり次も同じ停留所のドライバーは1分で完了"):
        // D1: 1->2, D2: 3->2 なので移動後に2で出会う
        val world = World(
          Driver("D1", Seq(1, 2), Set("a")),
          Driver("D2", Seq(3, 2), Set("b"))
        )
        simulate(world) shouldBe Completed(1)

      it("循環して出会うドライバーは出会うまでの時間で完了"):
        // D1: 1->2->1, D2: 1->3->1 なので2ステップ後に1で出会う
        val world = World(
          Driver("D1", Seq(1, 2), Set("a")),
          Driver("D2", Seq(1, 3), Set("b"))
        )
        simulate(world) shouldBe Completed(2)

      it("出会わないドライバーは Never"):
        val world = World(
          Driver("D1", Seq(1), Set("a")),
          Driver("D2", Seq(2), Set("b"))
        )
        simulate(world, maxMinutes = 10) shouldBe Never

      it("1人のドライバーは即座に完了"):
        val world = World(Driver("D1", Seq(1, 2), Set("a")))
        simulate(world) shouldBe Completed(0)

    describe("複雑なシナリオ"):
      it("3人のドライバーが順番に出会う"):
        val world = World(
          Driver("D1", Seq(3, 1, 2, 3), Set("a")),
          Driver("D2", Seq(3, 2, 3, 1), Set("b")),
          Driver("D3", Seq(4, 2, 3, 4, 5), Set("c"))
        )
        val result = simulate(world)
        result shouldBe a[Completed]
        val Completed(minutes) = result: @unchecked
        minutes should be > 0

      it("長いルートでも完了する"):
        val world = World(
          Driver("D1", Seq(1, 2, 3, 4, 5), Set("a")),
          Driver("D2", Seq(5, 4, 3, 2, 1), Set("b"))
        )
        val result = simulate(world)
        result shouldBe a[Completed]

    describe("履歴付きシミュレーション"):
      it("シミュレーション履歴を取得できる"):
        val world = World(
          Driver("D1", Seq(1, 2), Set("a")),
          Driver("D2", Seq(3, 2), Set("b"))
        )
        val (result, history) = simulateWithHistory(world)
        result shouldBe Completed(1)
        history should have length 2  // 初期状態と完了状態
        history.head.time shouldBe 0
        history.last.time shouldBe 1

  // ============================================================
  // 4. ヘルパー関数
  // ============================================================

  describe("ヘルパー関数"):

    describe("stopAtTime"):
      it("特定時間後の停留所を計算できる"):
        val driver = Driver("D1", Seq(1, 2, 3), Set.empty)
        stopAtTime(driver, 0) shouldBe 1
        stopAtTime(driver, 1) shouldBe 2
        stopAtTime(driver, 2) shouldBe 3
        stopAtTime(driver, 3) shouldBe 1  // 循環

    describe("firstMeetingTime"):
      it("2人のドライバーが最初に出会う時間を計算できる"):
        val d1 = Driver("D1", Seq(1, 2, 3), Set.empty)
        val d2 = Driver("D2", Seq(3, 2, 1), Set.empty)
        firstMeetingTime(d1, d2) shouldBe Some(1)  // 両方とも2で出会う

      it("出会わない場合はNone"):
        val d1 = Driver("D1", Seq(1), Set.empty)
        val d2 = Driver("D2", Seq(2), Set.empty)
        firstMeetingTime(d1, d2, maxTime = 10) shouldBe None

    describe("routeLcm"):
      it("ルート長の最小公倍数を計算できる"):
        routeLcm(Seq(Vector(1, 2), Vector(1, 2, 3))) shouldBe 6  // lcm(2, 3)
        routeLcm(Seq(Vector(1, 2, 3, 4), Vector(1, 2, 3, 4, 5, 6))) shouldBe 12  // lcm(4, 6)

  // ============================================================
  // 5. 統計情報
  // ============================================================

  describe("統計情報"):

    it("シミュレーション統計を取得できる"):
      val world = World(
        Driver("D1", Seq(1, 2), Set("a")),
        Driver("D2", Seq(3, 2), Set("b"))
      )
      val (result, stats) = simulateWithStats(world)

      result shouldBe Completed(1)
      stats.totalMinutes shouldBe 1
      stats.totalMeetings should be > 0

  // ============================================================
  // 6. ビルダーパターン
  // ============================================================

  describe("SimulationBuilder"):

    it("ビルダーでシミュレーションを構築できる"):
      val result = builder
        .addDriver("D1", Seq(1, 2), Set("a"))
        .addDriver("D2", Seq(3, 2), Set("b"))
        .run

      result shouldBe Completed(1)

    it("自動噂付きドライバーを追加できる"):
      val result = builder
        .addDriverWithAutoRumor("D1", Seq(1, 2))
        .addDriverWithAutoRumor("D2", Seq(3, 2))
        .run

      result shouldBe Completed(1)

    it("最大時間を設定できる"):
      val result = builder
        .addDriver("D1", Seq(1), Set("a"))
        .addDriver("D2", Seq(2), Set("b"))
        .withMaxMinutes(5)
        .run

      result shouldBe Never

    it("履歴付きで実行できる"):
      val (result, history) = builder
        .addDriver("D1", Seq(1, 2), Set("a"))
        .addDriver("D2", Seq(3, 2), Set("b"))
        .runWithHistory

      result shouldBe Completed(1)
      history should not be empty

  // ============================================================
  // 7. RouteDSL
  // ============================================================

  describe("RouteDSL"):

    import RouteDSL.*

    it("範囲でルートを定義できる"):
      range(1, 5) shouldBe Seq(1, 2, 3, 4, 5)

    it("ルートを逆順にできる"):
      reverse(Seq(1, 2, 3)) shouldBe Seq(3, 2, 1)

    it("往復ルートを作成できる"):
      roundTrip(Seq(1, 2, 3)) shouldBe Seq(1, 2, 3, 2, 1)

    it("複数のセグメントを結合できる"):
      concat(Seq(1, 2), Seq(3, 4)) shouldBe Seq(1, 2, 3, 4)

  // ============================================================
  // 8. 関数型コンビネータ
  // ============================================================

  describe("関数型コンビネータ"):

    describe("compose"):
      it("変換を合成できる"):
        val world = World(Driver("D1", Seq(1, 2, 3), Set("a")))
        val doubleMove = compose(_.moveDrivers, _.moveDrivers)
        val result = doubleMove(world)
        result.drivers.head.currentStop shouldBe 3

    describe("when"):
      it("条件付きで変換を適用できる"):
        val world = World(Driver("D1", Seq(1, 2), Set("a")))
        val moveIfAt1 = when(_.drivers.head.currentStop == 1)(_.moveDrivers)
        val result = moveIfAt1(world)
        result.drivers.head.currentStop shouldBe 2

      it("条件を満たさない場合は変換しない"):
        val world = World(Driver("D1", Seq(1, 2), Set("a"))).moveDrivers
        val moveIfAt1 = when(_.drivers.head.currentStop == 1)(_.moveDrivers)
        val result = moveIfAt1(world)
        result.drivers.head.currentStop shouldBe 2  // 変更なし

    describe("repeat"):
      it("N回変換を適用できる"):
        val world = World(Driver("D1", Seq(1, 2, 3, 4, 5), Set("a")))
        val moveThrice = repeat(3)(_.moveDrivers)
        val result = moveThrice(world)
        result.drivers.head.currentStop shouldBe 4

    describe("until"):
      it("条件が満たされるまで変換を適用できる"):
        val world = World(
          Driver("D1", Seq(1, 2), Set("a")),
          Driver("D2", Seq(3, 2), Set("b"))
        )
        val untilShared = until(_.allRumorsShared)(_.step)
        val result = untilShared(world)
        result.allRumorsShared shouldBe true

  // ============================================================
  // 9. 遅延付きシミュレーション
  // ============================================================

  describe("遅延付きシミュレーション"):

    it("遅延なしドライバーは通常通り動作する"):
      val world = DelayedWorld(Vector(
        DelayedDriver("D1", Vector(1, 2), 0, Set("a")),
        DelayedDriver("D2", Vector(1, 3), 0, Set("b"))
      ))
      // 初期位置が同じ(1)なので、移動後D1は2、D2は3で出会わない
      // D1: 1->2->1->2, D2: 1->3->1->3 なので、1で再び出会うのは2ステップ後
      simulateDelayed(world) shouldBe Completed(2)

    it("遅延付きドライバーは停留所に留まる"):
      val driver = DelayedDriver("D1", Vector(1, 2, 3), 0, Set("a"), delay = 2)
      val moved1 = driver.move
      moved1.currentStop shouldBe 1  // まだ移動しない
      moved1.delay shouldBe 1

      val moved2 = moved1.move
      moved2.currentStop shouldBe 1  // まだ移動しない
      moved2.delay shouldBe 0

      val moved3 = moved2.move
      moved3.currentStop shouldBe 2  // 移動

  // ============================================================
  // 10. エッジケース
  // ============================================================

  describe("エッジケース"):

    it("全員が最初から同じ噂を持っている場合は0分で完了"):
      val world = World(
        Driver("D1", Seq(1, 2), Set("a")),
        Driver("D2", Seq(3, 4), Set("a"))
      )
      simulate(world) shouldBe Completed(0)

    it("空のワールドは0分で完了"):
      val world = World(Vector.empty, 0)
      simulate(world) shouldBe Completed(0)

    it("単一停留所のルートを持つドライバー"):
      val world = World(
        Driver("D1", Seq(1), Set("a")),
        Driver("D2", Seq(1), Set("b"))
      )
      simulate(world) shouldBe Completed(1)

    it("同じルートを持つドライバーは必ず出会う"):
      val world = World(
        Driver("D1", Seq(1, 2, 3), Set("a")),
        Driver("D2", Seq(1, 2, 3), Set("b"))
      )
      val result = simulate(world)
      result shouldBe a[Completed]
