defmodule MyApp.Cldr do
  use Cldr, locales: ["en", "fr", "zh"]
end

defmodule Mezzofanti.Icu.IcuCompiler do
  @moduledoc false
  def fetch_variable!(vars, var), do: Keyword.fetch!(vars, var)

  def compile_expression(ctx, list) when is_list(list) do
    Enum.map(list, fn element -> compile_expression(ctx, element) end)
  end

  # def compile_expression(%{variables: variables, locale: locale}, {:date, options}) do
  #   variable = Keyword.fetch!(options, :variable) |> String.to_atom()

  #   quote do
  #     Cldr.
  #   end
  # end
end
