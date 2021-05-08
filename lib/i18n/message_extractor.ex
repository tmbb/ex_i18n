defmodule I18n.MessageExtractor do
  @moduledoc false

  alias I18n.Message
  alias I18n.TranslationData

  defp extract_all_inline_messages(extra_modules, predicate) do
    modules = Enum.map(:code.all_loaded(), fn {m, _} -> m end) ++ extra_modules

    Enum.flat_map(modules, fn module ->
      if predicate.(module) do
        try do
          module.__i18n_messages__()
        rescue
          UndefinedFunctionError -> []
        end
      else
        []
      end
    end)
  end

  defp merge_equivalent_messages(messages) do
    messages
    |> Enum.group_by(fn message -> message.hash end)
    |> Enum.map(fn {_k, messages} -> Message.merge_inline_messages(messages) end)
  end

  def extract_all_messages(extra_modules, predicate \\ (fn _ -> true end)) do
    extract_all_inline_messages(extra_modules, predicate)
    |> merge_equivalent_messages()
  end

  @doc """
  Extract messages from the code and persist them in the given path.

  Messages extracted from the source code will be merged with the messages
  loaded from the file in a way that preserves existing translations.
  """
  def extract_and_persist_messages!(path, extra_modules \\ []) do
    extracted_messages = extract_all_messages(extra_modules)

    translation_data =
      case TranslationData.load_translation_data(path) do
        {:ok, translation_data} ->
          translation_data

        {:error, _} ->
          TranslationData.new()
      end

    new_translation_data =
      TranslationData.incorporate_messages(
        translation_data,
        extracted_messages
      )

    TranslationData.persist_translation_data!(new_translation_data, path)
  end
end