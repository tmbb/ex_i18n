defmodule I18n.Fixtures.ExampleModule do
  use I18n
  # Note that I don't need to require or import a I18n backend here.
  # I just use the I18n library, and once a backend is configured
  # it will automatically become aware of these messages
  # (even if the messages exists in a different application)

  def f() do
    # A simple static translation
    I18n.t("Hello world!")
  end

  def g(guest) do
    # A translation with a variable.
    # This translation contains a context, possibly to disambiguate it
    # from a similar string which should be translated in a different way.
    # I18n will keep equal strings with different contexts separate.
    I18n.t("Hello {guest}!", context: "a message", variables: [guest: guest])
  end

  def h(user, nr_photos) do
    # A more complex translation with two variables and plural forms.
    # It also defines a different domain.
    I18n.t(
      """
      {nr_photos, plural,
        =0 {{user} didn't take any photos.}
        =1 {{user} took one photo.}
        other {{user} took # photos.}}\
      """,
      domain: "photos",
      variables: [
        user: user,
        nr_photos: nr_photos
      ]
    )
  end

  def i() do
    # An example message to show pseudolocalization for HTML
    I18n.t("This message contains <strong>html tags</strong> &amp; nasty stuff...")
  end

  def j() do
    I18n.t("message not extracted")
  end
end
