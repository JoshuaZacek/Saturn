defmodule Saturn.NotificationsTest do
  use Saturn.DataCase

  alias Saturn.{Notifications, Notification, Comments, Votes, Realtime}

  setup do
    author = insert_user()
    post = insert_post(author)
    %{author: author, post: post}
  end

  defp notifications_for(user) do
    Repo.all(
      from(n in Notification,
        where: n.user_id == ^user.id,
        order_by: n.id,
        select: {n.type, n.count}
      )
    )
  end

  defp comment!(user, post, attrs \\ %{}) do
    params = Map.merge(%{"post_id" => post.id, "content" => "Hello"}, attrs)
    %Saturn.Comment{} = comment = Comments.create(params, user)
    comment
  end

  defp upvote(voter, target), do: :ok = Votes.create(Map.put(target, "vote", "up"), voter.id)
  defp downvote(voter, target), do: :ok = Votes.create(Map.put(target, "vote", "down"), voter.id)

  defp upvoters(n), do: for(_ <- 1..n, do: insert_user())

  describe "comments" do
    test "a comment on a post tells its author, live", %{author: author, post: post} do
      Realtime.register(author.id)
      commenter = insert_user()
      comment = comment!(commenter, post, %{"content" => "Nice post"})

      assert notifications_for(author) == [{"post_comment", nil}]
      assert_receive {:realtime, json}
      assert %{"event" => "notification", "data" => data} = Jason.decode!(json)
      assert data["actor"]["username"] == commenter.username
      assert data["comment"] == %{"id" => comment.id, "snippet" => "Nice post"}
      assert data["post"]["id"] == post.id
    end

    test "a reply tells the parent comment's author, not the post's", %{
      author: author,
      post: post
    } do
      parent_author = insert_user()
      parent = insert_comment(parent_author, post)
      comment!(insert_user(), post, %{"comment_id" => parent.id})

      assert notifications_for(parent_author) == [{"comment_reply", nil}]
      assert notifications_for(author) == []
    end

    test "nobody is told about their own comment or reply", %{author: author, post: post} do
      own = comment!(author, post)
      comment!(author, post, %{"comment_id" => own.id})

      assert notifications_for(author) == []
    end

    test "a reply to a deleted comment tells nobody", %{post: post} do
      parent_author = insert_user()
      parent = insert_comment(parent_author, post, deleted: true, content: "")
      comment!(insert_user(), post, %{"comment_id" => parent.id})

      assert notifications_for(parent_author) == []
    end

    test "deleting a comment that has replies removes what pointed at it", %{
      author: author,
      post: post
    } do
      commenter = insert_user()
      comment = comment!(commenter, post)
      insert_comment(insert_user(), post, comment_id: comment.id)

      {:ok, %{kept: true}} = Comments.delete(comment.id, commenter)

      assert notifications_for(author) == []
      assert Notifications.unread_count(author.id) == 0
    end
  end

  describe "upvote milestones" do
    test "every upvote under 5, then 10", %{author: author, post: post} do
      target = %{"post_id" => post.id}
      Enum.each(upvoters(9), &upvote(&1, target))
      assert notifications_for(author) == Enum.map([1, 2, 3, 4], &{"post_upvotes", &1})

      upvote(insert_user(), target)
      assert List.last(notifications_for(author)) == {"post_upvotes", 10}
      assert length(notifications_for(author)) == 5
    end

    test "a flip that jumps 9 to 11 still announces 10", %{author: author, post: post} do
      target = %{"post_id" => post.id}
      Enum.each(upvoters(10), &upvote(&1, target))
      Repo.delete_all(Notification)

      flipper = insert_user()
      downvote(flipper, target)
      assert notifications_for(author) == []

      # Score 9 to 11
      upvote(flipper, target)
      assert notifications_for(author) == [{"post_upvotes", 10}]
    end

    test "un-voting and voting again doesn't repeat a milestone", %{author: author, post: post} do
      target = %{"post_id" => post.id}
      [voter | _] = voters = upvoters(4)
      Enum.each(voters, &upvote(&1, target))

      Votes.delete(%{post_id: post.id, comment_id: nil}, voter.id)
      upvote(voter, target)
      upvote(voter, target)

      assert length(notifications_for(author)) == 4
    end

    test "the author's own upvote announces nothing", %{author: author, post: post} do
      upvote(author, %{"post_id" => post.id})
      assert notifications_for(author) == []
    end

    test "comments have milestones too", %{post: post} do
      comment_author = insert_user()
      comment = insert_comment(comment_author, post)
      Enum.each(upvoters(2), &upvote(&1, %{"comment_id" => comment.id}))

      assert notifications_for(comment_author) == [{"comment_upvotes", 1}, {"comment_upvotes", 2}]
    end

    test "milestone_for/1" do
      assert Notifications.milestone_for(0) == nil
      assert Notifications.milestone_for(-3) == nil
      assert Notifications.milestone_for(4) == 4
      assert Notifications.milestone_for(9) == 4
      assert Notifications.milestone_for(99) == 10
      assert Notifications.milestone_for(5_000) == 1000
    end
  end

  describe "the bell" do
    test "pages newest first, counts unread and marks all read", %{author: author, post: post} do
      commenter = insert_user()
      for _ <- 1..(Notifications.page_size() + 2), do: comment!(commenter, post)

      first = Notifications.list(author.id)
      assert length(first.notifications) == Notifications.page_size()
      assert first.has_more
      assert first.unread_count == Notifications.page_size() + 2
      ids = Enum.map(first.notifications, & &1.id)
      assert ids == Enum.sort(ids, :desc)

      second = Notifications.list(author.id, List.last(ids))
      assert length(second.notifications) == 2
      refute second.has_more

      Realtime.register(author.id)
      Notifications.mark_read(author.id)
      assert_receive {:realtime, json}
      assert %{"event" => "notifications_read", "data" => %{"ids" => nil}} = Jason.decode!(json)
      assert Notifications.unread_count(author.id) == 0
      assert Enum.all?(Notifications.list(author.id).notifications, & &1.read)
    end

    test "marks only the chosen ones read, and only the person's own", %{
      author: author,
      post: post
    } do
      commenter = insert_user()
      for _ <- 1..3, do: comment!(commenter, post)
      [newest, middle, _] = Enum.map(Notifications.list(author.id).notifications, & &1.id)

      someone_else = insert_user()
      Notifications.mark_read(someone_else.id, [newest])
      assert Notifications.unread_count(author.id) == 3

      Realtime.register(author.id)
      Notifications.mark_read(author.id, [newest, middle])
      assert_receive {:realtime, json}
      assert %{"data" => %{"ids" => [^newest, ^middle]}} = Jason.decode!(json)
      assert Notifications.unread_count(author.id) == 1
    end

    test "marks chosen ones unread again, but not someone else's or cleared ones", %{
      author: author,
      post: post
    } do
      commenter = insert_user()
      for _ <- 1..3, do: comment!(commenter, post)
      [newest, middle, oldest] = Enum.map(Notifications.list(author.id).notifications, & &1.id)
      Notifications.mark_read(author.id)
      Notifications.clear(author.id, oldest)

      Notifications.mark_unread(insert_user().id, [newest])
      assert Notifications.unread_count(author.id) == 0

      Realtime.register(author.id)
      Notifications.mark_unread(author.id, [newest, oldest])
      assert_receive {:realtime, json}

      assert %{"event" => "notifications_unread", "data" => %{"ids" => [^newest, ^oldest]}} =
               Jason.decode!(json)

      assert Notifications.unread_count(author.id) == 1
      read = Map.new(Notifications.list(author.id).notifications, &{&1.id, &1.read})
      assert read == %{newest => false, middle => true}
    end

    test "clearing hides one or all, and only the person's own", %{author: author, post: post} do
      commenter = insert_user()
      for _ <- 1..3, do: comment!(commenter, post)
      [newest | _] = Enum.map(Notifications.list(author.id).notifications, & &1.id)

      assert Notifications.clear(insert_user().id, newest) == {:error, :not_found}

      Realtime.register(author.id)
      assert Notifications.clear(author.id, newest) == :ok
      assert_receive {:realtime, json}

      assert %{"event" => "notifications_cleared", "data" => %{"id" => ^newest}} =
               Jason.decode!(json)

      assert length(Notifications.list(author.id).notifications) == 2
      assert Notifications.unread_count(author.id) == 2
      assert Notifications.clear(author.id, newest) == {:error, :not_found}

      assert Notifications.clear(author.id) == :ok

      assert Notifications.list(author.id) == %{
               notifications: [],
               has_more: false,
               unread_count: 0
             }
    end

    test "a cleared milestone is never announced again", %{author: author, post: post} do
      target = %{"post_id" => post.id}
      [voter] = upvoters(1)
      upvote(voter, target)
      Notifications.clear(author.id)

      Votes.delete(%{post_id: post.id, comment_id: nil}, voter.id)
      upvote(voter, target)

      assert notifications_for(author) == [{"post_upvotes", 1}]
      assert Notifications.list(author.id).notifications == []
    end

    test "only shows a person their own", %{author: author, post: post} do
      comment!(insert_user(), post)
      assert Notifications.list(insert_user().id).notifications == []
      assert length(Notifications.list(author.id).notifications) == 1
    end
  end
end
