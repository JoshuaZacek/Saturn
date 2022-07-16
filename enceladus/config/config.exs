import Config

config :saturn, frontend_url: "*"

config :saturn, ecto_repos: [Saturn.Repo]

config :saturn, Saturn.Repo,
  database: "saturn",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  migration_timestamps: [type: :utc_datetime]
