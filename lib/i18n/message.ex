defmodule I18n.Message do
  @moduledoc false
  @type t() :: %__MODULE__{}

  alias Cldr.Message.Parser

  defstruct string: nil,
            file: nil,
            line: nil,
            module: nil,
            comment: "",
            context: "",
            domain: "default",
            flag: nil,
            hash: nil,
            translated: "",
            # For future use (not yet implemented)
            previous_hash: nil

  @doc """
  Hash the data that unambiguously identifies a message into a binary.

  Currently we use the SHA1 algorithm, but this is an implementation detail
  that's subject to change.
  """
  def hash(domain, context, string) do
    message_unique_identifier = {domain, context, string}
    :crypto.hash(:sha, :erlang.term_to_binary(message_unique_identifier))
  end

  @doc """
  Parse an ICU message. Raises if invalid message.
  """
  def parse_message!(string) do
    case Parser.message(string) do
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
      |> canonicalize_string()
      |> maybe_add_hash()

    struct(__MODULE__, all_options)
  end

  @doc """
  Sets the message domain. Also resets the message's `:hash`
  """
  def set_domain(%__MODULE__{} = message, domain) do
    new_hash = hash(domain, message.context, message.string)
    %{message | hash: new_hash, domain: domain}
  end

  # Helpers:

  defp maybe_add_hash(opts) do
    case Keyword.get(opts, :hash) do
      nil ->
        domain = Keyword.get(opts, :domain)
        context = Keyword.get(opts, :context)
        string = Keyword.get(opts, :string)
        [{:hash, hash(domain, context, string)} | opts]

      _ ->
        opts
    end
  end

  defp canonicalize_string(opts) do
    Keyword.update(opts, :string, "", fn string ->
      Cldr.Message.canonical_message!(string, pretty: true)
    end)
  end
end
