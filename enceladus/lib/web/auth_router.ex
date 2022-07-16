defmodule Saturn.AuthRouter do
  use Plug.Router
  alias Saturn.{Repo, Posts, Votes, Moons, Comments, Users}

  plug(:match)
  plug(Saturn.AuthRequiredPlug)
  plug(:dispatch)

  post "/post" do
    case Posts.create(conn.params, conn.assigns.user) do
      {:error, :file_not_supported} ->
        send_resp(conn, 400, "File type not supported")

      {:error, error} ->
        send_resp(conn, 400, Jason.encode!(error))

      post ->
        send_resp(conn, 200, Jason.encode!(post))
    end
  end

  delete "/post/:post_id" do
    case Posts.delete(post_id, conn.assigns.user_id) do
      :ok ->
        send_resp(conn, 204, "")

      {:error, :forbidden} ->
        send_resp(conn, 403, "Only the author can delete this post")

      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/vote" do
    case Votes.create(conn.params, conn.assigns.user_id) do
      :error ->
        send_resp(conn, 400, "Bad request")

      :ok ->
        send_resp(conn, 200, "Vote submitted")
    end
  end

  delete "/vote" do
    schema = %{
      post_id: [type: :integer, required: if(conn.params["comment_id"], do: false, else: true)],
      comment_id: [type: :integer, required: if(conn.params["post_id"], do: false, else: true)]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      case Votes.delete(params, conn.assigns.user.id) do
        {1, _} ->
          send_resp(conn, 200, "Downvote removed")

        {0, _} ->
          send_resp(conn, 400, "Bad request")
      end
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/moon" do
    case Moons.create(conn.params, conn.assigns.user) do
      {:error, error} ->
        send_resp(conn, 400, Jason.encode!(error))

      _ ->
        send_resp(conn, 200, "Moon created")
    end
  end

  post "/comment" do
    case Comments.create(conn.params, conn.assigns.user) do
      {:error, error} ->
        send_resp(conn, 400, Jason.encode!(error))

      comment ->
        send_resp(conn, 200, Jason.encode!(comment))
    end
  end

  post "/user/password" do
    case conn.params do
      %{"oldpassword" => old_password, "newpassword" => new_password} ->
        case Users.change_password(old_password, new_password, conn.assigns.user) do
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

  post "/user/email" do
    case conn.params do
      %{"newemail" => new_email} ->
        case Users.change_email(new_email, conn.assigns.user) do
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

  delete "/user/logout" do
    Repo.delete(conn.assigns.session)
    delete_resp_cookie(conn, "session_id")
    send_resp(conn, 204, "")
  end

  delete "/user" do
    Repo.delete!(conn.assigns.user)
    delete_resp_cookie(conn, "session_id")
    send_resp(conn, 204, "")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
