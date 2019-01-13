defmodule Mezzofanti.Worker do
  @moduledoc false

  def translate(string, opts) do
    locale = Keyword.get(opts, :locale, "en")

    string <> " (as rendered in the '#{locale}' locale)"
  end
end

# message =
#   translate("At {time,time} on {date,date}, there was {what} on planet {planet,number,integer}.",
#     domain: "war_of_the_starse",
#     context: "A famous event that transpired near Alderaan",
#     variables: [
#       time: Time.utc_now(),
#       date: Date.utc_today(),
#       what: "a great disturbance in the force",
#       planet: 7
#     ]
#   )
