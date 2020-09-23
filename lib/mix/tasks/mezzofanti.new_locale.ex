defmodule Mix.Tasks.Mezzofanti.NewLocale do
  use Mix.Task
  alias Mezzofanti.Backends.GettextBackend.LocaleCreator

  @recursive true

  @shortdoc "Creates a new locale"

  @moduledoc """
  Extracts messages from source code.
  """

  def run(args) do
    {named, unnamed} = OptionParser.parse!(args, strict: [priv: :string])
    priv = Keyword.get(named, :priv, "priv/mezzofanti")
    [locale] = unnamed
    LocaleCreator.create_locale(priv, locale)
  end
end
