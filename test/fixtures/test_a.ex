defmodule TestA do
  use Mezzofanti

  def f(_x) do
    translate("abc {a}", [])
  end

  def g(_x) do
    translate("def {a}", [])
  end

  def h(_x) do
    translate("ghi {a}", [])
  end
end
