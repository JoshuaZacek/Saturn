defmodule Saturn.Files do
  alias Saturn.Repo

  def file_upload(file, user) do
    filename = Ecto.UUID.generate() <> Path.extname(file.filename)
    File.cp(file.path, Path.expand("./../files/#{filename}"))
    Repo.insert(Saturn.File.changeset(%Saturn.File{user_id: user.id}, %{filename: filename}))
  end

  def file_request(filename) do
    Repo.get_by(Saturn.File, filename: filename)
  end
end
