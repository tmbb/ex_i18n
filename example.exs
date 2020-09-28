@external_resource "/Users/kip/Development/mezzofanti/_build/test/lib/mezzofanti/priv/mezzofanti/default.pot"
@external_resource "/Users/kip/Development/mezzofanti/_build/test/lib/mezzofanti/priv/mezzofanti/photos.pot"
@external_resource "/Users/kip/Development/mezzofanti/_build/test/lib/mezzofanti/priv/mezzofanti/pt-PT/LC_MESSAGES/default.po"
@external_resource "/Users/kip/Development/mezzofanti/_build/test/lib/mezzofanti/priv/mezzofanti/pt-PT/LC_MESSAGES/photos.po"
(
  def(
    translate_from_hash(
      message_hash,
      %Cldr.LanguageTag{extensions: %{"m" => ["pseudo"]}} = locale,
      variables,
      translation
    )
  ) do
    new_locale = %{locale | extensions: %{}}
    translated = translate_from_hash(message_hash, new_locale, variables, translation)
    text = to_string(translated)
    Mezzofanti.Pseudolocalization.TextPseudolocalization.pseudolocalize(text)
  end

  def(
    translate_from_hash(
      message_hash,
      %Cldr.LanguageTag{extensions: %{"m" => ["pseudoht"]}} = locale,
      variables,
      translation
    )
  ) do
    new_locale = %{locale | extensions: %{}}
    translated = translate_from_hash(message_hash, new_locale, variables, translation)
    text = to_string(translated)
    Mezzofanti.Pseudolocalization.HtmlPseudolocalization.pseudolocalize(text)
  end
)

def(
  translate_from_hash(
    <<169, 44, 181, 253, 151, 18, 8, 13, 7, 48, 160, 103, 65, 231, 215, 166, 7, 189, 51, 241>>,
    %Cldr.LanguageTag{cldr_locale_name: "pt-PT"} = _locale,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list([literal: "Olá ", named_arg: "guest", literal: "!"], variables,
    locale: "pt-PT"
  )
end

def(
  translate_from_hash(
    <<61, 62, 53, 189, 235, 34, 215, 35, 123, 170, 151, 71, 60, 160, 109, 93, 202, 127, 56, 250>>,
    %Cldr.LanguageTag{cldr_locale_name: "pt-PT"} = _locale,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list(
    [literal: "Esta mensagem contém <strong>tags de HTML</strong> &amp; e coisas chatas..."],
    variables,
    locale: "pt-PT"
  )
end

def(
  translate_from_hash(
    <<69, 123, 27, 245, 244, 99, 106, 151, 218, 122, 128, 16, 209, 236, 136, 229, 104, 255, 213,
      203>>,
    %Cldr.LanguageTag{cldr_locale_name: "pt-PT"} = _locale,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list([literal: "Olá a todos!"], variables, locale: "pt-PT")
end

def(
  translate_from_hash(
    <<4, 3, 99, 206, 215, 146, 169, 53, 97, 145, 198, 166, 100, 66, 154, 57, 26, 146, 34, 242>>,
    %Cldr.LanguageTag{cldr_locale_name: "pt-PT"} = _locale,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list(
    [
      {:plural, {:named_arg, "nr_photos"}, {:offset, 0},
       %{
         0 => [named_arg: "user", literal: " não tirou fotografias nenhumas."],
         1 => [named_arg: "user", literal: " tirou 1 fotografia."],
         :other => [
           {:named_arg, "user"},
           {:literal, " tirou "},
           :value,
           {:literal, " fotografias."}
         ]
       }}
    ],
    variables,
    locale: "pt-PT"
  )
end

def(
  translate_from_hash(
    <<61, 62, 53, 189, 235, 34, 215, 35, 123, 170, 151, 71, 60, 160, 109, 93, 202, 127, 56, 250>>,
    _,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list(
    [literal: "This message contains <strong>html tags</strong> &amp; nasty stuff..."],
    variables,
    []
  )
end

def(
  translate_from_hash(
    <<169, 44, 181, 253, 151, 18, 8, 13, 7, 48, 160, 103, 65, 231, 215, 166, 7, 189, 51, 241>>,
    _,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list([literal: "Hello ", named_arg: "guest", literal: "!"], variables, [])
end

def(
  translate_from_hash(
    <<69, 123, 27, 245, 244, 99, 106, 151, 218, 122, 128, 16, 209, 236, 136, 229, 104, 255, 213,
      203>>,
    _,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list([literal: "Hello world!"], variables, [])
end

def(
  translate_from_hash(
    <<4, 3, 99, 206, 215, 146, 169, 53, 97, 145, 198, 166, 100, 66, 154, 57, 26, 146, 34, 242>>,
    _,
    variables,
    _translation
  )
) do
  Cldr.Message.format_list(
    [
      {:plural, {:named_arg, "nr_photos"}, {:offset, 0},
       %{
         0 => [named_arg: "user", literal: " didn't take any photos."],
         1 => [named_arg: "user", literal: " took one photo."],
         :other => [{:named_arg, "user"}, {:literal, " took "}, :value, {:literal, " photos."}]
       }}
    ],
    variables,
    []
  )
end

(
  def(
    translate_from_hash(
      _,
      %Cldr.LanguageTag{extensions: %{"m" => ["pseudoht"]}},
      variables,
      message
    )
  ) do
    Mezzofanti.Backends.GettextBackend.log_message_not_extracted(message)
    parsed = Message.parse_message!(message.string)
    localized = Cldr.Message.format_list(parsed, variables, [])
    text = to_string(localized)
    Mezzofanti.Pseudolocalization.HtmlPseudolocalization.pseudolocalize(text)
  end

  def(
    translate_from_hash(
      _,
      %Cldr.LanguageTag{extensions: %{"m" => ["pseudo"]}},
      variables,
      message
    )
  ) do
    Mezzofanti.Backends.GettextBackend.log_message_not_extracted(message)
    parsed = Message.parse_message!(message.string)
    localized = Cldr.Message.format_list(parsed, variables, [])
    text = to_string(localized)
    Mezzofanti.Pseudolocalization.TextPseudolocalization.pseudolocalize(text)
  end

  def(translate_from_hash(_, _, variables, message)) do
    Mezzofanti.Backends.GettextBackend.log_message_not_extracted(message)
    parsed = Message.parse_message!(message.string)
    localized = Cldr.Message.format_list(parsed, variables, [])
    localized
  end
)