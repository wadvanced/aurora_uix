defmodule Mix.Tasks.Uix.Test.Setup do
  @shortdoc "Sets up the Aurora UIX test environment."

  @moduledoc """
  Prepares the Aurora UIX test environment, including database setup and asset installation.

  This task runs migrations, installs asset dependencies, and builds assets for the test environment.

  ## Key Features
  - Runs all database migrations for testing.
  - Installs and builds all frontend assets for the test environment.
  - Ensures the test environment is ready for development or CI.

  ## Example
  Prepare the test environment:
  ```shell
  mix uix.test.setup
  ```
  """

  use Mix.Task

  @doc """
  Sets up the test environment by running migrations and preparing assets.

  ## Parameters
  - `args` (list(binary())) - Arguments for the task (not used).

  ## Returns
  - `:ok` - Always returns :ok after running all setup steps.

  ## Example
      iex> Mix.Tasks.Uix.Test.Setup.run([])
      :ok
  """
  @spec run(list(binary()) | nil) :: term()
  def run(_args), do: Code.require_file("test/start_test_app.exs")
end
