defmodule Mezzofanti.Compiler do
  @moduledoc false

  @doc """
  Runs the given function with the given compiler options
  """
  def with_compiler_options(opts, fun) do
    old_compiler_options = Code.compiler_options()

    try do
      # Set the new compiler options
      Code.compiler_options(opts)
      fun.()
      # Reset the old compiler options
      Code.compiler_options(old_compiler_options)
    rescue
      e ->
        # reset the old compiler options
        Code.compiler_options(old_compiler_options)
        # Raise whatever exception was supposed to have been raised,
        # but after making sure we're using the old compiler options
        raise e
    end
  end
end
