defmodule Mix.Tasks.Uix.Test.Task do
  @moduledoc """
  A utility task to run Mix tasks in the `test` environment.

  This task simplifies running Mix tasks like `ecto.create`, `ecto.migrate`, or any custom task
  within the `test` environment without manually setting the `MIX_ENV` variable.

  ## Examples
    * Create the test database
    ```shell
    ~$ mix uix.test.task ecto.create
    ```
    * Run migrations in the test environment
    ```shell
    ~$ mix uix.test.task ecto.migrate
    ```
    * Run a custom task in the test environment
    ```shell
    ~$ mix uix.test.task my_custom_task
    ```
    * Run a task silently (suppress output)
    ```shell
    ~$ mix uix.test.task ecto.create silent
    ```
  """

  use Mix.Task

  @doc """
  Executes the specified Mix task in the test environment.

  ## Arguments
    - `args`: A list of arguments passed to the task. If there is a `silent` argument, the output is suppressed.
  """
  @spec run(list) :: any
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
