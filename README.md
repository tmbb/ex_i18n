# I18n

The `I18n` module provides a way of localizing your application
based on the [ICU message format](https://unicode-org.github.io/icu/).

## Differences and similarities to Gettext

The API is similar to [Gettext](https://hexdocs.pm/gettext/Gettext.html),
but with a number of important differences.
The main difference (aside from the message format) is the following:

In Gettext, you define a backend.
The backend defines a number of macros.
You use those macros to "mark" strings for translation
so that Gettext can gather all translatable strings and persist them
in `.po` and `.pot` files, which your translators can translate.

In I18n, to mark strings for translation you *don't* need
to define a backend.
You just `use I18n` and then mark the strings for translation
with the `I18n.t/2` macro.
The `I18n` application will be able to extract translatable strings from your
application and all your dependencies, so that you can translate
everything in a centralized place.

With Gettext, there it's not possible to translate messages in dependencies,
unless somehow the dependency provides you with an already created `.pot`
file that you add to your application's, `.pot` files.
## Using I18n

To use `I18n`, you must defines a `Cldr` backend and a `I18n` backend.
Refer to [ex_cldr's documentation](https://hexdocs.pm/ex_cldr/readme.html#introduction) for how to configure a `Cldr` locale.

```elixir
# Cldr backend to handle parsing and formatting ICU messages
defmodule ExampleClrdBackend do
  use Cldr,
    default_locale: "en",
    locales: ["en", "pt-PT"],
    providers: [
      Cldr.Number,
      Cldr.DateTime,
      Cldr.Unit,
      Cldr.Calendar,
      Cldr.Message
    ]
end
```

The backend should be configured in your app's `config.exs`:

```elixir
# config/config.exs
config :ex_cldr,
  default_locale: "en",
  default_backend: ExampleClrdBackend,
  json_library: Jason
```

To translate strings in a module, you have to `use I18n` inside the module
(it's *not* enough to `import I18n`, because the `use` macro adds some
pre-compile hooks so that I18n is able to find the translated strings).
This will import a `translate/2` macro into your module:

```elixir
defmodule ExampleModule do
  use I18n
  # Note that you don't need to require or import a I18n backend here.
  # Just use the I18n library, and once a backend is configured
  # it will automatically become aware of these messages
  # (even if the messages exist in a different application)

  def f() do
    # A simple static translation
    translate("Hello world!")
  end

  def g(guest) do
    # A translation with a variable.
    # This translation also contains a context (to disambiguate messages with the same text)
    translate("Hello {guest}!", context: "a message", bindings: [guest: guest])
  end
end
```

The messages use the [ICU message format](https://unicode-org.github.io/icu/).
This format is much more powerful and robust than Gettext.
Support for ICU messages uses the
[ex_cldr_messages](https://hexdocs.pm/ex_cldr_messages/readme.html),
which is part of the [ex_cldr](https://hexdocs.pm/ex_cldr/readme.html)

## Translations

By default, extracted messages and translations in all languages are stored in a JSON file at `priv/i18n/messages.json`.
## Locale

The `I18n.t/2` macro reads the locale from the process dictionary at runtime.

`Cldr.put_locale/1` can be used to change the locale for
the current Elixir process. That's the preferred mechanism for setting the
locale at runtime.

Similarly, `Cldr.get_locale/0` gets the locale for the
current process. As mentioned above, the locale is stored **per-process**
(in the process dictionary): this means that the locale must be set
in every new process in order to have the right locale available for that process.

Pay attention to this behaviour, since not setting the locale *will not*
result in any errors when `Cldr.get_locale/0` or `Cldr.get_locale/1`
are called; the default locale will be returned instead.