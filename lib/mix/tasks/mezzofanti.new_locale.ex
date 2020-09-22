defmodule Mix.Tasks.Mezzofanti.NewLocale do
  use Mix.Task
  alias Mezzofanti.Backends.GettextBackend.LocaleCreator

  @recursive true

  @shortdoc "Extracts messages from source code"

  @moduledoc """
  Extracts messages from source code.
  """

  def run(args) do
    # TODO: add better error handling
    [locale] = args
    LocaleCreator.create_locale("priv/mezzofanti/", locale)
  end
end
