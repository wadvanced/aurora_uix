defmodule Aurora.UixWeb.Test.AshPreloadMetadataTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Blog.Author

  auix_resource_metadata :author do
    ash_resource(Author)
    preload([:posts])
    field(:name, index_renderer: &__MODULE__.posts_marker/1)
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:author, [:name, :email])
  end

  @doc false
  @spec posts_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def posts_marker(assigns) do
    ~H"""
    <span class="auix-posts-marker">
      {if match?(%Ash.NotLoaded{}, @entity.posts), do: "NOT_LOADED", else: "LOADED"}
    </span>
    """
  end

  test "the resource preload loads a relationship the layout does not render", %{conn: conn} do
    delete_all_blog_data()
    create_sample_authors(2)

    {:ok, view, _html} = live(conn, "/ash-preload-metadata-authors")

    assert has_element?(view, "span.auix-posts-marker", "LOADED")
    refute has_element?(view, "span.auix-posts-marker", "NOT_LOADED")
  end
end
