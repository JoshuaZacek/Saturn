defmodule Saturn.Moons do
  import Ecto.Query

  alias Saturn.Moon
  alias Saturn.User
  alias Saturn.Repo

  def create(attrs, user) do
    case Repo.insert(Moon.changeset(%Moon{user_id: user.id}, attrs)) do
      {:ok, moon} ->
        Repo.preload(moon,
          user:
            from(u in User,
              select: %{username: u.username, id: u.id, inserted_at: u.inserted_at}
            )
        )
        |> Map.drop([:__meta__, :user_id, :posts, :__struct__])

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

  # Database stuff
  def get(moon) do
    Repo.get_by(Moon, name: moon)
  end
end
