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
        |> Repo.preload(user: from(u in User, select: map(u, [:id, :username, :inserted_at])))
        |> Map.drop([:__meta__, :user_id, :posts, :__struct__])

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
          select: %{name: m.name, id: m.id}
        )
      )

    %{results: results}
  end

  def get(moon) do
    Repo.get_by(Moon, name: moon)
  end
end
