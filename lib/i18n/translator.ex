defmodule I18n.Translator do
  @moduledoc """
  Utilities to store the message translations and to make use of them
  to actually translate the messages.
  """

  alias I18n.{
    Config,
    InvisibleMarker,
    TranslationData,
    Pseudolocalization
  }
  alias I18n.IcuMessageHandler

  require Logger

  @persistent_term_translations_key {I18n, :translations}
  @persistent_term_extracted_hash_set_key {I18n, :extracted_hash_set}
  @persistent_term_translator_data_key {I18n, :translator_data}

  # Return the original iolist and maybe log a warning if the message
  # hasn't been translayed yet.
  defmacrop iolist_maybe_with_warning(iolist, hash, message) do
    quote do
      # Don't remove these parenteses!
      # We need this to be a block, so that the first expression is run for the side-effects
      # and the second expression is returned
      (
        unless extracted_hash?(unquote(hash)) do
          Logger.warn(fn ->
            message = unquote(message)
            file = message.location.file
            line = message.location.line
            # The tests depend on this message prefix!
            # If you change the prefix, change the tests too.
            "I18n - message not extracted (#{file}:#{line}): \"#{message.text}\""
          end)
        end

        unquote(iolist)
      )
    end
  end

  # Main translation function.
  # This function will use the data in the persistent part to translate a given message.

  @doc false
  def translate(hash, user_specified_locale, bindings, parsed_original, message) do
    # I18n will use Cldr locales and nothing else; no need to abstract this further.
    locale = user_specified_locale || Cldr.get_locale()
    # We'll be using the locale name several times; this line saves us a map lookup.
    locale_name = locale.cldr_locale_name
    # TODO: should we use the locale as the full key?
    # Probably not because things are much easier if we serialize locales as a string.
    translation_lookup_key = {hash, locale_name}

    {is_pseudo?, translated_iolist} =
      case lookup_translation(translation_lookup_key) do
        # We've found a translation. Format the translated message.
        # This is the deafault case in production if everything goes well.
        {:ok, parsed_translation} ->
          iolist = IcuMessageHandler.format(parsed_translation, bindings, locale: locale)
          {false, iolist}

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
              iolist = iolist_maybe_with_warning(original_iolist, hash, message)
              {false, iolist}

            extension_list when is_list(extension_list) ->
              cond do
                "pseudo" in extension_list ->
                  # We have to convert the iolist into a string because
                  # the pseudolocalization functions need a string in order to be intelligent
                  # when handling punctuation characters.
                  original_text = to_string(original_iolist)
                  pseudolocalized_iolist = Pseudolocalization.pseudolocalize_text(original_text)
                  {true, pseudolocalized_iolist}

                "pseudoht" in extension_list ->
                  # Same as above
                  original_html = to_string(original_iolist)
                  pseudolocalized_iolist = Pseudolocalization.pseudolocalize_html(original_html)
                  {true, pseudolocalized_iolist}

                true ->
                  # No (known) pseudolocalization! we can return the original iolist
                  # (and log a warning if the message hasn't been extracted)
                  iolist = iolist_maybe_with_warning(original_iolist, hash, message)
                  {false, iolist}
              end

            _other ->
              # No weird extensions! We can return the original iolist
              # (and log a warning if the message hasn't been extracted)
              iolist = iolist_maybe_with_warning(original_iolist, hash, message)
              {false, iolist}
          end
      end

    # Translations with pseudolocalization aren't editable.
    # It doesn't make sense to add invisible markers to those.
    if InvisibleMarker.invisible_marker_active?() && not(is_pseudo?) do
      InvisibleMarker.encode_iolist(translated_iolist, hash, locale, [])
    else
      translated_iolist
    end
  end

  @doc """
  Updates the current translation data with the new value.
  The old value is discarded.

  This function will atomically update all the persistent terms so that
  they don't get out of sync.
  It's the only API that allows the user to update the persistent terms from
  outside of this module.
  """
  @spec update_translation_data(TranslationData.t()) :: :ok
  def update_translation_data(%TranslationData{} = translation_data) do
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


    hashes = Enum.map(translation_data.messages, fn {hash, _message} -> hash end)
    hash_map_set = MapSet.new(hashes)

    # Update all the persisten terms:
    put_translations(persistent_map)
    put_extracted_hash_set(hash_map_set)
    put_translation_data(translation_data)

    :ok
  end

  @doc """
  Setup the translator system, by populating the map with the translations.
  """
  @spec setup(Path.t()) :: :ok | :error
  def setup(path \\ nil) do
    translations_path =
      case path do
        nil -> Config.translations_path()
        other -> other
      end

    case TranslationData.load_translation_data(translations_path) do
      {:ok, translation_data} ->
        update_translation_data(translation_data)
        :ok

      {:error, _error_code} ->
        empty_translation_data = TranslationData.new([])
        update_translation_data(empty_translation_data)
        :error
    end
  end

  defp lookup_translation({_hash, _locale} = key) do
    map = get_translations()
    Map.fetch(map, key)
  end

  @doc """
  Get the translation data from the persistent term.
  This can be used to be able to live-edit the translation data for the app.
  After editing the translation data, you must call `#{__MODULE__}.update_translation_data/1`
  to make those translations available to the rest of the app.
  """
  def get_translation_data() do
    :persistent_term.get(@persistent_term_translator_data_key)
  end

  # Private

  defp put_translation_data(value) do
    # Put the translation data in the persistent term.
    # This will be used to be able to live-edit the translation data for the app.
    :persistent_term.put(@persistent_term_translator_data_key, value)
  end

  defp get_translations() do
    # Get the (global) translations map.
    # This is the map we will use to lookup the translations.
    :persistent_term.get(@persistent_term_translations_key)
  end

  defp put_translations(value) do
    # Set the (global) translations map.
    # This is the map we will use to lookup the translations.
    :persistent_term.put(@persistent_term_translations_key, value)
  end

  defp put_extracted_hash_set(value) do
    # Put the set of extracted hashes so that we can warn the user when
    # a non-extracted message is used.
    :persistent_term.put(@persistent_term_extracted_hash_set_key, value)
  end

  defp extracted_hash?(hash) do
    # Test whether the current hash belongs to a message that has been already extracted.
    map_set = :persistent_term.get(@persistent_term_extracted_hash_set_key)
    MapSet.member?(map_set, hash)
  end
end
