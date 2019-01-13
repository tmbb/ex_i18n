defmodule TestC do
  use Mezzofanti

  def f(_x) do
    translate("abc3 {a}", [])
  end

  def g(_x) do
    translate("def3 {a}", [])
  end

  def h(_x) do
    translate("ghi3 {a}", [])
  end
end
