# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :mezzofanti,
  backend: Mezzofanti.ExampleBackend

config :ex_cldr,
  default_locale: "en",
  default_backend: ExampleBackend.Cldr,
  json_library: Jason
