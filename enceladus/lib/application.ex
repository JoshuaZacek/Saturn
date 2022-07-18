defmodule Saturn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Dotenv.load()
    Mix.Task.run("loadconfig")

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Saturn.Router,
        options: [port: String.to_integer(System.get_env("PORT") || "4000")]
      ),
      Saturn.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Saturn.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
