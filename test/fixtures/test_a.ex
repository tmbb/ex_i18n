defmodule TestA do
  use Mezzofanti

  def f(_x) do
    translate("fair", comment: "'fair' as in 'just'")
  end

  def g(_x) do
    translate("unfair",
      comment: "'unfair' as in 'unjust', not as a 'fair' that has been erased from reality"
    )
  end

  def h(_x) do
    translate("ok", comment: "do you need context for this one?")
  end
end
