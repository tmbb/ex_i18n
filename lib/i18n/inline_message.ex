defmodule I18n.InlineMessage do
  @moduledoc false
  @type t() :: %__MODULE__{}

  alias Cldr.Message.Parser
  alias I18n.MessageHash

  @derive Jason.Encoder

  defstruct text: nil,
            context: "",
            domain: nil,
            location: nil,
            hash: nil

  @doc """
  Parse an ICU message. Raises if invalid message.
  """
  def parse_message!(text) do
    case Parser.message(text) do
      {:ok, message, _, _, _, _} -> message
      {:error, {error_type, text}} -> raise error_type, text
    end
  end

  @doc """
  Create a new message.

  If the field `:hash` is not given, they will be evaluated
  from the available fields (this field is unambiguously determined by the rest of them)
  """
  def new(options) do
    all_options =
      options
      |> canonicalize_text()
      |> MessageHash.maybe_add_hash()

    struct(__MODULE__, all_options)
  end

  defp canonicalize_text(opts) do
    Keyword.update(opts, :text, "", fn text ->
      Cldr.Message.canonical_message!(text, pretty: true)
    end)
  end
end
