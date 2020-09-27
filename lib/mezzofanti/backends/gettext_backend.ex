defmodule Mezzofanti.Backends.GettextBackend do
  alias Mezzofanti.Gettext.GettextParser
  alias Mezzofanti.Message
  require Logger

  defmacro __using__(opts \\ []) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    priv = Keyword.get(opts, :priv, "priv/mezzofanti")

    directory =
      otp_app
      |> Application.app_dir()
      |> Path.join(priv)

    # Ensure the backend is recompiled when the translation files change
    external_resources = Path.wildcard(Path.join(directory, "**/**.{po,pot}"))
    # translations = {[], %{}}
    translations = translations_from_files(directory)

    generate_clauses(:translate_from_hash, translations, external_resources)
  end

  @doc false
  def log_message_not_extracted(message) do
    Logger.warn(
      "mezzofanti - message not extracted (#{message.file}:#{message.line}): #{
        inspect(message.string)
      }"
    )
  end

  defp generate_clauses(fun_name, _messages = {original_messages, locales}, external_resources) do
    # These are the defaul function clauses.
    # The function will look up a valod translation and return the translated and localized message

    translated_function_clauses =
      for {locale_name, translated_messages} <- locales do
        # Iterate over all translated messages which have been in fact translated.
        # Ignore messages with empty translations.
        # A valid translation will never be empty, unless the original message is also empty.
        # In that case, we can default to the case in which the translation is not defined.
        for message <- translated_messages, message.translated != "" do
          # Store the parsed translation;
          # We don't need to check the translation is non-empty because we've done it already
          parsed_translation = Message.parse_message!(message.translated)

          quote do
            def unquote(fun_name)(
                  unquote(message.hash),
                  %Cldr.LanguageTag{cldr_locale_name: unquote(locale_name)} = _locale,
                  variables,
                  _translation
                ) do
              Cldr.Message.format_list(
                unquote(Macro.escape(parsed_translation)),
                variables,
                locale: unquote(locale_name)
              )
            end
          end
        end
      end

    # These function clauses will be invoked if an unsupported locale is used
    # or if the message doesn't have a translation on the chosen locale
    untranslated_function_clauses =
      for message <- original_messages do
        # Store the parsed translation;
        # Now even empty messages will be encoded.
        parsed_translation = Message.parse_message!(message.string)

        quote do
          def unquote(fun_name)(unquote(message.hash), _, variables, _translation) do
            Cldr.Message.format_list(
              unquote(Macro.escape(parsed_translation)),
              variables,
              # Don't specify a locale. Use the default one.
              []
            )
          end
        end
      end

    message_not_extracted_function_clauses =
      quote do
        # Text pseudolocalization
        def unquote(fun_name)(
              _,
              %Cldr.LanguageTag{extensions: %{"m" => ["pseudoht"]}},
              variables,
              message
            ) do
          # Parse the string at runtime
          Mezzofanti.Backends.GettextBackend.log_message_not_extracted(message)
          parsed = Message.parse_message!(message.string)

          localized =
            Cldr.Message.format_list(
              parsed,
              variables,
              # Don't specify a locale. Use the default one.
              []
            )

          # The variable `text` is an iolist and not a string
          # Our pseudolocalization functions expect a string for further processing.
          text = to_string(localized)
          # Use fully qualified module name in quoted expression
          Mezzofanti.Pseudolocalization.HtmlPseudolocalization.pseudolocalize(text)
        end

        # HTML pseudolocalization
        def unquote(fun_name)(
              _,
              %Cldr.LanguageTag{extensions: %{"m" => ["pseudo"]}},
              variables,
              message
            ) do
          # Parse the string at runtime
          Mezzofanti.Backends.GettextBackend.log_message_not_extracted(message)
          parsed = Message.parse_message!(message.string)

          localized =
            Cldr.Message.format_list(
              parsed,
              variables,
              # Don't specify a locale. Use the default one.
              []
            )

          # The variable `text` is an iolist and not a string
          # Our pseudolocalization functions expect a string for further processing.
          text = to_string(localized)
          # Use fully qualified module name in quoted expression
          Mezzofanti.Pseudolocalization.TextPseudolocalization.pseudolocalize(text)
        end

        # HTML pseudolocalization
        def unquote(fun_name)(_, _, variables, message) do
          # Parse the string at runtime
          Mezzofanti.Backends.GettextBackend.log_message_not_extracted(message)
          parsed = Message.parse_message!(message.string)

          localized =
            Cldr.Message.format_list(
              parsed,
              variables,
              # Don't specify a locale. Use the default one.
              []
            )

          localized
        end
      end

    # If the locale is `Cldr.LanguageTag.t` and there is an `m`
    # extensions, then invoke pseudolocalisation
    cldr_language_tag_pseudo_clauses =
      quote do
        def unquote(fun_name)(
              message_hash,
              %Cldr.LanguageTag{extensions: %{"m" => ["pseudo"]}} = locale,
              variables,
              translation
            ) do
          new_locale = %{locale | extensions: %{}}
          # Use the "normal" version of the string (which will probably be the english one)
          translated = unquote(fun_name)(message_hash, new_locale, variables, translation)
          # The variable `text` is an iolist and not a string
          # Our pseudolocalization functions expect a string for further processing.
          text = to_string(translated)
          # Use fully qualified module name in quoted expression
          Mezzofanti.Pseudolocalization.TextPseudolocalization.pseudolocalize(text)
        end

        def unquote(fun_name)(
              message_hash,
              %Cldr.LanguageTag{extensions: %{"m" => ["pseudoht"]}} = locale,
              variables,
              translation
            ) do
          new_locale = %{locale | extensions: %{}}
          # Use the "normal" version of the string (which will probably be the english one)
          translated = unquote(fun_name)(message_hash, new_locale, variables, translation)
          # The variable `text` is an iolist and not a string
          # Our pseudolocalization functions expect a string for further processing.
          text = to_string(translated)
          # Use fully qualified module name in quoted expression
          Mezzofanti.Pseudolocalization.HtmlPseudolocalization.pseudolocalize(text)
        end
      end

    # Make sure the gettext files are declared as external resources,
    # so that changing them triggers a recompilation of the Mezzofanti backend.
    resource_registration =
      for resource <- external_resources do
        quote do
          @external_resource unquote(resource)
        end
      end

    r =
      quote do
        (unquote_splicing(
           # Try to match the pseudolocales first
           # Try to match the "normal locales"
           # If the locale doesn't match, treat it as an untranslated
           resource_registration ++
             [cldr_language_tag_pseudo_clauses] ++
             List.flatten(translated_function_clauses) ++
             untranslated_function_clauses ++
             [message_not_extracted_function_clauses]
         ))
      end

    s = r |> Macro.to_string() |> Code.format_string!()
    File.write!("example.exs", s)

    r
  end

  def filter_pot_files(paths) do
    Enum.filter(paths, fn path -> Path.extname(path) == ".pot" end)
  end

  def filter_po_files(paths) do
    Enum.filter(paths, fn path -> Path.extname(path) == ".po" end)
  end

  def translations_from_locale(locale_directory) do
    locale_name = Path.basename(locale_directory)
    lc_messages = Path.join(locale_directory, "LC_MESSAGES")

    files =
      File.ls!(lc_messages)
      |> Enum.map(fn f -> Path.join(lc_messages, f) end)
      |> filter_po_files()

    translated_messages = Enum.flat_map(files, &GettextParser.messages_from_file/1)
    {locale_name, translated_messages}
  end

  def translations_from_locales(locale_directories) do
    locale_directories
    |> Enum.map(&translations_from_locale/1)
    |> Enum.into(%{})
  end

  def grouped_messages_from_directory(directory) do
    files =
      directory
      |> File.ls!()
      |> Enum.map(fn f -> Path.join(directory, f) end)
      |> Enum.reject(&File.dir?/1)
      |> filter_pot_files()

    Enum.map(files, fn f -> {f, GettextParser.messages_from_file(f)} end)
  end

  def translations_from_files(directory) do
    locations =
      directory
      |> File.ls!()
      |> Enum.map(fn f -> Path.join(directory, f) end)
      |> Enum.group_by(&File.dir?/1)

    files = Map.get(locations, false, []) |> filter_pot_files()
    directories = Map.get(locations, true, [])

    untranslated_messages = Enum.flat_map(files, &GettextParser.messages_from_file/1)

    translated_messages = translations_from_locales(directories)
    {untranslated_messages, translated_messages}
  end
end
