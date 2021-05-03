defmodule I18n.Pseudolocalization.TextPseudolocalizationTest do
  use ExUnit.Case, async: true
  alias I18n.Pseudolocalization.TextPseudolocalization
  import ExUnitProperties

  doctest I18n.Pseudolocalization.TextPseudolocalization

  # Convert all iolists to text to get prettier test cases.
  def pseudolocalize_text(string) do
    string
    |> TextPseudolocalization.pseudolocalize()
    |> to_string()
  end

  def contains_latin_characters?(string) do
    string
    |> String.to_charlist()
    |> Enum.any?(fn c -> c in ?a..?z or c in ?A..?Z and c in ?0..?9 end)
  end

  test "empty string" do
    assert pseudolocalize_text("") == "[]"
  end

  property "no latin characters remain in the string after pseudolocalization (ascii string)" do
    check all(string <- StreamData.string(:ascii)) do
      localized = pseudolocalize_text(string)
      assert not contains_latin_characters?(localized)
    end
  end

  property "no latin characters remain in the string after pseudolocalization (alphanumeric string)" do
    check all(string <- StreamData.string(:alphanumeric)) do
      localized = pseudolocalize_text(string)
      assert not contains_latin_characters?(localized)
    end
  end

  property "no latin characters remain in the string after pseudolocalization" do
    check all(string <- StreamData.string(:printable)) do
      localized = pseudolocalize_text(string)
      assert not contains_latin_characters?(localized)
    end
  end
end
