defmodule Saturn.Repo.Migrations.AddImageDimensionsToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :image_width, :integer
      add :image_height, :integer
    end

    # Explicit IS NOT NULLs: a check whose result is NULL (e.g. width 10, height NULL) would pass
    create constraint(:posts, :image_dimensions,
             check: """
             (image_width IS NULL AND image_height IS NULL) OR
             (image_width IS NOT NULL AND image_height IS NOT NULL AND
              image_width > 0 AND image_height > 0)
             """
           )
  end
end
