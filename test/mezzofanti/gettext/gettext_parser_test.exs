defmodule Mezzofanti.Gettext.GettextParserTest do
  use ExUnit.Case, async: true

  alias Mezzofanti.Gettext.GettextParser
  alias Mezzofanti.Translation

  test "parses references correctly" do
    po_contents = """
    #: lib/bureaucrat_demo_web/controllers/cde_controller.ex:14
    """

    assert GettextParser.parse_reference(po_contents) == [
             file: "lib/bureaucrat_demo_web/controllers/cde_controller.ex",
             line: 14
           ]
  end

  test "parses a single translation from a PO file" do
    po_contents = """
    #  translator-comments…
    #. extracted-comments…
    #: lib/my_file.ex:45
    #, flag…
    #| msgid previous-untranslated-string
    msgctxt "context-for-message"
    msgid "untranslated-string"
    msgstr "translated-string"
    """

    expected = %Translation{
      comment: "extracted-comments…",
      context: "context-for-message",
      domain: nil,
      file: "lib/my_file.ex",
      flag: "flag…",
      line: 45,
      module: nil,
      string: "untranslated-string",
      translated: "translated-string"
    }

    assert GettextParser.parse_single_translation(po_contents) == expected
  end
end
