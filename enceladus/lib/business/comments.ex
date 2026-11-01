defmodule Saturn.Comments do
  import Ecto.Query
  import Saturn.Functions

  alias Saturn.{Comment, User, Repo, Vote}

  def create(params, user) do
    inserted_comment =
      %Comment{user_id: user.id}
      |> Comment.changeset(params)
      |> Repo.insert()

    case inserted_comment do
      {:ok, comment} ->
        comment
        |> Repo.preload(
          user: from(u in User, select: map(u, ^User.public_fields())),
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
        {:error, %{errors: format_changeset(changeset)}}
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
    |> Repo.preload(user: from(u in User, select: map(u, ^User.public_fields())))
    |> hide_deleted()
  end

  def get(params, user_id) do
    cursor = parse_cursor(params.cursor, params.sort)

    replies_query =
      if params.parent_comment_id,
        do: dynamic([c], c.comment_id == ^params.parent_comment_id),
        else: dynamic([c], is_nil(c.comment_id))

    # Row comparisons keep comments at or after the cursor in (sort key, id) order, so ties on the
    # sort key fall back to id instead of dropping rows
    sort_query =
      case params.sort do
        "new" ->
          if cursor do
            dynamic(
              [c],
              fragment(
                "(?, ?) <= (?, ?)",
                c.inserted_at,
                c.id,
                ^cursor["inserted_at"],
                ^cursor["id"]
              )
            )
          else
            is_nil(cursor)
          end

        "top" ->
          if cursor do
            dynamic(
              [c],
              fragment(
                "((SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?), ?) <= (?, ?)",
                c.id,
                c.id,
                ^cursor["votes"],
                ^cursor["id"]
              )
            )
          else
            is_nil(cursor)
          end
      end

    order_query =
      case params.sort do
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
          where: c.post_id == ^params.post_id,
          where: ^replies_query,
          where: ^sort_query,
          order_by: ^order_query,
          limit: ^params.limit + 1,
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
      |> Repo.preload(user: from(u in User, select: map(u, ^User.public_fields())))
      |> Enum.map(&hide_deleted/1)

    {next_cursor, comments} = get_next_cursor(comments, params.limit, params.sort)

    %{
      comments: comments,
      next_cursor: next_cursor
    }
  end

  # Its author changes its text. Returns the comment as listed, with the new text and edit time.
  def edit(comment_id, params, user) do
    with {:ok, comment} <- own_comment(comment_id, user) do
      comment
      |> Comment.edit_changeset(params)
      |> Repo.update()
      |> case do
        {:ok, _} -> {:ok, get_by_id(comment_id, user.id)}
        {:error, changeset} -> {:error, %{errors: format_changeset(changeset)}}
      end
    end
  end

  # Its author deletes it. A comment with replies is kept as a placeholder (no text, no author),
  # so the replies stay in their thread; one without is removed, and so is any deleted
  # placeholder above it that was only kept for it. `kept` says which happened.
  def delete(comment_id, user) do
    with {:ok, comment} <- own_comment(comment_id, user) do
      if has_replies?(comment.id) do
        comment
        |> Ecto.Changeset.change(deleted: true, content: "", edited_at: nil)
        |> Repo.update!()

        {:ok, %{id: comment.id, kept: true}}
      else
        Repo.delete!(comment)
        remove_empty_placeholders(comment.comment_id)
        {:ok, %{id: comment.id, kept: false}}
      end
    end
  end

  defp own_comment(comment_id, user) do
    case Repo.get(Comment, comment_id) do
      %Comment{deleted: false, user_id: author_id} = comment when author_id == user.id ->
        {:ok, comment}

      %Comment{deleted: false} ->
        {:error, :forbidden}

      _ ->
        {:error, :not_found}
    end
  end

  defp has_replies?(comment_id) do
    Repo.exists?(from(c in Comment, where: c.comment_id == ^comment_id))
  end

  defp remove_empty_placeholders(nil), do: :ok

  defp remove_empty_placeholders(parent_id) do
    case Repo.get(Comment, parent_id) do
      %Comment{deleted: true} = parent ->
        unless has_replies?(parent.id) do
          Repo.delete!(parent)
          remove_empty_placeholders(parent.comment_id)
        end

        :ok

      _ ->
        :ok
    end
  end

  # A deleted placeholder shows neither what it said nor who said it
  defp hide_deleted(%{deleted: true} = comment), do: %{comment | user: nil, content: ""}
  defp hide_deleted(comment), do: comment

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
