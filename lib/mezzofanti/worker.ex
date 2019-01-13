defmodule Mezzofanti.Worker do
  @moduledoc false

  def translate(string, opts) do
    locale = Keyword.get(opts, :locale, "en")

    string <> " (as rendered in the '#{locale}' locale)"
  end
end
