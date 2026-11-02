defmodule Saturn.Notification do
  use Ecto.Schema

  alias Saturn.{User, Post, Comment}

  @types ~w(post_comment comment_reply post_upvotes comment_upvotes)

  schema "notifications" do
    belongs_to(:user, User)
    belongs_to(:actor, User)
    belongs_to(:post, Post)
    belongs_to(:comment, Comment)

    field(:type, :string)
    field(:count, :integer)
    field(:read_at, :utc_datetime)
    field(:cleared_at, :utc_datetime)
    field(:inserted_at, :utc_datetime, read_after_writes: true)
  end

  def types, do: @types
end
