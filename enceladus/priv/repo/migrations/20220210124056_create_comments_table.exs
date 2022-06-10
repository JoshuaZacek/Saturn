defmodule Saturn.Repo.Migrations.CreateCommentsTable do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :user_id, references(:users), null: false
      add :comment_id, references(:comments)
      add :post_id, references(:posts), null: false
      add :content, :text, null: false

      timestamps()
    end

    create index(:comments, [:user_id, :comment_id, :post_id, :inserted_at])
  end
end
