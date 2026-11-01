defmodule Saturn.Repo.Migrations.AddPostEditing do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      # When its author last changed its title or text; null if they never have
      add :edited_at, :utc_datetime
    end
  end
end
