defmodule Aurora.UixWeb.Test.IndexCardGridTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  @spec card_title(map()) :: binary()
  def card_title(assigns), do: "#" <> assigns.entity.reference

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns :product, [:reference, :name, :description, :product_location] do
      card title: &__MODULE__.card_title/1, subtitle: "Product", show_on: :all do
        inline([:name, :product_location])
      end
    end
  end

  test "show_on: :all shows the cards alone", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(3, :test)
    {:ok, view, _html} = live(conn, "/index-card-grid-products")

    m = "#auix-table-index-card-grid-products-index-mobile"

    assert has_element?(view, "#{m} [name='auix-card-title']", "#item_test-1")
    assert has_element?(view, "#{m} [name='auix-card-subtitle']", "Product")
    refute has_element?(view, "[name='auix-items-table']")
    assert has_element?(view, ".auix-items-cards [name='auix-items-card']")
    assert has_element?(view, ".auix-index-sort-action.auix-index-sort-action--always")
    assert has_element?(view, "#auix-sort-form-product option[value='description']")

    assert has_element?(
             view,
             "#{m} [name='auix-card-body'] .auix-items-card-item-label",
             "Name"
           )

    refute has_element?(
             view,
             "#{m} [name='auix-card-body'] .auix-items-card-item-label",
             "Product Location"
           )
  end
end
