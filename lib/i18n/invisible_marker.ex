defmodule I18n.InvisibleMarker do
  # The invisible marker system is a way to encode information
  # about the translation into the translation text using unicode
  # zero-width spaces. Those spaces can be rendered anywhere
  # (as long as the application doing the rendering supports Unicode)
  # and have zero influence on the visual output.
  #
  # The goal is for web applications to be able to "postprocess"
  # the strings using Javascript in a way that makes it possible
  # to inspect and edit translations at runtime.

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

  @zws_0_codepoint 0x200B
  @zws_1_codepoint 0x200C
  @zws_2_codepoint 0x200D
  @zws_3_codepoint 0x2060

  @invisible_markers_active :ex_i18n_invisible_marker_active
  @translations_hashes_key :ex_i18n_invisible_marker_translations_hashes
  @translations_locales_key :ex_i18n_invisible_marker_translations_locales

  # Invisible encoding prefix
  @invisible_prefix String.duplicate(<< 0x2060::utf8 >>, 2)

  def invisible_marker_active?() do
    Process.get(@invisible_markers_active, false)
  end

  def put_invisible_marker_activation_state(value) when value in [true, false] do
    Process.put(@invisible_markers_active, value)
  end

  def zws_to_base4_digit_map() do
    %{
      @zws_0_codepoint => 0,
      @zws_1_codepoint => 1,
      @zws_2_codepoint => 2,
      @zws_3_codepoint => 3
    }
  end

  def base4_digit_to_zws(digit) do
    case digit do
      0 -> @zws_0
      1 -> @zws_1
      2 -> @zws_2
      3 -> @zws_3
    end
  end

  def byte_to_zws(byte) do
    << z1::2, z2::2, z3::2, z4::2 >> = << byte::8 >>
    Enum.map([z1, z2, z3, z4], &base4_digit_to_zws/1)
  end

  def encode_integer(n) do
    << a::8, b::8, c::8 >> = << n :: 24 >>
    [@invisible_prefix | Enum.map([a, b, c], &byte_to_zws/1)]
  end

  defp update_locales_map(locale) do
    case Process.get(@translations_locales_key) do
      nil ->
        initial_map = %{locale => 0}
        Process.put(@translations_locales_key, {0, initial_map})
        0

      {counter, map} ->
        case Map.fetch(map, locale) do
          {:ok, index} ->
            index

          :error ->
            updated_map = Map.put(map, locale, counter)
            Process.put(@translations_locales_key, {counter + 1, updated_map})

            counter + 1
        end
    end
  end

  defp update_hashes_map(hash, locale_index) do
    case Process.get(@translations_hashes_key) do
      nil ->
        initial_list = [%{h: hash, l: locale_index}]
        Process.put(@translations_hashes_key, {1, initial_list})
        0

      {counter, list} ->
        updated_list = [%{h: hash, l: locale_index} | list]
        Process.put(@translations_hashes_key, {counter + 1, updated_list})
        counter
    end
  end

  def append_to_translations(hash, locale) do
    locale_index = update_locales_map(locale)
    hash_index = update_hashes_map(hash, locale_index)

    hash_index
  end

  defp invert_map(map) do
    map
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Enum.into(%{})
  end

  def get_invisible_markers_maps() do
    {_counter, hashes_map} = Process.get(@translations_hashes_key, {0, []})
    {_counter, locales_map} = Process.get(@translations_locales_key, {0, %{}})
    inverted_locales_map = invert_map(locales_map)

    %{
      hashes: hashes_map |> Enum.reverse(),
      locales: inverted_locales_map
    }
  end

  def encode_iolist(iolist, hash, locale, _bindings) do
    hash_index = append_to_translations(hash, locale)
    encoded_hash_index = encode_integer(hash_index)
    # IO.inspect(hash_index, label: "index")
    # IO.inspect(encoded_hash_index |> to_string() |> to_charlist() |> Enum.map(fn x -> rem(x, 10) end), label: "encoded_index")
    # IO.inspect(to_string(iolist), label: "text")
    # IO.puts("")
    [encoded_hash_index, iolist]
  end

  # # def with_id_encoded_as_invisible_marker(translated_message, hash, locale, bindings) do
  # #   # This uniquely identifies the
  # #   encoded_translation_id = encode_as_invisible(translation_id)
  # #   # Return everything in an iolist:
  # #   [encoded_translation_id, translated_message]
  # # end

  # def encode_as_invisible(binary), do: [@invisible_prefix | encode_as_invisible_(binary)]

  # defp encode_as_invisible_(<< 0::size(2), rest::bitstring >>), do: [@zws_0 | encode_as_invisible_(rest)]
  # defp encode_as_invisible_(<< 1::size(2), rest::bitstring >>), do: [@zws_1 | encode_as_invisible_(rest)]
  # defp encode_as_invisible_(<< 2::size(2), rest::bitstring >>), do: [@zws_2 | encode_as_invisible_(rest)]
  # defp encode_as_invisible_(<< 3::size(2), rest::bitstring >>), do: [@zws_3 | encode_as_invisible_(rest)]
  # defp encode_as_invisible_(<< >>), do: []


  # def decode_id(@invisible_encoded_prefix <> rest) do
  #   decode_bytes(rest)
  # end


  # defp decode_bytes(<<
  #       e0::bytes-size(4),
  #       e1::bytes-size(4),
  #       e2::bytes-size(4),
  #       e3::bytes-size(4),
  #       e4::bytes-size(4),
  #       e5::bytes-size(4),
  #       e6::bytes-size(4),
  #       e7::bytes-size(4),
  #       _rest::bytes()
  #     >>) do

  #   [e0, e1, e2, e3, e4, e5, e6, e7]
  #   |> Enum.map(&decode_byte/1)
  #   |> :erlang.iolist_to_binary()
  # end


  # defp decode_2bits(?0), do: 0
  # defp decode_2bits(?1), do: 1
  # defp decode_2bits(?2), do: 2
  # defp decode_2bits(?3), do: 3


  # defp decode_byte(<<
  #       e0::8,
  #       e1::8,
  #       e2::8,
  #       e3::8
  #     >>) do

  #   d0 = decode_2bits(e0)
  #   d1 = decode_2bits(e1)
  #   d2 = decode_2bits(e2)
  #   d3 = decode_2bits(e3)

  #   <<d0::2, d1::2, d2::2, d3::2>>
  # end
end