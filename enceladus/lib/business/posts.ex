defmodule Saturn.Posts do
  import Ecto.Query

  alias Saturn.{Repo, Post, User, Moon, Vote, Comment, Files, File}

  def get_by_id(id, user_id) do
    Repo.one(
      from(p in Post,
        where: p.id == ^id,
        select: %{
          p
          | votes: fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id),
            hasVoted:
              fragment(
                "SELECT vote FROM votes v WHERE v.post_id = ? AND v.user_id = ?",
                p.id,
                ^user_id
              ),
            comments:
              fragment("SELECT COALESCE(COUNT(*), 0) FROM comments WHERE post_id = ?", p.id)
        }
      )
    )
    |> Repo.preload(
      moon: from(m in Moon, select: map(m, [:name, :id, :inserted_at])),
      user: from(u in User, select: map(u, [:username, :id, :inserted_at]))
    )
  end

  def delete(post_id, user_id) do
    post =
      Repo.one(from(p in Post, where: p.id == ^post_id))
      |> Repo.preload(files: from(f in File, select: f.filename))

    case post do
      nil ->
        {:error, :bad_request}

      _ ->
        if post.user_id == user_id do
          if post.files do
            Files.delete(post.files)
          end

          Repo.delete!(post)
          :ok
        else
          {:error, :forbidden}
        end
    end
  end

  def create(attrs, user) do
    file =
      cond do
        attrs["type"] == "image" and attrs["file"] ->
          Files.upload(attrs["file"])

        attrs["type"] == "text" ->
          {:ok, nil}

        true ->
          {:error, :bad_request}
      end

    case file do
      {:ok, filename} ->
        attrs =
          if filename do
            Map.put(attrs, "body", filename)
          else
            attrs
          end

        case Repo.insert(Post.changeset(%Post{user_id: user.id}, attrs)) do
          {:ok, post} ->
            if filename do
              Files.insert_db(filename, user, post)
            end

            Repo.preload(post,
              moon: from(m in Moon, select: %{id: m.id, name: m.name}),
              user:
                from(u in User,
                  select: %{username: u.username, id: u.id, inserted_at: u.inserted_at}
                ),
              comments:
                from(c in Comment,
                  select:
                    fragment(
                      "SELECT COALESCE(COUNT(*), 0) FROM comments WHERE post_id = ?",
                      ^post.id
                    )
                ),
              votes:
                from(v in Vote,
                  select: %{
                    votes:
                      fragment(
                        "SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?",
                        ^post.id
                      ),
                    hasVoted:
                      fragment(
                        "SELECT vote FROM votes v WHERE v.post_id = ? AND v.user_id = ?",
                        ^post.id,
                        ^user.id
                      )
                  }
                )
            )

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

      {:error, error} ->
        {:error, error}
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
      |> DateTime.from_unix!()

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
                ),
              comments:
                fragment("SELECT COALESCE(COUNT(*), 0) FROM comments WHERE post_id = ?", p.id)
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
                    p.inserted_at <= ^DateTime.from_unix!(cursor["inserted_at"])
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
                ),
              comments:
                fragment("SELECT COALESCE(COUNT(*), 0) FROM comments WHERE post_id = ?", p.id)
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
            inserted_at: head.inserted_at |> DateTime.to_unix(),
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
end
