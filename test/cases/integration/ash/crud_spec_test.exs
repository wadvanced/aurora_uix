defmodule Aurora.Uix.Integration.Ash.CrudSpecTest do
  @moduledoc """
  Unit tests for `Aurora.Uix.Integration.Ash.CrudSpec` construction.

  Verifies that the optional `:actor_assign` is stored on the struct when provided and
  defaults to `nil` otherwise, preserving backward compatibility for callers that pass
  no options.
  """
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash.CrudSpec

  describe "new/0" do
    test "creates an empty spec with actor_assign defaulting to nil" do
      assert %CrudSpec{actor_assign: nil} = CrudSpec.new()
    end
  end

  describe "new/3 (backward-compatible)" do
    test "stores resource, action, auix_action_name; actor_assign defaults to nil" do
      action = %{name: :read}
      spec = CrudSpec.new(MyApp.User, action, :list_function)

      assert spec.resource == MyApp.User
      assert spec.action == action
      assert spec.auix_action_name == :list_function
      assert spec.actor_assign == nil
    end
  end

  describe "new/4 with :actor_assign opt" do
    test "stores actor_assign when provided" do
      spec = CrudSpec.new(MyApp.User, %{name: :read}, :list_function, actor_assign: :current_user)

      assert spec.actor_assign == :current_user
    end

    test "leaves actor_assign as nil when opts omits the key" do
      spec = CrudSpec.new(MyApp.User, %{name: :read}, :list_function, [])

      assert spec.actor_assign == nil
    end
  end
end
