defmodule Saturn.Repo.Migrations.AddMoonNameLengthConstraint do
  use Ecto.Migration

  def change do
    create constraint(:moons, :name_length, check: "char_length(name) <= 20")
  end
end
