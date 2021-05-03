defmodule I18n.Messages.Message do
  @moduledoc false
  @type t() :: %__MODULE__{}

  alias I18n.Messages.{
    MessageLocation,
    MessageTranslation,
    MessageHash
  }

  @derive {Jason.Encoder, except: [:hash]}

  defstruct text: nil,
            context: "",
            domain: "default",
            hash: nil,
            locations: [],
            translations: %{}

  def merge_inline_messages([inline_message | _] = inline_messages) do
    locations = Enum.map(inline_messages, fn msg -> msg.location end)

    %__MODULE__{
      text: inline_message.text,
      context: inline_message.context,
      domain: inline_message.domain,
      hash: inline_message.hash,
      locations: locations
    }
  end

  @doc """
  Create a new message.

  If the field `:hash` is not given, they will be evaluated
  from the available fields (this field is unambiguously determined by the rest of them)
  """
  def new(options) do
    options = Enum.into(options, [])
    all_options = MessageHash.maybe_add_hash(options)
    struct(__MODULE__, all_options)
  end

  def from_map(map) do
    encoded_translations = Map.fetch!(map, :translations)
    encoded_locations = Map.fetch!(map, :locations)

    decoded_translations = decode_translations(encoded_translations)
    decoded_locations = Enum.map(encoded_locations, &MessageLocation.from_map/1)

    map_with_decoded_translations =
      %{map | locations: decoded_locations, translations: decoded_translations}

    new(map_with_decoded_translations)
  end

  defp decode_translations(translations_map) do
    for translation_data <- translations_map, into: %{} do
      locale = Map.fetch!(translation_data, :locale)
      {locale, MessageTranslation.from_map(translation_data)}
    end
  end
end
