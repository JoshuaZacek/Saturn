defmodule Saturn.AuthPlug do
  import Plug.Conn
  alias Saturn.Session

  def init(default), do: default

  def call(conn, _) do
    case Session.get_by_id(conn.req_cookies["session_id"]) do
      nil ->
        conn
        |> send_resp(403, "Unauthorized")
        |> halt()

      session ->
        conn
        |> assign(:session, session)
        |> assign(:user, session.user)
    end
  end
end
