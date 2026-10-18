defmodule Saturn.Subscriptions do
  import Ecto.Query
  import Saturn.Functions

  alias Saturn.{Repo, Subscription}

  def create(params, user_id) do
    inserted_subscription =
      %Subscription{user_id: user_id}
      |> Subscription.changeset(params)
      |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :moon_id])

    case inserted_subscription do
      {:ok, _} ->
        :ok

      {:error, changeset} ->
        {:error, %{errors: format_changeset(changeset)}}
    end
  end

  def delete(params, user_id) do
    Repo.delete_all(
      from(s in Subscription, where: s.user_id == ^user_id and s.moon_id == ^params.moon_id)
    )

    :ok
  end

  def get(user_id) do
    moons =
      Repo.all(
        from(s in Subscription,
          join: m in assoc(s, :moon),
          where: s.user_id == ^user_id,
          order_by: [asc: fragment("lower(?)", m.name), asc: m.name],
          select: %{id: m.id, name: m.name}
        )
      )

    %{moons: moons}
  end
end
