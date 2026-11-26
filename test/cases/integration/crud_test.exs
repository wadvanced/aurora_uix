defmodule Aurora.Uix.Integration.CrudTest do
  @moduledoc "The CRUD dispatcher over both backend modules."
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash.ContextParserDefaults, as: AshParserDefaults
  alias Aurora.Uix.Integration.Ash.CrudSpec, as: AshCrudSpec
  alias Aurora.Uix.Integration.Connector
  alias Aurora.Uix.Integration.ContextParserDefaults
  alias Aurora.Uix.Integration.Crud
  alias Aurora.Uix.Integration.Ctx.ContextParserDefaults, as: CtxParserDefaults
  alias Aurora.Uix.Integration.Ctx.Crud, as: CtxCrud
  alias Aurora.Uix.Integration.Ctx.CrudSpec, as: CtxCrudSpec
  alias Aurora.Uix.Integration.Ctx.FieldsParser, as: CtxFieldsParser
  alias Aurora.Uix.Layout.Helpers

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

  # test/config/test.exs registers an :extra_ctx backend under each key, the way a host
  # adds a custom backend.
  test "a backend registered in the config is added to the built-in ones" do
    socket = %{assigns: %{current_user: %{id: 1}}}
    spec = %CtxCrudSpec{function_spec: fn _ -> :ok end}
    assert Crud.apply_socket_opts(%Connector{type: :extra_ctx, crud_spec: spec}, socket) == []

    ash = %Connector{type: :ash, crud_spec: %AshCrudSpec{actor_assign: :current_user}}
    assert Crud.apply_socket_opts(ash, socket) == [actor: %{id: 1}]

    assert ContextParserDefaults.backend_opts_schema(:extra_ctx) ==
             CtxParserDefaults.backend_opts_schema()

    assert ContextParserDefaults.backend_opts_schema(:ash) ==
             AshParserDefaults.backend_opts_schema()

    assert ContextParserDefaults.backend_opts_schema(:ctx) ==
             CtxParserDefaults.backend_opts_schema()

    assert Helpers.get_fields_parser_module(:extra_ctx) == CtxFieldsParser
    assert Helpers.get_fields_parser_module(:ctx) == CtxFieldsParser
  end
end
