defmodule Aurora.UixWeb.Test.AshWhereOne2ManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Post

  # The second author's titles ("Posttest-1" … "Posttest-3") sort inside the range, so a missing
  # owner-key condition would show them.
  @expected_titles Enum.map(14..8//-1, &"Posttest-#{String.pad_leading("#{&1}", 2, "0")}")

  auix_resource_metadata(:author, ash_resource: Author)
  auix_resource_metadata(:post, ash_resource: Post)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:post, [:title, :content])

    edit_layout :author do
      stacked([
        :name,
        :email,
        posts: [
          order_by: [desc: :title],
          where: {:title, :between, "Posttest-08", "Posttest-14"}
        ]
      ])
    end
  end

  test "one-to-many where and order_by select and sort the related rows", %{conn: conn} do
    [first, _second, _third] = create_authors_with_posts()

    {:ok, view, _html} = live(conn, "/ash-where-one_to_many-authors/#{first.id}/show")

    assert column_texts(view, "tbody#author__posts-show tr td:nth-of-type(1)") ==
             @expected_titles
  end

  test "an author with no post shows the empty one-to-many state", %{conn: conn} do
    [_first, _second, third] = create_authors_with_posts()

    {:ok, view, _html} = live(conn, "/ash-where-one_to_many-authors/#{third.id}/show")

    assert column_texts(view, "tbody#author__posts-show tr td:nth-of-type(1)") == []
    assert has_element?(view, "#auix-one_to_many-author__posts-show .auix-items-table-empty")
  end

  @spec create_authors_with_posts() :: list(struct())
  defp create_authors_with_posts do
    delete_all_blog_data()
    [first, second, _third] = authors = create_sample_authors(3)
    create_sample_posts(20, %{author_id: first.id})
    create_sample_posts(3, %{author_id: second.id})
    authors
  end

  @spec column_texts(Phoenix.LiveViewTest.View.t(), binary()) :: list(binary())
  defp column_texts(view, selector) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
