defmodule Aurora.UixWeb.Test.AshMany2ManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.PostTopic
  alias Aurora.Uix.Guides.Blog.Topic

  # Routes for both resources are registered in test/support/app_web/routes.ex as
  # "ash-many2many-posts" and "ash-many2many-topics".
  auix_resource_metadata :post, schema: Post do
    field(:topics, option_label: :name)
  end

  auix_resource_metadata(:topic, schema: Topic)

  auix_create_ui do
    edit_layout :post do
      stacked([:title, :content, :topics])
    end

    show_layout :post do
      stacked([:title, :topics])
    end
  end

  describe "form rendering" do
    test "renders every candidate topic as an option, none selected, on new", %{conn: conn} do
      delete_all_blog_data()
      create_sample_posts_with_topics(0, 3)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/new")

      assert has_element?(view, "select[name='post[topics][]'][multiple]")
      assert has_element?(view, "input[type='hidden'][name='post[topics][]']")

      assert options_count(view) == 3
      assert selected_labels(view) == []
    end

    test "pre-selects exactly the current members on edit", %{conn: conn} do
      delete_all_blog_data()
      {[post], topics} = create_sample_posts_with_topics(1, 3)
      [first, _second, _third] = topics

      # Reduce membership to one, so selected and unselected options both exist.
      {:ok, _} =
        post
        |> Ash.load!(:topics)
        |> Ash.update(%{"topics" => [first.id]}, action: :update)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/#{post.id}/edit")

      assert options_count(view) == 3
      assert selected_labels(view) == [first.name]
    end
  end

  describe "writing membership through the parent form" do
    test "adds the selected topics as join rows", %{conn: conn} do
      delete_all_blog_data()
      {_posts, topics} = create_sample_posts_with_topics(0, 3)
      chosen = topics |> Enum.take(2) |> Enum.map(& &1.id)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/new")

      view
      |> form("#auix-post-form", %{
        "post" => %{"title" => "Many topics", "content" => "Body", "topics" => chosen}
      })
      |> render_submit()

      post =
        Post
        |> Ash.read!()
        |> Enum.find(&(&1.title == "Many topics"))
        |> Ash.load!(:topics)

      assert Enum.count(post.topics) == 2
      assert count(PostTopic) == 2
    end

    test "removing a topic deletes only the join row, never the topic", %{conn: conn} do
      delete_all_blog_data()
      {[post], topics} = create_sample_posts_with_topics(1, 3)
      keep = topics |> Enum.take(1) |> Enum.map(& &1.id)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/#{post.id}/edit")

      view
      |> form("#auix-post-form", %{"post" => %{"topics" => keep}})
      |> render_submit()

      assert count(PostTopic) == 1
      # The de-selected topics must survive -- delete semantics invert for many_to_many.
      assert count(Topic) == 3
    end

    test "de-selecting everything clears membership", %{conn: conn} do
      delete_all_blog_data()
      {[post], _topics} = create_sample_posts_with_topics(1, 3)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/#{post.id}/edit")

      # Only the hidden sentinel is submitted, which is what a fully de-selected list looks like.
      view
      |> form("#auix-post-form", %{"post" => %{"topics" => [""]}})
      |> render_submit()

      assert count(PostTopic) == 0
      assert count(Topic) == 3
    end
  end

  describe "show rendering" do
    test "renders the membership select disabled", %{conn: conn} do
      delete_all_blog_data()
      {[post], _topics} = create_sample_posts_with_topics(1, 2)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/#{post.id}/show")

      assert has_element?(view, "#auix-many-to-many-topics-show select[disabled][multiple]")
      assert view |> selected_labels() |> Enum.count() == 2
    end
  end

  describe "index" do
    test "never renders the association as a column", %{conn: conn} do
      delete_all_blog_data()
      create_sample_posts_with_topics(2, 2)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts")

      refute view
             |> element("table.auix-items-table thead")
             |> render() =~ "Topic"
    end
  end

  @spec count(module()) :: non_neg_integer()
  defp count(resource), do: resource |> Ash.read!() |> Enum.count()

  @spec options_count(Phoenix.LiveViewTest.View.t()) :: non_neg_integer()
  defp options_count(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("select[multiple] option")
    |> Enum.count()
  end

  @spec selected_labels(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp selected_labels(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("select[multiple] option[selected]")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
