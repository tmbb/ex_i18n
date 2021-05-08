defmodule I18n.MessageBindings do
  defguardp is_simple_format(term) when elem(term, 0) == :simple_format

  def bindings(message) when is_binary(message) do
    with {:ok, parsed} <- Cldr.Message.Parser.parse(message) do
      bindings(parsed)
    end
  end

  def bindings(message) when is_list(message) do
    Enum.reduce(message, [], fn
      {:named_arg, arg}, acc ->
        [{arg, :string} | acc]

      {:pos_arg, arg}, acc ->
        [{arg, :string} | acc]

      {:select, {_, arg}, selectors}, acc ->
        [{arg, :string}, bindings(selectors) | acc]

      {:plural, {_, arg}, _, selectors}, acc ->
        [{arg, :number}, bindings(selectors) | acc]

      {:select_ordinal, {_, arg}, _, selectors}, acc ->
        [{arg, :number}, bindings(selectors) | acc]

      simple_format, acc when is_simple_format(simple_format) ->
        [binding_in_simple_format(simple_format) | acc]

      _other, acc-> acc
    end)
    |> List.flatten
    |> Enum.uniq
  end

  def bindings(message) when is_map(message) do
    Enum.map(message, fn {_selector, message} -> bindings(message) end)
  end

  defp binding_in_simple_format(simple_format) do
    tagged_arg = elem(simple_format, 1)
    type = elem(simple_format, 2)

    arg =
      case tagged_arg do
        {:named_arg, arg} -> arg
        {:pos_arg, arg} -> arg
      end

    {arg, type}
  end
end