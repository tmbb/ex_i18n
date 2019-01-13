defmodule Mix.Tasks.Mezzofanti.Extract do
  use Mix.Task
  alias Mezzofanti.Extractor

  @recursive true

  @shortdoc "Extracts translations from source code"

  @moduledoc """
  Extracts translations from source code.
  """

  def run(_args) do
    # Start all registered apps.
    Mix.Tasks.App.Start.run([])
    # Generate the `mezzofanti` directory where translations will go.
    Extractor.make_translations_priv_dir!()
    # Extract all translations and persiste in the POT file.
    Extractor.extract_and_persist_as_pot("priv/mezzofanti/default.pot")
  end
end
