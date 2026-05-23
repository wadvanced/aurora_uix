defmodule Aurora.Uix.Integration.CrudTest do
  @moduledoc """
  Unit tests for the polymorphic `apply_socket_opts/2` dispatcher on
  `Aurora.Uix.Integration.Crud`.

  Verifies that the dispatcher routes to the backend's `socket_opts/2` callback
  according to `connector.type`, returns `[]` for a `nil` connector, and never raises
  for an unset assign.
  """
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash.CrudSpec, as: AshCrudSpec
  alias Aurora.Uix.Integration.Connector
  alias Aurora.Uix.Integration.Crud
  alias Aurora.Uix.Integration.Ctx.CrudSpec, as: CtxCrudSpec

  describe "apply_socket_opts/2" do
    test "returns [] for nil connector" do
      assert Crud.apply_socket_opts(nil, %{assigns: %{current_user: %{id: 1}}}) == []
    end

    test "dispatches to Ash backend when type is :ash" do
      connector = %Connector{
        type: :ash,
        crud_spec: %AshCrudSpec{actor_assign: :current_user}
      }

      actor = %{id: 1}
      socket = %{assigns: %{current_user: actor}}

      assert Crud.apply_socket_opts(connector, socket) == [actor: actor]
    end

    test "dispatches to Ctx backend when type is :ctx (always returns [])" do
      connector = %Connector{
        type: :ctx,
        crud_spec: %CtxCrudSpec{function_spec: fn _ -> :ok end}
      }

      assert Crud.apply_socket_opts(connector, %{assigns: %{current_user: %{id: 1}}}) == []
    end

    test "returns [] for Ash connector without actor_assign" do
      connector = %Connector{
        type: :ash,
        crud_spec: %AshCrudSpec{actor_assign: nil}
      }

      assert Crud.apply_socket_opts(connector, %{assigns: %{current_user: %{id: 1}}}) == []
    end
  end
end
