defmodule Aurora.Uix.Test.NavigationTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Navigation
  alias Aurora.Uix.Stack
  alias Aurora.Uix.Templates.Basic.Helpers

  test "path/3 builds the five paths" do
    nav = Navigation.new(uri_path: "a/products")

    assert Navigation.path(nav, :index) == "/a/products"
    assert Navigation.path(nav, :new) == "/a/products/new"
    assert Navigation.path(nav, :show, 7) == "/a/products/7/show"
    assert Navigation.path(nav, :edit, 7) == "/a/products/7/edit"
    assert Navigation.path(nav, :show_edit, 7) == "/a/products/7/show-edit"
  end

  test "resolve_uri_path/2 parses the current path as before" do
    for {path, live_action, expected} <- [
          {"/a/products", :index, "a/products"},
          {"/a/products/7/edit", :edit, "a/products"},
          {"/a/products/7/show", :show, "a/products"},
          {"/a/products/7/show-edit", :show_edit, "a/products"},
          {"/a/products/new", :new, "a/products/new"}
        ] do
      nav = Navigation.new(current_path: path)
      resolved = Navigation.resolve_uri_path(nav, live_action)

      assert resolved.uri_path == expected
      assert resolved.uri_path_id == String.replace(expected, "/", "--")
    end
  end

  test "resolve_uri_path/2 prefers base_path" do
    nav = Navigation.new(base_path: "/shop/products", current_path: "/elsewhere/9/edit")

    assert Navigation.resolve_uri_path(nav, :edit).uri_path == "shop/products"
    assert Navigation.resolve_uri_path(nav, :index).uri_path == "shop/products"
  end

  test "encode_stack/1 and decode_stack/1 round-trip" do
    stack =
      Stack.new([
        %{type: :patch, path: "/a/products"},
        %{type: :navigate, path: "/a/products/7/show"}
      ])

    assert Navigation.encode_stack(Stack.new()) == "eJyrVipLzClNLVayio6tBQAhgwS%2F"

    assert stack
           |> Navigation.encode_stack()
           |> URI.decode_www_form()
           |> Navigation.decode_stack() == stack
  end

  test "put/2 stores the struct and mirrors the legacy keys" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{}}}
    nav = Navigation.new(uri_path: "a/b", uri_path_id: "a--b")

    auix = Navigation.put(socket, nav).assigns.auix

    assert auix.navigation == nav
    assert auix.uri_path == "a/b"
    assert auix.uri_path_id == "a--b"
    assert auix.routing_stack == nav.stack
    refute Map.has_key?(auix, :_current_path)
    refute Map.has_key?(auix, :_last_route_path)
  end

  test "new/1 rejects a key the struct does not have" do
    assert_raise KeyError, fn -> Navigation.new(mode: :local) end
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
          auix_route_back: 1
        ] do
      assert function_exported?(Helpers, name, arity)
    end
  end

  test "related_uri_path/3 swaps the source segment" do
    assert Navigation.related_uri_path(
             "navigation-products",
             "products",
             "product_transactions"
           ) == "navigation-product_transactions"

    assert Navigation.related_uri_path("navigation-products", "products", "products") ==
             "navigation-products"
  end
end
