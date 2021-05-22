defmodule I18n.Config do
  @moduledoc """
  Access I18n config options.
  """

  @doc """
  Get the Cldr backend.
  """
  def get_clrd_backend() do
    Application.get_env(:ex_i18n, :cldr_backend)
  end

  @doc """
  Get the path to the file containng the translations.
  """
  def translations_path() do
    default_path = Path.join(["priv", "i18n", "messages.json"])
    Application.get_env(:ex_i18n, :translations_path, default_path)
  end
end
