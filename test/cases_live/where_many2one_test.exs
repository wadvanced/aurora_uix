defmodule Aurora.Uix.Test.Web.WhereMany2OneTest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case
  use Aurora.Uix.Test.Web, :aurora_uix_for_test

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductLocation
  alias Aurora.Uix.Test.Inventory.ProductTransaction

  @test_names [
    "test-name-many2-14",
    "test-name-many2-13",
    "test-name-many2-12",
    "test-name-many2-11",
    "test-name-many2-10",
    "test-name-many2-09",
    "test-name-many2-08"
  ]

  auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation do
    field(:products, omitted: true)
  end

  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction) do
    field(:product, option_label: :name)
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product) do
    field(:product_location_id,
      option_label: :name,
      order_by: [desc: :name],
      where: [{:name, :between, "test-name-many2-08", "test-name-many2-14"}]
    )
  end

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "where-many_to_one-") do
    edit_layout :product_location do
      inline([:reference, :name, :type])
    end

    edit_layout :product do
      stacked([
        :reference,
        :name,
        :description,
        :quantity_initial,
        :product_location_id
      ])
    end
  end

  test "Test selector where", %{conn: conn} do
    location_id =
      20
      |> create_sample_product_locations(:many2)
      |> get_in(["id_1", Access.key!(:id)])

    product_id =
      1
      |> create_sample_products(:test, %{product_location_id: location_id})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, _view, html} =
      live(
        conn,
        "/where-many_to_one-products/#{product_id}/edit"
      )

    assert html
           |> Floki.find(
             "select[id^='auix-field-product-product_location_id-'][id$='-form'] option"
           )
           |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
           |> Enum.filter(&String.starts_with?(&1, "test-name-many2-")) == @test_names
  end
end
