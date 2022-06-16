defmodule Saturn.AuthRequiredPlug do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _) do
    case conn.assigns.session do
      nil ->
        conn
        |> send_resp(403, "Unauthorized")
        |> halt()

      _ ->
        conn
    end
  end
end
