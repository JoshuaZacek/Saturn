defmodule Saturn.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.User

  schema "files" do
    belongs_to(:user, User)
    field(:path, :string)

    timestamps()
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, [:path])
    |> validate_required([:path])
  end
end
