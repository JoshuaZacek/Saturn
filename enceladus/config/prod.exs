import Config

config :saturn, Saturn.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 10,
  migration_timestamps: [type: :utc_datetime]
