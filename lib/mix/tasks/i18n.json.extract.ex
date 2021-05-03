defmodule Mix.Tasks.I18n.Json.Extract do
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
    MessageExtractor.extract_and_persist_messages!(path, [
      I18n.Fixtures.ExampleModule
    ])
  end
end