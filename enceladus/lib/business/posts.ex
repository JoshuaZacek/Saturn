defmodule Saturn.Posts do
  import Ecto.Query
  import Saturn.Functions

  alias Saturn.{Repo, Post, User, Moon, Vote, Comment, Files, File}

  def create(params, user) do
    file =
      if !!params["file"] and params["type"] == "image",
        do: Files.upload(params["file"]),
        else: {:ok, nil}

    case file do
      {:ok, filename} ->
        params = if filename, do: Map.put(params, "body", filename), else: params

        inserted_post =
          %Post{user_id: user.id}
          |> Post.changeset(params)
          |> Repo.insert()

        case inserted_post do
          {:ok, post} ->
            if filename, do: Files.insert_db(filename, user, post)

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
            {:error, %{errors: format_changeset(changeset)}}
        end

      {:error, :file_not_supported} ->
        {:error, :file_not_supported}
    end
  end

  def get(
        %{limit: limit, sort: sort, cursor: cursor, moon_id: moon_id, time_period: time_period},
        user_id
      ) do
    cursor = parse_cursor(cursor)

    posts_after_query =
      if sort == "top" do
        dynamic(
          [p],
          p.inserted_at >
            ^(((DateTime.utc_now() |> DateTime.to_unix()) - time_period)
              |> DateTime.from_unix!())
        )
      else
        true
      end

    moon_query = if moon_id, do: dynamic([p], p.moon_id == ^moon_id), else: is_nil(moon_id)

    cursor_query =
      case sort do
        "new" ->
          if cursor,
            do:
              dynamic(
                [p],
                p.id <= ^cursor["id"] and
                  p.inserted_at <= ^DateTime.from_unix!(cursor["inserted_at"])
              ),
            else: is_nil(cursor)

        "top" ->
          if cursor,
            do:
              dynamic(
                [p],
                fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id) <=
                  ^cursor["votes"] and p.id <= ^cursor["id"]
              ),
            else: is_nil(cursor)
      end

    order_by_query =
      case sort do
        "new" ->
          [
            desc:
              dynamic(
                [p],
                p.inserted_at
              ),
            desc: dynamic([p], p.id)
          ]

        "top" ->
          [
            desc:
              dynamic(
                [p],
                fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id)
              ),
            desc: dynamic([p], p.id)
          ]
      end

    posts =
      Repo.all(
        from(p in Post,
          where: ^moon_query,
          where: ^cursor_query,
          where: ^posts_after_query,
          order_by: ^order_by_query,
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

    {next_cursor, posts} = get_next_cursor(posts, limit, sort)

    %{
      posts: posts,
      next_cursor: next_cursor
    }
  end

  def get_by_id(post_id, user_id) do
    Repo.one(
      from(p in Post,
        where: p.id == ^post_id,
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

  defp get_next_cursor(comments, _, _) do
    {nil, comments}
  end

  defp parse_cursor(cursor) do
    try do
      cursor
      |> Base.url_decode64!()
      |> Jason.decode!()
    rescue
      _ -> nil
    end
  end
end
