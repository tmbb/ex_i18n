defmodule I18n.InvisibleMarker do
  alias :mnesia, as: Mnesia

  @table_name I18n.InvisibleMarker

  # The invisible marker system is a way to encode information
  # about the translation into the translation text using unicode
  # zero-width spaces. Those spaces can be rendered anywhere
  # (as long as the application doing the rendering supports Unicode)
  # and have zero influence on the visual output.
  #
  # The goal is for web applications to be able to "postprocess"
  # the strings using Javascript in a way that makes it possible
  # to inspect and edit translations at runtime.
  #
  # This is very inefficient (both in terms of CPU and memory usage)
  # and is meant to be used only in development or in some kind of
  # semi-public staging area. It should NEVER be used in production.
  #
  # On a high level, a unique translation ID will be encoded in
  # a base-4 system using 4 unicode zero-width spaces.
  # The translation ID is the key to a mnesia database that stores
  # recently generated translations.
  #
  # The storage system for these translations can be turned on and off
  # at runtime using I18n's configuration.
  #
  # When the text is rendered in a web browser, the web browser will
  # use Javascript to replace the ID (encoded as zero-width spaces)
  # by a "flag" which is actually a hyperlink to a part of the web
  # application that allows us to review and edit translations.
  #
  # The HTML and Javascript parts of this system are naturally outside I18n.
  # The only think this module provides is the translation database and functions
  # to encode/decode translation IDs.
  #
  # TODO: Implement periodic removal of older translations.

  # ----------------------------------------
  # Stateless part
  # ----------------------------------------

  # Unicode character "ZERO WIDTH SPACE"
  # - will encode 0
  @zws_0 << 0x200B::utf8 >>
  # Unicode character "ZERO WIDTH NON JOINER"
  # - will encode 1
  @zws_1 << 0x200C::utf8 >>
  # Unicode character "ZERO WIDTH JOINER"
  # - will encode 2
  @zws_2 << 0x200D::utf8 >>
  # Unicode character "ZERO WIDTH WORD JOINER"
  # - will encode 3
  @zws_3 << 0x2060::utf8 >>

  # Invisible encoding prefix
  @invisible_prefix String.duplicate(<< 0x200B::utf8 >>, 4)
  # This prefix is encoded as "0000"
  @invisible_encoded_prefix "0000"

  def with_id_encoded_as_invisible_marker(translated_message, hash, locale, bindings) do
    # This uniquely identifies the
    translation_id = persist_in_storage(translated_message, locale, hash, bindings)
    encoded_translation_id = encode_as_invisible(translation_id)
    # Return everything in an iolist:
    [encoded_translation_id, translated_message]
  end

  def fetch_from_encoded_id(encoded_id) do
    id = decode_id(encoded_id)
    fetch_from_storage(id)
  end

  def encode_as_invisible(binary), do: [@invisible_prefix | encode_as_invisible_(binary)]

  defp encode_as_invisible_(<< 0::size(2), rest::bitstring >>), do: [@zws_0 | encode_as_invisible_(rest)]
  defp encode_as_invisible_(<< 1::size(2), rest::bitstring >>), do: [@zws_1 | encode_as_invisible_(rest)]
  defp encode_as_invisible_(<< 2::size(2), rest::bitstring >>), do: [@zws_2 | encode_as_invisible_(rest)]
  defp encode_as_invisible_(<< 3::size(2), rest::bitstring >>), do: [@zws_3 | encode_as_invisible_(rest)]
  defp encode_as_invisible_(<< >>), do: []


  def decode_id(@invisible_encoded_prefix <> rest) do
    decode_bytes(rest)
  end


  defp decode_bytes(<<
        e0::bytes-size(4),
        e1::bytes-size(4),
        e2::bytes-size(4),
        e3::bytes-size(4),
        e4::bytes-size(4),
        e5::bytes-size(4),
        e6::bytes-size(4),
        e7::bytes-size(4),
        _rest::bytes()
      >>) do

    [e0, e1, e2, e3, e4, e5, e6, e7]
    |> Enum.map(&decode_byte/1)
    |> :erlang.iolist_to_binary()
  end


  defp decode_2bits(?0), do: 0
  defp decode_2bits(?1), do: 1
  defp decode_2bits(?2), do: 2
  defp decode_2bits(?3), do: 3


  defp decode_byte(<<
        e0::8,
        e1::8,
        e2::8,
        e3::8
      >>) do

    d0 = decode_2bits(e0)
    d1 = decode_2bits(e1)
    d2 = decode_2bits(e2)
    d3 = decode_2bits(e3)

    <<d0::2, d1::2, d2::2, d3::2>>
  end


  # ------------------------------------------------------
  # Stateful part
  # ------------------------------------------------------
  def setup() do
    # Create a schema in all nodes
    Mnesia.create_schema([Node.list()])
    # Ad a table for translations
    Mnesia.create_table(@table_name, [
      attributes: [
        :id,
        :timestamp,
        :translated,
        :hash,
        :locale,
        :bindings
      ]
    ])
    Mnesia.add_table_index(@table_name, :id)
    Mnesia.add_table_index(@table_name, :timestamp)
  end

  defp random_id() do
    b0 = :random.uniform(255)
    b1 = :random.uniform(255)
    b2 = :random.uniform(255)
    b3 = :random.uniform(255)
    b4 = :random.uniform(255)
    b5 = :random.uniform(255)
    b6 = :random.uniform(255)
    b7 = :random.uniform(255)

    <<
      b0::8,
      b1::8,
      b2::8,
      b3::8,
      b4::8,
      b5::8,
      b6::8,
      b7::8
    >>
  end

  def persist_in_storage(translated_iolist, locale, hash, bindings) do
    id = random_id()
    timestamp = :erlang.timestamp()
    translated_binary = to_string(translated_iolist)
    Mnesia.dirty_write({@table_name, id, timestamp, translated_binary, hash, locale, bindings})

    id
  end

  def fetch_from_storage(id) do
    case Mnesia.dirty_read(@table_name, id) do
      [result] -> {:ok, result}
      _ -> :error
    end
  end
end