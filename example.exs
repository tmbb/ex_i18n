@external_resource "priv/mezzofanti/default.pot"
@external_resource "priv/mezzofanti/domain2.pot"
@external_resource "priv/mezzofanti/fr/LC_MESSAGES/default.po"
@external_resource "priv/mezzofanti/fr/LC_MESSAGES/domain2.po"
def(
  translate_from_hash(
    <<4, 146, 119, 153, 60, 106, 136, 225, 82, 229, 208, 61, 189, 89, 48, 154, 190, 134, 106,
      126>>,
    "fr",
    variables
  )
) do
  Cldr.Message.format_list([literal: "méssage numero deux"], variables, locale: "fr")
end

def(
  translate_from_hash(
    <<12, 119, 79, 42, 19, 139, 125, 110, 119, 17, 223, 235, 100, 236, 248, 186, 132, 58, 109,
      157>>,
    "fr",
    variables
  )
) do
  Cldr.Message.format_list([literal: "méssage numero un"], variables, locale: "fr")
end

def(
  translate_from_hash(
    <<81, 4, 58, 194, 129, 252, 113, 202, 128, 176, 129, 40, 142, 50, 71, 161, 112, 218, 60, 77>>,
    "fr",
    variables
  )
) do
  Cldr.Message.format_list([literal: "méssage numero trois"], variables, locale: "fr")
end

def(
  translate_from_hash(
    <<4, 146, 119, 153, 60, 106, 136, 225, 82, 229, 208, 61, 189, 89, 48, 154, 190, 134, 106,
      126>>,
    "pseudo",
    variables
  )
) do
  translated = Cldr.Message.format_list([literal: "message #2"], variables, [])
  text = to_string(translated)
  Pseudolocalization.pseudolocalize(text)
end

def(
  translate_from_hash(
    <<12, 119, 79, 42, 19, 139, 125, 110, 119, 17, 223, 235, 100, 236, 248, 186, 132, 58, 109,
      157>>,
    "pseudo",
    variables
  )
) do
  translated = Cldr.Message.format_list([literal: "message #1"], variables, [])
  text = to_string(translated)
  Pseudolocalization.pseudolocalize(text)
end

def(
  translate_from_hash(
    <<81, 4, 58, 194, 129, 252, 113, 202, 128, 176, 129, 40, 142, 50, 71, 161, 112, 218, 60, 77>>,
    "pseudo",
    variables
  )
) do
  translated = Cldr.Message.format_list([literal: "message #3"], variables, [])
  text = to_string(translated)
  Pseudolocalization.pseudolocalize(text)
end

def(
  translate_from_hash(
    <<4, 146, 119, 153, 60, 106, 136, 225, 82, 229, 208, 61, 189, 89, 48, 154, 190, 134, 106,
      126>>,
    _,
    variables
  )
) do
  Cldr.Message.format_list([literal: "message #2"], variables, [])
end

def(
  translate_from_hash(
    <<12, 119, 79, 42, 19, 139, 125, 110, 119, 17, 223, 235, 100, 236, 248, 186, 132, 58, 109,
      157>>,
    _,
    variables
  )
) do
  Cldr.Message.format_list([literal: "message #1"], variables, [])
end

def(
  translate_from_hash(
    <<81, 4, 58, 194, 129, 252, 113, 202, 128, 176, 129, 40, 142, 50, 71, 161, 112, 218, 60, 77>>,
    _,
    variables
  )
) do
  Cldr.Message.format_list([literal: "message #3"], variables, [])
end