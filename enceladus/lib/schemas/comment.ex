defmodule Saturn.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  import Saturn.Functions

  alias Saturn.{Vote, User, Post, Comment}

  @content_max_length 5_000

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
    |> cast(attrs, [:content, :post_id, :comment_id])
    |> validate_required([:content, :post_id, :user_id])
    # Code points, to match the char_length check constraint
    |> validate_length(:content, max: @content_max_length, count: :codepoints)
    |> validate_id(:post_id)
    |> validate_id(:comment_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:comment_id)
    |> check_constraint(:content,
      name: :content_length,
      message: "must be #{@content_max_length} characters or fewer"
    )
  end
end
