defmodule Saturn.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.{User, Post}

  schema "files" do
    belongs_to(:user, User)
    belongs_to(:post, Post)
    field(:filename, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, [:filename, :user_id, :post_id])
    |> validate_required([:filename, :user_id, :post_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:user_id)
  end
end
