defmodule Saturn.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.{User, Post, Comment}

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "votes" do
    belongs_to(:comment, Comment)
    belongs_to(:post, Post)
    belongs_to(:user, User)

    field(:vote, :integer)

    timestamps(type: :utc_datetime)
  end

  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:vote, :user_id, :post_id, :comment_id])
    |> validate_required([:vote, :user_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:comment_id)
    |> check_constraint(:post_id, name: :must_be_comment_or_post)
    |> check_constraint(:comment_id, name: :must_be_comment_or_post)
  end
end
