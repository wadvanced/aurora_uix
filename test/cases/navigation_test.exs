defmodule Aurora.Uix.Test.NavigationTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Navigation
  alias Aurora.Uix.Stack

  @empty "eJyrVipLzClNLVayio6tBQAhgwS%2F"

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

    assert Navigation.encode_stack(Stack.new()) == @empty

    assert stack
           |> Navigation.encode_stack()
           |> URI.decode_www_form()
           |> Navigation.decode_stack() == stack
  end

  test "new/1 rejects a key the struct does not have" do
    assert_raise KeyError, fn -> Navigation.new(mode: :local) end
  end

  test "forward/2 pushes the current path and returns the route" do
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

  test "back/1 pops the stack and falls back to the index path" do
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

  test "back_to_edit/2 returns to the edit path of the origin" do
    nav = Navigation.new(stack: Stack.new([%{type: :patch, path: "/a/products?page=2"}]))

    {nav2, route} = Navigation.back_to_edit(nav, 7)

    assert route == %{type: :navigate, path: "/a/products/7/edit?routing_stack=" <> @empty}
    assert nav2.stack == Stack.new()
  end

  test "put_current_path/2 and put_stack/2 set their field" do
    assert Navigation.put_current_path(
             Navigation.new(),
             "http://localhost:4001/a/products/7/edit?x=1"
           ).current_path == "/a/products/7/edit"

    stack = Stack.new([%{type: :patch, path: "/a"}])

    assert Navigation.put_stack(Navigation.new(), stack).stack == stack
  end

  test "forward/2 needs a current path and back_to_edit/2 an origin" do
    assert_raise FunctionClauseError, fn -> Navigation.forward(Navigation.new(), patch: "/x") end

    assert_raise Aurora.Uix.Stack.EmptyStackError, fn ->
      Navigation.back_to_edit(Navigation.new(), 7)
    end
  end
end
