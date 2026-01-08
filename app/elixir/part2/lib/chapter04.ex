defmodule Chapter04 do
  @moduledoc """
  第4章: データ検証

  Elixir におけるデータバリデーションの実現方法を学びます。
  {:ok, value} / {:error, reason} パターン、with 式、カスタムバリデータを活用します。
  """

  # ============================================================
  # 1. 基本的なバリデーション（Result パターン）
  # ============================================================

  @type validation_result(a) :: {:ok, a} | {:error, [String.t()]}

  @doc """
  名前をバリデートする。

  ## Examples

      iex> Chapter04.validate_name("田中太郎")
      {:ok, "田中太郎"}
      iex> Chapter04.validate_name("")
      {:error, ["名前は空にできません"]}
      iex> Chapter04.validate_name(String.duplicate("あ", 101))
      {:error, ["名前は100文字以内である必要があります"]}
  """
  @spec validate_name(String.t()) :: validation_result(String.t())
  def validate_name(name) do
    cond do
      name == "" -> {:error, ["名前は空にできません"]}
      String.length(name) > 100 -> {:error, ["名前は100文字以内である必要があります"]}
      true -> {:ok, name}
    end
  end

  @doc """
  年齢をバリデートする。

  ## Examples

      iex> Chapter04.validate_age(25)
      {:ok, 25}
      iex> Chapter04.validate_age(-1)
      {:error, ["年齢は0以上である必要があります"]}
      iex> Chapter04.validate_age(200)
      {:error, ["年齢は150以下である必要があります"]}
  """
  @spec validate_age(integer()) :: validation_result(integer())
  def validate_age(age) do
    cond do
      age < 0 -> {:error, ["年齢は0以上である必要があります"]}
      age > 150 -> {:error, ["年齢は150以下である必要があります"]}
      true -> {:ok, age}
    end
  end

  @doc """
  メールアドレスをバリデートする。

  ## Examples

      iex> Chapter04.validate_email("test@example.com")
      {:ok, "test@example.com"}
      iex> Chapter04.validate_email("invalid")
      {:error, ["無効なメールアドレス形式です"]}
  """
  @spec validate_email(String.t()) :: validation_result(String.t())
  def validate_email(email) do
    if Regex.match?(~r/.+@.+\..+/, email) do
      {:ok, email}
    else
      {:error, ["無効なメールアドレス形式です"]}
    end
  end

  # ============================================================
  # 2. 列挙型とスマートコンストラクタ
  # ============================================================

  @type membership :: :bronze | :silver | :gold | :platinum
  @type status :: :active | :inactive | :suspended

  @doc """
  文字列から会員種別を解析する。

  ## Examples

      iex> Chapter04.parse_membership("gold")
      {:ok, :gold}
      iex> Chapter04.parse_membership("SILVER")
      {:ok, :silver}
      iex> Chapter04.parse_membership("invalid")
      {:error, ["無効な会員種別: invalid"]}
  """
  @spec parse_membership(String.t()) :: validation_result(membership())
  def parse_membership(s) do
    case String.downcase(s) do
      "bronze" -> {:ok, :bronze}
      "silver" -> {:ok, :silver}
      "gold" -> {:ok, :gold}
      "platinum" -> {:ok, :platinum}
      _ -> {:error, ["無効な会員種別: #{s}"]}
    end
  end

  @doc """
  文字列からステータスを解析する。

  ## Examples

      iex> Chapter04.parse_status("active")
      {:ok, :active}
      iex> Chapter04.parse_status("unknown")
      {:error, ["無効なステータス: unknown"]}
  """
  @spec parse_status(String.t()) :: validation_result(status())
  def parse_status(s) do
    case String.downcase(s) do
      "active" -> {:ok, :active}
      "inactive" -> {:ok, :inactive}
      "suspended" -> {:ok, :suspended}
      _ -> {:error, ["無効なステータス: #{s}"]}
    end
  end

  # ============================================================
  # 3. Validated パターン（エラー蓄積）
  # ============================================================

  defmodule Validated do
    @moduledoc """
    エラーを蓄積するバリデーション結果を表す。
    """

    @type t(a) :: {:valid, a} | {:invalid, [String.t()]}

    @doc "有効な値を作成"
    @spec valid(a) :: t(a) when a: any()
    def valid(value), do: {:valid, value}

    @doc "無効な値を作成"
    @spec invalid([String.t()]) :: t(any())
    def invalid(errors), do: {:invalid, errors}

    @doc "バリデーション結果を変換"
    @spec map(t(a), (a -> b)) :: t(b) when a: any(), b: any()
    def map({:valid, value}, f), do: {:valid, f.(value)}
    def map({:invalid, errors}, _f), do: {:invalid, errors}

    @doc "バリデーション結果をフラットマップ"
    @spec flat_map(t(a), (a -> t(b))) :: t(b) when a: any(), b: any()
    def flat_map({:valid, value}, f), do: f.(value)
    def flat_map({:invalid, errors}, _f), do: {:invalid, errors}

    @doc "有効かどうかを確認"
    @spec valid?(t(any())) :: boolean()
    def valid?({:valid, _}), do: true
    def valid?({:invalid, _}), do: false

    @doc "2つの Validated を結合（エラー蓄積）"
    @spec combine(t(a), t(b), (a, b -> c)) :: t(c) when a: any(), b: any(), c: any()
    def combine({:valid, a}, {:valid, b}, f), do: {:valid, f.(a, b)}
    def combine({:invalid, e1}, {:invalid, e2}, _f), do: {:invalid, e1 ++ e2}
    def combine({:invalid, e}, _, _f), do: {:invalid, e}
    def combine(_, {:invalid, e}, _f), do: {:invalid, e}

    @doc "3つの Validated を結合（エラー蓄積）"
    @spec combine3(t(a), t(b), t(c), (a, b, c -> d)) :: t(d)
          when a: any(), b: any(), c: any(), d: any()
    def combine3(va, vb, vc, f) do
      case {va, vb, vc} do
        {{:valid, a}, {:valid, b}, {:valid, c}} ->
          {:valid, f.(a, b, c)}

        _ ->
          errors =
            [va, vb, vc]
            |> Enum.flat_map(fn
              {:invalid, e} -> e
              _ -> []
            end)

          {:invalid, errors}
      end
    end

    @doc "Result から Validated に変換"
    @spec from_result({:ok, a} | {:error, [String.t()]}) :: t(a) when a: any()
    def from_result({:ok, value}), do: {:valid, value}
    def from_result({:error, errors}), do: {:invalid, errors}

    @doc "Validated から Result に変換"
    @spec to_result(t(a)) :: {:ok, a} | {:error, [String.t()]} when a: any()
    def to_result({:valid, value}), do: {:ok, value}
    def to_result({:invalid, errors}), do: {:error, errors}
  end

  # ============================================================
  # 4. ユーザーバリデーション（実践例）
  # ============================================================

  defmodule User do
    @moduledoc "ユーザーを表す構造体"
    @enforce_keys [:name, :age, :email]
    defstruct [:name, :age, :email, :membership, :status]

    @type t :: %__MODULE__{
            name: String.t(),
            age: non_neg_integer(),
            email: String.t(),
            membership: Chapter04.membership() | nil,
            status: Chapter04.status() | nil
          }
  end

  @doc """
  with 式を使ったユーザーバリデーション（最初のエラーで停止）。

  ## Examples

      iex> Chapter04.validate_user_with(%{name: "田中", age: 25, email: "tanaka@example.com"})
      {:ok, %Chapter04.User{name: "田中", age: 25, email: "tanaka@example.com", membership: nil, status: nil}}

      iex> Chapter04.validate_user_with(%{name: "", age: 25, email: "test@example.com"})
      {:error, ["名前は空にできません"]}
  """
  @spec validate_user_with(map()) :: validation_result(User.t())
  def validate_user_with(params) do
    with {:ok, name} <- validate_name(Map.get(params, :name, "")),
         {:ok, age} <- validate_age(Map.get(params, :age, 0)),
         {:ok, email} <- validate_email(Map.get(params, :email, "")) do
      {:ok, %User{name: name, age: age, email: email}}
    end
  end

  @doc """
  エラーを蓄積するユーザーバリデーション。

  ## Examples

      iex> result = Chapter04.validate_user_accumulate(%{name: "田中", age: 25, email: "tanaka@example.com"})
      iex> Chapter04.Validated.valid?(result)
      true

      iex> result = Chapter04.validate_user_accumulate(%{name: "", age: -1, email: "invalid"})
      iex> Chapter04.Validated.valid?(result)
      false
  """
  @spec validate_user_accumulate(map()) :: Validated.t(User.t())
  def validate_user_accumulate(params) do
    v_name = params |> Map.get(:name, "") |> validate_name() |> Validated.from_result()
    v_age = params |> Map.get(:age, 0) |> validate_age() |> Validated.from_result()
    v_email = params |> Map.get(:email, "") |> validate_email() |> Validated.from_result()

    Validated.combine3(v_name, v_age, v_email, fn name, age, email ->
      %User{name: name, age: age, email: email}
    end)
  end

  # ============================================================
  # 5. バリデータの合成
  # ============================================================

  @doc """
  バリデータを作成する。

  ## Examples

      iex> is_positive = Chapter04.validator(fn x -> x > 0 end, "値は正の数である必要があります")
      iex> is_positive.(5)
      {:ok, 5}
      iex> is_positive.(-1)
      {:error, ["値は正の数である必要があります"]}
  """
  @spec validator((a -> boolean()), String.t()) :: (a -> validation_result(a)) when a: any()
  def validator(pred, error_msg) do
    fn value ->
      if pred.(value) do
        {:ok, value}
      else
        {:error, [error_msg]}
      end
    end
  end

  @doc """
  複数のバリデータを順次適用する（最初のエラーで停止）。

  ## Examples

      iex> validators = [
      ...>   Chapter04.validator(fn x -> x > 0 end, "正の数が必要"),
      ...>   Chapter04.validator(fn x -> x < 100 end, "100未満が必要")
      ...> ]
      iex> Chapter04.validate_all(50, validators)
      {:ok, 50}
      iex> Chapter04.validate_all(-1, validators)
      {:error, ["正の数が必要"]}
  """
  @spec validate_all(a, [(a -> validation_result(a))]) :: validation_result(a) when a: any()
  def validate_all(value, validators) do
    Enum.reduce_while(validators, {:ok, value}, fn v, {:ok, val} ->
      case v.(val) do
        {:ok, _} = result -> {:cont, result}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  複数のバリデータを適用し、すべてのエラーを蓄積する。

  ## Examples

      iex> validators = [
      ...>   Chapter04.validator(fn x -> x > 0 end, "正の数が必要"),
      ...>   Chapter04.validator(fn x -> x < 100 end, "100未満が必要")
      ...> ]
      iex> Chapter04.validate_all_accumulate(-200, validators)
      {:invalid, ["正の数が必要"]}
  """
  @spec validate_all_accumulate(a, [(a -> validation_result(a))]) :: Validated.t(a) when a: any()
  def validate_all_accumulate(value, validators) do
    errors =
      validators
      |> Enum.map(fn v -> v.(value) end)
      |> Enum.flat_map(fn
        {:error, e} -> e
        {:ok, _} -> []
      end)

    if errors == [] do
      {:valid, value}
    else
      {:invalid, errors}
    end
  end

  # ============================================================
  # 6. 値オブジェクト（スマートコンストラクタ）
  # ============================================================

  defmodule Email do
    @moduledoc """
    メールアドレスを表す値オブジェクト。
    スマートコンストラクタにより、不正なメールアドレスは作成できない。
    """
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{value: String.t()}

    @doc """
    メールアドレスを作成する。

    ## Examples

        iex> {:ok, email} = Chapter04.Email.new("test@example.com")
        iex> email.value
        "test@example.com"
        iex> Chapter04.Email.new("invalid")
        {:error, "無効なメールアドレス形式です"}
    """
    @spec new(String.t()) :: {:ok, t()} | {:error, String.t()}
    def new(value) do
      if Regex.match?(~r/.+@.+\..+/, value) do
        {:ok, %__MODULE__{value: value}}
      else
        {:error, "無効なメールアドレス形式です"}
      end
    end

    @doc "メールアドレスを文字列として取得"
    @spec to_string(t()) :: String.t()
    def to_string(%__MODULE__{value: value}), do: value
  end

  defmodule PositiveInteger do
    @moduledoc """
    正の整数を表す値オブジェクト。
    """
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{value: pos_integer()}

    @doc """
    正の整数を作成する。

    ## Examples

        iex> {:ok, num} = Chapter04.PositiveInteger.new(42)
        iex> num.value
        42
        iex> Chapter04.PositiveInteger.new(0)
        {:error, "値は正の整数である必要があります"}
        iex> Chapter04.PositiveInteger.new(-5)
        {:error, "値は正の整数である必要があります"}
    """
    @spec new(integer()) :: {:ok, t()} | {:error, String.t()}
    def new(value) when is_integer(value) and value > 0 do
      {:ok, %__MODULE__{value: value}}
    end

    def new(_) do
      {:error, "値は正の整数である必要があります"}
    end
  end

  defmodule NonEmptyString do
    @moduledoc """
    空でない文字列を表す値オブジェクト。
    """
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{value: String.t()}

    @doc """
    空でない文字列を作成する。

    ## Examples

        iex> {:ok, s} = Chapter04.NonEmptyString.new("hello")
        iex> s.value
        "hello"
        iex> Chapter04.NonEmptyString.new("")
        {:error, "文字列は空にできません"}
    """
    @spec new(String.t()) :: {:ok, t()} | {:error, String.t()}
    def new(value) when is_binary(value) and byte_size(value) > 0 do
      {:ok, %__MODULE__{value: value}}
    end

    def new(_) do
      {:error, "文字列は空にできません"}
    end
  end

  # ============================================================
  # 7. 複合バリデーション
  # ============================================================

  defmodule Order do
    @moduledoc "注文を表す構造体"
    @enforce_keys [:items, :customer_email, :quantity]
    defstruct [:items, :customer_email, :quantity]

    @type t :: %__MODULE__{
            items: [String.t()],
            customer_email: String.t(),
            quantity: pos_integer()
          }
  end

  @doc """
  注文をバリデートする。

  ## Examples

      iex> params = %{items: ["item1", "item2"], customer_email: "test@example.com", quantity: 5}
      iex> {:ok, order} = Chapter04.validate_order(params)
      iex> order.quantity
      5

      iex> params = %{items: [], customer_email: "invalid", quantity: 0}
      iex> {:error, errors} = Chapter04.validate_order(params)
      iex> length(errors) >= 2
      true
  """
  @spec validate_order(map()) :: validation_result(Order.t())
  def validate_order(params) do
    v_items =
      params
      |> Map.get(:items, [])
      |> validate_items()
      |> Validated.from_result()

    v_email =
      params
      |> Map.get(:customer_email, "")
      |> validate_email()
      |> Validated.from_result()

    v_quantity =
      params
      |> Map.get(:quantity, 0)
      |> validate_quantity()
      |> Validated.from_result()

    result =
      Validated.combine3(v_items, v_email, v_quantity, fn items, email, quantity ->
        %Order{items: items, customer_email: email, quantity: quantity}
      end)

    Validated.to_result(result)
  end

  defp validate_items([]), do: {:error, ["注文には少なくとも1つのアイテムが必要です"]}
  defp validate_items(items) when is_list(items), do: {:ok, items}

  defp validate_quantity(q) when is_integer(q) and q > 0, do: {:ok, q}
  defp validate_quantity(_), do: {:error, ["数量は正の整数である必要があります"]}

  # ============================================================
  # 8. カスタムエラー型
  # ============================================================

  defmodule ValidationError do
    @moduledoc "バリデーションエラーを表す構造体"
    @enforce_keys [:field, :message]
    defstruct [:field, :message, :code]

    @type t :: %__MODULE__{
            field: atom(),
            message: String.t(),
            code: atom() | nil
          }
  end

  @type typed_result(a) :: {:ok, a} | {:error, [ValidationError.t()]}

  @doc """
  構造化されたエラーでバリデートする。

  ## Examples

      iex> {:error, [error]} = Chapter04.validate_name_typed("")
      iex> error.field
      :name
      iex> error.code
      :required
  """
  @spec validate_name_typed(String.t()) :: typed_result(String.t())
  def validate_name_typed(name) do
    cond do
      name == "" ->
        {:error,
         [%ValidationError{field: :name, message: "名前は必須です", code: :required}]}

      String.length(name) > 100 ->
        {:error,
         [%ValidationError{field: :name, message: "名前は100文字以内", code: :max_length}]}

      true ->
        {:ok, name}
    end
  end

  @doc """
  エラーをフィールドでグループ化する。

  ## Examples

      iex> errors = [
      ...>   %Chapter04.ValidationError{field: :name, message: "名前は必須", code: :required},
      ...>   %Chapter04.ValidationError{field: :email, message: "無効な形式", code: :format},
      ...>   %Chapter04.ValidationError{field: :name, message: "名前が長すぎる", code: :max_length}
      ...> ]
      iex> grouped = Chapter04.group_errors_by_field(errors)
      iex> length(grouped[:name])
      2
  """
  @spec group_errors_by_field([ValidationError.t()]) :: %{atom() => [ValidationError.t()]}
  def group_errors_by_field(errors) do
    Enum.group_by(errors, & &1.field)
  end
end
