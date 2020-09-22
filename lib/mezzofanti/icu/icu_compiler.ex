defmodule Mezzofanti.Icu.IcuCompiler do
  @moduledoc false
  def fetch_variable!(vars, var), do: Keyword.fetch!(vars, var)

  def compile_expression(ctx, list) when is_list(list) do
    Enum.map(list, fn element -> compile_expression(ctx, element) end)
  end
end
