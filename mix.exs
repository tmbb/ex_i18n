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
    [{:nimble_parsec, "~> 0.5.0"}]
  end

  defp elixirc_paths(env) when env in [:test, :dev], do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]
end
