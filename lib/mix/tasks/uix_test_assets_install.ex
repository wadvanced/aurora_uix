defmodule Mix.Tasks.Uix.Test.Assets.Install do
  @shortdoc "Installs Tailwind and Esbuild dependencies in the test environment."

  @moduledoc """
  Installs frontend asset dependencies for the test environment in Aurora UIX projects.

  This task runs the installation steps for Tailwind and Esbuild in the test environment.

  ## Key Features
  - Installs Tailwind and Esbuild dependencies for testing.
  - Ensures all required assets are available for test runs and CI.

  ## Example
  Install all asset dependencies for testing:
  ```shell
  mix uix.test.assets.install
  ```
  """

  use Mix.Task

  @doc """
  Installs asset dependencies for the test environment.

  ## Parameters
  - `args` (list(binary())) - Arguments for the task (not used).

  ## Returns
  - `:ok` - Always returns :ok after running all install tasks.

  ## Example
      iex> Mix.Tasks.Uix.Test.Assets.Install.run([])
      :ok
  """
  @spec run(list(binary())) :: :ok
  def run(_args) do
    Mix.Task.run("uix.test.task", ["tailwind.install", "--if-missing", "silent"])
    Mix.Task.reenable("uix.test.task")
    Mix.Task.run("uix.test.task", ["esbuild.install", "--if-missing", "silent"])
  end
end
