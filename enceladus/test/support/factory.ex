defmodule Saturn.Factory do
  @moduledoc "Rows for tests, inserted directly (no changesets, so no hooks run)."
  alias Saturn.{Repo, User, Moon, Post, Comment}

  def insert_user(attrs \\ []) do
    n = System.unique_integer([:positive])

    Repo.insert!(
      struct(
        %User{username: "user#{n}", email: "user#{n}@test.saturn", password: "not-a-real-hash"},
        attrs
      )
    )
  end

  def insert_moon(owner) do
    Repo.insert!(%Moon{name: "moon#{System.unique_integer([:positive])}", user_id: owner.id})
  end

  def insert_post(author, attrs \\ []) do
    moon = insert_moon(author)

    Repo.insert!(
      struct(
        %Post{
          title: "A post",
          body: "Its text",
          type: "text",
          user_id: author.id,
          moon_id: moon.id
        },
        attrs
      )
    )
  end

  def insert_comment(author, post, attrs \\ []) do
    Repo.insert!(
      struct(%Comment{content: "A comment", user_id: author.id, post_id: post.id}, attrs)
    )
  end
end
