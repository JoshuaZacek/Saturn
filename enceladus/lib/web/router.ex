defmodule Saturn.Router do
  use Plug.Router
  alias Saturn.Accounts

  plug(Plug.Logger)
  plug(Corsica, origins: "http://localhost:8080", allow_headers: :all, allow_credentials: true)
  plug(:fetch_cookies)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded, :multipart], json_decoder: Poison)
  plug(:dispatch)

  post "/login" do
    case conn.params do
      %{"email" => email, "password" => password} ->
        case Accounts.login(email, password) do
          {:ok, session} ->
            user =
              session.user
              |> Map.from_struct()
              |> Map.drop([:__meta__, :sessions, :password, :updated_at])
              |> Poison.encode!()

            conn
            |> put_resp_cookie("session_id", session.session_id, same_site: "Strict")
            |> put_resp_content_type("application/json")
            |> send_resp(200, user)

          {:error, message} ->
            send_resp(conn, 401, Poison.encode!(message))
        end

      _ ->
        send_resp(conn, 400, "Missing parameters")
    end
  end

  post "/signup" do
    case conn.params do
      %{"username" => username, "email" => email, "password" => password} ->
        case Accounts.register(username, email, password) do
          {:ok, session} ->
            user =
              session.user
              |> Map.from_struct()
              |> Map.drop([:__meta__, :sessions, :password, :updated_at])
              |> Poison.encode!()

            conn
            |> put_resp_cookie("session_id", session.session_id, same_site: "Strict")
            |> put_resp_content_type("application/json")
            |> send_resp(200, user)

          {:error, message} ->
            send_resp(conn, 401, Poison.encode!(message))
        end

      _ ->
        send_resp(conn, 400, "Missing parameters")
    end
  end

  delete "/logout" do
    case Accounts.logout(conn) do
      {:error, :not_found} ->
        send_resp(conn, 400, "No Session Cookie found")

      _ ->
        delete_resp_cookie(conn, "session_id")
        send_resp(conn, 204, "")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
