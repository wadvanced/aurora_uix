defmodule Aurora.UixWeb.Test.ManualResourceTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  @auix_resource_metadata %{
    product_location: %Aurora.Uix.Resource{
      name: :product_location,
      schema: Aurora.Uix.Test.Inventory.ProductLocation,
      context: Aurora.Uix.Test.Inventory,
      fields: %{
        name: %Aurora.Uix.Field{
          key: :name,
          name: "name",
          label: "Name",
          placeholder: "Name"
        },
        type: %Aurora.Uix.Field{
          key: :type,
          name: "type",
          label: "Type",
          placeholder: "Type"
        },
        reference: %Aurora.Uix.Field{
          key: :reference,
          name: "reference",
          label: "Reference",
          placeholder: "Reference"
        }
      }
    },
    product_transaction: %Aurora.Uix.Resource{
      name: :product_transaction,
      schema: Aurora.Uix.Test.Inventory.ProductTransaction,
      context: Aurora.Uix.Test.Inventory,
      fields: %{
        type: %Aurora.Uix.Field{
          key: :type,
          name: "type",
          label: "Type",
          placeholder: "Type"
        },
        product: %Aurora.Uix.Field{
          key: :product,
          type: :many_to_one_association,
          name: "product",
          label: "",
          placeholder: "",
          data: %{
            resource: :product,
            owner_key: :product_id,
            related: Aurora.Uix.Test.Inventory.Product,
            related_key: :id
          }
        },
        quantity: %Aurora.Uix.Field{
          key: :quantity,
          type: :decimal,
          html_type: :number,
          name: "quantity",
          label: "Quantity",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        },
        cost: %Aurora.Uix.Field{
          key: :cost,
          type: :decimal,
          html_type: :number,
          name: "cost",
          label: "Cost",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        },
        product_id: %Aurora.Uix.Field{
          key: :product_id,
          type: :binary_id,
          html_type: :select,
          name: "product_id",
          label: "Product",
          placeholder: "Product_id",
          data: %{
            resource: :product,
            owner_key: :product_id,
            related: Aurora.Uix.Test.Inventory.Product,
            related_key: :id
          }
        }
      }
    },
    product: %Aurora.Uix.Resource{
      name: :product,
      schema: Aurora.Uix.Test.Inventory.Product,
      context: Aurora.Uix.Test.Inventory,
      fields: %{
        name: %Aurora.Uix.Field{
          key: :name,
          name: "name",
          label: "Name",
          placeholder: "Name"
        },
        status: %Aurora.Uix.Field{
          key: :status,
          name: "status",
          label: "Status",
          placeholder: "Status"
        },
        length: %Aurora.Uix.Field{
          key: :length,
          type: :decimal,
          html_type: :number,
          name: "length",
          label: "Length",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        },
        description: %Aurora.Uix.Field{
          key: :description,
          name: "description",
          label: "Description",
          placeholder: "Description"
        },
        reference: %Aurora.Uix.Field{
          key: :reference,
          name: "reference",
          label: "Reference",
          placeholder: "Reference"
        },
        image: %Aurora.Uix.Field{
          key: :image,
          type: :binary,
          name: "image",
          label: "Image",
          placeholder: "Image"
        },
        width: %Aurora.Uix.Field{
          key: :width,
          type: :decimal,
          html_type: :number,
          name: "width",
          label: "Width",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        },
        product_transactions: %Aurora.Uix.Field{
          key: :product_transactions,
          type: :one_to_many_association,
          name: "product_transactions",
          label: "",
          placeholder: "",
          filterable?: false,
          data: %{
            resource: :product_transaction,
            related: Aurora.Uix.Test.Inventory.ProductTransaction,
            related_key: :product_id,
            owner_key: :id
          }
        },
        product_location_id: %Aurora.Uix.Field{
          key: :product_location_id,
          type: :binary_id,
          html_type: :select,
          name: "product_location_id",
          label: "Product location id",
          placeholder: "Product_location_id",
          data: %{
            resource: :product_location,
            owner_key: :product_location_id,
            related: Aurora.Uix.Test.Inventory.ProductLocation,
            option_label: :name,
            related_key: :id
          }
        },
        quantity_at_hand: %Aurora.Uix.Field{
          key: :quantity_at_hand,
          type: :decimal,
          html_type: :number,
          name: "quantity_at_hand",
          label: "Quantity at hand",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        },
        quantity_initial: %Aurora.Uix.Field{
          key: :quantity_initial,
          type: :decimal,
          html_type: :number,
          name: "quantity_initial",
          label: "Quantity initial",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        },
        rrp: %Aurora.Uix.Field{
          key: :rrp,
          type: :decimal,
          html_type: :number,
          name: "rrp",
          label: "Rrp",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        },
        list_price: %Aurora.Uix.Field{
          key: :list_price,
          type: :decimal,
          html_type: :number,
          name: "list_price",
          label: "List price",
          placeholder: "0",
          length: 12,
          precision: 10,
          scale: 2
        }
      }
    }
  }

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "manual-resource-" do
    index_columns(:product, [:reference, :name, :description, :product_location_id],
      order_by: :name
    )

    edit_layout :product, [] do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
      inline([:product_location_id])
      inline([:product_transactions])
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/manual-resource-products")
    assert html =~ "Listing Products"
    assert html =~ "New Product"

    assert view
           |> element("a[name='auix-new-product']")
           |> render_click() =~ "New Product"
  end

  test "Test ensure all fields are displayed in NEW", %{conn: conn} do
    delete_all_sample_data()
    {:ok, view, html} = live(conn, "/manual-resource-products/new")

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

  test "Test ensure all fields are displayed in SHOW", %{conn: conn} do
    delete_all_sample_data()

    product_id =
      3
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    {:ok, view, html} = live(conn, "/manual-resource-products/#{product_id}")

    assert html =~ "Product"

    assert has_element?(view, "input[name='reference']")
    assert has_element?(view, "input[name='name']")
    assert has_element?(view, "input[name='description']")
    assert has_element?(view, "input[name='quantity_at_hand']")
    assert has_element?(view, "input[name='quantity_initial']")
    assert has_element?(view, "input[name='list_price']")
    assert has_element?(view, "input[name='rrp']")
    assert has_element?(view, "select[name='product_location_id']")
    assert has_element?(view, "div[name='auix-one_to_many-product']")
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    delete_all_sample_data()
    {:ok, view, html} = live(conn, "/manual-resource-products/new")

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

    {:ok, _view, new_html} = live(conn, "/manual-resource-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end
end
