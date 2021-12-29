defmodule Saturn.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.User
  alias Saturn.Post

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "votes" do
    belongs_to(:post, Post)
    belongs_to(:user, User)

    field(:vote, :integer)

    timestamps()
  end

  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:vote, :user_id, :post_id])
    |> validate_required([:vote, :user_id, :post_id])
    |> foreign_key_constraint(:post_id)
  end
end
