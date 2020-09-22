defmodule Mezzofanti do
  @moduledoc """
  Documentation for Mezzofanti.
  """

  alias Mezzofanti.Message

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :__mezzofanti_messages__, accumulate: true)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __mezzofanti_messages__(), do: @__mezzofanti_messages__
    end
  end

  @doc """
  Get the current locale
  """
  def get_locale() do
    Process.get(:mezzofanti_locale)
  end

  @doc """
  Set the current locale
  """
  def put_locale(locale) do
    Process.put(:mezzofanti_locale, locale)
  end

  @doc """
  Run the given function with the given locale.
  After the function is run, the locale is reset to what it was before
  """
  def with_locale(locale, fun) do
    old_locale = get_locale()

    try do
      put_locale(locale)
      fun.()
    after
      put_locale(old_locale)
    end
  end

  @doc """
  TODO
  """
  def maybe_post_process(text, message, locale, localized) do
    case Application.get_env(:mezzofanti, :backend) do
      nil -> text
      backend -> backend.post_process(text, message, locale, localized)
    end
  end

  @doc """
  Translates a given string.
  """
  defmacro translate(string, options \\ []) do
    line = __CALLER__.line
    file = __CALLER__.file
    module = __CALLER__.module
    domain = Keyword.get(options, :domain, "default")
    context = Keyword.get(options, :context, "")
    comment = Keyword.get(options, :comment, "")
    variables = Keyword.get(options, :variables, [])

    relative_path = Path.relative_to_cwd(file)

    message =
      Message.new(
        string: string,
        domain: domain,
        comment: comment,
        context: context,
        file: relative_path,
        line: line,
        module: module
      )

    Module.put_attribute(module, :__mezzofanti_messages__, message)

    quote do
      Mezzofanti.Translator.__translate__(
        unquote(message.hash),
        unquote(variables),
        unquote(Macro.escape(message))
      )
    end
  end
end
