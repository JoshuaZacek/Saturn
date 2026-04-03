defmodule Saturn.Files do
  import Ecto.Query

  alias Saturn.Repo

  @allowed_extensions [".jpg", ".jpeg", ".png", ".gif"]

  def upload(file) do
    file_extension = Path.extname(String.downcase(file.filename))

    case file_extension do
      file_extension when file_extension in @allowed_extensions ->
        filename = Ecto.UUID.generate() <> file_extension

        case upload_to_s3(file, filename) do
          :ok -> {:ok, filename}
          {:error, _reason} -> {:error, :upload_failed}
        end

      _ ->
        {:error, :file_not_supported}
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
        get_download_url(filename)
    end
  end

  def delete(filename) do
    case delete_from_s3(filename) do
      :ok ->
        from(f in Saturn.File, where: f.filename == ^filename) |> Repo.one!() |> Repo.delete!()
        :ok

      {:error, reason} -> {:error, reason}
    end
  end

  defp upload_to_s3(file, filename) do
    bucket = s3_bucket!()
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

  defp get_download_url(filename) do
    bucket = s3_bucket!()
    s3_config = ExAws.Config.new(:s3)
    ttl = Application.fetch_env!(:saturn, Saturn.Files)[:s3_signed_url_ttl]

    ExAws.S3.presigned_url(s3_config, :get, bucket, filename, expires_in: ttl)
  end

  defp delete_from_s3(filename) do
    bucket = s3_bucket!()

    bucket
    |> ExAws.S3.delete_object(filename)
    |> ExAws.request()
    |> case do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp s3_bucket! do
    bucket = Application.fetch_env!(:saturn, Saturn.Files)[:s3_bucket]

    if bucket in [nil, ""] do
      raise "missing S3 bucket configuration: set S3_BUCKET"
    end

    bucket
  end
end
