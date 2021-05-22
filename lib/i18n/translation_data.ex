defmodule I18n.TranslationData do
  alias I18n.Message
  alias I18n.MessageTranslation

  @derive Jason.Encoder

  defstruct locales: [],
            # :messages is a map to make it easier to dynamically edit
            # The translation data. We need a unique key for the translations anyway
            # and editing a map based on a key is much easier than editing a list.
            # Ideally this should be someting like a Mnesia database, but that
            # would complicate the implementation for little benefit.
            messages: %{},
            # :deleted_messages stores messages which have been deleted but which
            # have already been translated. This makes it less probably that
            # (possibly hard to replicate) translations will be lost.
            deleted_messages: %{}

  @type t :: %__MODULE__{}

  @doc """
  Create new %#{__MODULE__}{}.
  """
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @doc """
  Prune old messages that have been deleted.

  Only use this after you're sure you won't be needing the old translations,
  which will be deleted too.
  """
  def prune_deleted_messages(%__MODULE__{} = translation_data) do
    %{translation_data | deleted_messages: %{}}
  end

  def get_message(%__MODULE__{} = translation_data, hash) do
    Map.get(translation_data.messages, hash)
  end

  @doc """
  Add a new locale to the translation data.
  """
  def add_locale(%__MODULE__{} = translation_data, locale) do
    %{translation_data | locales: [locale | translation_data.locales]}
  end

  def put_translation(%__MODULE__{} = translation_data, hash, %MessageTranslation{} = new_translation) do
    {:ok, message} = Map.fetch(translation_data.messages, hash)
    new_translations = Map.put(message.translations, new_translation.locale, new_translation)
    new_message = %{message | translations: new_translations}
    new_messages = Map.put(translation_data.messages, hash, new_message)
    %{translation_data | messages: new_messages}
  end

  def translate_message(%__MODULE__{} = translation_data, hash, locale_name, translation_text) do
    # Get the old translation (if it exists)
    {:ok, message} = Map.fetch(translation_data.messages, hash)
    old_translation = Map.fetch(message.translations, locale_name)
    # Create a new translation from scratch or wdit the old translation
    new_translation =
      case old_translation do
        :error ->
          MessageTranslation.new(locale: locale_name, text: translation_text)

        {:ok, translation} ->
          %{translation | text: translation_text}
      end

    put_translation(translation_data, hash, new_translation)
  end

  def get_translations_by_locale(%__MODULE__{} = translation_data, locale) do
    translation_data.messages
    |> Enum.map(fn {_hash, message} -> Map.get(message.translations, locale) end)
    |> Enum.reject(fn value -> value == nil end)
  end



  @doc """
  Deletes a locale from the translation data.
  """
  def delete_locale(%__MODULE__{} = translation_data, locale) do
    new_locales = List.delete(translation_data.locales, locale)
    %{translation_data | locales: new_locales}
  end

  def incorporate_messages(%__MODULE__{} = translation_data, message_list, _options \\ []) do
    # Old messages will contain translations; we want to preserve those!
    # New messages won't contain any translations yet
    # (they've just been extracted from the source code)
    old_message_map = translation_data.messages
    deleted_messages = translation_data.deleted_messages
    new_message_map = message_list_to_map(message_list)

    # First we create some `MapSet`s to help with "naïve" diffs.
    # These naïve diffs will be refined later based on string similarity
    old_message_keys = old_message_map |> Map.keys() |> MapSet.new()
    new_message_keys = new_message_map |> Map.keys() |> MapSet.new()
    # Now we decide which keys to *keep*, which keys to *delete* and which keys to *add*.

    # In the naïve diff there are no keys to update (updating is based on string similarity)

    # These are the keys for the translations we'll keep.
    #
    # By definition, equivalent messages must contain:
    #   1. The same text (or sufficiently similar text)
    #   2. The same context
    #   3. The same domain
    #
    # If any of these parameters change, the message IS NOT equivalent.
    # This means the only relevant pice of information that might have changed
    # is the list of locations (those can indeed chnange for a numbr of reasons).
    #
    # We will only use this set of keys to update the message locations.
    keys_to_keep = MapSet.intersection(old_message_keys, new_message_keys) |> Enum.into([])

    # Messages which don't appear in the source code anymore will be deleted.
    # If they already contain translations, we'll save them in a special place
    # so that (possibly expensive) translations won't be lost.
    # These messages will be persisted along with the rest of the translation data
    # until explicitly deleted.
    keys_to_delete = MapSet.difference(old_message_keys, new_message_keys) |> Enum.into([])

    # Brand new messages extracted from the source.
    # These messages won't have a translation yet.
    keys_to_add = MapSet.difference(new_message_keys, old_message_keys) |> Enum.into([])

    # TODO: refine key deletion by supporting updates

    # Now we apply the changes to the message map
    translations_to_keep = Map.take(new_message_map, keys_to_keep)
    translations_to_delete = Map.take(new_message_map, keys_to_delete)
    translations_to_add = Map.take(new_message_map, keys_to_add)

    updated_deleted_messages_map = Map.merge(deleted_messages, translations_to_delete)

    updated_message_map =
      old_message_map
      # Remove some keys...
      |> Map.drop(keys_to_delete)
      # Add missing translations
      |> Map.merge(translations_to_add)
      # Update locations on already existing translations
      |> Map.merge(translations_to_keep, &update_locations/3)

    # Finally, return the updated translation data.
    # Note that we haven«t touched the locale.
    %{translation_data |
      messages: updated_message_map,
      deleted_messages: updated_deleted_messages_map}
  end

  # Update location of an old message based on the location of a new messages
  defp update_locations(_key, old_message, new_message) do
    # Preserve the fields on the old message because the old message
    # contains translations while the new one doesn't.
    %{old_message | locations: new_message.locations}
  end

  # ------------
  # Persistence:
  # ------------
  # Only JSON is supported right now.

  @doc """
  Decodes a JSON string into a `%#{inspect(__MODULE__)}{}` struct.
  """
  def decode_from_string(string) do
    map = Jason.decode!(string, keys: :atoms!)
    from_map(map)
  end

  @doc """
  Decodes a `%#{inspect(__MODULE__)}{}` struct from a JSON file.
  """
  @spec load_translation_data(Path.t()) :: {:ok, __MODULE__.t()} | {:error, File.posix()}
  def load_translation_data(path) do
    case File.read(path) do
      {:ok, string} ->
        {:ok, decode_from_string(string)}

      {:error, _error_code} = error ->
        error
    end
  end

  @doc """
  Decodes a `%#{inspect(__MODULE__)}{}` struct from a JSON file.
  Raises if the file can't be read for any reason.
  """
  @spec load_translation_data!(Path.t()) :: {:ok, __MODULE__.t()} | {:error, File.posix()}
  def load_translation_data!(path) do
    case load_translation_data(path) do
      {:ok, translation_data} ->
        translation_data

      {:error, error_code} = _error ->
        raise ArgumentError, "Couldn't read file '#{path}'. Error code: :#{error_code}."
    end
  end

  @doc """
  Encodes a `%#{inspect(__MODULE__)}{}` struct and saves it
  in the given path as a JSON file.
  """
  @spec persist_translation_data!(__MODULE__.t(), Path.t()) :: :ok
  def persist_translation_data!(data, path) do
    encoded = translation_data_to_json(data)
    # Create directory if it doesn't exist
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, encoded)
    :ok
  end

  @doc """
  Encodes a `%#{inspect(__MODULE__)}{}` struct as JSON.
  Returns the JSON binary.
  """
  def translation_data_to_json(data) do
    message_list =
      # Start with a map of translations
      data.messages
      # Turn the map into a list
      |> Map.values()
      # Turn the map of translations into a list of translations
      |> Enum.map(fn msg -> %{msg | translations: Map.values(msg.translations)} end)

    deleted_message_list = Map.values(data.deleted_messages)
    new_data = %{data | messages: message_list, deleted_messages: deleted_message_list}
    Jason.encode!(new_data, pretty: true)
  end

  defp from_map(map) do
    locales = Map.fetch!(map, :locales)
    messages = Map.fetch!(map, :messages)
    deleted_messages = Map.fetch!(map, :deleted_messages)

    decoded_messages = make_messages_map(messages)
    decoded_deleted_messages = make_messages_map(deleted_messages)

    new(
      locales: locales,
      messages: decoded_messages,
      deleted_messages: decoded_deleted_messages
    )
  end

  defp make_messages_map(messages) do
    for encoded_message <- messages, into: %{} do
      decoded_message = Message.from_map(encoded_message)
      key = decoded_message.hash

      {key, decoded_message}
    end
  end

  defp message_list_to_map(messages) do
    for message <- messages, into: %{} do
      key = message.hash
      {key, message}
    end
  end
end