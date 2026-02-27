defmodule Chapter08Test do
  use ExUnit.Case
  doctest Chapter08

  alias Chapter08.{
    Result,
    Either,
    Errors,
    Validated,
    Recovery,
    ExceptionBridge,
    UserRegistration,
    Pipeline
  }

  # ============================================================
  # 1. Result 型
  # ============================================================

  describe "Result" do
    test "ok は成功値を作成する" do
      assert Result.ok(42) == {:ok, 42}
    end

    test "error はエラー値を作成する" do
      assert Result.error("oops") == {:error, "oops"}
    end

    test "map は成功値に関数を適用する" do
      assert Result.map({:ok, 10}, &(&1 * 2)) == {:ok, 20}
      assert Result.map({:error, "err"}, &(&1 * 2)) == {:error, "err"}
    end

    test "flat_map は Result をチェインする" do
      divide = fn
        _, 0 -> {:error, "division by zero"}
        a, b -> {:ok, a / b}
      end

      assert Result.flat_map({:ok, 10}, &divide.(&1, 2)) == {:ok, 5.0}
      assert Result.flat_map({:ok, 10}, &divide.(&1, 0)) == {:error, "division by zero"}
      assert Result.flat_map({:error, "err"}, &divide.(&1, 2)) == {:error, "err"}
    end

    test "map_error はエラーに関数を適用する" do
      assert Result.map_error({:error, "err"}, &String.upcase/1) == {:error, "ERR"}
      assert Result.map_error({:ok, 42}, &String.upcase/1) == {:ok, 42}
    end

    test "unwrap_or はデフォルト値を使用する" do
      assert Result.unwrap_or({:ok, 42}, 0) == 42
      assert Result.unwrap_or({:error, "err"}, 0) == 0
    end

    test "unwrap_or_else はエラー時に関数を実行する" do
      assert Result.unwrap_or_else({:ok, 42}, fn _ -> 0 end) == 42
      assert Result.unwrap_or_else({:error, "abc"}, &String.length/1) == 3
    end

    test "ok? と error? は正しく判定する" do
      assert Result.ok?({:ok, 42}) == true
      assert Result.ok?({:error, "err"}) == false
      assert Result.error?({:ok, 42}) == false
      assert Result.error?({:error, "err"}) == true
    end

    test "sequence はすべての Result を結合する" do
      assert Result.sequence([{:ok, 1}, {:ok, 2}, {:ok, 3}]) == {:ok, [1, 2, 3]}
      assert Result.sequence([{:ok, 1}, {:error, "err"}, {:ok, 3}]) == {:error, "err"}
    end

    test "traverse はリストの各要素に関数を適用して結合する" do
      assert Result.traverse([1, 2, 3], fn x -> {:ok, x * 2} end) == {:ok, [2, 4, 6]}
      
      result = Result.traverse([1, -1, 3], fn x ->
        if x > 0, do: {:ok, x}, else: {:error, "negative"}
      end)
      assert result == {:error, "negative"}
    end
  end

  # ============================================================
  # 2. Either 型
  # ============================================================

  describe "Either" do
    test "left と right は値を作成する" do
      assert Either.left("error") == {:left, "error"}
      assert Either.right(42) == {:right, 42}
    end

    test "map は Right に関数を適用する" do
      assert Either.map({:right, 10}, &(&1 * 2)) == {:right, 20}
      assert Either.map({:left, "err"}, &(&1 * 2)) == {:left, "err"}
    end

    test "flat_map は Either をチェインする" do
      assert Either.flat_map({:right, 10}, fn x -> {:right, x * 2} end) == {:right, 20}
      assert Either.flat_map({:left, "err"}, fn x -> {:right, x * 2} end) == {:left, "err"}
    end

    test "map_left は Left に関数を適用する" do
      assert Either.map_left({:left, "err"}, &String.upcase/1) == {:left, "ERR"}
      assert Either.map_left({:right, 42}, &String.upcase/1) == {:right, 42}
    end

    test "fold は両方のケースを処理する" do
      left_fn = fn e -> "error: #{e}" end
      right_fn = fn v -> "value: #{v}" end

      assert Either.fold({:left, "oops"}, left_fn, right_fn) == "error: oops"
      assert Either.fold({:right, 42}, left_fn, right_fn) == "value: 42"
    end
  end

  # ============================================================
  # 3. エラードメインモデリング
  # ============================================================

  describe "Errors" do
    test "format はエラーを人間が読める形式に変換する" do
      assert Errors.format({:required_field, "name"}) == "フィールド 'name' は必須です"
      assert Errors.format({:invalid_format, "email", "user@domain.com"}) =~ "形式が不正"
      assert Errors.format({:out_of_range, "age", 0, 120}) =~ "0 から 120"
      assert Errors.format({:insufficient_funds, 100, 50}) =~ "残高不足"
      assert Errors.format({:item_not_found, "123"}) =~ "見つかりません"
      assert Errors.format({:duplicate_entry, "user1"}) =~ "既に存在"
      assert Errors.format({:unauthorized, "delete"}) =~ "権限がありません"
      assert Errors.format({:unknown, "something"}) =~ "不明なエラー"
    end
  end

  # ============================================================
  # 4. Validated パターン
  # ============================================================

  describe "Validated" do
    test "valid と invalid は値を作成する" do
      assert Validated.valid(42) == {:valid, 42}
      assert Validated.invalid("error") == {:invalid, ["error"]}
      assert Validated.invalid_all(["e1", "e2"]) == {:invalid, ["e1", "e2"]}
    end

    test "map は有効値に関数を適用する" do
      assert Validated.map({:valid, 10}, &(&1 * 2)) == {:valid, 20}
      assert Validated.map({:invalid, ["err"]}, &(&1 * 2)) == {:invalid, ["err"]}
    end

    test "combine はエラーを蓄積する" do
      assert Validated.combine({:valid, 1}, {:valid, 2}, &+/2) == {:valid, 3}
      assert Validated.combine({:invalid, ["e1"]}, {:valid, 2}, &+/2) == {:invalid, ["e1"]}
      assert Validated.combine({:valid, 1}, {:invalid, ["e2"]}, &+/2) == {:invalid, ["e2"]}
      assert Validated.combine({:invalid, ["e1"]}, {:invalid, ["e2"]}, &+/2) == {:invalid, ["e1", "e2"]}
    end

    test "sequence はすべての Validated を結合しエラーを蓄積する" do
      assert Validated.sequence([{:valid, 1}, {:valid, 2}, {:valid, 3}]) == {:valid, [1, 2, 3]}
      
      result = Validated.sequence([{:valid, 1}, {:invalid, ["e1"]}, {:invalid, ["e2"]}])
      assert {:invalid, errors} = result
      assert "e1" in errors
      assert "e2" in errors
    end
  end

  # ============================================================
  # 5. エラー復旧パターン
  # ============================================================

  describe "Recovery" do
    test "recover はエラー時にデフォルト値で復旧する" do
      assert Recovery.recover({:ok, 42}, fn _ -> 0 end) == {:ok, 42}
      assert Recovery.recover({:error, "err"}, fn _ -> 0 end) == {:ok, 0}
    end

    test "recover_with はエラー時に別の Result で復旧する" do
      assert Recovery.recover_with({:ok, 42}, fn _ -> {:ok, 0} end) == {:ok, 42}
      assert Recovery.recover_with({:error, "err"}, fn _ -> {:ok, 0} end) == {:ok, 0}
      assert Recovery.recover_with({:error, "err"}, fn _ -> {:error, "still error"} end) == {:error, "still error"}
    end

    test "retry はリトライ可能なエラーの場合にリトライする" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      operation = fn ->
        count = Agent.get_and_update(agent, fn n -> {n + 1, n + 1} end)
        if count < 3, do: {:error, :retry}, else: {:ok, "success"}
      end

      should_retry = fn
        {:error, :retry} -> true
        _ -> false
      end

      result = Recovery.retry(operation, 5, should_retry)
      assert result == {:ok, "success"}
      assert Agent.get(agent, & &1) == 3

      Agent.stop(agent)
    end

    test "retry は最大試行回数を超えるとエラーを返す" do
      operation = fn -> {:error, :always_fail} end
      should_retry = fn _ -> true end

      result = Recovery.retry(operation, 3, should_retry)
      assert result == {:error, :always_fail}
    end

    test "fallback_chain は最初の成功を返す" do
      operations = [
        fn -> {:error, "first failed"} end,
        fn -> {:error, "second failed"} end,
        fn -> {:ok, "third succeeded"} end
      ]

      assert Recovery.fallback_chain(operations) == {:ok, "third succeeded"}
    end

    test "fallback_chain はすべて失敗するとエラーを返す" do
      operations = [
        fn -> {:error, "first failed"} end,
        fn -> {:error, "second failed"} end
      ]

      assert {:error, "all fallbacks failed"} = Recovery.fallback_chain(operations)
    end
  end

  # ============================================================
  # 6. 例外と Result の変換
  # ============================================================

  describe "ExceptionBridge" do
    test "try_result は成功を Result に変換する" do
      assert ExceptionBridge.try_result(fn -> 1 + 1 end) == {:ok, 2}
    end

    test "try_result は例外を Result に変換する" do
      result = ExceptionBridge.try_result(fn -> raise "oops" end)
      assert {:error, %RuntimeError{message: "oops"}} = result
    end

    test "unwrap! は成功値を取り出す" do
      assert ExceptionBridge.unwrap!({:ok, 42}) == 42
    end

    test "unwrap! はエラー時に例外を発生させる" do
      assert_raise RuntimeError, fn ->
        ExceptionBridge.unwrap!({:error, "failed"})
      end
    end

    test "map_exception は例外を特定のエラー型に変換する" do
      result = ExceptionBridge.map_exception(
        fn -> raise ArgumentError, "bad arg" end,
        fn
          %ArgumentError{} -> {:error, :invalid_argument}
          _ -> {:error, :unknown}
        end
      )

      assert result == {:error, :invalid_argument}
    end
  end

  # ============================================================
  # 7. ユーザー登録
  # ============================================================

  describe "UserRegistration" do
    test "validate_username は有効なユーザー名を検証する" do
      assert UserRegistration.validate_username("alice") == {:valid, "alice"}
    end

    test "validate_username は空のユーザー名を拒否する" do
      assert UserRegistration.validate_username("") == {:invalid, [{:required_field, "username"}]}
    end

    test "validate_username は短すぎるユーザー名を拒否する" do
      assert UserRegistration.validate_username("ab") == {:invalid, [{:out_of_range, "username", 3, 20}]}
    end

    test "validate_email は有効なメールを検証する" do
      assert UserRegistration.validate_email("test@example.com") == {:valid, "test@example.com"}
    end

    test "validate_email は空のメールを拒否する" do
      assert UserRegistration.validate_email("") == {:invalid, [{:required_field, "email"}]}
    end

    test "validate_email は不正な形式を拒否する" do
      assert UserRegistration.validate_email("invalid") == {:invalid, [{:invalid_format, "email", "user@domain.com"}]}
    end

    test "validate_age は有効な年齢を検証する" do
      assert UserRegistration.validate_age(25) == {:valid, 25}
      assert UserRegistration.validate_age(18) == {:valid, 18}
      assert UserRegistration.validate_age(120) == {:valid, 120}
    end

    test "validate_age は範囲外の年齢を拒否する" do
      assert UserRegistration.validate_age(10) == {:invalid, [{:out_of_range, "age", 18, 120}]}
      assert UserRegistration.validate_age(150) == {:invalid, [{:out_of_range, "age", 18, 120}]}
    end

    test "validate_user は有効なユーザーを検証する" do
      result = UserRegistration.validate_user("alice", "alice@example.com", 25)
      assert {:valid, user} = result
      assert user.username == "alice"
      assert user.email == "alice@example.com"
      assert user.age == 25
    end

    test "validate_user はすべてのエラーを蓄積する" do
      result = UserRegistration.validate_user("", "invalid", 10)
      assert {:invalid, errors} = result
      assert length(errors) == 3
    end

    test "register は有効なユーザーを登録する" do
      check_exists = fn _ -> false end
      result = UserRegistration.register("bob", "bob@example.com", 30, check_exists)
      assert {:ok, user} = result
      assert user.username == "bob"
    end

    test "register は重複ユーザーを拒否する" do
      check_exists = fn "existing" -> true; _ -> false end
      result = UserRegistration.register("existing", "existing@example.com", 30, check_exists)
      assert {:error, [{:duplicate_entry, "existing"}]} = result
    end

    test "register は検証エラーを返す" do
      check_exists = fn _ -> false end
      result = UserRegistration.register("", "invalid", 10, check_exists)
      assert {:error, errors} = result
      assert length(errors) == 3
    end
  end

  # ============================================================
  # 8. パイプライン
  # ============================================================

  describe "Pipeline" do
    test "pipe は複数の関数をチェインする" do
      result = Pipeline.pipe({:ok, 10}, [
        &({:ok, &1 * 2}),
        &({:ok, &1 + 5})
      ])
      assert result == {:ok, 25}
    end

    test "pipe はエラーで停止する" do
      result = Pipeline.pipe({:ok, 10}, [
        fn _ -> {:error, "failed"} end,
        &({:ok, &1 + 5})
      ])
      assert result == {:error, "failed"}
    end

    test "when_ok は条件付きでステップを実行する" do
      assert Pipeline.when_ok({:ok, 10}, fn x -> x > 5 end, &({:ok, &1 * 2})) == {:ok, 20}
      assert Pipeline.when_ok({:ok, 3}, fn x -> x > 5 end, &({:ok, &1 * 2})) == {:ok, 3}
      assert Pipeline.when_ok({:error, "err"}, fn _ -> true end, &({:ok, &1})) == {:error, "err"}
    end

    test "tap_ok は副作用を実行しつつ値を通過させる" do
      result = Pipeline.tap_ok({:ok, 42}, fn x -> send(self(), {:tapped, x}) end)
      assert result == {:ok, 42}
      assert_receive {:tapped, 42}
    end

    test "tap_ok はエラーを通過させる" do
      result = Pipeline.tap_ok({:error, "err"}, fn _ -> send(self(), :should_not_receive) end)
      assert result == {:error, "err"}
      refute_receive :should_not_receive
    end
  end
end
