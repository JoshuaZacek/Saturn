defmodule Saturn.Repo.Migrations.CreateFileTable do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :path, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:files, [:path])
  end
end
