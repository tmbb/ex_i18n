defmodule I18n.Config do
  @moduledoc """
  Access I18n config options.
  """

  @doc """
  Get the I18n backend.

  TODO: deprecated, see if it can be safely removed
  """
  def get_backend() do
    Application.get_env(:ex_i18n, :backend)
  end

  @doc """
  Get the Cldr backend.
  """
  def get_clrd_backend() do
    Application.get_env(:ex_i18n, :cldr_backend)
  end

  def translations_path() do
    default_path = Path.join(["priv", "i18n", "messages.json"])
    Application.get_env(:ex_i18n, :translations_path, default_path)
  end


  @doc """
  Is the invsible marker system active?
  """
  @spec invisible_markers?() :: boolean()
  def invisible_markers?() do
    Application.get_env(:ex_i18n, :invisible_markers?)
  end

  @doc """
  Activate the invsible marker system.
  """
  def set_invisible_markers() do
    Application.put_env(:ex_i18n, :invisible_markers?, true)
    :ok
  end

  @doc """
  Deactivate the invsible marker system.
  """
  def unset_invisible_markers() do
    Application.put_env(:ex_i18n, :invisible_markers?, false)
    :ok
  end
end
