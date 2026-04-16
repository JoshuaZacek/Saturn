import Config

config :saturn, Saturn.Repo,
  database: "saturn",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  migration_timestamps: [type: :utc_datetime],
  pool_size: 50,
  queue_target: 1000,
  queue_interval: 1000

config :logger, level: :warning
