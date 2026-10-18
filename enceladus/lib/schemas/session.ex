defmodule Saturn.Session do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Saturn.User
  alias Saturn.Repo
  alias Saturn.Session

  # One year, also used as the session cookie's max_age
  @max_age 31_536_000

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "sessions" do
    belongs_to(:user, User)
    field(:session_id, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:session_id])
    |> validate_required([:session_id])
    |> unique_constraint(:session_id)
  end

  def max_age, do: @max_age

  def generate_session_id() do
    :crypto.strong_rand_bytes(128)
    |> Base.url_encode64()
  end

  def get_by_id(session_id) do
    case session_id do
      nil ->
        nil

      _ ->
        Repo.one(
          from(s in Session,
            where: s.session_id == ^session_id and s.inserted_at > ^expiry_cutoff()
          )
        )
        |> Repo.preload(:user)
    end
  end

  def delete_expired(user_id) do
    Repo.delete_all(
      from(s in Session, where: s.user_id == ^user_id and s.inserted_at <= ^expiry_cutoff())
    )
  end

  defp expiry_cutoff() do
    DateTime.add(DateTime.utc_now(), -@max_age, :second)
  end
end
