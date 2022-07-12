defmodule Saturn.Moon do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.Post
  alias Saturn.User

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "moons" do
    belongs_to(:user, User)
    has_many(:posts, Post, on_delete: :delete_all)

    field(:name, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(moon, attrs) do
    moon
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name])
    |> foreign_key_constraint(:user_id)
    |> validate_format(:name, ~r/^\w+$/)
  end
end
