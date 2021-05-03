defmodule I18n.Pseudolocalization.Common do
  @moduledoc """
  Common functions for modules that implement pseudolocalization of text
  in several markup formats.

  From [Wikipedia](https://en.wikipedia.org/wiki/Pseudolocalization):

  > Pseudolocalization (or pseudo-localization) is a software testing method
  > used for testing internationalization aspects of software.
  > Instead of translating the text of the software into a foreign language,
  > as in the process of localization, the textual elements of an application
  > are replaced with an altered version of the original language.
  >
  > These specific alterations make the original words appear readable,
  > but include the most problematic characteristics of the world's languages:
  > varying length of text or characters, language direction,
  > fit into the interface and so on.
  """

  alias I18n.Pseudolocalization.Common
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

      iex> alias I18n.Pseudolocalization.Common
      I18n.Pseudolocalization.Common

      iex> Common.pseudolocalize_word("text") |> to_string()
      "ťêẋť~"

      iex> Common.pseudolocalize_word("text!") |> to_string()
      "ťêẋť~!"

      iex> Common.pseudolocalize_word("(text!)") |> to_string()
      "(ťêẋť~!)"
  """
  def pseudolocalize_word(""), do: ""

  def pseudolocalize_word(word) do
    [left: left, middle: middle, right: right] = split_single_word(word)
    # We will work only with the middle, because that's the part that contains
    # the latin characters we want to "pseudolocalize".
    # Also, we want word expansion to apply only to the latin characters and
    # not to punctuation characters.
    # This is mostly an esthetic choice, because it's prettier and more obvious
    # when you have something like "word~~." then "word.~~".
    length = String.length(middle)
    nr_of_extra_characters = floor(length * @language_expansion)
    extra_characters = String.duplicate(@padding_characters, nr_of_extra_characters)

    new_graphemes =
      for grapheme <- String.graphemes(middle) do
        Common.convert_grapheme(grapheme)
      end

    [left, new_graphemes, extra_characters, right]
  end

  @doc """
  Converts a single grapheme (not a unicode codepoint!) into a localized version.

  You probably don't want to use this directly unless you want to implement your
  custom pseudolocalization function that deals with things like HTML tags
  or other special markup.

  ## Examples

      iex> alias I18n.Pseudolocalization.Common
      I18n.Pseudolocalization.Common

      iex> Common.convert_grapheme("A") |> to_string()
      "Å"

      iex> Common.pseudolocalize_word("D") |> to_string()
      "Đ"

      iex> Common.pseudolocalize_word("f") |> to_string()
      "ƒ"
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
      # Digits
      "0" -> "𝟘"
      "1" -> "𝟙"
      "2" -> "𝟚"
      "3" -> "𝟛"
      "4" -> "𝟜"
      "5" -> "𝟝"
      "6" -> "𝟞"
      "7" -> "𝟟"
      "8" -> "𝟠"
      "9" -> "𝟡"
      # Other characters are returned as they are
      other -> other
    end
  end

  def surround_by_brackets(iolist) do
    ["[", iolist, "]"]
  end
end
