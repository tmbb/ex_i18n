defmodule Mezzofanti do
  @moduledoc """
  Documentation for Mezzofanti.
  """

  alias Mezzofanti.Translation
  alias Mezzofanti.Gettext.GettextFormatter

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
    {domain, _options} = Keyword.pop(options, :domain)
    variables = Keyword.get(options, :variables, [])

    relative_path = Path.relative_to_cwd(file)

    translation =
      Translation.new(
        string: string,
        domain: domain,
        comment: comment,
        file: relative_path,
        line: line,
        module: module
      )

    Module.put_attribute(module, :__mezzofanti_translations__, translation)

    quote do
      Mezzofanti.Worker.translate(unquote(string), unquote(variables))
    end
  end

  defp get_mezzofanti_translations(module) do
    try do
      module.__mezzofanti_translations__()
    rescue
      UndefinedFunctionError -> []
    end
  end

  def get_all_mezzofanti_translations() do
    applications = for {app, _, _} <- Application.loaded_applications(), do: app
    modules = Enum.flat_map(applications, fn app -> Application.spec(app, :modules) end)
    Enum.flat_map(modules, &get_mezzofanti_translations/1)
  end

  def persist_translations(path) do
    translations = get_all_mezzofanti_translations()
    GettextFormatter.write_to_file!(path, translations)
  end
end
