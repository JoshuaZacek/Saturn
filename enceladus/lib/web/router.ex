defmodule Saturn.Router do
  use Plug.Router
  alias Saturn.Accounts
  alias Saturn.Posts
  alias Saturn.Session
  alias Saturn.Moons

  plug(Plug.Logger)
  plug(Corsica, origins: "http://localhost:8080", allow_headers: :all, allow_credentials: true)
  plug(:fetch_cookies)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded, :multipart], json_decoder: Jason)
  plug(:dispatch)

  # ========= AUTHENTICATION =========
  post "/login" do
    case conn.params do
      %{"email" => email, "password" => password} ->
        case Accounts.login(email, password) do
          {:error, message} ->
            send_resp(conn, 401, Jason.encode!(message))

          session ->
            conn
            |> put_resp_cookie("session_id", session.session_id, same_site: "Strict")
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(session.user))
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/signup" do
    case conn.params do
      %{"username" => username, "email" => email, "password" => password} ->
        case Accounts.register(username, email, password) do
          {:error, message} ->
            send_resp(conn, 401, Jason.encode!(message))

          session ->
            conn
            |> put_resp_cookie("session_id", session.session_id, same_site: "Strict")
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(session.user))
        end

      _ ->
        send_resp(conn, 400, "Bad request")
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

  # Create post
  post "/post" do
    case Session.get_by_id(conn.req_cookies["session_id"]) do
      nil ->
        send_resp(conn, 403, "Invalid session id")

      session ->
        case Posts.create(conn.params, session.user) do
          {:error, error} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(error))

          post ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(post))
        end
    end
  end

  # ========= MOONS =========
  # Create moon
  post "/moon" do
    case Session.get_by_id(conn.req_cookies["session_id"]) do
      nil ->
        send_resp(conn, 403, "Invalid session id")

      session ->
        case Moons.create(conn.params, session.user) do
          {:error, error} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(error))

          moon ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(moon))
        end
    end
  end

  get "/moon/search/:name" do
    case Moons.search(name) do
      results ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(Map.drop(results, [:posts, :user, :__meta__, :__struct__, :user_id]))
        )
    end
  end

  # Find moon
  get "/moon/:name" do
    case Moons.get(name) do
      nil ->
        send_resp(conn, 404, "Not found")

      moon ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(Map.drop(moon, [:posts, :user, :__meta__, :__struct__, :user_id]))
        )
    end
  end

  # Get posts in a moon
  get "/moon/:name/posts" do
    moon =
      if name != "all" do
        case Moons.get(name) do
          nil ->
            {:error, :not_found}

          moon ->
            moon.id
        end
      else
        nil
      end

    case moon do
      {:error, :not_found} ->
        send_resp(conn, 404, "Not found")

      _ ->
        case conn.query_params["sort"] do
          "new" ->
            case Moons.get_new_posts(
                   parse_int(conn.query_params["limit"]),
                   parse_int(conn.query_params["cursor"]),
                   moon
                 ) do
              {:ok, posts} ->
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(200, Jason.encode!(posts))

              {:error, :limit_too_high} ->
                send_resp(conn, 400, "Limit can't be above 50")

              {:error, :bad_request} ->
                send_resp(conn, 400, "Bad request")
            end

          _ ->
            send_resp(conn, 400, "Bad request")
        end
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp parse_int(num) do
    case Integer.parse(num || "") do
      {int, ""} -> int
      :error -> num
    end
  end
end
