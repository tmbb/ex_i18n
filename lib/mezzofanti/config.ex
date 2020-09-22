defmodule Mezzofanti.Config do
  @moduledoc """
  Access Mezzofanti config options.
  """

  @doc """
  Get the Mezzofanti backend.
  """
  def backend() do
    Application.get_env(:mezzofanti, :backend)
  end
end
