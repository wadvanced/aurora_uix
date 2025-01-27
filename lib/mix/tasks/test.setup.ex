defmodule Mix.Tasks.Test.Setup do
  @shortdoc """
  Run all the dependencies for testing under phoenix / ecto.

  ## Examples
  ```shell
  ENV_MIX=test mix do test.setup, ecto.migrate
  ```
  """

  @moduledoc """
  Compiles and start required dependencies for testing.
  """

  use Mix.Task

  @doc """
  Compiles (and run) test/dependencies_start.exs, that load phoenix and ecto apps and start their corresponding GenServers.
  """
  @spec run(list | nil) :: any
  def run(_args), do: Code.require_file("test/dependencies_start.exs")
end
