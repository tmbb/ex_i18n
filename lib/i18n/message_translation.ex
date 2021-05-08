defmodule I18n.MessageTranslation do

  @derive Jason.Encoder

  defstruct text: "",
            comments: "",
            locale: "",
            reviewed: false

  def new(opts) do
    struct(__MODULE__, opts)
  end

  def from_map(map) do
    new(map)
  end
end