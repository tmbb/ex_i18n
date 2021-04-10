defmodule I18n.Backends.GettextBackendTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias I18n.Fixtures.ExampleModule

  test "example #1" do
    message = I18n.with_locale("pt-PT", fn -> ExampleModule.f() end) |> to_string()
    assert message == "Olá a todos!"
  end

  test "example #2" do
    message = I18n.with_locale("pt-PT", fn -> ExampleModule.g("tmbb") end) |> to_string()
    assert message == "Olá tmbb!"
  end

  test "example #3 - n=0" do
    message = I18n.with_locale("pt-PT", fn -> ExampleModule.h("kip", 0) end) |> to_string()
    assert message == "kip não tirou fotografias nenhumas."
  end

  test "example #3 - n=1" do
    message = I18n.with_locale("pt-PT", fn -> ExampleModule.h("kip", 1) end) |> to_string()
    assert message == "kip tirou 1 fotografia."
  end

  test "example #3 - n>1" do
    message = I18n.with_locale("pt-PT", fn -> ExampleModule.h("kip", 4) end) |> to_string()
    assert message == "kip tirou 4 fotografias."
  end

  test "message not extracted - logs a warning in any locale" do
    assert capture_log(fn ->
             message = ExampleModule.j() |> to_string()
             # also text the message content, since we're at it
             assert message == "message not extracted"
           end) =~ "I18n - message not extracted"

    assert capture_log(fn ->
             I18n.with_locale(
               "pt-PT",
               fn ->
                 message = ExampleModule.j() |> to_string()
                 assert message == "message not extracted"
               end
             )
           end) =~ "I18n - message not extracted"

    assert capture_log(fn ->
             I18n.with_locale(
               "pseudo",
               fn ->
                 message = ExampleModule.j() |> to_string()
                 assert message == "message not extracted"
               end
             )
           end) =~ "I18n - message not extracted"

    assert capture_log(fn ->
             I18n.with_locale(
               "pseudo_html",
               fn ->
                 message = ExampleModule.j() |> to_string()
                 assert message == "message not extracted"
               end
             )
           end) =~ "I18n - message not extracted"
  end
end
