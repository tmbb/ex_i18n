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
      {:ex_cldr_messages, github: "elixir-cldr/cldr_messages"},
      {:jason, "~> 1.1"},
      {:decimal, "~> 2.0", override: true},
      {:ex_cldr_numbers, "~> 2.7"},
      {:ex_cldr_dates_times, "~> 2.2"},
      {:ex_money, "~> 4.0"},
      {:ex_cldr_units, "~> 2.0"},
      {:ex_cldr_lists, "~> 2.3"}
    ]
  end

  defp elixirc_paths(env) when env in [:test, :dev], do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]
end
