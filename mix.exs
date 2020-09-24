defmodule Mezzofanti.MixProject do
  use Mix.Project

  def project do
    [
      app: :mezzofanti,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 0.5"},
      {:jason, "~> 1.1"},
      {:decimal, "~> 2.0", override: true},
      {:ex_cldr, github: "elixir-cldr/cldr", branch: "cldr38", override: true},
      {:ex_cldr_messages, "~> 0.5.0"},
      {:ex_cldr_numbers, "~> 2.7"},
      {:ex_cldr_dates_times, "~> 2.2"},
      {:ex_money, "~> 4.0 or ~> 5.0"},
      {:ex_cldr_units, "~> 2.0 or ~> 3.0"},
      {:ex_cldr_lists, "~> 2.3"},
      {:stream_data, "~> 0.5.0", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(env) when env in [:test, :dev], do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]
end
