defmodule Aurora.UixWeb.Test.CreateUIDefaultLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui()

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/create-ui-default-layout-products")
    assert html =~ "Listing Products"
    assert html =~ "New Product"

    assert view
           |> element("a[name='auix-new-product']")
           |> render_click() =~ "New Product"
  end

  test "Test show default options", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test)
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, _view, html} = live(conn, "/create-ui-default-layout-products/#{product_id}")

    html
    |> tap(&assert &1 =~ "Product\n")
    |> tap(&assert &1 =~ " Details\n")
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = live(conn, "/create-ui-default-layout-products/new")

    assert view
           |> element("div#auix-product-form-modal header")
           |> render() =~ "New Product"

    assert view
           |> element("div#auix-product-form-modal header")
           |> render() =~ "Creates a new <strong>Product</strong> record in your database"

    assert view
           |> form("#auix-product-form",
             product: %{reference: "test-first", name: "This is the first test"}
           )
           |> render_change() =~ "can&#39;t be blank"

    view
    |> form("#auix-product-form",
      product: %{quantity_initial: 11}
    )
    |> render_submit()

    {:ok, _view, new_html} = live(conn, "/create-ui-default-layout-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end

  test "Check field, stacked order", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/create-ui-default-layout-products/new")

    __MODULE__
    |> resource_configs()
    |> get_in([Access.key!(:product), Access.key!(:fields_order)])
    |> assert_stacked_order(html)
  end

  test "Test main edit link", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(5, :test)

    {:ok, view, _html} = live(conn, "/create-ui-default-layout-products")

    view
    |> tap(
      &assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='auix-edit-product']")
    )
    |> element("tr[id^='products']:nth-of-type(1)  a[name='auix-edit-product']")
    |> render_click()
    |> tap(&assert &1 =~ "auix-save-product")

    assert view
           |> element("div#auix-product-form-modal header")
           |> render() =~ "Edit Product"

    assert view
           |> element("div#auix-product-form-modal header")
           |> render() =~
             "Use this form to manage <strong>Products</strong> records in your database"
  end

  @spec assert_stacked_order(list, binary) :: :ok
  defp assert_stacked_order(fields, html) do
    inputs =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query(
        "form#auix-product-form div.auix-form-container>div.auix-stacked-container input:not([type='hidden'])"
      )
      |> Enum.map(fn input ->
        input
        |> LazyHTML.attribute("name")
        |> List.first()
        |> String.replace("product[", "")
        |> String.replace("]", "")
      end)

    fields_as_string = Enum.map(fields, &to_string/1)
    assert_values_order(fields_as_string, inputs)
  end
end
