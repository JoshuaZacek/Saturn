defmodule Saturn.Accounts do
  alias Saturn.Repo
  alias Saturn.User
  alias Saturn.Session

  def login(email, password) do
    case Repo.get_by(User, email: email) do
      nil ->
        Argon2.no_user_verify()
        {:error, "Email doesn't exist"}

      user ->
        case Argon2.verify_pass(password, user.password) do
          true ->
            session_id = Session.generate_session_id()

            Repo.insert(
              Ecto.build_assoc(user, :sessions, %{session_id: session_id})
              |> Repo.preload(:user)
            )

          false ->
            {:error, "Incorrect password"}
        end
    end
  end

  def register(username, email, password) do
    changeset = User.changeset(%User{}, %{username: username, password: password, email: email})

    case Repo.insert(changeset) do
      {:ok, user} ->
        session_id = Session.generate_session_id()

        Repo.insert(
          Ecto.build_assoc(user, :sessions, %{session_id: session_id})
          |> Repo.preload(:user)
        )

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
