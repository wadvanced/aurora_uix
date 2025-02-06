defmodule Mix.Tasks.Test.Env do
  @shortdoc """
  Loads the test environment

  ## Examples
  ```shell
  ENV_MIX=test mix do test.env, any other command
  ```
  """

  @moduledoc """
  Enables the test environment.
  """

  use Mix.Task

  @doc """
  Enables the test environment
  """
  @spec run(list | nil) :: any
  def run(_args) do
    Code.require_file("test/env_loader.exs")
  end
end
