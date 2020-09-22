defmodule Mezzofanti.Pseudolocalization do
  @moduledoc """
  A module to support pseudolocalization of several markup formats.

  Currently it supports the following formats:

      * Raw text
      * XML and HTML
  """

  alias Mezzofanti.Pseudolocalization.TextPseudolocalization
  alias Mezzofanti.Pseudolocalization.HtmlPseudolocalization

  defdelegate pseudolocalize_text(text), to: TextPseudolocalization, as: :pseudolocalize
  defdelegate pseudolocalize_html(text), to: HtmlPseudolocalization, as: :pseudolocalize
end
