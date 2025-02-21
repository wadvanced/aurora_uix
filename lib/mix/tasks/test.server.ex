defmodule Mix.Tasks.Test.Server do
  @shortdoc """
  Starts a phoenix server.

  ## Examples
  ```shell
  mix test.server
  ```
  """

  @moduledoc """
  Starts a phoenix server in the test environment.

  This task launches a Phoenix server, opens an IEx console,
  and serves the application for browser visualization.
  The Phoenix framework is only available in the test environment.

  ## Usage

  ```shell
  ~$ mix test.server

  09:08:12.727 [info] Running AuroraUixTestWeb.Endpoint with Bandit 1.6.7 at 0.0.0.0:4001 (http)

  09:08:12.729 [info] Access AuroraUixTestWeb.Endpoint at http://localhost:4001
  Code.require_file("test/cases_live/crud_test.exs")
  iex(1)>
  ```
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
