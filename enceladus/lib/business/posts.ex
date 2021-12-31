defmodule Saturn.Posts do
  import Ecto.Query

  alias Saturn.Repo
  alias Saturn.Post
  alias Saturn.User
  alias Saturn.Moon
  alias Saturn.Vote

  def create(attrs, user) do
    case Repo.insert(Post.changeset(%Post{user_id: user.id}, attrs)) do
      {:ok, post} ->
        Repo.preload(post,
          moon: from(m in Moon, select: %{id: m.id, name: m.name}),
          user:
            from(u in User,
              select: %{username: u.username, id: u.id, inserted_at: u.inserted_at}
            ),
          votes:
            from(v in Vote,
              select: %{
                votes:
                  fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", ^post.id),
                hasVoted:
                  fragment(
                    "SELECT vote FROM votes v WHERE v.post_id = ? AND v.user_id = ?",
                    ^post.id,
                    ^user.id
                  )
              }
            )
        )
        |> Map.drop([:__meta__, :user_id, :moon_id])

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

  # Get top posts
  def get_top(limit, cursor, user_id, moon_id, time)
      when is_integer(limit) and limit <= 50 and cursor > 0 and
             (is_map(cursor) or is_nil(cursor)) and is_integer(time) do
    postsAfter =
      if time > 0 do
        (DateTime.utc_now() |> DateTime.to_unix()) - time
      else
        0
      end
      |> convert_unix_to_naive()

    # massive query to fetch posts
    posts =
      Repo.all(
        from(p in Post,
          where: ^if(moon_id, do: dynamic([p], p.moon_id == ^moon_id), else: is_nil(moon_id)),
          where:
            ^if(cursor,
              do:
                dynamic(
                  [p],
                  fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id) <=
                    ^cursor["votes"] and
                    p.id <= ^cursor["id"]
                ),
              else: is_nil(cursor)
            ),
          where: p.inserted_at > ^postsAfter,
          order_by: [
            desc: fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id),
            desc: p.id
          ],
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

    {next_cursor, posts} = get_next_cursor(posts, limit, "top")

    {:ok,
     %{
       posts: posts,
       next_cursor: next_cursor
     }}
  end

  def get_top(_, _, _, _, _) do
    {:error, :bad_request}
  end

  # Get new posts
  def get_new(limit, cursor, user_id, moon_id)
      when is_integer(limit) and limit <= 50 and cursor > 0 and
             (is_map(cursor) or is_nil(cursor)) do
    # massive query to fetch posts
    posts =
      Repo.all(
        from(p in Post,
          where:
            ^if(cursor,
              do:
                dynamic(
                  [p],
                  p.id <= ^cursor["id"] and
                    p.inserted_at <= ^convert_unix_to_naive(cursor["inserted_at"])
                ),
              else: is_nil(cursor)
            ),
          where: ^if(moon_id, do: dynamic([p], p.moon_id == ^moon_id), else: is_nil(moon_id)),
          order_by: [desc: p.inserted_at, desc: p.id],
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

    {next_cursor, posts} = get_next_cursor(posts, limit, "new")

    {:ok,
     %{
       posts: posts,
       next_cursor: next_cursor
     }}
  end

  def get_new(_, _, _, _) do
    {:error, :bad_request}
  end

  defp get_next_cursor(posts, limit, sort) when length(posts) > 0 do
    [head | tail] = Enum.reverse(posts)

    cond do
      length(tail) == limit and sort == "new" ->
        cursor =
          %{
            inserted_at:
              head.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
            id: head.id
          }
          |> Jason.encode!()
          |> Base.url_encode64()

        {cursor, Enum.reverse(tail)}

      length(tail) == limit and sort == "top" ->
        cursor = %{votes: head.votes, id: head.id} |> Jason.encode!() |> Base.url_encode64()
        {cursor, Enum.reverse(tail)}

      true ->
        {nil, posts}
    end
  end

  defp get_next_cursor(posts, _, _) do
    {nil, posts}
  end

  defp convert_unix_to_naive(unix_timestamp) do
    unix_timestamp
    |> DateTime.from_unix!()
    |> DateTime.to_naive()
  end
end
