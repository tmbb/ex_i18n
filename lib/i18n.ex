defmodule I18n do
  @moduledoc File.read!("README.md")

  require ExUnit.Assertions, as: Assertions
  alias I18n.Messages.{
    InlineMessage,
    MessageLocation
  }

  # We might support other message handlers in the future.
  # TODO: should we do it? if so, which API should we support?
  alias I18n.MessageHandlers.IcuMessageHandler

  defmacro __using__(opts \\ []) do
    domain = Keyword.get(opts, :domain)
    Assertions.assert((domain == nil) or (is_binary(domain)))

    quote do
      require unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      Module.put_attribute(__MODULE__, :__i18n_global_domain__, unquote(domain))

      Module.register_attribute(__MODULE__, :__i18n_messages__, accumulate: true)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __i18n_messages__(), do: @__i18n_messages__
    end
  end

  @doc false
  # This is meant to be used mainly for testing.
  # The right place for this function is in Cldr and not I18n,
  # so we don't make it par of the "public API" for this module.
  def with_locale(locale, fun) do
    old_locale = Cldr.get_locale()

    try do
      Cldr.put_locale(locale)
      fun.()
    after
      Cldr.put_locale(old_locale)
    end
  end

  @doc """
  Translates a given string.

  It takes two arguments:

      * A *compile-time* string
      * An (optional) *compile-time* keyword list containing several `options`

  It accepts the following options:

      * `:bindings` - variables to interpolate inside the string.
        Should be a keyword list of the form `[var1: value1, var2: value2]`
      * `:domain` - the domain of the translations. It must be a compile-time string.
        Domains will map to file names names inside the `priv/i18n` directory.
        Of no domain is given, I18n assigns the message to the `"default"`
        domain.
      * `:context` - a context to disambiguate equal or similar messages

  A message is uniquely identified by the following three parameters:

      * The `string`
      * The `domain` (which if not given is assumed to "default")
      * The `context` (which may be the empty string)

  I18n is able to lookup all translations in all modules in your application
  (even dependencies), as long as you `use I18n`
  (instead of `import I18n).
  """
  defmacro t(string, options \\ []) do
    line = __CALLER__.line
    file = __CALLER__.file
    module = __CALLER__.module

    global_domain = Module.get_attribute(module, :__i18n_global_domain__)
    default_domain =
      case global_domain do
        nil -> module_to_domain(module)
        other -> other
      end

    domain = Keyword.get(options, :domain!, default_domain)
    context = Keyword.get(options, :context!, "")
    locale = Keyword.get(options, :locale!, nil)
    binding =
      options
      |> Keyword.delete(:domain!)
      |> Keyword.delete(:context!)
      |> Keyword.delete(:locale!)

    relative_path = Path.relative_to_cwd(file)

    location =
      MessageLocation.new(
        file: relative_path,
        line: line,
        module: module
      )

    message =
      InlineMessage.new(
        text: string,
        domain: domain,
        context: context,
        location: location
      )

    {:ok, parsed} = IcuMessageHandler.parse(string)

    Module.put_attribute(module, :__i18n_messages__, message)

    quote do
      I18n.Translator.translate(
        unquote(message.hash),
        unquote(locale),
        unquote(binding),
        unquote(Macro.escape(parsed)),
        unquote(Macro.escape(message))
      )
    end
  end

  defp module_to_domain(module) do
    module
    |> Module.split()
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end
end
