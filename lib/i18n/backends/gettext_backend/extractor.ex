defmodule I18n.Backends.GettextBackend.Extractor do
  @moduledoc false

  alias I18n.Gettext.GettextFormatter

  @pot_header """
  This file is a PO Template file.

  `msgid`s here are often extracted from source code.
  Add new messages manually only if they're dynamic
  messages that can't be statically extracted.

  Run `mix i18n.extract` to bring this file up to
  date. Leave `msgstr`s empty as changing them here as no
  effect: edit them in PO (`.po`) files instead.\
  """

  @po_header """
  `msgid`s in this file come from POT (.pot) files.

  Do not add, change, or remove `msgid`s manually here as
  they're tied to the ones in the corresponding POT file
  (with the same domain).

  Use `mix i18n.extract --merge` or `mix gettext.merge`
  to merge POT files into PO files.\
  """

  defp extract_messages_from_module(module) do
    try do
      module.__I18n_messages__()
    rescue
      UndefinedFunctionError ->
        []
    end
  end

  @doc """
  Extract all messages from all the modules in all the applications.
  """
  def extract_all_messages() do
    applications = for {app, _, _} <- Application.loaded_applications(), do: app
    modules = Enum.flat_map(applications, fn app -> Application.spec(app, :modules) end)
    Enum.flat_map(modules, &extract_messages_from_module/1)
  end

  @doc """
  Group messages by domain.

  That's how Gettext groups them by default (one domain per file).
  We'll follow this aproach here, by lack of a better option.
  """
  def group_messages_by_domain(messages) do
    Enum.group_by(messages, fn t -> t.domain end)
  end

  # ------------------------------------------
  # Persist messages as PO(T) files
  # ------------------------------------------

  @doc """
  Extract and persist all messages into a directory of POT files.
  """
  def extract_and_persist_as_pot(directory_path) do
    extract_and_persist_with_header_and_extension(
      directory_path,
      @pot_header,
      ".pot"
    )
  end

  @doc """
  Delete all .POT files from a directory.
  """
  def clean_pot_files(directory_path) do
    for file <- Path.wildcard(Path.join(directory_path, "*.pot")) do
      File.rm!(file)
    end
  end

  @doc """
  Extract and persist all messages into a .PO file.
  """
  def extract_and_persist_as_po(directory_path) do
    extract_and_persist_with_header_and_extension(
      directory_path,
      @po_header,
      ".po"
    )
  end

  defp extract_and_persist_with_header_and_extension(directory_path, header, ext) do
    messages = extract_all_messages()
    domains = group_messages_by_domain(messages)
    File.mkdir_p!(directory_path)

    for {filename, messages} <- domains do
      path = Path.join(directory_path, filename <> ext)
      GettextFormatter.write_to_file!(path, header, messages)
    end

    :ok
  end

  def persist_messages_as_po(path, messages) do
    GettextFormatter.write_to_file!(path, @po_header, messages)
  end

  def make_messages_priv_dir!(directory) do
    File.mkdir_p!(directory)
  end
end
