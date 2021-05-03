defmodule I18n.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_i18n,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {I18n.Application, []},
      extra_applications: [:logger, :mnesia]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_cldr, "~> 2.0"},
      {:ex_cldr_messages, "~> 0.10"},

      # Tests and benchmarks
      {:stream_data, "~> 0.5.0", only: [:dev, :test]},
      {:benchee, "~> 1.0", only: [:dev, :test]},
      {:benchee_markdown, "~> 0.2", only: [:dev, :test]}
    ]
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "ex_i18n",
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tmbb/ex_i18n"}
    ]
  end

  defp elixirc_paths(env) when env in [:test, :dev], do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]
end
