defmodule Saturn.Router do
  use Plug.Router
  alias Saturn.AuthRouter

  plug(Plug.Logger)
  plug(Corsica, origins: "http://localhost:8080", allow_headers: :all, allow_credentials: true)
  plug(:fetch_cookies)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded, :multipart], json_decoder: Jason)
  plug(Saturn.SessionPlug)
  plug(:dispatch)

  # AUTHENTICATION
  post "/login" do
    case conn.params do
      %{"email" => email, "password" => password} ->
        case Saturn.Accounts.login(email, password) do
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
        case Saturn.Accounts.register(username, email, password) do
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

  # POSTS
  # Get posts
  get "/posts/:moon" do
    moon_id =
      if moon != "all" do
        case Saturn.Moons.get(moon) do
          nil ->
            {:error, :not_found}

          moon ->
            moon.id
        end
      else
        nil
      end

    session = Saturn.Session.get_by_id(conn.req_cookies["session_id"])
    user_id = if session, do: session.user.id, else: nil

    if moon_id == {:error, :not_found} do
      send_resp(conn, 404, "Moon not found")
    else
      case conn.params["sort"] do
        "new" ->
          case Saturn.Posts.get_new(
                 parse_int(conn.params["limit"]),
                 parse_cursor(conn.params["cursor"]),
                 user_id,
                 moon_id
               ) do
            {:ok, posts} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(200, Jason.encode!(posts))

            {:error, :bad_request} ->
              send_resp(conn, 400, "Bad request")
          end

        "top" ->
          Saturn.Moons.get(moon)

          case Saturn.Posts.get_top(
                 parse_int(conn.params["limit"]),
                 parse_cursor(conn.params["cursor"]),
                 user_id,
                 moon_id,
                 parse_int(conn.params["time"])
               ) do
            {:ok, posts} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(200, Jason.encode!(posts))

            {:error, :bad_request} ->
              send_resp(conn, 400, "Bad request")
          end
      end
    end
  end

  # get a post by it's id
  get "/post/:id" do
    user_id =
      case Saturn.Session.get_by_id(conn.req_cookies["session_id"]) do
        nil ->
          nil

        session ->
          session.user.id
      end

    case Saturn.Posts.get_by_id(id, user_id) do
      nil ->
        send_resp(conn, 404, "Not found")

      post ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(post))
    end
  end

  # MOONS
  # search for a moon
  get "/moon/search/:name" do
    case Saturn.Moons.search(name) do
      results ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(Map.drop(results, [:posts, :user, :__meta__, :__struct__, :user_id]))
        )
    end
  end

  # check if moon exists/get info about moon
  get "/moon/:name" do
    case Saturn.Moons.get(name) do
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

  # FILES
  # serve files
  get "/assets/:filename" do
    case Saturn.Files.get(filename) do
      nil ->
        send_resp(conn, 404, "File not found")

      file ->
        send_file(conn, 200, file)
    end
  end

  # COMMENTS
  # get comments for a post
  get "/comments" do
    case Saturn.Comments.get(conn.params, conn.assigns.user_id) do
      {:ok, comments} ->
        send_resp(conn, 200, Jason.encode!(comments))
    end
  end

  # get a single comment by it's id
  get "/comments/:id" do
    case Saturn.Comments.get_by_id(id, conn.assigns.user_id) do
      nil ->
        send_resp(conn, 404, "Not found")

      comment ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(comment)
        )
    end
  end

  # PROFILES
  # Get user details by username
  get "/user/:username" do
    case Saturn.Accounts.get(username) do
      nil ->
        send_resp(conn, 404, "Not found")

      user ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(user)
        )
    end
  end

  # Get a user's posts
  get "/profile/:user_id/posts" do
    case Saturn.Profiles.get_posts(
           parse_int(user_id),
           conn.assigns.user_id,
           conn.params["sort"],
           parse_cursor(conn.params["cursor"]),
           parse_int(conn.params["limit"])
         ) do
      {:ok, posts} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(posts)
        )
    end
  end

  # Get a user's comments
  get "/profile/:user_id/comments" do
    case Saturn.Profiles.get_comments(
           parse_int(user_id),
           conn.assigns.user_id,
           conn.params["sort"],
           parse_cursor(conn.params["cursor"]),
           parse_int(conn.params["limit"])
         ) do
      {:ok, comments} ->
        comments = %{
          next_cursor: comments.next_cursor,
          content:
            Enum.map(comments.content, fn comment ->
              Map.drop(comment, [
                :__meta__,
                :__struct__,
                :post_id,
                :user_id,
                :comment_id,
                :comment
              ])
            end)
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(comments)
        )
    end
  end

  # Get at user's overview
  get "/profile/:user_id/overview" do
    case Saturn.Profiles.overview(
           parse_int(user_id),
           conn.assigns.user_id,
           conn.params["sort"],
           parse_cursor(conn.params["cursor"]),
           parse_int(conn.params["limit"])
         ) do
      {:ok, overview} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(overview)
        )
    end
  end

  forward("/", to: AuthRouter)

  defp parse_int(num) do
    case Integer.parse(num || "") do
      {int, ""} -> int
      :error -> num
    end
  end

  defp parse_cursor(cursor) do
    try do
      cursor
      |> Base.url_decode64!()
      |> Jason.decode!()
    rescue
      _ -> cursor
    end
  end
end
