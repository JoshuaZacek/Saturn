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

  def get(post_id, user_id, parent_comment_id \\ nil) do
    parent_comment_query =
      if parent_comment_id,
        do: dynamic([c], c.comment_id == ^parent_comment_id),
        else: dynamic([c], is_nil(c.comment_id))

    Repo.all(
      from(c in Comment,
        where: c.post_id == ^post_id,
        where: ^parent_comment_query,
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
    |> Repo.preload(user: from(u in User, select: map(u, [:username, :id, :inserted_at])))
  end
end
