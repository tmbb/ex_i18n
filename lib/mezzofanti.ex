defmodule Mezzofanti do
  @moduledoc """
  Documentation for Mezzofanti.
  """

  alias Mezzofanti.Translation

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :__mezzofanti_translations__, accumulate: true)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __mezzofanti_translations__(), do: @__mezzofanti_translations__
    end
  end

  @doc """
  Translates a given string.
  """
  defmacro translate(string, options) do
    line = __CALLER__.line
    file = __CALLER__.file
    module = __CALLER__.module
    {comment, options} = Keyword.pop(options, :comment)
    {context, options} = Keyword.pop(options, :context)
    {domain, _options} = Keyword.pop(options, :domain)
    variables = Keyword.get(options, :variables, [])

    relative_path = Path.relative_to_cwd(file)

    translation =
      Translation.new(
        string: string,
        domain: domain,
        comment: comment,
        context: context,
        file: relative_path,
        line: line,
        module: module
      )

    Module.put_attribute(module, :__mezzofanti_translations__, translation)

    quote do
      Mezzofanti.Worker.translate(unquote(string), unquote(variables))
    end
  end
end
