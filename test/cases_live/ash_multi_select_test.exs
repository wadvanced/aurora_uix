defmodule Aurora.UixWeb.Test.AshMultiSelectTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Post

  # Route registered in test/support/app_web/routes.ex as "ash-multi-select-posts".
  # No field override on purpose: `labels` is an `{:array, :atom}` with an `items: [one_of: ...]`
  # constraint, and what is under test is that the parser alone turns it into a multi-value select.
  auix_resource_metadata(:post, schema: Post)

  auix_create_ui do
    index_columns(:post, [:title, :labels])

    edit_layout :post do
      stacked([:title, :content, :labels])
    end

    show_layout :post do
      stacked([:title, :labels])
    end
  end

  describe "form rendering" do
    test "renders one checkbox per constrained value, plus the empty-list sentinel", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/new")

      assert has_element?(view, "input[type='hidden'][name='post[labels][]']")
      refute has_element?(view, "select[multiple][name='post[labels][]']")

      for value <- ~w(featured sponsored opinion full_review) do
        assert has_element?(
                 view,
                 "input[type='checkbox'][name='post[labels][]'][value='#{value}']"
               )
      end
    end

    test "checks exactly the stored values on edit", %{conn: conn} do
      delete_all_blog_data()
      [post] = create_sample_posts(1, %{labels: [:featured, :opinion]})

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/#{post.id}/edit")

      assert checked_values(view) == ["featured", "opinion"]
    end
  end

  describe "toggle all" do
    test "checks every option, then clears them", %{conn: conn} do
      delete_all_blog_data()
      [post] = create_sample_posts(1, %{labels: [:featured]})

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/#{post.id}/edit")

      assert toggle_state(view) == :mixed

      toggle_all(view, "true")

      assert checked_values(view) == ["featured", "sponsored", "opinion", "full_review"]
      assert toggle_state(view) == :all

      toggle_all(view, "false")

      assert checked_values(view) == []
      assert toggle_state(view) == :none
    end
  end

  describe "writing through the parent form" do
    test "saves every checked value, ignoring the sentinel", %{conn: conn} do
      delete_all_blog_data()

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/new")

      view
      |> form("#auix-post-form", %{
        "post" => %{
          "title" => "Multi labels",
          "content" => "Body",
          "labels" => ["", "featured", "sponsored"]
        }
      })
      |> render_submit()

      post = Post |> Ash.read!() |> Enum.find(&(&1.title == "Multi labels"))

      assert post.labels == [:featured, :sponsored]
    end
  end

  describe "show" do
    test "lists only the selected values", %{conn: conn} do
      delete_all_blog_data()
      [post] = create_sample_posts(1, %{labels: [:featured, :opinion]})

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/#{post.id}/show")

      assert selected_items(view) == ["Featured", "Opinion"]
      refute has_element?(view, "input[type='checkbox'][name='post[labels][]']")
    end

    test "shows the empty-state message when nothing is selected", %{conn: conn} do
      delete_all_blog_data()
      [post] = create_sample_posts(1, %{labels: []})

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/#{post.id}/show")

      assert has_element?(
               view,
               "#auix-multi-select-labels-show-options .auix-selected-list-empty-msg",
               "No options to show"
             )
    end
  end

  describe "index" do
    test "shows the option labels joined", %{conn: conn} do
      delete_all_blog_data()
      create_sample_posts(1, %{labels: [:featured, :opinion]})

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts")

      assert has_element?(view, "[name='auix-show-post']", "Featured, Opinion")
    end
  end

  @spec toggle_all(Phoenix.LiveViewTest.View.t(), binary()) :: binary()
  defp toggle_all(view, state) do
    view
    |> form("#auix-post-form", %{"auix_toggle_all__labels" => state})
    |> render_change(%{"_target" => ["auix_toggle_all__labels"]})
  end

  @spec toggle_state(Phoenix.LiveViewTest.View.t()) :: :all | :none | :mixed
  defp toggle_state(view) do
    toggle =
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("input#auix-multi-select-toggle_all-labels")

    cond do
      LazyHTML.attribute(toggle, "checked") != [] -> :all
      toggle |> LazyHTML.attribute("class") |> to_string() =~ "auix-checkbox--mixed" -> :mixed
      true -> :none
    end
  end

  @spec checked_values(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp checked_values(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("input[type='checkbox'][name='post[labels][]'][checked]")
    |> Enum.map(&(&1 |> LazyHTML.attribute("value") |> List.first()))
  end

  @spec selected_items(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp selected_items(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#auix-multi-select-labels-show-options .auix-selected-list-item")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
