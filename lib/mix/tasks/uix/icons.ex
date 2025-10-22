defmodule Mix.Tasks.Auix.Icons do
  @shortdoc "Generates CSS for heroicons"

  @moduledoc """
    Reads hero icons from deps/heroicons and creates a assets/css/icons.css.
  """

  use Mix.Task

  @doc """
  Runs the icons generator.
  """
  @spec run(keyword()) :: any()
  def run(_) do
    Code.require_file("priv/icon_generator.exs")
  end
end
