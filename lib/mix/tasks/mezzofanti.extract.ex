defmodule Mix.Tasks.Mezzofanti.Extract do
  use Mix.Task
  alias Mezzofanti.Extractor

  @recursive true

  @shortdoc "Extracts messages from source code"

  @moduledoc """
  Extracts messages from source code.
  """

  def run(_args) do
    # Start all registered apps.
    Mix.Tasks.App.Start.run([])
    # Generate the `mezzofanti` directory where messages will go.
    Extractor.make_messages_priv_dir!()
    # Extract all messages and persiste in the POT file.
    Extractor.extract_and_persist_as_pot("priv/mezzofanti/")
  end
end
