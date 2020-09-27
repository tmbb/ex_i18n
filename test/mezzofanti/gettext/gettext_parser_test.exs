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

  test "parse file - 1" do
    file = """
    ## `msgid`s in this file come from POT (.pot) files.
    ##
    ## Do not add, change, or remove `msgid`s manually here as
    ## they're tied to the ones in the corresponding POT file
    ## (with the same domain).
    ##
    ## Use `mix mezzofanti.extract --merge` or `mix gettext.merge`
    ## to merge POT files into PO files.


    #.
    #, icu-format
    #: test/fixtures/example_module.ex:24
    msgctxt ""
    msgid ""
    "{nr_photos, plural, "
    "  =0 {{user} didn't take any photos.}"
    "  =1 {{user} took one photo.}"
    "  other {{user} took # photos.}}"
    msgstr ""
    "{nr_photos, plural, "
    "  =0 {{user} não tirou fotografias nenhumas.}"
    "  =1 {{user} tirou 1 fotografia.}"
    "  other {{user} tirou # fotografias.}}"
    """

    expected = [
      %Mezzofanti.Message{
        comment: "",
        context: "",
        domain: "default",
        file: "test/fixtures/example_module.ex",
        flag: "icu-format",
        hash:
          <<15, 121, 10, 94, 114, 198, 239, 112, 167, 255, 210, 82, 53, 172, 82, 95, 79, 237, 153,
            112>>,
        line: 24,
        module: nil,
        previous_hash: nil,
        string:
          "{nr_photos, plural, \n  =0 {{user} didn't take any photos.}\n  =1 {{user} took one photo.}\n  other {{user} took # photos.}}",
        translated:
          "{nr_photos, plural, \n  =0 {{user} não tirou fotografias nenhumas.}\n  =1 {{user} tirou 1 fotografia.}\n  other {{user} tirou # fotografias.}}"
      }
    ]

    assert GettextParser.parse_file!(file) == expected
  end

  test "file - 2" do
    file = """
    ## `msgid`s in this file come from POT (.pot) files.
    ##
    ## Do not add, change, or remove `msgid`s manually here as
    ## they're tied to the ones in the corresponding POT file
    ## (with the same domain).
    ##
    ## Use `mix mezzofanti.extract --merge` or `mix gettext.merge`
    ## to merge POT files into PO files.

    #.
    #, icu-format
    #: test/fixtures/example_module.ex:41
    msgctxt ""
    msgid "This message contains <strong>html tags</strong> &amp; nasty stuff..."
    msgstr "Esta mensagem contém <strong>tags de HTML</strong> &amp; e coisas chatas..."

    #.
    #, icu-format
    #: test/fixtures/example_module.ex:18
    msgctxt "a message"
    msgid "Hello {guest}!"
    msgstr "Olá {guest}!"

    #.
    #, icu-format
    #: test/fixtures/example_module.ex:10
    msgctxt ""
    msgid "Hello world!"
    msgstr "Olá a todos!"

    """

    expected = [
      %Mezzofanti.Message{
        comment: "",
        context: "",
        domain: "default",
        file: "test/fixtures/example_module.ex",
        flag: "icu-format",
        hash:
          <<99, 236, 200, 67, 9, 124, 192, 92, 227, 29, 195, 7, 29, 155, 224, 32, 193, 18, 144,
            123>>,
        line: 41,
        module: nil,
        previous_hash: nil,
        string: "This message contains <strong>html tags</strong> &amp; nasty stuff...",
        translated: "Esta mensagem contém <strong>tags de HTML</strong> &amp; e coisas chatas..."
      },
      %Mezzofanti.Message{
        comment: "",
        context: "a message",
        domain: "default",
        file: "test/fixtures/example_module.ex",
        flag: "icu-format",
        hash:
          <<91, 60, 39, 76, 25, 249, 138, 129, 96, 139, 12, 141, 91, 97, 121, 94, 100, 112, 170,
            143>>,
        line: 18,
        module: nil,
        previous_hash: nil,
        string: "Hello {guest}!",
        translated: "Olá {guest}!"
      },
      %Mezzofanti.Message{
        comment: "",
        context: "",
        domain: "default",
        file: "test/fixtures/example_module.ex",
        flag: "icu-format",
        hash:
          <<207, 4, 108, 103, 221, 143, 26, 172, 80, 184, 52, 91, 76, 187, 106, 237, 213, 193, 89,
            178>>,
        line: 10,
        module: nil,
        previous_hash: nil,
        string: "Hello world!",
        translated: "Olá a todos!"
      }
    ]

    assert GettextParser.parse_file!(file) == expected
  end
end
