defmodule Mix.Tasks.Test.Env do
  @shortdoc """
  Sets up the test environment by loading the necessary files.
  """

  @moduledoc """
  Configures the test environment by loading the required files.

  ## Usage
    Run any command that requires the test environment using:

    ```shell
    ~$ ENV_MIX=test mix do test.env, <command>
    ```

  ## Examples
    ```shell
    ~$ ENV_MIX=test mix do test.env, tailwind aurora_uix
    Rebuilding...

    Done in 129ms.
    ```
  """

  use Mix.Task

  @doc """
  Loads the test environment files.
  """
  @spec run(list | nil) :: any
  def run(_args) do
    Code.require_file("test/env_loader.exs")
  end
end
