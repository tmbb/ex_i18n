defmodule Mix.Tasks.Mezzofanti.Merge do
  use Mix.Task
  alias Mix.Tasks.Mezzofanti.Extract
  alias Mezzofanti.Backends.GettextBackend.Merger

  @recursive true

  @shortdoc "Extracts messages from source code"

  @moduledoc """
  Extracts messages from source code.
  """

  # Currently no configuration options are supported
  def run(_args) do
    # Extract messages
    Extract.run([])
    # Merge 
    Merger.merge("priv/mezzofanti")
  end
end