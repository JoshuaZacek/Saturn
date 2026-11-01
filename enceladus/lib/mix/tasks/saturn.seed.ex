defmodule Mix.Tasks.Saturn.Seed do
  @shortdoc "Fills a local database with placeholder people, moons, posts and comment threads"

  @moduledoc """
  Adds placeholder content for local development: people, moons, text posts spread over the last
  year (so every Top period has something), comment threads up to seven replies deep, votes and
  subscriptions.

      mix saturn.seed           # adds it, unless it's already there
      mix saturn.seed --reset   # removes it first, then adds it again

  Every placeholder account has an `@seed.saturn.test` email and the password `saturn-seed`, e.g.
  `nina@seed.saturn.test`. `--reset` deletes those accounts, which also deletes everything that
  depends on them: their posts, comments and votes, and their moons along with every post in them
  (including posts by real accounts). Nothing else is touched.
  """

  use Mix.Task
  import Ecto.Query
  alias Saturn.{Repo, User, Avatars}

  @requirements ["app.config"]

  @email_domain "seed.saturn.test"
  @password "saturn-seed"

  @impl true
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [reset: :boolean])
    # Not every query
    Logger.configure(level: :info)

    for app <- [:ecto_sql, :postgrex] do
      {:ok, _} = Application.ensure_all_started(app)
    end

    {:ok, _} = Repo.start_link()

    seeded = Repo.all(from(u in User, where: like(u.email, ^"%@#{@email_domain}"), select: u.id))

    cond do
      seeded != [] and !opts[:reset] ->
        Mix.shell().info(
          "Placeholder content is already there (#{length(seeded)} accounts). " <>
            "Run `mix saturn.seed --reset` to start it over."
        )

      true ->
        if seeded != [] do
          Repo.delete_all(from(u in User, where: u.id in ^seeded))
          Mix.shell().info("Removed the old placeholder content")
        end

        Repo.transaction(fn -> seed() end)
    end
  end

  defp seed do
    # The same votes every time
    :rand.seed(:exsss, {7, 11, 13})
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    password = Argon2.hash_pwd_salt(@password)

    users =
      for {username, joined_days_ago} <- people(), into: %{} do
        joined = ago(now, joined_days_ago * 24)

        {1, [%{id: id}]} =
          Repo.insert_all(
            "users",
            [
              %{
                username: username,
                email: "#{String.split(username, "_") |> hd()}@#{@email_domain}",
                password: password,
                avatar_color: Avatars.random_color(),
                inserted_at: joined,
                updated_at: joined
              }
            ],
            returning: [:id]
          )

        {username, id}
      end

    moons =
      for {name, owner, created_days_ago} <- moons(), into: %{} do
        created = ago(now, created_days_ago * 24)

        {1, [%{id: id}]} =
          Repo.insert_all(
            "moons",
            [
              %{
                name: name,
                user_id: users[owner],
                avatar_color: Avatars.random_color(),
                inserted_at: created,
                updated_at: created
              }
            ],
            returning: [:id]
          )

        {name, id}
      end

    owners = for {name, owner, _} <- moons(), into: %{}, do: {name, owner}

    # Owners follow their own moons; everyone else picks a few
    subscriptions =
      for {username, user_id} <- users,
          {name, moon_id} <- moons,
          owners[name] == username or :rand.uniform() < 0.45 do
        %{user_id: user_id, moon_id: moon_id, inserted_at: now, updated_at: now}
      end

    Repo.insert_all("subscriptions", subscriptions)

    counts =
      Enum.reduce(posts(), %{posts: 0, comments: 0}, fn post, counts ->
        posted = ago(now, post.hours_ago)

        {1, [%{id: post_id}]} =
          Repo.insert_all(
            "posts",
            [
              %{
                title: post.title,
                body: String.trim(post.body),
                type: "text",
                moon_id: moons[post.moon],
                user_id: users[post.by],
                inserted_at: posted,
                updated_at: posted
              }
            ],
            returning: [:id]
          )

        vote(:post_id, post_id, users, Map.get(post, :popularity, 0.5))
        comments = insert_comments(post.comments, post_id, nil, posted, users, now)

        %{posts: counts.posts + 1, comments: counts.comments + comments}
      end)

    Mix.shell().info(
      "Added #{map_size(users)} people, #{map_size(moons)} moons, #{counts.posts} posts and " <>
        "#{counts.comments} comments. Log in as e.g. nina@#{@email_domain} / #{@password}"
    )
  end

  # Each comment comes some minutes after what it replies to (but never in the future). Returns
  # how many were added.
  defp insert_comments(comments, post_id, parent_id, parent_time, users, now) do
    Enum.reduce(comments, 0, fn {by, minutes_after, content, replies}, count ->
      commented =
        Enum.min(
          [DateTime.add(parent_time, minutes_after * 60, :second), ago(now, 0.02)],
          DateTime
        )

      {1, [%{id: id}]} =
        Repo.insert_all(
          "comments",
          [
            %{
              post_id: post_id,
              comment_id: parent_id,
              user_id: users[by],
              content: content,
              inserted_at: commented,
              updated_at: commented
            }
          ],
          returning: [:id]
        )

      vote(:comment_id, id, users, 0.3)
      count + 1 + insert_comments(replies, post_id, id, commented, users, now)
    end)
  end

  # Mostly upvotes; `popularity` is the chance that each person votes at all
  defp vote(field, id, users, popularity) do
    votes =
      for {_username, user_id} <- users, :rand.uniform() < popularity do
        %{
          field => id,
          :user_id => user_id,
          :vote => if(:rand.uniform() < 0.85, do: 1, else: -1),
          :inserted_at => DateTime.utc_now() |> DateTime.truncate(:second),
          :updated_at => DateTime.utc_now() |> DateTime.truncate(:second)
        }
      end

    Repo.insert_all("votes", votes)
  end

  defp ago(now, hours), do: DateTime.add(now, -round(hours * 3600), :second)

  defp people do
    [
      {"nina_orbit", 420},
      {"tomas_k", 380},
      {"priya_s", 300},
      {"marcus_bakes", 260},
      {"lena_frames", 200},
      {"oli_runs", 150},
      {"sam_reads", 90},
      {"juno_dev", 40}
    ]
  end

  defp moons do
    [
      {"astronomy", "nina_orbit", 400},
      {"baking", "marcus_bakes", 250},
      {"photography", "lena_frames", 190},
      {"running", "oli_runs", 140},
      {"books", "sam_reads", 85},
      {"webdev", "juno_dev", 35}
    ]
  end

  # Comments are {author, minutes after the parent, text, replies}
  defp posts do
    [
      %{
        moon: "astronomy",
        by: "nina_orbit",
        hours_ago: 3,
        popularity: 0.9,
        title: "Saturn's rings were edge-on this year, and they're opening up again",
        body: """
        For a few weeks the rings almost vanished from small telescopes, because we were looking at them exactly edge-on. That only happens about every 13 to 15 years.

        They're tilting back towards us now. If you have any telescope at all, Saturn is high in the south after dark this month. Even at 50x the gap between the planet and the rings is obvious, and on a steady night you can pick out Titan as a little star nearby.

        Post your sketches or phone shots through the eyepiece. I'd love to see how they compare.
        """,
        comments: [
          {"tomas_k", 12,
           "Caught it last night with a 4\" refractor. The rings are still a thin line, but you can see their shadow on the globe.",
           [
             {"nina_orbit", 9,
              "That shadow is my favourite detail this year. Did you see Titan too?",
              [
                {"tomas_k", 21,
                 "Yes, well off to the east. Two fainter dots closer in that I think were Rhea and Dione.",
                 [
                   {"priya_s", 40,
                    "Stellarium will tell you which is which if you set the time exactly. It's a good way to check.",
                    [
                      {"tomas_k", 15, "Just did: Rhea and Tethys, not Dione. Close!",
                       [
                         {"nina_orbit", 8,
                          "Tethys is a good catch from the city. It's under 10th magnitude.",
                          [
                            {"juno_dev", 30, "This thread is making me want a telescope.", []}
                          ]}
                       ]}
                    ]}
                 ]}
              ]}
           ]},
          {"priya_s", 55,
           "Any tips for phone photos? Mine come out as a bright overexposed blob.",
           [
             {"lena_frames", 14,
              "Lock the exposure and pull it right down, then tap to focus on the planet. Video and stacking the frames helps even more.",
              []},
             {"nina_orbit", 22,
              "And use the lowest zoom you can. The phone's own zoom just enlarges the blur.", []}
           ]},
          {"sam_reads", 95, "Is there a good book for getting started with observing?",
           [
             {"nina_orbit", 6,
              "Turn Left at Orion. It's written for exactly the kind of telescope most people start with.",
              []}
           ]}
        ]
      },
      %{
        moon: "astronomy",
        by: "priya_s",
        hours_ago: 30,
        popularity: 0.6,
        title: "What's the darkest sky you've ever been under?",
        body:
          "Mine was a campsite in the Atacama. The Milky Way cast shadows, which I didn't believe was possible until I saw it. Where's yours?",
        comments: [
          {"oli_runs", 20,
           "Northumberland, in winter. Cold enough that my eyelashes froze, worth every second.",
           []},
          {"tomas_k", 45,
           "A ferry across the North Sea at 3am. No lights anywhere, just the deck rail and stars down to the waterline.",
           [
             {"priya_s", 10, "That sounds unreal. Did you have binoculars?",
              [{"tomas_k", 5, "Sadly not. I've packed them for every trip since.", []}]}
           ]}
        ]
      },
      %{
        moon: "astronomy",
        by: "tomas_k",
        hours_ago: 24 * 9,
        popularity: 0.4,
        title: "Beginner question: why do stars twinkle but planets mostly don't?",
        body: "I've heard this is a way to tell them apart, but I don't understand why it works.",
        comments: [
          {"nina_orbit", 30,
           "Stars are so far away that they're points of light, so turbulence in our air bends that single point around. Planets are tiny discs, and the wobble from each part of the disc averages out.",
           [
             {"tomas_k", 12, "That's a great way to put it, thank you.", []}
           ]}
        ]
      },
      %{
        moon: "baking",
        by: "marcus_bakes",
        hours_ago: 6,
        popularity: 0.8,
        title: "My sourdough finally has an open crumb. Here's what changed",
        body: """
        After about four months of tight, gummy loaves, the last three have come out properly open. Three things made the difference:

        1. A much stronger starter. I feed it twice a day for two days before baking, and only use it at its peak.
        2. Wetter dough: 78% hydration instead of 70%. It's harder to shape, but it's the single biggest change.
        3. Longer bulk fermentation, by the dough rather than the clock. I wait for it to grow about 50% and feel airy.

        I'm still learning to shape wet dough without deflating it, so tips are welcome.
        """,
        comments: [
          {"lena_frames", 25, "What flour are you using? I can never get past 72% without soup.",
           [
             {"marcus_bakes", 18,
              "A strong bread flour with about 13% protein, and 10% wholemeal. The weaker flours I tried couldn't hold that much water.",
              [
                {"lena_frames", 11, "That's probably my problem. Mine is plain flour.", []}
              ]}
           ]},
          {"sam_reads", 70, "Do you do stretch and folds or coil folds?",
           [
             {"marcus_bakes", 9,
              "Coil folds, four sets 30 minutes apart. They're gentler on a wet dough.", []}
           ]},
          {"juno_dev", 120, "Saving this. My loaves look like frisbees.",
           [
             {"marcus_bakes", 4,
              "We've all made frisbees. Starter first, everything else second.", []}
           ]}
        ]
      },
      %{
        moon: "baking",
        by: "priya_s",
        hours_ago: 24 * 4,
        popularity: 0.5,
        title: "Brown butter makes everything better: cookies edition",
        body:
          "Swapped the melted butter in my usual chocolate chip recipe for brown butter and let the dough rest overnight. They taste like toffee now. Highly recommend.",
        comments: [
          {"marcus_bakes", 40,
           "The overnight rest is underrated. The flour hydrates and the sugar deepens.", []}
        ]
      },
      %{
        moon: "baking",
        by: "marcus_bakes",
        hours_ago: 24 * 45,
        popularity: 0.3,
        title: "Weekly thread: what did you bake this week?",
        body: "Share anything, successes and disasters alike.",
        comments: [
          {"oli_runs", 60, "Banana bread, because the bananas were judging me.", []},
          {"priya_s", 90, "Focaccia with far too much rosemary. Still ate all of it.", []},
          {"nina_orbit", 200,
           "Nothing, but I watched a lot of other people bake. Does that count?",
           [{"marcus_bakes", 30, "It absolutely counts.", []}]}
        ]
      },
      %{
        moon: "photography",
        by: "lena_frames",
        hours_ago: 14,
        popularity: 0.7,
        title: "Shooting only a 35mm prime for a month taught me more than any new lens",
        body: """
        I left the zoom at home for all of October. At first I kept wishing I could get closer, but by the second week I'd stopped thinking about focal length entirely and started moving my feet.

        The pictures I'm proudest of from that month are all ones I'd have framed differently, and worse, with a zoom. If you're feeling stuck, try it.
        """,
        comments: [
          {"tomas_k", 35, "35 or 50? I can never decide which to commit to.",
           [
             {"lena_frames", 7,
              "35 for streets and travel, 50 if you mostly photograph people. But either is better than switching every day.",
              []},
             {"priya_s", 25, "I'm firmly team 28. Wider, but you have to get close.", []}
           ]},
          {"oli_runs", 80, "Did you crop much afterwards?",
           [{"lena_frames", 5, "Almost never, which was half the point.", []}]}
        ]
      },
      %{
        moon: "photography",
        by: "tomas_k",
        hours_ago: 24 * 2,
        popularity: 0.4,
        title: "How do you back up your photos?",
        body:
          "I had a scare last week when an SD card died. Looking for a simple routine that I'll actually stick to.",
        comments: [
          {"juno_dev", 15,
           "3-2-1: three copies, two kinds of storage, one somewhere else. For me that's the laptop, an external drive, and a cloud folder.",
           [
             {"tomas_k", 30, "And you copy them off the card the same day?",
              [
                {"juno_dev", 6, "Same evening, before I format anything. It's become a habit.",
                 []}
              ]}
           ]}
        ]
      },
      %{
        moon: "photography",
        by: "lena_frames",
        hours_ago: 24 * 120,
        popularity: 0.6,
        title: "Golden hour is overrated. Try blue hour",
        body:
          "The twenty minutes after sunset, when the sky goes deep blue and the city lights come on, is when I get my favourite shots. Bring a tripod.",
        comments: []
      },
      %{
        moon: "running",
        by: "oli_runs",
        hours_ago: 1.5,
        popularity: 0.6,
        title: "Ran my first half marathon this morning!",
        body:
          "2:04, which is four minutes faster than I hoped. My legs are completely gone and I'm already looking at the next one. Thank you to everyone here for the training advice over the summer.",
        comments: [
          {"marcus_bakes", 18, "Congratulations! That's a great first time.", []},
          {"priya_s", 25, "Amazing! How did you pace it?",
           [
             {"oli_runs", 10,
              "Held back for the first 10k, which felt far too easy, then let go. Negative split by almost two minutes.",
              []}
           ]}
        ]
      },
      %{
        moon: "running",
        by: "oli_runs",
        hours_ago: 24 * 6,
        popularity: 0.5,
        title: "Easy runs should feel embarrassingly slow",
        body: """
        This was the biggest change in my training. I used to run every run at the same moderately hard pace, and I was always a bit tired and never got faster.

        Now about 80% of my running is slow enough that I can hold a full conversation. The hard days are harder, and the easy days actually let me recover.
        """,
        comments: [
          {"sam_reads", 45,
           "How do you know if it's slow enough? I don't have a heart rate monitor.",
           [
             {"oli_runs", 12, "If you can say a full sentence without gasping, you're there.",
              [
                {"sam_reads", 20, "That's much slower than I'd like to admit.",
                 [
                   {"oli_runs", 3, "That's the point!", []}
                 ]}
              ]}
           ]}
        ]
      },
      %{
        moon: "running",
        by: "nina_orbit",
        hours_ago: 24 * 100,
        popularity: 0.3,
        title: "Running in the dark: what lights do you use?",
        body: "Winter is coming and I need to be seen. Head torch, chest light, both?",
        comments: [
          {"oli_runs", 50, "A head torch and a small red light clipped on the back.", []}
        ]
      },
      %{
        moon: "books",
        by: "sam_reads",
        hours_ago: 20,
        popularity: 0.6,
        title: "What book do you wish you could read again for the first time?",
        body: "For me it's The Left Hand of Darkness. I had no idea where it was going.",
        comments: [
          {"nina_orbit", 14, "Project Hail Mary. The reveal halfway through got me completely.",
           [
             {"sam_reads", 9, "Yes! I couldn't put it down for two days.", []},
             {"juno_dev", 30, "Adding it to my list. No spoilers please!",
              [
                {"nina_orbit", 4, "Wouldn't dream of it.", []}
              ]}
           ]},
          {"lena_frames", 40,
           "A Wizard of Earthsea. I read it far too young and want to try again.", []},
          {"tomas_k", 75, "Piranesi. It's so strange and gentle.",
           [
             {"sam_reads", 8, "Piranesi is a perfect book. Short, too.", []}
           ]}
        ]
      },
      %{
        moon: "books",
        by: "sam_reads",
        hours_ago: 24 * 15,
        popularity: 0.4,
        title: "Monthly reading thread",
        body: "What are you reading, and would you recommend it so far?",
        comments: [
          {"priya_s", 30,
           "The Overstory. Slow at first, but I think about trees differently now.", []},
          {"marcus_bakes", 100, "Bread by Jeffrey Hamelman. Yes, it counts as reading.",
           [{"sam_reads", 12, "It definitely counts.", []}]}
        ]
      },
      %{
        moon: "books",
        by: "priya_s",
        hours_ago: 24 * 70,
        popularity: 0.2,
        title: "Audiobooks or paper?",
        body:
          "I've switched to mostly audiobooks for my commute, and I'm curious how others split it.",
        comments: []
      },
      %{
        moon: "webdev",
        by: "juno_dev",
        hours_ago: 0.5,
        popularity: 0.3,
        title: "TIL: the dialog element handles focus trapping for you",
        body: """
        I've been hand-rolling modal focus traps for years. A native <dialog> opened with showModal() makes the rest of the page inert, puts focus inside, closes on Escape and gives you a ::backdrop to style.

        You still need to put focus back where it was when it closes, but that's one line.
        """,
        comments: [
          {"tomas_k", 10, "And it's in every current browser now, isn't it?",
           [{"juno_dev", 4, "Yes, it's been safe to use for a couple of years.", []}]}
        ]
      },
      %{
        moon: "webdev",
        by: "juno_dev",
        hours_ago: 24 * 3,
        popularity: 0.5,
        title: "Container queries changed how I build components",
        body:
          "Cards that lay themselves out based on the space they're given, rather than the size of the window. I've deleted so many breakpoints.",
        comments: [
          {"lena_frames", 22, "Is there a good introduction you'd recommend?", []},
          {"priya_s", 60,
           "Same experience here. The tricky part was remembering to set container-type on the parent.",
           [
             {"juno_dev", 7, "That one gets me every single time.", []}
           ]}
        ]
      },
      %{
        moon: "webdev",
        by: "tomas_k",
        hours_ago: 24 * 25,
        popularity: 0.3,
        title: "Light and dark themes: do you test both every time?",
        body:
          "I keep shipping things that look fine in light mode and terrible in dark. Looking for a habit or a tool that catches it.",
        comments: [
          {"juno_dev", 35,
           "Screenshots of every page in both themes, before anything is called done. It's boring, and it catches nearly everything.",
           []}
        ]
      }
    ]
  end
end
