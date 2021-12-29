defmodule Saturn.Repo.Migrations.CreateVotesTable do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :vote, :integer, null: false

      timestamps()
    end

    create index(:votes, [:post_id])
    create unique_index(:votes, [:post_id, :user_id])
  end
end
