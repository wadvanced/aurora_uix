defmodule Aurora.Uix.Integration.CrudTest do
  @moduledoc "The CRUD dispatcher over both backend modules."
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash.CrudSpec, as: AshCrudSpec
  alias Aurora.Uix.Integration.Connector
  alias Aurora.Uix.Integration.Crud
  alias Aurora.Uix.Integration.Ctx.Crud, as: CtxCrud
  alias Aurora.Uix.Integration.Ctx.CrudSpec, as: CtxCrudSpec

  test "the CRUD dispatcher picks the backend module" do
    socket = %{assigns: %{current_user: %{id: 1}}}
    assert Crud.apply_socket_opts(nil, socket) == []

    ash = %Connector{type: :ash, crud_spec: %AshCrudSpec{actor_assign: :current_user}}
    assert Crud.apply_socket_opts(ash, socket) == [actor: %{id: 1}]

    ctx = %Connector{type: :ctx, crud_spec: %CtxCrudSpec{function_spec: fn _ -> :ok end}}
    assert Crud.apply_socket_opts(ctx, socket) == []

    no_actor = %Connector{type: :ash, crud_spec: %AshCrudSpec{actor_assign: nil}}
    assert Crud.apply_socket_opts(no_actor, socket) == []

    spec = %CtxCrudSpec{function_spec: fn _ -> :ok end}
    assert CtxCrud.socket_opts(spec, socket) == []
    assert CtxCrud.socket_opts(spec, %{assigns: %{}}) == []
    assert CtxCrud.socket_opts(%CtxCrudSpec{}, %{assigns: %{whatever: :anything}}) == []
  end
end
