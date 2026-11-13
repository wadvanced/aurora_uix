defmodule Aurora.Uix.Templates.Basic.HelpersNavigationTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Navigation
  alias Aurora.Uix.Stack
  alias Aurora.Uix.Templates.Basic.Helpers

  test "the helpers store the struct and mirror the legacy keys" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{}}}

    auix =
      socket
      |> Helpers.assign_auix_current_path("/a/b?x=1")
      |> Helpers.assign_auix_uri_path()
      |> Helpers.assign_auix_routing_stack(%{})
      |> then(& &1.assigns.auix)

    assert auix.navigation ==
             Navigation.new(current_path: "/a/b", uri_path: "a/b", uri_path_id: "a--b")

    assert auix._current_path == "/a/b"
    assert auix.uri_path == "a/b"
    assert auix.uri_path_id == "a--b"
    assert auix.routing_stack == Stack.new()
    refute Map.has_key?(auix, :_last_route_path)
  end

  test "the Basic helpers keep their navigation functions" do
    Code.ensure_loaded!(Helpers)

    for {name, arity} <- [
          assign_auix_current_path: 2,
          assign_auix_uri_path: 1,
          assign_auix_index_new_link: 1,
          assign_auix_routing_stack: 2,
          assign_auix_routing_stack: 3,
          auix_route_forward: 2,
          auix_route_back: 1,
          assign_auix_navigation: 2,
          auix_route_back_from: 2,
          auix_route_back_to_edit: 2
        ] do
      assert function_exported?(Helpers, name, arity)
    end
  end

  test "assign_auix_navigation/2 starts the navigation of a component" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{uri_path: "a/b"}}}
    stack = Stack.new([%{type: :patch, path: "/a/b"}])

    auix = Helpers.assign_auix_navigation(socket, nil).assigns.auix

    assert auix.navigation == Navigation.new(uri_path: "a/b")
    assert auix.routing_stack == Stack.new()
    refute Map.has_key?(auix, :_current_path)

    auix2 = Helpers.assign_auix_navigation(socket, stack).assigns.auix

    assert auix2.navigation.stack == stack
    assert auix2.routing_stack == stack
  end
end
