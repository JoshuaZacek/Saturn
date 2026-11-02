import Config

config :saturn, ecto_repos: [Saturn.Repo]

config :saturn, Saturn.Files,
	s3_bucket: System.get_env("S3_BUCKET"),
	s3_region: System.get_env("AWS_REGION") || "us-east-1",
	s3_signed_url_ttl: String.to_integer(System.get_env("S3_SIGNED_URL_TTL") || "3600")

config :ex_aws,
	region: System.get_env("AWS_REGION") || "us-east-1"

# MIX_ENV is read at runtime because the app loads it from .env (see Saturn.Application). Under
# `mix test`, though, .env's MIX_ENV must never win, or the tests would run on the dev database.
env = if Mix.env() == :test, do: "test", else: System.get_env("MIX_ENV") || "dev"
import_config "#{env}.exs"
