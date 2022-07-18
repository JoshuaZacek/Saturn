import Config

config :saturn, ecto_repos: [Saturn.Repo]

import_config "#{System.get_env("MIX_ENV") || "dev"}.exs"
