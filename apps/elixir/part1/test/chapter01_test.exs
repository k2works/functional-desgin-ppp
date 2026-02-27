defmodule Chapter01Test do
  use ExUnit.Case
  doctest Chapter01

  alias Chapter01.{Person, Member, Team, Item, Customer, Order, Invoice}

  # ============================================================
  # 1. 不変データ構造の基本
  # ============================================================

  describe "不変データ構造" do
    test "Person を作成できる" do
      person = %Person{name: "田中", age: 30}
      assert person.name == "田中"
      assert person.age == 30
    end

    test "update_age は新しい Person を返す" do
      original = %Person{name: "田中", age: 30}
      updated = Chapter01.update_age(original, 31)

      # 新しいデータが返される
      assert updated.age == 31
      # 元のデータは変更されない
      assert original.age == 30
    end

    test "birthday は年齢を1つ増やした新しい Person を返す" do
      person = %Person{name: "鈴木", age: 25}
      after_birthday = Chapter01.birthday(person)

      assert after_birthday.age == 26
      assert person.age == 25
    end
  end

  # ============================================================
  # 2. 構造共有
  # ============================================================

  describe "構造共有" do
    test "Team にメンバーを追加できる" do
      team = %Team{name: "開発チーム", members: []}
      member = %Member{name: "山田", role: "developer"}

      new_team = Chapter01.add_member(team, member)

      assert length(new_team.members) == 1
      assert hd(new_team.members).name == "山田"
      # 元のチームは変更されない
      assert length(team.members) == 0
    end

    test "Team からメンバーを削除できる" do
      member1 = %Member{name: "田中", role: "developer"}
      member2 = %Member{name: "鈴木", role: "designer"}
      team = %Team{name: "開発チーム", members: [member1, member2]}

      new_team = Chapter01.remove_member(team, "田中")

      assert length(new_team.members) == 1
      assert hd(new_team.members).name == "鈴木"
      # 元のチームは変更されない
      assert length(team.members) == 2
    end

    test "構造共有により既存のメンバーは参照が共有される" do
      member1 = %Member{name: "田中", role: "developer"}
      team = %Team{name: "開発チーム", members: [member1]}

      member2 = %Member{name: "鈴木", role: "designer"}
      new_team = Chapter01.add_member(team, member2)

      # 既存のメンバーは同じ参照
      assert hd(team.members) == hd(new_team.members)
    end
  end

  # ============================================================
  # 3. データ変換パイプライン
  # ============================================================

  describe "データ変換パイプライン" do
    test "calculate_subtotal はアイテムの小計を計算する" do
      item = %Item{name: "りんご", price: 100, quantity: 3}
      assert Chapter01.calculate_subtotal(item) == 300
    end

    test "membership_discount は会員種別に応じた割引率を返す" do
      assert Chapter01.membership_discount("gold") == 0.1
      assert Chapter01.membership_discount("silver") == 0.05
      assert Chapter01.membership_discount("bronze") == 0.02
      assert Chapter01.membership_discount("regular") == 0.0
      assert Chapter01.membership_discount("unknown") == 0.0
    end

    test "calculate_total は複数アイテムの合計を計算する" do
      items = [
        %Item{name: "りんご", price: 100, quantity: 3},
        %Item{name: "みかん", price: 80, quantity: 5}
      ]

      assert Chapter01.calculate_total(items) == 700
    end

    test "apply_discount は割引を適用した金額を返す" do
      assert Chapter01.apply_discount(1000, "gold") == 900.0
      assert Chapter01.apply_discount(1000, "silver") == 950.0
      assert Chapter01.apply_discount(1000, "regular") == 1000.0
    end

    test "process_order は注文全体を処理する" do
      items = [
        %Item{name: "りんご", price: 100, quantity: 10}
      ]

      customer = %Customer{name: "田中", membership: "gold"}
      order = %Order{items: items, customer: customer}

      result = Chapter01.process_order(order)
      assert result == 900.0
    end

    test "process_order パイプラインの例" do
      items = [
        %Item{name: "本", price: 1500, quantity: 2},
        %Item{name: "ノート", price: 200, quantity: 5}
      ]

      customer = %Customer{name: "山田", membership: "silver"}
      order = %Order{items: items, customer: customer}

      result = Chapter01.process_order(order)
      # (1500*2 + 200*5) * 0.95 = 4000 * 0.95 = 3800
      assert result == 3800.0
    end
  end

  # ============================================================
  # 4. 副作用の分離
  # ============================================================

  describe "副作用の分離" do
    test "calculate_tax は純粋関数" do
      # 同じ入力に対して常に同じ出力
      assert Chapter01.calculate_tax(1000, 0.1) == 100.0
      assert Chapter01.calculate_tax(1000, 0.1) == 100.0
      assert Chapter01.calculate_tax(2000, 0.08) == 160.0
    end

    test "calculate_invoice は純粋関数" do
      items = [%Item{name: "本", price: 1000, quantity: 1}]

      invoice1 = Chapter01.calculate_invoice(items, 0.1)
      invoice2 = Chapter01.calculate_invoice(items, 0.1)

      # 同じ入力に対して同じ出力
      assert invoice1 == invoice2
      assert invoice1.subtotal == 1000
      assert invoice1.tax == 100.0
      assert invoice1.total == 1100.0
    end

    test "Invoice 構造体が正しく作成される" do
      invoice = %Invoice{subtotal: 1000, tax: 100.0, total: 1100.0}

      assert invoice.subtotal == 1000
      assert invoice.tax == 100.0
      assert invoice.total == 1100.0
    end
  end

  # ============================================================
  # 5. 履歴管理（Undo/Redo）
  # ============================================================

  describe "履歴管理" do
    test "create_history は空の履歴を作成する" do
      history = Chapter01.create_history()

      assert history.current == nil
      assert history.past == []
      assert history.future == []
    end

    test "push_state は新しい状態を履歴に追加する" do
      history =
        Chapter01.create_history()
        |> Chapter01.push_state(%{text: "Hello"})

      assert history.current == %{text: "Hello"}
      assert history.past == []
    end

    test "push_state は前の状態を past に保存する" do
      history =
        Chapter01.create_history()
        |> Chapter01.push_state(%{text: "v1"})
        |> Chapter01.push_state(%{text: "v2"})

      assert history.current == %{text: "v2"}
      assert history.past == [%{text: "v1"}]
    end

    test "undo は直前の状態に戻す" do
      history =
        Chapter01.create_history()
        |> Chapter01.push_state(%{text: "v1"})
        |> Chapter01.push_state(%{text: "v2"})
        |> Chapter01.push_state(%{text: "v3"})
        |> Chapter01.undo()

      assert history.current == %{text: "v2"}
      assert history.past == [%{text: "v1"}]
      assert history.future == [%{text: "v3"}]
    end

    test "undo は past が空の場合は何もしない" do
      history =
        Chapter01.create_history()
        |> Chapter01.push_state(%{text: "v1"})
        |> Chapter01.undo()

      # past が空になったら undo は効かない
      assert history.past == []
      
      history2 = Chapter01.undo(history)
      # 2回目の undo は変化なし
      assert history2 == history
    end

    test "redo はやり直し操作を行う" do
      history =
        Chapter01.create_history()
        |> Chapter01.push_state(%{text: "v1"})
        |> Chapter01.push_state(%{text: "v2"})
        |> Chapter01.undo()
        |> Chapter01.redo()

      assert history.current == %{text: "v2"}
    end

    test "redo は future が空の場合は何もしない" do
      history =
        Chapter01.create_history()
        |> Chapter01.push_state(%{text: "v1"})
        |> Chapter01.redo()

      assert history.current == %{text: "v1"}
      assert history.future == []
    end

    test "push_state は future をクリアする" do
      history =
        Chapter01.create_history()
        |> Chapter01.push_state(%{text: "v1"})
        |> Chapter01.push_state(%{text: "v2"})
        |> Chapter01.undo()
        |> Chapter01.push_state(%{text: "v3"})

      assert history.current == %{text: "v3"}
      assert history.future == []
    end
  end

  # ============================================================
  # 6. Stream による遅延評価
  # ============================================================

  describe "遅延評価" do
    test "process_items は条件に合うアイテムのみを処理する" do
      items = [
        %Item{name: "A", price: 100, quantity: 2},
        %Item{name: "B", price: 50, quantity: 0},
        %Item{name: "C", price: 200, quantity: 1}
      ]

      result = Chapter01.process_items(items)

      # quantity > 0 && subtotal > 100 のみ
      # A: quantity=2, subtotal=200 -> OK
      # B: quantity=0 -> NG
      # C: quantity=1, subtotal=200 -> OK
      assert length(result) == 2
      assert Enum.map(result, & &1.name) == ["A", "C"]
    end

    test "process_items_lazy は同じ結果を返す" do
      items = [
        %Item{name: "A", price: 100, quantity: 2},
        %Item{name: "B", price: 50, quantity: 0},
        %Item{name: "C", price: 200, quantity: 1}
      ]

      eager = Chapter01.process_items(items)
      lazy = Chapter01.process_items_lazy(items)

      assert eager == lazy
    end

    test "take_even_numbers は指定した数の偶数を返す" do
      result = Chapter01.take_even_numbers(5)
      assert result == [2, 4, 6, 8, 10]
    end

    test "take_even_numbers は無限ストリームから取得する" do
      result = Chapter01.take_even_numbers(10)
      assert length(result) == 10
      assert Enum.all?(result, &(rem(&1, 2) == 0))
    end
  end

  # ============================================================
  # 7. マップ操作
  # ============================================================

  describe "ネストしたマップ操作" do
    test "update_nested_name はネストした名前を更新する" do
      data = %{user: %{profile: %{name: "田中", age: 30}}}
      result = Chapter01.update_nested_name(data, "鈴木")

      assert result == %{user: %{profile: %{name: "鈴木", age: 30}}}
      # 元のデータは変更されない
      assert data == %{user: %{profile: %{name: "田中", age: 30}}}
    end

    test "increment_nested_age はネストした年齢を増やす" do
      data = %{user: %{profile: %{name: "田中", age: 30}}}
      result = Chapter01.increment_nested_age(data)

      assert result == %{user: %{profile: %{name: "田中", age: 31}}}
    end

    test "get_nested_name はネストした名前を取得する" do
      data = %{user: %{profile: %{name: "田中", age: 30}}}
      assert Chapter01.get_nested_name(data) == "田中"
    end

    test "get_in は存在しないキーに対して nil を返す" do
      data = %{user: %{}}
      assert get_in(data, [:user, :profile, :name]) == nil
    end
  end

  # ============================================================
  # 追加テスト: パイプ演算子の活用
  # ============================================================

  describe "パイプ演算子" do
    test "複数の変換をパイプで繋げられる" do
      result =
        1..10
        |> Enum.filter(&(rem(&1, 2) == 0))
        |> Enum.map(&(&1 * 2))
        |> Enum.sum()

      # 2, 4, 6, 8, 10 -> 4, 8, 12, 16, 20 -> 60
      assert result == 60
    end

    test "文字列処理のパイプライン" do
      result =
        "  Hello World  "
        |> String.trim()
        |> String.downcase()
        |> String.split()

      assert result == ["hello", "world"]
    end
  end
end
