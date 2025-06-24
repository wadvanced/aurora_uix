defmodule Aurora.Uix.Test.Web.ConnCase do
  @moduledoc """
  Test case to be used by tests that require setting up a connection.

  ## Key Features
  - Uses Phoenix.ConnTest and related helpers for connection tests.
  - Enables SQL sandbox for database tests.
  - Supports async database tests for PostgreSQL.
  """

  use ExUnit.CaseTemplate

  alias Aurora.Uix.Test.Web

  using do
    quote do
      # The default endpoint for testing
      @endpoint Web.Endpoint

      use Aurora.Uix.Test.Web, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn, except: [assign: 3]
      import Phoenix.ConnTest, except: [put_flash: 3]
      import Web.ConnCase
    end
  end

  setup tags do
    Web.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
