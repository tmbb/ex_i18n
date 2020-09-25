defmodule Mezzofanti.Pseudolocalization.EndToEndTest do
  use ExUnit.Case, async: true
  alias Mezzofanti.Fixtures.ExampleModule

  test "pseudolocalization of normal text" do
    message = Mezzofanti.with_locale("en-m-pseudo", fn ->
        ExampleModule.g("user") |> to_string()
      end)

    assert message == "Ȟêĺĺø~ üšêȓ~!"
  end

  test "pseudolocalization of html as normal text" do
    message = Mezzofanti.with_locale("en-m-pseudo", fn ->
        ExampleModule.i() |> to_string()
      end)

    assert message == "Ťȟıš~ ɱêššàğê~~ ċøñťàıñš~~ <šťȓøñğ>ȟťɱĺ~~~~ ťàğš</šťȓøñğ>~~~~ &àɱƥ~; ñàšťÿ~ šťüƒƒ~..."
  end

  test "pseudolocalization of html as html" do
    message = Mezzofanti.with_locale("en-m-pseudoht", fn ->
        ExampleModule.i() |> to_string()
      end)

    assert message == "Ťȟıš~ ɱêššàğê~~ ċøñťàıñš~~ <strong>ȟťɱĺ~ ťàğš~</strong> &amp; ñàšťÿ~ šťüƒƒ~..."
  end
end
