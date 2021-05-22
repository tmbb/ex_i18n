defmodule I18n do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")

  require ExUnit.Assertions, as: Assertions
  require Logger
  alias I18n.{
    InlineMessage,
    MessageLocation
  }

  # We might support other message handlers in the future.
  # TODO: should we do it? if so, which API should we support?
  alias I18n.IcuMessageHandler

  @doc """
  Enables the `I18n.t/2` macro for the current module in a way
  that allows messages to be extracted and translated.

  If you simply `require I18n`, you won't be able to extract messages.

  The simplest way of enabling the `I18n.t/2` macro is to `use I18n`
  (without arguments). However, because of the way `I18n` uses `@before_compile`
  hooks, you might have to use it with a `do ... end` block around any code
  that defines functions in `@before_compile` hooks:

      use I18n do
        # ...
        # code that defines other @before_compile hooks
        # ...
      end

  The `@before_compile` hooks are usually defined by the `__using__/1` macro
  of modules. However, Elixir code can define `@before_compile` hooks
  virtually anywhere. You can always make sure `I18n` works properly by
  adding the `do ... end` block around the full module contents
  (but you won't need to do it often, if at all).

  An example where you *need* to use the `do ... end` block is when using
  `I18n` to internationalize Phoenix applications.
  For example, the following code will fail to register the messages correctly:


      def view do
        quote do
          use I18n
          use Phoenix.View,
            root: "lib/my_app_web/templates",
            namespace: MyAppWeb

          # Import convenience functions from controllers
          import Phoenix.Controller,
            only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

          # Include shared imports and aliases for views
          unquote(view_helpers())
        end
      end

  For that to work, you need to envelop the `use ...` expressions in the block:

      def view do
        quote do
          # Note the do ... end block:
          use I18n do
            use Phoenix.View,
              root: "lib/my_app_web/templates",
              namespace: MyAppWeb

            # Import convenience functions from controllers
            import Phoenix.Controller,
              only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

            # Include shared imports and aliases for views
            unquote(view_helpers())
          end
        end
      end

  ### Implementation Details

  **TODO:** Explain why we need the block around code that defines functions
  inside `@before_compile` blocks.
  """
  defmacro __using__(opts \\ []) do
    body = Keyword.get(opts, :do, nil)
    domain = Keyword.get(opts, :domain)
    Assertions.assert((domain == nil) or (is_binary(domain)))

    quote do
      # Make the `I18n.t/2` macro available to what comes next
      require I18n
      # Register the attributes we'll need available when we translate messages
      # or run ou @before_compile hook.
      Module.put_attribute(__MODULE__, :__i18n_global_domain__, unquote(domain))
      Module.register_attribute(__MODULE__, :__i18n_messages__, accumulate: true)

      # Run the expressions enclosed between the `do` and `end`.
      # These expressions probably define some @before_compile hooks themselves,
      # and those hooks may define functions which use the `I18n.t/2` macro.
      #
      # If those functions are defined after we define our own `before_compile` hook,
      # the messages there won't be persisted in the `__i18n_messages__/0` function
      # and we won't be able to extract them.
      #
      # This happens with Phoenix views and templates, for example.
      # Phoenix compiles your templates into functions inside the view module,
      # which naturally get access to the macros you've imported/required there,
      # like the `I18n.t/2` macro, for example.
      #
      # We need run/splice these expressions BEFORE we register our `@before_compile` hook.
      unquote(body)

      # Now we're sure that all `@before_compile` hooks for this module have been registered
      # and can now register our own.
      # This way, we're sure our hook will be the last to run and that all functions defined
      # by `@before_compile` hooks have already been defined.
      # This means the `I18n.t/2` macro inside those functions has already been invoked
      # and the translations have been registered in the `@__i18n_messages__` attribute.
      @before_compile I18n
    end
  end

  @doc false
  defmacro consolidate_translations() do
    # A hack to consolidate translations whenever we want.
    # Im not sure this will be needed, so hide it from the docs for now.
    quote do
      @before_compile {I18n, :before_compile_non_overridable__}
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __i18n_messages__(), do: @__i18n_messages__
      # Make this overridable
      defoverridable __i18n_messages__: 0
    end
  end

  @doc false
  defmacro __before_compile_non_overridable__(_env) do
    quote do
      def __i18n_messages__(), do: @__i18n_messages__
    end
  end

  @doc false
  def maybe_register_messages_attribute(module) do
    current_attr_value = Module.get_attribute(module, :__i18n_messages__, :undefined)
    if current_attr_value == :undefined do
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
      * An (optional) *compile-time* keyword list containing several `options`.
        These options include the *special options* (as explained below)
        and the message variables

  All the special options end with `!` to unambiguously distinguish them from
  variables. They are all optional. The complete list of special options is:

      * `:domain!` (`t:String.t/0`) - the domain of the translations.
        It must be a compile-time string.
        If the domain is not given, it will be inferred from the `:domain` argument
        given in the `use I18n` call or from the module name.
      * `:context!` (`t:String.t/0`) - a context to disambiguate equal or similar messages.
        If not given, it will default to the empty string.
      * `:locale!` (`t:Cldr.Locale.t/0`) - a locale in which to render the message.
        If not given, it will be extracted from the process dictionary using
        `Cldr.get_locale/1`.

  A message is uniquely identified by the following three parameters:

      * The `string`
      * The `domain`
      * The `context`

  I18n is able to lookup all translations in all modules in your application
  (even dependencies), as long as you `use I18n` (instead of `import I18n`).

  ## Examples

      I18n.t("Hello {guest}!", context!: "a message", guest: guest)
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

    # Logger.debug("`I18n.t/2` macro invoked inside `#{inspect(module)}`")

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
