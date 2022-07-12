defmodule Saturn.Files do
  import Ecto.Query

  alias Saturn.Repo

  def upload(file) do
    file_extension = Path.extname(String.downcase(file.filename))

    case file_extension do
      file_extension when file_extension in [".jpg", ".jpeg", ".png", ".gif"] ->
        filename = Ecto.UUID.generate() <> file_extension
        File.cp(file.path, Path.expand("./../files/#{filename}"))

        {:ok, filename}

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
        Path.expand("./../files/#{filename}")
    end
  end

  def delete(filename) do
    from(f in Saturn.File, where: f.filename == ^filename) |> Repo.one!() |> Repo.delete!()
    File.rm!(Path.expand("./../files/#{filename}"))
  end
end
