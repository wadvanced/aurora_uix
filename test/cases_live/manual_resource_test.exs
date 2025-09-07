defmodule Aurora.Uix.Test.Web.ManualResourceTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  @auix_resource_metadata %{
    product_location: %Aurora.Uix.Resource{
      name: :product_location,
      schema: Aurora.Uix.Test.Inventory.ProductLocation,
      context: Aurora.Uix.Test.Inventory,
      fields: %{
        id: %Aurora.Uix.Field{
          key: :id,
          type: :binary_id,
          name: "id",
          label: "Id",
          placeholder: "Id",
          html_id: "auix-field-product_location-id-33",
          disabled: true
        },
        name: %Aurora.Uix.Field{
          key: :name,
          name: "name",
          label: "Name",
          placeholder: "Name",
          html_id: "auix-field-product_location-name-35"
        },
        type: %Aurora.Uix.Field{
          key: :type,
          name: "type",
          label: "Type",
          placeholder: "Type",
          html_id: "auix-field-product_location-type-36"
        },
        reference: %Aurora.Uix.Field{
          key: :reference,
          name: "reference",
          label: "Reference",
          placeholder: "Reference",
          html_id: "auix-field-product_location-reference-34"
        }
      }
    },
    product_transaction: %Aurora.Uix.Resource{
      name: :product_transaction,
      schema: Aurora.Uix.Test.Inventory.ProductTransaction,
      context: Aurora.Uix.Test.Inventory,
      fields: %{
        id: %Aurora.Uix.Field{
          key: :id,
          type: :binary_id,
          name: "id",
          label: "Id",
          placeholder: "Id",
          html_id: "auix-field-product_transaction-id-1",
          disabled: true
        },
        type: %Aurora.Uix.Field{
          key: :type,
          name: "type",
          label: "Type",
          placeholder: "Type",
          html_id: "auix-field-product_transaction-type-2"
        },
        product: %Aurora.Uix.Field{
          key: :product,
          type: :many_to_one_association,
          html_type: :many_to_one_association,
          name: "product",
          label: "",
          placeholder: "",
          html_id: "auix-field-product_transaction-product-33",
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
          scale: 2,
          html_id: "auix-field-product_transaction-quantity-3"
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
          scale: 2,
          html_id: "auix-field-product_transaction-cost-4"
        },
        product_id: %Aurora.Uix.Field{
          key: :product_id,
          type: :binary_id,
          html_type: :select,
          name: "product_id",
          label: "Product",
          placeholder: "Product_id",
          html_id: "auix-field-product_transaction-product_id-5",
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
        id: %Aurora.Uix.Field{
          key: :id,
          type: :binary_id,
          name: "id",
          label: "Id",
          placeholder: "Id",
          html_id: "auix-field-product-id-8",
          disabled: true
        },
        name: %Aurora.Uix.Field{
          key: :name,
          name: "name",
          label: "Name",
          placeholder: "Name",
          html_id: "auix-field-product-name-10"
        },
        status: %Aurora.Uix.Field{
          key: :status,
          name: "status",
          label: "Status",
          placeholder: "Status",
          html_id: "auix-field-product-status-27"
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
          scale: 2,
          html_id: "auix-field-product-length-22"
        },
        description: %Aurora.Uix.Field{
          key: :description,
          name: "description",
          label: "Description",
          placeholder: "Description",
          html_id: "auix-field-product-description-11"
        },
        reference: %Aurora.Uix.Field{
          key: :reference,
          name: "reference",
          label: "Reference",
          placeholder: "Reference",
          html_id: "auix-field-product-reference-9"
        },
        image: %Aurora.Uix.Field{
          key: :image,
          type: :binary,
          name: "image",
          label: "Image",
          placeholder: "Image",
          html_id: "auix-field-product-image-25"
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
          scale: 2,
          html_id: "auix-field-product-width-23"
        },
        product_transactions: %Aurora.Uix.Field{
          key: :product_transactions,
          type: :one_to_many_association,
          html_type: :one_to_many_association,
          name: "product_transactions",
          label: "",
          placeholder: "",
          html_id: "auix-field-product-product_transactions-34",
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
          html_id: "auix-field-product-product_location_id-30",
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
          scale: 2,
          html_id: "auix-field-product-quantity_at_hand-12"
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
          scale: 2,
          html_id: "auix-field-product-quantity_initial-13"
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
          scale: 2,
          html_id: "auix-field-product-rrp-18"
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
          scale: 2,
          html_id: "auix-field-product-list_price-19"
        }
      }
    }
  }

  # When you define a link in a test, add a line to test/support/app_web/router.exs
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
