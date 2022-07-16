defmodule Saturn.Users do
  import Ecto.Query
  import Ecto.Changeset
  import Saturn.Functions

  alias Saturn.{Repo, User, Session}

  def check_password_match(changeset, old_password, new_password) do
    if old_password == new_password do
      add_error(changeset, :password, "cannot be the same")
    else
      changeset
    end
  end

  def check_password_is_correct(changeset, password, user) do
    if Argon2.verify_pass(password, user.password) do
      changeset
    else
      add_error(changeset, :password, "incorrect")
    end
  end

  def check_email_match(changeset, email, user) do
    if user.email == email do
      add_error(changeset, :email, "cannot be the same")
    else
      changeset
    end
  end

  def create_session(user) do
    session_id = Session.generate_session_id()

    user
    |> Ecto.build_assoc(:sessions, %{session_id: session_id})
    |> Repo.insert!()
    |> Repo.preload(user: from(u in User, select: map(u, [:id, :username, :email, :inserted_at])))
  end

  def login(email, password) do
    case Repo.get_by(User, email: email) do
      nil ->
        Argon2.no_user_verify()
        {:error, %{errors: %{email: ["Email not found"]}}}

      user ->
        case Argon2.verify_pass(password, user.password) do
          true ->
            create_session(user)

          false ->
            {:error, %{errors: %{password: ["Incorrect password"]}}}
        end
    end
  end

  def signup(username, email, password) do
    inserted_user =
      %User{}
      |> User.changeset(%{username: username, password: password, email: email})
      |> Repo.insert()

    case inserted_user do
      {:ok, user} ->
        create_session(user)

      {:error, changeset} ->
        {:error, %{errors: format_changeset(changeset)}}
    end
  end

  def change_password(old_password, new_password, current_user) do
    updated_password =
      current_user
      |> User.changeset(%{password: new_password})
      |> check_password_is_correct(old_password, current_user)
      |> check_password_match(old_password, new_password)
      |> Repo.update()

    case updated_password do
      {:ok, _} ->
        :ok

      {:error, changeset} ->
        {:error, %{errors: format_changeset(changeset)}}
    end
  end

  def change_email(new_email, current_user) do
    updated_email =
      current_user
      |> User.changeset(%{email: new_email})
      |> check_email_match(new_email, current_user)
      |> Repo.update()

    case updated_email do
      {:ok, _} ->
        :ok

      {:error, changeset} ->
        {:error, %{errors: format_changeset(changeset)}}
    end
  end

  def get_by_username(username) do
    Repo.one(
      from(u in User,
        where: u.username == ^username,
        select: map(u, [:id, :username, :inserted_at])
      )
    )
  end
end
