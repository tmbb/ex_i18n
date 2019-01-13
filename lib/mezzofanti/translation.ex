defmodule Mezzofanti.Translation do
  @moduledoc false

  @type t() :: %__MODULE__{}

  defstruct string: nil,
            file: nil,
            line: nil,
            module: nil,
            comment: nil,
            domain: nil,
            flag: nil

  def new(opts) do
    struct(__MODULE__, opts)
  end
end
