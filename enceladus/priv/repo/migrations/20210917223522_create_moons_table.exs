defmodule Saturn.Repo.Migrations.CreateMoonsTable do
  use Ecto.Migration

  def change do
    create table(:moons) do
      add :name, :string, null: false

      timestamps()
    end
  end
end
