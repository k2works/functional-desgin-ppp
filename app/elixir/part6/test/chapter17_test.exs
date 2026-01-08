defmodule Chapter17Test do
  use ExUnit.Case, async: false
  doctest Chapter17

  alias Chapter17.{Movie, Rental, Pricing, Statement, Customer, MovieRepository, RentalService}

  # ============================================================
  # Movie Tests
  # ============================================================

  describe "Movie" do
    test "new/2 creates a movie with title and category" do
      movie = Movie.new("The Matrix", :new_release)
      assert movie.title == "The Matrix"
      assert movie.category == :new_release
    end

    test "regular/1 creates a regular movie" do
      movie = Movie.regular("Casablanca")
      assert Movie.get_category(movie) == :regular
    end

    test "new_release/1 creates a new release movie" do
      movie = Movie.new_release("Dune")
      assert Movie.get_category(movie) == :new_release
    end

    test "childrens/1 creates a children's movie" do
      movie = Movie.childrens("Frozen")
      assert Movie.get_category(movie) == :childrens
    end
  end

  # ============================================================
  # Rental Tests
  # ============================================================

  describe "Rental" do
    test "new/2 creates a rental with movie and days" do
      movie = Movie.regular("Test")
      rental = Rental.new(movie, 3)

      assert Rental.get_movie(rental) == movie
      assert Rental.get_days(rental) == 3
    end

    test "get_movie_title/1 returns the movie title" do
      movie = Movie.regular("Test Movie")
      rental = Rental.new(movie, 1)

      assert Rental.get_movie_title(rental) == "Test Movie"
    end

    test "get_movie_category/1 returns the movie category" do
      movie = Movie.new_release("New Movie")
      rental = Rental.new(movie, 1)

      assert Rental.get_movie_category(rental) == :new_release
    end
  end

  # ============================================================
  # Pricing Tests
  # ============================================================

  describe "Pricing - Regular Movies" do
    test "2 days or less costs 2.0" do
      movie = Movie.regular("Test")

      assert Pricing.determine_amount(Rental.new(movie, 1)) == 2.0
      assert Pricing.determine_amount(Rental.new(movie, 2)) == 2.0
    end

    test "more than 2 days adds 1.5 per extra day" do
      movie = Movie.regular("Test")

      assert Pricing.determine_amount(Rental.new(movie, 3)) == 3.5
      assert Pricing.determine_amount(Rental.new(movie, 4)) == 5.0
      assert Pricing.determine_amount(Rental.new(movie, 5)) == 6.5
    end

    test "regular movies earn 1 point" do
      movie = Movie.regular("Test")
      rental = Rental.new(movie, 5)

      assert Pricing.determine_points(rental) == 1
    end
  end

  describe "Pricing - New Release Movies" do
    test "costs 3.0 per day" do
      movie = Movie.new_release("Test")

      assert Pricing.determine_amount(Rental.new(movie, 1)) == 3.0
      assert Pricing.determine_amount(Rental.new(movie, 2)) == 6.0
      assert Pricing.determine_amount(Rental.new(movie, 3)) == 9.0
    end

    test "1 day earns 1 point" do
      movie = Movie.new_release("Test")
      rental = Rental.new(movie, 1)

      assert Pricing.determine_points(rental) == 1
    end

    test "more than 1 day earns 2 points" do
      movie = Movie.new_release("Test")

      assert Pricing.determine_points(Rental.new(movie, 2)) == 2
      assert Pricing.determine_points(Rental.new(movie, 3)) == 2
    end
  end

  describe "Pricing - Children's Movies" do
    test "3 days or less costs 1.5" do
      movie = Movie.childrens("Test")

      assert Pricing.determine_amount(Rental.new(movie, 1)) == 1.5
      assert Pricing.determine_amount(Rental.new(movie, 2)) == 1.5
      assert Pricing.determine_amount(Rental.new(movie, 3)) == 1.5
    end

    test "more than 3 days adds 1.5 per extra day" do
      movie = Movie.childrens("Test")

      assert Pricing.determine_amount(Rental.new(movie, 4)) == 3.0
      assert Pricing.determine_amount(Rental.new(movie, 5)) == 4.5
    end

    test "children's movies earn 1 point" do
      movie = Movie.childrens("Test")
      rental = Rental.new(movie, 5)

      assert Pricing.determine_points(rental) == 1
    end
  end

  describe "Pricing - Totals" do
    test "total_amount/1 sums all rental amounts" do
      rentals = [
        Rental.new(Movie.regular("R1"), 3),      # 3.5
        Rental.new(Movie.new_release("N1"), 2),  # 6.0
        Rental.new(Movie.childrens("C1"), 4)     # 3.0
      ]

      assert Pricing.total_amount(rentals) == 12.5
    end

    test "total_points/1 sums all rental points" do
      rentals = [
        Rental.new(Movie.regular("R1"), 3),      # 1
        Rental.new(Movie.new_release("N1"), 2),  # 2
        Rental.new(Movie.childrens("C1"), 4)     # 1
      ]

      assert Pricing.total_points(rentals) == 4
    end
  end

  # ============================================================
  # Statement Tests
  # ============================================================

  describe "Statement - Text Format" do
    test "generates text statement" do
      rentals = [
        Rental.new(Movie.regular("Movie A"), 3),
        Rental.new(Movie.new_release("Movie B"), 1)
      ]

      statement = Statement.make("John", rentals)

      assert String.contains?(statement, "Rental Record for John")
      assert String.contains?(statement, "Movie A")
      assert String.contains?(statement, "Movie B")
      assert String.contains?(statement, "Amount owed is")
      assert String.contains?(statement, "frequent renter points")
    end

    test "calculates correct totals" do
      rentals = [
        Rental.new(Movie.regular("Movie A"), 3)  # 3.5, 1 point
      ]

      statement = Statement.make("John", rentals)

      assert String.contains?(statement, "3.5")
      assert String.contains?(statement, "1 frequent renter points")
    end
  end

  describe "Statement - HTML Format" do
    test "generates HTML statement" do
      rentals = [
        Rental.new(Movie.regular("Movie A"), 3)
      ]

      statement = Statement.make("John", rentals, :html)

      assert String.contains?(statement, "<h1>")
      assert String.contains?(statement, "<em>John</em>")
      assert String.contains?(statement, "<ul>")
      assert String.contains?(statement, "<li>")
      assert String.contains?(statement, "<strong>")
    end
  end

  describe "Statement - Data" do
    test "statement_data/2 returns structured data" do
      rentals = [
        Rental.new(Movie.regular("Movie A"), 3)
      ]

      data = Statement.statement_data("John", rentals)

      assert data.customer == "John"
      assert length(data.rentals) == 1

      [rental_data] = data.rentals
      assert rental_data.title == "Movie A"
      assert rental_data.days == 3
      assert rental_data.amount == 3.5
      assert rental_data.points == 1

      assert data.total_amount == 3.5
      assert data.total_points == 1
    end
  end

  # ============================================================
  # Customer Tests
  # ============================================================

  describe "Customer" do
    test "new/1 creates a customer with name" do
      customer = Customer.new("John")
      assert customer.name == "John"
      assert customer.rentals == []
    end

    test "add_rental/2 adds rental to customer" do
      customer = Customer.new("John")
      rental = Rental.new(Movie.regular("Test"), 3)

      updated = Customer.add_rental(customer, rental)

      assert length(updated.rentals) == 1
    end

    test "statement/1 generates text statement" do
      customer = Customer.new("John")
                 |> Customer.add_rental(Rental.new(Movie.regular("Test"), 3))

      statement = Customer.statement(customer)

      assert String.contains?(statement, "John")
    end

    test "html_statement/1 generates HTML statement" do
      customer = Customer.new("John")
                 |> Customer.add_rental(Rental.new(Movie.regular("Test"), 3))

      statement = Customer.html_statement(customer)

      assert String.contains?(statement, "<h1>")
    end
  end

  # ============================================================
  # MovieRepository Tests
  # ============================================================

  describe "MovieRepository" do
    setup do
      {:ok, repo} = MovieRepository.start_link()
      on_exit(fn -> MovieRepository.stop(repo) end)
      %{repo: repo}
    end

    test "add/2 and get/2 work", %{repo: repo} do
      movie = Movie.regular("Test")
      {:ok, _} = MovieRepository.add(repo, movie)

      assert {:ok, m} = MovieRepository.get(repo, "Test")
      assert m.title == "Test"
    end

    test "get/2 returns error for non-existent movie", %{repo: repo} do
      assert {:error, :not_found} = MovieRepository.get(repo, "NonExistent")
    end

    test "get_all/1 returns all movies", %{repo: repo} do
      MovieRepository.add(repo, Movie.regular("Movie1"))
      MovieRepository.add(repo, Movie.new_release("Movie2"))

      movies = MovieRepository.get_all(repo)
      assert length(movies) == 2
    end

    test "find_by_category/2 filters by category", %{repo: repo} do
      MovieRepository.add(repo, Movie.regular("Regular1"))
      MovieRepository.add(repo, Movie.regular("Regular2"))
      MovieRepository.add(repo, Movie.new_release("New1"))

      regular_movies = MovieRepository.find_by_category(repo, :regular)
      assert length(regular_movies) == 2
    end
  end

  # ============================================================
  # RentalService Tests
  # ============================================================

  describe "RentalService" do
    setup do
      service = RentalService.new()
      on_exit(fn -> RentalService.stop(service) end)
      %{service: service}
    end

    test "add_movie/3 adds movie to repository", %{service: service} do
      service = RentalService.add_movie(service, "Test Movie", :regular)

      assert {:ok, movie} = RentalService.get_movie(service, "Test Movie")
      assert movie.title == "Test Movie"
    end

    test "add_customer/2 adds customer", %{service: service} do
      service = RentalService.add_customer(service, "John")

      assert {:ok, customer} = RentalService.get_customer(service, "John")
      assert customer.name == "John"
    end

    test "rent_movie/4 creates rental for customer", %{service: service} do
      service =
        service
        |> RentalService.add_movie("Test Movie", :regular)
        |> RentalService.add_customer("John")

      {:ok, service} = RentalService.rent_movie(service, "John", "Test Movie", 3)

      {:ok, customer} = RentalService.get_customer(service, "John")
      assert length(customer.rentals) == 1
    end

    test "rent_movie/4 returns error for non-existent movie", %{service: service} do
      service = RentalService.add_customer(service, "John")

      assert {:error, :not_found} = RentalService.rent_movie(service, "John", "NonExistent", 3)
    end

    test "generate_statement/3 generates statement", %{service: service} do
      service =
        service
        |> RentalService.add_movie("Test Movie", :regular)
        |> RentalService.add_customer("John")

      {:ok, service} = RentalService.rent_movie(service, "John", "Test Movie", 3)

      {:ok, statement} = RentalService.generate_statement(service, "John")
      assert String.contains?(statement, "John")
      assert String.contains?(statement, "Test Movie")
    end

    test "get_statement_data/2 returns statement data", %{service: service} do
      service =
        service
        |> RentalService.add_movie("Test Movie", :regular)
        |> RentalService.add_customer("John")

      {:ok, service} = RentalService.rent_movie(service, "John", "Test Movie", 3)

      {:ok, data} = RentalService.get_statement_data(service, "John")
      assert data.customer == "John"
      assert data.total_amount == 3.5
    end
  end

  # ============================================================
  # Integration Tests
  # ============================================================

  describe "Integration" do
    test "complete rental workflow" do
      service = RentalService.new()

      try do
        # Add movies
        service =
          service
          |> RentalService.add_movie("The Matrix", :new_release)
          |> RentalService.add_movie("Casablanca", :regular)
          |> RentalService.add_movie("Frozen", :childrens)

        # Add customer
        service = RentalService.add_customer(service, "Alice")

        # Rent movies
        {:ok, service} = RentalService.rent_movie(service, "Alice", "The Matrix", 3)
        {:ok, service} = RentalService.rent_movie(service, "Alice", "Casablanca", 5)
        {:ok, service} = RentalService.rent_movie(service, "Alice", "Frozen", 4)

        # Generate statement
        {:ok, statement} = RentalService.generate_statement(service, "Alice")

        # Verify
        assert String.contains?(statement, "Alice")
        assert String.contains?(statement, "The Matrix")
        assert String.contains?(statement, "Casablanca")
        assert String.contains?(statement, "Frozen")

        # Get statement data
        {:ok, data} = RentalService.get_statement_data(service, "Alice")

        # The Matrix: 3 * 3.0 = 9.0, 2 points
        # Casablanca: 2.0 + 3 * 1.5 = 6.5, 1 point
        # Frozen: 1.5 + 1 * 1.5 = 3.0, 1 point
        # Total: 18.5, 4 points
        assert data.total_amount == 18.5
        assert data.total_points == 4
      after
        RentalService.stop(service)
      end
    end
  end
end
