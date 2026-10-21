defmodule Mix.Tasks.Saturn.BackfillImageDimensions do
  @shortdoc "Stores the pixel size of image posts that don't have one yet"

  @moduledoc """
  Downloads the file of each image post without `image_width`/`image_height` from S3, reads its
  pixel size and stores it. A post whose file is missing or isn't a readable image stays null.

      mix saturn.backfill_image_dimensions [--dry-run]

  `--dry-run` reads the files and reports what it would store, without updating any posts.
  """

  use Mix.Task
  import Ecto.Query
  alias Saturn.{Repo, Post, Files, ImageSize}

  @requirements ["app.config"]

  @impl true
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [dry_run: :boolean])

    # Set up like Saturn.Application, without the HTTP server: the dotenv app exports .env, then
    # the config is reloaded so the S3 settings can see it
    {:ok, _} = Application.ensure_all_started(:dotenv)
    Mix.Task.rerun("loadconfig")

    for app <- [:ecto_sql, :postgrex, :hackney, :ex_aws] do
      {:ok, _} = Application.ensure_all_started(app)
    end

    {:ok, _} = Repo.start_link()
    backfill(dry_run: Keyword.get(opts, :dry_run, false))
  end

  def backfill(opts) do
    posts =
      Repo.all(
        from(p in Post,
          where: p.type == "image" and is_nil(p.image_width),
          order_by: p.id,
          select: {p.id, p.body}
        )
      )

    Mix.shell().info("#{length(posts)} image post(s) without dimensions")

    results =
      for {id, filename} <- posts do
        result =
          with {:ok, contents} <- Files.download(filename),
               {:ok, {width, height}} <- ImageSize.read(contents) do
            unless opts[:dry_run] do
              Repo.update_all(from(p in Post, where: p.id == ^id),
                set: [image_width: width, image_height: height]
              )
            end

            {:updated, "#{width}x#{height}"}
          else
            {:error, :missing_s3_config} -> Mix.raise("S3 isn't configured (S3_BUCKET is empty)")
            {:error, reason} -> {:not_downloaded, inspect(reason)}
            :error -> {:unreadable, "not a PNG, GIF or JPEG we can read"}
          end

        Mix.shell().info("post #{id} (#{filename}): #{elem(result, 0)} #{elem(result, 1)}")
        elem(result, 0)
      end

    counts = Enum.frequencies(results)

    Mix.shell().info(
      "#{if opts[:dry_run], do: "Would update", else: "Updated"} #{counts[:updated] || 0}, " <>
        "couldn't download #{counts[:not_downloaded] || 0}, unreadable #{counts[:unreadable] || 0}"
    )

    counts
  end
end
