defmodule Saturn.Realtime do
  @moduledoc """
  Pushes events to a person's open websockets (`Saturn.NotificationSocket`). Each socket registers
  itself under its user's id, so one person with several tabs gets the event in each.
  """

  @registry Saturn.Realtime.Registry

  def child_spec(_), do: Registry.child_spec(keys: :duplicate, name: @registry)

  def register(user_id), do: Registry.register(@registry, user_id, nil)

  def broadcast(user_id, event, payload) do
    message = {:realtime, Jason.encode!(%{event: event, data: payload})}

    Registry.dispatch(@registry, user_id, fn sockets ->
      for {pid, _} <- sockets, do: send(pid, message)
    end)
  end
end
