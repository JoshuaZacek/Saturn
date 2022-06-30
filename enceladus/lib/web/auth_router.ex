defmodule Saturn.AuthRouter do
  use Plug.Router
  alias Saturn.Repo

  plug(:match)
  plug(Saturn.AuthRequiredPlug)
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
    case Saturn.Posts.create(conn.params, conn.assigns.user) do
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

  delete "/post/:post_id" do
    case Saturn.Posts.delete(post_id, conn.assigns.user_id) do
      :ok ->
        send_resp(conn, 204, "")

      {:error, :forbidden} ->
        send_resp(conn, 403, "Only the author can delete this post")

      {:error, _} ->
        send_resp(conn, 400, "Bad request")
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

    case Saturn.Votes.create(
           vote,
           conn.params["post_id"],
           conn.params["comment_id"],
           conn.assigns.user.id
         ) do
      :error ->
        send_resp(conn, 400, "Bad request")

      _ ->
        send_resp(conn, 200, "Vote submitted")
    end
  end

  # Delete a vote
  delete "/vote" do
    case Saturn.Votes.delete(
           conn.params["post_id"],
           conn.params["comment_id"],
           conn.assigns.user.id
         ) do
      {1, _} ->
        send_resp(conn, 200, "Downvote removed")

      {0, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  # MOONS
  # Create a moon
  post "/moon" do
    case Saturn.Moons.create(conn.params, conn.assigns.user) do
      {:error, error} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(error))

      _ ->
        send_resp(conn, 200, "Moon created")
    end
  end

  # COMMENTS
  # Create a comment
  post "/comment" do
    case Saturn.Comments.create(conn.params, conn.assigns.user) do
      {:error, error} ->
        send_resp(conn, 400, format_error(error) |> Jason.encode!())

      comment ->
        send_resp(conn, 200, Jason.encode!(comment))
    end
  end

  # ACCOUNTS
  # Change password
  post "/account/password" do
    case conn.params do
      %{"oldPassword" => old_password, "newPassword" => new_password} ->
        case Saturn.Accounts.change_password(
               old_password,
               new_password,
               conn.assigns.user
             ) do
          :ok ->
            send_resp(conn, 204, "")

          {:error, errors} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(errors))
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  # Change email
  post "/account/email" do
    case conn.params do
      %{"email" => email} ->
        case Saturn.Accounts.change_email(
               email,
               conn.assigns.user
             ) do
          :ok ->
            send_resp(conn, 204, "")

          {:error, errors} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(errors))
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/upload" do
    case conn.params do
      %{"file" => file} ->
        Saturn.Files.file_upload(file, conn.assigns.user)
        send_resp(conn, 200, "Image uploaded")

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp format_error(error) do
    Ecto.Changeset.traverse_errors(error, fn {message, options} ->
      Enum.reduce(options, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
