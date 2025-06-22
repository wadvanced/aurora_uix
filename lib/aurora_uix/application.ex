defmodule Aurora.Uix.Application do
  @moduledoc """
  Internal OTP application module for Aurora UIX.

  Defines the supervision tree for internal processes. Not intended for direct use.
  """

  use Application

  alias Aurora.Uix.CounterAgent

  @doc """
  Callback for starting the Aurora UIX supervision tree (internal use only).

  This function is invoked automatically by the BEAM when the library is included as a dependency in an OTP application. It is not intended to be called directly by users.

  ## Parameters
  - `_type` (term()) - The type of start (ignored).
  - `_args` (term()) - The start arguments (ignored).

  ## Returns
  - `{:ok, pid()}` - On success, returns a tuple with the supervisor PID.
  - `{:error, term()}` - On failure, returns a tuple with the error reason.
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
