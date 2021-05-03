defmodule I18n.Pseudolocalization.EndToEndTest do
  use ExUnit.Case, async: true
  alias I18n.Fixtures.ExampleModule

  test "pseudolocalization of normal text" do
    message =
      I18n.with_locale("en-m-pseudo", fn ->
        ExampleModule.g("user") |> to_string()
      end)

    assert message == "[Ȟêĺĺø~ üšêȓ~!]"
  end

  test "pseudolocalization of html as normal text" do
    message =
      I18n.with_locale("en-m-pseudo", fn ->
        ExampleModule.i() |> to_string()
      end)

    assert message ==
             "[Ťȟıš~ ɱêššàğê~~ ċøñťàıñš~~ <šťȓøñğ>ȟťɱĺ~~~~ ťàğš</šťȓøñğ>~~~~ &àɱƥ~; ñàšťÿ~ šťüƒƒ~...]"
  end

  test "pseudolocalization of html as html" do
    message =
      I18n.with_locale("en-m-pseudoht", fn ->
        ExampleModule.i() |> to_string()
      end)

    assert message ==
             "[Ťȟıš~ ɱêššàğê~~ ċøñťàıñš~~ <strong>ȟťɱĺ~ ťàğš~</strong> &amp; ñàšťÿ~ šťüƒƒ~...]"
  end
end
