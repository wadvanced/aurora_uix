defmodule Aurora.Uix.Integration.Ash.CrudTest do
  @moduledoc """
  Unit tests for the Ash backend's `socket_opts/2` callback and actor threading.

  Verifies that the Ash CRUD backend correctly resolves `actor:` opts from a LiveView
  socket using `crud_spec.actor_assign`, and returns `[]` when the assign is unset,
  the assign holds `nil`, or `actor_assign` itself is `nil`.
  """
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash.Crud, as: AshCrud
  alias Aurora.Uix.Integration.Ash.CrudSpec

  describe "socket_opts/2" do
    test "returns [] when actor_assign is nil" do
      spec = %CrudSpec{actor_assign: nil}
      socket = %{assigns: %{current_user: %{id: 1}}}

      assert AshCrud.socket_opts(spec, socket) == []
    end

    test "returns [actor: actor] when actor_assign resolves to a non-nil value" do
      spec = %CrudSpec{actor_assign: :current_user}
      actor = %{id: 1, role: :admin}
      socket = %{assigns: %{current_user: actor}}

      assert AshCrud.socket_opts(spec, socket) == [actor: actor]
    end

    test "returns [] when the named assign is nil" do
      spec = %CrudSpec{actor_assign: :current_user}
      socket = %{assigns: %{current_user: nil}}

      assert AshCrud.socket_opts(spec, socket) == []
    end

    test "returns [] when the named assign is missing entirely" do
      spec = %CrudSpec{actor_assign: :current_user}
      socket = %{assigns: %{}}

      assert AshCrud.socket_opts(spec, socket) == []
    end

    test "works with an alternative assign name" do
      spec = %CrudSpec{actor_assign: :actor}
      actor = %{id: 42}
      socket = %{assigns: %{actor: actor, current_user: %{id: 99}}}

      assert AshCrud.socket_opts(spec, socket) == [actor: actor]
    end

    test "returns [] when given a non-CrudSpec (defensive fall-through)" do
      assert AshCrud.socket_opts(%{}, %{assigns: %{}}) == []
      assert AshCrud.socket_opts(nil, %{assigns: %{}}) == []
    end
  end
end
