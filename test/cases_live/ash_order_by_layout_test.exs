defmodule Aurora.UixWeb.Test.AshOrderByLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author

  @shuffled_references [
    "test_order-11",
    "test_order-03",
    "test_order-20",
    "test_order-08",
    "test_order-14",
    "test_order-05",
    "test_order-19",
    "test_order-17",
    "test_order-02",
    "test_order-10",
    "test_order-16",
    "test_order-07",
    "test_order-12",
    "test_order-09",
    "test_order-18",
    "test_order-04",
    "test_order-13",
    "test_order-06",
    "test_order-01",
    "test_order-15"
  ]

  @test_names Enum.map(1..20, &"Author test_order-#{String.pad_leading("#{&1}", 2, "0")}")

  auix_resource_metadata(:author, ash_resource: Author, order_by: :email)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:author, [:name, :email, :bio], order_by: :name)
  end

  test "layout order_by overrides the metadata order_by", %{conn: conn} do
    delete_all_blog_data()
    create_shuffled_authors(@shuffled_references)

    {:ok, view, _html} = live(conn, "/ash-order-by-layout-authors")

    assert column_texts(view, 2) == @test_names
  end

  # Random emails make the metadata order_by disagree with the name order.
  @spec create_shuffled_authors(list(binary())) :: :ok
  defp create_shuffled_authors(reference_ids) do
    Enum.each(reference_ids, fn reference_id ->
      create_sample_authors(1, %{
        name: "Author #{reference_id}",
        email: "#{Ash.UUID.generate()}@test.com",
        bio: "Bio #{reference_id}"
      })
    end)
  end

  @spec column_texts(Phoenix.LiveViewTest.View.t(), pos_integer()) :: list(binary())
  defp column_texts(view, position) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(
      "#auix-table-ash-order-by-layout-authors-index tr td:nth-of-type(#{position})"
    )
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
