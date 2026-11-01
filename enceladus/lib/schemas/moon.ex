defmodule Saturn.Moon do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.Post
  alias Saturn.User
  alias Saturn.Subscription
  alias Saturn.Avatars

  @name_max_length 20

  # What anyone may see of a moon, wherever it appears
  @public_fields [:id, :name, :inserted_at, :avatar_color, :avatar_image]

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "moons" do
    belongs_to(:user, User)
    has_many(:posts, Post, on_delete: :delete_all)
    has_many(:subscriptions, Subscription, on_delete: :delete_all)

    field(:name, :string)
    # Its picture, set by its owner (see Saturn.Avatars): a monogram colour, picked at random when
    # it's created, and an uploaded image's filename, which is shown instead when set
    field(:avatar_color, :string, autogenerate: {Avatars, :random_color, []})
    field(:avatar_image, :string)

    timestamps(type: :utc_datetime)
  end

  def public_fields, do: @public_fields

  def avatar_changeset(moon, attrs) do
    moon
    |> cast(attrs, [:avatar_color, :avatar_image])
    |> validate_required([:avatar_color])
    |> validate_inclusion(:avatar_color, Avatars.colors(), message: "isn't one of the choices")
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
