defmodule Chapter03Test do
  use ExUnit.Case
  doctest Chapter03

  alias Chapter03.{
    Rectangle,
    Circle,
    Triangle,
    Payment,
    ShopProduct,
    Service,
    SavingsAccount,
    PremiumSavingsAccount,
    CheckingAccount,
    Sum,
    Multiply
  }

  # ============================================================
  # 1. パターンマッチングによる多態性
  # ============================================================

  describe "タグ付きタプルによる多態性" do
    test "長方形の面積を計算する" do
      assert Chapter03.calculate_area({:rectangle, 4, 5}) == 20
    end

    test "円の面積を計算する" do
      result = Chapter03.calculate_area({:circle, 3})
      assert_in_delta result, 28.274, 0.001
    end

    test "三角形の面積を計算する" do
      assert Chapter03.calculate_area({:triangle, 6, 5}) == 15.0
    end

    test "周囲長を計算する" do
      assert Chapter03.calculate_perimeter({:rectangle, 4, 5}) == 18
      assert_in_delta Chapter03.calculate_perimeter({:circle, 3}), 18.849, 0.001
    end
  end

  # ============================================================
  # 2. 構造体とパターンマッチング
  # ============================================================

  describe "構造体による多態性" do
    test "Rectangle の面積を計算する" do
      assert Chapter03.area(%Rectangle{width: 4, height: 5}) == 20
    end

    test "Circle の面積を計算する" do
      result = Chapter03.area(%Circle{radius: 3})
      assert_in_delta result, 28.274, 0.001
    end

    test "Triangle の面積を計算する" do
      assert Chapter03.area(%Triangle{base: 6, height: 5}) == 15.0
    end
  end

  # ============================================================
  # 3. 複合ディスパッチ
  # ============================================================

  describe "複合ディスパッチ" do
    test "クレジットカード + 円の支払いを処理する" do
      payment = %Payment{method: :credit_card, currency: :jpy, amount: 1000}
      result = Chapter03.process_payment(payment)

      assert result.status == "processed"
      assert result.message == "クレジットカード（円）で処理しました"
      assert result.amount == 1000
    end

    test "クレジットカード + ドルの支払いを処理する" do
      payment = %Payment{method: :credit_card, currency: :usd, amount: 100}
      result = Chapter03.process_payment(payment)

      assert result.status == "processed"
      assert result.converted == 15000
    end

    test "銀行振込 + 円の支払いを処理する" do
      payment = %Payment{method: :bank_transfer, currency: :jpy, amount: 5000}
      result = Chapter03.process_payment(payment)

      assert result.status == "pending"
    end

    test "サポートされていない組み合わせはエラーを返す" do
      payment = %Payment{method: :cash, currency: :eur, amount: 500}
      result = Chapter03.process_payment(payment)

      assert result.status == "error"
    end
  end

  # ============================================================
  # 4. プロトコル
  # ============================================================

  describe "Describable プロトコル" do
    test "ShopProduct を説明する" do
      product = %ShopProduct{name: "りんご", price: 150}
      assert Chapter03.Describable.describe(product) == "商品: りんご (150円)"
    end

    test "Service を説明する" do
      service = %Service{name: "コンサルティング", hourly_rate: 10000}
      assert Chapter03.Describable.describe(service) == "サービス: コンサルティング (時給10000円)"
    end

    test "Map を説明する" do
      map = %{a: 1, b: 2, c: 3}
      assert Chapter03.Describable.describe(map) == "マップ with 3 keys"
    end

    test "List を説明する" do
      list = [1, 2, 3, 4, 5]
      assert Chapter03.Describable.describe(list) == "リスト with 5 elements"
    end
  end

  # ============================================================
  # 5. 口座の例
  # ============================================================

  describe "口座の利息計算" do
    test "普通預金口座の利息を計算する" do
      assert Chapter03.calculate_interest(%SavingsAccount{balance: 10000}) == 200.0
    end

    test "プレミアム預金口座の利息を計算する" do
      assert Chapter03.calculate_interest(%PremiumSavingsAccount{balance: 10000}) == 500.0
    end

    test "当座預金口座の利息を計算する" do
      assert Chapter03.calculate_interest(%CheckingAccount{balance: 10000}) == 10.0
    end
  end

  # ============================================================
  # 6. ビヘイビア
  # ============================================================

  describe "シリアライザ" do
    test "JsonSerializer でシリアライズする" do
      data = %{name: "test", value: 42}
      result = Chapter03.JsonSerializer.serialize(data)
      assert is_binary(result)
    end

    test "CsvSerializer でシリアライズする" do
      data = [["a", "b", "c"], ["1", "2", "3"]]
      result = Chapter03.CsvSerializer.serialize(data)
      assert result == "a,b,c\n1,2,3"
    end

    test "CsvSerializer でデシリアライズする" do
      csv = "a,b,c\n1,2,3"
      result = Chapter03.CsvSerializer.deserialize(csv)
      assert result == [["a", "b", "c"], ["1", "2", "3"]]
    end
  end

  # ============================================================
  # 7. モノイド
  # ============================================================

  describe "Monoid プロトコル" do
    test "Sum モノイドを結合する" do
      a = %Sum{value: 5}
      b = %Sum{value: 3}
      result = Chapter03.Monoid.combine(a, b)
      assert result == %Sum{value: 8}
    end

    test "Multiply モノイドを結合する" do
      a = %Multiply{value: 5}
      b = %Multiply{value: 3}
      result = Chapter03.Monoid.combine(a, b)
      assert result == %Multiply{value: 15}
    end

    test "List モノイドを結合する" do
      a = [1, 2, 3]
      b = [4, 5, 6]
      result = Chapter03.Monoid.combine(a, b)
      assert result == [1, 2, 3, 4, 5, 6]
    end

    test "fold_monoid で Sum を畳み込む" do
      sums = [%Sum{value: 1}, %Sum{value: 2}, %Sum{value: 3}]
      result = Chapter03.fold_monoid(sums, Sum.empty())
      assert result == %Sum{value: 6}
    end

    test "fold_monoid で Multiply を畳み込む" do
      mults = [%Multiply{value: 2}, %Multiply{value: 3}, %Multiply{value: 4}]
      result = Chapter03.fold_monoid(mults, Multiply.empty())
      assert result == %Multiply{value: 24}
    end
  end

  # ============================================================
  # 8. 動的ディスパッチ
  # ============================================================

  describe "動的ディスパッチ" do
    test "関数マップでディスパッチする" do
      handlers = %{
        add: fn a, b -> a + b end,
        multiply: fn a, b -> a * b end
      }

      assert Chapter03.dispatch(handlers, :add, [5, 3]) == 8
      assert Chapter03.dispatch(handlers, :multiply, [5, 3]) == 15
    end

    test "存在しない操作はエラーを投げる" do
      handlers = %{add: fn a, b -> a + b end}

      assert_raise ArgumentError, "Unknown operation: subtract", fn ->
        Chapter03.dispatch(handlers, :subtract, [5, 3])
      end
    end

    test "create_calculator で計算機を作成する" do
      calc = Chapter03.create_calculator()

      assert calc.(:add, 5, 3) == 8
      assert calc.(:subtract, 5, 3) == 2
      assert calc.(:multiply, 5, 3) == 15
      assert calc.(:divide, 10, 2) == 5.0
    end
  end

  # ============================================================
  # 9. 式の評価
  # ============================================================

  describe "式の評価" do
    test "数値を評価する" do
      assert Chapter03.evaluate({:num, 42}) == 42
    end

    test "加算を評価する" do
      expr = {:add, {:num, 5}, {:num, 3}}
      assert Chapter03.evaluate(expr) == 8
    end

    test "複合式を評価する" do
      # 5 + (2 * 3) = 11
      expr = {:add, {:num, 5}, {:mul, {:num, 2}, {:num, 3}}}
      assert Chapter03.evaluate(expr) == 11
    end

    test "式を文字列に変換する" do
      expr = {:add, {:num, 5}, {:mul, {:num, 2}, {:num, 3}}}
      assert Chapter03.expr_to_string(expr) == "(5 + (2 * 3))"
    end

    test "複雑な式を文字列に変換する" do
      # (10 - 4) / 2
      expr = {:div, {:sub, {:num, 10}, {:num, 4}}, {:num, 2}}
      assert Chapter03.expr_to_string(expr) == "((10 - 4) / 2)"
    end
  end

  # ============================================================
  # 10. ガード節
  # ============================================================

  describe "ガード節による多態性" do
    test "正の整数を説明する" do
      assert Chapter03.describe_value(42) == "正の整数: 42"
    end

    test "負の整数を説明する" do
      assert Chapter03.describe_value(-5) == "負の整数: -5"
    end

    test "ゼロを説明する" do
      assert Chapter03.describe_value(0) == "ゼロ"
    end

    test "浮動小数点数を説明する" do
      assert Chapter03.describe_value(3.14) == "浮動小数点数: 3.14"
    end

    test "文字列を説明する" do
      assert Chapter03.describe_value("hello") == "文字列: hello"
    end

    test "リストを説明する" do
      assert Chapter03.describe_value([1, 2, 3]) == "リスト（要素数: 3）"
    end

    test "マップを説明する" do
      assert Chapter03.describe_value(%{a: 1, b: 2}) == "マップ（キー数: 2）"
    end
  end
end
