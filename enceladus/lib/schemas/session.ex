defmodule Saturn.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias Saturn.User
  alias Saturn.Repo
  alias Saturn.Session

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

  def generate_session_id() do
    :crypto.strong_rand_bytes(128)
    |> Base.url_encode64()
  end

  def get_by_id(session_id) do
    case session_id do
      nil ->
        nil

      _ ->
        Repo.get_by(Session, %{session_id: session_id})
        |> Repo.preload(:user)
    end
  end
end
