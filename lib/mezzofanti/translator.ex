defmodule Mezzofanti.Translator do
  @moduledoc false
  alias Mezzofanti.Config

  @doc false
  def __translate__(hash, variables, translation) do
    locale = Mezzofanti.get_locale() || Cldr.default_locale().cldr_locale_name

    case Config.backend() do
      nil ->
        Cldr.Message.format_list(translation.parsed, variables, locale: locale)

      module ->
        module.translate_from_hash(hash, locale, variables)
    end
  end
end
