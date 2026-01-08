defmodule Chapter04Test do
  use ExUnit.Case
  doctest Chapter04

  alias Chapter04.{Validated, User, Email, PositiveInteger, NonEmptyString, Order, ValidationError}

  # ============================================================
  # 1. 基本的なバリデーション
  # ============================================================

  describe "基本的なバリデーション" do
    test "validate_name は有効な名前を受け入れる" do
      assert {:ok, "田中太郎"} = Chapter04.validate_name("田中太郎")
    end

    test "validate_name は空の名前を拒否する" do
      assert {:error, ["名前は空にできません"]} = Chapter04.validate_name("")
    end

    test "validate_name は長すぎる名前を拒否する" do
      long_name = String.duplicate("あ", 101)
      assert {:error, ["名前は100文字以内である必要があります"]} = Chapter04.validate_name(long_name)
    end

    test "validate_age は有効な年齢を受け入れる" do
      assert {:ok, 25} = Chapter04.validate_age(25)
      assert {:ok, 0} = Chapter04.validate_age(0)
      assert {:ok, 150} = Chapter04.validate_age(150)
    end

    test "validate_age は負の年齢を拒否する" do
      assert {:error, ["年齢は0以上である必要があります"]} = Chapter04.validate_age(-1)
    end

    test "validate_age は大きすぎる年齢を拒否する" do
      assert {:error, ["年齢は150以下である必要があります"]} = Chapter04.validate_age(151)
    end

    test "validate_email は有効なメールを受け入れる" do
      assert {:ok, "test@example.com"} = Chapter04.validate_email("test@example.com")
    end

    test "validate_email は無効なメールを拒否する" do
      assert {:error, ["無効なメールアドレス形式です"]} = Chapter04.validate_email("invalid")
      assert {:error, _} = Chapter04.validate_email("@example.com")
    end
  end

  # ============================================================
  # 2. 列挙型とスマートコンストラクタ
  # ============================================================

  describe "列挙型パース" do
    test "parse_membership は有効な会員種別を解析する" do
      assert {:ok, :bronze} = Chapter04.parse_membership("bronze")
      assert {:ok, :silver} = Chapter04.parse_membership("SILVER")
      assert {:ok, :gold} = Chapter04.parse_membership("Gold")
      assert {:ok, :platinum} = Chapter04.parse_membership("platinum")
    end

    test "parse_membership は無効な会員種別を拒否する" do
      assert {:error, ["無効な会員種別: invalid"]} = Chapter04.parse_membership("invalid")
    end

    test "parse_status は有効なステータスを解析する" do
      assert {:ok, :active} = Chapter04.parse_status("active")
      assert {:ok, :inactive} = Chapter04.parse_status("inactive")
      assert {:ok, :suspended} = Chapter04.parse_status("suspended")
    end

    test "parse_status は無効なステータスを拒否する" do
      assert {:error, _} = Chapter04.parse_status("unknown")
    end
  end

  # ============================================================
  # 3. Validated パターン
  # ============================================================

  describe "Validated" do
    test "valid は有効な値を作成する" do
      assert {:valid, 42} = Validated.valid(42)
    end

    test "invalid は無効な値を作成する" do
      assert {:invalid, ["エラー"]} = Validated.invalid(["エラー"])
    end

    test "map は有効な値を変換する" do
      result = Validated.valid(5) |> Validated.map(&(&1 * 2))
      assert {:valid, 10} = result
    end

    test "map は無効な値をそのまま返す" do
      result = Validated.invalid(["エラー"]) |> Validated.map(&(&1 * 2))
      assert {:invalid, ["エラー"]} = result
    end

    test "combine は2つの有効な値を結合する" do
      result = Validated.combine({:valid, 5}, {:valid, 3}, &+/2)
      assert {:valid, 8} = result
    end

    test "combine はエラーを蓄積する" do
      result = Validated.combine({:invalid, ["エラー1"]}, {:invalid, ["エラー2"]}, &+/2)
      assert {:invalid, ["エラー1", "エラー2"]} = result
    end

    test "combine3 は3つの有効な値を結合する" do
      result =
        Validated.combine3(
          {:valid, 1},
          {:valid, 2},
          {:valid, 3},
          fn a, b, c -> a + b + c end
        )

      assert {:valid, 6} = result
    end

    test "combine3 はすべてのエラーを蓄積する" do
      result =
        Validated.combine3(
          {:invalid, ["エラー1"]},
          {:valid, 2},
          {:invalid, ["エラー3"]},
          fn a, b, c -> a + b + c end
        )

      assert {:invalid, errors} = result
      assert "エラー1" in errors
      assert "エラー3" in errors
    end

    test "from_result と to_result は相互変換できる" do
      assert {:valid, 42} = Validated.from_result({:ok, 42})
      assert {:invalid, ["エラー"]} = Validated.from_result({:error, ["エラー"]})
      assert {:ok, 42} = Validated.to_result({:valid, 42})
      assert {:error, ["エラー"]} = Validated.to_result({:invalid, ["エラー"]})
    end
  end

  # ============================================================
  # 4. ユーザーバリデーション
  # ============================================================

  describe "ユーザーバリデーション" do
    test "validate_user_with は有効なユーザーを作成する" do
      params = %{name: "田中", age: 25, email: "tanaka@example.com"}
      assert {:ok, %User{name: "田中", age: 25}} = Chapter04.validate_user_with(params)
    end

    test "validate_user_with は最初のエラーで停止する" do
      params = %{name: "", age: -1, email: "invalid"}
      assert {:error, ["名前は空にできません"]} = Chapter04.validate_user_with(params)
    end

    test "validate_user_accumulate は有効なユーザーを作成する" do
      params = %{name: "田中", age: 25, email: "tanaka@example.com"}
      result = Chapter04.validate_user_accumulate(params)
      assert Validated.valid?(result)
    end

    test "validate_user_accumulate はすべてのエラーを蓄積する" do
      params = %{name: "", age: -1, email: "invalid"}
      result = Chapter04.validate_user_accumulate(params)

      assert {:invalid, errors} = result
      assert length(errors) == 3
    end
  end

  # ============================================================
  # 5. バリデータの合成
  # ============================================================

  describe "バリデータの合成" do
    test "validator は述語からバリデータを作成する" do
      is_positive = Chapter04.validator(fn x -> x > 0 end, "正の数が必要")

      assert {:ok, 5} = is_positive.(5)
      assert {:error, ["正の数が必要"]} = is_positive.(-1)
    end

    test "validate_all は順次バリデートする" do
      validators = [
        Chapter04.validator(fn x -> x > 0 end, "正の数が必要"),
        Chapter04.validator(fn x -> x < 100 end, "100未満が必要")
      ]

      assert {:ok, 50} = Chapter04.validate_all(50, validators)
      assert {:error, ["正の数が必要"]} = Chapter04.validate_all(-1, validators)
    end

    test "validate_all_accumulate はすべてのエラーを蓄積する" do
      validators = [
        Chapter04.validator(fn x -> x > 0 end, "正の数が必要"),
        Chapter04.validator(fn x -> x < 100 end, "100未満が必要")
      ]

      assert {:valid, 50} = Chapter04.validate_all_accumulate(50, validators)
      # -200 は 100 未満なので、正の数エラーのみ
      assert {:invalid, ["正の数が必要"]} = Chapter04.validate_all_accumulate(-200, validators)
      # 200 は正の数だが 100 以上なので、100未満エラーのみ
      assert {:invalid, ["100未満が必要"]} = Chapter04.validate_all_accumulate(200, validators)
      # 両方のエラーをテストするには、異なる条件のバリデータを使用
      both_fail_validators = [
        Chapter04.validator(fn x -> x < 0 end, "負の数が必要"),
        Chapter04.validator(fn x -> x > 100 end, "100より大きい数が必要")
      ]
      assert {:invalid, errors} = Chapter04.validate_all_accumulate(50, both_fail_validators)
      assert length(errors) == 2
    end
  end

  # ============================================================
  # 6. 値オブジェクト
  # ============================================================

  describe "Email 値オブジェクト" do
    test "有効なメールアドレスで作成できる" do
      assert {:ok, %Email{value: "test@example.com"}} = Email.new("test@example.com")
    end

    test "無効なメールアドレスでは作成できない" do
      assert {:error, _} = Email.new("invalid")
    end

    test "to_string で文字列を取得できる" do
      {:ok, email} = Email.new("test@example.com")
      assert "test@example.com" = Email.to_string(email)
    end
  end

  describe "PositiveInteger 値オブジェクト" do
    test "正の整数で作成できる" do
      assert {:ok, %PositiveInteger{value: 42}} = PositiveInteger.new(42)
    end

    test "ゼロでは作成できない" do
      assert {:error, _} = PositiveInteger.new(0)
    end

    test "負の整数では作成できない" do
      assert {:error, _} = PositiveInteger.new(-5)
    end
  end

  describe "NonEmptyString 値オブジェクト" do
    test "空でない文字列で作成できる" do
      assert {:ok, %NonEmptyString{value: "hello"}} = NonEmptyString.new("hello")
    end

    test "空の文字列では作成できない" do
      assert {:error, _} = NonEmptyString.new("")
    end
  end

  # ============================================================
  # 7. 複合バリデーション
  # ============================================================

  describe "注文バリデーション" do
    test "有効な注文を作成できる" do
      params = %{items: ["item1", "item2"], customer_email: "test@example.com", quantity: 5}
      assert {:ok, %Order{quantity: 5}} = Chapter04.validate_order(params)
    end

    test "空のアイテムリストを拒否する" do
      params = %{items: [], customer_email: "test@example.com", quantity: 5}
      assert {:error, errors} = Chapter04.validate_order(params)
      assert Enum.any?(errors, &String.contains?(&1, "アイテム"))
    end

    test "複数のエラーを蓄積する" do
      params = %{items: [], customer_email: "invalid", quantity: 0}
      assert {:error, errors} = Chapter04.validate_order(params)
      assert length(errors) >= 2
    end
  end

  # ============================================================
  # 8. カスタムエラー型
  # ============================================================

  describe "カスタムエラー型" do
    test "validate_name_typed は構造化されたエラーを返す" do
      assert {:error, [%ValidationError{field: :name, code: :required}]} =
               Chapter04.validate_name_typed("")
    end

    test "group_errors_by_field はエラーをフィールドでグループ化する" do
      errors = [
        %ValidationError{field: :name, message: "エラー1", code: :required},
        %ValidationError{field: :email, message: "エラー2", code: :format},
        %ValidationError{field: :name, message: "エラー3", code: :max_length}
      ]

      grouped = Chapter04.group_errors_by_field(errors)

      assert length(grouped[:name]) == 2
      assert length(grouped[:email]) == 1
    end
  end
end
