defmodule Saturn.Moons do
  import Ecto.Query

  alias Saturn.Moon
  alias Saturn.User
  alias Saturn.Repo
  alias Saturn.Post

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

  @doc "Get posts from all moons sorted by new."
  def get_new_posts(limit, cursor, moon)
      when is_integer(limit) and limit <= 50 and (is_integer(cursor) or is_nil(cursor)) and
             cursor > 0 do
    cursor_where =
      if cursor do
        dynamic([p], p.id <= ^cursor)
      else
        is_nil(cursor)
      end

    moon_where =
      if moon do
        dynamic([p], p.moon_id == ^moon)
      else
        is_nil(moon)
      end

    posts =
      Repo.all(
        from(p in Post,
          where: ^cursor_where,
          where: ^moon_where,
          order_by: [desc: p.id],
          limit: ^limit + 1
        )
      )
      |> Repo.preload(
        moon: from(m in Moon, select: map(m, [:name, :id, :inserted_at])),
        user: from(u in User, select: map(u, [:username, :id, :inserted_at]))
      )

    {next_cursor, posts} = get_next_cursor(posts, limit)

    {:ok,
     %{
       data: %{posts: posts},
       next_cursor: next_cursor
     }}
  end

  # Fallbacks
  # Limit shouldn't be over 50
  def get_new_posts(limit, _, _) when is_integer(limit) and limit > 50 do
    {:error, :limit_too_high}
  end

  def get_new_posts(_, _, _) do
    {:error, :bad_request}
  end

  # functions for get_new posts
  defp get_next_cursor(posts, limit) do
    [head | tail] = Enum.reverse(posts)

    if length(tail) == limit do
      {head.id, Enum.reverse(tail)}
    else
      {nil, posts}
    end
  end

  # Database stuff
  def get_by_name(moon) do
    Repo.get_by(Moon, name: moon)
  end
end
