defmodule Mezzofanti.Icu.IcuParser.Helpers do
  import NimbleParsec

  @whitespace repeat(ascii_char([?\n, ?\s, ?\f, ?t]))

  def seq(combinators) do
    wrapped_raw_strings =
      Enum.map(combinators, fn
        comb when is_binary(comb) -> ignore(string(comb))
        comb -> comb
      end)

    combinators_with_whitespace =
      wrapped_raw_strings
      |> Enum.intersperse(ignore(@whitespace))
      |> Enum.reverse()

    Enum.reduce(combinators_with_whitespace, &concat/2)
  end

  def one_or_more(combinator) do
    combinator
    |> repeat(ignore(@whitespace) |> concat(combinator))
  end
end
