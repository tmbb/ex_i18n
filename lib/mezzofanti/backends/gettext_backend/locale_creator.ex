defmodule Mezzofanti.Backends.GettextBackend.LocaleCreator do
  @moduledoc false

  alias Mezzofanti.Backends.GettextBackend
  alias Mezzofanti.Backends.GettextBackend.Extractor

  def create_locale(directory, locale) do
    locale_path = Path.join(directory, locale)
    lc_messages_path = Path.join(locale_path, "LC_MESSAGES")

    if File.exists?(locale_path) do
      raise ArgumentError, "Locale '#{locale}' already exists."
    end

    File.mkdir_p!(locale_path)
    File.mkdir_p!(lc_messages_path)

    groups = GettextBackend.grouped_messages_from_directory(directory)

    for {file, messages} <- groups do
      domain =
        file
        |> Path.basename()
        |> Path.rootname()

      path = Path.join(lc_messages_path, domain <> ".po")
      Extractor.persist_messages_as_po(path, messages)
    end

    :ok
  end
end
