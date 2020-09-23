defmodule Mix.Tasks.Mezzofanti.Merge do
  use Mix.Task
  alias Mix.Tasks.Mezzofanti.Extract
  alias Mezzofanti.Backends.GettextBackend.Merger

  @recursive true

  @shortdoc "Merges new messages into the locale directories"

  @moduledoc """
  Merges new messages into the locale directories.
  """

  # Currently no configuration options are supported
  def run(args) do
    {named, _} = OptionParser.parse!(args, strict: [priv: :string])
    priv = Keyword.get(named, :priv, "priv/mezzofanti")
    # Extract messages
    Extract.run(args)
    # Merge 
    Merger.merge(priv)
  end
end
