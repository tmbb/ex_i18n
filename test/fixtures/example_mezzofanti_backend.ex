defmodule ExampleMezzofantiBackend do
  use Mezzofanti.Backends.GettextBackend,
    otp_app: :mezzofanti,
    priv: "priv/mezzofanti"
end
