Imagine have an application `my_app`, which depends on another application `my_dependency`.

I want to enable something like this, which gettext already allows:

```elixir
# * In :my_dependency
# file config.exs:
config :my_dependency,
  gettext_backend: MyDependency.MezzofantiBackend

# file lib/my_dependency/mezzofanti_backend.ex
defmodule MyDependency.MezzofantiBackend do
  use Mezzofanti.Backend
end

# file lib/my_dependency/some_module.ex
defmodule MyDependency.SomeModule do
  use MyDependency.MezzofantiBackend

  def x() do
    translate("my sentence", [])
  end
end

# * In :my_app
# file config.exs
config :my_dependency,
  gettext_backend: MyApp.MezzofantiBackend

# file lib/my_app/mezzofanti_backend.ex
defmodule MyApp.MezzofantiBackend do
  use Mezzofanti.Backend
end
```

The big difference is that when you run `mezzofanti.extract` inside `my_app`'s mix project, it will extract not only the translations in `my_app` (which `gettext` already does), but also the translations in `my_dependency` (which `gettext` can't do).

Basically, the "trick" is to add the translations into something more durable than a process that is only alive while compilation happens.
I've decided to store the translations into a special function in the modules.
To get all the translations in all applications, I just have to iterate over all modules inside all applications. The literal source code that does this is quite clear:

```elixir
  defp extract_translations_from_module(module) do
    try do
      module.__mezzofanti_translations__()
    rescue
      UndefinedFunctionError ->
        []
    end
  end

  @doc """
  Extract all translations from all the modules in all the applications.
  """
  def extract_all_translations() do
    applications = for {app, _, _} <- Application.loaded_applications(), do: app
    modules = Enum.flat_map(applications, fn app -> Application.spec(app, :modules) end)
    Enum.flat_map(modules, &extract_translations_from_module/1)
  end
```