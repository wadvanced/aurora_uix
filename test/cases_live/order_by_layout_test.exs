defmodule Aurora.Uix.Test.Web.OrderByLayoutTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Repo

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

  @test_references [
    "Item test_order-01",
    "Item test_order-02",
    "Item test_order-03",
    "Item test_order-04",
    "Item test_order-05",
    "Item test_order-06",
    "Item test_order-07",
    "Item test_order-08",
    "Item test_order-09",
    "Item test_order-10",
    "Item test_order-11",
    "Item test_order-12",
    "Item test_order-13",
    "Item test_order-14",
    "Item test_order-15",
    "Item test_order-16",
    "Item test_order-17",
    "Item test_order-18",
    "Item test_order-19",
    "Item test_order-20"
  ]

  auix_resource_metadata(:product,
    context: Inventory,
    schema: Product,
    order_by: :reference
  )

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "order-by-metadata-") do
    index_columns(:product, [:id, :reference, :name, :cost], order_by: :name)
  end

  test "Test UI default order", %{conn: conn} do
    create_shuffled_products(@shuffled_references)

    {:ok, _view, html} = live(conn, "/order-by-layout-products")
    assert html =~ "Listing Products"

    assert html
           |> Floki.find("table tbody tr td:nth-of-type(3)")
           |> Enum.map(&Floki.text/1)
           |> Enum.filter(&String.starts_with?(&1, "Item test_order-")) == @test_references
  end

  @spec create_shuffled_products(list()) :: :ok
  defp create_shuffled_products(reference_ids) do
    Enum.each(reference_ids, fn reference_id ->
      name = "Item #{reference_id}"
      description = "This is the item #{reference_id} as described."

      Repo.insert(%Product{
        reference: Ecto.UUID.generate() |> to_string() |> String.slice(0, 30),
        name: name,
        description: description,
        cost: :rand.uniform_real() * 100 + 123,
        quantity_initial: :rand.uniform_real() * 20
      })
    end)
  end
end
