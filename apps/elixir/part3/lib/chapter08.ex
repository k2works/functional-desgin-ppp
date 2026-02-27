defmodule Chapter08 do
  @moduledoc """
  # Chapter 08: Error Handling Strategies

  このモジュールでは、関数型プログラミングにおけるエラーハンドリング戦略を学びます。
  Elixir では、例外よりも戻り値による明示的なエラー処理が推奨されます。

  ## 主なトピック

  1. Result 型（{:ok, value} | {:error, reason}）
  2. Either パターン
  3. エラーの伝播と合成
  4. 例外 vs 戻り値
  5. 復旧可能/不可能なエラー
  6. エラードメインモデリング
  """

  # ============================================================
  # 1. Result 型の基本
  # ============================================================

  defmodule Result do
    @moduledoc """
    Result 型の操作を提供するユーティリティモジュール。
    """

    @type t(a, e) :: {:ok, a} | {:error, e}
    @type t(a) :: t(a, any())

    @doc """
    成功値を作成する。

    ## Examples

        iex> Chapter08.Result.ok(42)
        {:ok, 42}
    """
    @spec ok(a) :: t(a) when a: any()
    def ok(value), do: {:ok, value}

    @doc """
    エラー値を作成する。

    ## Examples

        iex> Chapter08.Result.error("something went wrong")
        {:error, "something went wrong"}
    """
    @spec error(e) :: t(any(), e) when e: any()
    def error(reason), do: {:error, reason}

    @doc """
    Result に関数を適用する（map）。

    ## Examples

        iex> Chapter08.Result.map({:ok, 10}, &(&1 * 2))
        {:ok, 20}
        iex> Chapter08.Result.map({:error, "err"}, &(&1 * 2))
        {:error, "err"}
    """
    @spec map(t(a, e), (a -> b)) :: t(b, e) when a: any(), b: any(), e: any()
    def map({:ok, value}, f), do: {:ok, f.(value)}
    def map({:error, _} = err, _f), do: err

    @doc """
    Result をフラットマップする（flatMap/bind）。

    ## Examples

        iex> Chapter08.Result.flat_map({:ok, 10}, fn x ->
        ...>   if x > 0, do: {:ok, x * 2}, else: {:error, "not positive"}
        ...> end)
        {:ok, 20}
        iex> Chapter08.Result.flat_map({:error, "err"}, fn x -> {:ok, x} end)
        {:error, "err"}
    """
    @spec flat_map(t(a, e), (a -> t(b, e))) :: t(b, e) when a: any(), b: any(), e: any()
    def flat_map({:ok, value}, f), do: f.(value)
    def flat_map({:error, _} = err, _f), do: err

    @doc """
    エラーに関数を適用する（map_error）。

    ## Examples

        iex> Chapter08.Result.map_error({:error, "err"}, &String.upcase/1)
        {:error, "ERR"}
        iex> Chapter08.Result.map_error({:ok, 42}, &String.upcase/1)
        {:ok, 42}
    """
    @spec map_error(t(a, e1), (e1 -> e2)) :: t(a, e2) when a: any(), e1: any(), e2: any()
    def map_error({:ok, _} = ok, _f), do: ok
    def map_error({:error, reason}, f), do: {:error, f.(reason)}

    @doc """
    Result から値を取り出す（デフォルト値付き）。

    ## Examples

        iex> Chapter08.Result.unwrap_or({:ok, 42}, 0)
        42
        iex> Chapter08.Result.unwrap_or({:error, "err"}, 0)
        0
    """
    @spec unwrap_or(t(a, any()), a) :: a when a: any()
    def unwrap_or({:ok, value}, _default), do: value
    def unwrap_or({:error, _}, default), do: default

    @doc """
    Result から値を取り出す（エラー時は関数を実行）。

    ## Examples

        iex> Chapter08.Result.unwrap_or_else({:ok, 42}, fn _ -> 0 end)
        42
        iex> Chapter08.Result.unwrap_or_else({:error, "err"}, fn e -> String.length(e) end)
        3
    """
    @spec unwrap_or_else(t(a, e), (e -> a)) :: a when a: any(), e: any()
    def unwrap_or_else({:ok, value}, _f), do: value
    def unwrap_or_else({:error, reason}, f), do: f.(reason)

    @doc """
    成功かどうかを判定する。

    ## Examples

        iex> Chapter08.Result.ok?({:ok, 42})
        true
        iex> Chapter08.Result.ok?({:error, "err"})
        false
    """
    @spec ok?(t(any(), any())) :: boolean()
    def ok?({:ok, _}), do: true
    def ok?({:error, _}), do: false

    @doc """
    エラーかどうかを判定する。

    ## Examples

        iex> Chapter08.Result.error?({:ok, 42})
        false
        iex> Chapter08.Result.error?({:error, "err"})
        true
    """
    @spec error?(t(any(), any())) :: boolean()
    def error?({:ok, _}), do: false
    def error?({:error, _}), do: true

    @doc """
    複数の Result を結合する（すべて成功した場合のみ成功）。

    ## Examples

        iex> Chapter08.Result.sequence([{:ok, 1}, {:ok, 2}, {:ok, 3}])
        {:ok, [1, 2, 3]}
        iex> Chapter08.Result.sequence([{:ok, 1}, {:error, "err"}, {:ok, 3}])
        {:error, "err"}
    """
    @spec sequence([t(a, e)]) :: t([a], e) when a: any(), e: any()
    def sequence(results) do
      Enum.reduce_while(results, {:ok, []}, fn
        {:ok, value}, {:ok, acc} -> {:cont, {:ok, [value | acc]}}
        {:error, _} = err, _ -> {:halt, err}
      end)
      |> map(&Enum.reverse/1)
    end

    @doc """
    リストの各要素に関数を適用し、結果を結合する。

    ## Examples

        iex> Chapter08.Result.traverse([1, 2, 3], fn x -> {:ok, x * 2} end)
        {:ok, [2, 4, 6]}
        iex> Chapter08.Result.traverse([1, -1, 3], fn x ->
        ...>   if x > 0, do: {:ok, x}, else: {:error, "negative"}
        ...> end)
        {:error, "negative"}
    """
    @spec traverse([a], (a -> t(b, e))) :: t([b], e) when a: any(), b: any(), e: any()
    def traverse(list, f) do
      list
      |> Enum.map(f)
      |> sequence()
    end
  end

  # ============================================================
  # 2. Either パターン
  # ============================================================

  defmodule Either do
    @moduledoc """
    Either 型：2つの可能性を表現する。
    Left は通常エラーを、Right は成功を表す。
    """

    @type t(l, r) :: {:left, l} | {:right, r}

    @doc """
    Left 値を作成する。

    ## Examples

        iex> Chapter08.Either.left("error")
        {:left, "error"}
    """
    @spec left(l) :: t(l, any()) when l: any()
    def left(value), do: {:left, value}

    @doc """
    Right 値を作成する。

    ## Examples

        iex> Chapter08.Either.right(42)
        {:right, 42}
    """
    @spec right(r) :: t(any(), r) when r: any()
    def right(value), do: {:right, value}

    @doc """
    Either に関数を適用する（Right のみ）。

    ## Examples

        iex> Chapter08.Either.map({:right, 10}, &(&1 * 2))
        {:right, 20}
        iex> Chapter08.Either.map({:left, "err"}, &(&1 * 2))
        {:left, "err"}
    """
    @spec map(t(l, r1), (r1 -> r2)) :: t(l, r2) when l: any(), r1: any(), r2: any()
    def map({:right, value}, f), do: {:right, f.(value)}
    def map({:left, _} = left, _f), do: left

    @doc """
    Either をフラットマップする。

    ## Examples

        iex> Chapter08.Either.flat_map({:right, 10}, fn x ->
        ...>   if x > 0, do: {:right, x * 2}, else: {:left, "not positive"}
        ...> end)
        {:right, 20}
    """
    @spec flat_map(t(l, r1), (r1 -> t(l, r2))) :: t(l, r2) when l: any(), r1: any(), r2: any()
    def flat_map({:right, value}, f), do: f.(value)
    def flat_map({:left, _} = left, _f), do: left

    @doc """
    Left に関数を適用する。

    ## Examples

        iex> Chapter08.Either.map_left({:left, "err"}, &String.upcase/1)
        {:left, "ERR"}
        iex> Chapter08.Either.map_left({:right, 42}, &String.upcase/1)
        {:right, 42}
    """
    @spec map_left(t(l1, r), (l1 -> l2)) :: t(l2, r) when l1: any(), l2: any(), r: any()
    def map_left({:left, value}, f), do: {:left, f.(value)}
    def map_left({:right, _} = right, _f), do: right

    @doc """
    Either を fold する（両方のケースを処理）。

    ## Examples

        iex> Chapter08.Either.fold({:right, 42}, fn _ -> "error" end, fn x -> "value: \#{x}" end)
        "value: 42"
        iex> Chapter08.Either.fold({:left, "oops"}, fn e -> "error: \#{e}" end, fn _ -> "ok" end)
        "error: oops"
    """
    @spec fold(t(l, r), (l -> a), (r -> a)) :: a when l: any(), r: any(), a: any()
    def fold({:left, value}, left_fn, _right_fn), do: left_fn.(value)
    def fold({:right, value}, _left_fn, right_fn), do: right_fn.(value)
  end

  # ============================================================
  # 3. エラードメインモデリング
  # ============================================================

  defmodule Errors do
    @moduledoc """
    ドメイン固有のエラー型を定義する。
    """

    @type validation_error ::
      {:required_field, String.t()}
      | {:invalid_format, String.t(), String.t()}
      | {:out_of_range, String.t(), number(), number()}

    @type business_error ::
      {:insufficient_funds, number(), number()}
      | {:item_not_found, String.t()}
      | {:duplicate_entry, String.t()}
      | {:unauthorized, String.t()}

    @type error :: validation_error() | business_error() | {:unknown, String.t()}

    @doc """
    エラーを人間が読める形式に変換する。

    ## Examples

        iex> Chapter08.Errors.format({:required_field, "name"})
        "フィールド 'name' は必須です"
        iex> Chapter08.Errors.format({:insufficient_funds, 100, 50})
        "残高不足: 必要額 100、残高 50"
    """
    @spec format(error()) :: String.t()
    def format({:required_field, field}) do
      "フィールド '#{field}' は必須です"
    end
    def format({:invalid_format, field, expected}) do
      "フィールド '#{field}' の形式が不正です。期待される形式: #{expected}"
    end
    def format({:out_of_range, field, min, max}) do
      "フィールド '#{field}' は #{min} から #{max} の範囲内である必要があります"
    end
    def format({:insufficient_funds, required, available}) do
      "残高不足: 必要額 #{required}、残高 #{available}"
    end
    def format({:item_not_found, id}) do
      "アイテム '#{id}' が見つかりません"
    end
    def format({:duplicate_entry, id}) do
      "エントリ '#{id}' は既に存在します"
    end
    def format({:unauthorized, action}) do
      "操作 '#{action}' を実行する権限がありません"
    end
    def format({:unknown, message}) do
      "不明なエラー: #{message}"
    end
  end

  # ============================================================
  # 4. Validated パターン（エラー蓄積）
  # ============================================================

  defmodule Validated do
    @moduledoc """
    エラーを蓄積する Validated 型。
    Result と異なり、すべてのエラーを収集する。
    """

    @type t(a, e) :: {:valid, a} | {:invalid, [e]}

    @doc """
    有効な値を作成する。

    ## Examples

        iex> Chapter08.Validated.valid(42)
        {:valid, 42}
    """
    @spec valid(a) :: t(a, any()) when a: any()
    def valid(value), do: {:valid, value}

    @doc """
    無効な値を作成する。

    ## Examples

        iex> Chapter08.Validated.invalid("error")
        {:invalid, ["error"]}
    """
    @spec invalid(e) :: t(any(), e) when e: any()
    def invalid(error), do: {:invalid, [error]}

    @doc """
    複数のエラーで無効な値を作成する。

    ## Examples

        iex> Chapter08.Validated.invalid_all(["error1", "error2"])
        {:invalid, ["error1", "error2"]}
    """
    @spec invalid_all([e]) :: t(any(), e) when e: any()
    def invalid_all(errors), do: {:invalid, errors}

    @doc """
    Validated に関数を適用する。

    ## Examples

        iex> Chapter08.Validated.map({:valid, 10}, &(&1 * 2))
        {:valid, 20}
        iex> Chapter08.Validated.map({:invalid, ["err"]}, &(&1 * 2))
        {:invalid, ["err"]}
    """
    @spec map(t(a, e), (a -> b)) :: t(b, e) when a: any(), b: any(), e: any()
    def map({:valid, value}, f), do: {:valid, f.(value)}
    def map({:invalid, _} = invalid, _f), do: invalid

    @doc """
    2つの Validated を結合する（エラーを蓄積）。

    ## Examples

        iex> Chapter08.Validated.combine({:valid, 1}, {:valid, 2}, &+/2)
        {:valid, 3}
        iex> Chapter08.Validated.combine({:invalid, ["e1"]}, {:invalid, ["e2"]}, &+/2)
        {:invalid, ["e1", "e2"]}
    """
    @spec combine(t(a, e), t(b, e), (a, b -> c)) :: t(c, e) when a: any(), b: any(), c: any(), e: any()
    def combine({:valid, a}, {:valid, b}, f), do: {:valid, f.(a, b)}
    def combine({:valid, _}, {:invalid, errors}, _f), do: {:invalid, errors}
    def combine({:invalid, errors}, {:valid, _}, _f), do: {:invalid, errors}
    def combine({:invalid, e1}, {:invalid, e2}, _f), do: {:invalid, e1 ++ e2}

    @doc """
    複数の Validated を結合する。

    ## Examples

        iex> Chapter08.Validated.sequence([{:valid, 1}, {:valid, 2}, {:valid, 3}])
        {:valid, [1, 2, 3]}
        iex> Chapter08.Validated.sequence([{:valid, 1}, {:invalid, ["e1"]}, {:invalid, ["e2"]}])
        {:invalid, ["e1", "e2"]}
    """
    @spec sequence([t(a, e)]) :: t([a], e) when a: any(), e: any()
    def sequence(validations) do
      Enum.reduce(validations, {:valid, []}, fn
        {:valid, value}, {:valid, acc} -> {:valid, [value | acc]}
        {:invalid, errors}, {:valid, _} -> {:invalid, errors}
        {:valid, _}, {:invalid, errors} -> {:invalid, errors}
        {:invalid, e1}, {:invalid, e2} -> {:invalid, e2 ++ e1}
      end)
      |> map(&Enum.reverse/1)
    end
  end

  # ============================================================
  # 5. エラー復旧パターン
  # ============================================================

  defmodule Recovery do
    @moduledoc """
    エラーからの復旧パターン。
    """

    alias Chapter08.Result

    @doc """
    エラー時にデフォルト値で復旧する。

    ## Examples

        iex> Chapter08.Recovery.recover({:error, "err"}, fn _ -> 0 end)
        {:ok, 0}
        iex> Chapter08.Recovery.recover({:ok, 42}, fn _ -> 0 end)
        {:ok, 42}
    """
    @spec recover(Result.t(a, e), (e -> a)) :: Result.t(a, e) when a: any(), e: any()
    def recover({:ok, _} = ok, _f), do: ok
    def recover({:error, reason}, f), do: {:ok, f.(reason)}

    @doc """
    エラー時に別の Result で復旧する。

    ## Examples

        iex> Chapter08.Recovery.recover_with({:error, "err"}, fn _ -> {:ok, 0} end)
        {:ok, 0}
        iex> Chapter08.Recovery.recover_with({:ok, 42}, fn _ -> {:ok, 0} end)
        {:ok, 42}
    """
    @spec recover_with(Result.t(a, e1), (e1 -> Result.t(a, e2))) :: Result.t(a, e2) when a: any(), e1: any(), e2: any()
    def recover_with({:ok, _} = ok, _f), do: ok
    def recover_with({:error, reason}, f), do: f.(reason)

    @doc """
    リトライ可能なエラーの場合にリトライする。

    ## Examples

        iex> attempts = Agent.start_link(fn -> 0 end) |> elem(1)
        iex> operation = fn ->
        ...>   count = Agent.get_and_update(attempts, fn n -> {n + 1, n + 1} end)
        ...>   if count < 3, do: {:error, :retry}, else: {:ok, "success"}
        ...> end
        iex> result = Chapter08.Recovery.retry(operation, 5, fn {:error, :retry} -> true; _ -> false end)
        iex> result
        {:ok, "success"}
    """
    @spec retry((() -> Result.t(a, e)), pos_integer(), (Result.t(a, e) -> boolean())) :: Result.t(a, e)
      when a: any(), e: any()
    def retry(operation, max_attempts, should_retry) do
      do_retry(operation, max_attempts, should_retry, 1)
    end

    defp do_retry(operation, max_attempts, should_retry, attempt) do
      result = operation.()

      cond do
        Result.ok?(result) ->
          result
        attempt >= max_attempts ->
          result
        should_retry.(result) ->
          do_retry(operation, max_attempts, should_retry, attempt + 1)
        true ->
          result
      end
    end

    @doc """
    フォールバックのチェーンを試行する。

    ## Examples

        iex> operations = [
        ...>   fn -> {:error, "first failed"} end,
        ...>   fn -> {:error, "second failed"} end,
        ...>   fn -> {:ok, "third succeeded"} end
        ...> ]
        iex> Chapter08.Recovery.fallback_chain(operations)
        {:ok, "third succeeded"}
    """
    @spec fallback_chain([(() -> Result.t(a, e))]) :: Result.t(a, e) when a: any(), e: any()
    def fallback_chain([]), do: {:error, "all fallbacks failed"}
    def fallback_chain([operation | rest]) do
      case operation.() do
        {:ok, _} = ok -> ok
        {:error, _} -> fallback_chain(rest)
      end
    end
  end

  # ============================================================
  # 6. 例外と Result の変換
  # ============================================================

  defmodule ExceptionBridge do
    @moduledoc """
    例外と Result 型の間を橋渡しする。
    """

    alias Chapter08.Result

    @doc """
    例外を Result に変換する。

    ## Examples

        iex> Chapter08.ExceptionBridge.try_result(fn -> 1 + 1 end)
        {:ok, 2}
        iex> Chapter08.ExceptionBridge.try_result(fn -> raise "oops" end)
        {:error, %RuntimeError{message: "oops"}}
    """
    @spec try_result((() -> a)) :: Result.t(a, Exception.t()) when a: any()
    def try_result(f) do
      {:ok, f.()}
    rescue
      e -> {:error, e}
    end

    @doc """
    Result を例外に変換する（エラーの場合）。

    ## Examples

        iex> Chapter08.ExceptionBridge.unwrap!({:ok, 42})
        42
    """
    @spec unwrap!(Result.t(a, any())) :: a when a: any()
    def unwrap!({:ok, value}), do: value
    def unwrap!({:error, reason}) when is_exception(reason), do: raise reason
    def unwrap!({:error, reason}), do: raise "Unwrap failed: #{inspect(reason)}"

    @doc """
    例外を特定のエラー型に変換する。

    ## Examples

        iex> Chapter08.ExceptionBridge.map_exception(fn -> raise ArgumentError, "bad arg" end, fn
        ...>   %ArgumentError{} -> {:error, :invalid_argument}
        ...>   _ -> {:error, :unknown}
        ...> end)
        {:error, :invalid_argument}
    """
    @spec map_exception((() -> a), (Exception.t() -> Result.t(a, e))) :: Result.t(a, e) when a: any(), e: any()
    def map_exception(f, mapper) do
      {:ok, f.()}
    rescue
      e -> mapper.(e)
    end
  end

  # ============================================================
  # 7. 実践例：ユーザー登録
  # ============================================================

  defmodule UserRegistration do
    @moduledoc """
    ユーザー登録のエラーハンドリング例。
    """

    alias Chapter08.{Result, Validated, Errors}

    @type user :: %{
      username: String.t(),
      email: String.t(),
      age: pos_integer()
    }

    @doc """
    ユーザー名を検証する。

    ## Examples

        iex> Chapter08.UserRegistration.validate_username("alice")
        {:valid, "alice"}
        iex> Chapter08.UserRegistration.validate_username("")
        {:invalid, [{:required_field, "username"}]}
        iex> Chapter08.UserRegistration.validate_username("ab")
        {:invalid, [{:out_of_range, "username", 3, 20}]}
    """
    @spec validate_username(String.t()) :: Validated.t(String.t(), Errors.error())
    def validate_username(""), do: Validated.invalid({:required_field, "username"})
    def validate_username(username) do
      len = String.length(username)
      if len >= 3 and len <= 20 do
        Validated.valid(username)
      else
        Validated.invalid({:out_of_range, "username", 3, 20})
      end
    end

    @doc """
    メールアドレスを検証する。

    ## Examples

        iex> Chapter08.UserRegistration.validate_email("test@example.com")
        {:valid, "test@example.com"}
        iex> Chapter08.UserRegistration.validate_email("")
        {:invalid, [{:required_field, "email"}]}
        iex> Chapter08.UserRegistration.validate_email("invalid")
        {:invalid, [{:invalid_format, "email", "user@domain.com"}]}
    """
    @spec validate_email(String.t()) :: Validated.t(String.t(), Errors.error())
    def validate_email(""), do: Validated.invalid({:required_field, "email"})
    def validate_email(email) do
      if String.contains?(email, "@") and String.contains?(email, ".") do
        Validated.valid(email)
      else
        Validated.invalid({:invalid_format, "email", "user@domain.com"})
      end
    end

    @doc """
    年齢を検証する。

    ## Examples

        iex> Chapter08.UserRegistration.validate_age(25)
        {:valid, 25}
        iex> Chapter08.UserRegistration.validate_age(10)
        {:invalid, [{:out_of_range, "age", 18, 120}]}
    """
    @spec validate_age(integer()) :: Validated.t(pos_integer(), Errors.error())
    def validate_age(age) when age >= 18 and age <= 120 do
      Validated.valid(age)
    end
    def validate_age(_age) do
      Validated.invalid({:out_of_range, "age", 18, 120})
    end

    @doc """
    ユーザー登録データを検証する（すべてのエラーを蓄積）。

    ## Examples

        iex> Chapter08.UserRegistration.validate_user("alice", "alice@example.com", 25)
        {:valid, %{username: "alice", email: "alice@example.com", age: 25}}
        iex> {:invalid, errors} = Chapter08.UserRegistration.validate_user("", "invalid", 10)
        iex> length(errors)
        3
    """
    @spec validate_user(String.t(), String.t(), integer()) :: Validated.t(user(), Errors.error())
    def validate_user(username, email, age) do
      username_result = validate_username(username)
      email_result = validate_email(email)
      age_result = validate_age(age)

      Validated.sequence([username_result, email_result, age_result])
      |> Validated.map(fn [u, e, a] ->
        %{username: u, email: e, age: a}
      end)
    end

    @doc """
    ユーザー登録を実行する（Result 型で返す）。

    ## Examples

        iex> check_exists = fn _ -> false end
        iex> {:ok, user} = Chapter08.UserRegistration.register("bob", "bob@example.com", 30, check_exists)
        iex> user.username
        "bob"
    """
    @spec register(String.t(), String.t(), integer(), (String.t() -> boolean())) :: Result.t(user(), [Errors.error()])
    def register(username, email, age, check_exists) do
      case validate_user(username, email, age) do
        {:valid, user} ->
          if check_exists.(user.username) do
            {:error, [{:duplicate_entry, username}]}
          else
            {:ok, user}
          end
        {:invalid, errors} ->
          {:error, errors}
      end
    end
  end

  # ============================================================
  # 8. パイプライン with エラーハンドリング
  # ============================================================

  defmodule Pipeline do
    @moduledoc """
    エラーハンドリングを含むパイプライン処理。
    """

    alias Chapter08.Result

    @doc """
    パイプラインを構築するマクロ風関数。

    ## Examples

        iex> Chapter08.Pipeline.pipe({:ok, 10}, [
        ...>   &({:ok, &1 * 2}),
        ...>   &({:ok, &1 + 5})
        ...> ])
        {:ok, 25}
        iex> Chapter08.Pipeline.pipe({:ok, 10}, [
        ...>   fn _ -> {:error, "failed"} end,
        ...>   &({:ok, &1 + 5})
        ...> ])
        {:error, "failed"}
    """
    @spec pipe(Result.t(a, e), [(a -> Result.t(b, e))]) :: Result.t(b, e) when a: any(), b: any(), e: any()
    def pipe(initial, functions) do
      Enum.reduce(functions, initial, fn f, acc ->
        Result.flat_map(acc, f)
      end)
    end

    @doc """
    条件付きでステップを実行する。

    ## Examples

        iex> Chapter08.Pipeline.when_ok({:ok, 10}, fn x -> x > 5 end, &({:ok, &1 * 2}))
        {:ok, 20}
        iex> Chapter08.Pipeline.when_ok({:ok, 3}, fn x -> x > 5 end, &({:ok, &1 * 2}))
        {:ok, 3}
    """
    @spec when_ok(Result.t(a, e), (a -> boolean()), (a -> Result.t(a, e))) :: Result.t(a, e) when a: any(), e: any()
    def when_ok({:ok, value} = ok, condition, f) do
      if condition.(value), do: f.(value), else: ok
    end
    def when_ok({:error, _} = err, _condition, _f), do: err

    @doc """
    副作用を実行しつつ値を通過させる（タップ）。

    ## Examples

        iex> Chapter08.Pipeline.tap_ok({:ok, 42}, fn x -> send(self(), {:tapped, x}) end)
        {:ok, 42}
        iex> receive do
        ...>   {:tapped, 42} -> :received
        ...> after
        ...>   0 -> :not_received
        ...> end
        :received
    """
    @spec tap_ok(Result.t(a, e), (a -> any())) :: Result.t(a, e) when a: any(), e: any()
    def tap_ok({:ok, value} = ok, f) do
      f.(value)
      ok
    end
    def tap_ok({:error, _} = err, _f), do: err
  end
end
