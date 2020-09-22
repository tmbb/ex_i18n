defmodule Mezzofanti.Backends.GettextBackend do
  alias Mezzofanti.Gettext.GettextParser
  alias Mezzofanti.Message

  defmacro __using__(opts \\ []) do
    directory = Keyword.get(opts, :directory, "priv/mezzofanti")
    external_resources = Path.wildcard(Path.join(directory, "**/**.{po,pot}"))
    translations = translations_from_files(directory)

    generate_clauses(:translate_from_hash, translations, external_resources)
  end

  def generate_clauses(fun_name, _messages = {original_messages, locales}, external_resources) do
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
            def unquote(fun_name)(unquote(message.hash), unquote(locale_name), variables, _translation) do
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

    text_pseudolocalization_function_clauses =
      for message <- original_messages do
        # Store the parsed translation;
        # Now even empty messages will be encoded.
        parsed_translation = Message.parse_message!(message.string)

        quote do
          # This clause is triggered by the `"pseudo`" locale.
          def unquote(fun_name)(unquote(message.hash), "pseudo", variables, _translation) do
            translated =
              Cldr.Message.format_list(
                unquote(Macro.escape(parsed_translation)),
                variables,
                # Don't specify a locale. Use the default one.
                []
              )

            # The variable `text` is an iolist and not a string
            # Our pseudolocalization functions expect a string for further processing.
            text = to_string(translated)
            # Use fully qualified module name in quoted expression
            Mezzofanti.Pseudolocalization.TextPseudolocalization.pseudolocalize(text)
          end
        end
      end

    html_pseudolocalization_function_clauses =
      for message <- original_messages do
        # Store the parsed translation;
        # Now even empty messages will be encoded.
        parsed_translation = Message.parse_message!(message.string)

        quote do
          # This clause is triggered by the `"pseudo_html`" locale.
          def unquote(fun_name)(unquote(message.hash), "pseudo_html", variables, _translation) do
            translated =
              Cldr.Message.format_list(
                unquote(Macro.escape(parsed_translation)),
                variables,
                # Don't specify a locale. Use the default one.
                []
              )

            # The variable `text` is an iolist and not a string
            # Our pseudolocalization functions expect a string for further processing.
            text = to_string(translated)
            # Use fully qualified module name in quoted expression
            Mezzofanti.Pseudolocalization.HtmlPseudolocalization.pseudolocalize(text)
          end
        end
      end

    message_not_extracted_function_clauses =
      quote do
        # Text pseudolocalization
        def unquote(fun_name)(_, "pseudo_html", variables, message) do
          # Parse the string at runtime
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
        def unquote(fun_name)(_, "pseudo", variables, message) do
          # Parse the string at runtime
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

    # Make sure the gettext files are declared as external resources,
    # so that changing them triggers a recompilation of the Mezzofanti backend.
    resource_registration =
      for resource <- external_resources do
        quote do
          @external_resource unquote(resource)
        end
      end

    result =
      quote do
        (unquote_splicing(
           resource_registration ++
             List.flatten(translated_function_clauses) ++
             text_pseudolocalization_function_clauses ++
             html_pseudolocalization_function_clauses ++
             untranslated_function_clauses ++
             [message_not_extracted_function_clauses]
         ))
      end

    # File.write!("example.exs", result |> Macro.to_string() |> Code.format_string!())

    result
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
