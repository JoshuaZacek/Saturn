defmodule Saturn.Repo.Migrations.CreateVotesTable do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :post_id, references(:posts, on_delete: :delete_all)
      add :comment_id, references(:comments, on_delete: :delete_all)

      add :vote, :integer, null: false

      timestamps()
    end

    create constraint("votes", :must_be_comment_or_post, check: "(post_id is not null and comment_id is null) or (post_id is null and comment_id is not null)")

    create index(:votes, [:post_id, :comment_id])
    create unique_index(:votes, [:post_id, :user_id])
    create unique_index(:votes, [:comment_id, :user_id])
  end
end
