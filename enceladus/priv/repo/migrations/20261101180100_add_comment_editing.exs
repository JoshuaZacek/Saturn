defmodule Saturn.Repo.Migrations.AddCommentEditing do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      # When its author last changed its text; null if they never have
      add :edited_at, :utc_datetime
      # Deleted by its author while it had replies: kept, without its text or author, so the
      # replies stay where they were
      add :deleted, :boolean, null: false, default: false
    end
  end
end
