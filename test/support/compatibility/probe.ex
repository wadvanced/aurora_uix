defmodule Aurora.UixWeb.Test.Compatibility.Probe do
  @moduledoc """
  Reports handler callbacks to the test process registered as `:auix_compat_probe`.

  ## Key Features
  - Sends `{:compat, name, self()}` so a test can assert which process ran a callback.

  ## Key Constraints
  - Reports nothing when no process is registered under `:auix_compat_probe`.
  """

  @doc """
  Sends `{:compat, name, self()}` to the process registered as `:auix_compat_probe`.

  ## Parameters
  - `name` (term()) - The callback name to report.

  ## Returns
  `:ok` - Whether or not a probe process is registered.
  """
  @spec report(term()) :: :ok
  def report(name) do
    case Process.whereis(:auix_compat_probe) do
      nil -> :ok
      probe -> send(probe, {:compat, name, self()})
    end

    :ok
  end
end
