defmodule I18n.Translator do
  @moduledoc false
  alias I18n.Config

  @doc false
  def __translate__(hash, variables, translation) do
    # I18n will use Cldr locales; no need to abstract this further.
    locale = Cldr.get_locale()

    # Try to find a I18n backend that will translate our messages.
    case Config.get_backend() do
      # No I18n backend was defined; Use the default Clrd backend format
      # (the untranslated) message.
      nil ->
        # Interpolate the message with the default locale.
        Cldr.Message.format_list(translation.parsed, variables, locale: locale)

      # We've found a I18n backend. Use that backend to translate the message
      module ->
        module.translate_from_hash(hash, locale, variables, translation)
    end
  end
end
