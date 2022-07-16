defmodule Saturn.SessionPlug do
  import Plug.Conn
  alias Saturn.Session

  def init(default), do: default

  def call(conn, _) do
    case Session.get_by_id(conn.req_cookies["session_id"]) do
      nil ->
        conn
        |> assign(:session, nil)
        |> assign(:user, nil)
        |> assign(:user_id, nil)

      session ->
        conn
        |> assign(:session, session)
        |> assign(:user, session.user)
        |> assign(:user_id, session.user.id)
    end
  end
end
