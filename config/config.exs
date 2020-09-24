# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :mezzofanti,
  backend: ExampleMezzofantiBackend

config :ex_cldr,
  default_locale: "en",
  default_backend: ExampleCldrBackend,
  json_library: Jason
