defmodule Saturn.Router do
  use Plug.Router
  alias Saturn.{AuthRouter, SessionPlug, Users, Posts, Moons, Comments, Profiles}

  plug(Plug.Logger)

  plug(Corsica,
    origins: System.get_env("CORS_URL") || "*",
    allow_headers: :all,
    allow_credentials: true
  )

  plug(:fetch_cookies)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded, :multipart], json_decoder: Jason)
  plug(SessionPlug)
  plug(:dispatch)

  # /user
  post "/user/login" do
    case conn.params do
      %{"email" => email, "password" => password} ->
        case Users.login(email, password) do
          {:error, error} ->
            send_resp(conn, 400, Jason.encode!(error))

          session ->
            conn
            |> put_resp_cookie("session_id", session.session_id,
              same_site: "Strict",
              max_age: 31_536_000
            )
            |> send_resp(200, Jason.encode!(session.user))
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
            send_resp(conn, 400, Jason.encode!(error))

          session ->
            conn
            |> put_resp_cookie("session_id", session.session_id,
              same_site: "Strict",
              max_age: 31_536_000
            )
            |> send_resp(200, Jason.encode!(session.user))
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  get "/user/:username" do
    case Users.get_by_username(username) do
      nil ->
        send_resp(conn, 404, "Not found")

      user ->
        send_resp(conn, 200, Jason.encode!(user))
    end
  end

  # /posts
  get "/posts" do
    schema = %{
      limit: [type: :integer, required: true, number: [min: 1, max: 10]],
      sort: [type: :string, required: true, in: ["top", "new"]],
      cursor: [type: :string],
      moon_id: [type: :integer],
      time_period: [type: :integer]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      posts = Posts.get(params, conn.assigns.user_id)
      send_resp(conn, 200, Jason.encode!(posts))
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
        send_resp(conn, 200, Jason.encode!(post))
    end
  end

  # /moon
  get "/moon/search/:name" do
    case Moons.search(name) do
      results ->
        json_results =
          results
          |> Map.drop([:posts, :user, :__meta__, :__struct__, :user_id])
          |> Jason.encode!()

        send_resp(conn, 200, json_results)
    end
  end

  get "/moon/:name" do
    case Moons.get(name) do
      nil ->
        send_resp(conn, 404, "Not found")

      moon ->
        json_moon =
          moon
          |> Map.drop([:posts, :user, :__meta__, :__struct__, :user_id])
          |> Jason.encode!()

        send_resp(conn, 200, json_moon)
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
      comments = Comments.get(params, conn.assigns.user_id)
      send_resp(conn, 200, Jason.encode!(comments))
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
        send_resp(conn, 200, Jason.encode!(comment))
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
      posts = Profiles.get_posts(params, conn.assigns.user_id)
      send_resp(conn, 200, Jason.encode!(posts))
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

      json_comments =
        %{
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
        |> Jason.encode!()

      send_resp(conn, 200, json_comments)
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
      overview = Profiles.overview(params, conn.assigns.user_id)
      send_resp(conn, 200, Jason.encode!(overview))
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

      file ->
        send_file(conn, 200, file)
    end
  end

  forward("/", to: AuthRouter)
end
