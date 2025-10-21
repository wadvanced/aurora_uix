defmodule Mix.Tasks.Auix.Icons do
  use Mix.Task

  @shortdoc "Generates CSS for heroicons"
  def run(_) do
    Code.require_file("priv/icon_generator.exs")
  end
end
