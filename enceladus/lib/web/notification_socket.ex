defmodule Saturn.NotificationSocket do
  @moduledoc """
  A logged-in person's websocket (GET /ws). It receives what `Saturn.Realtime` broadcasts to them
  (new notifications, and "notifications_read" from their other tabs) as JSON text frames
  `{"event": ..., "data": ...}`. The client sends "ping" every so often, answered with "pong", which
  keeps proxies from closing an idle connection.
  """
  @behaviour WebSock

  alias Saturn.{Realtime, Session, Users}

  # How often an open socket records the person as still here, and checks they're still logged in
  @check_interval_ms 5 * 60 * 1000

  @impl true
  def init(%{user_id: user_id} = state) do
    Realtime.register(user_id)
    Users.touch_last_seen(user_id)
    schedule_check()
    {:ok, state}
  end

  @impl true
  def handle_in({"ping", [opcode: :text]}, state), do: {:push, {:text, "pong"}, state}
  def handle_in(_frame, state), do: {:ok, state}

  @impl true
  def handle_info({:realtime, json}, state), do: {:push, {:text, json}, state}

  def handle_info(:check, %{session_id: session_id, user_id: user_id} = state) do
    case Session.get_by_id(session_id) do
      %Session{user_id: ^user_id} ->
        Users.touch_last_seen(user_id)
        schedule_check()
        {:ok, state}

      # Logged out (or the account was deleted) since it connected
      _ ->
        {:stop, :normal, 4001, state}
    end
  end

  def handle_info(_message, state), do: {:ok, state}

  @impl true
  def terminate(_reason, _state), do: :ok

  defp schedule_check(), do: Process.send_after(self(), :check, @check_interval_ms)
end
