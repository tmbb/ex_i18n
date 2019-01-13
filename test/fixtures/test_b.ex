defmodule TestB do
  use Mezzofanti

  def f(_x) do
    translate("abc2 {a}", [])
  end

  def g(_x) do
    translate("def2 {a}", [])
  end

  def h(_x) do
    translate("ghi2 {a}", [])
  end
end
