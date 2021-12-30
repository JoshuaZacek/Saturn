defmodule Saturn.Accounts do
  import Ecto.Query

  alias Saturn.Repo
  alias Saturn.User
  alias Saturn.Session

  def login(email, password) do
    case Repo.get_by(User, email: email) do
      nil ->
        Argon2.no_user_verify()
        {:error, %{errors: %{email: ["Email not found"]}}}

      user ->
        case Argon2.verify_pass(password, user.password) do
          true ->
            session_id = Session.generate_session_id()

            case Repo.insert(Ecto.build_assoc(user, :sessions, %{session_id: session_id})) do
              {:ok, session} ->
                session
                |> Repo.preload(
                  user:
                    from(u in User,
                      select: %{
                        username: u.username,
                        inserted_at: u.inserted_at,
                        id: u.id,
                        email: u.email
                      }
                    )
                )
            end

          false ->
            {:error, %{errors: %{password: ["Incorrect password"]}}}
        end
    end
  end

  def register(username, email, password) do
    changeset = User.changeset(%User{}, %{username: username, password: password, email: email})

    case Repo.insert(changeset) do
      {:ok, user} ->
        session_id = Session.generate_session_id()

        case Repo.insert(Ecto.build_assoc(user, :sessions, %{session_id: session_id})) do
          {:ok, session} ->
            session
            |> Repo.preload(
              user:
                from(u in User,
                  select: %{
                    username: u.username,
                    inserted_at: u.inserted_at,
                    id: u.id,
                    email: u.email
                  }
                )
            )
        end

      {:error, changeset} ->
        # Format errors
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, _value}, acc ->
              String.replace(acc, "%{#{key}}", msg)
            end)
          end)
          |> Enum.map(fn
            {:email, ["has invalid format"]} ->
              {:email, ["Please enter a valid email"]}

            {:password,
             ["should be at least should be at least %{count} character(s) character(s)"]} ->
              {:password, ["Passwords should be 8 characters or more long"]}

            {k, ["can't be blank"]} ->
              {k, ["Please enter a #{k}"]}

            {k, ["has already been taken"]} ->
              {k, ["#{k |> Atom.to_string() |> String.capitalize()} has already been taken"]}

            other ->
              other
          end)
          |> Enum.into(%{})

        {:error, %{errors: errors}}
    end
  end
end
