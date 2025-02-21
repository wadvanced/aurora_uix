defmodule Mix.Tasks.Test.Setup do
  @shortdoc """
  Sets up the test environment and starts Phoenix, Ecto, and ExUnit.
  """

  @moduledoc """
  Prepares the test environment by compiling and starting required dependencies.

  This task ensures that Phoenix, Ecto, and ExUnit are properly loaded and their
  respective GenServers are started before running tests.
  """

  use Mix.Task

  @doc """
  Loads and initializes Phoenix, Ecto, and ExUnit,
  ensuring their applications and GenServers are ready for testing.
  """
  @spec run(list | nil) :: any
  def run(_args), do: Code.require_file("test/start_dependencies.exs")
end
