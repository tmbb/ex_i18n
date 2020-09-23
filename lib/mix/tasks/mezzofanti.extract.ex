defmodule Mix.Tasks.Mezzofanti.Extract do
  use Mix.Task
  alias Mezzofanti.Backends.GettextBackend.Extractor

  @recursive true

  @shortdoc "Extracts messages from source code"

  @moduledoc """
  Extracts messages from source code.
  """

  def run(args) do
    {named, _} = OptionParser.parse!(args, strict: [priv: :string])
    priv = Keyword.get(named, :priv, "priv/mezzofanti")
    # Start all registered apps.
    Mix.Tasks.App.Start.run([])
    # Generate the `mezzofanti` directory where messages will go.
    Extractor.make_messages_priv_dir!(priv)
    # Remove old POT files
    Extractor.clean_pot_files(priv)
    # Extract all messages and persiste in the POT file.
    Extractor.extract_and_persist_as_pot(priv)
  end
end
