defmodule Aurora.UixWeb.Test.AssociationOne2ManyUILayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    edit_layout :product do
      stacked([
        :reference,
        :name,
        :description,
        :quantity_initial,
        product_transactions: [order_by: [desc: :quantity]]
      ])
    end
  end

  test "Test one-to-many relationship UI workflow", %{conn: conn} do
    delete_all_inventory_data()
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
  end

  test "Test one-to-many relationship UI workflow new Product", %{conn: conn} do
    {_conn, view, product_id} =
      conn
      |> visit_products_index()
      |> start_product_creation()

    {conn, view}
    |> create_multiple_transactions(product_id, :form)
    |> edit_single_transaction(product_id, :form)
    |> delete_single_transaction(product_id, :form)
  end

  test "Test order_by", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products_with_transactions(10, :one2)
      |> List.first()
      |> elem(1)
      |> Map.get(:id)

    expected_result =
      [order_by: [desc: :quantity], where: [product_id: product_id]]
      |> Inventory.list_product_transactions()
      |> Enum.map(&(&1 |> Map.get(:quantity) |> to_string()))

    {:ok, _view, html} = live(conn, "/association/one_to_many/layout/products/#{product_id}")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("tbody#product__product_transactions-show tr td:nth-of-type(3)")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == expected_result
  end

  @spec visit_products_index(Plug.Conn.t()) :: {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp visit_products_index(conn) do
    {:ok, view, html} = live(conn, "/association/one_to_many/layout/products")
    assert html =~ "Listing Products"

    # Verify index shows the products
    assert has_element?(view, "#auix-table-association--one_to_many--layout--products-index")

    {conn, view}
  end

  @spec start_product_creation({Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t(), integer()}
  defp start_product_creation({conn, view}) do
    unique_id = :nanosecond |> System.system_time() |> to_string()

    view
    |> element("a[name='auix-new-product']")
    |> render_click()

    {:ok, created_product_view, _html} =
      view
      |> form("#auix-product-form", %{
        "product[reference]" => "#{unique_id}",
        "product[name]" => "name-#{unique_id}",
        "product[description]" => "test item",
        "product[quantity_initial]" => 345.67
      })
      |> render_submit()
      |> follow_redirect(conn)

    product_id =
      unique_id
      |> then(&Inventory.list_products(where: [reference: &1]))
      |> List.first()
      |> Map.get(:id)

    {conn, created_product_view, product_id}
  end

  @spec select_product({Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}, integer()) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp select_product({conn, view}, product_id) do
    {:ok, view, _html} =
      view
      |> element("tr[id^='products-#{product_id}'] td:nth-child(2) a[name='auix-show-product']")
      |> render_click()
      |> follow_redirect(conn)

    # Verify product details page includes transactions section
    assert has_element?(view, "#auix-one_to_many-product__product_transactions-show")

    # Verify transactions table exists and shows entries
    assert has_element?(view, "#auix-one_to_many-product__product_transactions-show table")

    {conn, view}
  end

  @spec edit_product({Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp edit_product({conn, view}) do
    view
    |> element("a[name='auix-edit-product']")
    |> render_click()

    {conn, view}
  end

  @spec create_multiple_transactions(
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()},
          integer(),
          binary()
        ) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp create_multiple_transactions({conn, view}, product_id, suffix) do
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
          |> element("a[name='auix-new-product__product_transactions-form']")
          |> render_click()
          |> follow_redirect(conn)

        # Verify modal appears for new transaction and the parent id field is correctly set
        assert has_element?(new_view, "#auix-product_transaction-#{suffix}-modal")

        assert new_view
               |> element("[id^='auix-field-product_transaction-product_id-'][id$='-form']")
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
               "#auix-one_to_many-product__product_transactions-#{suffix} table tr",
               "#{transaction.cost}"
             )
    end)

    {conn, new_view}
  end

  @spec edit_single_transaction(
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()},
          integer(),
          binary()
        ) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp edit_single_transaction({conn, view}, product_id, suffix) do
    transaction_id =
      product_id
      |> get_single_transaction()
      |> Map.get(:id)

    # Test editing a transaction
    {:ok, edit_view, _html} =
      view
      |> element(
        "#auix-one_to_many-product__product_transactions-#{suffix} table a[name='auix-edit-product__product_transaction-#{transaction_id}']"
      )
      |> render_click()
      |> follow_redirect(conn)

    # Verify edit modal appears
    assert has_element?(edit_view, "#auix-product_transaction-#{suffix}-modal")

    assert edit_view
           |> element("[id^='auix-field-product_transaction-product_id-'][id$='-form']")
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
             "#auix-one_to_many-product__product_transactions-#{suffix} table tr",
             "444.000"
           )

    {conn, submitted_view}
  end

  @spec delete_single_transaction(
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()},
          integer(),
          binary()
        ) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp delete_single_transaction({conn, view}, product_id, suffix) do
    transaction = get_single_transaction(product_id)

    # Assert transaction exists
    assert has_element?(
             view,
             "#auix-one_to_many-product__product_transactions-#{suffix} table tr",
             "#{transaction.id}"
           )

    # The data-confirm will trigger browser's native confirm dialog
    view
    |> element(
      "#auix-one_to_many-product__product_transactions-#{suffix} table a[phx-click*='#{transaction.id}'][name^='auix-delete-product__product_transaction-'][data-confirm='Are you sure?']"
    )
    |> render_click()

    # Verify transaction is removed
    refute has_element?(
             view,
             "#auix-one_to_many-product__product_transactions-#{suffix} table tr",
             "#{transaction.id}"
           )

    {conn, view}
  end

  @spec get_single_transaction(integer()) :: Aurora.Uix.Guides.Inventory.ProductTransaction.t()
  defp get_single_transaction(product_id) do
    product_id
    |> Inventory.get_product!(preload: [:product_transactions], order_by: [:id])
    |> Map.get(:product_transactions)
    |> List.first()
  end
end
