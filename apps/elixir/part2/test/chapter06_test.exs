defmodule Chapter06Test do
  use ExUnit.Case
  doctest Chapter06

  alias Chapter06.{
    FizzBuzz,
    PricingService,
    OrderProcessor,
    OrderState,
    Calculator,
    PasswordValidator,
    UserBuilder
  }

  # ============================================================
  # 1. FizzBuzz のテスト
  # ============================================================

  describe "FizzBuzz.convert/1" do
    test "通常の数値は文字列として返す" do
      assert FizzBuzz.convert(1) == "1"
      assert FizzBuzz.convert(2) == "2"
      assert FizzBuzz.convert(7) == "7"
    end

    test "3の倍数は 'Fizz' を返す" do
      assert FizzBuzz.convert(3) == "Fizz"
      assert FizzBuzz.convert(6) == "Fizz"
      assert FizzBuzz.convert(9) == "Fizz"
    end

    test "5の倍数は 'Buzz' を返す" do
      assert FizzBuzz.convert(5) == "Buzz"
      assert FizzBuzz.convert(10) == "Buzz"
      assert FizzBuzz.convert(20) == "Buzz"
    end

    test "15の倍数は 'FizzBuzz' を返す" do
      assert FizzBuzz.convert(15) == "FizzBuzz"
      assert FizzBuzz.convert(30) == "FizzBuzz"
      assert FizzBuzz.convert(45) == "FizzBuzz"
    end
  end

  describe "FizzBuzz.generate/1" do
    test "1から指定した数までのFizzBuzzリストを生成する" do
      assert FizzBuzz.generate(1) == ["1"]
      assert FizzBuzz.generate(5) == ["1", "2", "Fizz", "4", "Buzz"]
      assert FizzBuzz.generate(15) |> List.last() == "FizzBuzz"
    end
  end

  # ============================================================
  # 2. PricingService のテスト（依存性注入）
  # ============================================================

  describe "PricingService.calculate_price/3" do
    test "割引率を適用して価格を計算する" do
      # スタブ：常に10%割引
      discount_fetcher = fn _product_id -> 0.10 end

      assert PricingService.calculate_price("PROD001", 1000, discount_fetcher) == 900.0
    end

    test "商品ごとに異なる割引率を適用する" do
      discount_fetcher = fn
        "PROD001" -> 0.10
        "PROD002" -> 0.20
        _ -> 0.0
      end

      assert PricingService.calculate_price("PROD001", 1000, discount_fetcher) == 900.0
      assert PricingService.calculate_price("PROD002", 1000, discount_fetcher) == 800.0
      assert PricingService.calculate_price("PROD003", 1000, discount_fetcher) == 1000.0
    end

    test "割引率0%の場合は元の価格" do
      no_discount = fn _product_id -> 0.0 end
      assert PricingService.calculate_price("PROD001", 1000, no_discount) == 1000.0
    end
  end

  describe "PricingService.calculate_total/2" do
    test "複数商品の合計を計算する" do
      items = [{"P1", 1000}, {"P2", 500}, {"P3", 300}]
      discount_fetcher = fn
        "P1" -> 0.10  # 900
        "P2" -> 0.20  # 400
        "P3" -> 0.0   # 300
      end

      assert PricingService.calculate_total(items, discount_fetcher) == 1600.0
    end

    test "空のアイテムリストは0を返す" do
      assert PricingService.calculate_total([], fn _ -> 0.0 end) == 0.0
    end
  end

  # ============================================================
  # 3. OrderProcessor のテスト（純粋関数）
  # ============================================================

  describe "OrderProcessor.calculate_subtotal/1" do
    test "アイテムの小計を計算する" do
      items = [{"Item1", 2, 100.0}, {"Item2", 3, 50.0}]
      assert OrderProcessor.calculate_subtotal(items) == 350.0
    end

    test "空のアイテムリストは0を返す" do
      assert OrderProcessor.calculate_subtotal([]) == 0.0
    end
  end

  describe "OrderProcessor.discount_rate/1" do
    test "顧客タイプごとの割引率" do
      assert OrderProcessor.discount_rate(:regular) == 0.0
      assert OrderProcessor.discount_rate(:premium) == 0.05
      assert OrderProcessor.discount_rate(:vip) == 0.10
    end
  end

  describe "OrderProcessor.process_order/2" do
    test "通常顧客の注文を処理する" do
      order = %{
        items: [{"Item", 1, 1000.0}],
        customer_type: :regular
      }

      result = OrderProcessor.process_order(order, 0.10)

      assert result.subtotal == 1000.0
      assert result.discount == 0.0
      assert result.tax == 100.0
      assert result.total == 1100.0
    end

    test "プレミアム顧客の注文を処理する" do
      order = %{
        items: [{"Item", 1, 1000.0}],
        customer_type: :premium
      }

      result = OrderProcessor.process_order(order, 0.10)

      assert result.subtotal == 1000.0
      assert result.discount == 50.0
      assert result.tax == 95.0
      assert result.total == 1045.0
    end

    test "VIP顧客の注文を処理する" do
      order = %{
        items: [{"Item", 1, 1000.0}],
        customer_type: :vip
      }

      result = OrderProcessor.process_order(order, 0.10)

      assert result.subtotal == 1000.0
      assert result.discount == 100.0
      assert result.tax == 90.0
      assert result.total == 990.0
    end
  end

  # ============================================================
  # 4. OrderState のテスト（状態遷移）
  # ============================================================

  describe "OrderState 状態遷移" do
    test "新規注文は pending 状態" do
      order = OrderState.new("ORD001", [])
      assert order.state == :pending
    end

    test "正常な状態遷移: pending -> confirmed -> shipped -> delivered" do
      order = OrderState.new("ORD001", [])

      assert {:ok, order} = OrderState.confirm(order)
      assert order.state == :confirmed

      assert {:ok, order} = OrderState.ship(order)
      assert order.state == :shipped

      assert {:ok, order} = OrderState.deliver(order)
      assert order.state == :delivered
    end

    test "pending または confirmed からキャンセルできる" do
      pending = OrderState.new("ORD001", [])
      assert {:ok, cancelled} = OrderState.cancel(pending)
      assert cancelled.state == :cancelled

      {:ok, confirmed} = OrderState.confirm(OrderState.new("ORD002", []))
      assert {:ok, cancelled} = OrderState.cancel(confirmed)
      assert cancelled.state == :cancelled
    end

    test "shipped からはキャンセルできない" do
      {:ok, confirmed} = OrderState.confirm(OrderState.new("ORD001", []))
      {:ok, shipped} = OrderState.ship(confirmed)

      assert {:error, _} = OrderState.cancel(shipped)
    end

    test "不正な状態遷移はエラーを返す" do
      order = OrderState.new("ORD001", [])

      # pending から直接 ship はできない
      assert {:error, _} = OrderState.ship(order)

      # pending から直接 deliver はできない
      assert {:error, _} = OrderState.deliver(order)
    end

    test "履歴が記録される" do
      order = OrderState.new("ORD001", [])
      {:ok, order} = OrderState.confirm(order)
      {:ok, order} = OrderState.ship(order)

      assert order.history == [:shipped, :confirmed, :pending]
    end

    test "can_complete? は完了可能な状態で true を返す" do
      pending = OrderState.new("ORD001", [])
      assert OrderState.can_complete?(pending) == true

      {:ok, confirmed} = OrderState.confirm(pending)
      assert OrderState.can_complete?(confirmed) == true

      {:ok, shipped} = OrderState.ship(confirmed)
      assert OrderState.can_complete?(shipped) == true

      {:ok, delivered} = OrderState.deliver(shipped)
      assert OrderState.can_complete?(delivered) == false

      {:ok, cancelled} = OrderState.cancel(OrderState.new("ORD002", []))
      assert OrderState.can_complete?(cancelled) == false
    end
  end

  # ============================================================
  # 5. Calculator のテスト
  # ============================================================

  describe "Calculator 基本演算" do
    test "add/2 は2つの数を加算する" do
      assert Calculator.add(2, 3) == {:ok, 5}
      assert Calculator.add(-1, 1) == {:ok, 0}
    end

    test "subtract/2 は2つの数を減算する" do
      assert Calculator.subtract(5, 3) == {:ok, 2}
      assert Calculator.subtract(1, 5) == {:ok, -4}
    end

    test "multiply/2 は2つの数を乗算する" do
      assert Calculator.multiply(3, 4) == {:ok, 12}
      assert Calculator.multiply(0, 100) == {:ok, 0}
    end

    test "divide/2 は2つの数を除算する" do
      assert Calculator.divide(10, 2) == {:ok, 5.0}
      assert Calculator.divide(1, 4) == {:ok, 0.25}
    end

    test "divide/2 はゼロ除算でエラー" do
      assert Calculator.divide(1, 0) == {:error, "Division by zero"}
    end

    test "sqrt/1 は平方根を計算する" do
      assert Calculator.sqrt(16) == {:ok, 4.0}
      assert Calculator.sqrt(0) == {:ok, 0.0}
    end

    test "sqrt/1 は負数でエラー" do
      assert Calculator.sqrt(-1) == {:error, "Cannot calculate square root of negative number"}
    end
  end

  describe "Calculator チェイン演算" do
    test "計算をチェインできる" do
      result =
        Calculator.chain(10)
        |> Calculator.then_add(5)
        |> Calculator.then_multiply(2)

      assert result == {:ok, 30}
    end

    test "エラーはチェインを通じて伝播する" do
      result =
        Calculator.chain(10)
        |> Calculator.then_divide(0)
        |> Calculator.then_add(5)

      assert {:error, "Division by zero"} = result
    end
  end

  describe "Calculator.evaluate/1" do
    test "有効な式を評価する" do
      assert Calculator.evaluate("2 + 3") == {:ok, 5.0}
      assert Calculator.evaluate("10 - 3") == {:ok, 7.0}
      assert Calculator.evaluate("4 * 5") == {:ok, 20.0}
      assert Calculator.evaluate("20 / 4") == {:ok, 5.0}
    end

    test "ゼロ除算はエラー" do
      assert Calculator.evaluate("10 / 0") == {:error, "Division by zero"}
    end

    test "無効な式はエラー" do
      assert Calculator.evaluate("invalid") == {:error, "Invalid expression"}
      assert Calculator.evaluate("1 +") == {:error, "Invalid expression"}
    end
  end

  # ============================================================
  # 6. PasswordValidator のテスト
  # ============================================================

  describe "PasswordValidator.validate/1" do
    test "有効なパスワードは :ok を返す" do
      assert {:ok, "Abc123!@"} = PasswordValidator.validate("Abc123!@")
      assert {:ok, "P@ssw0rd!"} = PasswordValidator.validate("P@ssw0rd!")
    end

    test "短すぎるパスワードはエラー" do
      {:error, errors} = PasswordValidator.validate("Ab1!")
      assert "8文字以上必要" in errors
    end

    test "大文字がないパスワードはエラー" do
      {:error, errors} = PasswordValidator.validate("abc123!@")
      assert "大文字が必要" in errors
    end

    test "小文字がないパスワードはエラー" do
      {:error, errors} = PasswordValidator.validate("ABC123!@")
      assert "小文字が必要" in errors
    end

    test "数字がないパスワードはエラー" do
      {:error, errors} = PasswordValidator.validate("Abcdefg!")
      assert "数字が必要" in errors
    end

    test "特殊文字がないパスワードはエラー" do
      {:error, errors} = PasswordValidator.validate("Abcdefg1")
      assert "特殊文字が必要" in errors
    end

    test "複数のエラーを返す" do
      {:error, errors} = PasswordValidator.validate("short")
      assert length(errors) >= 3
    end
  end

  describe "PasswordValidator 個別チェック" do
    test "check_length/1" do
      assert PasswordValidator.check_length("12345678") == :ok
      assert PasswordValidator.check_length("1234567") == {:error, "8文字以上必要"}
    end

    test "check_uppercase/1" do
      assert PasswordValidator.check_uppercase("Abc") == :ok
      assert PasswordValidator.check_uppercase("abc") == {:error, "大文字が必要"}
    end

    test "check_lowercase/1" do
      assert PasswordValidator.check_lowercase("Abc") == :ok
      assert PasswordValidator.check_lowercase("ABC") == {:error, "小文字が必要"}
    end

    test "check_digit/1" do
      assert PasswordValidator.check_digit("abc1") == :ok
      assert PasswordValidator.check_digit("abc") == {:error, "数字が必要"}
    end

    test "check_special/1" do
      assert PasswordValidator.check_special("abc!") == :ok
      assert PasswordValidator.check_special("abc") == {:error, "特殊文字が必要"}
    end
  end

  # ============================================================
  # 7. UserBuilder のテスト（テストデータビルダー）
  # ============================================================

  describe "UserBuilder" do
    test "デフォルト値でユーザーを作成する" do
      user = UserBuilder.build()

      assert user.name == "Test User"
      assert user.email == "test@example.com"
      assert user.age == 25
      assert user.role == :user
      assert user.active == true
    end

    test "特定のフィールドを上書きできる" do
      user = UserBuilder.build(name: "Alice", age: 30)

      assert user.name == "Alice"
      assert user.age == 30
      assert user.email == "test@example.com"  # 他はデフォルト
    end

    test "admin/0 で管理者を作成できる" do
      admin = UserBuilder.admin()
      assert admin.role == :admin
    end

    test "inactive/0 で非アクティブユーザーを作成できる" do
      inactive = UserBuilder.inactive()
      assert inactive.active == false
    end

    test "build_list/1 で複数ユーザーを作成できる" do
      users = UserBuilder.build_list(3)

      assert length(users) == 3
      assert Enum.at(users, 0).name == "User 1"
      assert Enum.at(users, 1).name == "User 2"
      assert Enum.at(users, 2).name == "User 3"
    end
  end

  # ============================================================
  # 8. テストヘルパー関数のテスト
  # ============================================================

  describe "テストヘルパー関数" do
    test "days_ago/1 は過去の日付を返す" do
      assert Chapter06.days_ago(0) == Date.utc_today()
      assert Chapter06.days_ago(1) == Date.add(Date.utc_today(), -1)
      assert Chapter06.days_ago(7) == Date.add(Date.utc_today(), -7)
    end

    test "days_from_now/1 は未来の日付を返す" do
      assert Chapter06.days_from_now(0) == Date.utc_today()
      assert Chapter06.days_from_now(1) == Date.add(Date.utc_today(), 1)
      assert Chapter06.days_from_now(7) == Date.add(Date.utc_today(), 7)
    end

    test "random_string/1 は指定長の文字列を返す" do
      s = Chapter06.random_string(10)
      assert String.length(s) == 10

      # 2回呼び出すと異なる値を返す
      s2 = Chapter06.random_string(10)
      assert s != s2
    end

    test "random_email/0 はメールアドレス形式の文字列を返す" do
      email = Chapter06.random_email()
      assert String.contains?(email, "@example.com")
    end
  end

  # ============================================================
  # 9. Parameterized Tests の例
  # ============================================================

  describe "Parameterized Tests（パラメタライズドテスト）" do
    # FizzBuzz のパラメタライズドテスト
    for {input, expected} <- [
      {1, "1"},
      {2, "2"},
      {3, "Fizz"},
      {5, "Buzz"},
      {15, "FizzBuzz"},
      {30, "FizzBuzz"}
    ] do
      test "FizzBuzz.convert(#{input}) == #{expected}" do
        assert FizzBuzz.convert(unquote(input)) == unquote(expected)
      end
    end

    # Calculator のパラメタライズドテスト
    for {expr, expected} <- [
      {"1 + 1", {:ok, 2.0}},
      {"10 - 5", {:ok, 5.0}},
      {"3 * 4", {:ok, 12.0}},
      {"20 / 4", {:ok, 5.0}}
    ] do
      test "Calculator.evaluate(\"#{expr}\") == #{inspect(expected)}" do
        assert Calculator.evaluate(unquote(expr)) == unquote(expected)
      end
    end
  end
end
