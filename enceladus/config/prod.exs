import Config

config :saturn, Saturn.Repo,
  ssl: true,
  url: System.get_env("DATABASE_URL"),
  pool_size: 10,
  migration_timestamps: [type: :utc_datetime]
