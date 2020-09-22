defmodule Mezzofanti.Pseudolocalization.HtmlPseudolocalizationTest do
  use ExUnit.Case, async: true
  import Mezzofanti.Pseudolocalization.HtmlPseudolocalization, only: [pseudolocalize: 1]
  import ExUnitProperties
  alias Mezzofanti.Pseudolocalization.TextPseudolocalization

  @html_tag_chars [?a..?z, ?A..?Z, ?0..?9, ?-, ?_, ?\s, ?:, ?.]

  def contains_latin_characters?(string) do
    string
    |> String.to_charlist()
    |> Enum.any?(fn c -> c in ?a..?z or c in ?A..?Z end)
  end

  test "empty string" do
    assert pseudolocalize("") == ""
  end

  test "examples" do
    # HTML tags
    assert pseudolocalize("a <b>thing</b>") == "à <b>ťȟıñğ~</b>"
    # HTML entity
    assert pseudolocalize("a &amp; b") == "à &amp; ƀ"
    # HTML without optional semicolon
    assert pseudolocalize("a &amp b") == "à &amp ƀ"
    # HTML tags and entities
    assert pseudolocalize("<i>a</i> &amp; b") == "<i>à</i> &amp; ƀ"
  end

  property "tags are preserved" do
    check all tag_name <- StreamData.string(@html_tag_chars),
              open <- StreamData.member_of(["<", "</"]),
              close <- StreamData.member_of([">", "/>"]),
              string = open <> tag_name <> close do
              
      assert pseudolocalize(string) == string
    end
  end

  property "no latin characters remain in the string after pseudolocalization (alphanumeric string)" do
    # This property is not true if the string is allowed to have non-alphanumeric characters
    check all string <- StreamData.string(:alphanumeric) do
      localized = pseudolocalize(string)
      assert not(contains_latin_characters?(localized))
    end
  end

  property "for alphanumeric strings, text localization is equivalent to html localization" do
    # This property is not true if the string is allowed to have non-alphanumeric characters
    check all string <- StreamData.string(:alphanumeric) do
      assert assert pseudolocalize(string) == TextPseudolocalization.pseudolocalize(string)
    end
  end
  
      
end