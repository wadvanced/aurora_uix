defmodule Aurora.UixWeb.Test.AshFilterBarTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Post
  alias Phoenix.LiveViewTest.View

  auix_resource_metadata(:author, ash_resource: Author)

  auix_resource_metadata :post, ash_resource: Post do
    field(:author_id, option_label: :name)
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:post, [:title, :author_id, :published_at])
  end

  describe "filter bar" do
    test "equality", %{conn: conn} do
      {view, _authors} = prepare_filters_test(conn)
      set_filter_change(view, :filter_condition, :title, :eq)
      set_filter_change(view, :filter_from, :title, "post_group_3d-1")

      assert has_element?(view, "input[name='filter_from__title'][value='post_group_3d-1']")
      assert submitted_row_count(view) == 1
    end

    test "ge", %{conn: conn} do
      {view, _authors} = prepare_filters_test(conn)
      set_filter_change(view, :filter_condition, :title, :ge)
      set_filter_change(view, :filter_from, :title, "post_group_3d-2")

      assert has_element?(view, "input[name='filter_from__title'][value='post_group_3d-2']")
      assert submitted_row_count(view) == 3
    end

    test "between", %{conn: conn} do
      {view, _authors} = prepare_filters_test(conn)
      set_filter_change(view, :filter_condition, :title, :between)
      set_filter_change(view, :filter_from, :title, "post_group_2b")
      set_filter_change(view, :filter_to, :title, "post_group_3d")

      assert has_element?(view, "input[name='filter_to__title'][value='post_group_3d']")
      assert submitted_row_count(view) == 5
    end

    test "many to one", %{conn: conn} do
      {view, [_first, second, _third]} = prepare_filters_test(conn)
      set_filter_change(view, :filter_condition, :author_id, :eq)
      set_filter_change(view, :filter_from, :author_id, second.id)

      assert has_element?(
               view,
               "select[name='filter_from__author_id'] option[selected][value='#{second.id}']"
             )

      assert submitted_row_count(view) == 7
    end

    test "contains escapes the ilike wildcards", %{conn: conn} do
      {view, _authors} = prepare_filters_test(conn)
      set_filter_change(view, :filter_condition, :title, :contains)

      for value <- ["%", "a_1"] do
        set_filter_change(view, :filter_from, :title, value)
        assert submitted_row_count(view) == 0
      end
    end

    test "contains ignores the to value and a blank from value", %{conn: conn} do
      {view, _authors} = prepare_filters_test(conn)
      set_filter_change(view, :filter_condition, :title, :contains)
      set_filter_change(view, :filter_from, :title, "")

      assert has_element?(view, "[name='filter_to__title'][readonly][disabled]")
      assert submitted_row_count(view) == 11
    end

    test "a filter matching no row shows the empty state", %{conn: conn} do
      {view, _authors} = prepare_filters_test(conn)
      set_filter_change(view, :filter_condition, :title, :eq)
      set_filter_change(view, :filter_from, :title, "post_group_9z-1")

      assert submitted_row_count(view) == 0
      assert has_element?(view, "div.auix-items-table-empty")
    end

    test "the filter bar opens on the toggle", %{conn: conn} do
      delete_all_blog_data()
      {:ok, view, _html} = live(conn, "/ash-filter-bar-posts")

      refute has_element?(view, "[name='auix-filters_submit-post']")
      refute has_element?(view, "[name='auix-filters_clear-post']")

      view
      |> element("[name='auix-filter_toggle_open']")
      |> render_click()

      assert has_element?(view, "[name='auix-filters_submit-post']")
      assert has_element?(view, "[name='auix-filters_clear-post']")
    end

    test "the condition select offers no contains option for non-text fields", %{conn: conn} do
      {view, _authors} = prepare_filters_test(conn)

      for field <- [:author_id, :published_at] do
        refute has_element?(
                 view,
                 "select[name='filter_condition__#{field}'] option[value='contains']"
               )
      end
    end
  end

  @spec prepare_filters_test(Plug.Conn.t()) :: {View.t(), list(struct())}
  defp prepare_filters_test(conn) do
    delete_all_blog_data()
    [first, second, third] = authors = create_sample_authors(3)

    posts = [
      {"post_group_1a-1", first},
      {"post_group_1a-2", first},
      {"post_group_2b-1", second},
      {"post_group_2b-2", second},
      {"post_group_2b-3", second},
      {"post_group_3c-1", third},
      {"post_group_3c-2", third},
      {"post_group_3d-1", second},
      {"post_group_3d-2", second},
      {"post_group_3d-3", second},
      {"post_group_3d-4", second}
    ]

    Enum.each(posts, fn {title, author} ->
      create_sample_posts(1, %{title: title, author_id: author.id})
    end)

    {:ok, view, _html} = live(conn, "/ash-filter-bar-posts")

    view
    |> element("[name='auix-filter_toggle_open']")
    |> render_click()

    {view, authors}
  end

  @spec submitted_row_count(View.t()) :: non_neg_integer()
  defp submitted_row_count(view) do
    view
    |> element("[name='auix-index-header-actions'] [name='auix-filters_submit-post']")
    |> render_click()

    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#auix-table-ash-filter-bar-posts-index tr")
    |> Enum.count()
  end

  @spec set_filter_change(View.t(), atom(), atom(), atom() | binary()) :: View.t()
  defp set_filter_change(view, element, field, value) do
    render_change(view, "index-layout-change", %{
      "_target" => ["#{element}__#{field}"],
      "#{element}__#{field}" => "#{value}"
    })

    view
  end
end
