defmodule Mix.Tasks.Uix.Test.Task do
  @shortdoc "Runs a Mix task in the Aurora UIX test environment."

  @moduledoc """
  Runs a specified Mix task in the Aurora UIX test environment.

  This task is used internally by other test Mix tasks to execute commands in a controlled test context.

  ## Key Features
  - Runs any Mix task with arguments in the test environment.
  - Used as a utility for asset and setup tasks.
  - Returns the exit code and output of the executed task.

  ## Example
  Run a custom Mix task in the test environment:
  ```shell
  mix uix.test.task phx.digest test/_priv/static silent
  ```
  """

  use Mix.Task

  @doc """
  Runs the given Mix task with arguments in the test environment.

  ## Parameters
  - `args` (list(binary())) - The Mix task and its arguments to run.

  ## Returns
  - `{integer(), binary()}` - The exit code and output of the executed task.

  ## Example
      iex> Mix.Tasks.Uix.Test.Task.run(["phx.digest", "test/_priv/static", "silent"])
      {0, "...output..."}
  """
  @spec run(list(binary())) :: term()
  def run(args) do
    mix_cmd =
      case :os.type() do
        {:win32, _} -> "mix.bat"
        _ -> "mix"
      end

    {silent, task_args} = Enum.split_with(args, &(&1 == "silent"))

    into = if silent == [], do: IO.stream(:stdio, :line), else: ""

    mix_tasks = ["do", "uix.test.setup,"] ++ task_args

    running = Enum.join(task_args, " ")
    IO.puts("Running mix task `#{running}`")

    System.cmd(mix_cmd, mix_tasks,
      env: [{"MIX_ENV", "test"}],
      into: into
    )
  end
end
