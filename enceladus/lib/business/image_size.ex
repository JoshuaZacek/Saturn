defmodule Saturn.ImageSize do
  # Reads the displayed pixel size of a PNG, GIF or JPEG from its bytes. Browsers apply a JPEG's
  # EXIF orientation, and orientations 5-8 turn it 90°, so those swap width and height.

  # PNG's own limit, which also keeps sizes within a Postgres integer
  @max_dimension 2_147_483_647

  def read(
        <<0x89, "PNG\r\n", 0x1A, "\n", _length::32, "IHDR", width::32, height::32, _::binary>>
      ),
      do: dimensions(width, height)

  def read(<<"GIF8", version, "a", width::little-16, height::little-16, _::binary>>)
      when version in [?7, ?9],
      do: dimensions(width, height)

  def read(<<0xFF, 0xD8, rest::binary>>), do: read_jpeg(rest, 1)

  def read(_), do: :error

  # Fill bytes before a marker
  defp read_jpeg(<<0xFF, 0xFF, rest::binary>>, orientation),
    do: read_jpeg(<<0xFF, rest::binary>>, orientation)

  # TEM and RST0-7 have no length
  defp read_jpeg(<<0xFF, marker, rest::binary>>, orientation)
       when marker == 0x01 or marker in 0xD0..0xD7,
       do: read_jpeg(rest, orientation)

  # Start of frame: SOF0-15, except DHT (C4), JPG (C8) and DAC (CC)
  defp read_jpeg(
         <<0xFF, marker, _length::16, _precision, height::16, width::16, _::binary>>,
         orientation
       )
       when marker in 0xC0..0xCF and marker not in [0xC4, 0xC8, 0xCC] do
    if orientation in 5..8, do: dimensions(height, width), else: dimensions(width, height)
  end

  # SOI, EOI or SOS (image data) before a frame header means it isn't an image we can size
  defp read_jpeg(<<0xFF, marker, _::binary>>, _) when marker in [0x00, 0xD8, 0xD9, 0xDA],
    do: :error

  defp read_jpeg(<<0xFF, marker, length::16, rest::binary>>, orientation) when length >= 2 do
    segment_length = length - 2

    case rest do
      <<segment::binary-size(^segment_length), rest::binary>> when marker == 0xE1 ->
        read_jpeg(rest, exif_orientation(segment) || orientation)

      <<_::binary-size(^segment_length), rest::binary>> ->
        read_jpeg(rest, orientation)

      _ ->
        :error
    end
  end

  defp read_jpeg(_, _), do: :error

  defp exif_orientation(<<"Exif", 0, 0, tiff::binary>>) do
    case tiff do
      <<"II", 42::little-16, ifd::little-32, _::binary>> -> ifd_orientation(tiff, ifd, :little)
      <<"MM", 42::big-16, ifd::big-32, _::binary>> -> ifd_orientation(tiff, ifd, :big)
      _ -> nil
    end
  end

  defp exif_orientation(_), do: nil

  defp ifd_orientation(tiff, ifd, endian) do
    case tiff do
      <<_::binary-size(^ifd), count::binary-size(2), entries::binary>> ->
        find_orientation(entries, :binary.decode_unsigned(count, endian), endian)

      _ ->
        nil
    end
  end

  # 12-byte entries: tag, type, count, then the value, left-justified in 4 bytes
  defp find_orientation(
         <<tag::binary-size(2), _type_and_count::binary-size(6), value::binary-size(2),
           _::binary-size(2), rest::binary>>,
         remaining,
         endian
       )
       when remaining > 0 do
    if :binary.decode_unsigned(tag, endian) == 0x0112,
      do: :binary.decode_unsigned(value, endian),
      else: find_orientation(rest, remaining - 1, endian)
  end

  defp find_orientation(_, _, _), do: nil

  defp dimensions(width, height)
       when width in 1..@max_dimension and height in 1..@max_dimension,
       do: {:ok, {width, height}}

  defp dimensions(_, _), do: :error
end
