defmodule Saturn.Notifications do
  @moduledoc """
  What a person is told about: comments on their posts, replies to their comments, and their
  posts and comments reaching upvote milestones. Each is stored (for the bell) and pushed to their
  open websockets (`Saturn.Realtime`).
  """

  import Ecto.Query
  require Logger

  alias Saturn.{Repo, Notification, Comment, Post, User, Realtime}

  # Every upvote under 5, then 10, 100 and 1,000, then nothing more
  @milestones [1, 2, 3, 4, 10, 100, 1000]
  @page_size 30
  @snippet_length 140

  def milestones, do: @milestones
  def page_size, do: @page_size

  @doc """
  A new comment: tells the post's author about a top-level comment, or the parent comment's author
  about a reply. Never about your own comment. A failure here is logged, never raised, so it can't
  fail the comment.
  """
  def comment_created(%Comment{} = comment) do
    safely(fn ->
      case recipient(comment) do
        {user_id, type} when user_id != comment.user_id ->
          insert_and_push(%{
            user_id: user_id,
            type: type,
            actor_id: comment.user_id,
            post_id: comment.post_id,
            comment_id: comment.id
          })

        _ ->
          :ok
      end
    end)
  end

  defp recipient(%Comment{comment_id: nil, post_id: post_id}) do
    case Repo.one(from(p in Post, where: p.id == ^post_id, select: p.user_id)) do
      nil -> nil
      author_id -> {author_id, "post_comment"}
    end
  end

  defp recipient(%Comment{comment_id: parent_id}) do
    case Repo.one(from(c in Comment, where: c.id == ^parent_id, select: {c.user_id, c.deleted})) do
      {author_id, false} -> {author_id, "comment_reply"}
      _ -> nil
    end
  end

  @doc """
  An upvote from `voter_id` on a post (`%{post_id: id}`) or comment (`%{comment_id: id}`). When its
  score reaches a milestone higher than any already announced for it, its author is told once.
  Taking the highest milestone at or below the score (not only an exact match) covers a vote flip
  that skips a number (9 to 11 still announces 10), and comparing with the highest already sent
  means un-voting and re-voting around a milestone never repeats it.
  """
  def vote_cast(target, voter_id) do
    safely(fn ->
      with {type, author_id, post_id, score} when author_id != voter_id <- vote_target(target),
           milestone when not is_nil(milestone) <- milestone_for(score),
           true <- milestone > highest_sent(type, target) do
        insert_and_push(
          %{
            user_id: author_id,
            type: type,
            post_id: post_id,
            comment_id: target[:comment_id],
            count: milestone
          },
          on_conflict: :nothing,
          conflict_target: milestone_conflict_target(type)
        )
      else
        _ -> :ok
      end
    end)
  end

  defp vote_target(%{comment_id: comment_id}) when not is_nil(comment_id) do
    Repo.one(
      from(c in Comment,
        where: c.id == ^comment_id and not c.deleted,
        select:
          {"comment_upvotes", c.user_id, c.post_id,
           fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE comment_id = ?", c.id)}
      )
    )
  end

  defp vote_target(%{post_id: post_id}) when not is_nil(post_id) do
    Repo.one(
      from(p in Post,
        where: p.id == ^post_id,
        select:
          {"post_upvotes", p.user_id, p.id,
           fragment("SELECT COALESCE(SUM(vote), 0) FROM votes WHERE post_id = ?", p.id)}
      )
    )
  end

  defp vote_target(_), do: nil

  @doc false
  def milestone_for(score) do
    @milestones |> Enum.filter(&(&1 <= score)) |> List.last()
  end

  defp highest_sent("post_upvotes", %{post_id: post_id}) do
    Repo.one(
      from(n in Notification,
        where: n.type == "post_upvotes" and n.post_id == ^post_id,
        select: coalesce(max(n.count), 0)
      )
    )
  end

  defp highest_sent("comment_upvotes", %{comment_id: comment_id}) do
    Repo.one(
      from(n in Notification,
        where: n.type == "comment_upvotes" and n.comment_id == ^comment_id,
        select: coalesce(max(n.count), 0)
      )
    )
  end

  # The partial unique indexes, which catch two votes announcing the same milestone at once
  defp milestone_conflict_target("post_upvotes"),
    do: {:unsafe_fragment, "(post_id, count) WHERE type = 'post_upvotes'"}

  defp milestone_conflict_target("comment_upvotes"),
    do: {:unsafe_fragment, "(comment_id, count) WHERE type = 'comment_upvotes'"}

  defp insert_and_push(attrs, opts \\ []) do
    case Repo.insert(struct(Notification, attrs), opts) do
      # on_conflict: :nothing gives back a struct without an id when the row already existed
      {:ok, %Notification{id: nil}} ->
        :ok

      {:ok, %Notification{id: id, user_id: user_id}} ->
        case get(id) do
          nil -> :ok
          notification -> Realtime.broadcast(user_id, "notification", notification)
        end

        :ok
    end
  end

  @doc """
  A page of a person's notifications, newest first, with what the bell shows: who did it, the
  post's title and a snippet of the comment. `before` is the id of the last one already shown.
  """
  def list(user_id, before \\ nil) do
    query = from(n in base_query(), where: n.user_id == ^user_id, limit: ^(@page_size + 1))
    query = if before, do: from(n in query, where: n.id < ^before), else: query
    rows = Repo.all(query)

    %{
      notifications: Enum.take(rows, @page_size),
      has_more: length(rows) > @page_size,
      unread_count: unread_count(user_id)
    }
  end

  def get(id), do: Repo.one(from(n in base_query(), where: n.id == ^id))

  defp base_query() do
    from(n in Notification,
      join: p in Post,
      on: p.id == n.post_id,
      left_join: c in Comment,
      on: c.id == n.comment_id,
      left_join: a in User,
      on: a.id == n.actor_id,
      # A comment deleted since (kept as a placeholder for its replies) has nothing left to show
      where: is_nil(n.cleared_at) and (is_nil(n.comment_id) or not c.deleted),
      order_by: [desc: n.id],
      select: %{
        id: n.id,
        type: n.type,
        count: n.count,
        read: not is_nil(n.read_at),
        inserted_at: n.inserted_at,
        post: %{id: p.id, title: p.title},
        comment:
          fragment(
            "CASE WHEN ? IS NULL THEN NULL ELSE json_build_object('id', ?, 'snippet', left(?, ?)) END",
            c.id,
            c.id,
            c.content,
            ^@snippet_length
          ),
        actor:
          fragment(
            "CASE WHEN ? IS NULL THEN NULL ELSE json_build_object('id', ?, 'username', ?, 'avatar_color', ?, 'avatar_image', ?) END",
            a.id,
            a.id,
            a.username,
            a.avatar_color,
            a.avatar_image
          )
      }
    )
  end

  def unread_count(user_id) do
    Repo.one(
      from(n in Notification,
        left_join: c in Comment,
        on: c.id == n.comment_id,
        where:
          n.user_id == ^user_id and is_nil(n.read_at) and is_nil(n.cleared_at) and
            (is_nil(n.comment_id) or not c.deleted),
        select: count(n.id)
      )
    )
  end

  @doc """
  Marks some of a person's notifications read (`ids`), or all of them (`nil`), and tells their
  other tabs. Ids that aren't theirs are ignored.
  """
  def mark_read(user_id, ids \\ nil) do
    query = from(n in Notification, where: n.user_id == ^user_id and is_nil(n.read_at))
    query = if ids, do: from(n in query, where: n.id in ^ids), else: query
    Repo.update_all(query, set: [read_at: now()])

    Realtime.broadcast(user_id, "notifications_read", %{ids: ids})
    :ok
  end

  @doc """
  Marks some of a person's notifications unread again, and tells their other tabs. Ids that aren't
  theirs, or that they've cleared, are ignored.
  """
  def mark_unread(user_id, ids) when is_list(ids) do
    Repo.update_all(
      from(n in Notification,
        where:
          n.user_id == ^user_id and n.id in ^ids and not is_nil(n.read_at) and
            is_nil(n.cleared_at)
      ),
      set: [read_at: nil]
    )

    Realtime.broadcast(user_id, "notifications_unread", %{ids: ids})
    :ok
  end

  @doc """
  Clears one of a person's notifications (`id`), or all of them (`nil`), and tells their other
  tabs. Cleared ones are hidden, not deleted (see the migration). `{:error, :not_found}` for an id
  that isn't one of theirs.
  """
  def clear(user_id, id \\ nil) do
    query = from(n in Notification, where: n.user_id == ^user_id and is_nil(n.cleared_at))
    query = if id, do: from(n in query, where: n.id == ^id), else: query
    {count, _} = Repo.update_all(query, set: [cleared_at: now()])

    if id && count == 0 do
      {:error, :not_found}
    else
      Realtime.broadcast(user_id, "notifications_cleared", %{id: id})
      :ok
    end
  end

  defp now(), do: DateTime.utc_now() |> DateTime.truncate(:second)

  @doc "Removes what pointed at a comment that's been deleted (hard deletes cascade by themselves)."
  def delete_for_comment(comment_id) do
    Repo.delete_all(from(n in Notification, where: n.comment_id == ^comment_id))
    :ok
  end

  defp safely(fun) do
    fun.()
  rescue
    error ->
      Logger.error("Notification failed: " <> Exception.format(:error, error, __STACKTRACE__))
      :error
  end
end
