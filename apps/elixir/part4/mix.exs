defmodule FunctionalDesignPart4.MixProject do
  use Mix.Project

  def project do
    [
      app: :functional_design_part4,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:stream_data, "~> 1.0", only: :test}
    ]
  end
end
