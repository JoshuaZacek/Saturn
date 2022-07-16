defmodule Saturn.Functions do
  import Ecto.Changeset

  def format_changeset(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn
      {:password, ["incorrect"]} ->
        {:password, ["Incorrect password"]}

      {key, value} ->
        {key,
         Enum.map(value, fn message ->
           "#{key |> Atom.to_string() |> String.capitalize()} #{message}"
         end)}
    end)
    |> Enum.into(%{})
  end
end
