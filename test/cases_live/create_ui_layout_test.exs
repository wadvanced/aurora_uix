defmodule AuroraUixTestWeb.CreateUILayoutTest do
  use AuroraUixTest.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link_prefix: "create-ui-layout-" do
      edit_layout :product, [] do
        inline([:reference, :name, :description])
        inline([:quantity_at_hand, :quantity_initial])
        inline([:list_price, :rrp])
      end
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, html} = live(conn, "/create-ui-layout-products")
    assert html =~ "Listing Products"
    assert html =~ "New Product"

    assert view
           |> element("#auix-new-product")
           |> render_click() =~ "New Product"
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/create-ui-layout-products/new")

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

    {:ok, _view, new_html} = live(conn, "/create-ui-layout-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end

  test "Test main links", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/create-ui-layout-products")
    Process.sleep(500)
    view
    |> tap(&assert has_element?(&1, "#auix-new-product"))
    |> tap(&assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='show-product']"))
    |> tap(&assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='edit-product']"))
    |> tap(
      &assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='delete-product']")
    )
  end

  test "Test new link", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(&assert has_element?(&1, "#auix-new-product"))
    |> element("#auix-new-product")
    |> render_click()

    view
    |> tap(&assert has_element?(&1, "#auix-save-product"))
    |> tap(
      &assert has_element?(&1, "div#auix-product-modal-container div button[phx-click*='exec']")
    )
  end

  test "Test main show link", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(&assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='show-product']"))
    |> element("tr[id^='products']:nth-of-type(1)  a[name='show-product']")
    |> render_click()
    |> follow_redirect(conn)
    |> elem(1)
    |> tap(&assert has_element?(&1, "#auix-edit-product"))
    |> tap(&assert has_element?(&1, "div#auix-show-navigate-back a:nth-of-type(1)"))
  end

  test "Test show link - edit link", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> element("tr[id^='products']:nth-of-type(1)  a[name='show-product']")
    |> render_click()
    |> follow_redirect(conn)
    |> elem(1)
    |> tap(&assert has_element?(&1, "#auix-edit-product"))
    |> element("#auix-edit-product")
    |> render_click()
    |> tap(&assert &1 =~ "auix-save-product")
  end

  test "Test main edit link", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(&assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='edit-product']"))
    |> element("tr[id^='products']:nth-of-type(1)  a[name='edit-product']")
    |> render_click()
    |> tap(&assert &1 =~ "auix-save-product")
  end

  test "Test main delete link", %{conn: conn} do
    # Can only test up to the data-confirm existance
    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(
      &assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='delete-product']")
    )
    |> element("tr[id^='products']:nth-of-type(1)  a[name='delete-product']")
    |> render()
    |> Floki.parse_document!()
    |> tap(&assert &1 |> Floki.attribute("data-confirm") |> List.first() =~ "Are you sure?")
    |> tap(&assert &1 |> Floki.attribute("phx-click") |> List.first() =~ ~r".+event.+delete")
  end
end
