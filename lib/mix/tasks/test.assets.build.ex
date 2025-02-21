defmodule Mix.Tasks.Test.Assets.Build do
  @shortdoc "Builds Tailwind and Esbuild assets in the test environment."

  @moduledoc """
  Compiles frontend assets for the test environment.

  Runs Tailwind, Esbuild, and Phoenix digest tasks after setting up `test.env`.

  Equivalent to:
    ```shell
      mix do test.env, tailwind aurora_uix, esbuild aurora_uix, phx.digest test/_priv/static, phx.digest.clean -o test/_priv/static --all
    ```

  ## Usage
    ```shell
    ~$ mix test.assets.build
    Rebuilding...

    Done in 120ms.

    ../_priv/static/assets/app.js  260.1kb

    ⚡ Done in 10ms
    Check your digested files at "test/_priv/static"
    Clean complete for "test/_priv/static"

    ```
  """

  use Mix.Task

  @doc """
  Sets up the test environment and compiles assets.
  """
  @spec run(list | nil) :: any
  def run(_args) do
    Mix.Task.run("test.env")
    Mix.Task.reenable("tailwind")
    Mix.Task.run("tailwind", ["aurora_uix"])

    Mix.Task.reenable("esbuild")
    Mix.Task.run("esbuild", ["aurora_uix"])

    Mix.Task.reenable("phx.digest")
    Mix.Task.run("phx.digest", ["test/_priv/static"])

    Mix.Task.reenable("phx.digest.clean")
    Mix.Task.run("phx.digest.clean", ["-o", "test/_priv/static", "--all"])
  end
end
