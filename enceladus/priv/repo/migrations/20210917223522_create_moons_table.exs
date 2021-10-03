defmodule Saturn.Repo.Migrations.CreateMoonsTable do
  use Ecto.Migration

  def change do
    create table(:moons) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:moons, [:name])
    create index(:moons, [:user_id])
  end
end
