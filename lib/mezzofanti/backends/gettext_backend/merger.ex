defmodule Mezzofanti.Backends.GettextBackend.Merger do
  alias Mezzofanti.Backends.GettextBackend
  alias Mezzofanti.Backends.GettextBackend.Extractor

  def merge(directory) do
    locales =
      directory
      |> File.ls!()
      |> Enum.filter(fn f -> File.dir?(Path.join(directory, f)) end)

    for locale <- locales do
      merge_locale(directory, locale)
    end
  end

  def merge_locale(directory, locale) do
    locale_path = Path.join(directory, locale)
    lc_messages_path = Path.join(locale_path, "LC_MESSAGES")

    unless File.exists?(locale_path) do
      raise ArgumentError, """
      Locale '#{locale}' doesn't exist.
      Create it using `mix mezzofanti.new_locale LOCALE`
      """
    end

    # These contain the original messages
    original_groups =
      directory
      |> GettextBackend.grouped_messages_from_directory()
      |> filenames_to_domains()

    # These contain the messages from a locale (which might or might not be translated)
    locale_groups =
      lc_messages_path
      |> GettextBackend.grouped_messages_from_directory()
      |> filenames_to_domains()

    domains_old = Map.keys(locale_groups)
    domains_new = Map.keys(original_groups)

    {add, keep, remove} = add_keep_remove(domains_old, domains_new)

    delete_removed_domains(lc_messages_path, remove)
    persist_added_domains(lc_messages_path, add, original_groups)
    merge_kept_domains(lc_messages_path, keep, locale_groups, original_groups)
  end

  defp merge_kept_domains(lc_messages_path, keep, locale_groups, original_groups) do
    for domain <- keep do
      path = Path.join(lc_messages_path, domain <> ".po")
      original_messages = Map.fetch!(original_groups, domain)
      locale_messages = Map.fetch!(locale_groups, domain)
      new_messages = merge_group(locale_messages, original_messages)
      Extractor.persist_messages_as_po(path, new_messages)
    end
  end

  defp persist_added_domains(lc_messages_path, add, original_groups) do
    for domain <- add do
      path = Path.join(lc_messages_path, domain <> ".po")
      # We're sure the group exists for this domain
      messages = Map.fetch!(original_groups, domain)
      Extractor.persist_messages_as_po(path, messages)
    end
  end

  defp delete_removed_domains(lc_messages_path, domains) do
    for domain <- domains do
      po_file_path = Path.join(lc_messages_path, domain <> ".po")
      File.rm!(po_file_path)
    end
  end

  defp filename_to_domain(file) do
    file
    |> Path.basename()
    |> Path.rootname()
  end

  defp filenames_to_domains(groups) do
    for {file, translations} <- groups, into: %{} do
      {filename_to_domain(file), translations}
    end
  end

  @doc false
  def add_keep_remove(list_old, list_new) do
    s_old = MapSet.new(list_old)
    s_new = MapSet.new(list_new)

    add = MapSet.difference(s_new, s_old) |> MapSet.to_list()
    keep = MapSet.intersection(s_new, s_old) |> MapSet.to_list()
    remove = MapSet.difference(s_old, s_new) |> MapSet.to_list()

    {add, keep, remove}
  end

  def merge_group(g_old, g_new) do
    map_old =
      g_old
      |> Enum.map(fn t -> {{t.string, t.context}, t} end)
      |> Enum.into(%{})

    map_new =
      g_new
      |> Enum.map(fn t -> {{t.string, t.context}, t} end)
      |> Enum.into(%{})

    keys_old = Map.keys(map_old)
    keys_new = Map.keys(map_new)

    s_old = MapSet.new(keys_old)
    s_new = MapSet.new(keys_new)

    {add_keys, keep_keys, _remove_keys} = add_keep_remove(s_old, s_new)
    
    add = map_new |> Map.take(add_keys) |> Map.values()
    # We'll discard most message information from the old messages,
    # but we'll keep the translations.
    # We "keep" the old messages to avoid having to translate them again.
    keep_new = Map.take(map_new, keep_keys)

    keep =
      for {key, message} <- keep_new do
        old_message = Map.fetch!(map_old, key)
        old_translated = old_message.translated
        %{message | translated: old_translated}
      end

    # Return the new messages, ready to be persisted into a file
    add ++ keep
  end
end
