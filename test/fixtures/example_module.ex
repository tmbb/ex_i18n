defmodule Mezzofanti.Fixtures.ExampleModule do
  use Mezzofanti
  # Not that I don't need to require or impor a Mezzofanti backend here.
  # I just use the Mezzofanti library, and once a backend is configured
  # it will automatically become aware of these messages
  # (even if the messages exist in a different application)

  def f() do
    # A simple static translation
    translate("Hello world!")
  end

  def g(guest) do
    # A translation with a variable.
    # This translation contains a context, possibly to disambiguate it
    # from a similar string which should be translated in a different way.
    # Mezzofanti will keep equal strings with different contexts separate.
    translate("Hello {guest}!", context: "a message", variables: [guest: guest])
  end

  def h(user, nr_photos) do
    # A more complex translation with two variables and plural forms.
    # It also defines a different domain.
    translate("""
    {nr_photos, plural,
      =0 {{user} didn't take any photos.}
      =1 {{user} took one photo.}
      other {{user} took # photos.}}\
    """,
      domain: "photos",
      variables: [
        user: user,
        nr_photos: nr_photos
      ])
  end

  def i() do
    # An example message to show pseudolocalization for HTML
    translate("This message contains <strong>html tags</strong> &amp; nasty stuff...")
  end
end
