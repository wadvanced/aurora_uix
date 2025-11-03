defmodule Aurora.UixWeb.Test.SpecialFieldsUITest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductLocation

  alias Phoenix.LiveViewTest.View

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:status,
      html_type: :select,
      data: %{
        select: %{
          opts: [
            "In stock": "in_stock",
            Discontinued: "discontinued",
            "Only available online": "online_only",
            "Only available in the store": "in_store_only"
          ],
          multiple: false
        }
      }
    )

    field(:product_location_id, option_label: :name)
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "special-fields-ui-" do
    index_columns(:product, [:id, :reference, :name, :product_location_id, :status, :inactive],
      order_by: :reference
    )

    edit_layout :product, [] do
      stacked([:reference, :name, :description, :status])
    end
  end

  test "Test select field", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/special-fields-ui-products/new")

    assert view
           |> element("[id^='auix-field-product-status-'][id$='-form']")
           |> has_element?()

    assert_option_exists(view, :status, 1, "in_stock")
    assert_option_exists(view, :status, 2, "discontinued")
    assert_option_exists(view, :status, 3, "online_only")
    assert_option_exists(view, :status, 4, "in_store_only")
  end

  test "Test filters enablement", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/special-fields-ui-products")

    refute has_element?(view, "[name='auix-filters_submit-product']")
    refute has_element?(view, "[name='auix-filters_clear-product']")

    view
    |> element("[name='auix-filter_toggle_open']")
    |> render_click()

    assert has_element?(view, "[name='auix-filters_submit-product']")
    assert has_element?(view, "[name='auix-filters_clear-product']")
  end

  test "Test filters equality", %{conn: conn} do
    {view, _locations} = prepare_filters_test(conn)

    view
    |> set_filter_change(:filter_condition, :reference, :eq)
    |> set_filter_change(:filter_from, :reference, "item_group_3d-1")

    assert view
           |> element("[name='filter_from__reference']")
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.attribute("value")
           |> List.first() == "item_group_3d-1"

    view
    |> element("[name='auix-items-table'] [name='auix-filters_submit-product']")
    |> render_click()

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("tbody tr")
           |> Enum.count() == 1
  end

  test "Test filters ge", %{conn: conn} do
    {view, _locations} = prepare_filters_test(conn)

    view
    |> set_filter_change(:filter_condition, :reference, :ge)
    |> set_filter_change(:filter_from, :reference, "item_group_3d-2")

    assert view
           |> element("[name='filter_from__reference']")
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.attribute("value")
           |> List.first() == "item_group_3d-2"

    view
    |> element("[name='auix-items-table'] [name='auix-filters_submit-product']")
    |> render_click()

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("tbody tr")
           |> Enum.count() == 3
  end

  test "Test filters between", %{conn: conn} do
    {view, _locations} = prepare_filters_test(conn)

    view
    |> set_filter_change(:filter_condition, :reference, :between)
    |> set_filter_change(:filter_from, :reference, "item_group_2b")
    |> set_filter_change(:filter_to, :reference, "item_group_3c")

    assert view
           |> element("[name='filter_to__reference']")
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.attribute("value")
           |> List.first() == "item_group_3c"

    view
    |> element("[name='auix-items-table'] [name='auix-filters_submit-product']")
    |> render_click()

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("tbody tr")
           |> Enum.count() == 16
  end

  test "Test filters for many to one", %{conn: conn} do
    {view, locations} = prepare_filters_test(conn)

    view
    |> element("[name='filter_from__product_location_id']")
    |> render() =~ locations["id_3"].name

    view
    |> set_filter_change(:filter_condition, :product_location_id, :eq)
    |> set_filter_change(:filter_from, :product_location_id, locations["id_3"].id)

    assert view
           |> element("[name='filter_from__product_location_id']")
           |> render()
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("option[selected='']")
           |> LazyHTML.attribute("value")
           |> List.first() == locations["id_3"].id

    view
    |> element("[name='auix-items-table'] [name='auix-filters_submit-product']")
    |> render_click()

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("tbody tr")
           |> Enum.count() == 7
  end

  ## PRIVATE

  @spec assert_option_exists(View.t(), atom, integer, binary) :: any
  defp assert_option_exists(view, field_name, index, value) do
    element =
      view
      |> element(
        "[id^='auix-field-product-#{field_name}-'][id$='-form'] option:nth-of-type(#{index})"
      )
      |> render()

    assert element =~ value,
           "The field `#{field_name}` at option `#{index}` does not contain the value #{value}. #{element}"
  end

  @spec prepare_filters_test(Phoenix.Conn.t()) :: View.t()
  defp prepare_filters_test(conn) do
    delete_all_sample_data()
    locations = create_sample_product_locations(5, :flt)

    create_sample_products(2, :group_1a, %{
      inactive: false,
      status: "in_stock",
      product_location_id: locations["id_3"].id
    })

    create_sample_products(1, :group_1b, %{
      inactive: false,
      status: "in_stock",
      product_location_id: locations["id_5"].id
    })

    create_sample_products(2, :group_2a, %{
      inactive: true,
      status: "discontinued",
      product_location_id: locations["id_1"].id
    })

    create_sample_products(3, :group_2b, %{
      inactive: true,
      status: "discontinued",
      product_location_id: locations["id_3"].id
    })

    create_sample_products(6, :group_3a, %{
      inactive: false,
      status: "online_only",
      product_location_id: locations["id_1"].id
    })

    create_sample_products(7, :group_3b, %{
      inactive: false,
      status: "online_only",
      product_location_id: locations["id_4"].id
    })

    create_sample_products(2, :group_3c, %{
      inactive: false,
      status: "online_only",
      product_location_id: locations["id_3"].id
    })

    create_sample_products(4, :group_3d, %{
      inactive: false,
      status: "online_only",
      product_location_id: locations["id_2"].id
    })

    {:ok, view, _html} = live(conn, "/special-fields-ui-products")

    view
    |> element("[name='auix-filter_toggle_open']")
    |> render_click()

    {view, locations}
  end

  @spec set_filter_change(View.t(), atom(), atom(), atom() | binary()) :: View.t()
  defp set_filter_change(view, element, field, value) do
    render_change(view, "index-layout-change", %{
      "_target" => ["#{element}__#{field}"],
      "#{element}__#{field}" => "#{value}"
    })

    view
  end
end

# %Aurora.Uix.Test.Inventory.Product{
#     __meta__: #Ecto.Schema.Metadata<:loaded, "products">,
#     id: "03ae4c02-ea92-485c-9fe1-53e0b4fc144c",
#     reference: "item_group_3d-4",
#     name: "Item group_3d-4",
#     description: "This is the item group_3d-4 as described.",
#     quantity_at_hand: nil,
#     quantity_initial: nil,
#     quantity_entries: nil,
#     quantity_exits: nil,
#     cost: Decimal.new("123.040000"),
#     msrp: nil,
#     rrp: nil,
#     list_price: nil,
#     discounted_price: nil,
#     weight: nil,
#     length: nil,
#     width: nil,
#     height: nil,
#     image: nil,
#     thumbnail: nil,
#     status: "online_only",
#     deleted: false,
#     inactive: false,
#     product_transactions: #Ecto.Association.NotLoaded<association :product_transactions is not loaded>,
#     product_location_id: "afdb6f1f-6f36-44db-bb7e-b954f594e18b",
#     product_location: #Ecto.Association.NotLoaded<association :product_location is not loaded>,
#     inserted_at: ~U[2025-07-29 07:19:43Z],
#     updated_at: ~U[2025-07-29 07:19:43Z]
#   }
# ]
