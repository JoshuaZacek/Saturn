defmodule Saturn.AuthRouter do
  use Plug.Router
  alias Saturn.Repo

  plug(:match)
  plug(Saturn.AuthPlug)
  plug(:dispatch)

  # AUTHENTICATION
  # Delete session
  delete "/logout" do
    Repo.delete(conn.assigns.session)
    delete_resp_cookie(conn, "session_id")
    send_resp(conn, 204, "")
  end

  # POSTS
  # Create post
  post "/post" do
    case Saturn.Posts.create(conn.params, conn.assigns.session.user) do
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

  # VOTES
  # Upvote/downvote a post
  post "/vote" do
    vote =
      case conn.params["vote"] do
        "up" ->
          1

        "down" ->
          -1
      end

    case Saturn.Votes.create(vote, conn.params["post_id"], conn.assigns.session.user.id) do
      :error ->
        send_resp(conn, 400, "Bad request")

      _ ->
        send_resp(conn, 200, "Vote submitted")
    end
  end

  # Delete a vote
  delete "/vote" do
    case Saturn.Votes.delete(conn.params["post_id"], conn.assigns.session.user.id) do
      {1, _} ->
        send_resp(conn, 200, "Downvote removed")

      {0, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  # MOONS
  # Create a moon
  post "/moon" do
    case Saturn.Moons.create(conn.params, conn.assigns.session.user) do
      {:error, error} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(error))

      _ ->
        send_resp(conn, 200, "Moon created")
    end
  end

  post "/upload" do
    case conn.params do
      %{"file" => file} ->
        Saturn.Files.file_upload(file, conn.assigns.session.user)
        send_resp(conn, 200, "Image uploaded")

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  # test route
  get "/hello" do
    send_resp(conn, 200, "world")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
