defmodule Saturn.Votes do
  import Ecto.Query

  alias Saturn.Vote
  alias Saturn.Repo

  def create(vote, post_id, comment_id, user_id) when vote != 0 do
    fields =
      if comment_id do
        [:user_id, :comment_id]
      else
        [:user_id, :post_id]
      end

    case Repo.insert(
           Vote.changeset(%Vote{}, %{
             vote: vote,
             post_id: post_id,
             comment_id: comment_id,
             user_id: user_id
           }),
           on_conflict: :replace_all,
           conflict_target: fields
         ) do
      {:ok, vote} ->
        vote

      {:error, _} ->
        :error
    end
  end

  def create(_, _, _) do
    {:error, :bad_request}
  end

  def delete(post_id, comment_id, user_id) do
    query =
      if comment_id,
        do: dynamic([v], v.user_id == ^user_id and v.comment_id == ^comment_id),
        else: dynamic([v], v.user_id == ^user_id and v.post_id == ^post_id)

    Repo.delete_all(from(v in Vote, where: ^query))
  end
end
