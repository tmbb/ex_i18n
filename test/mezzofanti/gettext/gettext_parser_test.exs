defmodule Mezzofanti.Gettext.GettextParserTest do
  use ExUnit.Case, async: true

  alias Mezzofanti.Gettext.GettextParser
  alias Mezzofanti.Message

  test "parses references correctly" do
    po_contents = """
    #: lib/bureaucrat_demo_web/controllers/cde_controller.ex:14
    """

    assert GettextParser.parse_reference!(po_contents) == [
             file: "lib/bureaucrat_demo_web/controllers/cde_controller.ex",
             line: 14
           ]
  end

  test "parses a single message from a PO file" do
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

    expected = %Message{
      comment: "extracted-comments…",
      context: "context-for-message",
      domain: "default",
      file: "lib/my_file.ex",
      flag: "flag…",
      line: 45,
      module: nil,
      string: "untranslated-string",
      translated: "translated-string",
      hash:
        <<194, 242, 19, 95, 45, 106, 35, 20, 164, 21, 152, 111, 146, 254, 230, 198, 56, 179, 232,
          70>>
    }

    assert GettextParser.parse_single_message!(po_contents) == expected
  end

  test "parses a single message from a PO file - multiline strings" do
    po_contents = """
    #  translator-comments…
    #. extracted-comments…
    #: lib/my_file.ex:45
    #, flag…
    #| msgid previous-untranslated-string
    msgctxt "context-for-message"
    msgid ""
    "untranslated-string - line 1"
    "untranslated-string - line 2"
    msgstr "translated-string"
    """

    expected = %Message{
      comment: "extracted-comments…",
      context: "context-for-message",
      domain: "default",
      file: "lib/my_file.ex",
      flag: "flag…",
      line: 45,
      module: nil,
      string: "untranslated-string - line 1\nuntranslated-string - line 2",
      translated: "translated-string",
      hash:
        <<234, 222, 204, 191, 41, 208, 36, 248, 61, 228, 107, 64, 236, 177, 201, 236, 6, 13, 151,
          149>>
    }

    assert GettextParser.parse_single_message!(po_contents) == expected
  end

  # @tag skip: true
  test "parses a multiple messages from a PO file" do
    po_contents = """

    #  translator-comments1
    #. extracted-comments1
    #: lib/my_file1.ex:1
    #, flag1
    #| msgid previous-untranslated-string1
    msgctxt "context-for-message1"
    msgid "untranslated-string1"
    msgstr "translated-string1"

    #  translator-comments2
    #. extracted-comments2
    #: lib/my_file2.ex:2
    #, flag2
    #| msgid previous-untranslated-string2
    msgctxt "context-for-message2"
    msgid "untranslated-string2"
    msgstr "translated-string2"



    """

    expected = [
      %Message{
        comment: "extracted-comments1",
        context: "context-for-message1",
        domain: "default",
        file: "lib/my_file1.ex",
        flag: "flag1",
        line: 1,
        module: nil,
        string: "untranslated-string1",
        translated: "translated-string1",
        hash:
          <<52, 185, 219, 229, 221, 26, 178, 185, 214, 105, 6, 126, 214, 64, 138, 171, 96, 225, 0,
            245>>
      },
      %Message{
        comment: "extracted-comments2",
        context: "context-for-message2",
        domain: "default",
        file: "lib/my_file2.ex",
        flag: "flag2",
        line: 2,
        module: nil,
        string: "untranslated-string2",
        translated: "translated-string2",
        hash:
          <<21, 6, 89, 175, 250, 77, 191, 58, 62, 47, 159, 94, 184, 31, 231, 224, 229, 196, 139,
            73>>
      }
    ]

    assert GettextParser.parse_messages!(po_contents) == expected
  end
end
