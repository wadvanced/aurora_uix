defmodule Mix.Tasks.Uix.Test.Assets.Install do
  @shortdoc "Installs Tailwind and Esbuild in the test environment if missing."

  @moduledoc """
  Ensures Tailwind and Esbuild are installed within the test environment.

  This task first loads `test.env`, then installs Tailwind and Esbuild if needed.
  Equivalent to:

    ```shell
      mix do test.env, tailwind.install --if-missing, esbuild.install --if-missing
    ```

  ## Usage
    ```shell
    ~$ mix uix.test.assets.install
    13:22:58.414 [debug] Downloading tailwind from https://github.com/tailwindlabs/tailwindcss/releases/download/v3.4.6/tailwindcss-macos-arm64

    13:23:04.998 [debug] Downloading esbuild from https://registry.npmjs.org/@esbuild/darwin-arm64/0.23.0
    ```

  """

  use Mix.Task

  @doc """
  Installs missing frontend assets.
  """
  @spec run(list | nil) :: any
  def run(_args) do
    Mix.Task.run("uix.test.task", ["tailwind.install", "--if-missing", "silent"])
    Mix.Task.reenable("uix.test.task")
    Mix.Task.run("uix.test.task", ["esbuild.install", "--if-missing", "silent"])
  end
end
