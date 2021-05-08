defmodule I18n.MessageHash do
  @moduledoc false

  @doc """
  Hash the data that unambiguously identifies a message into a binary.

  Currently we use the SHA1 algorithm, but this is an implementation detail
  that's subject to change.
  """
  def hash(domain, context, text) do
    message_unique_identifier = {domain, context, text}
    :crypto.hash(:sha, :erlang.term_to_binary(message_unique_identifier))
  end

  @doc """
  Add the hash to a list of options.

  The hash is evaluated according to the following options:
  `:domain`, `:context` and `:text`.
  """
  def maybe_add_hash(opts) do
    case Keyword.get(opts, :hash) do
      nil ->
        domain = Keyword.get(opts, :domain)
        context = Keyword.get(opts, :context)
        text = Keyword.get(opts, :text)
        hash = hash(domain, context, text)
        [{:hash, hash} | opts]

      _ ->
        opts
    end
  end
end