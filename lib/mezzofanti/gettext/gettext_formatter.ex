defmodule Mezzofanti.Gettext.GettextFormatter do
  @moduledoc false

  alias Mezzofanti.Translation

  defp comment_with(nil, _prefix), do: []

  defp comment_with(text, prefix) do
    text
    |> String.split("\n")
    |> Enum.map(fn line -> [prefix, " ", line, "\n"] end)
  end

  #  The format of an entry in a `.po` file is the following:
  #
  #     white-space
  #     #  translator-comments
  #     #. extracted-comments
  #     #: reference…
  #     #, flag…
  #     #| msgid previous-untranslated-string
  #     msgid untranslated-string
  #     msgstr translated-string
  #
  defp format_translation_as_iodata(%Translation{} = translation) do
    extracted_comments = comment_with(translation.comment, "#.")
    flag = comment_with(translation.flag, "#,")
    source = ["#: ", translation.file, ":", to_string(translation.line), "\n"]
    msgid = ["msgid ", inspect(translation.string), "\n"]
    msgstr = ~s'msgstr ""\n'

    [
      "\n",
      extracted_comments,
      flag,
      source,
      msgid,
      msgstr
    ]
  end

  defp format_translations_as_iodata(translations) do
    Enum.map(translations, &format_translation_as_iodata/1)
  end

  def format_translations(translations) do
    translations
    |> format_translations_as_iodata()
    |> IO.iodata_to_binary()
  end

  def write_to_file!(path, translations) do
    iodata = format_translations_as_iodata(translations)
    File.write!(path, iodata)
  end
end
