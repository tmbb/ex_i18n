defmodule I18n.Gettext.GettextParser do
  @moduledoc false
  import NimbleParsec
  alias I18n.Message

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

  def make_multiline_string(["" | lines]), do: Enum.join(lines, "\n")
  def make_multiline_string(lines), do: Enum.join(lines, "\n")

  def make_message(parts) do
    deduped = Enum.dedup_by(parts, fn {tag, _value} -> tag end)
    Message.new(deduped)
  end

  newline = ascii_char([?\n])

  maybe_empty_line = repeat(utf8_char(not: ?\n)) |> ignore(newline)

  whitespace_chars = [?\s, ?\t, ?\f]

  whitespace = repeat(ascii_char(whitespace_chars))

  blank_line = whitespace |> concat(newline)

  blank_lines = repeat(blank_line) |> optional(eos())

  gettext_string =
    ignore(ascii_char([?"]))
    |> repeat(
      choice([
        replace(string(~S[\"]), ?"),
        utf8_char(not: ?")
      ])
    )
    |> ignore(ascii_char([?"]))
    |> reduce(:make_string)

  text =
    gettext_string
    |> repeat(
      ignore(blank_lines)
      |> ignore(whitespace)
      |> concat(gettext_string)
    )
    |> reduce(:make_multiline_string)

  # lines = fn marker, tag ->
  #   marker
  #   |> optional(ascii_char([?\s]))
  #   |> ignore()
  #   |> wrap(line)
  #   |> times(min: 1)
  #   |> reduce(:merge_lines)
  #   |> unwrap_and_tag(tag)
  # end

  maybe_empty_lines = fn marker, tag ->
    marker
    |> optional(ascii_char([?\s]))
    |> ignore()
    |> wrap(maybe_empty_line)
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
    |> ignore(choice([newline, eos()]))
    |> unwrap_and_tag(tag)
  end

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

  extracted_comments = maybe_empty_lines.(string("#."), :comment)
  msgid_untranslated_string = maybe_empty_lines.(string("#|"), :msgid_untranslated)
  flag = maybe_empty_lines.(string("#,"), :flag)
  header = maybe_empty_lines.(string("##"), :header)

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

  translator_comments = maybe_empty_lines.(translator_comments_marker, :translator_comments)

  comment = choice([translator_comments | specific_comments])

  text_fields =
    optional(msgctxt)
    |> concat(msgid)
    |> concat(msgstr)

  message =
    repeat(comment)
    |> concat(text_fields)
    |> ignore(blank_lines)
    |> reduce(:make_message)

  messages = repeat(message)

  file =
    header
    |> concat(blank_lines)
    |> optional()
    |> ignore()
    |> concat(messages)

  defparsec(:blank_line, blank_line)
  defparsec(:blank_lines, blank_lines)
  defparsec(:flag, flag)
  defparsecp(:message, message)
  defparsecp(:reference, reference)
  defparsecp(:messages, messages)
  defparsecp(:file, file)

  @doc false
  def parse_reference!(text) do
    {:ok, reference, "", _, _, _} = reference(text)
    reference
  end

  @doc false
  def parse_single_message!(text) do
    {:ok, [message], "", _, _, _} = message(text)
    message
  end

  @doc false
  def parse_messages!(text) do
    {:ok, messages, "", _, _, _} = messages(text)
    messages
  end

  @doc false
  def parse_file!(text) do
    {:ok, messages, "", _, _, _} = file(text)
    messages
  end

  def messages_from_file(path) do
    domain =
      path
      |> Path.basename()
      |> Path.rootname()

    contents = File.read!(path)
    normalized = String.replace(contents, "\r\n", "\n")
    messages = parse_file!(normalized)

    Enum.map(messages, fn m -> Message.set_domain(m, domain) end)
  end
end
