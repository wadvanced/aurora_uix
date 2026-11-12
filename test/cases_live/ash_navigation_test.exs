defmodule Aurora.UixWeb.Test.AshNavigationTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.UixWeb.Test.NavigationHelper

  @p "/ash-navigation-authors"
  @c "/ash-navigation-posts"

  auix_resource_metadata(:author, ash_resource: Author)
  auix_resource_metadata(:post, ash_resource: Post)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:post, [:title, :content])

    edit_layout :author do
      stacked([:name, :email, :posts])
    end
  end

  setup do
    delete_all_blog_data()
    [author | _] = create_sample_authors(2)
    create_sample_posts(3, %{author_id: author.id})
    %{id: author.id}
  end

  test "index opens show, edit and new with the index pushed twice", %{conn: conn, id: id} do
    stack = [{:patch, @p}, {:patch, @p}]

    {:ok, show_view, _html} = live(conn, @p)
    click(show_view, "tr[id='authors-#{id}'] td:nth-child(2) a[name='auix-show-author']")
    assert decoded_patch(show_view) == {"#{@p}/#{id}/show", %{}, stack}

    {:ok, edit_view, _html} = live(conn, @p)
    click(edit_view, "tr[id='authors-#{id}'] a[name='auix-edit-author']")
    assert decoded_patch(edit_view) == {"#{@p}/#{id}/edit", %{}, stack}

    {:ok, new_view, _html} = live(conn, @p)
    click(new_view, "a[name='auix-new-author']")
    assert decoded_patch(new_view) == {"#{@p}/new", %{}, stack}
  end

  test "show to show-edit and back unwinds the stack", %{conn: conn, id: id} do
    {:ok, view, _html} = live(conn, @p)
    click(view, "tr[id='authors-#{id}'] td:nth-child(2) a[name='auix-show-author']")
    assert_patch(view)

    click(view, "#auix-author-show-modal a[name='auix-edit-author']")

    assert decoded_patch(view) ==
             {"#{@p}/#{id}/show-edit", %{},
              [{:patch, "#{@p}/#{id}/show"}, {:patch, @p}, {:patch, @p}]}

    request_close(view, "#auix-author-show_edit-modal [data-phx-component]")

    assert decoded_patch(view) == {"#{@p}/#{id}/show", %{}, [{:patch, @p}, {:patch, @p}]}

    render_click(view, "auix_route_back", %{})
    assert decoded_patch(view) == {@p, %{}, [{:patch, @p}]}
  end

  test "a directly loaded form or show returns to the index with an empty stack", %{
    conn: conn,
    id: id
  } do
    {:ok, view, _html} = live(conn, "#{@p}/#{id}/edit")
    request_close(view, "#auix-author-edit-modal [data-phx-component]")
    assert decoded_patch(view) == {@p, %{}, []}

    {:ok, show_view, _html} = live(conn, "#{@p}/#{id}/show")
    render_click(show_view, "auix_route_back", %{})
    assert decoded_patch(show_view) == {@p, %{}, []}
  end

  test "a new child navigates to the child route and back to the parent form", %{
    conn: conn,
    id: id
  } do
    {:ok, view, _html} = live(conn, "#{@p}/#{id}/edit")

    {:error, {:live_redirect, %{to: to}}} =
      view
      |> element("a[name='auix-new-author__posts-form']")
      |> render_click()

    assert NavigationHelper.decode_route(to) ==
             {"#{@c}/new", %{"related_key" => "author_id", "parent_id" => id},
              [{:navigate, "#{@p}/#{id}/edit"}, {:patch, @p}]}

    {:ok, child, _html} = live(conn, to)

    {:error, {:live_redirect, %{to: closed_to}}} =
      request_close(child, "#auix-post-new-modal [data-phx-component]")

    assert NavigationHelper.decode_route(closed_to) == {"#{@p}/#{id}/edit", %{}, [{:patch, @p}]}
  end

  @spec click(term(), binary()) :: term()
  defp click(view, selector), do: view |> element(selector) |> render_click()

  @spec request_close(term(), binary()) :: term()
  defp request_close(view, target) do
    view |> with_target(target) |> render_click("auix_request_close", %{})
  end

  @spec decoded_patch(term()) :: tuple()
  defp decoded_patch(view), do: view |> assert_patch() |> NavigationHelper.decode_route()
end
