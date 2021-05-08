defmodule I18n.Pseudolocalization.HtmlPseudolocalization do
  @moduledoc """
  A module to support pseudolocalization.
  """
  import NimbleParsec
  alias I18n.Pseudolocalization.Common
  alias I18n.Pseudolocalization.TextPseudolocalization

  # An HTML tag is basically anything between `<` and `>`.
  # Because HTMl attributes may contain inline CSS and inline JS,
  # it's possible that `<` and `>` can appear inside an HTML tag.
  # We can deal with that, but that requires parsing a non-trivial
  # subset of the HTML standard...
  # This can be done, but it's not a priority right now
  html_tag =
    string("<")
    |> utf8_string([not: ?>], min: 0)
    |> string(">")

  # An HTMl entity is (more or less) an ampersand (`&`) character
  # followed by a number of characters which an be either:
  #   * a decimal or hexadecimal encoding of the unicode codepoint
  #   * a character name (there is a finite number of supported names)
  # The entity reference is usualy but not always terminated by a colon (`;`)

  # Encoding of characters using the decimal and hexadecimal values:
  hex_encoding = times(ascii_char([?0..?9, ?a..?f, ?A..?F]), min: 1)
  decimal_encoding = times(ascii_char([?0..?9]), min: 1)

  # TODO: use JSON for this, since we're already using JSON for other purposes?
  #
  # To be as correct as possible, we will parse the list of allowed HTML entities
  # from the JSON file in the original spec.
  #
  # To avoid having to depend on a JSON library, we will use split the file
  # into lines and use regex to extract the name of the HTML entities.
  #
  # This only works because the file has been formatted in a specific way.
  # If the JSON file is changed, we need to check if the following code
  # is still correct.
  entity_names =
    "lib/I18n/pseudolocalization/data/html_entities.json"
    |> File.read!()
    # Trim empty newlines that will make the following steps harder
    |> String.trim()
    # Split into lines
    |> String.split("\n")
    # Delete the first line, which contains only the opening curly brace (`{`)
    |> List.delete_at(0)
    # Delete the last line, which that contains only the closing curly brace (`}`)
    |> List.delete_at(-1)
    # Extract the entity name from the line (it's the first string in the line)
    # For these particular strings, we don't need to worry about escaping and such
    |> Enum.map(fn line -> Map.get(Regex.named_captures(~r/"(?<name>[^"]+)"/, line), "name") end)

  html_entity_named =
    entity_names
    # Reverse the list becuase some entity names are prefixes of other entiry names.
    # The most obvious case is entity names such as `&amp`, which might or migh not
    # end in a semicolon.
    # By ordering all entity names in a decreasing lexicographic ordering,
    # we make sure that (for example) `&amp` will be matched after `&amp;`
    |> Enum.reverse()
    # Wrap the names in the string combinator
    |> Enum.map(&string/1)
    |> choice()

  # Encapsulate the above combinator in a function to reduce compilation time
  # at the cost of being a little slower at runtime
  defparsec(:html_entity_named, html_entity_named)

  # Now, everything together:
  # An HTML entity always starts with a literal ampersand character
  html_entity_codepoint =
    string("&#")
    |> choice([
      # Decimal (no need for a prefix)
      decimal_encoding,
      # Hexadecimal (as indicated by the `x` prefix)
      string("x") |> concat(hex_encoding)
    ])
    # In any case, it is terminated by a semicolon
    |> string(";")

  html_entity =
    choice([
      html_entity_codepoint,
      # Use the parsec and not the combinator to reduce compilation time.
      # Apparently NimbleParsec tries really hard to optimize these choices
      # unless we use the parsec.
      parsec(:html_entity_named)
    ])

  # Text is anything that isn't an HTML tag or an entity
  text = utf8_string([not: ?<, not: ?>, not: ?&], min: 1)

  # Consume a single character as a form of error correction
  malformed = utf8_string([], 1)

  # We'll split the (possibly empty) HTML string into fragments
  # using the combinators above.
  # Only the parts tagged as `:text` will be pseudolocalized.
  html_contents =
    choice([
      tag(html_tag, :html_tag),
      tag(html_entity, :html_entity),
      unwrap_and_tag(text, :text),
      unwrap_and_tag(malformed, :malformed)
    ])
    |> repeat()

  defparsecp(:html_contents, html_contents)

  @doc false
  # This function is mae public (but hidden!) to make it easier to test
  # the very rudimentary HTML "parser".
  def parse_html(text) do
    # This line should never raise an error because
    # our parser will never fail on any string.
    # It something is really strange it will just use
    # the `malformed` combinator and proceed.
    {:ok, fragments, "", _, _, _} = html_contents(text)
    fragments
  end

  # Pseudolocalize the result of each of the combinators above.
  # To get the final string, we just concatenate everything.
  defp pseudolocalize_fragment({:html_tag, iolist}), do: iolist
  defp pseudolocalize_fragment({:html_entity, iolist}), do: iolist
  defp pseudolocalize_fragment({:malformed, iolist}), do: iolist
  defp pseudolocalize_fragment({:text, text}), do: TextPseudolocalization.pseudolocalize_fragment(text)

  @doc """
  Apply pseudolocalization to a given HTML string (respecting tags).

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

  This pseudolocalization function does the following:

      * Replace each latin character with a slightly modified version,
        which is still legible (for example, `m → ɱ`, `j → ǰ` )

      * Add extra tilde (`~`) characters to words to make them 35% longer.
        as a rule of thumb, one should asusme that foreign language strings
        are 35% longer in other languages

      * Other characters (non-latin characters, numbers, punctuation characters, etc.)
        are not touched by the localization process

      * *Respect HTML tags* (tags are preserved by pseudolocalization)

  ## Examples

      iex> alias I18n.Pseudolocalization.HtmlPseudolocalization
      I18n.Pseudolocalization.HtmlPseudolocalization

      iex> HtmlPseudolocalization.pseudolocalize("normal text") |> to_string()
      "⟪ñøȓɱàĺ~~ ťêẋť~⟫"

      iex> HtmlPseudolocalization.pseudolocalize("<a-tag>") |> to_string()
      "⟪<a-tag>⟫"

      iex> HtmlPseudolocalization.pseudolocalize("Abbot &amp; Costello") |> to_string()
      "⟪Åƀƀøť~ &amp; Ċøšťêĺĺø~~⟫"

      iex> HtmlPseudolocalization.pseudolocalize("Abbot &amp Costello") |> to_string() # entity without semicolon
      "⟪Åƀƀøť~ &amp Ċøšťêĺĺø~~⟫"

      iex> HtmlPseudolocalization.pseudolocalize("<strong>Abbot</strong> &amp Costello") |> to_string()
      "⟪<strong>Åƀƀøť~</strong> &amp Ċøšťêĺĺø~~⟫"

  """
  def pseudolocalize(string) do
    string
    |> parse_html()
    |> Enum.map(&pseudolocalize_fragment/1)
    |> Common.surround_by_brackets()
  end
end
