defmodule Aurora.Uix.Integration.Ctx.CrudTest do
  @moduledoc """
  Unit tests for the Ctx backend's `socket_opts/2` callback.

  The Ctx backend deliberately ignores socket-derived options — Ecto contexts have no
  concept of an Ash actor. This test pins the no-op behaviour so a future change
  trying to leak an actor concept into ctx fails loudly.
  """
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ctx.Crud, as: CtxCrud
  alias Aurora.Uix.Integration.Ctx.CrudSpec

  describe "socket_opts/2" do
    test "returns [] for any spec / socket combination" do
      spec = %CrudSpec{function_spec: fn _ -> :ok end}
      assert CtxCrud.socket_opts(spec, %{assigns: %{current_user: %{id: 1}}}) == []
      assert CtxCrud.socket_opts(spec, %{assigns: %{}}) == []
      assert CtxCrud.socket_opts(%CrudSpec{}, %{assigns: %{whatever: :anything}}) == []
    end
  end
end
