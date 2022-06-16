defmodule Saturn.Comments do
  import Ecto.Query

  alias Saturn.{Comment, User, Repo, Vote}

  def create(attrs, user) do
    case %Comment{user_id: user.id} |> Comment.changeset(attrs) |> Repo.insert() do
      {:ok, comment} ->
        comment
        |> Repo.preload(
          user: from(u in User, select: map(u, [:username, :id, :inserted_at])),
          votes:
            from(v in Vote,
              select: %{
                votes:
                  fragment(
                    "SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?",
                    ^comment.id
                  ),
                hasVoted:
                  fragment(
                    "SELECT vote FROM votes v WHERE v.comment_id = ? AND v.user_id = ?",
                    ^comment.id,
                    ^user.id
                  )
              }
            )
        )

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_by_id(comment_id, user_id) do
    Repo.one(
      from(c in Comment,
        where: c.id == ^comment_id,
        select: %{
          c
          | votes:
              fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?", c.id),
            hasVoted:
              fragment(
                "SELECT vote FROM votes v WHERE v.comment_id = ? AND v.user_id = ?",
                c.id,
                ^user_id
              ),
            replies:
              fragment(
                "SELECT CASE WHEN EXISTS (SELECT * FROM comments WHERE comment_id = ?) THEN TRUE ELSE FALSE END",
                c.id
              )
        }
      )
    )
    |> Repo.preload(user: from(u in User, select: map(u, [:username, :id, :inserted_at])))
  end

  def get(params, user_id) do
    post_id = params["post_id"]
    parent_comment_id = params["parent_comment_id"]
    sort = if params["sort"], do: params["sort"], else: "new"
    limit = parse_int(params["limit"])
    cursor = parse_cursor(params["cursor"])

    replies_query =
      if parent_comment_id,
        do: dynamic([c], c.comment_id == ^parent_comment_id),
        else: dynamic([c], is_nil(c.comment_id))

    sort_query =
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
              fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", c.id) <=
                ^cursor["votes"] and
                c.id <= ^cursor["id"]
            )
          else
            is_nil(cursor)
          end
      end

    order_query =
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

    comments =
      Repo.all(
        from(c in Comment,
          where: c.post_id == ^post_id,
          where: ^replies_query,
          where: ^sort_query,
          order_by: ^order_query,
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
                ),
              replies:
                fragment(
                  "SELECT CASE WHEN EXISTS (SELECT * FROM comments WHERE comment_id = ?) THEN TRUE ELSE FALSE END",
                  c.id
                )
          }
        )
      )
      |> Repo.preload(user: from(u in User, select: map(u, [:username, :id, :inserted_at])))

    {next_cursor, comments} = get_next_cursor(comments, limit, sort)

    {:ok,
     %{
       comments: comments,
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

  defp parse_int(num) do
    case Integer.parse(num || "") do
      {int, ""} -> int
      :error -> num
    end
  end

  defp parse_cursor(cursor) do
    try do
      cursor
      |> Base.url_decode64!()
      |> Jason.decode!()
    rescue
      _ -> cursor
    end
  end
end
