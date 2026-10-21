defmodule Saturn.Files do
  import Ecto.Query

  alias Saturn.{Repo, ImageSize}

  @allowed_extensions [".jpg", ".jpeg", ".png", ".gif"]

  # The file must really be an image (not just named like one), so its size can be stored
  def upload(file) do
    file_extension = Path.extname(String.downcase(file.filename))

    with true <- file_extension in @allowed_extensions,
         {:ok, contents} <- File.read(file.path),
         {:ok, {width, height}} <- ImageSize.read(contents) do
      filename = Ecto.UUID.generate() <> file_extension

      case upload_to_s3(file, filename) do
        :ok -> {:ok, %{filename: filename, width: width, height: height}}
        {:error, :missing_s3_config} -> {:error, :missing_s3_config}
        {:error, _reason} -> {:error, :upload_failed}
      end
    else
      _ -> {:error, :file_not_supported}
    end
  end

  def download(filename) do
    with {:ok, bucket} <- s3_bucket() do
      case bucket |> ExAws.S3.get_object(filename) |> ExAws.request() do
        {:ok, %{body: body}} -> {:ok, body}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def insert_db(filename, user, post) do
    Repo.insert(
      Saturn.File.changeset(%Saturn.File{user_id: user.id, post_id: post.id}, %{
        filename: filename
      })
    )
  end

  def get(filename) do
    case Repo.get_by(Saturn.File, filename: filename) do
      nil ->
        nil

      _ ->
        case get_download_url(filename) do
          {:ok, url} -> {:ok, url}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def delete(filename) do
    case delete_from_s3(filename) do
      :ok ->
        from(f in Saturn.File, where: f.filename == ^filename) |> Repo.one!() |> Repo.delete!()
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp upload_to_s3(file, filename) do
    with {:ok, bucket} <- s3_bucket() do
      content_type = MIME.from_path(file.filename)

      file.path
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(bucket, filename, content_type: content_type)
      |> ExAws.request()
      |> case do
        {:ok, _response} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp get_download_url(filename) do
    with {:ok, bucket} <- s3_bucket() do
      s3_config = ExAws.Config.new(:s3)
      ttl = Application.fetch_env!(:saturn, Saturn.Files)[:s3_signed_url_ttl]

      ExAws.S3.presigned_url(s3_config, :get, bucket, filename, expires_in: ttl)
    end
  end

  defp delete_from_s3(filename) do
    with {:ok, bucket} <- s3_bucket() do
      bucket
      |> ExAws.S3.delete_object(filename)
      |> ExAws.request()
      |> case do
        {:ok, _response} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp s3_bucket do
    bucket = Application.fetch_env!(:saturn, Saturn.Files)[:s3_bucket]

    if bucket in [nil, ""] do
      {:error, :missing_s3_config}
    else
      {:ok, bucket}
    end
  end
end
