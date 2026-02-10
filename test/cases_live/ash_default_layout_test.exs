defmodule Aurora.UixWeb.Test.AshDefaultLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author

  auix_resource_metadata(:author, ash_resource: Author, order_by: [:bio])

  auix_create_ui()

  test "Default layout index", %{conn: conn} do
    delete_all_blog_data()
    create_sample_authors(20)

    {:ok, view, html} = live(conn, "/ash-default-layout-authors")
    assert html =~ "Listing Authors"
    assert html =~ "New Author"

    refute has_element?(view, "div[name='auix-pages_bar-authors']")
  end

  test "Pagination navigation test", %{conn: conn} do
    delete_all_blog_data()
    create_sample_authors(1000)
    {:ok, view, html} = live(conn, "/ash-default-layout-authors")
    assert html =~ "Listing Authors"

    assert has_element?(view, "div[name='auix-pages_bar-authors']")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-ash-default-layout-authors-index tr")
           |> Enum.count() == 40

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-authors-md'] [name^='auix-pages_bar_page-']"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "1",
             "2",
             "3",
             "4",
             "5",
             "6",
             "7",
             "8",
             "9",
             "...",
             "25",
             ""
           ]

    # Direct navigation
    {:ok, view_direct, html_direct} = live(conn, "/ash-default-layout-authors?page=12")

    assert html_direct
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-authors-md'] [name^='auix-pages_bar_page-']"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "",
             "1",
             "...",
             "8",
             "9",
             "10",
             "11",
             "12",
             "13",
             "14",
             "15",
             "16",
             "...",
             "25",
             ""
           ]

    assert html_direct
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-ash-default-layout-authors-index tr")
           |> Enum.count() == 40

    # Navigate to a page by click
    view_direct
    |> element("div[name='auix-pages_bar-authors-md'] a[name='auix-pages_bar_page-10']")
    |> render_click()

    assert view_direct
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-authors-md'] [name^='auix-pages_bar_page-']"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "",
             "1",
             "...",
             "6",
             "7",
             "8",
             "9",
             "10",
             "11",
             "12",
             "13",
             "14",
             "...",
             "25",
             ""
           ]

    assert view_direct
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-ash-default-layout-authors-index tr")
           |> Enum.count() == 40
  end

  test "Test show default behaviour", %{conn: conn} do
    delete_all_blog_data()

    author =
      3
      |> create_sample_authors()
      |> List.last()

    {:ok, _view, html} = live(conn, "/ash-default-layout-authors/#{author.id}/show")

    html
    |> tap(&assert &1 =~ "Author\n")
    |> tap(&assert &1 =~ " Details\n")

    html
    |> LazyHTML.from_document()
    |> tap(
      &assert &1
              |> LazyHTML.query("input[id^='auix-field-author-name-'][id$='-#{author.id}--show']")
              |> LazyHTML.attribute("value") == [author.name]
    )
    |> tap(
      &assert &1
              |> LazyHTML.query(
                "input[id^='auix-field-author-email-'][id$='-#{author.id}--show']"
              )
              |> LazyHTML.attribute("value") == [author.email]
    )
    |> tap(
      &assert &1
              |> LazyHTML.query("input[id^='auix-field-author-bio-'][id$='-#{author.id}--show']")
              |> LazyHTML.attribute("value") == [author.bio]
    )
  end

  test "Test CREATE new author", %{conn: conn} do
    delete_all_blog_data()
    {:ok, view, _html} = live(conn, "/ash-default-layout-authors/new")

    assert view
           |> element("div#auix-author-new-modal header")
           |> render() =~ "New Author"

    assert view
           |> element("div#auix-author-new-modal header")
           |> render() =~ "Creates a new <strong>Author</strong> record in your database"

    # Create unique test data
    unique_name = "Author-#{System.system_time(:nanosecond)}"
    unique_email = "author-#{System.system_time(:nanosecond)}@test.com"
    unique_bio = "Test bio #{System.system_time(:nanosecond)}"

    # Submit the form
    view
    |> form("#auix-author-form",
      author: %{
        name: unique_name,
        email: unique_email,
        bio: unique_bio
      }
    )
    |> render_submit()

    # Verify the author appears in the index
    {:ok, _view, new_html} = live(conn, "/ash-default-layout-authors")

    assert new_html =~ "Listing Authors"
    assert new_html =~ unique_name
    assert new_html =~ unique_email
  end

  test "Test UPDATE existing author", %{conn: conn} do
    delete_all_blog_data()

    author =
      1
      |> create_sample_authors()
      |> List.first()

    {:ok, view, _html} = live(conn, "/ash-default-layout-authors/#{author.id}/edit")

    assert view
           |> element("div#auix-author-edit-modal header")
           |> render() =~ "Edit Author"

    assert view
           |> element("div#auix-author-edit-modal header")
           |> render() =~
             "Use this form to manage <strong>Authors</strong> records in your database"

    # Verify form fields are populated with existing values
    html = render(view)

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("input[name='author[name]']")
           |> LazyHTML.attribute("value") == [author.name]

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("input[name='author[email]']")
           |> LazyHTML.attribute("value") == [author.email]

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("input[name='author[bio]']")
           |> LazyHTML.attribute("value") == [author.bio]

    # Update with unique values
    updated_name = "Updated-#{System.system_time(:nanosecond)}"
    updated_bio = "Updated bio-#{System.system_time(:nanosecond)}"

    # Submit the update
    view
    |> form("#auix-author-form",
      author: %{
        name: updated_name,
        bio: updated_bio
      }
    )
    |> render_submit()

    # Verify the changes appear in the index
    {:ok, _view, updated_html} = live(conn, "/ash-default-layout-authors")

    assert updated_html =~ updated_name
    assert updated_html =~ updated_bio
  end
end
