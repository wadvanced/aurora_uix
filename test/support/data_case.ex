defmodule Aurora.Uix.Test.Web.DataCase do
  @moduledoc """
  Setup for tests requiring access to the application's data layer.

  ## Key Features
  - Provides helpers for data-related tests.
  - Enables SQL sandbox for database tests.
  - Supports async database tests for PostgreSQL.
  """

  use ExUnit.CaseTemplate

  alias Aurora.Uix.Test.Repo
  alias Aurora.Uix.Test.Web.DataCase
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Aurora.Uix.Test.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Aurora.Uix.Test.DataCase
    end
  end

  setup tags do
    DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.

  ## Parameters
  - `tags` (keyword()) - Test tags.

  ## Returns
  :ok - Always returns :ok after setting up the sandbox.
  """
  @spec setup_sandbox(keyword()) :: :ok
  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end
end
