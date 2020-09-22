defmodule Mezzofanti.Pseudolocalization.TextPseudolocalizationTest do
  use ExUnit.Case, async: true
  import Mezzofanti.Pseudolocalization.TextPseudolocalization, only: [pseudolocalize: 1]
  import ExUnitProperties

  def contains_latin_characters?(string) do
    string
    |> String.to_charlist()
    |> Enum.any?(fn c -> c in ?a..?z or c in ?A..?Z end)
  end

  test "empty string" do
    assert pseudolocalize("") == ""
  end

  property "no latin characters remain in the string after pseudolocalization (ascii string)" do
    check all string <- StreamData.string(:ascii) do
      localized = pseudolocalize(string)
      assert not(contains_latin_characters?(localized))
    end
  end

  property "no latin characters remain in the string after pseudolocalization (alphanumeric string)" do
    check all string <- StreamData.string(:alphanumeric) do
      localized = pseudolocalize(string)
      assert not(contains_latin_characters?(localized))
    end
  end

  property "no latin characters remain in the string after pseudolocalization" do
    check all string <- StreamData.string(:printable) do
      localized = pseudolocalize(string)
      assert not(contains_latin_characters?(localized))
    end
  end
end