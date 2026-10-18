defmodule Saturn.AuthRouter do
  use Plug.Router
  import Saturn.Responses
  alias Saturn.{Repo, Posts, Votes, Moons, Comments, Users, Subscriptions}

  plug(:match)
  # Every route here needs a session. As a plug (not a call inside the route), its halt stops
  # the request before the route body runs.
  plug(Saturn.AuthRequiredPlug)
  plug(:dispatch)

  post "/post" do
    case Posts.create(conn.params, conn.assigns.user) do
      {:error, :file_not_supported} ->
        send_json(conn, 400, %{errors: %{file: ["File type not supported"]}})

      {:error, :missing_s3_config} ->
        send_json(conn, 503, %{errors: %{file: ["Image storage is not configured"]}})

      {:error, :upload_failed} ->
        send_json(conn, 502, %{errors: %{file: ["Image upload failed"]}})

      {:error, error} ->
        send_json(conn, 400, error)

      post ->
        send_json(conn, 200, post)
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
      Votes.delete(params, conn.assigns.user_id)
      send_resp(conn, 200, "Downvote removed")
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/moon" do
    schema = %{
      name: [type: :string, length: [max: 20]]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      case Moons.create(params, conn.assigns.user) do
        {:error, error} ->
          send_json(conn, 400, error)

        _ ->
          send_resp(conn, 200, "Moon created")
      end
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/comment" do
    case Comments.create(conn.params, conn.assigns.user) do
      {:error, error} ->
        send_json(conn, 400, error)

      comment ->
        send_json(conn, 200, comment)
    end
  end

  post "/subscription" do
    schema = %{
      moon_id: [type: :integer, required: true]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      case Subscriptions.create(params, conn.assigns.user_id) do
        :ok ->
          send_json(conn, 200, %{moon_id: params.moon_id, subscribed: true})

        {:error, error} ->
          send_json(conn, 400, error)
      end
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  delete "/subscription" do
    schema = %{
      moon_id: [type: :integer, required: true]
    }

    with {:ok, params} <- Tarams.cast(conn.params, schema) do
      Subscriptions.delete(params, conn.assigns.user_id)
      send_json(conn, 200, %{moon_id: params.moon_id, subscribed: false})
    else
      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  get "/subscriptions" do
    send_json(conn, 200, Subscriptions.get(conn.assigns.user_id))
  end

  get "/user/me" do
    send_json(conn, 200, Users.session_user(conn.assigns.user))
  end

  post "/user/password" do
    case conn.params do
      %{"oldpassword" => old_password, "newpassword" => new_password} ->
        case Users.change_password(old_password, new_password, conn.assigns.user) do
          :ok ->
            send_resp(conn, 204, "")

          {:error, errors} ->
            send_json(conn, 400, errors)
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
            send_json(conn, 400, errors)
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  delete "/user/logout" do
    Repo.delete(conn.assigns.session)

    conn
    |> delete_resp_cookie("session_id")
    |> send_resp(204, "")
  end

  delete "/user" do
    Repo.delete!(conn.assigns.user)

    conn
    |> delete_resp_cookie("session_id")
    |> send_resp(204, "")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
