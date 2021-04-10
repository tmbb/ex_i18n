defmodule ExampleCldrBackend do
  use Cldr,
    default_locale: "en",
    locales: ["en", "pt-PT"],
    providers: [
      Cldr.Number
    ]
end
