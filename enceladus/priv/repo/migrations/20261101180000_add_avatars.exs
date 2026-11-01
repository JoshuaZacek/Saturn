defmodule Saturn.Repo.Migrations.AddAvatars do
  use Ecto.Migration

  # Kept here rather than read from Saturn.Avatars, so this migration doesn't change if that list does
  @colors ~w(red orange amber lime green teal cyan sky blue indigo purple pink)

  def up do
    for table <- [:users, :moons] do
      alter table(table) do
        add :avatar_color, :string
        add :avatar_image, :string
      end
    end

    flush()

    # Existing people and moons keep the colour they've had so far, which the frontend worked out
    # from their name. Everyone new gets a random one.
    backfill("users", "username")
    backfill("moons", "name")

    for table <- [:users, :moons] do
      execute "ALTER TABLE #{table} ALTER COLUMN avatar_color SET NOT NULL"

      create constraint(table, :avatar_color_choices,
               check: "avatar_color IN (#{Enum.map_join(@colors, ", ", &"'#{&1}'")})"
             )
    end

    # Pictures are uploaded files that belong to no post
    execute "ALTER TABLE files ALTER COLUMN post_id DROP NOT NULL"
  end

  def down do
    execute "DELETE FROM files WHERE post_id IS NULL"
    execute "ALTER TABLE files ALTER COLUMN post_id SET NOT NULL"

    for table <- [:users, :moons] do
      drop constraint(table, :avatar_color_choices)

      alter table(table) do
        remove :avatar_color
        remove :avatar_image
      end
    end
  end

  defp backfill(table, name_column) do
    %{rows: rows} = repo().query!("SELECT id, #{name_column} FROM #{table}")

    for [id, name] <- rows do
      repo().query!("UPDATE #{table} SET avatar_color = $1 WHERE id = $2", [name_color(name), id])
    end
  end

  # The frontend's old hash: (hash * 31 + code point) as an unsigned 32-bit integer, over the
  # lowercased name, then an index into the colours
  defp name_color(name) do
    hash =
      name
      |> String.downcase()
      |> String.to_charlist()
      |> Enum.reduce(0, fn code_point, hash -> rem(hash * 31 + code_point, 4_294_967_296) end)

    Enum.at(@colors, rem(hash, length(@colors)))
  end
end
