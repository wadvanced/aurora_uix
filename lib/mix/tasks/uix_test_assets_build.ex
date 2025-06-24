defmodule Mix.Tasks.Uix.Test.Assets.Build do
  @shortdoc "Builds Tailwind and Esbuild assets in the test environment."

  @moduledoc """
  Compiles frontend assets for the test environment.

  This task runs Tailwind, Esbuild, and Phoenix digest tasks after setting up the test environment.

  ## Key Features
  - Compiles Tailwind and Esbuild assets for testing.
  - Runs digest and clean tasks for static assets.
  - Ensures assets are up-to-date for test runs and CI.

  ## Example
  Build all assets for testing:
  ```shell
  mix uix.test.assets.build
  ```
  """

  use Mix.Task

  @doc """
  Sets up the test environment and compiles assets.

  ## Parameters
  - `args` (list(binary())) - Arguments for the task (not used).

  ## Returns
  - `:ok` - Always returns :ok after running all asset tasks.

  ## Example
      iex> Mix.Tasks.Uix.Test.Assets.Build.run([])
      :ok
  """
  @spec run(list(binary())) :: :ok
  def run(_args) do
    Mix.Task.run("uix.test.task", ["tailwind", "aurora_uix", "silent"])

    Mix.Task.reenable("uix.test.task")
    Mix.Task.run("uix.test.task", ["esbuild", "aurora_uix", "silent"])

    Mix.Task.reenable("uix.test.task")
    Mix.Task.run("uix.test.task", ["phx.digest", "test/_priv/static", "silent"])

    Mix.Task.reenable("uix.test.task")

    Mix.Task.run("uix.test.task", [
      "phx.digest.clean",
      "-o",
      "test/_priv/static",
      "--all",
      "silent"
    ])
  end
end
