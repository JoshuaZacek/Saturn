defmodule Saturn.Repo.Migrations.CreateSessionTable do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :session_id, :text, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:sessions, [:session_id])
    create index(:sessions, [:user_id])
  end
end
