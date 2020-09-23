defmodule Mezzofanti.Backends.GettextBackendTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias Mezzofanti.Fixtures.ExampleModule

  test "example #1" do
    message = Mezzofanti.with_locale("pt-PT", fn -> ExampleModule.f() end) |> to_string()
    assert message == "Olá a todos!"
  end

  test "example #2" do
    message = Mezzofanti.with_locale("pt-PT", fn -> ExampleModule.g("tmbb") end) |> to_string()
    assert message == "Olá tmbb!"
  end

  test "example #3 - n=0" do
    message = Mezzofanti.with_locale("pt-PT", fn -> ExampleModule.h("kip", 0) end) |> to_string()
    assert message == "kip não tirou fotografias nenhumas."
  end

  test "example #3 - n=1" do
    message = Mezzofanti.with_locale("pt-PT", fn -> ExampleModule.h("kip", 1) end) |> to_string()
    assert message == "kip tirou 1 fotografia."
  end

  test "example #3 - n>1" do
    message = Mezzofanti.with_locale("pt-PT", fn -> ExampleModule.h("kip", 4) end) |> to_string()
    assert message == "kip tirou 4 fotografias."
  end

  test "string not extracted" do
    message_en = ExampleModule.j() |> to_string()
    message_pt = Mezzofanti.with_locale("pt-PT", fn -> ExampleModule.j() end) |> to_string()

    assert message_en == "message not extracted"
    assert message_pt == "message not extracted"
  end

  test "message not extracted logs a warning in any locale" do
    assert capture_log(fn -> ExampleModule.j() end) =~ "mezzofanti - message not extracted"
    
    assert capture_log(fn -> Mezzofanti.with_locale("pt-PT", fn -> ExampleModule.j() end) end) =~
      "mezzofanti - message not extracted"
    
    assert capture_log(fn -> Mezzofanti.with_locale("pseudo", fn -> ExampleModule.j() end) end) =~
      "mezzofanti - message not extracted"
    
    assert capture_log(fn -> Mezzofanti.with_locale("pseudo_html", fn -> ExampleModule.j() end) end) =~
      "mezzofanti - message not extracted"
  end
end
