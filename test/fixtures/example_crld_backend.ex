defmodule ExampleClrdBackend do
  use Cldr,
    default_locale: "en",
    locales: ["en", "pt-PT"],
    providers: [
      Cldr.Number,
      Cldr.DateTime,
      Cldr.Unit,
      Cldr.Calendar,
      Cldr.Message
    ]
end
