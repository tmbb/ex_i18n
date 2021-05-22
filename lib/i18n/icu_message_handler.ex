defmodule I18n.IcuMessageHandler do
  @moduledoc """
  Parses and formats messages in the ICU message format.

  TODO: should we support alternative formats?
  """

  @doc """
  Format a messages (that has already been parsed) with the given
  arguments and options.
  """
  @spec format(
          list() | tuple(),
          Cldr.Message.arguments(),
          Cldr.Message.options()
        ) :: list() | no_return()

  def format(parsed_message, arguments, options \\ []) do
    Cldr.Message.format_list(parsed_message, arguments, options)
  end

  @doc """
  Parse a message.
  """
  @spec parse(String.t) :: {:ok, list()} | {:error, any()}

  def parse(message_text) do
    Cldr.Message.Parser.parse(message_text)
  end

  @doc """
  Parses a message and formats it with the given arguments and options.

  Useful to immediately preview messages that have been edited or to
  preview messages with different arguments.
  """
  @spec parse_and_format!(
          list() | tuple(),
          Cldr.Message.arguments(),
          Cldr.Message.options()
        ) :: list() | no_return()

  def parse_and_format!(message_text, arguments, options \\ []) do
    Cldr.Message.format!(message_text, arguments, options)
  end
end