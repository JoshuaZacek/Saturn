defmodule Saturn.Avatars do
  # A person's or moon's picture: a monogram (their first letter) in one of these colours, or an
  # uploaded image. Every person and moon gets a random colour when they're created, which is kept
  # (as the fallback) while an image is set. The frontend maps each name to its shades.
  import Saturn.Functions

  alias Saturn.{Repo, Files, Moon}

  @colors ~w(red orange amber lime green teal cyan sky blue indigo purple pink)

  # Avatars are shown small, so they don't need the 15 MB a post image may have
  @max_image_bytes 5 * 1024 * 1024

  def colors, do: @colors

  def random_color, do: Enum.random(@colors)

  # The current user's picture
  def update_user(user, params), do: update(user, params, user)

  # A moon's picture, which only its owner can set
  def update_moon(moon_id, params, user) do
    case Repo.get(Moon, moon_id) do
      nil -> {:error, :not_found}
      %Moon{user_id: owner_id} = moon when owner_id == user.id -> update(moon, params, user)
      _ -> {:error, :forbidden}
    end
  end

  defp update(record, %{"type" => "monogram", "color" => color}, _user) when is_binary(color) do
    changeset =
      record.__struct__.avatar_changeset(record, %{avatar_color: color, avatar_image: nil})

    with {:ok, updated} <- save(changeset) do
      remove_image(record.avatar_image)
      {:ok, avatar(updated)}
    end
  end

  defp update(record, %{"type" => "image", "file" => %Plug.Upload{} = file}, user) do
    with {:ok, upload} <- Files.upload(file, max_bytes: @max_image_bytes),
         {:ok, _} <- Files.insert_db(upload.filename, user, nil) do
      changeset = record.__struct__.avatar_changeset(record, %{avatar_image: upload.filename})

      case save(changeset) do
        {:ok, updated} ->
          remove_image(record.avatar_image)
          {:ok, avatar(updated)}

        error ->
          remove_image(upload.filename)
          error
      end
    end
  end

  defp update(_record, %{"type" => "image"}, _user), do: {:error, :missing_file}
  defp update(_record, _params, _user), do: {:error, :bad_request}

  defp save(changeset) do
    case Repo.update(changeset) do
      {:ok, record} ->
        {:ok, record}

      {:error, changeset} ->
        if Keyword.has_key?(changeset.errors, :avatar_color),
          do: {:error, %{errors: %{color: ["Choose one of the colours"]}}},
          else: {:error, %{errors: format_changeset(changeset)}}
    end
  end

  defp avatar(record), do: Map.take(record, [:avatar_color, :avatar_image])

  # The image a picture no longer uses. A failure only leaves an unused file behind, so it
  # doesn't fail the change.
  defp remove_image(nil), do: :ok
  defp remove_image(filename), do: Files.delete(filename)
end
