defmodule Aurora.UixWeb.Test.AshMany2ManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.PostTopic
  alias Aurora.Uix.Guides.Blog.Topic

  # Routes for both resources are registered in test/support/app_web/routes.ex as
  # "ash-many2many-posts" and "ash-many2many-topics".
  # No `option_label:` on purpose: this module covers the label the renderer resolves from the
  # related resource's own `:index` layout. The Ctx counterpart declares one explicitly.
  auix_resource_metadata(:post, schema: Post)

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

      assert has_element?(view, "input[type='checkbox'][name='post[topics][]']")
      assert has_element?(view, "input[type='hidden'][name='post[topics][]']")

      assert options_count(view) == 3
      assert checked_ids(view) == []
    end

    test "labels each option from the related resource when no option_label is declared", %{
      conn: conn
    } do
      delete_all_blog_data()
      {_posts, topics} = create_sample_posts_with_topics(0, 3)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/new")

      assert view |> option_labels() |> Enum.sort() ==
               topics |> Enum.map(& &1.name) |> Enum.sort()
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
      assert checked_ids(view) == [first.id]
    end
  end

  # These submit through the same `post[topics][]` key a `<select multiple>` used, and are
  # deliberately untouched by the switch to checkboxes: their survival is the proof that the wire
  # format did not change, and therefore that no host has to adapt.
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

  # Only the submit round trip is covered here: the tri-state logic and the params merge are
  # backend-agnostic and are covered against Ctx. What is Ash-specific is that the toggled
  # membership reaches `manage_relationship`.
  describe "toggle all" do
    test "a toggled-all membership survives submit", %{conn: conn} do
      delete_all_blog_data()
      create_sample_posts_with_topics(0, 3)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/new")

      view
      |> form("#auix-post-form", %{"auix_toggle_all__topics" => "true"})
      |> render_change(%{"_target" => ["auix_toggle_all__topics"]})

      view
      |> form("#auix-post-form", %{"post" => %{"title" => "All topics", "content" => "Body"}})
      |> render_submit()

      assert count(PostTopic) == 3
    end
  end

  describe "show rendering" do
    test "renders only the current membership, as a plain read-only list", %{conn: conn} do
      delete_all_blog_data()
      {[post], topics} = create_sample_posts_with_topics(1, 2)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/#{post.id}/show")

      refute has_element?(view, "#auix-many-to-many-topics-show input[type='checkbox']")

      for topic <- topics do
        assert has_element?(
                 view,
                 "#auix-many-to-many-topics-show-options .auix-selected-list-item",
                 topic.name
               )
      end
    end

    test "shows the empty-state message when there is no membership", %{conn: conn} do
      delete_all_blog_data()
      {[post], _topics} = create_sample_posts_with_topics(1, 0)

      {:ok, view, _html} = live(conn, "/ash-many2many-posts/#{post.id}/show")

      assert has_element?(
               view,
               "#auix-many-to-many-topics-show-options .auix-selected-list-empty-msg",
               "No items to show"
             )
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
    |> LazyHTML.query(".auix-checkbox-group input[type='checkbox']")
    |> Enum.count()
  end

  @spec option_labels(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp option_labels(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(".auix-checkbox-group-option-label")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end

  # Asserting on the submitted values rather than the labels: the value is what the round trip
  # actually preserves.
  @spec checked_ids(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp checked_ids(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(".auix-checkbox-group input[type='checkbox'][checked]")
    |> Enum.map(&(&1 |> LazyHTML.attribute("value") |> List.first()))
  end
end
