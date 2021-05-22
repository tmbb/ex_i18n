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

  @doc """
  TODO
  """
  def invisible_marker_active?() do
    Process.get(@invisible_markers_active, false)
  end

  @doc """
  TODO
  """
  def activate_invisible_markers() do
    put_invisible_marker_activation_state(true)
  end

  @doc """
  TODO
  """
  def deactivate_invisible_markers() do
    put_invisible_marker_activation_state(false)
  end

  @doc """
  TODO
  """
  def put_invisible_marker_activation_state(value) when value in [true, false] do
    Process.put(@invisible_markers_active, value)
    :ok
  end

  @doc """
  A map from zero-width space codepoint to the base-4 digits they encode.
  """
  def zws_to_base4_digit_map() do
    %{
      @zws_0_codepoint => 0,
      @zws_1_codepoint => 1,
      @zws_2_codepoint => 2,
      @zws_3_codepoint => 3
    }
  end

  @doc """
  Encode a single base-4 digit as a zero-width space binary.
  """
  def base4_digit_to_zws(digit) do
    # We return binaries isntead of codepoints becausse iolists can't
    # contain unicode characters outside the ascii range
    # (this makes total sense, as the BEAM can't assume everything is unicode)
    case digit do
      0 -> @zws_0
      1 -> @zws_1
      2 -> @zws_2
      3 -> @zws_3
    end
  end

  @doc """
  Encode a single base-4 digit as a zero-width space codepoint.
  """
  def base4_digit_to_zws_codepoint(digit) do
    case digit do
      0 -> @zws_0_codepoint
      1 -> @zws_1_codepoint
      2 -> @zws_2_codepoint
      3 -> @zws_3_codepoint
    end
  end

  defp byte_to_zws(byte) do
    << z1::2, z2::2, z3::2, z4::2 >> = << byte::8 >>
    Enum.map([z1, z2, z3, z4], &base4_digit_to_zws/1)
  end

  defp encode_integer(n) do
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

  defp append_to_translations(hash, locale) do
    locale_index = update_locales_map(locale)
    hash_index = update_hashes_map(hash, locale_index)

    hash_index
  end

  defp invert_map(map) do
    map
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Enum.into(%{})
  end

  def get_invisible_markers_data() do
    {_counter, hashes_list} = Process.get(@translations_hashes_key, {0, []})
    {_counter, locales_map} = Process.get(@translations_locales_key, {0, %{}})
    inverted_locales_map = invert_map(locales_map)

    %{
      hashes: hashes_list |> Enum.reverse(),
      locales: inverted_locales_map
    }
  end

  def encode_iolist(iolist, hash, locale, _bindings) do
    hash_index = append_to_translations(hash, locale)
    encoded_hash_index = encode_integer(hash_index)

    [encoded_hash_index, iolist]
  end
end
