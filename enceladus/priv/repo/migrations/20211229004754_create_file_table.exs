defmodule Saturn.Repo.Migrations.CreateFileTable do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :filename, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:files, [:filename])
  end
end
