defmodule Aurora.UixWeb.Test.GuidesTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case

  alias Aurora.Uix.Guides.Inventory.ProductTransaction
  alias Aurora.Uix.Repo

  test "the guide pages mount on both backends", %{conn: conn} do
    delete_all_sample_data()
    [{_, product}] = create_sample_products_with_transactions(1, 1, :test)
    [location] = 1 |> create_sample_product_locations(:test) |> Map.values()
    [author] = create_sample_authors(1)
    [category] = create_sample_categories(1)
    [post] = create_sample_posts(1, %{author_id: author.id, category_id: category.id})
    [transaction] = Repo.all(ProductTransaction)

    routes = [
      {"/guides-overview/products", product.id},
      {"/guides-overview/product-locations", location.id},
      {"/guides-overview/product_transactions", transaction.id},
      {"/guides-overview/posts", post.id},
      {"/guides-overview/authors", author.id},
      {"/guides-overview/categories", category.id}
    ]

    for {route, id} <- routes, suffix <- ["", "/new", "/#{id}/show", "/#{id}/edit"] do
      assert {:ok, view, _} = live(conn, route <> suffix)
      assert has_element?(view, ".auix-index-container")
    end
  end
end
