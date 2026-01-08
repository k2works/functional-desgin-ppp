defmodule Chapter07Test do
  use ExUnit.Case
  doctest Chapter07

  alias Chapter07.{
    PureVsImpure,
    PricingCore,
    PricingShell,
    Effect,
    Reader,
    ReaderExample,
    TimeService,
    RandomService,
    Logger,
    ShoppingCart
  }

  # ============================================================
  # 1. 純粋関数と副作用
  # ============================================================

  describe "PureVsImpure" do
    test "純粋関数は同じ入力に対して同じ出力を返す" do
      assert PureVsImpure.add(2, 3) == 5
      assert PureVsImpure.add(2, 3) == 5
      assert PureVsImpure.add(2, 3) == 5
    end

    test "sum は純粋関数" do
      list = [1, 2, 3, 4, 5]
      result = PureVsImpure.sum(list)
      assert result == 15
      assert PureVsImpure.sum(list) == result
    end

    test "upcase は純粋関数" do
      assert PureVsImpure.upcase("hello") == "HELLO"
      assert PureVsImpure.upcase("hello") == "HELLO"
    end

    test "current_time は副作用を持つ（異なる値を返す可能性がある）" do
      time1 = PureVsImpure.current_time()
      Process.sleep(10)
      time2 = PureVsImpure.current_time()
      # 時間が進んでいることを確認
      assert DateTime.compare(time1, time2) in [:lt, :eq]
    end

    test "random_number は副作用を持つ" do
      results = for _ <- 1..100, do: PureVsImpure.random_number()
      unique_results = Enum.uniq(results)
      # 100回呼ぶと複数の異なる値が得られるはず
      assert length(unique_results) > 1
    end
  end

  # ============================================================
  # 2. Functional Core, Imperative Shell
  # ============================================================

  describe "PricingCore (純粋関数)" do
    test "apply_discount はパーセント割引を適用する" do
      assert PricingCore.apply_discount(100, %{type: :percentage, value: 10}) == 90.0
      assert PricingCore.apply_discount(100, %{type: :percentage, value: 50}) == 50.0
    end

    test "apply_discount は固定割引を適用する" do
      assert PricingCore.apply_discount(100, %{type: :fixed, value: 15}) == 85
      assert PricingCore.apply_discount(100, %{type: :fixed, value: 150}) == 0  # 負にならない
    end

    test "calculate_total は商品の合計を計算する" do
      products = [
        %{name: "A", price: 100},
        %{name: "B", price: 200},
        %{name: "C", price: 300}
      ]
      assert PricingCore.calculate_total(products) == 600
    end

    test "calculate_tax は税金を計算する" do
      assert PricingCore.calculate_tax(1000, 0.1) == 100.0
      assert PricingCore.calculate_tax(1000, 0.08) == 80.0
    end

    test "calculate_final_price は最終価格を計算する" do
      products = [%{name: "A", price: 1000}]
      discount = %{type: :percentage, value: 10}
      
      result = PricingCore.calculate_final_price(products, discount, 0.1)
      
      assert result.subtotal == 1000
      assert result.discount == 100.0
      assert result.tax == 90.0
      assert result.total == 990.0
    end
  end

  describe "PricingShell (副作用の境界)" do
    test "外部から割引を取得して計算する" do
      products = [%{name: "A", price: 1000}]
      
      # モック割引取得関数
      discount_fetcher = fn
        "VIP" -> %{type: :percentage, value: 20}
        "NORMAL" -> %{type: :percentage, value: 5}
        _ -> %{type: :percentage, value: 0}
      end
      
      vip_result = PricingShell.calculate_order_price(products, discount_fetcher, "VIP", 0.1)
      assert vip_result.discount == 200.0
      
      normal_result = PricingShell.calculate_order_price(products, discount_fetcher, "NORMAL", 0.1)
      assert normal_result.discount == 50.0
    end
  end

  # ============================================================
  # 3. Effect as Data
  # ============================================================

  describe "Effect" do
    test "console_log エフェクトを作成できる" do
      effect = Effect.console_log("Hello")
      assert match?({:effect, :console_log, "Hello", _}, effect)
    end

    test "get_current_time エフェクトを作成できる" do
      effect = Effect.get_current_time()
      assert match?({:effect, :get_time, nil, _}, effect)
    end

    test "get_random エフェクトを作成できる" do
      effect = Effect.get_random()
      assert match?({:effect, :random, nil, _}, effect)
    end

    test "http_get エフェクトを作成できる" do
      effect = Effect.http_get("https://api.example.com")
      assert match?({:effect, :http_get, "https://api.example.com", _}, effect)
    end

    test "run_test はモック値を使用してエフェクトを評価する" do
      fixed_time = ~U[2024-01-01 00:00:00Z]
      mock_values = %{get_time: fixed_time}
      
      effect = Effect.get_current_time()
      result = Effect.run_test(effect, mock_values)
      
      assert result == fixed_time
    end

    test "run_test は乱数をモックできる" do
      mock_values = %{random: 0.5}
      
      effect = Effect.get_random()
      result = Effect.run_test(effect, mock_values)
      
      assert result == 0.5
    end
  end

  # ============================================================
  # 4. Reader パターン
  # ============================================================

  describe "Reader" do
    test "pure は値をラップする" do
      reader = Reader.pure(42)
      assert Reader.run(reader, :any_env) == 42
    end

    test "ask は環境を取得する" do
      reader = Reader.ask()
      assert Reader.run(reader, %{value: 123}) == %{value: 123}
    end

    test "asks は環境の一部を取得する" do
      reader = Reader.asks(fn env -> env.name end)
      assert Reader.run(reader, %{name: "Alice", age: 30}) == "Alice"
    end

    test "map は Reader に関数を適用する" do
      reader = Reader.pure(10)
      mapped = Reader.map(reader, &(&1 * 2))
      assert Reader.run(mapped, :any) == 20
    end

    test "flat_map は Reader をチェインする" do
      reader1 = Reader.pure(10)
      reader2 = Reader.flat_map(reader1, fn x ->
        Reader.asks(fn env -> x + env.bonus end)
      end)
      
      assert Reader.run(reader2, %{bonus: 5}) == 15
    end
  end

  describe "ReaderExample" do
    setup do
      config = %{
        db_url: "postgres://localhost:5432/test",
        api_key: "secret-key-123",
        timeout: 5000
      }
      {:ok, config: config}
    end

    test "get_db_url は設定からDB URLを取得する", %{config: config} do
      reader = ReaderExample.get_db_url()
      assert Reader.run(reader, config) == "postgres://localhost:5432/test"
    end

    test "get_api_key は設定からAPIキーを取得する", %{config: config} do
      reader = ReaderExample.get_api_key()
      assert Reader.run(reader, config) == "secret-key-123"
    end

    test "build_service は複数の設定を使用してサービスを構築する", %{config: config} do
      reader = ReaderExample.build_service()
      result = Reader.run(reader, config)
      
      assert result.db == "postgres://localhost:5432/test"
      assert result.key == "secret-key-123"
      assert result.ready == true
    end
  end

  # ============================================================
  # 5. 時間の抽象化
  # ============================================================

  describe "TimeService" do
    test "now は現在時刻を返す" do
      time = TimeService.now()
      assert is_struct(time, DateTime)
    end

    test "now_with_provider はプロバイダーから時刻を取得する" do
      fixed_time = ~U[2024-06-15 10:30:00Z]
      provider = fn -> fixed_time end
      
      assert TimeService.now_with_provider(provider) == fixed_time
    end

    test "add_timestamp はデータにタイムスタンプを追加する" do
      fixed_time = ~U[2024-01-01 12:00:00Z]
      provider = fn -> fixed_time end
      data = %{event: "user_login", user_id: 123}
      
      result = TimeService.add_timestamp(data, provider)
      
      assert result.event == "user_login"
      assert result.user_id == 123
      assert result.timestamp == fixed_time
    end

    test "is_expired? は期限切れを判定する" do
      now = ~U[2024-01-15 12:00:00Z]
      provider = fn -> now end
      
      past_date = ~U[2024-01-10 12:00:00Z]
      future_date = ~U[2024-01-20 12:00:00Z]
      
      assert TimeService.is_expired?(past_date, provider) == true
      assert TimeService.is_expired?(future_date, provider) == false
    end
  end

  # ============================================================
  # 6. 乱数の抽象化
  # ============================================================

  describe "RandomService" do
    test "random は0.0から1.0の範囲の値を返す" do
      for _ <- 1..100 do
        n = RandomService.random()
        assert n >= 0.0 and n < 1.0
      end
    end

    test "random_with_provider はプロバイダーから値を取得する" do
      provider = fn -> 0.42 end
      assert RandomService.random_with_provider(provider) == 0.42
    end

    test "random_int はプロバイダーから整数を取得する" do
      provider = fn _range -> 7 end
      assert RandomService.random_int(1..10, provider) == 7
    end

    test "random_element はリストから要素を選択する" do
      list = ["apple", "banana", "cherry"]
      provider = fn _range -> 2 end  # インデックス2 = "cherry"
      
      assert RandomService.random_element(list, provider) == "cherry"
    end

    test "with_probability は確率に基づいて真偽を返す" do
      provider_low = fn -> 0.1 end   # 10%
      provider_high = fn -> 0.9 end  # 90%
      
      # 50%の確率の場合
      assert RandomService.with_probability(0.5, provider_low) == true   # 0.1 < 0.5
      assert RandomService.with_probability(0.5, provider_high) == false # 0.9 >= 0.5
    end
  end

  # ============================================================
  # 7. ログの抽象化
  # ============================================================

  describe "Logger" do
    test "noop_logger は何もしない" do
      logger = Logger.noop_logger()
      assert logger.(:info, "test message") == :ok
    end

    test "collecting_logger はログを蓄積する" do
      {logger, get_logs} = Logger.collecting_logger()
      
      logger.(:info, "First message")
      logger.(:warn, "Second message")
      logger.(:error, "Third message")
      
      logs = get_logs.()
      
      assert length(logs) == 3
      assert {_, "First message", _} = Enum.at(logs, 0)
      assert {:warn, "Second message", _} = Enum.at(logs, 1)
      assert {:error, "Third message", _} = Enum.at(logs, 2)
    end

    test "with_min_level は指定レベル以上のログのみを通す" do
      {base_logger, get_logs} = Logger.collecting_logger()
      filtered_logger = Logger.with_min_level(base_logger, :warn)
      
      filtered_logger.(:debug, "Debug message")  # 無視される
      filtered_logger.(:info, "Info message")    # 無視される
      filtered_logger.(:warn, "Warn message")    # 記録される
      filtered_logger.(:error, "Error message")  # 記録される
      
      logs = get_logs.()
      
      assert length(logs) == 2
      assert {:warn, "Warn message", _} = Enum.at(logs, 0)
      assert {:error, "Error message", _} = Enum.at(logs, 1)
    end
  end

  # ============================================================
  # 8. ShoppingCart
  # ============================================================

  describe "ShoppingCart" do
    test "空のカートを作成できる" do
      cart = ShoppingCart.empty()
      assert cart.items == []
      assert cart.coupon == nil
    end

    test "カートに商品を追加できる" do
      cart = ShoppingCart.empty()
      item = %{id: "1", name: "Book", price: 1000, quantity: 2}
      
      cart = ShoppingCart.add_item(cart, item)
      
      assert length(cart.items) == 1
      assert Enum.at(cart.items, 0).name == "Book"
    end

    test "同じ商品を追加すると数量が増える" do
      cart = ShoppingCart.empty()
      item1 = %{id: "1", name: "Book", price: 1000, quantity: 2}
      item2 = %{id: "1", name: "Book", price: 1000, quantity: 3}
      
      cart = ShoppingCart.add_item(cart, item1)
      cart = ShoppingCart.add_item(cart, item2)
      
      assert length(cart.items) == 1
      assert Enum.at(cart.items, 0).quantity == 5
    end

    test "カートから商品を削除できる" do
      cart = ShoppingCart.empty()
      item = %{id: "1", name: "Book", price: 1000, quantity: 1}
      
      cart = ShoppingCart.add_item(cart, item)
      cart = ShoppingCart.remove_item(cart, "1")
      
      assert cart.items == []
    end

    test "クーポンを適用できる" do
      cart = ShoppingCart.empty()
      cart = ShoppingCart.apply_coupon(cart, "SAVE20")
      
      assert cart.coupon == "SAVE20"
    end

    test "小計を計算できる" do
      cart = ShoppingCart.empty()
      |> ShoppingCart.add_item(%{id: "1", name: "A", price: 100, quantity: 2})
      |> ShoppingCart.add_item(%{id: "2", name: "B", price: 50, quantity: 4})
      
      assert ShoppingCart.subtotal(cart) == 400
    end

    test "クーポンなしの合計を計算できる" do
      cart = ShoppingCart.empty()
      |> ShoppingCart.add_item(%{id: "1", name: "A", price: 1000, quantity: 1})
      
      resolver = fn _ -> 0.0 end
      
      assert ShoppingCart.total(cart, resolver) == 1000.0
    end

    test "クーポン適用後の合計を計算できる" do
      cart = ShoppingCart.empty()
      |> ShoppingCart.add_item(%{id: "1", name: "A", price: 1000, quantity: 1})
      |> ShoppingCart.apply_coupon("SAVE10")
      
      resolver = fn
        "SAVE10" -> 0.10
        "SAVE20" -> 0.20
        _ -> 0.0
      end
      
      assert ShoppingCart.total(cart, resolver) == 900.0
    end
  end
end
