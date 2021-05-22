defmodule I18n.TranslationDataStatistics do
  @moduledoc """
  Statistics about translated/untranslated messages.
  """
  alias I18n.TranslationData

  defstruct messages_count: 0,
            locales: [],
            translated_counts: %{},
            untranslated_counts: %{},
            translated_percent: %{},
            untranslated_percent: %{}

  @type t :: %__MODULE__{}

  def stats_for(%TranslationData{} = translation_data) do
    messages_count = count_messages(translation_data)
    locales = get_locales(translation_data)

    rows =
      for locale <- locales do
        translated_count = count_translated_messages(translation_data, locale)
        untranslated_count = messages_count - translated_count
        translated_percent = translated_count / messages_count * 100
        untranslated_percent = 100 - translated_percent

        %{
          locale: locale,
          translated_count: translated_count,
          untranslated_count: untranslated_count,
          translated_percent: translated_percent,
          untranslated_percent: untranslated_percent
        }
      end

    %__MODULE__{
      messages_count: messages_count,
      locales: Enum.sort(locales),
      translated_counts: rows_to_column(rows, :translated_count),
      untranslated_counts: rows_to_column(rows, :untranslated_count),
      translated_percent: rows_to_column(rows, :translated_percent),
      untranslated_percent: rows_to_column(rows, :untranslated_percent),
    }
  end

  defp rows_to_column(rows, column) do
    rows
    |> Enum.map(fn row -> {row[:locale], row[column]} end)
    |> Enum.into(%{})
  end

  defp count_messages(%TranslationData{} = translation_data) do
    map_size(translation_data.messages)
  end

  defp get_locales(%TranslationData{} = translation_data) do
    translation_data.locales
  end

  defp translated_messages(%TranslationData{} = translation_data, locale) do
    translation_data.messages
    |> Enum.map(fn {_hash, message} -> message.translations end)
    |> Enum.filter(fn translations -> Map.has_key?(translations, locale) end)
  end

  defp count_translated_messages(%TranslationData{} = translation_data, locale) do
    length(translated_messages(translation_data, locale))
  end
end