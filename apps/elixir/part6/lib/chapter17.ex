defmodule Chapter17 do
  @moduledoc """
  # Chapter 17: レンタルビデオシステム

  レンタルビデオシステムは、映画のレンタル、料金計算、
  明細書生成を行うシステムです。パターンマッチングによる
  多態性を活用して、カテゴリごとの料金計算を実装します。

  ## 主なトピック

  1. 映画モデル（通常、新作、子供向け）
  2. レンタルモデル
  3. 料金・ポイント計算
  4. 明細書生成（テキスト、HTML）
  """

  # ============================================================
  # 1. 映画モデル
  # ============================================================

  defmodule Movie do
    @moduledoc "映画の構造体"

    @type category :: :regular | :new_release | :childrens

    defstruct [:title, :category]

    @type t :: %__MODULE__{
      title: String.t(),
      category: category()
    }

    @doc """
    映画を作成する。

    ## Examples

        iex> movie = Chapter17.Movie.new("The Matrix", :new_release)
        iex> movie.title
        "The Matrix"
        iex> movie.category
        :new_release
    """
    def new(title, category) when category in [:regular, :new_release, :childrens] do
      %__MODULE__{title: title, category: category}
    end

    @doc "通常映画を作成"
    def regular(title), do: new(title, :regular)

    @doc "新作映画を作成"
    def new_release(title), do: new(title, :new_release)

    @doc "子供向け映画を作成"
    def childrens(title), do: new(title, :childrens)

    def get_title(%__MODULE__{title: title}), do: title
    def get_category(%__MODULE__{category: category}), do: category
  end

  # ============================================================
  # 2. レンタルモデル
  # ============================================================

  defmodule Rental do
    @moduledoc "レンタルの構造体"

    alias Chapter17.Movie

    defstruct [:movie, :days]

    @type t :: %__MODULE__{
      movie: Movie.t(),
      days: pos_integer()
    }

    @doc """
    レンタルを作成する。

    ## Examples

        iex> movie = Chapter17.Movie.regular("Casablanca")
        iex> rental = Chapter17.Rental.new(movie, 3)
        iex> rental.days
        3
    """
    def new(%Movie{} = movie, days) when days > 0 do
      %__MODULE__{movie: movie, days: days}
    end

    def get_movie(%__MODULE__{movie: movie}), do: movie
    def get_days(%__MODULE__{days: days}), do: days
    def get_movie_title(%__MODULE__{movie: movie}), do: Movie.get_title(movie)
    def get_movie_category(%__MODULE__{movie: movie}), do: Movie.get_category(movie)
  end

  # ============================================================
  # 3. 料金計算
  # ============================================================

  defmodule Pricing do
    @moduledoc "料金とポイントの計算"

    alias Chapter17.Rental

    @doc """
    レンタル料金を計算する。

    ## Examples

        iex> movie = Chapter17.Movie.regular("Test")
        iex> rental = Chapter17.Rental.new(movie, 3)
        iex> Chapter17.Pricing.determine_amount(rental)
        3.5
    """
    def determine_amount(%Rental{} = rental) do
      case Rental.get_movie_category(rental) do
        :regular -> calculate_regular(Rental.get_days(rental))
        :new_release -> calculate_new_release(Rental.get_days(rental))
        :childrens -> calculate_childrens(Rental.get_days(rental))
      end
    end

    # 通常映画: 2日まで2.0、以降1日ごとに1.5追加
    defp calculate_regular(days) when days > 2, do: 2.0 + (days - 2) * 1.5
    defp calculate_regular(_days), do: 2.0

    # 新作: 1日ごとに3.0
    defp calculate_new_release(days), do: days * 3.0

    # 子供向け: 3日まで1.5、以降1日ごとに1.5追加
    defp calculate_childrens(days) when days > 3, do: 1.5 + (days - 3) * 1.5
    defp calculate_childrens(_days), do: 1.5

    @doc """
    レンタルポイントを計算する。

    ## Examples

        iex> movie = Chapter17.Movie.new_release("Test")
        iex> rental = Chapter17.Rental.new(movie, 3)
        iex> Chapter17.Pricing.determine_points(rental)
        2
    """
    def determine_points(%Rental{} = rental) do
      case Rental.get_movie_category(rental) do
        :regular -> 1
        :new_release -> if Rental.get_days(rental) > 1, do: 2, else: 1
        :childrens -> 1
      end
    end

    @doc "複数レンタルの合計金額を計算"
    def total_amount(rentals) do
      Enum.sum(Enum.map(rentals, &determine_amount/1))
    end

    @doc "複数レンタルの合計ポイントを計算"
    def total_points(rentals) do
      Enum.sum(Enum.map(rentals, &determine_points/1))
    end
  end

  # ============================================================
  # 4. 明細書生成
  # ============================================================

  defmodule Statement do
    @moduledoc "明細書の生成"

    alias Chapter17.{Rental, Pricing}

    @doc """
    明細書を生成する。

    ## Examples

        iex> movie = Chapter17.Movie.regular("Test")
        iex> rental = Chapter17.Rental.new(movie, 1)
        iex> statement = Chapter17.Statement.make("John", [rental])
        iex> String.contains?(statement, "John")
        true
    """
    def make(customer, rentals, format \\ :text) do
      format_statement(format, customer, rentals)
    end

    @doc "明細データを生成（フォーマット非依存）"
    def statement_data(customer, rentals) do
      %{
        customer: customer,
        rentals: Enum.map(rentals, fn rental ->
          %{
            title: Rental.get_movie_title(rental),
            days: Rental.get_days(rental),
            amount: Pricing.determine_amount(rental),
            points: Pricing.determine_points(rental)
          }
        end),
        total_amount: Pricing.total_amount(rentals),
        total_points: Pricing.total_points(rentals)
      }
    end

    # テキスト形式
    defp format_statement(:text, customer, rentals) do
      header = "Rental Record for #{customer}\n"

      lines = Enum.map(rentals, fn rental ->
        "\t#{Rental.get_movie_title(rental)}\t#{Pricing.determine_amount(rental)}\n"
      end)

      total = Pricing.total_amount(rentals)
      points = Pricing.total_points(rentals)
      footer = "Amount owed is #{total}\nYou earned #{points} frequent renter points"

      header <> Enum.join(lines, "") <> footer
    end

    # HTML形式
    defp format_statement(:html, customer, rentals) do
      header = "<h1>Rental Record for <em>#{customer}</em></h1>\n<ul>\n"

      lines = Enum.map(rentals, fn rental ->
        "  <li>#{Rental.get_movie_title(rental)} - #{Pricing.determine_amount(rental)}</li>\n"
      end)

      total = Pricing.total_amount(rentals)
      points = Pricing.total_points(rentals)
      footer = "</ul>\n<p>Amount owed is <strong>#{total}</strong></p>\n" <>
               "<p>You earned <strong>#{points}</strong> frequent renter points</p>"

      header <> Enum.join(lines, "") <> footer
    end
  end

  # ============================================================
  # 5. 顧客モデル
  # ============================================================

  defmodule Customer do
    @moduledoc "顧客の構造体"

    defstruct [:name, rentals: []]

    @type t :: %__MODULE__{
      name: String.t(),
      rentals: [Rental.t()]
    }

    alias Chapter17.{Rental, Statement}

    def new(name), do: %__MODULE__{name: name}

    def add_rental(%__MODULE__{rentals: rentals} = customer, %Rental{} = rental) do
      %{customer | rentals: rentals ++ [rental]}
    end

    def statement(%__MODULE__{name: name, rentals: rentals}) do
      Statement.make(name, rentals)
    end

    def html_statement(%__MODULE__{name: name, rentals: rentals}) do
      Statement.make(name, rentals, :html)
    end
  end

  # ============================================================
  # 6. リポジトリ
  # ============================================================

  defmodule MovieRepository do
    @moduledoc "映画リポジトリ（Agent ベース）"

    alias Chapter17.Movie

    def start_link do
      Agent.start_link(fn -> %{} end)
    end

    def stop(pid) do
      if Process.alive?(pid) do
        Agent.stop(pid)
      else
        :ok
      end
    end

    def add(pid, %Movie{} = movie) do
      Agent.update(pid, &Map.put(&1, movie.title, movie))
      {:ok, movie}
    end

    def get(pid, title) do
      case Agent.get(pid, &Map.get(&1, title)) do
        nil -> {:error, :not_found}
        movie -> {:ok, movie}
      end
    end

    def get_all(pid) do
      Agent.get(pid, &Map.values(&1))
    end

    def find_by_category(pid, category) do
      Agent.get(pid, fn movies ->
        movies
        |> Map.values()
        |> Enum.filter(&(&1.category == category))
      end)
    end
  end

  # ============================================================
  # 7. サービス層
  # ============================================================

  defmodule RentalService do
    @moduledoc "レンタルサービス"

    alias Chapter17.{Movie, Rental, Customer, MovieRepository, Statement}

    defstruct [:movie_repo, customers: %{}]

    def new do
      {:ok, repo} = MovieRepository.start_link()
      %__MODULE__{movie_repo: repo}
    end

    def stop(%__MODULE__{movie_repo: repo}) do
      MovieRepository.stop(repo)
    end

    # 映画管理
    def add_movie(service, title, category) do
      movie = Movie.new(title, category)
      MovieRepository.add(service.movie_repo, movie)
      service
    end

    def get_movie(service, title) do
      MovieRepository.get(service.movie_repo, title)
    end

    def list_movies(service) do
      MovieRepository.get_all(service.movie_repo)
    end

    # 顧客管理
    def add_customer(%__MODULE__{customers: customers} = service, name) do
      customer = Customer.new(name)
      %{service | customers: Map.put(customers, name, customer)}
    end

    def get_customer(%__MODULE__{customers: customers}, name) do
      case Map.get(customers, name) do
        nil -> {:error, :not_found}
        customer -> {:ok, customer}
      end
    end

    # レンタル
    def rent_movie(%__MODULE__{customers: customers} = service, customer_name, movie_title, days) do
      with {:ok, movie} <- get_movie(service, movie_title),
           {:ok, customer} <- get_customer(service, customer_name) do
        rental = Rental.new(movie, days)
        updated_customer = Customer.add_rental(customer, rental)
        {:ok, %{service | customers: Map.put(customers, customer_name, updated_customer)}}
      end
    end

    # 明細書
    def generate_statement(service, customer_name, format \\ :text) do
      case get_customer(service, customer_name) do
        {:ok, %Customer{name: name, rentals: rentals}} ->
          {:ok, Statement.make(name, rentals, format)}
        error ->
          error
      end
    end

    def get_statement_data(service, customer_name) do
      case get_customer(service, customer_name) do
        {:ok, %Customer{name: name, rentals: rentals}} ->
          {:ok, Statement.statement_data(name, rentals)}
        error ->
          error
      end
    end
  end
end
