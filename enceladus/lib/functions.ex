defmodule Saturn.Functions do
  import Ecto.Changeset

  # Ids are Postgres bigints. A larger integer can't match a row, and Postgrex raises on it
  @max_bigint 9_223_372_036_854_775_807

  @cursor_fields %{"new" => ["inserted_at", "id"], "top" => ["votes", "id"], "row" => ["row"]}

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

  # Tarams field for an id param
  def id_param(opts \\ []) do
    Keyword.merge([type: :integer, number: [min: 1, max: @max_bigint]], opts)
  end

  def validate_id(changeset, field) do
    validate_number(changeset, field,
      greater_than: 0,
      less_than_or_equal_to: @max_bigint,
      message: "does not exist"
    )
  end

  # Decodes a next_cursor for a "new", "top" or "row" (profile overview) listing. A cursor without
  # the integers that listing needs (e.g. edited by hand) is nil, the first page, rather than a
  # query that can't run.
  def parse_cursor(cursor, sort) do
    fields = Map.fetch!(@cursor_fields, sort)

    with true <- is_binary(cursor),
         {:ok, json} <- Base.url_decode64(cursor),
         {:ok, %{} = decoded} <- Jason.decode(json),
         true <- Enum.all?(fields, &bigint?(decoded[&1])),
         {:ok, decoded} <- cursor_datetime(decoded) do
      decoded
    else
      _ -> nil
    end
  end

  defp bigint?(value), do: is_integer(value) and abs(value) <= @max_bigint

  defp cursor_datetime(%{"inserted_at" => unix} = cursor) do
    with {:ok, datetime} <- DateTime.from_unix(unix) do
      {:ok, %{cursor | "inserted_at" => datetime}}
    end
  end

  defp cursor_datetime(cursor), do: {:ok, cursor}
end
