defmodule Saturn.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.{User, Moon}

  schema "subscriptions" do
    belongs_to(:user, User)
    belongs_to(:moon, Moon)

    timestamps(type: :utc_datetime)
  end

  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:moon_id])
    |> validate_required([:user_id, :moon_id])
    |> unique_constraint([:user_id, :moon_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:moon_id)
  end
end
