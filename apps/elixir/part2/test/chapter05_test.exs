defmodule Chapter05Test do
  use ExUnit.Case
  use ExUnitProperties
  doctest Chapter05

  alias Chapter05.{Money, Cart}

  # ============================================================
  # 1. 基本的な数学関数のプロパティテスト
  # ============================================================

  describe "absolute/1 のプロパティ" do
    property "結果は常に非負" do
      check all n <- integer() do
        assert Chapter05.absolute(n) >= 0
      end
    end

    property "冪等性: abs(abs(x)) == abs(x)" do
      check all n <- integer() do
        assert Chapter05.absolute(Chapter05.absolute(n)) == Chapter05.absolute(n)
      end
    end

    property "偶関数: abs(-x) == abs(x)" do
      check all n <- integer() do
        assert Chapter05.absolute(-n) == Chapter05.absolute(n)
      end
    end
  end

  describe "reverse/1 のプロパティ" do
    property "反転の反転は元に戻る" do
      check all list <- list_of(integer()) do
        assert Chapter05.reverse(Chapter05.reverse(list)) == list
      end
    end

    property "長さは保存される" do
      check all list <- list_of(term()) do
        assert length(Chapter05.reverse(list)) == length(list)
      end
    end

    property "単一要素リストは変わらない" do
      check all x <- term() do
        assert Chapter05.reverse([x]) == [x]
      end
    end
  end

  describe "concat/2 のプロパティ" do
    property "長さの加法性" do
      check all xs <- list_of(integer()),
                ys <- list_of(integer()) do
        assert length(Chapter05.concat(xs, ys)) == length(xs) + length(ys)
      end
    end

    property "結合律" do
      check all xs <- list_of(integer()),
                ys <- list_of(integer()),
                zs <- list_of(integer()) do
        left = Chapter05.concat(Chapter05.concat(xs, ys), zs)
        right = Chapter05.concat(xs, Chapter05.concat(ys, zs))
        assert left == right
      end
    end

    property "空リストは単位元" do
      check all xs <- list_of(integer()) do
        assert Chapter05.concat([], xs) == xs
        assert Chapter05.concat(xs, []) == xs
      end
    end
  end

  describe "sort/1 のプロパティ" do
    property "冪等性: sort(sort(xs)) == sort(xs)" do
      check all list <- list_of(integer()) do
        assert Chapter05.sort(Chapter05.sort(list)) == Chapter05.sort(list)
      end
    end

    property "長さは保存される" do
      check all list <- list_of(integer()) do
        assert length(Chapter05.sort(list)) == length(list)
      end
    end

    property "結果はソート済み" do
      check all list <- list_of(integer()) do
        sorted = Chapter05.sort(list)
        assert Chapter05.sorted?(sorted)
      end
    end

    property "要素は保存される" do
      check all list <- list_of(integer()) do
        sorted = Chapter05.sort(list)
        assert Enum.sort(list) == Enum.sort(sorted)
      end
    end
  end

  # ============================================================
  # 2. 文字列操作関数のプロパティテスト
  # ============================================================

  describe "upcase/1 のプロパティ" do
    property "冪等性" do
      check all s <- string(:printable) do
        assert Chapter05.upcase(Chapter05.upcase(s)) == Chapter05.upcase(s)
      end
    end

    property "長さは保存される" do
      check all s <- string(:ascii) do
        assert String.length(Chapter05.upcase(s)) == String.length(s)
      end
    end
  end

  describe "downcase/1 のプロパティ" do
    property "冪等性" do
      check all s <- string(:printable) do
        assert Chapter05.downcase(Chapter05.downcase(s)) == Chapter05.downcase(s)
      end
    end
  end

  describe "trim/1 のプロパティ" do
    property "冪等性" do
      check all s <- string(:printable) do
        assert Chapter05.trim(Chapter05.trim(s)) == Chapter05.trim(s)
      end
    end

    property "長さは減少または同じ" do
      check all s <- string(:printable) do
        assert String.length(Chapter05.trim(s)) <= String.length(s)
      end
    end

    property "結果の前後に空白がない" do
      check all s <- string(:printable) do
        trimmed = Chapter05.trim(s)
        if trimmed != "" do
          assert not String.starts_with?(trimmed, " ")
          assert not String.ends_with?(trimmed, " ")
        end
      end
    end
  end

  # ============================================================
  # 3. データ構造操作のプロパティテスト
  # ============================================================

  describe "deep_merge/2 のプロパティ" do
    property "空マップは単位元" do
      check all m <- map_of(atom(:alphanumeric), integer()) do
        assert Chapter05.deep_merge(%{}, m) == m
        assert Chapter05.deep_merge(m, %{}) == m
      end
    end

    property "右優先でマージされる" do
      check all k <- atom(:alphanumeric),
                v1 <- integer(),
                v2 <- integer() do
        m1 = %{k => v1}
        m2 = %{k => v2}
        assert Chapter05.deep_merge(m1, m2) == %{k => v2}
      end
    end
  end

  describe "unique/1 のプロパティ" do
    property "冪等性" do
      check all list <- list_of(integer()) do
        assert Chapter05.unique(Chapter05.unique(list)) == Chapter05.unique(list)
      end
    end

    property "長さは減少または同じ" do
      check all list <- list_of(integer()) do
        assert length(Chapter05.unique(list)) <= length(list)
      end
    end

    property "結果に重複がない" do
      check all list <- list_of(integer()) do
        result = Chapter05.unique(list)
        assert Chapter05.no_duplicates?(result)
      end
    end

    property "元の要素はすべて含まれる" do
      check all list <- list_of(integer()) do
        unique_list = Chapter05.unique(list)
        assert Enum.all?(list, fn x -> x in unique_list end)
      end
    end
  end

  # ============================================================
  # 4. エンコード/デコードのプロパティテスト
  # ============================================================

  describe "encode_int/decode_int ラウンドトリップ" do
    property "エンコードしてデコードすると元に戻る" do
      check all n <- integer() do
        encoded = Chapter05.encode_int(n)
        assert {:ok, ^n} = Chapter05.decode_int(encoded)
      end
    end
  end

  describe "serialize/deserialize ラウンドトリップ" do
    property "シンプルなマップのラウンドトリップ" do
      check all key <- atom(:alphanumeric),
                value <- integer() do
        original = %{key => value}
        serialized = Chapter05.serialize(original)
        {:ok, deserialized} = Chapter05.deserialize(serialized)
        # キーは文字列になる
        assert deserialized[to_string(key)] == value
      end
    end
  end

  # ============================================================
  # 5. ドメインモデルのプロパティテスト
  # ============================================================

  describe "Money のプロパティ" do
    # カスタムジェネレータ
    defp money_generator(currency) do
      gen all amount <- integer() do
        Money.new(amount, currency)
      end
    end

    property "加法の結合律" do
      check all a <- money_generator("JPY"),
                b <- money_generator("JPY"),
                c <- money_generator("JPY") do
        {:ok, ab} = Money.add(a, b)
        {:ok, ab_c} = Money.add(ab, c)
        {:ok, bc} = Money.add(b, c)
        {:ok, a_bc} = Money.add(a, bc)
        assert ab_c == a_bc
      end
    end

    property "加法の可換律" do
      check all a <- money_generator("JPY"),
                b <- money_generator("JPY") do
        {:ok, ab} = Money.add(a, b)
        {:ok, ba} = Money.add(b, a)
        assert ab == ba
      end
    end

    property "ゼロは加法の単位元" do
      check all m <- money_generator("JPY") do
        zero = Money.zero("JPY")
        {:ok, m_plus_zero} = Money.add(m, zero)
        {:ok, zero_plus_m} = Money.add(zero, m)
        assert m_plus_zero == m
        assert zero_plus_m == m
      end
    end

    property "異なる通貨の加算はエラー" do
      check all jpy <- money_generator("JPY"),
                usd <- money_generator("USD") do
        assert {:error, _} = Money.add(jpy, usd)
      end
    end

    property "乗算は分配的" do
      check all amount <- integer(),
                factor <- integer(-100..100) do
        m = Money.new(amount, "JPY")
        result = Money.multiply(m, factor)
        assert result.amount == amount * factor
      end
    end
  end

  describe "Cart のプロパティ" do
    defp non_negative_price_generator do
      gen all amount <- non_negative_integer() do
        Money.new(amount, "JPY")
      end
    end

    defp item_generator do
      gen all name <- string(:alphanumeric, min_length: 1),
              qty <- positive_integer(),
              price <- non_negative_price_generator() do
        {name, qty, price}
      end
    end

    property "空カートの合計はゼロ" do
      cart = Cart.empty()
      assert Cart.total(cart, "JPY").amount == 0
    end

    property "アイテム追加後、アイテム数は増加" do
      check all {name, qty, price} <- item_generator() do
        cart = Cart.empty()
        cart = Cart.add_item(cart, name, qty, price)
        assert length(cart.items) == 1
      end
    end

    property "合計は各アイテムの小計の和" do
      check all items <- list_of(item_generator(), min_length: 1, max_length: 5) do
        cart =
          Enum.reduce(items, Cart.empty(), fn {name, qty, price}, acc ->
            Cart.add_item(acc, name, qty, price)
          end)

        expected_total =
          Enum.reduce(items, 0, fn {_name, qty, price}, acc ->
            acc + qty * price.amount
          end)

        assert Cart.total(cart, "JPY").amount == expected_total
      end
    end
  end

  # ============================================================
  # 6. ヘルパー関数のテスト
  # ============================================================

  describe "ヘルパー関数" do
    property "all_positive? は正の整数リストで真" do
      check all list <- list_of(positive_integer()) do
        assert Chapter05.all_positive?(list)
      end
    end

    property "sorted? はソート済みリストで真" do
      check all list <- list_of(integer()) do
        sorted = Enum.sort(list)
        assert Chapter05.sorted?(sorted)
      end
    end

    property "no_duplicates? はユニークリストで真" do
      check all list <- list_of(integer()) do
        unique = Enum.uniq(list)
        assert Chapter05.no_duplicates?(unique)
      end
    end
  end

  # ============================================================
  # 7. 収縮（シュリンキング）のデモ
  # ============================================================

  describe "収縮のデモ（コメントアウト時に失敗を確認可能）" do
    # このテストは収縮を確認するためのもの
    # 失敗すると、最小の反例が表示される
    @tag :skip
    test "故意に失敗するプロパティ（収縮のデモ）" do
      # check all list <- list_of(integer(), min_length: 1) do
      #   # この条件は必ず失敗する入力がある
      #   assert Enum.sum(list) < 100
      # end
    end
  end

  # ============================================================
  # 8. カスタムジェネレータの例
  # ============================================================

  describe "カスタムジェネレータ" do
    # メールアドレスのカスタムジェネレータ
    defp email_generator do
      gen all local <- string(:alphanumeric, min_length: 1, max_length: 10),
              domain <- string(:alphanumeric, min_length: 1, max_length: 10),
              tld <- member_of(["com", "org", "net", "io"]) do
        "#{local}@#{domain}.#{tld}"
      end
    end

    property "生成されたメールアドレスは有効な形式" do
      check all email <- email_generator() do
        assert Chapter05.valid_email?(email)
      end
    end

    # 正の整数リストのカスタムジェネレータ
    defp positive_list_generator do
      list_of(positive_integer(), min_length: 1)
    end

    property "正の整数リストはall_positive?を満たす" do
      check all list <- positive_list_generator() do
        assert Chapter05.all_positive?(list)
      end
    end

    # 範囲付き整数のジェネレータ
    defp bounded_integer_generator(min, max) do
      integer(min..max)
    end

    property "範囲付き整数は範囲内" do
      check all n <- bounded_integer_generator(1, 100) do
        assert n >= 1 and n <= 100
      end
    end
  end
end
