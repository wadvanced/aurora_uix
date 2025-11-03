defmodule Aurora.UixWeb.Test.ConnCase do
  @moduledoc """
  Test case to be used by tests that require setting up a connection.

  ## Key Features
  - Uses Phoenix.ConnTest and related helpers for connection tests.
  - Enables SQL sandbox for database tests.
  - Supports async database tests for PostgreSQL.
  """

  use ExUnit.CaseTemplate

  alias Aurora.UixWeb.Test, as: TestWeb
  alias Aurora.UixWeb.Test.ConnCase
  alias Aurora.UixWeb.Test.DataCase
  alias Aurora.UixWeb.Test.Endpoint, as: TestEndpoint

  using do
    quote do
      # The default endpoint for testing
      @endpoint TestEndpoint

      use TestWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn, except: [assign: 3]
      import Phoenix.ConnTest, except: [put_flash: 3]
      import ConnCase
    end
  end

  setup tags do
    DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
