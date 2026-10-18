defmodule Saturn.Repo.Migrations.CreateSubscriptionsTable do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :moon_id, references(:moons, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:subscriptions, [:user_id, :moon_id])
    create index(:subscriptions, [:moon_id])
  end
end
