defmodule Saturn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Dotenv.load()
    Mix.Task.run("loadconfig")

    # The server starts last, so a request never arrives before what it needs
    children = [Saturn.Repo, Saturn.Realtime] ++ server()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Saturn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Not under `mix test` (config/test.exs), where it would clash with a running dev server
  defp server() do
    if Application.get_env(:saturn, :server, true) do
      [
        Plug.Cowboy.child_spec(
          scheme: :http,
          plug: Saturn.Router,
          options: [port: String.to_integer(System.get_env("PORT") || "4000")]
        )
      ]
    else
      []
    end
  end
end
