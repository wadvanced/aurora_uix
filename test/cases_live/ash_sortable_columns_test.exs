defmodule Aurora.UixWeb.Test.AshSortableColumnsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Phoenix.LiveViewTest.View

  auix_resource_metadata :author, ash_resource: Author, order_by: :email do
    field(:bio, sortable?: false)

    field(:email,
      sortable?: true,
      data: %{upload: %{allow: [accept: ~w(.png)], consume: &Function.identity/1}}
    )
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:author, [:name, :bio, :email])
  end

  test "sortable columns carry a sort button, opted-out columns do not", %{conn: conn} do
    view = prepare_sort_test(conn)

    assert has_element?(view, "th[aria-sort='none'] button[name='auix-sort-name']")

    for key <- [:bio, :email, :selected_check__],
        do: refute(has_element?(view, "button[name='auix-sort-#{key}']"))
  end

  test "a header click sorts ascending, a second click descending", %{conn: conn} do
    view = conn |> prepare_sort_test() |> click_sort(:name)

    assert name_cells(view) == ["Alpha", "Bravo", "Charlie"]
    assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")

    click_sort(view, :name)

    assert name_cells(view) == ["Charlie", "Bravo", "Alpha"]
    assert has_element?(view, "th[aria-sort='descending'] button[name='auix-sort-name']")
  end

  test "an opted-out or unknown key leaves the order unchanged", %{conn: conn} do
    view = prepare_sort_test(conn)

    render_click(view, "index-sort", %{"key" => "bio"})
    render_click(view, "index-sort", %{"key" => "email"})
    render_click(view, "index-sort", %{"key" => "not_a_column"})

    assert name_cells(view) == ["Charlie", "Alpha", "Bravo"]
    refute has_element?(view, "th[aria-sort='ascending']")
  end

  test "the card sort select offers default order and only the sortable fields", %{conn: conn} do
    view = prepare_sort_test(conn)

    for value <- ["", "name"],
        do:
          assert(
            has_element?(
              view,
              "#auix-sort-form-author select[name='sort'] option[value='#{value}']"
            )
          )

    for value <- ["bio", "email", "selected_check__"],
        do: refute(has_element?(view, "#auix-sort-form-author option[value='#{value}']"))

    assert has_element?(view, "button[name='auix-sort_direction-author'][disabled]")
  end

  test "the card sort select and direction switch sort, reverse and clear", %{conn: conn} do
    view = conn |> prepare_sort_test() |> select_sort("name")

    assert mobile_name_cells(view) == ["Alpha", "Bravo", "Charlie"]
    assert has_element?(view, "#auix-sort-form-author option[value='name'][selected]")
    assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")
    assert has_element?(view, "button[name='auix-sort_direction-author'] span.hero-chevron-up")

    view |> element("button[name='auix-sort_direction-author']") |> render_click()

    assert mobile_name_cells(view) == ["Charlie", "Bravo", "Alpha"]
    assert has_element?(view, "th[aria-sort='descending'] button[name='auix-sort-name']")
    assert has_element?(view, "button[name='auix-sort_direction-author'] span.hero-chevron-down")

    select_sort(view, "")

    assert mobile_name_cells(view) == ["Charlie", "Alpha", "Bravo"]
    assert has_element?(view, "button[name='auix-sort_direction-author'][disabled]")
  end

  test "a third header click returns to the backend order", %{conn: conn} do
    view = conn |> prepare_sort_test() |> click_sort(:name) |> click_sort(:name)
    assert name_cells(view) == ["Charlie", "Bravo", "Alpha"]

    click_sort(view, :name)

    assert name_cells(view) == ["Charlie", "Alpha", "Bravo"]
    assert has_element?(view, "th[aria-sort='none'] button[name='auix-sort-name']")
  end

  @spec prepare_sort_test(Plug.Conn.t()) :: View.t()
  defp prepare_sort_test(conn) do
    delete_all_blog_data()

    for {name, email} <- [
          {"Charlie", "author_1@test.com"},
          {"Alpha", "author_2@test.com"},
          {"Bravo", "author_3@test.com"}
        ],
        do: create_sample_authors(1, %{name: name, email: email})

    {:ok, view, _html} = live(conn, "/ash-sortable-columns-authors")
    view
  end

  @spec click_sort(View.t(), atom()) :: View.t()
  defp click_sort(view, key) do
    view
    |> element("button[name='auix-sort-#{key}']")
    |> render_click()

    view
  end

  @spec name_cells(View.t()) :: list(binary())
  defp name_cells(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#auix-table-ash-sortable-columns-authors-index tr td:nth-of-type(2)")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end

  @spec select_sort(View.t(), binary()) :: View.t()
  defp select_sort(view, sort) do
    view
    |> form("#auix-sort-form-author", %{"sort" => sort})
    |> render_change()

    view
  end

  @spec mobile_name_cells(View.t()) :: list(binary())
  defp mobile_name_cells(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(
      "#auix-table-ash-sortable-columns-authors-index-mobile .auix-items-card-item > div:nth-of-type(1) [name='auix-column-value']"
    )
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
