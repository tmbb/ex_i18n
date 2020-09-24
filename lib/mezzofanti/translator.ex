defmodule Mezzofanti.Translator do
  @moduledoc false
  alias Mezzofanti.Config

  @doc false
  def __translate__(hash, variables, translation) do
    locale = Cldr.get_locale()

    case Config.backend() do
      nil ->
        # Interpolate the message with the default locale
        Cldr.Message.format_list(translation.parsed, variables, locale: locale)

      module ->
        module.translate_from_hash(hash, locale, variables, translation)
    end
  end
end
