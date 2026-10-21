defmodule Saturn.Repo.Migrations.AddCommentContentLengthConstraint do
  use Ecto.Migration

  def change do
    create constraint(:comments, :content_length, check: "char_length(content) <= 5000")
  end
end
