defmodule Saturn.MixProject do
  use Mix.Project

  def project do
    [
      app: :saturn,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: System.get_env("MIX_ENV") == "prod",
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
      {:plug_cowboy, "~> 2.8"},
      {:jason, "~> 1.2"},
      {:postgrex, "~> 0.19"},
      {:ecto_sql, "~> 3.13"},
      {:argon2_elixir, "~> 2.0"},
      {:corsica, "~> 1.1.3"},
      {:tarams, "~> 1.6"},
      {:dotenv, "~> 3.0.0"}
    ]
  end
end
