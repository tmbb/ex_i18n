defmodule TestA do
  use Mezzofanti

  def f() do
    translate("message #1", comment: "'fair' as in 'just'")
  end

  def g() do
    translate("message #2", context: "a message")
  end

  def h() do
    translate("message #3", domain: "domain2")
  end
end
