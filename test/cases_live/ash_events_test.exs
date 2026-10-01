defmodule Aurora.UixWeb.Test.AshEventsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Guides.Blog.Author

  @badge "#auix-delete-all-button-author>button span.auix-button-badge"

  auix_resource_metadata(:author, ash_resource: Author)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  auix_create_ui do
    index_columns(:author, [:name, :email])

    edit_layout :author do
      stacked([:name, :email, :bio])
    end

    show_layout :author do
      stacked([:name, :email])
    end
  end

  test "an index subscribes to its resource's topic", %{conn: conn} do
    delete_all_blog_data()
    {:ok, view, _} = live(conn, "/ash-events-authors")

    pids = Aurora.Uix.PubSub |> Registry.lookup(Events.topic(Author)) |> Enum.map(&elem(&1, 0))

    assert view.pid in pids
  end

  test "a save in one view re-reads another index", %{conn: conn} do
    delete_all_blog_data()
    [author | _] = create_sample_authors(3)
    id = author.id

    {:ok, view_b, _} = live(conn, "/ash-events-authors")
    {:ok, view_a, _} = live(conn, "/ash-events-authors/#{id}/edit")

    view_a
    |> form("#auix-author-form", author: %{name: "Renamed author"})
    |> render_submit()

    assert has_element?(view_b, "#authors-#{id}", "Renamed author")
  end

  test "a row delete removes the row from another index", %{conn: conn} do
    delete_all_blog_data()
    [author | _] = create_sample_authors(3)
    id = author.id

    {:ok, view_a, _} = live(conn, "/ash-events-authors")
    {:ok, view_b, _} = live(conn, "/ash-events-authors")

    render_click(view_a, "delete", %{"id" => id})

    refute has_element?(view_b, "#authors-#{id}")
  end

  test "Delete selected publishes only the records it deleted", %{conn: conn} do
    delete_all_blog_data()
    [first, second, third] = create_sample_authors(3)

    :ok = Events.subscribe(Author)
    {:ok, view_a, _} = live(conn, "/ash-events-authors")
    {:ok, view_b, _} = live(conn, "/ash-events-authors")

    Enum.each([first, second, third], &select_row(view_a, &1.id))
    Ash.destroy!(third)

    render_click(view_a, "selected-delete_all", %{})
    render_async(view_a)

    assert_receive %Event{action: :deleted, ids: ids}
    assert Enum.sort(ids) == Enum.sort([first.id, second.id])
    refute has_element?(view_b, "#authors-#{first.id}")
  end

  test "a deleted id leaves another view's selection", %{conn: conn} do
    delete_all_blog_data()
    [first, second | _] = create_sample_authors(3)

    {:ok, view_b, _} = live(conn, "/ash-events-authors")
    select_row(view_b, first.id)
    select_row(view_b, second.id)
    {:ok, view_a, _} = live(conn, "/ash-events-authors")

    assert has_element?(view_b, @badge, "2")

    render_click(view_a, "delete", %{"id" => first.id})

    assert has_element?(view_b, @badge, "1")
  end

  @spec select_row(term(), term()) :: binary()
  defp select_row(view, id),
    do: render_change(view, "index-layout-change", %{"_target" => ["selected_check__#{id}"]})
end
