defmodule Mix.Tasks.I18n.NewLocale do
  use Mix.Task
  alias I18n.Backends.GettextBackend.LocaleCreator

  @recursive true

  @shortdoc "Creates a new locale"

  @moduledoc """
  Extracts messages from source code.
  """

  def run(args) do
    {named, unnamed} = OptionParser.parse!(args, strict: [priv: :string])
    priv = Keyword.get(named, :priv, "priv/i18n")
    [locale] = unnamed
    LocaleCreator.create_locale(priv, locale)
  end
end
