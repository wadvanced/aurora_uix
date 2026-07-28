defmodule Aurora.UixWeb.Test.AssociationOne2OneUILayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductBarcode
  alias Aurora.Uix.Repo

  # Routes for both resources are registered in test/support/app_web/routes.ex as
  # "association/one_to_one/layout/products" and ".../product_barcodes".
  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_barcode, context: Inventory, schema: ProductBarcode)

  auix_create_ui do
    edit_layout :product do
      stacked([:reference, :name, :quantity_initial, :product_barcode])
    end

    # `:product_id` is listed deliberately: the renderer must strip the child's back-reference to
    # the parent, otherwise a redundant Product selector renders inside the nested form.
    edit_layout :product_barcode do
      stacked([:code, :symbology, :registered_at, :product_id])
    end

    show_layout :product do
      stacked([:reference, :name, :product_barcode])
    end

    show_layout :product_barcode do
      stacked([:code, :symbology, :registered_at])
    end
  end

  describe "form rendering" do
    test "renders blank nested inputs on new, with no child record", %{conn: conn} do
      delete_all_inventory_data()

      {:ok, view, _html} = live(conn, "/association/one_to_one/layout/products/new")

      assert has_element?(view, "#auix-one-to-one-product_barcode-form")

      for field <- ~w(code symbology registered_at) do
        assert has_element?(view, "input[name='product[product_barcode][#{field}]']")
      end
    end

    test "strips the child's foreign key back-reference", %{conn: conn} do
      delete_all_inventory_data()

      {:ok, view, _html} = live(conn, "/association/one_to_one/layout/products/new")

      refute has_element?(view, "select[name='product[product_barcode][product_id]']")
      refute has_element?(view, "input[name='product[product_barcode][product_id]']")
    end

    test "pre-fills nested inputs and emits the hidden id on edit", %{conn: conn} do
      delete_all_inventory_data()
      [product] = create_sample_products_with_barcodes(1)

      {:ok, view, _html} =
        live(conn, "/association/one_to_one/layout/products/#{product.id}/edit")

      assert has_element?(
               view,
               "input[name='product[product_barcode][code]'][value='4006381330001']"
             )

      assert has_element?(view, "input[name='product[product_barcode][id]'][type='hidden']")
    end
  end

  describe "writing through the parent form" do
    test "creates the product and its barcode in one submit", %{conn: conn} do
      delete_all_inventory_data()

      {:ok, view, _html} = live(conn, "/association/one_to_one/layout/products/new")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "nested_ref",
          "name" => "Nested product",
          "quantity_initial" => "3",
          "product_barcode" => %{
            "code" => "5901234123457",
            "symbology" => "EAN-13",
            "registered_at" => "2026-03-04"
          }
        }
      })
      |> render_submit()

      product =
        Product
        |> Repo.all()
        |> List.first()
        |> Repo.preload(:product_barcode)

      assert product.name == "Nested product"
      assert product.product_barcode.code == "5901234123457"
      assert product.product_barcode.registered_at == ~D[2026-03-04]
      assert product.product_barcode.product_id == product.id
    end

    test "updates the existing barcode in place rather than adding a second", %{conn: conn} do
      delete_all_inventory_data()
      [product] = create_sample_products_with_barcodes(1)

      {:ok, view, _html} =
        live(conn, "/association/one_to_one/layout/products/#{product.id}/edit")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "product_barcode" => %{"code" => "9781234567897", "symbology" => "UPC-A"}
        }
      })
      |> render_submit()

      barcodes = Repo.all(ProductBarcode)

      assert Enum.count(barcodes) == 1
      assert List.first(barcodes).code == "9781234567897"
      assert List.first(barcodes).product_id == product.id
    end
  end

  describe "show rendering" do
    test "renders the child read-only", %{conn: conn} do
      delete_all_inventory_data()
      [product] = create_sample_products_with_barcodes(1)

      {:ok, view, _html} =
        live(conn, "/association/one_to_one/layout/products/#{product.id}/show")

      assert has_element?(view, "#auix-one-to-one-product_barcode-show")

      assert view
             |> element("#auix-one-to-one-product_barcode-show")
             |> render() =~ "4006381330001"

      # `:show` displays fields as disabled inputs, so read-only means every input is disabled.
      refute has_element?(view, "#auix-one-to-one-product_barcode-show input:not([disabled])")
    end

    test "renders the empty message when there is no child", %{conn: conn} do
      delete_all_inventory_data()

      product =
        1
        |> create_sample_products()
        |> Map.values()
        |> List.first()

      {:ok, view, _html} =
        live(conn, "/association/one_to_one/layout/products/#{product.id}/show")

      assert has_element?(
               view,
               "#auix-one-to-one-product_barcode-show .auix-one-to-one-empty-msg"
             )
    end
  end

  describe "index" do
    test "never renders the association as a column", %{conn: conn} do
      delete_all_inventory_data()
      create_sample_products_with_barcodes(2)

      {:ok, view, _html} = live(conn, "/association/one_to_one/layout/products")

      refute view
             |> element("table.auix-items-table thead")
             |> render() =~ "Product Barcode"
    end
  end
end
