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
Then, to *display* the translated strings, you do define a I18n backend.
That backend will be able to extract translatable strings from your
application and all your dependencies, so that you can translate
everything in a centralized place.
With Gettext, there it's nor possible to translate messages in dependencies,
unless somehow the dependency provides you with an already created `.pot`
file that you add to your application's, `.pot` files
If you are translating user-visible strings
*in a library meant to be imported by other projects*, you shouldn't
define a I18n backend at all.
The user's I18n backend will be able to extract the strings from your library.

Unlike Gettext, where it might make sense to have more than one backend active
at the same time, it never makes sense to have more than one I18n backend
active at the same time.

## Using I18n

To use `I18n`, you must defines a `Cldr` backend and a `I18n` backend.
Refer to [ex_cldr's documentation]() for how to configure a `Cldr` locale.

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

# I18n backend that extracts translations
# from `.po` and `.pot` files (used by gettext)
defmodule ExampleI18nBackend do
  use I18n.Backends.GettextBackend,
    otp_app: :my_app,
    priv: "priv/i18n"
end
```

Both backends should be configured in your app's `config.exs`:

```elixir
# config/config.exs
config :i18n,
  backend: ExampleI18nBackend

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
    translate("Hello {guest}!", context: "a message", variables: [guest: guest])
  end
end
```

The messages use the [ICU message format](https://unicode-org.github.io/icu/).
This format is much more powerful and robust than Gettext.
Support for ICU messages uses the
[ex_cldr_messages](https://hexdocs.pm/ex_cldr_messages/readme.html),
which is part of the [ex_cldr](https://hexdocs.pm/ex_cldr/readme.html)

## Translations

Translations are stored inside PO (Portable Object) files, with a `.po`
extension. For example, this is a snippet from a PO file:

    # This is a comment
    msgid "Hello world!"
    msgstr "Ciao mondo!"

PO files containing translations for an application must be stored in a
directory (by default it's `priv/gettext`) that has the following structure:

    gettext directory
    └─ locale
        └─ LC_MESSAGES
          ├─ domain_1.po
          ├─ domain_2.po
          └─ domain_3.po

Here, `locale` is the locale of the translations (for example, `en_US`),
`LC_MESSAGES` is a fixed directory, and `domain_i.po` are PO files containing
domain-scoped translations.

A concrete example of such a directory structure could look like this:

    priv/gettext
    └─ en_US
    |  └─ LC_MESSAGES
    |     ├─ default.po
    |     └─ errors.po
    └─ it
        └─ LC_MESSAGES
          ├─ default.po
          └─ errors.po

By default, I18n expects translations to be stored under the `priv/I18n`
directory of an application. This behaviour can be changed by specifying a
`:priv` option when using `I18n`:

    # Look for translations in my_app/priv/translations instead of
    # my_app/priv/I18n

    use Gettext, otp_app: :my_app, priv: "priv/translations"

The translations directory specified by the `:priv` option should be a directory
inside `priv/`, otherwise some functions (like `mix i18n.extract`) won't work
as expected.

## Locale

At runtime, all gettext-related functions and macros that do not explicitly
take a locale as an argument read the locale from the process dictionary.

`Cldr.put_locale/1` can be used to change the locale of all backends for
the current Elixir process. That's the preferred mechanism for setting the
locale at runtime.

Similarly, `Cldr.get_locale/0` gets the locale for all backends in the
current process. As mentioned above, the locale is stored **per-process**
(in the process dictionary): this means that the locale must be set
in every new process in order to have the right locale available for that process.
Pay attention to this behaviour, since not setting the locale *will not*
result in any errors when `Cldr.get_locale/0` or `Cldr.get_locale/1`
are called; the default locale will be returned instead.