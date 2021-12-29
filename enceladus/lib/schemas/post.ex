defmodule Saturn.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.User
  alias Saturn.Moon
  alias Saturn.Vote

  @derive {Jason.Encoder, except: [:__meta__, :moon_id, :user_id]}
  schema "posts" do
    has_many(:votes, Vote)
    belongs_to(:user, User)
    belongs_to(:moon, Moon)

    field(:title, :string)
    field(:body, :string)
    field(:hasVoted, :integer, virtual: true)

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :moon_id, :user_id])
    |> validate_required([:title, :body, :moon_id, :user_id])
    |> foreign_key_constraint(:moon_id)
    |> foreign_key_constraint(:user_id)
  end
end
