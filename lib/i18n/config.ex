defmodule I18n.Config do
  @moduledoc """
  Access I18n config options.
  """

  @doc """
  Get the I18n backend.
  """
  def get_backend() do
    Application.get_env(:ex_i18n, :backend)
  end

  def get_clrd_backend() do
    Application.get_env(:ex_i18n, :cldr_backend)
  end
end
