defmodule Saturn.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.Repo
  alias Saturn.Session

  schema "users" do
    has_many(:sessions, Session)

    field(:username, :string)
    field(:password, :string)
    field(:email, :string)

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :email])
    |> validate_required([:username, :password, :email])
    |> unsafe_validate_unique([:email], Repo, name: :users_email_username_index)
    |> unsafe_validate_unique([:username], Repo, name: :users_email_username_index)
    |> unique_constraint([:email, :username], name: :users_email_username_index)
    |> validate_format(:email, ~r/.+@(?=[^@]+$).+\.(?=[^.]+$)/)
    |> validate_length(:password, min: 8)
    |> hash_password()
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
