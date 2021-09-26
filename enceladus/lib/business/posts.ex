defmodule Saturn.Posts do
  import Ecto.Query

  alias Saturn.Repo
  alias Saturn.Post
  alias Saturn.User
  alias Saturn.Moon

  def create(attrs, user) do
    case Repo.insert(Post.changeset(%Post{user_id: user.id}, attrs)) do
      {:ok, post} ->
        Repo.preload(post,
          moon: from(m in Moon, select: %{id: m.id, name: m.name}),
          user:
            from(u in User,
              select: %{username: u.username, id: u.id, inserted_at: u.inserted_at}
            )
        )
        |> Map.delete(:__meta__)

      {:error, changeset} ->
        # Format errors
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, _value}, acc ->
              String.replace(acc, "%{#{key}}", msg)
            end)
          end)
          |> Enum.map(fn
            {k, ["can't be blank"]} ->
              {k, ["Please enter a #{k}"]}

            other ->
              other
          end)
          |> Enum.into(%{})

        {:error, %{errors: errors}}
    end
  end
end
