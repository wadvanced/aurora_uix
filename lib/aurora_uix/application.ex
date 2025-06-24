defmodule Aurora.Uix.Application do
  @moduledoc """
  Application entry point for Aurora UIX.

  Starts the supervision tree, including the CounterAgent process.

  ## Key Features
  - Defines the supervision tree for internal processes required by Aurora UIX.
  - Not intended for direct use by end users or application developers.

  ## Key Constraints
  - This module should only be started by the BEAM as part of the library's OTP application lifecycle.
  - Supervision tree is limited to internal Aurora UIX processes.
  """

  use Application

  alias Aurora.Uix.CounterAgent

  @doc """
  Starts the Aurora UIX supervision tree.

  This function is invoked automatically by the BEAM when the library is included as a dependency in an OTP application. It is not intended to be called directly by users.

  ## Parameters
  - `_type` (term()) - The type of start (ignored).
  - `_args` (term()) - The start arguments (ignored).

  ## Returns
  `{:ok, pid()}` | `{:error, term()}` - On success, returns a tuple with the supervisor PID. On failure, returns a tuple with the error reason.
  """
  @spec start(term(), term()) :: {:ok, pid()} | {:error, term()}
  @impl true
  def start(_type, _args) do
    children = [
      CounterAgent
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
