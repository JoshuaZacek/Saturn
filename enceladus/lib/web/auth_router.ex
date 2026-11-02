defmodule Saturn.AuthRouter do
  use Plug.Router
  import Saturn.Responses
  import Saturn.Functions
  alias Saturn.{Repo, Posts, Votes, Moons, Comments, Users, Subscriptions, Avatars, Notifications}

  plug(:match)
  # Every route here needs a session. As a plug (not a call inside the route), its halt stops
  # the request before the route body runs.
  plug(Saturn.AuthRequiredPlug)
  plug(:dispatch)

  post "/post" do
    case Posts.create(conn.params, conn.assigns.user) do
      {:error, :file_not_supported} ->
        send_json(conn, 400, %{errors: %{file: ["File type not supported"]}})

      {:error, :missing_file} ->
        send_json(conn, 400, %{errors: %{file: ["File can't be blank"]}})

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

  patch "/post/:post_id" do
    with {:ok, params} <- Tarams.cast(conn.path_params, %{post_id: id_param(required: true)}),
         {:ok, post} <- Posts.edit(params.post_id, conn.body_params, conn.assigns.user) do
      send_json(conn, 200, post)
    else
      {:error, :forbidden} -> send_resp(conn, 403, "Only the author can edit this post")
      {:error, :not_found} -> send_resp(conn, 404, "Not found")
      {:error, %{errors: _} = error} -> send_json(conn, 400, error)
      {:error, _} -> send_resp(conn, 400, "Bad request")
    end
  end

  delete "/post/:post_id" do
    with {:ok, params} <- Tarams.cast(conn.path_params, %{post_id: id_param(required: true)}),
         :ok <- Posts.delete(params.post_id, conn.assigns.user_id) do
      send_resp(conn, 204, "")
    else
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
      post_id: id_param(required: if(conn.params["comment_id"], do: false, else: true)),
      comment_id: id_param(required: if(conn.params["post_id"], do: false, else: true))
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

  patch "/comment/:id" do
    with {:ok, params} <- Tarams.cast(conn.path_params, %{id: id_param(required: true)}),
         {:ok, comment} <- Comments.edit(params.id, conn.body_params, conn.assigns.user) do
      send_json(conn, 200, comment)
    else
      {:error, :forbidden} -> send_resp(conn, 403, "Only the author can edit this comment")
      {:error, :not_found} -> send_resp(conn, 404, "Not found")
      {:error, %{errors: _} = error} -> send_json(conn, 400, error)
      {:error, _} -> send_resp(conn, 400, "Bad request")
    end
  end

  delete "/comment/:id" do
    with {:ok, params} <- Tarams.cast(conn.path_params, %{id: id_param(required: true)}),
         {:ok, result} <- Comments.delete(params.id, conn.assigns.user) do
      send_json(conn, 200, result)
    else
      {:error, :forbidden} -> send_resp(conn, 403, "Only the author can delete this comment")
      {:error, :not_found} -> send_resp(conn, 404, "Not found")
      {:error, _} -> send_resp(conn, 400, "Bad request")
    end
  end

  # A picture: `type` "monogram" with a `color`, or "image" with a `file`
  post "/user/avatar" do
    conn
    |> send_avatar_result(Avatars.update_user(conn.assigns.user, conn.body_params))
  end

  post "/moon/:id/avatar" do
    case Tarams.cast(conn.path_params, %{id: id_param(required: true)}) do
      {:ok, params} ->
        send_avatar_result(
          conn,
          Avatars.update_moon(params.id, conn.body_params, conn.assigns.user)
        )

      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end

  post "/subscription" do
    schema = %{
      moon_id: id_param(required: true)
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
      moon_id: id_param(required: true)
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

  # /notifications
  get "/notifications" do
    with {:ok, params} <- Tarams.cast(conn.query_params, %{before: id_param()}) do
      send_json(conn, 200, Notifications.list(conn.assigns.user_id, params[:before]))
    else
      {:error, _} -> send_resp(conn, 400, "Bad request")
    end
  end

  # Marks the notifications in `ids` read, or all of them without it
  post "/notifications/read" do
    case conn.body_params do
      %{"ids" => ids} when is_list(ids) ->
        if ids != [] and Enum.all?(ids, &(is_integer(&1) and &1 > 0)) do
          Notifications.mark_read(conn.assigns.user_id, ids)
          send_resp(conn, 204, "")
        else
          send_resp(conn, 400, "Bad request")
        end

      %{"ids" => _} ->
        send_resp(conn, 400, "Bad request")

      _ ->
        Notifications.mark_read(conn.assigns.user_id)
        send_resp(conn, 204, "")
    end
  end

  # Marks the notifications in `ids` unread again
  post "/notifications/unread" do
    case conn.body_params do
      %{"ids" => [_ | _] = ids} ->
        if Enum.all?(ids, &(is_integer(&1) and &1 > 0)) do
          Notifications.mark_unread(conn.assigns.user_id, ids)
          send_resp(conn, 204, "")
        else
          send_resp(conn, 400, "Bad request")
        end

      _ ->
        send_resp(conn, 400, "Bad request")
    end
  end

  # Clears all of them
  delete "/notifications" do
    Notifications.clear(conn.assigns.user_id)
    send_resp(conn, 204, "")
  end

  delete "/notification/:id" do
    with {:ok, params} <- Tarams.cast(conn.path_params, %{id: id_param(required: true)}),
         :ok <- Notifications.clear(conn.assigns.user_id, params.id) do
      send_resp(conn, 204, "")
    else
      {:error, :not_found} -> send_resp(conn, 404, "Not found")
      {:error, _} -> send_resp(conn, 400, "Bad request")
    end
  end

  # The live connection for notifications (Saturn.NotificationSocket). Browsers don't apply CORS
  # to websockets, so the page's origin is checked here instead.
  get "/ws" do
    if allowed_origin?(get_req_header(conn, "origin")) do
      conn
      |> WebSockAdapter.upgrade(
        Saturn.NotificationSocket,
        %{user_id: conn.assigns.user_id, session_id: conn.assigns.session.session_id},
        timeout: 60_000
      )
      |> halt()
    else
      send_resp(conn, 403, "Origin not allowed")
    end
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

  defp allowed_origin?(origins) do
    case Saturn.Router.cors_origins() do
      "*" ->
        true

      allowed ->
        Enum.any?(origins, &(String.trim_trailing(&1, "/") == String.trim_trailing(allowed, "/")))
    end
  end

  defp send_avatar_result(conn, result) do
    case result do
      {:ok, avatar} ->
        send_json(conn, 200, avatar)

      {:error, :forbidden} ->
        send_resp(conn, 403, "Only the moon's owner can change its picture")

      {:error, :not_found} ->
        send_resp(conn, 404, "Not found")

      {:error, :missing_file} ->
        send_json(conn, 400, %{errors: %{file: ["File can't be blank"]}})

      {:error, :file_not_supported} ->
        send_json(conn, 400, %{errors: %{file: ["File type not supported"]}})

      {:error, :file_too_large} ->
        send_json(conn, 400, %{errors: %{file: ["Image must be 5 MB or smaller"]}})

      {:error, :missing_s3_config} ->
        send_json(conn, 503, %{errors: %{file: ["Image storage is not configured"]}})

      {:error, :upload_failed} ->
        send_json(conn, 502, %{errors: %{file: ["Image upload failed"]}})

      {:error, %{errors: _} = error} ->
        send_json(conn, 400, error)

      {:error, _} ->
        send_resp(conn, 400, "Bad request")
    end
  end
end
