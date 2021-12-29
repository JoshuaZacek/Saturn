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

  @doc "Get posts from all moons sorted by new."
  def get_new_posts(session, limit, cursor, moon)
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

    user_id = if session, do: session.user.id, else: nil

    posts =
      Repo.all(
        from(p in Post,
          where: ^cursor_where,
          where: ^moon_where,
          order_by: [desc: p.id],
          limit: ^limit + 1,
          select: %{
            p
            | votes: fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id),
              hasVoted:
                fragment(
                  "SELECT vote FROM votes v WHERE v.post_id = ? AND v.user_id = ?",
                  p.id,
                  ^user_id
                )
          }
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
  def get_new_posts(_, limit, _, _) when is_integer(limit) and limit > 50 do
    {:error, :limit_too_high}
  end

  def get_new_posts(_, _, _, _) do
    {:error, :bad_request}
  end

  # functions for get_new posts
  defp get_next_cursor(posts, limit) when length(posts) > 0 do
    [head | tail] = Enum.reverse(posts)

    if length(tail) == limit do
      {head.id, Enum.reverse(tail)}
    else
      {nil, posts}
    end
  end

  defp get_next_cursor(posts, _) do
    {nil, posts}
  end

  # Database stuff
  def get(moon) do
    Repo.get_by(Moon, name: moon)
  end
end