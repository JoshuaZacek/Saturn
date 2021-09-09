use Mix.Config

config :saturn, ecto_repos: [Saturn.Repo]

config :saturn, Saturn.Repo,
  database: "saturn",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432
