defmodule Mezzofanti.Gettext.GettextParser do
  @moduledoc false
  import NimbleParsec
  alias Mezzofanti.Translation

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

  def merge_lines(lines) do
    lines
    |> Enum.intersperse("\n")
    |> List.to_string()
  end

  def make_string(parts) do
    List.to_string(parts)
  end

  def make_translation(parts) do
    deduped = Enum.dedup_by(parts, fn {tag, _value} -> tag end)
    Translation.new(deduped)
  end

  newline =
    choice([
      ascii_char([?\n]),
      eos()
    ])

  line = times(utf8_char(not: ?\n), min: 1) |> ignore(newline)

  whitespace_chars = [?\s, ?\t, ?\f]

  whitespace = repeat(ascii_char(whitespace_chars))

  # TODO: extend to multiline strings
  text =
    ignore(ascii_char([?"]))
    |> repeat(
      choice([
        replace(string(~S[\"]), ?"),
        utf8_char(not: ?")
      ])
    )
    |> ignore(ascii_char([?"]))
    |> reduce(:make_string)

  lines = fn marker, tag ->
    marker
    |> optional(ascii_char([?\s]))
    |> ignore()
    |> wrap(line)
    |> times(min: 1)
    |> reduce(:merge_lines)
    |> unwrap_and_tag(tag)
  end

  text_field = fn marker, tag ->
    marker
    |> concat(whitespace)
    |> ignore()
    |> concat(text)
    |> ignore(whitespace)
    |> ignore(newline)
    |> unwrap_and_tag(tag)
  end

  blank_line = whitespace |> concat(ascii_char([?\n]))
  blank_lines = repeat(blank_line)

  integer =
    ascii_string([?0..?9], min: 1)
    |> map({String, :to_integer, []})

  reference =
    string("#:")
    |> concat(whitespace)
    |> ignore()
    |> unwrap_and_tag(utf8_string([not: ?:, not: ?\n], min: 1), :file)
    |> ignore(string(":"))
    |> unwrap_and_tag(integer, :line)
    |> ignore(whitespace |> concat(newline))

  extracted_comments = lines.(string("#."), :comment)
  msgid_untranslated_string = lines.(string("#|"), :msgid_untranslated)
  flag = lines.(string("#,"), :flag)

  msgid = text_field.(string("msgid"), :string)
  msgstr = text_field.(string("msgstr"), :translated)
  msgctxt = text_field.(string("msgctxt"), :context)

  specific_comments = [
    reference,
    extracted_comments,
    msgid_untranslated_string,
    flag
  ]

  translator_comments_marker =
    choice([
      string("#:"),
      string("#."),
      string("#,"),
      string("#|")
    ])
    |> lookahead_not()
    |> string("#")

  translator_comments = lines.(translator_comments_marker, :translator_comments)

  comment = choice([translator_comments | specific_comments])

  text_fields =
    optional(msgctxt)
    |> concat(msgid)
    |> concat(msgstr)

  translation =
    repeat(comment)
    |> concat(text_fields)
    |> ignore(blank_lines)
    |> reduce(:make_translation)

  translations =
    blank_lines
    |> optional()
    |> ignore()
    |> repeat(translation)

  defparsecp(:translation, translation)
  defparsecp(:reference, reference)
  defparsecp(:translations, translations)

  @doc false
  def parse_reference(text) do
    {:ok, reference, _, _, _, _} = reference(text)
    reference
  end

  @doc false
  def parse_single_translation(text) do
    {:ok, [translation], _, _, _, _} = translation(text)
    translation
  end

  @doc false
  def parse_translations(text) do
    {:ok, translations, _, _, _, _} = translations(text)
    translations
  end
end
