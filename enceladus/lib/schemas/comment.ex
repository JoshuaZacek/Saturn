defmodule Saturn.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.{Vote, User, Post, Comment}

  @derive {Jason.Encoder, except: [:__meta__, :post_id, :user_id, :comment_id, :comment, :post]}
  schema "comments" do
    has_many(:votes, Vote, on_delete: :delete_all)
    belongs_to(:user, User)
    belongs_to(:post, Post)
    belongs_to(:comment, Comment)

    field(:content, :string)
    field(:hasVoted, :integer, virtual: true)
    field(:replies, :integer, virtual: true)

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :post_id, :user_id, :comment_id])
    |> validate_required([:content, :post_id, :user_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:comment_id)
  end
end
