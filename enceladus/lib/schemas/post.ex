defmodule Saturn.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.{User, Moon, Vote, Comment, File}

  @derive {Jason.Encoder, except: [:__meta__, :moon_id, :user_id, :files]}
  schema "posts" do
    has_many(:votes, Vote, on_delete: :delete_all)
    has_many(:comments, Comment, on_delete: :delete_all)
    has_one(:files, File, on_delete: :delete_all)
    belongs_to(:user, User)
    belongs_to(:moon, Moon)

    field(:title, :string)
    field(:body, :string)
    field(:type, :string)
    field(:hasVoted, :integer, virtual: true)

    timestamps(type: :utc_datetime)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :moon_id, :user_id, :type])
    |> validate_required([:title, :body, :moon_id, :user_id, :type])
    |> foreign_key_constraint(:moon_id)
    |> foreign_key_constraint(:user_id)
  end
end
