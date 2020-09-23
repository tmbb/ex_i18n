defmodule ExampleBackend.Cldr do
  use Cldr,
    default_locale: "en",
    locales: ["fr", "en", "bs", "si", "ak", "th"],
    providers: [
      Cldr.Number,
      Cldr.DateTime,
      Cldr.Unit,
      Cldr.Calendar,
      Cldr.Message
    ]
end
