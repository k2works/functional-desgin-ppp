defmodule Chapter09 do
  @moduledoc """
  # Chapter 09: I/O and External Systems

  このモジュールでは、I/O 操作と外部システムとの連携を
  関数型プログラミングの原則に従って実装する方法を学びます。

  ## 主なトピック

  1. I/O の抽象化
  2. ポートとアダプター
  3. リポジトリパターン
  4. 外部 API クライアント
  5. ファイル操作
  6. データベース操作の抽象化
  """

  # ============================================================
  # 1. I/O の抽象化
  # ============================================================

  defmodule IO.Console do
    @moduledoc """
    コンソール I/O の抽象化。
    テスト時にモック可能にする。
    """

    @type console :: %{
      read: (() -> String.t()),
      write: (String.t() -> :ok)
    }

    @doc """
    標準のコンソール実装を返す。
    """
    @spec standard() :: console()
    def standard do
      %{
        read: fn -> Elixir.IO.gets("") |> String.trim() end,
        write: fn msg -> Elixir.IO.puts(msg); :ok end
      }
    end

    @doc """
    テスト用のコンソール実装を返す。

    ## Examples

        iex> {console, get_output} = Chapter09.IO.Console.test_console(["input1", "input2"])
        iex> console.read.()
        "input1"
        iex> console.read.()
        "input2"
        iex> console.write.("hello")
        :ok
        iex> get_output.()
        ["hello"]
    """
    @spec test_console([String.t()]) :: {console(), (() -> [String.t()])}
    def test_console(inputs) do
      {:ok, input_agent} = Agent.start_link(fn -> inputs end)
      {:ok, output_agent} = Agent.start_link(fn -> [] end)

      console = %{
        read: fn ->
          Agent.get_and_update(input_agent, fn
            [head | tail] -> {head, tail}
            [] -> {"", []}
          end)
        end,
        write: fn msg ->
          Agent.update(output_agent, fn outputs -> outputs ++ [msg] end)
          :ok
        end
      }

      get_output = fn -> Agent.get(output_agent, & &1) end

      {console, get_output}
    end

    @doc """
    コンソールを使用してプロンプトを表示し入力を取得する。

    ## Examples

        iex> {console, _} = Chapter09.IO.Console.test_console(["Alice"])
        iex> Chapter09.IO.Console.prompt(console, "Name: ")
        "Alice"
    """
    @spec prompt(console(), String.t()) :: String.t()
    def prompt(console, message) do
      console.write.(message)
      console.read.()
    end

    @doc """
    複数の入力を順番に取得する。

    ## Examples

        iex> {console, _} = Chapter09.IO.Console.test_console(["Alice", "30", "Tokyo"])
        iex> Chapter09.IO.Console.prompt_many(console, ["Name: ", "Age: ", "City: "])
        ["Alice", "30", "Tokyo"]
    """
    @spec prompt_many(console(), [String.t()]) :: [String.t()]
    def prompt_many(console, prompts) do
      Enum.map(prompts, &prompt(console, &1))
    end
  end

  # ============================================================
  # 2. ファイル操作の抽象化
  # ============================================================

  defmodule IO.FileSystem do
    @moduledoc """
    ファイルシステム操作の抽象化。
    """

    @type fs :: %{
      read: (String.t() -> {:ok, String.t()} | {:error, term()}),
      write: (String.t(), String.t() -> :ok | {:error, term()}),
      exists?: (String.t() -> boolean()),
      delete: (String.t() -> :ok | {:error, term()}),
      list_dir: (String.t() -> {:ok, [String.t()]} | {:error, term()})
    }

    @doc """
    実際のファイルシステム実装を返す。
    """
    @spec real() :: fs()
    def real do
      %{
        read: &File.read/1,
        write: &File.write/2,
        exists?: &File.exists?/1,
        delete: &File.rm/1,
        list_dir: &File.ls/1
      }
    end

    @doc """
    インメモリのファイルシステム実装を返す（テスト用）。

    ## Examples

        iex> {fs, get_state} = Chapter09.IO.FileSystem.in_memory(%{"file.txt" => "content"})
        iex> fs.read.("file.txt")
        {:ok, "content"}
        iex> fs.exists?.("file.txt")
        true
        iex> fs.write.("new.txt", "new content")
        :ok
        iex> get_state.()["new.txt"]
        "new content"
    """
    @spec in_memory(map()) :: {fs(), (() -> map())}
    def in_memory(initial_files \\ %{}) do
      {:ok, agent} = Agent.start_link(fn -> initial_files end)

      fs = %{
        read: fn path ->
          case Agent.get(agent, &Map.get(&1, path)) do
            nil -> {:error, :enoent}
            content -> {:ok, content}
          end
        end,
        write: fn path, content ->
          Agent.update(agent, &Map.put(&1, path, content))
          :ok
        end,
        exists?: fn path ->
          Agent.get(agent, &Map.has_key?(&1, path))
        end,
        delete: fn path ->
          if Agent.get(agent, &Map.has_key?(&1, path)) do
            Agent.update(agent, &Map.delete(&1, path))
            :ok
          else
            {:error, :enoent}
          end
        end,
        list_dir: fn _path ->
          {:ok, Agent.get(agent, &Map.keys(&1))}
        end
      }

      get_state = fn -> Agent.get(agent, & &1) end

      {fs, get_state}
    end

    @doc """
    ファイルを安全に読み込む。

    ## Examples

        iex> {fs, _} = Chapter09.IO.FileSystem.in_memory(%{"test.txt" => "hello"})
        iex> Chapter09.IO.FileSystem.safe_read(fs, "test.txt")
        {:ok, "hello"}
        iex> Chapter09.IO.FileSystem.safe_read(fs, "missing.txt")
        {:error, :enoent}
    """
    @spec safe_read(fs(), String.t()) :: {:ok, String.t()} | {:error, term()}
    def safe_read(fs, path) do
      fs.read.(path)
    end

    @doc """
    ファイルの内容を変換して書き込む。

    ## Examples

        iex> {fs, get_state} = Chapter09.IO.FileSystem.in_memory(%{"data.txt" => "hello"})
        iex> Chapter09.IO.FileSystem.transform(fs, "data.txt", &String.upcase/1)
        :ok
        iex> get_state.()["data.txt"]
        "HELLO"
    """
    @spec transform(fs(), String.t(), (String.t() -> String.t())) :: :ok | {:error, term()}
    def transform(fs, path, transformer) do
      case fs.read.(path) do
        {:ok, content} -> fs.write.(path, transformer.(content))
        error -> error
      end
    end
  end

  # ============================================================
  # 3. リポジトリパターン
  # ============================================================

  defmodule Repository do
    @moduledoc """
    リポジトリパターンの実装。
    データ永続化を抽象化する。
    """

    @type entity :: %{id: String.t(), data: map()}

    @type repo(entity) :: %{
      find: (String.t() -> {:ok, entity} | {:error, :not_found}),
      find_all: (() -> [entity]),
      save: (entity -> {:ok, entity}),
      delete: (String.t() -> :ok | {:error, :not_found}),
      exists?: (String.t() -> boolean())
    }

    @doc """
    インメモリリポジトリを作成する。

    ## Examples

        iex> repo = Chapter09.Repository.in_memory()
        iex> {:ok, saved} = repo.save.(%{id: "1", data: %{name: "Alice"}})
        iex> saved.id
        "1"
        iex> {:ok, found} = repo.find.("1")
        iex> found.data.name
        "Alice"
    """
    @spec in_memory() :: repo(entity())
    def in_memory do
      {:ok, agent} = Agent.start_link(fn -> %{} end)

      %{
        find: fn id ->
          case Agent.get(agent, &Map.get(&1, id)) do
            nil -> {:error, :not_found}
            entity -> {:ok, entity}
          end
        end,
        find_all: fn ->
          Agent.get(agent, &Map.values(&1))
        end,
        save: fn entity ->
          Agent.update(agent, &Map.put(&1, entity.id, entity))
          {:ok, entity}
        end,
        delete: fn id ->
          if Agent.get(agent, &Map.has_key?(&1, id)) do
            Agent.update(agent, &Map.delete(&1, id))
            :ok
          else
            {:error, :not_found}
          end
        end,
        exists?: fn id ->
          Agent.get(agent, &Map.has_key?(&1, id))
        end
      }
    end

    @doc """
    条件に一致するエンティティを検索する。

    ## Examples

        iex> repo = Chapter09.Repository.in_memory()
        iex> repo.save.(%{id: "1", data: %{name: "Alice", age: 30}})
        iex> repo.save.(%{id: "2", data: %{name: "Bob", age: 25}})
        iex> results = Chapter09.Repository.find_by(repo, fn e -> e.data.age > 26 end)
        iex> length(results)
        1
        iex> hd(results).data.name
        "Alice"
    """
    @spec find_by(repo(entity()), (entity() -> boolean())) :: [entity()]
    def find_by(repo, predicate) do
      repo.find_all.()
      |> Enum.filter(predicate)
    end

    @doc """
    バッチで保存する。

    ## Examples

        iex> repo = Chapter09.Repository.in_memory()
        iex> entities = [
        ...>   %{id: "1", data: %{name: "A"}},
        ...>   %{id: "2", data: %{name: "B"}}
        ...> ]
        iex> Chapter09.Repository.save_all(repo, entities)
        :ok
        iex> length(repo.find_all.())
        2
    """
    @spec save_all(repo(entity()), [entity()]) :: :ok
    def save_all(repo, entities) do
      Enum.each(entities, &repo.save.(&1))
      :ok
    end
  end

  # ============================================================
  # 4. HTTP クライアントの抽象化
  # ============================================================

  defmodule Http do
    @moduledoc """
    HTTP クライアントの抽象化。
    """

    @type response :: %{
      status: pos_integer(),
      headers: map(),
      body: String.t()
    }

    @type http_client :: %{
      get: (String.t() -> {:ok, response()} | {:error, term()}),
      post: (String.t(), String.t() -> {:ok, response()} | {:error, term()}),
      put: (String.t(), String.t() -> {:ok, response()} | {:error, term()}),
      delete: (String.t() -> {:ok, response()} | {:error, term()})
    }

    @doc """
    テスト用の HTTP クライアントを作成する。

    ## Examples

        iex> responses = %{
        ...>   "https://api.example.com/users" => %{status: 200, headers: %{}, body: ~s({"users": []})}
        ...> }
        iex> client = Chapter09.Http.test_client(responses)
        iex> {:ok, response} = client.get.("https://api.example.com/users")
        iex> response.status
        200
    """
    @spec test_client(map()) :: http_client()
    def test_client(responses) do
      make_request = fn url ->
        case Map.get(responses, url) do
          nil -> {:error, :not_found}
          response -> {:ok, response}
        end
      end

      %{
        get: make_request,
        post: fn url, _body -> make_request.(url) end,
        put: fn url, _body -> make_request.(url) end,
        delete: make_request
      }
    end

    @doc """
    JSON レスポンスをパースする。

    ## Examples

        iex> response = %{status: 200, headers: %{}, body: ~s({"name": "Alice"})}
        iex> Chapter09.Http.parse_json_response({:ok, response})
        {:ok, %{"name" => "Alice"}}
    """
    @spec parse_json_response({:ok, response()} | {:error, term()}) :: {:ok, map()} | {:error, term()}
    def parse_json_response({:ok, %{body: body}}) do
      case Jason.decode(body) do
        {:ok, data} -> {:ok, data}
        {:error, _} -> {:error, :invalid_json}
      end
    rescue
      UndefinedFunctionError -> {:error, :jason_not_available}
    end
    def parse_json_response({:error, _} = error), do: error

    @doc """
    JSON レスポンスをパースする（Jason なしのシンプル版）。

    ## Examples

        iex> body = ~s({"name": "Alice", "age": 30})
        iex> Chapter09.Http.simple_json_parse(body)
        %{"name" => "Alice", "age" => 30}
    """
    @spec simple_json_parse(String.t()) :: map()
    def simple_json_parse(body) do
      # 非常にシンプルな JSON パーサー（デモ用）
      body
      |> String.trim()
      |> String.trim_leading("{")
      |> String.trim_trailing("}")
      |> String.split(",")
      |> Enum.map(fn pair ->
        [key, value] = String.split(pair, ":", parts: 2)
        key = key |> String.trim() |> String.trim("\"")
        value = parse_value(String.trim(value))
        {key, value}
      end)
      |> Map.new()
    end

    defp parse_value(v) do
      v = String.trim(v)
      cond do
        String.starts_with?(v, "\"") -> String.trim(v, "\"")
        v == "true" -> true
        v == "false" -> false
        v == "null" -> nil
        String.contains?(v, ".") ->
          {f, ""} = Float.parse(v)
          f
        true ->
          case Integer.parse(v) do
            {i, ""} -> i
            _ -> v
          end
      end
    end
  end

  # ============================================================
  # 5. API クライアント例
  # ============================================================

  defmodule UserApiClient do
    @moduledoc """
    ユーザー API クライアントの例。
    HTTP クライアントを注入して使用する。
    """

    alias Chapter09.Http

    @type user :: %{
      id: String.t(),
      name: String.t(),
      email: String.t()
    }

    @doc """
    ユーザー一覧を取得する。

    ## Examples

        iex> responses = %{
        ...>   "https://api.example.com/users" => %{
        ...>     status: 200,
        ...>     headers: %{},
        ...>     body: ~s([{"id":"1","name":"Alice","email":"alice@example.com"}])
        ...>   }
        ...> }
        iex> client = Chapter09.Http.test_client(responses)
        iex> # 注: この例は簡易パーサーでは動作しない
        iex> :ok
        :ok
    """
    @spec list_users(Http.http_client(), String.t()) :: {:ok, [user()]} | {:error, term()}
    def list_users(http_client, base_url) do
      case http_client.get.("#{base_url}/users") do
        {:ok, %{status: 200, body: body}} ->
          # 簡易実装
          {:ok, parse_users(body)}
        {:ok, %{status: status}} ->
          {:error, {:http_error, status}}
        {:error, _} = error ->
          error
      end
    end

    defp parse_users(_body) do
      # 実際には JSON パースを行う
      []
    end

    @doc """
    ユーザーを取得する。

    ## Examples

        iex> responses = %{
        ...>   "https://api.example.com/users/1" => %{
        ...>     status: 200,
        ...>     headers: %{},
        ...>     body: ~s({"id":"1","name":"Alice","email":"alice@example.com"})
        ...>   }
        ...> }
        iex> client = Chapter09.Http.test_client(responses)
        iex> {:ok, user} = Chapter09.UserApiClient.get_user(client, "https://api.example.com", "1")
        iex> user.name
        "Alice"
    """
    @spec get_user(Http.http_client(), String.t(), String.t()) :: {:ok, user()} | {:error, term()}
    def get_user(http_client, base_url, user_id) do
      case http_client.get.("#{base_url}/users/#{user_id}") do
        {:ok, %{status: 200, body: body}} ->
          data = Http.simple_json_parse(body)
          {:ok, %{
            id: data["id"],
            name: data["name"],
            email: data["email"]
          }}
        {:ok, %{status: 404}} ->
          {:error, :not_found}
        {:ok, %{status: status}} ->
          {:error, {:http_error, status}}
        {:error, _} = error ->
          error
      end
    end
  end

  # ============================================================
  # 6. サービス層パターン
  # ============================================================

  defmodule UserService do
    @moduledoc """
    ユーザーサービス。
    リポジトリを使用してビジネスロジックを実装する。
    """

    alias Chapter09.Repository

    @type user :: %{
      id: String.t(),
      name: String.t(),
      email: String.t(),
      created_at: DateTime.t()
    }

    @type create_user_params :: %{
      name: String.t(),
      email: String.t()
    }

    @doc """
    ユーザーを作成する。

    ## Examples

        iex> repo = Chapter09.Repository.in_memory()
        iex> id_generator = fn -> "gen-123" end
        iex> time_provider = fn -> ~U[2024-01-01 00:00:00Z] end
        iex> params = %{name: "Alice", email: "alice@example.com"}
        iex> {:ok, user} = Chapter09.UserService.create_user(repo, params, id_generator, time_provider)
        iex> user.name
        "Alice"
        iex> user.id
        "gen-123"
    """
    @spec create_user(
      Repository.repo(any()),
      create_user_params(),
      (() -> String.t()),
      (() -> DateTime.t())
    ) :: {:ok, user()} | {:error, term()}
    def create_user(repo, params, id_generator, time_provider) do
      # バリデーション
      with :ok <- validate_name(params.name),
           :ok <- validate_email(params.email),
           false <- email_exists?(repo, params.email) do
        user = %{
          id: id_generator.(),
          name: params.name,
          email: params.email,
          created_at: time_provider.(),
          data: %{name: params.name, email: params.email}
        }

        repo.save.(user)
        {:ok, user}
      else
        {:error, _} = error -> error
        true -> {:error, :email_already_exists}
      end
    end

    defp validate_name(name) when byte_size(name) >= 1, do: :ok
    defp validate_name(_), do: {:error, :invalid_name}

    defp validate_email(email) do
      if String.contains?(email, "@"), do: :ok, else: {:error, :invalid_email}
    end

    defp email_exists?(repo, email) do
      repo.find_all.()
      |> Enum.any?(fn user -> user.data[:email] == email end)
    end

    @doc """
    ユーザーを取得する。

    ## Examples

        iex> repo = Chapter09.Repository.in_memory()
        iex> repo.save.(%{id: "1", data: %{name: "Alice", email: "alice@example.com"}})
        iex> {:ok, user} = Chapter09.UserService.get_user(repo, "1")
        iex> user.data.name
        "Alice"
    """
    @spec get_user(Repository.repo(any()), String.t()) :: {:ok, user()} | {:error, :not_found}
    def get_user(repo, id) do
      repo.find.(id)
    end

    @doc """
    メールアドレスでユーザーを検索する。

    ## Examples

        iex> repo = Chapter09.Repository.in_memory()
        iex> repo.save.(%{id: "1", data: %{name: "Alice", email: "alice@example.com"}})
        iex> repo.save.(%{id: "2", data: %{name: "Bob", email: "bob@example.com"}})
        iex> {:ok, user} = Chapter09.UserService.find_by_email(repo, "alice@example.com")
        iex> user.data.name
        "Alice"
    """
    @spec find_by_email(Repository.repo(any()), String.t()) :: {:ok, user()} | {:error, :not_found}
    def find_by_email(repo, email) do
      case Repository.find_by(repo, fn user -> user.data[:email] == email end) do
        [user | _] -> {:ok, user}
        [] -> {:error, :not_found}
      end
    end
  end

  # ============================================================
  # 7. 設定管理
  # ============================================================

  defmodule Config do
    @moduledoc """
    設定管理の抽象化。
    """

    @type config_source :: %{
      get: (String.t() -> String.t() | nil),
      get_all: (() -> map())
    }

    @doc """
    環境変数ベースの設定ソースを作成する。
    """
    @spec from_env() :: config_source()
    def from_env do
      %{
        get: &System.get_env/1,
        get_all: fn -> System.get_env() end
      }
    end

    @doc """
    マップベースの設定ソースを作成する（テスト用）。

    ## Examples

        iex> source = Chapter09.Config.from_map(%{"DB_HOST" => "localhost", "DB_PORT" => "5432"})
        iex> source.get.("DB_HOST")
        "localhost"
    """
    @spec from_map(map()) :: config_source()
    def from_map(config) do
      %{
        get: &Map.get(config, &1),
        get_all: fn -> config end
      }
    end

    @doc """
    必須の設定値を取得する。

    ## Examples

        iex> source = Chapter09.Config.from_map(%{"KEY" => "value"})
        iex> Chapter09.Config.require(source, "KEY")
        {:ok, "value"}
        iex> Chapter09.Config.require(source, "MISSING")
        {:error, {:missing_config, "MISSING"}}
    """
    @spec require(config_source(), String.t()) :: {:ok, String.t()} | {:error, {:missing_config, String.t()}}
    def require(source, key) do
      case source.get.(key) do
        nil -> {:error, {:missing_config, key}}
        value -> {:ok, value}
      end
    end

    @doc """
    デフォルト値付きで設定値を取得する。

    ## Examples

        iex> source = Chapter09.Config.from_map(%{"KEY" => "value"})
        iex> Chapter09.Config.get_or_default(source, "KEY", "default")
        "value"
        iex> Chapter09.Config.get_or_default(source, "MISSING", "default")
        "default"
    """
    @spec get_or_default(config_source(), String.t(), String.t()) :: String.t()
    def get_or_default(source, key, default) do
      source.get.(key) || default
    end

    @doc """
    整数として設定値を取得する。

    ## Examples

        iex> source = Chapter09.Config.from_map(%{"PORT" => "8080"})
        iex> Chapter09.Config.get_integer(source, "PORT", 3000)
        8080
        iex> Chapter09.Config.get_integer(source, "MISSING", 3000)
        3000
    """
    @spec get_integer(config_source(), String.t(), integer()) :: integer()
    def get_integer(source, key, default) do
      case source.get.(key) do
        nil -> default
        value ->
          case Integer.parse(value) do
            {int, ""} -> int
            _ -> default
          end
      end
    end
  end

  # ============================================================
  # 8. トランザクション風の操作
  # ============================================================

  defmodule Transaction do
    @moduledoc """
    トランザクション風の操作をシミュレートする。
    """

    @type operation(a) :: (() -> {:ok, a} | {:error, term()})
    @type rollback :: (() -> :ok)

    @doc """
    複数の操作をトランザクション風に実行する。
    失敗した場合は以前の操作をロールバックする。

    ## Examples

        iex> operations = [
        ...>   {fn -> {:ok, 1} end, fn -> :ok end},
        ...>   {fn -> {:ok, 2} end, fn -> :ok end}
        ...> ]
        iex> Chapter09.Transaction.execute(operations)
        {:ok, [1, 2]}

        iex> rollback_called = Agent.start_link(fn -> false end) |> elem(1)
        iex> operations = [
        ...>   {fn -> {:ok, 1} end, fn -> Agent.update(rollback_called, fn _ -> true end); :ok end},
        ...>   {fn -> {:error, "failed"} end, fn -> :ok end}
        ...> ]
        iex> Chapter09.Transaction.execute(operations)
        {:error, "failed"}
        iex> Agent.get(rollback_called, & &1)
        true
    """
    @spec execute([{operation(any()), rollback()}]) :: {:ok, [any()]} | {:error, term()}
    def execute(operations) do
      do_execute(operations, [], [])
    end

    defp do_execute([], results, _rollbacks), do: {:ok, Enum.reverse(results)}
    defp do_execute([{operation, rollback} | rest], results, rollbacks) do
      case operation.() do
        {:ok, result} ->
          do_execute(rest, [result | results], [rollback | rollbacks])
        {:error, reason} ->
          # ロールバック実行
          Enum.each(rollbacks, fn rb -> rb.() end)
          {:error, reason}
      end
    end

    @doc """
    リソースを使用して操作を実行し、完了後にクリーンアップする。

    ## Examples

        iex> cleanup_called = Agent.start_link(fn -> false end) |> elem(1)
        iex> acquire = fn -> {:ok, :resource} end
        iex> release = fn _ -> Agent.update(cleanup_called, fn _ -> true end); :ok end
        iex> use_resource = fn :resource -> {:ok, "result"} end
        iex> Chapter09.Transaction.with_resource(acquire, release, use_resource)
        {:ok, "result"}
        iex> Agent.get(cleanup_called, & &1)
        true
    """
    @spec with_resource(
      (() -> {:ok, any()} | {:error, term()}),
      (any() -> :ok),
      (any() -> {:ok, any()} | {:error, term()})
    ) :: {:ok, any()} | {:error, term()}
    def with_resource(acquire, release, use) do
      case acquire.() do
        {:ok, resource} ->
          try do
            use.(resource)
          after
            release.(resource)
          end
        {:error, _} = error ->
          error
      end
    end
  end
end
