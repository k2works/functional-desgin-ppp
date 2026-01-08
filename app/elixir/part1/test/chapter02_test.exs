defmodule Chapter02Test do
  use ExUnit.Case
  doctest Chapter02

  alias Chapter02.{Email, OrderItem, Customer, Order, CustomerInfo}

  # ============================================================
  # 1. 関数合成の基本
  # ============================================================

  describe "関数合成" do
    test "add_tax は税金を追加する関数を返す" do
      add_tax = Chapter02.add_tax(0.1)
      assert add_tax.(1000) == 1100.0
    end

    test "apply_discount は割引を適用する関数を返す" do
      discount = Chapter02.apply_discount(0.2)
      assert discount.(1000) == 800.0
    end

    test "round_to_yen は円単位で丸める" do
      assert Chapter02.round_to_yen(880.5) == 881
      assert Chapter02.round_to_yen(880.4) == 880
    end

    test "compose は複数の関数を左から右へ合成する" do
      add_one = fn x -> x + 1 end
      double = fn x -> x * 2 end
      composed = Chapter02.compose([add_one, double])

      # (5 + 1) * 2 = 12
      assert composed.(5) == 12
    end

    test "calculate_final_price は価格計算パイプラインを実行する" do
      calculate = Chapter02.calculate_final_price()
      # 1000 -> 20%割引(800) -> 10%税込(880) -> 丸め(880)
      assert calculate.(1000) == 880
    end
  end

  # ============================================================
  # 2. カリー化と部分適用
  # ============================================================

  describe "カリー化と部分適用" do
    test "greet は挨拶関数を返す" do
      say_hello = Chapter02.greet("Hello")
      say_goodbye = Chapter02.greet("Goodbye")

      assert say_hello.("田中") == "Hello, 田中!"
      assert say_goodbye.("鈴木") == "Goodbye, 鈴木!"
    end

    test "send_email はカリー化されたメール送信関数" do
      send_from_system = Chapter02.send_email("system@example.com")
      send_notification = send_from_system.("user@example.com").("通知")
      email = send_notification.("メッセージ本文")

      assert %Email{} = email
      assert email.from == "system@example.com"
      assert email.to == "user@example.com"
      assert email.subject == "通知"
      assert email.body == "メッセージ本文"
    end
  end

  # ============================================================
  # 3. 複数の関数を並列適用
  # ============================================================

  describe "並列適用" do
    test "get_stats は数値リストの統計情報を返す" do
      result = Chapter02.get_stats([3, 1, 4, 1, 5, 9, 2, 6])
      assert result == {3, 6, 8, 1, 9}
    end

    test "analyze_person は人物を分析する" do
      adult = Chapter02.analyze_person(%{name: "田中", age: 25})
      assert adult.category == "adult"

      minor = Chapter02.analyze_person(%{name: "鈴木", age: 15})
      assert minor.category == "minor"
    end

    test "juxt は複数の関数を適用してタプルを返す" do
      juxt_fn = Chapter02.juxt([&Enum.min/1, &Enum.max/1, &Enum.sum/1])
      result = juxt_fn.([1, 2, 3, 4, 5])
      assert result == {1, 5, 15}
    end
  end

  # ============================================================
  # 4. 高階関数
  # ============================================================

  describe "高階関数" do
    test "with_logging はログ出力付きの関数を返す" do
      import ExUnit.CaptureIO

      double = fn x -> x * 2 end
      double_with_log = Chapter02.with_logging(double)

      output = capture_io(fn ->
        result = double_with_log.(5)
        assert result == 10
      end)

      assert output =~ "入力: 5"
      assert output =~ "出力: 10"
    end

    test "with_retry は失敗時にリトライする" do
      counter = :counters.new(1, [:atomics])

      unstable = fn _x ->
        count = :counters.get(counter, 1)
        :counters.add(counter, 1, 1)

        if count < 2 do
          raise "Temporary error"
        else
          :ok
        end
      end

      with_retry = Chapter02.with_retry(unstable, 3)
      assert with_retry.(nil) == :ok
      assert :counters.get(counter, 1) == 3
    end

    test "with_retry はリトライ上限を超えると例外を投げる" do
      always_fail = fn _x -> raise "Always fails" end
      with_retry = Chapter02.with_retry(always_fail, 2)

      assert_raise RuntimeError, "Always fails", fn ->
        with_retry.(nil)
      end
    end

    test "memoize は結果をキャッシュする" do
      call_count = :counters.new(1, [:atomics])

      expensive = fn x ->
        :counters.add(call_count, 1, 1)
        x * 2
      end

      {:ok, memoized} = Chapter02.memoize(expensive)

      # 最初の呼び出し
      assert memoized.(5) == 10
      assert :counters.get(call_count, 1) == 1

      # 2回目は キャッシュから
      assert memoized.(5) == 10
      assert :counters.get(call_count, 1) == 1

      # 異なる引数は新規計算
      assert memoized.(10) == 20
      assert :counters.get(call_count, 1) == 2
    end
  end

  # ============================================================
  # 5. パイプライン処理
  # ============================================================

  describe "パイプライン処理" do
    test "validate_order は空の注文を拒否する" do
      order = %Order{items: [], customer: %Customer{membership: "gold"}}

      assert_raise ArgumentError, "注文にアイテムがありません", fn ->
        Chapter02.validate_order(order)
      end
    end

    test "calculate_order_total は合計を計算する" do
      items = [
        %OrderItem{price: 1000, quantity: 2},
        %OrderItem{price: 500, quantity: 3}
      ]

      order = %Order{items: items, customer: %Customer{membership: "gold"}}
      result = Chapter02.calculate_order_total(order)

      assert result.total == 3500
    end

    test "apply_order_discount は会員割引を適用する" do
      order = %Order{items: [], customer: %Customer{membership: "gold"}, total: 1000}
      result = Chapter02.apply_order_discount(order)
      assert result.total == 900.0

      order_silver = %Order{items: [], customer: %Customer{membership: "silver"}, total: 1000}
      result_silver = Chapter02.apply_order_discount(order_silver)
      assert result_silver.total == 950.0
    end

    test "add_shipping は送料を追加する" do
      cheap_order = %Order{items: [], customer: nil, total: 3000}
      result = Chapter02.add_shipping(cheap_order)
      assert result.shipping == 500
      assert result.total == 3500

      expensive_order = %Order{items: [], customer: nil, total: 5000}
      result = Chapter02.add_shipping(expensive_order)
      assert result.shipping == 0
      assert result.total == 5000
    end

    test "process_order_pipeline は注文を処理する" do
      items = [
        %OrderItem{price: 1000, quantity: 2},
        %OrderItem{price: 500, quantity: 3}
      ]

      order = %Order{items: items, customer: %Customer{membership: "gold"}}
      result = Chapter02.process_order_pipeline(order)

      # 3500 * 0.9 = 3150 + 500 = 3650
      assert result.total == 3650.0
      assert result.shipping == 500
    end
  end

  # ============================================================
  # 6. バリデーション合成
  # ============================================================

  describe "バリデーション" do
    test "validator は述語関数からバリデータを作成する" do
      is_positive = Chapter02.validator(fn x -> x > 0 end, "正の数が必要")

      valid = is_positive.(5)
      assert valid.valid == true
      assert valid.value == 5
      assert valid.error == nil

      invalid = is_positive.(-1)
      assert invalid.valid == false
      assert invalid.error == "正の数が必要"
    end

    test "combine_validators は複数のバリデータを合成する" do
      is_positive = Chapter02.validator(fn x -> x > 0 end, "正の数が必要")
      under_100 = Chapter02.validator(fn x -> x < 100 end, "100未満が必要")
      validate = Chapter02.combine_validators([is_positive, under_100])

      valid = validate.(50)
      assert valid.valid == true

      invalid_negative = validate.(-1)
      assert invalid_negative.valid == false
      assert invalid_negative.error == "正の数が必要"

      invalid_over = validate.(100)
      assert invalid_over.valid == false
      assert invalid_over.error == "100未満が必要"
    end
  end

  # ============================================================
  # 7. 関数の変換
  # ============================================================

  describe "関数の変換" do
    test "flip は引数の順序を反転する" do
      subtract = fn a, b -> a - b end
      flipped = Chapter02.flip(subtract)

      # subtract(5, 3) = 2, flipped(3, 5) = subtract(5, 3) = 2
      assert flipped.(3, 5) == 2
    end

    test "curry は2引数関数をカリー化する" do
      add = fn a, b -> a + b end
      curried = Chapter02.curry(add)
      add_5 = curried.(5)

      assert add_5.(3) == 8
    end

    test "uncurry はカリー化された関数を非カリー化する" do
      curried_add = fn a -> fn b -> a + b end end
      uncurried = Chapter02.uncurry(curried_add)

      assert uncurried.(5, 3) == 8
    end

    test "complement は述語の補関数を作成する" do
      is_even = fn x -> rem(x, 2) == 0 end
      is_odd = Chapter02.complement(is_even)

      assert is_odd.(3) == true
      assert is_odd.(4) == false
    end
  end

  # ============================================================
  # 8. 述語の合成
  # ============================================================

  describe "述語の合成" do
    test "compose_predicates_and は複数の述語をANDで合成する" do
      valid_age =
        Chapter02.compose_predicates_and([
          fn x -> x > 0 end,
          fn x -> x <= 150 end
        ])

      assert valid_age.(25) == true
      assert valid_age.(-1) == false
      assert valid_age.(200) == false
    end

    test "compose_predicates_or は複数の述語をORで合成する" do
      is_special =
        Chapter02.compose_predicates_or([
          fn x -> x == 0 end,
          fn x -> x == 100 end
        ])

      assert is_special.(0) == true
      assert is_special.(100) == true
      assert is_special.(50) == false
    end

    test "premium_customer_checker はプレミアム顧客を判定する" do
      checker = Chapter02.premium_customer_checker()

      gold = %CustomerInfo{membership: "gold", purchase_count: 0, total_spent: 0}
      assert checker.(gold) == true

      frequent = %CustomerInfo{membership: "bronze", purchase_count: 100, total_spent: 0}
      assert checker.(frequent) == true

      big_spender = %CustomerInfo{membership: "bronze", purchase_count: 0, total_spent: 100_000}
      assert checker.(big_spender) == true

      regular = %CustomerInfo{membership: "bronze", purchase_count: 10, total_spent: 1000}
      assert checker.(regular) == false
    end
  end

  # ============================================================
  # 9. 関数のキャプチャ
  # ============================================================

  describe "関数のキャプチャ" do
    test "double_all はリストの要素を2倍にする" do
      assert Chapter02.double_all([1, 2, 3]) == [2, 4, 6]
    end

    test "stringify_all はリストの要素を文字列に変換する" do
      assert Chapter02.stringify_all([1, 2, 3]) == ["1", "2", "3"]
    end
  end
end
