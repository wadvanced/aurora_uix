defmodule Aurora.UixWeb.Test.AshWhereMany2OneTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Post

  @expected_names Enum.map(14..8//-1, &"Authortest-#{String.pad_leading("#{&1}", 2, "0")}")

  auix_resource_metadata(:author, ash_resource: Author)

  auix_resource_metadata :post, ash_resource: Post do
    field(:author_id,
      option_label: :name,
      order_by: [desc: :name],
      where: [{:name, :between, "Authortest-08", "Authortest-14"}]
    )
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    edit_layout :post do
      stacked([:title, :content, :author_id])
    end
  end

  test "many-to-one selector where and order_by select and sort the options", %{conn: conn} do
    delete_all_blog_data()
    authors = create_sample_authors(20)
    [post] = create_sample_posts(1, %{author_id: Enum.at(authors, 9).id})

    {:ok, view, _html} = live(conn, "/ash-where-many_to_one-posts/#{post.id}/edit")

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("select[name='post[author_id]'] option")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
           |> Enum.filter(&String.starts_with?(&1, "Authortest-")) == @expected_names
  end
end
