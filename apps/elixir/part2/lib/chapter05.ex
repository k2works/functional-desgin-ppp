defmodule Chapter05 do
  @moduledoc """
  # Chapter 05: Property-Based Testing

  このモジュールでは、プロパティベーステストの概念と StreamData ライブラリを使った
  Elixir でのプロパティベーステストを学びます。

  ## プロパティベーステストとは

  従来の例示ベーステストでは、特定の入力に対する期待される出力を手動で指定します。
  プロパティベーステストでは、**すべての入力に対して成り立つべき性質（プロパティ）**を
  定義し、ランダムに生成された多数の入力でその性質を検証します。

  ## 主なトピック

  1. ジェネレータの基本
  2. プロパティの定義
  3. 収縮（シュリンキング）
  4. カスタムジェネレータ
  5. ドメイン固有のプロパティ
  """

  # ============================================================
  # 1. 基本的な数学関数（プロパティテスト対象）
  # ============================================================

  @doc """
  絶対値を返す。

  ## 性質（プロパティ）
  - 結果は常に非負: abs(x) >= 0
  - 冪等性: abs(abs(x)) == abs(x)
  - 偶関数: abs(-x) == abs(x)

  ## Examples

      iex> Chapter05.absolute(-5)
      5
      iex> Chapter05.absolute(5)
      5
      iex> Chapter05.absolute(0)
      0
  """
  @spec absolute(number()) :: number()
  def absolute(n) when n < 0, do: -n
  def absolute(n), do: n

  @doc """
  リストを反転する。

  ## 性質（プロパティ）
  - 反転の反転は元に戻る: reverse(reverse(xs)) == xs
  - 長さは保存される: length(reverse(xs)) == length(xs)
  - 単一要素リストは変わらない: reverse([x]) == [x]

  ## Examples

      iex> Chapter05.reverse([1, 2, 3])
      [3, 2, 1]
      iex> Chapter05.reverse([])
      []
  """
  @spec reverse(list()) :: list()
  def reverse(list), do: Enum.reverse(list)

  @doc """
  2つのリストを連結する。

  ## 性質（プロパティ）
  - 長さの加法性: length(xs ++ ys) == length(xs) + length(ys)
  - 結合律: (xs ++ ys) ++ zs == xs ++ (ys ++ zs)
  - 単位元: [] ++ xs == xs かつ xs ++ [] == xs

  ## Examples

      iex> Chapter05.concat([1, 2], [3, 4])
      [1, 2, 3, 4]
      iex> Chapter05.concat([], [1])
      [1]
  """
  @spec concat(list(), list()) :: list()
  def concat(xs, ys), do: xs ++ ys

  @doc """
  リストをソートする。

  ## 性質（プロパティ）
  - 冪等性: sort(sort(xs)) == sort(xs)
  - 長さの保存: length(sort(xs)) == length(xs)
  - 要素の保存: Enum.sort(xs) は元の要素を全て含む
  - 順序付け: 結果は昇順

  ## Examples

      iex> Chapter05.sort([3, 1, 2])
      [1, 2, 3]
      iex> Chapter05.sort([])
      []
  """
  @spec sort(list()) :: list()
  def sort(list), do: Enum.sort(list)

  # ============================================================
  # 2. 文字列操作関数
  # ============================================================

  @doc """
  文字列を大文字に変換する。

  ## 性質（プロパティ）
  - 冪等性: upcase(upcase(s)) == upcase(s)
  - 長さの保存: String.length(upcase(s)) == String.length(s)

  ## Examples

      iex> Chapter05.upcase("hello")
      "HELLO"
      iex> Chapter05.upcase("HELLO")
      "HELLO"
  """
  @spec upcase(String.t()) :: String.t()
  def upcase(s), do: String.upcase(s)

  @doc """
  文字列を小文字に変換する。

  ## 性質（プロパティ）
  - 冪等性: downcase(downcase(s)) == downcase(s)
  - 大文字との関係: downcase(upcase(s)) の後に upcase すると upcase(s) と等しい

  ## Examples

      iex> Chapter05.downcase("HELLO")
      "hello"
      iex> Chapter05.downcase("hello")
      "hello"
  """
  @spec downcase(String.t()) :: String.t()
  def downcase(s), do: String.downcase(s)

  @doc """
  文字列をトリムする。

  ## 性質（プロパティ）
  - 冪等性: trim(trim(s)) == trim(s)
  - 長さは減少または同じ: String.length(trim(s)) <= String.length(s)

  ## Examples

      iex> Chapter05.trim("  hello  ")
      "hello"
      iex> Chapter05.trim("hello")
      "hello"
  """
  @spec trim(String.t()) :: String.t()
  def trim(s), do: String.trim(s)

  # ============================================================
  # 3. データ構造操作
  # ============================================================

  @doc """
  マップの2つを深くマージする。

  ## 性質（プロパティ）
  - 単位元: deep_merge(%{}, m) == m かつ deep_merge(m, %{}) == m
  - 右優先: 衝突時は右のマップの値が優先

  ## Examples

      iex> Chapter05.deep_merge(%{a: 1}, %{b: 2})
      %{a: 1, b: 2}
      iex> Chapter05.deep_merge(%{a: 1}, %{a: 2})
      %{a: 2}
      iex> Chapter05.deep_merge(%{a: %{b: 1}}, %{a: %{c: 2}})
      %{a: %{b: 1, c: 2}}
  """
  @spec deep_merge(map(), map()) :: map()
  def deep_merge(left, right) do
    Map.merge(left, right, fn
      _k, %{} = v1, %{} = v2 -> deep_merge(v1, v2)
      _k, _v1, v2 -> v2
    end)
  end

  @doc """
  リストからユニークな要素のみを抽出する。

  ## 性質（プロパティ）
  - 冪等性: unique(unique(xs)) == unique(xs)
  - 長さは減少または同じ: length(unique(xs)) <= length(xs)
  - 重複なし: 結果に重複がない

  ## Examples

      iex> Chapter05.unique([1, 2, 2, 3, 3, 3])
      [1, 2, 3]
      iex> Chapter05.unique([])
      []
  """
  @spec unique(list()) :: list()
  def unique(list), do: Enum.uniq(list)

  # ============================================================
  # 4. エンコード/デコード関数
  # ============================================================

  @doc """
  整数をBase64エンコードする。

  ## Examples

      iex> Chapter05.encode_int(42)
      "NDI="
  """
  @spec encode_int(integer()) :: String.t()
  def encode_int(n) do
    n
    |> Integer.to_string()
    |> Base.encode64()
  end

  @doc """
  Base64文字列を整数にデコードする。

  ## Examples

      iex> Chapter05.decode_int("NDI=")
      {:ok, 42}
      iex> Chapter05.decode_int("invalid")
      :error
  """
  @spec decode_int(String.t()) :: {:ok, integer()} | :error
  def decode_int(s) do
    with {:ok, decoded} <- Base.decode64(s),
         {n, ""} <- Integer.parse(decoded) do
      {:ok, n}
    else
      _ -> :error
    end
  end

  @doc """
  JSON風のシリアライズ（簡易版）。

  ## 性質（プロパティ）
  - ラウンドトリップ: deserialize(serialize(x)) == {:ok, x}

  ## Examples

      iex> Chapter05.serialize(%{name: "Alice", age: 30})
      ~s({"age":30,"name":"Alice"})
  """
  @spec serialize(map()) :: String.t()
  def serialize(data) when is_map(data) do
    inner =
      data
      |> Enum.sort_by(fn {k, _} -> to_string(k) end)
      |> Enum.map(fn {k, v} -> ~s("#{k}":#{serialize_value(v)}) end)
      |> Enum.join(",")

    "{#{inner}}"
  end

  defp serialize_value(v) when is_binary(v), do: ~s("#{v}")
  defp serialize_value(v) when is_integer(v), do: Integer.to_string(v)
  defp serialize_value(v) when is_float(v), do: Float.to_string(v)
  defp serialize_value(v) when is_boolean(v), do: if(v, do: "true", else: "false")
  defp serialize_value(nil), do: "null"
  defp serialize_value(v) when is_atom(v), do: ~s("#{v}")
  defp serialize_value(v) when is_list(v) do
    inner = v |> Enum.map(&serialize_value/1) |> Enum.join(",")
    "[#{inner}]"
  end
  defp serialize_value(v) when is_map(v), do: serialize(v)

  @doc """
  JSON風のデシリアライズ（簡易版、整数とキー:値ペアのみ対応）。

  ## Examples

      iex> Chapter05.deserialize(~s({"age":30,"name":"Alice"}))
      {:ok, %{"age" => 30, "name" => "Alice"}}
  """
  @spec deserialize(String.t()) :: {:ok, map()} | {:error, String.t()}
  def deserialize(json) do
    try do
      # 簡易的なJSON風パーサー
      {:ok, parse_object(String.trim(json))}
    rescue
      _ -> {:error, "Invalid JSON"}
    end
  end

  defp parse_object(s) do
    s = String.trim(s)
    if String.starts_with?(s, "{") and String.ends_with?(s, "}") do
      inner = s |> String.slice(1..-2//1) |> String.trim()
      if inner == "" do
        %{}
      else
        parse_pairs(inner)
      end
    else
      raise "Not an object"
    end
  end

  defp parse_pairs(s) do
    # 簡易的なパース：カンマで分割してキー:値ペアを処理
    pairs = split_pairs(s)
    Enum.reduce(pairs, %{}, fn pair, acc ->
      [key_part, value_part] = String.split(pair, ":", parts: 2)
      key = key_part |> String.trim() |> String.trim("\"")
      value = parse_value(String.trim(value_part))
      Map.put(acc, key, value)
    end)
  end

  defp split_pairs(s) do
    # ネストを考慮した分割（簡易版）
    {pairs, current, _depth} =
      String.graphemes(s)
      |> Enum.reduce({[], "", 0}, fn char, {pairs, current, depth} ->
        cond do
          char == "," and depth == 0 ->
            {[current | pairs], "", 0}
          char in ["{", "["] ->
            {pairs, current <> char, depth + 1}
          char in ["}", "]"] ->
            {pairs, current <> char, depth - 1}
          true ->
            {pairs, current <> char, depth}
        end
      end)

    ([current | pairs] |> Enum.reverse() |> Enum.reject(&(&1 == "")))
  end

  defp parse_value(s) do
    s = String.trim(s)
    cond do
      String.starts_with?(s, "\"") and String.ends_with?(s, "\"") ->
        String.slice(s, 1..-2//1)
      s == "true" -> true
      s == "false" -> false
      s == "null" -> nil
      String.contains?(s, ".") ->
        {f, ""} = Float.parse(s)
        f
      true ->
        case Integer.parse(s) do
          {n, ""} -> n
          _ -> s
        end
    end
  end

  # ============================================================
  # 5. ドメインモデル（プロパティテスト対象）
  # ============================================================

  defmodule Money do
    @moduledoc """
    通貨を表すドメインモデル。
    プロパティベーステストでモノイド則を検証できる。
    """
    @enforce_keys [:amount, :currency]
    defstruct [:amount, :currency]

    @type t :: %__MODULE__{
      amount: integer(),
      currency: String.t()
    }

    @doc """
    新しいMoneyを作成する。

    ## Examples

        iex> Chapter05.Money.new(100, "JPY")
        %Chapter05.Money{amount: 100, currency: "JPY"}
    """
    @spec new(integer(), String.t()) :: t()
    def new(amount, currency) do
      %__MODULE__{amount: amount, currency: currency}
    end

    @doc """
    同じ通貨のMoneyを加算する。

    ## 性質（プロパティ）
    - 結合律: add(add(a, b), c) == add(a, add(b, c))
    - 単位元: add(zero(currency), m) == m
    - 可換律: add(a, b) == add(b, a)

    ## Examples

        iex> m1 = Chapter05.Money.new(100, "JPY")
        iex> m2 = Chapter05.Money.new(200, "JPY")
        iex> Chapter05.Money.add(m1, m2)
        {:ok, %Chapter05.Money{amount: 300, currency: "JPY"}}
    """
    @spec add(t(), t()) :: {:ok, t()} | {:error, String.t()}
    def add(%__MODULE__{currency: c1}, %__MODULE__{currency: c2}) when c1 != c2 do
      {:error, "Currency mismatch: #{c1} vs #{c2}"}
    end
    def add(%__MODULE__{amount: a1, currency: c}, %__MODULE__{amount: a2, currency: c}) do
      {:ok, new(a1 + a2, c)}
    end

    @doc """
    ゼロ金額を作成する（加法の単位元）。

    ## Examples

        iex> Chapter05.Money.zero("JPY")
        %Chapter05.Money{amount: 0, currency: "JPY"}
    """
    @spec zero(String.t()) :: t()
    def zero(currency), do: new(0, currency)

    @doc """
    金額を乗算する。

    ## Examples

        iex> m = Chapter05.Money.new(100, "JPY")
        iex> Chapter05.Money.multiply(m, 3)
        %Chapter05.Money{amount: 300, currency: "JPY"}
    """
    @spec multiply(t(), integer()) :: t()
    def multiply(%__MODULE__{amount: a, currency: c}, factor) do
      new(a * factor, c)
    end
  end

  defmodule Cart do
    @moduledoc """
    ショッピングカートを表すドメインモデル。
    """
    defstruct items: []

    @type item :: {String.t(), pos_integer(), Money.t()}
    @type t :: %__MODULE__{items: [item()]}

    @doc """
    空のカートを作成する。

    ## Examples

        iex> Chapter05.Cart.empty()
        %Chapter05.Cart{items: []}
    """
    @spec empty() :: t()
    def empty, do: %__MODULE__{items: []}

    @doc """
    カートに商品を追加する。

    ## 性質（プロパティ）
    - 追加後のアイテム数は増加: length(add_item(cart).items) >= length(cart.items)

    ## Examples

        iex> cart = Chapter05.Cart.empty()
        iex> price = Chapter05.Money.new(1000, "JPY")
        iex> cart = Chapter05.Cart.add_item(cart, "Book", 2, price)
        iex> length(cart.items)
        1
    """
    @spec add_item(t(), String.t(), pos_integer(), Money.t()) :: t()
    def add_item(%__MODULE__{items: items}, name, qty, price) do
      %__MODULE__{items: [{name, qty, price} | items]}
    end

    @doc """
    カートの合計金額を計算する。

    ## 性質（プロパティ）
    - 合計は非負: total(cart).amount >= 0（価格が非負の場合）
    - 空カートの合計はゼロ: total(empty()).amount == 0

    ## Examples

        iex> cart = Chapter05.Cart.empty()
        iex> price = Chapter05.Money.new(100, "JPY")
        iex> cart = Chapter05.Cart.add_item(cart, "Item", 3, price)
        iex> Chapter05.Cart.total(cart, "JPY")
        %Chapter05.Money{amount: 300, currency: "JPY"}
    """
    @spec total(t(), String.t()) :: Money.t()
    def total(%__MODULE__{items: items}, currency) do
      items
      |> Enum.reduce(Money.zero(currency), fn {_name, qty, price}, acc ->
        item_total = Money.multiply(price, qty)
        case Money.add(acc, item_total) do
          {:ok, sum} -> sum
          {:error, _} -> acc  # 通貨が違う場合はスキップ
        end
      end)
    end
  end

  # ============================================================
  # 6. ジェネレータヘルパー
  # StreamDataで使用するカスタムジェネレータを定義するためのヘルパー関数群。
  # これらはテストコードで使用されます。
  # ============================================================

  @doc """
  正の整数のみを含むリストかどうかを判定する。

  ## Examples

      iex> Chapter05.all_positive?([1, 2, 3])
      true
      iex> Chapter05.all_positive?([1, -2, 3])
      false
      iex> Chapter05.all_positive?([])
      true
  """
  @spec all_positive?(list(integer())) :: boolean()
  def all_positive?(list), do: Enum.all?(list, &(&1 > 0))

  @doc """
  リストがソート済みかどうかを判定する。

  ## Examples

      iex> Chapter05.sorted?([1, 2, 3])
      true
      iex> Chapter05.sorted?([3, 1, 2])
      false
      iex> Chapter05.sorted?([])
      true
  """
  @spec sorted?(list()) :: boolean()
  def sorted?(list), do: list == Enum.sort(list)

  @doc """
  リストに重複がないかどうかを判定する。

  ## Examples

      iex> Chapter05.no_duplicates?([1, 2, 3])
      true
      iex> Chapter05.no_duplicates?([1, 2, 2])
      false
      iex> Chapter05.no_duplicates?([])
      true
  """
  @spec no_duplicates?(list()) :: boolean()
  def no_duplicates?(list), do: length(list) == length(Enum.uniq(list))

  @doc """
  有効なメールアドレス形式かどうかを判定する（簡易版）。

  ## Examples

      iex> Chapter05.valid_email?("test@example.com")
      true
      iex> Chapter05.valid_email?("invalid")
      false
  """
  @spec valid_email?(String.t()) :: boolean()
  def valid_email?(email) do
    String.contains?(email, "@") and String.contains?(email, ".")
  end
end
