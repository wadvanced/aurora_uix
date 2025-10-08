defmodule Aurora.UixWeb.Test.ManualUITest do
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Aurora.UixWeb.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductLocation
  alias Aurora.Uix.Test.Inventory.ProductTransaction
  alias Aurora.Uix.TreePath

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

  @auix_layout_opts link_prefix: "manual-ui-"

  @auix_layout_trees %TreePath{
    tag: :form,
    name: :product,
    inner_elements: [
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{tag: :field, name: :reference},
          %TreePath{tag: :field, name: :name},
          %TreePath{tag: :field, name: :description}
        ]
      },
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{
            tag: :field,
            name: :quantity_at_hand
          },
          %TreePath{
            tag: :field,
            name: :quantity_initial
          }
        ]
      },
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{tag: :field, name: :list_price},
          %TreePath{tag: :field, name: :rrp}
        ]
      },
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{
            tag: :field,
            name: :product_location_id
          }
        ]
      },
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{
            tag: :field,
            name: :product_transactions
          }
        ]
      }
    ]
  }

  @auix_layout_trees %TreePath{
    tag: :show,
    name: :product,
    inner_elements: [
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{tag: :field, name: :reference},
          %TreePath{tag: :field, name: :name},
          %TreePath{tag: :field, name: :description}
        ]
      },
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{
            tag: :field,
            name: :quantity_at_hand
          },
          %TreePath{
            tag: :field,
            name: :quantity_initial
          }
        ]
      },
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{
            tag: :field,
            name: :product_location_id
          }
        ]
      },
      %TreePath{
        tag: :inline,
        inner_elements: [
          %TreePath{
            tag: :field,
            name: :product_transactions
          }
        ]
      }
    ]
  }

  auix_create_ui do
    index_columns(:product, [:reference, :name, :description, :product_location_id],
      order_by: :name
    )
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/manual-ui-products")
    assert html =~ "Listing Products"
    assert html =~ "New Product"

    assert view
           |> element("a[name='auix-new-product']")
           |> render_click() =~ "New Product"

    refute has_element?(view, "div[name='auix-column-label']", "Quantity at hand")
  end

  test "Test validate the fields displayed in NEW", %{conn: conn} do
    delete_all_sample_data()
    {:ok, view, html} = live(conn, "/manual-ui-products/new")

    assert html =~ "New Product"

    assert has_element?(view, "input[name='product[reference]']")
    assert has_element?(view, "input[name='product[name]']")
    assert has_element?(view, "input[name='product[description]']")
    assert has_element?(view, "input[name='product[quantity_at_hand]']")
    assert has_element?(view, "input[name='product[quantity_initial]']")
    assert has_element?(view, "input[name='product[list_price]']")
    assert has_element?(view, "input[name='product[rrp]']")
    assert has_element?(view, "select[name='product[product_location_id]']")
    assert has_element?(view, "#auix-one_to_many-product__product_transactions-form")
  end

  test "Test validate the fields displayed in SHOW", %{conn: conn} do
    delete_all_sample_data()

    product_id =
      3
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    {:ok, view, html} = live(conn, "/manual-ui-products/#{product_id}")

    assert html =~ "Product"

    assert has_element?(view, "input[name='reference']")
    assert has_element?(view, "input[name='name']")
    assert has_element?(view, "input[name='description']")
    assert has_element?(view, "input[name='quantity_at_hand']")
    assert has_element?(view, "input[name='quantity_initial']")
    refute has_element?(view, "input[name='list_price']")
    refute has_element?(view, "input[name='rrp']")
    assert has_element?(view, "select[name='product_location_id']")
    assert has_element?(view, "div[name='auix-one_to_many-product']")
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    delete_all_sample_data()
    {:ok, view, html} = live(conn, "/manual-ui-products/new")

    assert html =~ "New Product"

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

    {:ok, _view, new_html} = live(conn, "/manual-ui-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end
end
