defmodule ExampleCldrBackend do
  use Cldr,
    generate_docs: false,
    default_locale: "en",
    locales: ["en", "pt-PT"],
    providers: [
      Cldr.Number
    ]

  @moduledoc false
end
