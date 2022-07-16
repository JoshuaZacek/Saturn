defmodule Saturn.Votes do
  import Ecto.Query

  alias Saturn.Vote
  alias Saturn.Repo

  def create(params, user_id) do
    fields = if params["comment_id"], do: [:user_id, :comment_id], else: [:user_id, :post_id]

    params =
      case params["vote"] do
        "up" ->
          %{params | "vote" => 1}

        "down" ->
          %{params | "vote" => -1}

        nil ->
          params

        _ ->
          Map.drop(params, ["vote"])
      end

    inserted_vote =
      %Vote{user_id: user_id}
      |> Vote.changeset(params)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: fields)

    case inserted_vote do
      {:ok, _} ->
        :ok

      {:error, _} ->
        :error
    end
  end

  def delete(params, user_id) do
    query =
      if params.comment_id,
        do: dynamic([v], v.user_id == ^user_id and v.comment_id == ^params.comment_id),
        else: dynamic([v], v.user_id == ^user_id and v.post_id == ^params.post_id)

    Repo.delete_all(from(v in Vote, where: ^query))
  end
end
