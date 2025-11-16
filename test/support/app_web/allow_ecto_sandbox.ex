defmodule Aurora.UixWeb.Test.AllowEctoSandbox do
  @moduledoc """
  Provides Ecto sandbox allowance for LiveView tests.

  This module implements a `on_mount/4` hook that enables Ecto sandbox access
  for LiveView components during testing. It ensures database operations in
  LiveView tests are properly isolated and cleaned up.

  ## Usage

  Add this module to your router:
  ```elixir
    live_session :default, on_mount: MyApp.Hooks.AllowEctoSandbox do
        # ...
    end
  ```
  ## Configuration

  Requires the `:sandbox` configuration to be set in your test environment (config/test.exs):

      config :aurora_uix, :sandbox, Aurora.Uix.Repo
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias Phoenix.Ecto.SQL.Sandbox
  alias Phoenix.LiveView.Socket

  @doc """
  Mount hook for enabling Ecto sandbox in LiveView tests.

  This function is called when a LiveView mounts and ensures the Ecto sandbox
  is properly configured for the current socket connection.

  ## Parameters

    - `:default` - The mount type identifier
    - `_params` - Route parameters (unused)
    - `_session` - Session data (unused)
    - `socket` - The Phoenix LiveView socket

  ## Returns

    - `{:cont, socket}` - Continues the mount process with the updated socket

  """
  @spec on_mount(atom(), map(), map(), Socket.t()) ::
          {:cont, Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    allow_ecto_sandbox(socket)
    {:cont, socket}
  end

  @spec allow_ecto_sandbox(Socket.t()) :: :ok
  defp allow_ecto_sandbox(socket) do
    %{assigns: %{phoenix_ecto_sandbox: metadata}} =
      assign_new(socket, :phoenix_ecto_sandbox, fn ->
        if connected?(socket), do: get_connect_info(socket, :user_agent)
      end)

    Sandbox.allow(metadata, Application.get_env(:aurora_uix, :sandbox))
  end
end
