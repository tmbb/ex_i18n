defmodule Mezzofanti.Pseudolocalization.Common do
  @moduledoc """
  Common functions for modules that implement pseudolocalization of text
  in several markup formats.
  """

  alias Mezzofanti.Pseudolocalization.Common
  import NimbleParsec
  # Strings in other languages are assumed to be ~35% longer than in English
  @language_expansion 0.35
  # Pad the string with extra characters to simulate ~35% longer words
  @padding_characters "~"

  non_word_characters = String.to_charlist(".!?,;:«»\"`()[]{}")
  word_characters = Enum.map(non_word_characters, fn c -> {:not, c} end)

  left = utf8_string(non_word_characters, min: 0)
  right = utf8_string(non_word_characters, min: 0)
  middle = utf8_string(word_characters, min: 0)

  word =
    unwrap_and_tag(left, :left)
    |> unwrap_and_tag(middle, :middle)
    |> unwrap_and_tag(right, :right)

  defparsecp(:single_word, word)

  defp split_single_word(word) do
    {:ok, parts, _, _, _, _} = single_word(word)
    parts
  end

  @doc """
  Pseudolocalizes a word, which can include other non-word characters.

  Such characters are handled intelligently.

  ## Examples:

  TODO
  """
  def pseudolocalize_word(""), do: ""

  def pseudolocalize_word(word) do
    [left: left, middle: middle, right: right] = split_single_word(word)
    # We will work only with the middle, because that's the part that contains
    # the latin characters we want to "pseudolocalize".
    # Also, we want word expansion to apply only to the latin characters and
    # not to punctuation characters.
    # This is mostly an esthetic choice, becuase it's prettier and more obvious
    # when you have something like "word~~." then "word.~~".
    length = String.length(middle)
    nr_of_extra_characters = floor(length * @language_expansion)
    extra_characters = String.duplicate(@padding_characters, nr_of_extra_characters)

    new_graphemes =
      for grapheme <- String.graphemes(middle) do
        Common.convert_grapheme(grapheme)
      end

    to_string([left, new_graphemes, extra_characters, right])
  end

  @doc """
  Converts a single grapheme (not a unicode codepoints!) into a localized version.

  You probably don't want to use this directly unless you want to implement your
  custom pseudolocalization function that deals with things like HTML tags
  or other special markup.

  ## Examples

  TODO
  """
  def convert_grapheme(g) do
    case g do
      # Upper case
      "A" -> "Å"
      "B" -> "Ɓ"
      "C" -> "Ċ"
      "D" -> "Đ"
      "E" -> "Ȅ"
      "F" -> "Ḟ"
      "G" -> "Ġ"
      "H" -> "Ȟ"
      "I" -> "İ"
      "J" -> "Ĵ"
      "K" -> "Ǩ"
      "L" -> "Ĺ"
      "M" -> "Ṁ"
      "N" -> "Ñ"
      "O" -> "Ò"
      "P" -> "Ƥ"
      "Q" -> "Ꝗ"
      "R" -> "Ȓ"
      "S" -> "Ș"
      "T" -> "Ť"
      "U" -> "Ü"
      "V" -> "Ṽ"
      "W" -> "Ẃ"
      "X" -> "Ẍ"
      "Y" -> "Ẏ"
      "Z" -> "Ž"
      # Lower case
      "a" -> "à"
      "b" -> "ƀ"
      "c" -> "ċ"
      "d" -> "đ"
      "e" -> "ê"
      "f" -> "ƒ"
      "g" -> "ğ"
      "h" -> "ȟ"
      "i" -> "ı"
      "j" -> "ǰ"
      "k" -> "ǩ"
      "l" -> "ĺ"
      "m" -> "ɱ"
      "n" -> "ñ"
      "o" -> "ø"
      "p" -> "ƥ"
      "q" -> "ʠ"
      "r" -> "ȓ"
      "s" -> "š"
      "t" -> "ť"
      "u" -> "ü"
      "v" -> "ṽ"
      "w" -> "ẁ"
      "x" -> "ẋ"
      "y" -> "ÿ"
      "z" -> "ź"
      # Other characters are returned as they are
      other -> other
    end
  end
end
