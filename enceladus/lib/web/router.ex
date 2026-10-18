defmodule Saturn.Router do
  use Plug.Router
  import Saturn.Responses
  alias Saturn.{AuthRouter, SessionPlug, Session, Users, Posts, Moons, Comments, Profiles}

  plug(Plug.Logger)

  plug(Corsica,
    origins: System.get_env("CORS_URL") || "*",
    allow_headers: :all,
    allow_credentials: true
  )

  plug(:fetch_cookies)
  plug(:match)
  plug(Plug.Parsers,
    parsers: [
      :json,
      :urlencoded,
      {:multipart, length: 15_000_000}
    ],
    json_decoder: Jason
  )
  plug(SessionPlug)
  plug(:dispatch)

  # /user
  post "/user/login" do
    case conn.params do
      %{"email" => email, "password" => password} ->
        case Users.login(email, password) do
          {:error, error} ->
            send_json(conn, 400, error)

          session ->
            conn
            |> put_resp_cookie("session_id", session.session_id,
              same_site: "Strict",
              max_age: Session.max_age()
            )
            |> send_json(200, session.user)
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/user/create" do
    case conn.params do
      %{"username" => username, "email" => email, "password" => password} ->
        case Users.signup(username, email, password) do
          {:error, error} ->
            send_json(conn, 400, error)

          session ->
            conn
            |> put_resp_cookie("session_id", session.session_id,
              same_site: "Strict",
              max_age: Session.max_age()
            )
            |> send_json(200, session.user)
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  # GET /user/me (the session user) is in AuthRouter
  get "/user/:username" when username != "me" do
    case Users.get_by_username(username) do
      nil ->
        send_resp(conn, 404, "Not found")

      user ->
        send_json(conn, 200, user)
    end
  end

  # /posts
  get "/posts" do
    schema = %{
      limit: [type: :integer, required: true, number: [min: 1, max: 10]],
      sort: [type: :string, required: true, in: ["top", "new"]],
      cursor: [type: :string],
      moon_id: [type: :integer],
      time_period: [type: :integer],
      subscribed: [type: :boolean]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      cond do
        params.subscribed && params.moon_id ->
          send_resp(conn, 400, "Bad request")

        params.subscribed && !conn.assigns.user_id ->
          send_resp(conn, 403, "Unauthorized")

        true ->
          send_json(conn, 200, Posts.get(params, conn.assigns.user_id))
      end
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  get "/post/:id" do
    case Posts.get_by_id(id, conn.assigns.user_id) do
      nil ->
        send_resp(conn, 404, "Not found")

      post ->
        send_json(conn, 200, post)
    end
  end

  # /moon
  get "/moon/search/:name" do
    send_json(conn, 200, Moons.search(name))
  end

  get "/moon/:name" do
    case Moons.get(name, conn.assigns.user_id) do
      nil ->
        send_resp(conn, 404, "Not found")

      moon ->
        send_json(conn, 200, moon)
    end
  end

  # /comments
  get "/comments" do
    schema = %{
      limit: [type: :integer, required: true, number: [min: 1, max: 10]],
      sort: [type: :string, required: true, in: ["top", "new"]],
      cursor: [type: :string],
      parent_comment_id: [type: :integer],
      post_id: [type: :integer]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      send_json(conn, 200, Comments.get(params, conn.assigns.user_id))
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  get "/comments/:id" do
    case Comments.get_by_id(id, conn.assigns.user_id) do
      nil ->
        send_resp(conn, 404, "Not found")

      comment ->
        send_json(conn, 200, comment)
    end
  end

  # /profile
  get "/profile/posts" do
    schema = %{
      limit: [type: :integer, required: true, number: [min: 1, max: 10]],
      sort: [type: :string, required: true, in: ["top", "new"]],
      cursor: [type: :string],
      parent_comment_id: [type: :integer],
      user_id: [type: :integer]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      send_json(conn, 200, Profiles.get_posts(params, conn.assigns.user_id))
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  get "/profile/comments" do
    schema = %{
      limit: [type: :integer, required: true, number: [min: 1, max: 10]],
      sort: [type: :string, required: true, in: ["top", "new"]],
      cursor: [type: :string],
      parent_comment_id: [type: :integer],
      user_id: [type: :integer]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      comments = Profiles.get_comments(params, conn.assigns.user_id)

      send_json(conn, 200, %{
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
      })
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  get "/profile/overview" do
    schema = %{
      limit: [type: :integer, required: true, number: [min: 1, max: 10]],
      sort: [type: :string, required: true, in: ["top", "new"]],
      cursor: [type: :string],
      parent_comment_id: [type: :integer],
      user_id: [type: :integer]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      send_json(conn, 200, Profiles.overview(params, conn.assigns.user_id))
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  # /assets
  get "/assets/:filename" do
    case Saturn.Files.get(filename) do
      nil ->
        send_resp(conn, 404, "File not found")

      {:ok, url} ->
        conn
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      {:error, _reason} ->
        send_resp(conn, 500, "Error fetching file")
    end
  end

  forward("/", to: AuthRouter)
end
