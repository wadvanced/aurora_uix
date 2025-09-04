defmodule Aurora.Uix.Test.Web.CreateUILayoutTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case
  use Aurora.Uix.CoreComponentsImporter
  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  @spec page_title(map()) :: term()
  def page_title(assigns) do
    ~H"Details for {@auix.name}"
  end

  @spec edit_title(map()) :: term()
  def edit_title(%{auix: %{form: _form}} = assigns),
    do: ~H"Modify {@auix.name}: #{@auix.form[:reference].value} "

  def edit_title(%{auix: %{entity: nil}} = assigns), do: ~H"Modify {@auix.name}"

  def edit_title(%{auix: %{entity: _entity}} = assigns),
    do: ~H"Modify {@auix.name}: {@auix.entity.reference}"

  @spec new_subtitle(map()) :: term()
  def new_subtitle(assigns),
    do: ~H"Please fill <strong>{@auix.name}'s</strong> values properly"

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "create-ui-layout-" do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand],
      page_title: "The Products Listing"
    )

    edit_layout :product,
      new_title: "Add a Product",
      new_subtitle: &__MODULE__.new_subtitle/1,
      edit_title: &__MODULE__.edit_title/1,
      edit_subtitle: "Entries are validated before saving" do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end

    show_layout :product, page_title: &__MODULE__.page_title/1, page_subtitle: nil do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/create-ui-layout-products")
    assert html =~ "The Products Listing"
    assert html =~ "New Product"

    assert view
           |> element("a[name='auix-new-product']")
           |> render_click() =~ "New Product"
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    delete_all_sample_data()
    {:ok, view, html} = live(conn, "/create-ui-layout-products/new")

    assert html =~ "Please fill <strong"
    assert html =~ "Product&#39;s</strong> values properly"

    assert view
           |> element("div#auix-product-modal header")
           |> render() =~ "Add a Product"

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

    assert new_html =~ "The Products Listing"
    assert new_html =~ "test-first"
  end

  test "Test index layout", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, _view, html} = live(conn, "/create-ui-layout-products")

    assert html =~ "The Products Listing"

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("thead tr th [name='auix-column-label']")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "",
             "Id",
             "Reference",
             "Name",
             "Description",
             "Quantity at hand"
           ]
  end

  test "Test main links", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(&assert has_element?(&1, "a[name='auix-new-product']"))
    |> tap(
      &assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='auix-show-product']")
    )
    |> tap(
      &assert has_element?(
                &1,
                "tr[id^='products']:nth-of-type(1)  a[name='auix-edit-product']"
              )
    )
    |> tap(
      &assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='auix-delete-product']")
    )
  end

  test "Test new link", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(&assert has_element?(&1, "a[name='auix-new-product']"))
    |> element("a[name='auix-new-product']")
    |> render_click()

    view
    |> tap(&assert has_element?(&1, "[name='auix-save-product']"))
    |> tap(
      &assert has_element?(&1, "div#auix-product-modal-container div button[phx-click*='exec']")
    )
  end

  test "Test main show link", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(
      &assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='auix-show-product']")
    )
    |> element("tr[id^='products']:nth-of-type(1)  a[name='auix-show-product']")
    |> render_click()
    |> follow_redirect(conn)
    |> elem(1)
    |> tap(&assert render(&1) =~ "Details for Product")
    ## Shouldn't show since the show layout has a nil value for page_subtitle
    |> tap(&refute render(&1) =~ " Detail\n")
    |> tap(&assert has_element?(&1, "a[name='auix-edit-product']"))
    |> tap(&assert has_element?(&1, "div[name='auix-show-navigate-back'] a:nth-of-type(1)"))
  end

  test "Test show link - edit link", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> element("tr[id^='products']:nth-of-type(1)  a[name='auix-show-product']")
    |> render_click()
    |> follow_redirect(conn)
    |> elem(1)
    |> tap(&assert has_element?(&1, "a[name='auix-edit-product']"))
    |> element("a[name='auix-edit-product']")
    |> render_click()
    |> tap(&assert &1 =~ "auix-save-product")
  end

  test "Test main edit link", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(
      &assert has_element?(
                &1,
                "tr[id^='products']:nth-of-type(1)  a[name='auix-edit-product']"
              )
    )
    |> element("tr[id^='products']:nth-of-type(1)  a[name='auix-edit-product']")
    |> render_click()
    |> tap(&assert &1 =~ "auix-save-product")

    assert view
           |> element("div#auix-product-modal header")
           |> render() =~ "Modify Product: #item_"

    assert view
           |> element("div#auix-product-modal header")
           |> render() =~
             "Entries are validated before saving"
  end

  test "Test main delete link", %{conn: conn} do
    delete_all_sample_data()
    # Can only test up to the data-confirm existance
    create_sample_products(5, :test)

    {:ok, view, _html} = live(conn, "/create-ui-layout-products")

    view
    |> tap(
      &assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='auix-delete-product']")
    )
    |> element("tr[id^='products']:nth-of-type(1)  a[name='auix-delete-product']")
    |> render()
    |> LazyHTML.from_fragment()
    |> tap(&assert &1 |> LazyHTML.attribute("data-confirm") |> List.first() =~ "Are you sure?")
    |> tap(&assert &1 |> LazyHTML.attribute("phx-click") |> List.first() =~ ~r".+event.+delete")
  end
end
