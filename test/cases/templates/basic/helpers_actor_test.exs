defmodule Aurora.Uix.Templates.Basic.HelpersActorTest do
  @moduledoc """
  Unit tests for `Aurora.Uix.Templates.Basic.Helpers.backend_socket_opts/2`.

  Verifies that the handler-facing wrapper accepts both a full LiveView socket and a
  bare assigns map, that it returns `[]` when no connector is supplied, and that the
  Ash actor flows through transparently.
  """
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash.CrudSpec
  alias Aurora.Uix.Integration.Connector
  alias Aurora.Uix.Templates.Basic.Helpers

  describe "backend_socket_opts/2" do
    test "returns [] when connector is nil regardless of socket/assigns shape" do
      assert Helpers.backend_socket_opts(%{assigns: %{current_user: %{id: 1}}}, nil) == []
      assert Helpers.backend_socket_opts(%{current_user: %{id: 1}}, nil) == []
    end

    test "accepts a socket-shaped map (with :assigns key)" do
      connector = ash_connector_with_actor(:current_user)
      actor = %{id: 1}
      socket = %{assigns: %{current_user: actor}}

      assert Helpers.backend_socket_opts(socket, connector) == [actor: actor]
    end

    test "accepts a bare assigns map (wraps it internally)" do
      connector = ash_connector_with_actor(:current_user)
      actor = %{id: 1}

      assert Helpers.backend_socket_opts(%{current_user: actor}, connector) == [actor: actor]
    end

    test "returns [] when actor_assign is unset on the spec" do
      connector = %Connector{type: :ash, crud_spec: %CrudSpec{actor_assign: nil}}

      assert Helpers.backend_socket_opts(%{assigns: %{current_user: %{id: 1}}}, connector) == []
    end
  end

  @spec ash_connector_with_actor(atom() | nil) :: Connector.t()
  defp ash_connector_with_actor(assign_key) do
    %Connector{type: :ash, crud_spec: %CrudSpec{actor_assign: assign_key}}
  end
end
