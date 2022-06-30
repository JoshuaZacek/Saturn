defmodule Saturn.Profiles do
  import Ecto.Query

  alias Saturn.{Repo, Post, Moon, User, Comment}

  def get_posts(user_id, sort, cursor, limit) do
    order_by =
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

    cursor_query =
      case sort do
        "new" ->
          if cursor do
            dynamic(
              [p],
              p.id <= ^cursor["id"] and
                p.inserted_at <= ^DateTime.from_unix!(cursor["inserted_at"])
            )
          else
            is_nil(cursor)
          end

        "top" ->
          if cursor do
            dynamic(
              [p],
              fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id) <=
                ^cursor["votes"] and
                p.id <= ^cursor["id"]
            )
          else
            is_nil(cursor)
          end
      end

    posts =
      Repo.all(
        from(p in Post,
          where: p.user_id == ^user_id,
          where: ^cursor_query,
          order_by: ^order_by,
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

    {:ok,
     %{
       content: posts,
       next_cursor: next_cursor
     }}
  end

  def get_comments(user_id, sort, cursor, limit) do
    order_by =
      case sort do
        "new" ->
          [
            desc:
              dynamic(
                [c],
                c.inserted_at
              ),
            desc: dynamic([c], c.id)
          ]

        "top" ->
          [
            desc:
              dynamic(
                [c],
                fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?", c.id)
              ),
            desc: dynamic([c], c.id)
          ]
      end

    cursor_query =
      case sort do
        "new" ->
          if cursor do
            dynamic(
              [c],
              c.id <= ^cursor["id"] and
                c.inserted_at <= ^DateTime.from_unix!(cursor["inserted_at"])
            )
          else
            is_nil(cursor)
          end

        "top" ->
          if cursor do
            dynamic(
              [c],
              fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?", c.id) <=
                ^cursor["votes"] and
                c.id <= ^cursor["id"]
            )
          else
            is_nil(cursor)
          end
      end

    comments =
      Repo.all(
        from(c in Comment,
          where: c.user_id == ^user_id,
          where: ^cursor_query,
          order_by: ^order_by,
          limit: ^limit + 1,
          select: %{
            c
            | votes:
                fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?", c.id),
              hasVoted:
                fragment(
                  "SELECT vote FROM votes v WHERE v.comment_id = ? AND v.user_id = ?",
                  c.id,
                  ^user_id
                )
          }
        )
      )
      |> Repo.preload(
        user: from(u in User, select: map(u, [:username, :id, :inserted_at])),
        post: from(p in Post, select: map(p, [:id, :title]))
      )

    {next_cursor, comments} = get_next_cursor(comments, limit, sort)

    {:ok,
     %{
       content: comments,
       next_cursor: next_cursor
     }}
  end

  def overview(user_id, sort, cursor, limit) do
    posts_query =
      from(p in Post,
        where: p.user_id == ^user_id,
        select: %{
          id: p.id,
          inserted_at: p.inserted_at,
          updated_at: p.updated_at,
          user_id: p.user_id,
          user: nil,
          moon_id: p.moon_id,
          moon: nil,
          title: p.title,
          body: p.body,
          content: nil,
          post_id: nil,
          post: nil,
          type: "post",
          comments:
            fragment("SELECT COALESCE(COUNT(*), 0) FROM comments WHERE post_id = ?", p.id),
          votes: fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id),
          hasVoted:
            fragment(
              "SELECT vote FROM votes v WHERE v.post_id = ? AND v.user_id = ?",
              p.id,
              ^user_id
            )
        }
      )

    comments_query =
      from(c in Comment,
        where: c.user_id == ^user_id,
        select: %{
          id: c.id,
          inserted_at: c.inserted_at,
          updated_at: c.updated_at,
          user_id: c.user_id,
          user: nil,
          moon_id: nil,
          moon: nil,
          title: nil,
          body: nil,
          content: c.content,
          post_id: c.post_id,
          post: nil,
          type: "comment",
          comments: nil,
          votes: fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?", c.id),
          hasVoted:
            fragment(
              "SELECT vote FROM votes v WHERE v.comment_id = ? AND v.user_id = ?",
              c.id,
              ^user_id
            )
        }
      )

    union_query = union_all(comments_query, ^posts_query)

    order_by =
      case sort do
        "new" ->
          [
            desc:
              dynamic(
                [q],
                q.inserted_at
              ),
            desc: dynamic([q], q.id)
          ]

        "top" ->
          [
            desc:
              dynamic(
                [q],
                q.votes
              ),
            desc: dynamic([q], q.id)
          ]
      end

    cursor_query =
      case sort do
        "new" ->
          if cursor do
            dynamic(
              [q],
              q.id <= ^cursor["id"] and
                q.inserted_at <= ^DateTime.from_unix!(cursor["inserted_at"])
            )
          else
            is_nil(cursor)
          end

        "top" ->
          if cursor do
            dynamic(
              [q],
              q.votes <=
                ^cursor["votes"] and
                q.id <= ^cursor["id"]
            )
          else
            is_nil(cursor)
          end
      end

    overview =
      Repo.all(
        from(q in subquery(union_query),
          left_join: m in Moon,
          on: q.moon_id == m.id,
          left_join: p in Post,
          on: q.post_id == p.id,
          join: u in User,
          on: q.user_id == u.id,
          select: %{
            q
            | user: %{
                id: u.id,
                username: u.username,
                inserted_at: u.inserted_at
              },
              post: %{
                id: p.id,
                title: p.title
              },
              moon: %{
                id: m.id,
                name: m.name,
                inserted_at: m.inserted_at
              }
          },
          where: ^cursor_query,
          order_by: ^order_by,
          limit: ^limit + 1
        )
      )

    {next_cursor, overview} = get_next_cursor(overview, limit, sort)

    {:ok,
     %{
       content: overview,
       next_cursor: next_cursor
     }}
  end

  defp get_next_cursor(comments, limit, sort) when length(comments) > 0 do
    [head | tail] = Enum.reverse(comments)

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
        {nil, comments}
    end
  end

  defp get_next_cursor(comments, _, _) do
    {nil, comments}
  end
end
