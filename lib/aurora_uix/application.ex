defmodule Aurora.Uix.Application do
  @moduledoc """
  Application entry point for Aurora UIX.

  Starts the supervision tree, including the CounterAgent process.
  """

  use Application

  alias Aurora.Uix.CounterAgent

  @doc """
  Starts the Aurora UIX application supervision tree.

  ## Parameters
  - _type (term()) - The type of start (ignored)
  - _args (term()) - The start arguments (ignored)

  ## Returns
  - {:ok, pid()} on success
  - {:error, reason} on failure
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
