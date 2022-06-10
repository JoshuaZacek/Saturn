defmodule Saturn.MixProject do
  use Mix.Project

  def project do
    [
      app: :saturn,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Saturn.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.2"},
      {:postgrex, "~> 0.15.1"},
      {:ecto_sql, "~> 3.7.0"},
      {:argon2_elixir, "~> 2.0"},
      {:corsica, "~> 1.1.3"}
    ]
  end
end
