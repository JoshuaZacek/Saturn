defmodule Saturn.Moons do
  import Ecto.Query
  import Saturn.Functions

  alias Saturn.{Moon, User, Repo}

  def create(params, user) do
    inserted_post =
      %Moon{user_id: user.id}
      |> Moon.changeset(params)
      |> Repo.insert()

    case inserted_post do
      {:ok, moon} ->
        moon
        |> Repo.preload(user: from(u in User, select: map(u, ^User.public_fields())))
        |> Map.drop([:__meta__, :user_id, :posts, :subscriptions, :__struct__])

      {:error, changeset} ->
        {:error, %{errors: format_changeset(changeset)}}
    end
  end

  def search(search_term) do
    results =
      Repo.all(
        from(m in Moon,
          where: ilike(m.name, ^"#{Regex.replace(~r/^$|([%_])/, search_term, "\\\\\\1")}%"),
          limit: 5,
          select: map(m, ^Moon.public_fields())
        )
      )

    %{results: results}
  end

  def get(name, user_id) do
    Repo.one(
      from(m in Moon,
        where: m.name == ^name,
        select: %{
          id: m.id,
          name: m.name,
          inserted_at: m.inserted_at,
          avatar_color: m.avatar_color,
          avatar_image: m.avatar_image,
          # Its owner, who can change its picture
          user_id: m.user_id,
          updated_at: m.updated_at,
          subscribers: fragment("SELECT COUNT(*) FROM subscriptions WHERE moon_id = ?", m.id),
          subscribed:
            fragment(
              "SELECT EXISTS (SELECT 1 FROM subscriptions WHERE moon_id = ? AND user_id = ?)",
              m.id,
              ^user_id
            )
        }
      )
    )
  end
end
