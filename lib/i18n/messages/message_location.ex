defmodule I18n.Messages.MessageLocation do
  @moduledoc false

  @derive Jason.Encoder

  defstruct file: nil,
            line: nil,
            module: nil

  def new(opts) do
    struct(__MODULE__, opts)
  end

  defp parse_application(nil), do: nil
  defp parse_application(string), do: String.to_existing_atom(string)

  def from_map(map) do
    message_location = new(map)
    module = String.to_existing_atom(message_location.module)
    %{message_location | module: module}
  end
end
