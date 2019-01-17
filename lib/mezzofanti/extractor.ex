defmodule Mezzofanti.Extractor do
  @moduledoc false

  alias Mezzofanti.Gettext.GettextFormatter

  @translations_priv_dir "priv/mezzofanti"

  @pot_header """
  This file is a PO Template file.

  `msgid`s here are often extracted from source code.
  Add new translations manually only if they're dynamic
  translations that can't be statically extracted.

  Run `mix mezzofanti.extract` to bring this file up to
  date. Leave `msgstr`s empty as changing them here as no
  effect: edit them in PO (`.po`) files instead.\
  """

  @po_header """
  `msgid`s in this file come from POT (.pot) files.

  Do not add, change, or remove `msgid`s manually here as
  they're tied to the ones in the corresponding POT file
  (with the same domain).

  Use `mix mezzofanti.extract --merge` or `mix gettext.merge`
  to merge POT files into PO files.\
  """

  defp extract_translations_from_module(module) do
    try do
      module.__mezzofanti_translations__()
    rescue
      UndefinedFunctionError ->
        []
    end
  end

  @doc """
  Extract all translations from all the modules in all the applications.
  """
  def extract_all_translations() do
    applications = for {app, _, _} <- Application.loaded_applications(), do: app
    modules = Enum.flat_map(applications, fn app -> Application.spec(app, :modules) end)
    Enum.flat_map(modules, &extract_translations_from_module/1)
  end

  @doc """
  Persist the translations into a file.
  """
  def persist_translations(path, header, translations) do
    GettextFormatter.write_to_file!(path, header, translations)
  end

  @doc """
  Extract and persist all translations into a POT file.
  """
  def extract_and_persist_as_pot(path) do
    translations = extract_all_translations()
    persist_translations(path, @pot_header, translations)
  end

  @doc """
  Extract and persist all translations into a PO file.
  """
  def extract_and_persist_as_po(path) do
    translations = extract_all_translations()
    persist_translations(path, @po_header, translations)
  end

  def make_translations_priv_dir!() do
    File.mkdir_p!(@translations_priv_dir)
  end
end
