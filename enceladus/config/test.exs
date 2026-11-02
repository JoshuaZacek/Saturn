import Config

config :saturn, Saturn.Repo,
  database: "saturn_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  migration_timestamps: [type: :utc_datetime]

config :saturn, server: false

config :logger, level: :warning
