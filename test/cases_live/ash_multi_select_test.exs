defmodule Aurora.UixWeb.Test.AshMultiSelectTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Post

  # Route registered in test/support/app_web/routes.ex as "ash-multi-select-posts".
  # No field override on purpose: `labels` is an `{:array, :atom}` with an `items: [one_of: ...]`
  # constraint, and what is under test is that the parser alone turns it into a multiple select.
  auix_resource_metadata(:post, schema: Post)

  auix_create_ui do
    index_columns(:post, [:title, :labels])

    edit_layout :post do
      stacked([:title, :content, :labels])
    end
  end

  describe "form rendering" do
    test "renders the field as a multiple select with every constrained value", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/new")

      assert has_element?(view, "select[multiple][name='post[labels][]']")

      for value <- ~w(featured sponsored opinion) do
        assert has_element?(view, "select[name='post[labels][]'] option[value='#{value}']")
      end
    end

    test "pre-selects exactly the stored values on edit", %{conn: conn} do
      delete_all_blog_data()
      [post] = create_sample_posts(1, %{labels: [:featured, :opinion]})

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/#{post.id}/edit")

      assert has_element?(view, "option[value='featured'][selected]")
      assert has_element?(view, "option[value='opinion'][selected]")
      refute has_element?(view, "option[value='sponsored'][selected]")
    end
  end

  describe "writing through the parent form" do
    test "saves every selected value", %{conn: conn} do
      delete_all_blog_data()

      {:ok, view, _html} = live(conn, "/ash-multi-select-posts/new")

      view
      |> form("#auix-post-form", %{
        "post" => %{
          "title" => "Multi labels",
          "content" => "Body",
          "labels" => ["featured", "sponsored"]
        }
      })
      |> render_submit()

      post = Post |> Ash.read!() |> Enum.find(&(&1.title == "Multi labels"))

      assert post.labels == [:featured, :sponsored]
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
end
