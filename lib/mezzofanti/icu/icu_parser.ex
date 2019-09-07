defmodule Mezzofanti.Icu.IcuParser do
  import NimbleParsec

  actual_newline = "\n\n" |> string() |> replace(?\n)
  newline = "\n" |> string() |> replace(?\s)

  whitespace = repeat(ascii_char([?\n, ?\s, ?\f, ?\t]))

  # Some utilities to help define more complex parsers

  # A sequence of combinators separated by optional whitespace
  seq = fn combinators ->
    wrapped_raw_strings =
      Enum.map(combinators, fn
        comb when is_binary(comb) -> ignore(string(comb))
        comb -> comb
      end)

    combinators_with_whitespace =
      wrapped_raw_strings
      |> Enum.intersperse(ignore(whitespace))
      |> Enum.reverse()

    Enum.reduce(combinators_with_whitespace, &concat/2)
  end

  # one or more of the given combinator, separated by optional whitespace
  multiple1 = fn combinator ->
    combinator
    |> repeat(ignore(whitespace) |> concat(combinator))
  end

  integer = ascii_string([?0..?9], min: 1) |> reduce({String, :to_integer, []})

  string_from_list = fn args ->
    args
    |> Enum.map(&string/1)
    |> choice()
  end

  text =
    choice([
      actual_newline,
      newline,
      utf8_char(not: ?{, not: ?})
    ])
    |> times(min: 1)
    |> reduce({List, :to_string, []})

  variable = utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)

  # ...
  simple_format = fn name, tag, params ->
    head = ["{", variable |> unwrap_and_tag(:variable), ",", name]

    middle =
      if params do
        [
          seq.([",", unwrap_and_tag(params, :parameter)]) |> optional()
        ]
      else
        []
      end

    tail = ["}"]

    (head ++ middle ++ tail) |> seq.() |> tag(tag)
  end

  # Plural (plural and selectordinal)
  # ---------------------------------

  plural_fixed_value = string_from_list.(~w(zero one two few many other))
  literal_value = seq.(["=", integer])
  plural_value = choice([plural_fixed_value, literal_value])

  plural_option =
    seq.([unwrap_and_tag(plural_value, :value), "{", unwrap_and_tag(parsec(:message), :body), "}"])
    |> wrap()

  plural_options = multiple1.(plural_option)

  plural_format = fn name, tag ->
    seq.([
      "{",
      variable |> unwrap_and_tag(:variable),
      ",",
      name,
      ",",
      plural_options |> tag(:options),
      "}"
    ])
    |> tag(tag)
  end

  plural = plural_format.("plural", :plural)
  selectordinal = plural_format.("selectordinal", :selectordinal)

  # Select (no literal values are allowed and `#` isn't a special character)
  # ------------------------------------------------------------------------

  select_value = utf8_string([not: ?\n, not: ?\s, not: ?\f, not: ?{, not: ?}], min: 1)

  select_option =
    seq.([unwrap_and_tag(select_value, :value), "{", unwrap_and_tag(parsec(:message), :body), "}"])
    |> wrap()

  select_options = multiple1.(select_option)

  select =
    seq.([
      "{",
      variable |> unwrap_and_tag(:variable),
      ",",
      "select",
      ",",
      select_options |> tag(:options),
      "}"
    ])
    |> tag(:select)

  duration = simple_format.("duration", :duration, nil)
  date = simple_format.("date", :date, string_from_list.(~w(full long short default)))
  time = simple_format.("time", :time, string_from_list.(~w(full long short default)))

  message =
    choice([
      text,
      date,
      time,
      duration,
      select,
      plural,
      selectordinal
    ])
    |> repeat()

  full_message = message |> eos()

  @doc false
  defparsec(:text, text)
  @doc false
  defparsec(:date, date)
  @doc false
  defparsec(:time, time)
  @doc false
  defparsec(:duration, duration)
  @doc false
  defparsec(:message, message)
  @doc false
  defparsec(:select, select)

  defparsec(:full_message, full_message)

  def parse_message(text) do
    case full_message(text) do
      {:ok, parsed, "", _, _, _} ->
        {:ok, parsed}

      error ->
        error
    end
  end
end
