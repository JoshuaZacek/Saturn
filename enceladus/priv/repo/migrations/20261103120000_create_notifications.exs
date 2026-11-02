defmodule Saturn.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def up do
    create table(:notifications) do
      # Who it's for
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      # post_comment | comment_reply | post_upvotes | comment_upvotes
      add(:type, :text, null: false)

      # Who caused it (the commenter); null for upvote milestones, or once they delete their account
      add(:actor_id, references(:users, on_delete: :nilify_all))
      add(:post_id, references(:posts, on_delete: :delete_all), null: false)
      # The new comment (post_comment, comment_reply) or the upvoted comment (comment_upvotes)
      add(:comment_id, references(:comments, on_delete: :delete_all))
      # The milestone reached, for upvote notifications
      add(:count, :integer)
      add(:read_at, :utc_datetime)
      # Cleared by the person: hidden from them, but kept, so a cleared upvote milestone is never
      # announced again
      add(:cleared_at, :utc_datetime)

      add(:inserted_at, :utc_datetime, null: false, default: fragment("now()"))
    end

    create(index(:notifications, [:user_id, "id DESC"]))

    create(
      index(:notifications, [:user_id],
        where: "read_at IS NULL AND cleared_at IS NULL",
        name: :notifications_unread_index
      )
    )

    create(index(:notifications, [:comment_id]))

    # Each upvote milestone is announced once per post or comment
    create(
      unique_index(:notifications, [:post_id, :count],
        where: "type = 'post_upvotes'",
        name: :notifications_post_milestone_index
      )
    )

    create(
      unique_index(:notifications, [:comment_id, :count],
        where: "type = 'comment_upvotes'",
        name: :notifications_comment_milestone_index
      )
    )

    create(
      constraint(:notifications, :notification_type,
        check: "type IN ('post_comment', 'comment_reply', 'post_upvotes', 'comment_upvotes')"
      )
    )

    alter table(:users) do
      # The last time they used the site (throttled to every few minutes). Starts at now so
      # existing accounts don't all look long-inactive.
      add(:last_seen_at, :utc_datetime, null: false, default: fragment("now()"))
    end
  end

  def down do
    alter table(:users) do
      remove(:last_seen_at)
    end

    drop(table(:notifications))
  end
end
