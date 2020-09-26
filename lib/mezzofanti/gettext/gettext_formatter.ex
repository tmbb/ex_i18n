defmodule Mezzofanti.Gettext.GettextFormatter do
  @moduledoc false

  alias Mezzofanti.Message

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
  @default_flag "#, icu-format"

  defp format_message_as_iodata(%Message{} = message) do
    translated = if message.translated, do: message.translated, else: ""

    flag =
      case message.flag do
        nil -> @default_flag
        _ -> comment_with(message.flag, @default_flag <> ",")
      end

    source = ["#: ", message.file, ":", to_string(message.line), "\n"]
    msgid = ["msgid ", encode_as_multiple_strings(message.string), "\n"]
    msgstr = ["msgstr ", encode_as_multiple_strings(translated), "\n"]
    # The comments are not used for message disambiguation.
    # They are only notes for translators
    extracted_comments = comment_with(message.comment, "#.")
    # Unlike comments, the context is used for message disambiguation
    msgctxt =
      if message.context do
        ["msgctxt ", inspect(message.context), "\n"]
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

  defp format_messages_as_iodata(header, messages) do
    commented_header = if header, do: [comment_with(header, "##"), "\n"], else: []
    [commented_header, Enum.map(messages, &format_message_as_iodata/1)]
  end

  def format_messages(header \\ nil, messages) do
    messages
    |> format_messages_as_iodata(header)
    |> IO.iodata_to_binary()
  end

  defp encode_as_multiple_strings(""), do: "\"\""

  defp encode_as_multiple_strings(string) do
    lines = String.split(string, "\n")

    case lines do
      [line] ->
        inspect(line)

      _ ->
        encoded_lines = Enum.map(["" | String.split(string, "\n")], &inspect/1)
        Enum.join(encoded_lines, "\n")
    end
  end

  @doc """
  Write messages to a `.PO` or `.POT` file.
  """
  def write_to_file!(path, header \\ nil, messages) do
    iodata = format_messages_as_iodata(header, messages)
    File.write!(path, iodata)
  end
end
