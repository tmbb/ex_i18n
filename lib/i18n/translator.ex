defmodule I18n.Translator do
  @moduledoc false

  alias I18n.{
    Config,
    InvisibleMarker,
    TranslationData,
    Pseudolocalization
  }
  alias I18n.MessageHandlers.IcuMessageHandler

  require Logger

  @persistent_term_translations_key {I18n, :translations}
  @persistent_term_extracted_hash_set_key {I18n, :extracted_hash_set}

  @doc """
  Setup the translator system, by populating the map with the translations.
  """
  def setup(path \\ nil) do
    translations_path =
      case path do
        nil -> Config.translations_path()
        other -> other
      end

    translation_data = TranslationData.load_translation_data!(translations_path)

    translations =
      for {hash, message} <- translation_data.messages do
        for {locale_name, translation} <- message.translations do
          text = translation.text
          {:ok, parsed} = IcuMessageHandler.parse(text)

          {{hash, locale_name}, parsed}
        end
      end

    persistent_map =
      translations
      |> List.flatten()
      |> Enum.into(%{})

    put_translations(persistent_map)

    hashes = Enum.map(translation_data.messages, fn {hash, _message} -> hash end)
    hash_map_set = MapSet.new(hashes)

    put_extracted_hash_set(hash_map_set)

    :ok
  end

  defp lookup_translation({_hash, _locale} = key) do
    map = get_translations()
    Map.fetch(map, key)
  end

  @doc """
  Get the (global) translations map.
  """
  def get_translations() do
    :persistent_term.get(@persistent_term_translations_key)
  end

  @doc """
  Set the (global) translations map.
  """
  def put_translations(value) do
    :persistent_term.put(@persistent_term_translations_key, value)
  end

  @doc """
  Put the set of extracted hashes so that we can warn the user when
  a non-extracted message is used.
  """
  def put_extracted_hash_set(value) do
    :persistent_term.put(@persistent_term_extracted_hash_set_key, value)
  end

  @doc """
  Test whether the current hash belongs to a message that has been already extracted.
  """
  def extracted_hash?(hash) do
    map_set = :persistent_term.get(@persistent_term_extracted_hash_set_key)
    MapSet.member?(map_set, hash)
  end

  @doc """
  Translates a message.
  """
  def translate(hash, user_specified_locale, bindings, parsed_original, message) do
    # I18n will use Cldr locales and nothing else; no need to abstract this further.
    # TODO: make this work with configurable locale providers?
    locale = user_specified_locale || Cldr.get_locale()
    # We'll be using the locale name several times; this line saves us a map lookup.
    locale_name = locale.cldr_locale_name
    # TODO: should we use the locale as the full key?
    translation_lookup_key = {hash, locale_name}

    translated_iolist =
      case lookup_translation(translation_lookup_key) do
        # We've found a translation. Format the translated message.
        # This is the deafault case in production if everything goes well.
        {:ok, parsed_translation} ->
          IcuMessageHandler.format(parsed_translation, bindings, locale: locale)

        # We didn't find a translation. Format the original message.
        :error ->
          # From now on, everything wil be based on the original (untranslated) iolist.
          # We better generate it here and refer to it later instead of generating it
          # in each branch of the (admittedly complex) conditional.
          original_iolist = IcuMessageHandler.format(parsed_original, bindings, locale: locale)
          # Currently pseudolocalization of text and HTML is hardcoded in a case statement,
          # but in the future we should add a way to make it more dynamic.
          # Currently we support pseudolocalization of latin characters assuming
          # the English language.
          # TODO: add pseudolocalization registry in a way that's performant.
          case Map.get(locale.extensions, "m") do
            nil ->
              # No pseudolocalization! we can return the original iolist
              # (and log a warning if the message hasn't been extracted)
              iolist_maybe_with_warning(original_iolist, hash, message)

            extension_list when is_list(extension_list) ->
              cond do
                "pseudo" in extension_list ->
                  # We have to convert the iolist into a string because
                  # the pseudolocalization functions need a string in order to be intelligent
                  # when handling punctuation characters.
                  original_text = to_string(original_iolist)
                  Pseudolocalization.pseudolocalize_text(original_text)

                "pseudoht" in extension_list ->
                  # Same as above
                  original_html = to_string(original_iolist)
                  Pseudolocalization.pseudolocalize_html(original_html)

                true ->
                  # No (known) pseudolocalization! we can return the original iolist
                  # (and log a warning if the message hasn't been extracted)
                  iolist_maybe_with_warning(original_iolist, hash, message)
              end

            _other ->
              # No weird extensions! We can return the original iolist
              # (and log a warning if the message hasn't been extracted)
              iolist_maybe_with_warning(original_iolist, hash, message)
          end
      end

    # TODO: disable this at compile time to save an ETS lookup?
    if Config.invisible_markers?() do
      InvisibleMarker.with_id_encoded_as_invisible_marker(translated_iolist, hash, locale, [])
    else
      translated_iolist
    end
  end

  # Return the original iolist and maybe log a warning if the message
  # hasn't been translayed yet.
  defp iolist_maybe_with_warning(iolist, hash, message) do
    unless extracted_hash?(hash) do
      Logger.warn(fn ->
      file = message.location.file
      line = message.location.line
      # The tests depend on this message prefix!
      # If you change the prefix, change the tests too.
      "I18n - message not extracted (#{file}:#{line}): \"#{message.text}\""
      end)
    end

    iolist
  end
end
