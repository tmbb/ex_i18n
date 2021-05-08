defmodule Mix.Tasks.I18n.Extract do
  @moduledoc "Extracts translations into a JSON file."
  @shortdoc "Extracts translations into a JSON file."

  use Mix.Task

  alias I18n.{
    MessageExtractor,
    Config
  }

  @impl Mix.Task
  def run(_args) do
    path = Config.translations_path()
    force_compile()
    MessageExtractor.extract_and_persist_messages!(path)
  end

  defp force_compile do
    Enum.map(Mix.Tasks.Compile.Elixir.manifests(), &make_old_if_exists/1)

    # If "compile" was never called, the reenabling is a no-op and
    # "compile.elixir" is a no-op as well (because it wasn't reenabled after
    # running "compile"). If "compile" was already called, then running
    # "compile" is a no-op and running "compile.elixir" will work because we
    # manually reenabled it.
    Mix.Task.reenable("compile.elixir")
    Mix.Task.run("compile")
    Mix.Task.run("compile.elixir")
  end

  defp make_old_if_exists(path) do
    :file.change_time(path, {{2000, 1, 1}, {0, 0, 0}})
  end
end