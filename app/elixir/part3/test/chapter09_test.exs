defmodule Chapter09Test do
  use ExUnit.Case
  doctest Chapter09

  alias Chapter09.{
    IO.Console,
    IO.FileSystem,
    Repository,
    Http,
    UserApiClient,
    UserService,
    Config,
    Transaction
  }

  # ============================================================
  # 1. コンソール I/O
  # ============================================================

  describe "IO.Console" do
    test "test_console は入力をシミュレートする" do
      {console, _} = Console.test_console(["input1", "input2", "input3"])

      assert console.read.() == "input1"
      assert console.read.() == "input2"
      assert console.read.() == "input3"
      assert console.read.() == ""  # 入力が尽きた場合
    end

    test "test_console は出力を記録する" do
      {console, get_output} = Console.test_console([])

      console.write.("hello")
      console.write.("world")

      assert get_output.() == ["hello", "world"]
    end

    test "prompt はメッセージを出力して入力を取得する" do
      {console, get_output} = Console.test_console(["Alice"])

      result = Console.prompt(console, "Name: ")

      assert result == "Alice"
      assert get_output.() == ["Name: "]
    end

    test "prompt_many は複数の入力を取得する" do
      {console, _} = Console.test_console(["Alice", "30", "Tokyo"])

      results = Console.prompt_many(console, ["Name: ", "Age: ", "City: "])

      assert results == ["Alice", "30", "Tokyo"]
    end
  end

  # ============================================================
  # 2. ファイルシステム
  # ============================================================

  describe "IO.FileSystem" do
    test "in_memory は初期ファイルを読み込める" do
      {fs, _} = FileSystem.in_memory(%{"file.txt" => "content"})

      assert fs.read.("file.txt") == {:ok, "content"}
      assert fs.read.("missing.txt") == {:error, :enoent}
    end

    test "in_memory はファイルの存在を確認できる" do
      {fs, _} = FileSystem.in_memory(%{"file.txt" => "content"})

      assert fs.exists?.("file.txt") == true
      assert fs.exists?.("missing.txt") == false
    end

    test "in_memory はファイルを書き込める" do
      {fs, get_state} = FileSystem.in_memory(%{})

      assert fs.write.("new.txt", "new content") == :ok
      assert get_state.()["new.txt"] == "new content"
    end

    test "in_memory はファイルを削除できる" do
      {fs, get_state} = FileSystem.in_memory(%{"file.txt" => "content"})

      assert fs.delete.("file.txt") == :ok
      assert get_state.()["file.txt"] == nil
      assert fs.delete.("missing.txt") == {:error, :enoent}
    end

    test "in_memory はディレクトリをリストできる" do
      {fs, _} = FileSystem.in_memory(%{"a.txt" => "a", "b.txt" => "b"})

      {:ok, files} = fs.list_dir.("/")
      assert "a.txt" in files
      assert "b.txt" in files
    end

    test "safe_read はファイルを安全に読み込む" do
      {fs, _} = FileSystem.in_memory(%{"test.txt" => "hello"})

      assert FileSystem.safe_read(fs, "test.txt") == {:ok, "hello"}
      assert FileSystem.safe_read(fs, "missing.txt") == {:error, :enoent}
    end

    test "transform はファイルの内容を変換する" do
      {fs, get_state} = FileSystem.in_memory(%{"data.txt" => "hello"})

      assert FileSystem.transform(fs, "data.txt", &String.upcase/1) == :ok
      assert get_state.()["data.txt"] == "HELLO"
    end

    test "transform は存在しないファイルでエラーを返す" do
      {fs, _} = FileSystem.in_memory(%{})

      assert FileSystem.transform(fs, "missing.txt", &String.upcase/1) == {:error, :enoent}
    end
  end

  # ============================================================
  # 3. リポジトリパターン
  # ============================================================

  describe "Repository" do
    test "in_memory はエンティティを保存・取得できる" do
      repo = Repository.in_memory()

      {:ok, saved} = repo.save.(%{id: "1", data: %{name: "Alice"}})
      assert saved.id == "1"

      {:ok, found} = repo.find.("1")
      assert found.data.name == "Alice"
    end

    test "in_memory は存在しないエンティティでエラーを返す" do
      repo = Repository.in_memory()

      assert repo.find.("nonexistent") == {:error, :not_found}
    end

    test "in_memory はすべてのエンティティを取得できる" do
      repo = Repository.in_memory()

      repo.save.(%{id: "1", data: %{name: "Alice"}})
      repo.save.(%{id: "2", data: %{name: "Bob"}})

      all = repo.find_all.()
      assert length(all) == 2
    end

    test "in_memory はエンティティを削除できる" do
      repo = Repository.in_memory()

      repo.save.(%{id: "1", data: %{name: "Alice"}})
      assert repo.delete.("1") == :ok
      assert repo.find.("1") == {:error, :not_found}
    end

    test "in_memory は存在を確認できる" do
      repo = Repository.in_memory()

      repo.save.(%{id: "1", data: %{name: "Alice"}})
      assert repo.exists?.("1") == true
      assert repo.exists?.("2") == false
    end

    test "find_by は条件に一致するエンティティを返す" do
      repo = Repository.in_memory()

      repo.save.(%{id: "1", data: %{name: "Alice", age: 30}})
      repo.save.(%{id: "2", data: %{name: "Bob", age: 25}})
      repo.save.(%{id: "3", data: %{name: "Charlie", age: 35}})

      results = Repository.find_by(repo, fn e -> e.data.age > 26 end)

      assert length(results) == 2
      names = Enum.map(results, & &1.data.name)
      assert "Alice" in names
      assert "Charlie" in names
    end

    test "save_all は複数のエンティティを保存する" do
      repo = Repository.in_memory()

      entities = [
        %{id: "1", data: %{name: "A"}},
        %{id: "2", data: %{name: "B"}},
        %{id: "3", data: %{name: "C"}}
      ]

      assert Repository.save_all(repo, entities) == :ok
      assert length(repo.find_all.()) == 3
    end
  end

  # ============================================================
  # 4. HTTP クライアント
  # ============================================================

  describe "Http" do
    test "test_client はレスポンスをシミュレートする" do
      responses = %{
        "https://api.example.com/users" => %{status: 200, headers: %{}, body: "[]"}
      }

      client = Http.test_client(responses)

      {:ok, response} = client.get.("https://api.example.com/users")
      assert response.status == 200
      assert response.body == "[]"
    end

    test "test_client は存在しない URL でエラーを返す" do
      client = Http.test_client(%{})

      assert client.get.("https://unknown.com") == {:error, :not_found}
    end

    test "simple_json_parse は JSON をパースする" do
      body = ~s({"name": "Alice", "age": 30})

      result = Http.simple_json_parse(body)

      assert result["name"] == "Alice"
      assert result["age"] == 30
    end

    test "simple_json_parse はブール値をパースする" do
      body = ~s({"active": true, "deleted": false})

      result = Http.simple_json_parse(body)

      assert result["active"] == true
      assert result["deleted"] == false
    end
  end

  # ============================================================
  # 5. UserApiClient
  # ============================================================

  describe "UserApiClient" do
    test "get_user はユーザーを取得する" do
      responses = %{
        "https://api.example.com/users/1" => %{
          status: 200,
          headers: %{},
          body: ~s({"id": "1", "name": "Alice", "email": "alice@example.com"})
        }
      }

      client = Http.test_client(responses)

      {:ok, user} = UserApiClient.get_user(client, "https://api.example.com", "1")

      assert user.id == "1"
      assert user.name == "Alice"
      assert user.email == "alice@example.com"
    end

    test "get_user は 404 でエラーを返す" do
      responses = %{
        "https://api.example.com/users/999" => %{status: 404, headers: %{}, body: ""}
      }

      client = Http.test_client(responses)

      assert UserApiClient.get_user(client, "https://api.example.com", "999") == {:error, :not_found}
    end
  end

  # ============================================================
  # 6. UserService
  # ============================================================

  describe "UserService" do
    test "create_user は新しいユーザーを作成する" do
      repo = Repository.in_memory()
      id_generator = fn -> "gen-123" end
      time_provider = fn -> ~U[2024-01-01 00:00:00Z] end
      params = %{name: "Alice", email: "alice@example.com"}

      {:ok, user} = UserService.create_user(repo, params, id_generator, time_provider)

      assert user.id == "gen-123"
      assert user.name == "Alice"
      assert user.email == "alice@example.com"
      assert user.created_at == ~U[2024-01-01 00:00:00Z]
    end

    test "create_user は空の名前を拒否する" do
      repo = Repository.in_memory()
      params = %{name: "", email: "alice@example.com"}

      result = UserService.create_user(repo, params, fn -> "id" end, fn -> DateTime.utc_now() end)

      assert result == {:error, :invalid_name}
    end

    test "create_user は不正なメールを拒否する" do
      repo = Repository.in_memory()
      params = %{name: "Alice", email: "invalid"}

      result = UserService.create_user(repo, params, fn -> "id" end, fn -> DateTime.utc_now() end)

      assert result == {:error, :invalid_email}
    end

    test "create_user は重複メールを拒否する" do
      repo = Repository.in_memory()
      repo.save.(%{id: "existing", data: %{email: "alice@example.com"}})
      params = %{name: "Alice", email: "alice@example.com"}

      result = UserService.create_user(repo, params, fn -> "id" end, fn -> DateTime.utc_now() end)

      assert result == {:error, :email_already_exists}
    end

    test "get_user はユーザーを取得する" do
      repo = Repository.in_memory()
      repo.save.(%{id: "1", data: %{name: "Alice", email: "alice@example.com"}})

      {:ok, user} = UserService.get_user(repo, "1")

      assert user.data.name == "Alice"
    end

    test "find_by_email はメールでユーザーを検索する" do
      repo = Repository.in_memory()
      repo.save.(%{id: "1", data: %{name: "Alice", email: "alice@example.com"}})
      repo.save.(%{id: "2", data: %{name: "Bob", email: "bob@example.com"}})

      {:ok, user} = UserService.find_by_email(repo, "alice@example.com")

      assert user.data.name == "Alice"
    end

    test "find_by_email は存在しないメールでエラーを返す" do
      repo = Repository.in_memory()

      assert UserService.find_by_email(repo, "unknown@example.com") == {:error, :not_found}
    end
  end

  # ============================================================
  # 7. Config
  # ============================================================

  describe "Config" do
    test "from_map は設定値を取得できる" do
      source = Config.from_map(%{"KEY" => "value"})

      assert source.get.("KEY") == "value"
      assert source.get.("MISSING") == nil
    end

    test "require は必須の設定値を取得する" do
      source = Config.from_map(%{"KEY" => "value"})

      assert Config.require(source, "KEY") == {:ok, "value"}
      assert Config.require(source, "MISSING") == {:error, {:missing_config, "MISSING"}}
    end

    test "get_or_default はデフォルト値を使用する" do
      source = Config.from_map(%{"KEY" => "value"})

      assert Config.get_or_default(source, "KEY", "default") == "value"
      assert Config.get_or_default(source, "MISSING", "default") == "default"
    end

    test "get_integer は整数として取得する" do
      source = Config.from_map(%{"PORT" => "8080", "INVALID" => "not_a_number"})

      assert Config.get_integer(source, "PORT", 3000) == 8080
      assert Config.get_integer(source, "INVALID", 3000) == 3000
      assert Config.get_integer(source, "MISSING", 3000) == 3000
    end
  end

  # ============================================================
  # 8. Transaction
  # ============================================================

  describe "Transaction" do
    test "execute はすべての操作を実行する" do
      operations = [
        {fn -> {:ok, 1} end, fn -> :ok end},
        {fn -> {:ok, 2} end, fn -> :ok end},
        {fn -> {:ok, 3} end, fn -> :ok end}
      ]

      assert Transaction.execute(operations) == {:ok, [1, 2, 3]}
    end

    test "execute は失敗時にロールバックを実行する" do
      {:ok, rollback_tracker} = Agent.start_link(fn -> [] end)

      operations = [
        {fn -> {:ok, 1} end, fn ->
          Agent.update(rollback_tracker, &["rollback1" | &1])
          :ok
        end},
        {fn -> {:ok, 2} end, fn ->
          Agent.update(rollback_tracker, &["rollback2" | &1])
          :ok
        end},
        {fn -> {:error, "failed"} end, fn -> :ok end}
      ]

      assert Transaction.execute(operations) == {:error, "failed"}

      rollbacks = Agent.get(rollback_tracker, & &1)
      # 最後に成功した操作から逆順でロールバック
      assert "rollback2" in rollbacks
      assert "rollback1" in rollbacks

      Agent.stop(rollback_tracker)
    end

    test "with_resource はリソースを確実にクリーンアップする" do
      {:ok, cleanup_tracker} = Agent.start_link(fn -> false end)

      acquire = fn -> {:ok, :resource} end
      release = fn _ ->
        Agent.update(cleanup_tracker, fn _ -> true end)
        :ok
      end
      use_resource = fn :resource -> {:ok, "result"} end

      result = Transaction.with_resource(acquire, release, use_resource)

      assert result == {:ok, "result"}
      assert Agent.get(cleanup_tracker, & &1) == true

      Agent.stop(cleanup_tracker)
    end

    test "with_resource はエラー時もクリーンアップする" do
      {:ok, cleanup_tracker} = Agent.start_link(fn -> false end)

      acquire = fn -> {:ok, :resource} end
      release = fn _ ->
        Agent.update(cleanup_tracker, fn _ -> true end)
        :ok
      end
      use_resource = fn _ -> {:error, "failed"} end

      result = Transaction.with_resource(acquire, release, use_resource)

      assert result == {:error, "failed"}
      assert Agent.get(cleanup_tracker, & &1) == true

      Agent.stop(cleanup_tracker)
    end

    test "with_resource は取得失敗時はクリーンアップしない" do
      {:ok, cleanup_tracker} = Agent.start_link(fn -> false end)

      acquire = fn -> {:error, :acquire_failed} end
      release = fn _ ->
        Agent.update(cleanup_tracker, fn _ -> true end)
        :ok
      end
      use_resource = fn _ -> {:ok, "result"} end

      result = Transaction.with_resource(acquire, release, use_resource)

      assert result == {:error, :acquire_failed}
      assert Agent.get(cleanup_tracker, & &1) == false

      Agent.stop(cleanup_tracker)
    end
  end
end
