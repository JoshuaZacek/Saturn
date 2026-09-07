defmodule Saturn.Moon do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.Post
  alias Saturn.User

  @name_max_length 20

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
    |> validate_length(:name, max: @name_max_length)
    |> unique_constraint([:name])
    |> foreign_key_constraint(:user_id)
    |> validate_format(:name, ~r/^\w+$/)
    |> check_constraint(:name,
      name: :name_length,
      message: "must be #{@name_max_length} characters or fewer"
    )
  end
end
