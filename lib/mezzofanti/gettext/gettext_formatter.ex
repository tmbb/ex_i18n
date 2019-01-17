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
    translated = if translation.translated, do: translation.translated, else: ""
    flag = comment_with(translation.flag, "#,")
    source = ["#: ", translation.file, ":", to_string(translation.line), "\n"]
    msgid = ["msgid ", inspect(translation.string), "\n"]
    msgstr = ["msgstr ", inspect(translated), "\n"]
    # The comments are not used for message disambiguation.
    # They are only notes for translators
    extracted_comments = comment_with(translation.comment, "#.")
    # Unlike comments, the context is used for message disambiguation
    msgctxt =
      if translation.context do
        ["msgctxt ", inspect(translation.context), "\n"]
      else
        []
      end

    [
      "\n",
      extracted_comments,
      flag,
      source,
      msgctxt,
      msgid,
      msgstr
    ]
  end

  defp format_translations_as_iodata(header, translations) do
    commented_header = if header, do: [comment_with(header, "##"), "\n"], else: []
    [commented_header, Enum.map(translations, &format_translation_as_iodata/1)]
  end

  def format_translations(header \\ nil, translations) do
    translations
    |> format_translations_as_iodata(header)
    |> IO.iodata_to_binary()
  end

  def write_to_file!(path, header \\ nil, translations) do
    iodata = format_translations_as_iodata(header, translations)
    File.write!(path, iodata)
  end
end
