defmodule Saturn.Votes do
  import Ecto.Query

  alias Saturn.Vote
  alias Saturn.Repo

  def create(vote, post_id, user_id) when vote != 0 do
    case Repo.insert(
           Vote.changeset(%Vote{}, %{vote: vote, post_id: post_id, user_id: user_id}),
           on_conflict: :replace_all,
           conflict_target: [:user_id, :post_id]
         ) do
      {:ok, vote} ->
        vote

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

  def create(_, _, _) do
    {:error, :bad_request}
  end

  def delete(post_id, user_id) do
    Repo.delete_all(from(v in Vote, where: v.user_id == ^user_id and v.post_id == ^post_id))
  end

  def count(post_id) when is_integer(post_id) do
    Repo.one(from(v in Vote, where: v.post_id == ^post_id, select: sum(v.vote))) || 0
  end

  def count(_) do
    {:error, :bad_request}
  end
end
