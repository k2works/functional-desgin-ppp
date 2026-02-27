package immutability

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class ImmutabilitySpec extends AnyFlatSpec with Matchers:

  import Immutability.*

  // =============================================================================
  // 不変データ構造の基本
  // =============================================================================

  "updateAge" should "元のデータを変更しない" in {
    val original = Person("田中", 30)
    val updated = updateAge(original, 31)

    original.age shouldBe 30
    updated.age shouldBe 31
    updated.name shouldBe "田中"
  }

  // =============================================================================
  // 構造共有
  // =============================================================================

  "addMember" should "新しいメンバーを追加した新しいチームを返す" in {
    val team = Team("開発チーム", List(Member("田中", "developer")))
    val newTeam = addMember(team, Member("鈴木", "designer"))

    team.members.length shouldBe 1
    newTeam.members.length shouldBe 2
    newTeam.name shouldBe "開発チーム"
  }

  // =============================================================================
  // データ変換パイプライン
  // =============================================================================

  "calculateSubtotal" should "単価×数量を計算する" in {
    calculateSubtotal(Item("A", 1000, 2)) shouldBe 2000
    calculateSubtotal(Item("B", 500, 3)) shouldBe 1500
  }

  "membershipDiscount" should "会員種別に応じた割引率を返す" in {
    membershipDiscount("gold") shouldBe 0.1
    membershipDiscount("silver") shouldBe 0.05
    membershipDiscount("bronze") shouldBe 0.02
    membershipDiscount("regular") shouldBe 0.0
  }

  "calculateTotal" should "注文の合計金額を計算する" in {
    val order = Order(
      items = List(Item("A", 1000, 2), Item("B", 500, 3)),
      customer = Customer("山田", "regular")
    )
    calculateTotal(order) shouldBe 3500
  }

  "applyDiscount" should "割引後の金額を計算する" in {
    val order = Order(
      items = List.empty,
      customer = Customer("山田", "gold")
    )
    applyDiscount(order, 1000) shouldBe 900.0
  }

  "processOrder" should "注文処理全体を行う" in {
    val order = Order(
      items = List(Item("A", 1000, 2), Item("B", 500, 3)),
      customer = Customer("山田", "gold")
    )
    processOrder(order) shouldBe 3150.0
  }

  // =============================================================================
  // 副作用の分離
  // =============================================================================

  "pureCalculateTax" should "税額を計算する" in {
    pureCalculateTax(1000, 0.1) shouldBe 100.0
    pureCalculateTax(1000, 0.08) shouldBe 80.0
  }

  "calculateInvoice" should "請求書を計算する" in {
    val items = List(Item("A", 1000, 2), Item("B", 500, 1))
    val invoice = calculateInvoice(items, 0.1)

    invoice.subtotal shouldBe 2500
    invoice.tax shouldBe 250.0
    invoice.total shouldBe 2750.0
  }

  // =============================================================================
  // Undo/Redo の実装
  // =============================================================================

  "createHistory" should "空の履歴を作成する" in {
    val history = createHistory[Map[String, String]]()

    history.current shouldBe None
    history.past shouldBe List.empty
    history.future shouldBe List.empty
  }

  "pushState" should "新しい状態を追加する" in {
    val history = pushState(createHistory[Map[String, String]](), Map("text" -> "Hello"))

    history.current shouldBe Some(Map("text" -> "Hello"))
    history.past shouldBe List(None).flatten
  }

  "undo" should "直前の状態に戻す" in {
    val history = pushState(
      pushState(createHistory[Map[String, String]](), Map("text" -> "Hello")),
      Map("text" -> "Hello World")
    )
    val afterUndo = undo(history)

    afterUndo.current shouldBe Some(Map("text" -> "Hello"))
    afterUndo.future shouldBe List(Map("text" -> "Hello World"))
  }

  "redo" should "やり直しを行う" in {
    val history = redo(undo(pushState(
      pushState(createHistory[Map[String, String]](), Map("text" -> "Hello")),
      Map("text" -> "Hello World")
    )))

    history.current shouldBe Some(Map("text" -> "Hello World"))
    history.future shouldBe List.empty
  }

  "undo" should "空の履歴で undo しても安全" in {
    val history = createHistory[Map[String, String]]()
    val afterUndo = undo(history)

    afterUndo.current shouldBe None
  }

  "redo" should "future が空で redo しても安全" in {
    val history = pushState(createHistory[Map[String, String]](), Map("text" -> "Hello"))
    val afterRedo = redo(history)

    afterRedo.current shouldBe Some(Map("text" -> "Hello"))
  }

  // =============================================================================
  // トランスデューサー（Scala では関数合成）
  // =============================================================================

  "processItemsEfficiently" should "効率的にアイテムを処理する" in {
    val items = List(
      Item("A", 100, 2),   // subtotal 200 > 100 ✓
      Item("B", 50, 1),    // subtotal 50 <= 100 ✗
      Item("C", 200, 0),   // quantity 0 ✗
      Item("D", 300, 1)    // subtotal 300 > 100 ✓
    )
    processItemsEfficiently(items).length shouldBe 2
  }

  "processItemsWithIterator" should "Iterator を使用して効率的にアイテムを処理する" in {
    val items = List(
      Item("A", 100, 2),
      Item("B", 50, 1),
      Item("C", 200, 0),
      Item("D", 300, 1)
    )
    processItemsWithIterator(items).length shouldBe 2
  }
