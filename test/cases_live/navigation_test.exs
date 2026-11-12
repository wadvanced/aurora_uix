defmodule Aurora.UixWeb.Test.NavigationTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductTransaction
  alias Aurora.UixWeb.Test.NavigationHelper

  @p "/navigation-products"
  @c "/navigation-product_transactions"

  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)

    edit_layout :product do
      stacked([:reference, :name, :description, :quantity_initial, :product_transactions])
    end
  end

  setup do
    delete_all_inventory_data()
    :ok
  end

  test "index opens show, edit and new with the index pushed twice", %{conn: conn} do
    id = first_product_id(create_sample_products(3, :test), "id_test-1")
    stack = [{:patch, @p}, {:patch, @p}]

    {:ok, show_view, _html} = live(conn, @p)
    click(show_view, "tr[id^='products-#{id}'] td:nth-child(2) a[name='auix-show-product']")
    assert decoded_patch(show_view) == {"#{@p}/#{id}/show", %{}, stack}

    {:ok, edit_view, _html} = live(conn, @p)
    click(edit_view, "tr[id^='products-#{id}'] a[name='auix-edit-product']")
    assert decoded_patch(edit_view) == {"#{@p}/#{id}/edit", %{}, stack}

    {:ok, new_view, _html} = live(conn, @p)
    click(new_view, "a[name='auix-new-product']")
    assert decoded_patch(new_view) == {"#{@p}/new", %{}, stack}
  end

  test "show to show-edit and back unwinds the stack", %{conn: conn} do
    id = first_product_id(create_sample_products(3, :test), "id_test-1")

    {:ok, view, _html} = live(conn, @p)
    click(view, "tr[id^='products-#{id}'] td:nth-child(2) a[name='auix-show-product']")
    assert_patch(view)

    click(view, "#auix-product-show-modal a[name='auix-edit-product']")

    assert decoded_patch(view) ==
             {"#{@p}/#{id}/show-edit", %{},
              [{:patch, "#{@p}/#{id}/show"}, {:patch, @p}, {:patch, @p}]}

    request_close(view, "#auix-product-show_edit-modal [data-phx-component]")

    assert decoded_patch(view) == {"#{@p}/#{id}/show", %{}, [{:patch, @p}, {:patch, @p}]}

    render_click(view, "auix_route_back", %{})
    assert decoded_patch(view) == {@p, %{}, [{:patch, @p}]}
  end

  test "closing and saving a form opened from the index returns to the index", %{conn: conn} do
    id = first_product_id(create_sample_products(3, :test), "id_test-1")

    {:ok, view, _html} = live(conn, @p)
    click(view, "a[name='auix-new-product']")
    assert_patch(view)
    request_close(view, "#auix-product-new-modal [data-phx-component]")
    assert decoded_patch(view) == {@p, %{}, [{:patch, @p}]}

    {:ok, edit_view, _html} = live(conn, @p)
    click(edit_view, "tr[id^='products-#{id}'] a[name='auix-edit-product']")
    assert_patch(edit_view)

    edit_view
    |> form("#auix-product-form",
      product: %{name: "Changed", description: "d", quantity_initial: 2.0}
    )
    |> render_submit()

    assert decoded_patch(edit_view) == {@p, %{}, [{:patch, @p}]}
  end

  test "a directly loaded form or show returns to the index with an empty stack", %{conn: conn} do
    id = first_product_id(create_sample_products(3, :test), "id_test-1")

    {:ok, view, _html} = live(conn, "#{@p}/#{id}/edit")
    request_close(view, "#auix-product-edit-modal [data-phx-component]")
    assert decoded_patch(view) == {@p, %{}, []}

    {:ok, save_view, _html} = live(conn, "#{@p}/#{id}/edit")

    save_view
    |> form("#auix-product-form",
      product: %{name: "Changed", description: "d", quantity_initial: 2.0}
    )
    |> render_submit()

    assert decoded_patch(save_view) == {@p, %{}, []}

    {:ok, show_view, _html} = live(conn, "#{@p}/#{id}/show")
    render_click(show_view, "auix_route_back", %{})
    assert decoded_patch(show_view) == {@p, %{}, []}
  end

  test "the discard guard holds navigation until the change is discarded", %{conn: conn} do
    id = first_product_id(create_sample_products(3, :test), "id_test-1")

    {:ok, view, _html} = live(conn, "#{@p}/#{id}/edit")
    view |> form("#auix-product-form", product: %{name: "Dirty"}) |> render_change()
    request_close(view, "#auix-product-edit-modal [data-phx-component]")

    assert has_element?(view, "#auix-product-discard-confirm-modal")
    assert has_element?(view, "#auix-product-edit-modal")

    click(view, "button[name='auix-discard-changes']")
    assert decoded_patch(view) == {@p, %{}, []}
  end

  test "a new child navigates to the child route and back to the parent form", %{conn: conn} do
    id = with_transactions_id()

    {:ok, view, _html} = live(conn, "#{@p}/#{id}/edit")

    {:error, {:live_redirect, %{to: to}}} =
      view
      |> element("a[name='auix-new-product__product_transactions-form']")
      |> render_click()

    assert NavigationHelper.decode_route(to) ==
             {"#{@c}/new", %{"related_key" => "product_id", "parent_id" => id},
              [{:navigate, "#{@p}/#{id}/edit"}, {:patch, @p}]}

    back = {"#{@p}/#{id}/edit", %{}, [{:patch, @p}]}

    {:ok, child, _html} = live(conn, to)

    {:error, {:live_redirect, %{to: saved_to}}} =
      child
      |> form("#auix-product_transaction-form",
        product_transaction: %{quantity: "3", type: "in", cost: 1.5}
      )
      |> render_submit()

    assert NavigationHelper.decode_route(saved_to) == back

    {:ok, close_child, _html} = live(conn, to)

    {:error, {:live_redirect, %{to: closed_to}}} =
      request_close(close_child, "#auix-product_transaction-new-modal [data-phx-component]")

    assert NavigationHelper.decode_route(closed_to) == back
  end

  test "child show and edit links navigate with the parent on the stack", %{conn: conn} do
    id = with_transactions_id()

    [%{id: cid} | _] =
      Inventory.list_product_transactions(where: [product_id: id], order_by: :id)

    {:ok, view, _html} = live(conn, "#{@p}/#{id}/show")

    {:error, {:live_redirect, %{to: to}}} =
      view
      |> element("table a[name='auix-show-product__product_transaction-#{cid}']")
      |> render_click()

    assert NavigationHelper.decode_route(to) ==
             {"#{@c}/#{cid}/show", %{}, [{:navigate, "#{@p}/#{id}/show"}, {:patch, @p}]}

    {:ok, child, _html} = live(conn, to)

    {:error, {:live_redirect, %{to: back_to}}} = render_click(child, "auix_route_back", %{})

    assert NavigationHelper.decode_route(back_to) == {"#{@p}/#{id}/show", %{}, [{:patch, @p}]}

    {:ok, edit_view, _html} = live(conn, "#{@p}/#{id}/edit")

    {:error, {:live_redirect, %{to: edit_to}}} =
      edit_view
      |> element("table a[name='auix-edit-product__product_transaction-#{cid}']")
      |> render_click()

    assert NavigationHelper.decode_route(edit_to) ==
             {"#{@c}/#{cid}/edit", %{"related_key" => "product_id", "parent_id" => id},
              [{:navigate, "#{@p}/#{id}/edit"}, {:patch, @p}]}
  end

  test "a new parent with a child list continues on its edit form", %{conn: conn} do
    ref = "navigation-#{System.unique_integer([:positive])}"

    {:ok, view, _html} = live(conn, @p)
    click(view, "a[name='auix-new-product']")
    assert_patch(view)

    {:error, {:live_redirect, %{to: to}}} =
      view
      |> form("#auix-product-form",
        product: %{reference: ref, name: "n", description: "d", quantity_initial: 1.0}
      )
      |> render_submit()

    [%{id: new_id}] = Inventory.list_products(where: [reference: ref])

    assert NavigationHelper.decode_route(to) == {"#{@p}/#{new_id}/edit", %{}, [{:patch, @p}]}
  end

  test "record navigation patches without a routing stack", %{conn: conn} do
    products = create_sample_products(100, :test)

    {:ok, view, _html} = live(conn, @p)
    click(view, "table tbody tr:nth-of-type(5) td:nth-of-type(2) a")
    assert_patch(view)

    render_click(view, "read_indexed_entry", %{"page" => "1", "index" => "5"})

    assert decoded_patch(view) ==
             {"#{@p}/#{first_product_id(products, "id_test-006")}/show", %{}, :none}

    render_click(view, "read_indexed_entry", %{"page" => "2", "index" => "0"})

    assert decoded_patch(view) ==
             {"#{@p}/#{first_product_id(products, "id_test-041")}/show", %{}, :none}

    render_click(view, "auix_route_back", %{})
    assert decoded_patch(view) == {@p, %{}, []}
  end

  test "pagination pushes the index and closing a form drops the page", %{conn: conn} do
    create_sample_products(100, :test)

    {:ok, view, _html} = live(conn, @p)

    render_click(view, "pagination_next", %{})
    assert decoded_patch(view) == {@p, %{"page" => "2"}, index_entries(2)}

    render_click(view, "pagination_to_page", %{"page" => "3"})
    assert decoded_patch(view) == {@p, %{"page" => "3"}, index_entries(3)}

    click(view, "a[name='auix-new-product']")
    assert decoded_patch(view) == {"#{@p}/new", %{}, index_entries(4)}

    request_close(view, "#auix-product-new-modal [data-phx-component]")
    assert decoded_patch(view) == {@p, %{}, index_entries(3)}
  end

  test "only and except limit the mounted routes", %{conn: conn} do
    id = first_product_id(create_sample_products(1, :test), "id_test-1")

    assert {:ok, _, _} = live(conn, "/navigation-only-products")
    assert {:ok, _, _} = live(conn, "/navigation-only-products/#{id}/show")

    for path <- ["/new", "/#{id}/edit", "/#{id}/show-edit"] do
      assert route_info("/navigation-only-products#{path}") == :error
    end

    assert {:ok, _, _} = live(conn, "/navigation-except-products/#{id}/show-edit")

    for path <- ["/new", "/#{id}/edit"] do
      assert route_info("/navigation-except-products#{path}") == :error
    end
  end

  test "a forwarded routing stack is honoured on back", %{conn: conn} do
    id = first_product_id(create_sample_products(1, :test), "id_test-1")
    stack = NavigationHelper.encode_stack([{:navigate, @c}, {:patch, @p}])

    {:ok, view, _html} = live(conn, "#{@p}/#{id}/show?routing_stack=" <> stack)

    {:error, {:live_redirect, %{to: to}}} = render_click(view, "auix_route_back", %{})

    assert NavigationHelper.decode_route(to) == {@c, %{}, [{:patch, @p}]}
  end

  test "index links keep their anchor attributes", %{conn: conn} do
    id = first_product_id(create_sample_products(1, :test), "id_test-1")
    fwd = "[phx-click='auix_route_forward'][phx-value-route_type='patch']"

    {:ok, view, _html} = live(conn, @p)

    assert has_element?(
             view,
             "tr[id^='products-#{id}'] a[name='auix-show-product'][href='#']#{fwd}[phx-value-route_path='#{@p}/#{id}/show']"
           )

    assert has_element?(
             view,
             "tr[id^='products-#{id}'] a[name='auix-edit-product'][href='#']#{fwd}[phx-value-route_path='#{@p}/#{id}/edit']"
           )

    assert has_element?(
             view,
             "a[name='auix-new-product']#{fwd}[phx-value-route_path='#{@p}/new']"
           )

    refute has_element?(view, "a[name='auix-new-product'][href]")
  end

  @spec first_product_id(map(), binary()) :: binary()
  defp first_product_id(products, key), do: products |> Map.fetch!(key) |> Map.fetch!(:id)

  @spec with_transactions_id() :: binary()
  defp with_transactions_id do
    [{_key, product} | _] = create_sample_products_with_transactions(1, 2, :test)
    product.id
  end

  @spec index_entries(pos_integer()) :: list({atom(), binary()})
  defp index_entries(count), do: List.duplicate({:patch, @p}, count)

  @spec click(term(), binary()) :: term()
  defp click(view, selector), do: view |> element(selector) |> render_click()

  @spec request_close(term(), binary()) :: term()
  defp request_close(view, target) do
    view |> with_target(target) |> render_click("auix_request_close", %{})
  end

  @spec decoded_patch(term()) :: tuple()
  defp decoded_patch(view), do: view |> assert_patch() |> NavigationHelper.decode_route()

  @spec route_info(binary()) :: :error | map()
  defp route_info(path),
    do: Phoenix.Router.route_info(Aurora.UixWeb.Test.Router, "GET", path, "localhost")
end
