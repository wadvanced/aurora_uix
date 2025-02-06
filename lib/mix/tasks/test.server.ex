defmodule Mix.Tasks.Test.Server do
  @shortdoc """
  Starts a phoenix server.

  ## Examples
  ```shell
  mix test.server
  ```
  """

  @moduledoc """
  Compiles and start required dependencies for testing.
  """

  use Mix.Task

  @doc """
  Compiles (and run) test/start_dependencies.exs, that load phoenix and ecto apps and start their corresponding GenServers.
  """
  @spec run(list | nil) :: any
  def run(_args) do
    with :ok <- Mix.Task.run("test.assets.install"),
         :ok <- Mix.Task.run("test.assets.build") do
      System.cmd("iex", ["--dot-iex", "test/start_server.exs", "-S", "mix"],
        env: [{"MIX_ENV", "test"}],
        into: IO.stream(:stdio, :line)
      )
    else
      error ->
        IO.puts("Failed with error: #{inspect(error)}")
    end
  end
end
