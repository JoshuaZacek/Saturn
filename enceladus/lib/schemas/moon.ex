defmodule Saturn.Moon do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.Post

  schema "moons" do
    has_many(:posts, Post)
    field(:name, :string)

    timestamps()
  end

  def changeset(moon, attrs) do
    moon
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
