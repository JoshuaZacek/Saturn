defmodule Saturn.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.{Repo, Session, Post, Moon, Vote, Comment, File, Subscription, Avatars}

  # What anyone may see of a person, wherever they appear
  @public_fields [:id, :username, :inserted_at, :avatar_color, :avatar_image]

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "users" do
    has_many(:sessions, Session, on_delete: :delete_all)
    has_many(:comments, Comment, on_delete: :delete_all)
    has_many(:posts, Post, on_delete: :delete_all)
    has_many(:moons, Moon, on_delete: :delete_all)
    has_many(:votes, Vote, on_delete: :delete_all)
    has_many(:files, File, on_delete: :delete_all)
    has_many(:subscriptions, Subscription, on_delete: :delete_all)

    field(:username, :string)
    field(:password, :string)
    field(:email, :string)
    # Their picture (see Saturn.Avatars): a monogram colour, picked at random when they sign up,
    # and an uploaded image's filename, which is shown instead when set
    field(:avatar_color, :string, autogenerate: {Avatars, :random_color, []})
    field(:avatar_image, :string)

    timestamps(type: :utc_datetime)
  end

  def public_fields, do: @public_fields

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :email])
    |> validate_required([:username, :password, :email])
    |> unsafe_validate_unique([:email], Repo, name: :users_email_username_index)
    |> unsafe_validate_unique([:username], Repo, name: :users_email_username_index)
    |> unique_constraint([:email, :username], name: :users_email_username_index)
    |> validate_format(:email, ~r/.+@(?=[^@]+$).+\.(?=[^.]+$)/)
    |> validate_length(:password, min: 8)
    |> validate_format(:username, ~r/^\w+$/)
    # GET /user/me is the session user, so a user called "me" would have no reachable profile
    |> validate_exclusion(:username, ["me"], message: "is reserved")
    |> hash_password()
  end

  def avatar_changeset(user, attrs) do
    user
    |> cast(attrs, [:avatar_color, :avatar_image])
    |> validate_required([:avatar_color])
    |> validate_inclusion(:avatar_color, Avatars.colors(), message: "isn't one of the choices")
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end
end
