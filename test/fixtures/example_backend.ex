defmodule ExampleI18nBackend do
  use I18n.Backends.GettextBackend,
    otp_app: :ex_i18n,
    priv: "priv/i18n"
end
