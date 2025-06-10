defmodule Aurora.Uix.Test.Web.AssociationOne2ManyUILayoutTest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product
    alias Aurora.Uix.Test.Inventory.ProductLocation
    alias Aurora.Uix.Test.Inventory.ProductTransaction

    auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
    auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(link_prefix: "association-one_to_many-layout-") do
      edit_layout :product do
        stacked([:reference, :name, :description, :quantity_initial, :product_transactions])
      end
    end
  end

  test "Test one-to-many relationship UI workflow", %{conn: conn} do
    # Create sample data with 1 product
    product_id =
      3
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    # Start by visiting the products index
      {:ok, view_1, html} = live(conn, "/association-one_to_many-layout-products")
      assert html =~ "Listing Products"

    # Verify index shows the products
    assert has_element?(view_1, "tr[id^='products']")

    # Click on the first product to view details and follow the navigation
    {:ok, view_2, _html} =
      view_1
      |> element("tr[id^='products-#{product_id}'] a[name='show-product']")
      |> render_click()
      |> follow_redirect(conn)

    # Verify product details page includes transactions section
    assert has_element?(view_2, "#auix-one_to_many-product__product_transactions-show")

    # Verify transactions table exists and shows entries
    assert has_element?(view_2, "#auix-one_to_many-product__product_transactions-show table")

    # Click edit button to enable transactions management
    view_2
    |> element("a[id='auix-edit-product']")
    |> render_click()

    # Create multiple transactions with different values
    transactions = [
      %{quantity: 10, type: "in", cost: 13.4},
      %{quantity: 15, type: "out", cost: 14.5},
      %{quantity: 20, type: "in", cost: 15.6}
    ]

    view_3 =
      Enum.reduce(transactions, view_2, fn transaction, acc_view ->
        # Add
        {:ok, new_view, _html} =
          acc_view
          |> element("#auix-new-product__product_transactions-form")
          |> render_click()
          |> follow_redirect(conn)

        # Verify modal appears for new transaction and the parent id field is correctly set
        assert has_element?(new_view, "#auix-product_transaction-modal")

        assert new_view
               |> element("#auix-field-product_id-form")
               |> render() =~
                 "#{product_id}"

        # Fill and submit new transaction form
        {:ok, new_view, _html} =
          new_view
          |> form("#auix-product_transaction-form", %{
            "product_transaction[quantity]" => "#{transaction.quantity}",
            "product_transaction[type]" => transaction.type,
            "product_transaction[cost]" => transaction.cost
          })
          |> render_submit()
          |> follow_redirect(conn)

        new_view
      end)

    # Verify all transactions appear in the list
    Enum.each(transactions, fn transaction ->
      assert has_element?(
               view_3,
               "#auix-one_to_many-product__product_transactions-show table tr",
               "#{transaction.quantity}.000"
             )
    end)

    # Get one transaction to edit
    transaction_id =
      product_id
      |> Inventory.get_product!()
      |> Map.get(:product_transactions)
      |> List.first()
      |> Map.get(:id)

    # Test editing a transaction
    {:ok, view_4, _html} =
      view_3
      |> element("#auix-edit-#{transaction_id}-form")
      |> render_click()
      |> follow_redirect(conn)

    # Verify edit modal appears
    assert has_element?(view_4, "#auix-product_transaction-modal")

    assert view_4
           |> element("#auix-field-product_id-form")
           |> render() =~
             "#{product_id}"

    # Submit edited transaction
    {:ok, view_5, _html} =
      view_4
      |> form("#auix-product_transaction-form", %{
        "product_transaction[quantity]" => "444",
        "product_transaction[type]" => "out",
        "product_transaction[cost]" => 11.5
      })
      |> render_submit()
      |> follow_redirect(conn)

    # Verify changes are reflected
    assert has_element?(
             view_5,
             "#auix-one_to_many-product__product_transactions-show table tr",
             "444.000"
           )

    # Test deleting a transaction
    # The data-confirm will trigger browser's native confirm dialog
    {:ok, view_6, _html} =
      view_5
      |> element(
        "#auix-one_to_many-product__product_transactions-show table a[phx-click*='#{transaction_id}'][name='auix-delete-product__product_transaction'][data-confirm='Are you sure?']"
      )
      |> render_click()
      |> follow_redirect(conn)

    # Verify transaction is removed
    refute has_element?(
             view_6,
             "#auix-one_to_many-product__product_transactions-show table tr",
             "444.0000"
           )
  end

  test "Test one-to-many relationship UI workflow-2", %{conn: conn} do
    # Create sample data with 1 product
    product_id =
      3
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    conn
    |> visit_products_index()
    |> select_product(product_id)
    |> edit_product()
    |> create_multiple_transactions(product_id)
    |> edit_single_transaction(product_id)
    |> delete_single_transaction(product_id)
  end

  defp visit_products_index(conn) do
    {:ok, view, html} = live(conn, "/association-one_to_many-layout-products")
    assert html =~ "Listing Products"

    # Verify index shows the products
    assert has_element?(view, "tr[id^='products']")

    {conn, view}
  end

  defp select_product({conn, view}, product_id) do
    {:ok, view, _html} =
      view
      |> element("tr[id^='products-#{product_id}'] a[name='show-product']")
      |> render_click()
      |> follow_redirect(conn)

    # Verify product details page includes transactions section
    assert has_element?(view, "#auix-one_to_many-product__product_transactions-show")

    # Verify transactions table exists and shows entries
    assert has_element?(view, "#auix-one_to_many-product__product_transactions-show table")

    {conn, view}
  end

  defp edit_product({conn, view}) do
    view
    |> element("a[id='auix-edit-product']")
    |> render_click()

    {conn, view}
  end

  defp create_multiple_transactions({conn, view}, product_id) do
    transactions = [
      %{quantity: 10, type: "in", cost: 13.4},
      %{quantity: 15, type: "out", cost: 14.5},
      %{quantity: 20, type: "in", cost: 15.6}
    ]

    new_view =
      Enum.reduce(transactions, view, fn transaction, acc_view ->
        # Add
        {:ok, new_view, _html} =
          acc_view
          |> element("#auix-new-product__product_transactions-form")
          |> render_click()
          |> follow_redirect(conn)

        # Verify modal appears for new transaction and the parent id field is correctly set
        assert has_element?(new_view, "#auix-product_transaction-modal")

        assert new_view
               |> element("#auix-field-product_id-form")
               |> render() =~
                 "#{product_id}"

        # Fill and submit new transaction form
        {:ok, new_view, _html} =
          new_view
          |> form("#auix-product_transaction-form", %{
            "product_transaction[quantity]" => "#{transaction.quantity}",
            "product_transaction[type]" => transaction.type,
            "product_transaction[cost]" => transaction.cost
          })
          |> render_submit()
          |> follow_redirect(conn)

        new_view
      end)

    # Verify all transactions appear in the list
    Enum.each(transactions, fn transaction ->
      assert has_element?(
               new_view,
               "#auix-one_to_many-product__product_transactions-show table tr",
               "#{transaction.quantity}.000"
             )
    end)

    {conn, new_view}
  end

  defp edit_single_transaction({conn, view}, product_id) do
    transaction_id = product_id
      |> get_single_transaction()
      |> Map.get(:id)

    # Test editing a transaction
    {:ok, edit_view, _html} =
      view
      |> element("#auix-edit-#{transaction_id}-form")
      |> render_click()
      |> follow_redirect(conn)

    # Verify edit modal appears
    assert has_element?(edit_view, "#auix-product_transaction-modal")

    assert edit_view
           |> element("#auix-field-product_id-form")
           |> render() =~
             "#{product_id}"

    # Submit edited transaction
    {:ok, submitted_view, _html} =
      edit_view
      |> form("#auix-product_transaction-form", %{
        "product_transaction[quantity]" => "444",
        "product_transaction[type]" => "out",
        "product_transaction[cost]" => 11.5
      })
      |> render_submit()
      |> follow_redirect(conn)

        # Verify changes are reflected
    assert has_element?(
             submitted_view,
             "#auix-one_to_many-product__product_transactions-show table tr",
             "444.000"
           )
    {conn, submitted_view}
  end

  defp delete_single_transaction({conn, view}, product_id) do
    transaction = get_single_transaction(product_id)

    # Assert transaction exists
    assert has_element?(
             view,
             "#auix-one_to_many-product__product_transactions-show table tr",
             "#{transaction.id}"
           )

    # The data-confirm will trigger browser's native confirm dialog
    {:ok, deleted_view, _html} =
      view
      |> element(
        "#auix-one_to_many-product__product_transactions-show table a[phx-click*='#{transaction.id}'][name='auix-delete-product__product_transaction'][data-confirm='Are you sure?']"
      )
      |> render_click()
      |> follow_redirect(conn)

    # Verify transaction is removed
    refute has_element?(
             deleted_view,
             "#auix-one_to_many-product__product_transactions-show table tr",
             "#{transaction.id}"
           )
    {conn, deleted_view}
  end

  defp get_single_transaction(product_id) do
    product_id
      |> Inventory.get_product!(preload: [:product_transactions], order_by: [:id])
      |> Map.get(:product_transactions)
      |> List.first()
  end
end
