defmodule Mezzofanti.Fixtures.ExampleModule do
  use Mezzofanti

  def f() do
    translate("Hello world!")
  end

  def g(guest) do
    translate("Hello {guest}!", context: "a message", variables: [guest: guest])
  end

  def h(user, nr_photos) do
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
end
