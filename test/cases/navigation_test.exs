defmodule Aurora.Uix.Test.NavigationTest do
  use ExUnit.Case, async: true
  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents
  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest

  alias Aurora.Uix.Navigation
  alias Aurora.Uix.Stack
  alias Aurora.Uix.Templates.Basic.Helpers

  @empty "eJyrVipLzClNLVayio6tBQAhgwS%2F"

  test "Navigation builds and resolves paths" do
    nav = Navigation.new(uri_path: "a/products")

    assert Navigation.path(nav, :index) == "/a/products"
    assert Navigation.path(nav, :new) == "/a/products/new"
    assert Navigation.path(nav, :show, 7) == "/a/products/7/show"
    assert Navigation.path(nav, :edit, 7) == "/a/products/7/edit"
    assert Navigation.path(nav, :show_edit, 7) == "/a/products/7/show-edit"

    for {path, live_action, expected} <- [
          {"/a/products", :index, "a/products"},
          {"/a/products/7/edit", :edit, "a/products"},
          {"/a/products/7/show", :show, "a/products"},
          {"/a/products/7/show-edit", :show_edit, "a/products"},
          {"/a/products/new", :new, "a/products/new"}
        ] do
      resolved =
        [current_path: path]
        |> Navigation.new()
        |> Navigation.resolve_uri_path(live_action)

      assert resolved.uri_path == expected
      assert resolved.uri_path_id == String.replace(expected, "/", "--")
    end

    based = Navigation.new(base_path: "/shop/products", current_path: "/elsewhere/9/edit")

    assert Navigation.resolve_uri_path(based, :edit).uri_path == "shop/products"
    assert Navigation.resolve_uri_path(based, :index).uri_path == "shop/products"
  end

  test "Navigation moves the routing stack" do
    stack =
      Stack.new([
        %{type: :patch, path: "/a/products"},
        %{type: :navigate, path: "/a/products/7/show"}
      ])

    assert Navigation.encode_stack(Stack.new()) == @empty

    assert stack
           |> Navigation.encode_stack()
           |> URI.decode_www_form()
           |> Navigation.decode_stack() == stack

    assert_raise KeyError, fn -> Navigation.new(mode: :local) end

    assert_forward()
    assert_back()
    assert_back_to_edit()
    assert_puts()
    assert_missing_origin()
  end

  test "the Basic helpers store and start the navigation of a socket" do
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

    component_socket = %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}, auix: %{uri_path: "a/b"}}
    }

    started = Stack.new([%{type: :patch, path: "/a/b"}])

    component_auix = Helpers.assign_auix_navigation(component_socket, nil).assigns.auix

    assert component_auix.navigation == Navigation.new(uri_path: "a/b")
    assert component_auix.routing_stack == Stack.new()
    refute Map.has_key?(component_auix, :_current_path)

    stacked_auix = Helpers.assign_auix_navigation(component_socket, started).assigns.auix

    assert stacked_auix.navigation.stack == started
    assert stacked_auix.routing_stack == started
  end

  test "routing links pass phx-target through" do
    forward = query(&targeted_link/1, "a[phx-click='auix_route_forward'][phx-target='#c']")
    link_back = query(&targeted_link_back/1, "a[phx-click='auix_route_back'][phx-target='#c']")
    back = query(&targeted_back/1, "a[phx-click='auix_route_back'][phx-target='#c']")
    plain = query(&plain_link/1, "a[phx-target]")

    assert Enum.count(forward) == 1
    assert Enum.count(link_back) == 1
    assert Enum.count(back) == 1
    assert Enum.empty?(plain)
  end

  @spec assert_forward() :: term()
  defp assert_forward do
    nav = Navigation.new(current_path: "/a/products", uri_path: "a/products")

    {nav2, route} = Navigation.forward(nav, patch: "/a/products/7/show")

    assert nav2.stack == Stack.new([%{type: :patch, path: "/a/products"}])
    assert nav2.last_route_path == "/a/products"

    assert route == %{
             type: :patch,
             path: "/a/products/7/show?routing_stack=" <> Navigation.encode_stack(nav2.stack)
           }

    {nav3, route3} = Navigation.forward(nav, to: "/a/products?page=2")

    assert nav3.stack == Stack.new([%{type: :navigate, path: "/a/products"}])

    assert route3 == %{
             type: :navigate,
             path: "/a/products?page=2&routing_stack=" <> Navigation.encode_stack(nav3.stack)
           }
  end

  @spec assert_back() :: term()
  defp assert_back do
    {nav2, route} =
      [
        current_path: "/a/products/7/show",
        stack: Stack.new([%{type: :patch, path: "/a/products"}])
      ]
      |> Navigation.new()
      |> Navigation.back()

    assert route == %{type: :patch, path: "/a/products?routing_stack=" <> @empty}
    assert nav2.stack == Stack.new()

    {_nav, fallback_route} =
      [current_path: "/a/products/7/edit"]
      |> Navigation.new()
      |> Navigation.back()

    assert fallback_route == %{type: :navigate, path: "/a/products?routing_stack=" <> @empty}

    {nav3, same_path_route} =
      [
        current_path: "/a/products/new",
        stack: Stack.new([%{type: :patch, path: "/a/products/new"}])
      ]
      |> Navigation.new()
      |> Navigation.back()

    assert same_path_route == %{type: :navigate, path: "/a/products?routing_stack=" <> @empty}
    assert nav3.stack == Stack.new()
  end

  @spec assert_back_to_edit() :: term()
  defp assert_back_to_edit do
    nav = Navigation.new(stack: Stack.new([%{type: :patch, path: "/a/products?page=2"}]))

    {nav2, route} = Navigation.back_to_edit(nav, 7)

    assert route == %{type: :navigate, path: "/a/products/7/edit?routing_stack=" <> @empty}
    assert nav2.stack == Stack.new()
  end

  @spec assert_puts() :: term()
  defp assert_puts do
    assert Navigation.put_current_path(
             Navigation.new(),
             "http://localhost:4001/a/products/7/edit?x=1"
           ).current_path == "/a/products/7/edit"

    stack = Stack.new([%{type: :patch, path: "/a"}])

    assert Navigation.put_stack(Navigation.new(), stack).stack == stack
  end

  @spec assert_missing_origin() :: term()
  defp assert_missing_origin do
    assert_raise FunctionClauseError, fn -> Navigation.forward(Navigation.new(), patch: "/x") end

    assert_raise Aurora.Uix.Stack.EmptyStackError, fn ->
      Navigation.back_to_edit(Navigation.new(), 7)
    end
  end

  @spec targeted_link(map()) :: Phoenix.LiveView.Rendered.t()
  defp targeted_link(assigns), do: ~H|<.auix_link patch="/x" phx-target="#c">x</.auix_link>|

  @spec targeted_link_back(map()) :: Phoenix.LiveView.Rendered.t()
  defp targeted_link_back(assigns),
    do: ~H|<.auix_link_back phx-target="#c">x</.auix_link_back>|

  @spec targeted_back(map()) :: Phoenix.LiveView.Rendered.t()
  defp targeted_back(assigns), do: ~H|<.auix_back phx-target="#c">x</.auix_back>|

  @spec plain_link(map()) :: Phoenix.LiveView.Rendered.t()
  defp plain_link(assigns), do: ~H|<.auix_link patch="/x">x</.auix_link>|

  @spec query(function(), binary()) :: LazyHTML.t()
  defp query(component, selector) do
    component
    |> render_component(%{})
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
  end
end
