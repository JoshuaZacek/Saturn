defmodule Saturn.DataCase do
  @moduledoc "A test that uses the database, each inside a transaction that's rolled back after."
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto.Query
      import Saturn.Factory
      alias Saturn.Repo
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Saturn.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
