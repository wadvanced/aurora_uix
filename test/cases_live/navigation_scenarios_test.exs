defmodule Aurora.UixWeb.Test.NavigationScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case

  import Ecto.Query, only: [from: 2]

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx
  alias Aurora.UixWeb.Test.NavigationHelper

  test "the routing stack follows index, show, edit and new", %{conn: conn} do
    each_backend(fn backend ->
      p = nav_path(backend, "products")
      id = first_product_id(create_sample_products(3, :test), "id_test-1")
      stack = [{:patch, p}, {:patch, p}]

      {:ok, show_view, _html} = live(conn, p)
      click(show_view, "tr[id^='products-#{id}'] td:nth-child(2) a[name='auix-show-product']")
      assert decoded_patch(show_view) == {"#{p}/#{id}/show", %{}, stack}

      {:ok, edit_view, _html} = live(conn, p)
      click(edit_view, "tr[id^='products-#{id}'] a[name='auix-edit-product']")
      assert decoded_patch(edit_view) == {"#{p}/#{id}/edit", %{}, stack}

      {:ok, new_view, _html} = live(conn, p)
      click(new_view, "a[name='auix-new-product']")
      assert decoded_patch(new_view) == {"#{p}/new", %{}, stack}

      assert_show_edit_unwinds(conn, p, id)
      assert_close_and_save_return_to_index(conn, p, id)
      assert_direct_load_returns_to_index(conn, p, id)
    end)
  end

  test "the discard guard holds navigation until the change is discarded", %{conn: conn} do
    each_backend(fn backend ->
      p = nav_path(backend, "products")
      id = first_product_id(create_sample_products(3, :test), "id_test-1")

      {:ok, view, _html} = live(conn, "#{p}/#{id}/edit")
      view |> form("#auix-product-form", product: %{name: "Dirty"}) |> render_change()

      request_close(
        view,
        "#auix-product-edit-modal [data-phx-component]:has(> #auix-product-form)"
      )

      assert has_element?(view, "#auix-product-discard-confirm-modal")
      assert has_element?(view, "#auix-product-edit-modal")

      click(view, "button[name='auix-discard-changes']")
      assert decoded_patch(view) == {p, %{}, []}
    end)
  end

  test "child routes navigate with the parent on the stack", %{conn: conn} do
    each_backend(fn backend ->
      p = nav_path(backend, "products")
      c = nav_path(backend, "product_transactions")
      id = with_transactions_id()

      {:ok, view, _html} = live(conn, "#{p}/#{id}/edit")

      {:error, {:live_redirect, %{to: to}}} =
        view
        |> element("a[name='auix-new-product__product_transactions-form']")
        |> render_click()

      assert NavigationHelper.decode_route(to) ==
               {"#{c}/new", %{"related_key" => "product_id", "parent_id" => id},
                [{:navigate, "#{p}/#{id}/edit"}, {:patch, p}]}

      back = {"#{p}/#{id}/edit", %{}, [{:patch, p}]}

      {:ok, child, _html} = live(conn, to)

      child
      |> form("#auix-product_transaction-form",
        product_transaction: %{quantity: "3", type: "in", cost: 1.5}
      )
      |> render_submit()

      {saved_to, _flash} = assert_redirect(child)
      assert NavigationHelper.decode_route(saved_to) == back

      {:ok, close_child, _html} = live(conn, to)
      request_close(close_child, "#auix-product_transaction-new-modal [data-phx-component]")
      {closed_to, _flash} = assert_redirect(close_child)
      assert NavigationHelper.decode_route(closed_to) == back

      assert_child_links(conn, p, c, id)
      assert_new_parent_continues_on_edit(conn, p)
    end)
  end

  test "only and except limit the mounted routes", %{conn: conn} do
    each_backend(fn backend ->
      id = first_product_id(create_sample_products(1, :test), "id_test-1")
      only = "/mirror-#{backend.slug}-navigation-only-products"
      except = "/mirror-#{backend.slug}-navigation-except-products"

      assert {:ok, _, _} = live(conn, only)
      assert {:ok, _, _} = live(conn, "#{only}/#{id}/show")

      for suffix <- ["/new", "/#{id}/edit", "/#{id}/show-edit"] do
        assert route_info(only <> suffix) == :error
      end

      assert {:ok, _, _} = live(conn, "#{except}/#{id}/show-edit")

      for suffix <- ["/new", "/#{id}/edit"] do
        assert route_info(except <> suffix) == :error
      end
    end)
  end

  test "pagination, record navigation and a forwarded stack keep the way back", %{conn: conn} do
    each_backend(fn backend ->
      p = nav_path(backend, "products")
      c = nav_path(backend, "product_transactions")
      products = create_sample_products(100, :test)

      {:ok, view, _html} = live(conn, p)

      render_click(view, "pagination_next", %{})
      assert decoded_patch(view) == {p, %{"page" => "2"}, index_entries(p, 2)}

      render_click(view, "pagination_to_page", %{"page" => "3"})
      assert decoded_patch(view) == {p, %{"page" => "3"}, index_entries(p, 3)}

      click(view, "a[name='auix-new-product']")
      assert decoded_patch(view) == {"#{p}/new", %{}, index_entries(p, 4)}

      request_close(
        view,
        "#auix-product-new-modal [data-phx-component]:has(> #auix-product-form)"
      )

      assert decoded_patch(view) == {p, %{}, index_entries(p, 3)}

      assert_record_navigation(conn, backend, p, products)

      id = first_product_id(products, "id_test-001")
      stack = NavigationHelper.encode_stack([{:navigate, c}, {:patch, p}])

      {:ok, forwarded, _html} = live(conn, "#{p}/#{id}/show?routing_stack=" <> stack)

      {:error, {:live_redirect, %{to: to}}} = render_click(forwarded, "auix_route_back", %{})

      assert NavigationHelper.decode_route(to) == {c, %{}, [{:patch, p}]}
    end)
  end

  test "index links keep their anchor attributes", %{conn: conn} do
    each_backend(fn backend ->
      p = nav_path(backend, "products")
      id = first_product_id(create_sample_products(1, :test), "id_test-1")
      fwd = "[phx-click='auix_route_forward'][phx-value-route_type='patch']"

      {:ok, view, _html} = live(conn, p)

      assert has_element?(
               view,
               "tr[id^='products-#{id}'] a[name='auix-show-product'][href='#']#{fwd}[phx-value-route_path='#{p}/#{id}/show']"
             )

      assert has_element?(
               view,
               "tr[id^='products-#{id}'] a[name='auix-edit-product'][href='#']#{fwd}[phx-value-route_path='#{p}/#{id}/edit']"
             )

      assert has_element?(
               view,
               "a[name='auix-new-product']#{fwd}[phx-value-route_path='#{p}/new']"
             )

      refute has_element?(view, "a[name='auix-new-product'][href]")
    end)
  end

  test "the flash of a form follows the redirect of the LiveView", %{conn: conn} do
    each_backend(fn backend ->
      p = nav_path(backend, "products")
      id = with_transactions_id()
      {:ok, view, _html} = live(conn, "#{p}/#{id}/edit")

      {:error, {:live_redirect, %{to: to}}} =
        view
        |> element("a[name='auix-new-product__product_transactions-form']")
        |> render_click()

      back = {"#{p}/#{id}/edit", %{}, [{:patch, p}]}

      {:ok, child, _html} = live(conn, to)

      saved =
        child
        |> form("#auix-product_transaction-form",
          product_transaction: %{quantity: "3", type: "in", cost: 1.5}
        )
        |> render_submit()

      assert is_binary(saved)

      assert saved
             |> LazyHTML.from_document()
             |> LazyHTML.query("#flash-info")
             |> Enum.count() == 0

      {_saved_to, saved_flash} = assert_redirect(child)
      assert saved_flash["info"] =~ "updated successfully"

      {:ok, failed, _html} = live(conn, to)

      failed
      |> form("#auix-product_transaction-form",
        product_transaction: %{quantity: "-1", type: "in", cost: 1.5}
      )
      |> render_submit()

      assert has_element?(failed, "#auix-product_transaction-new-modal")
      closed = request_close(failed, "#auix-product_transaction-new-modal [data-phx-component]")
      assert is_binary(closed)
      {closed_to, closed_flash} = assert_redirect(failed)
      assert Map.has_key?(closed_flash, "error")
      assert NavigationHelper.decode_route(closed_to) == back
    end)
  end

  @spec assert_show_edit_unwinds(Plug.Conn.t(), binary(), binary()) :: term()
  defp assert_show_edit_unwinds(conn, p, id) do
    {:ok, view, _html} = live(conn, p)
    click(view, "tr[id^='products-#{id}'] td:nth-child(2) a[name='auix-show-product']")
    assert_patch(view)

    click(view, "#auix-product-show-modal a[name='auix-edit-product']")

    assert decoded_patch(view) ==
             {"#{p}/#{id}/show-edit", %{},
              [{:patch, "#{p}/#{id}/show"}, {:patch, p}, {:patch, p}]}

    request_close(
      view,
      "#auix-product-show_edit-modal [data-phx-component]:has(> #auix-product-form)"
    )

    assert decoded_patch(view) == {"#{p}/#{id}/show", %{}, [{:patch, p}, {:patch, p}]}

    render_click(view, "auix_route_back", %{})
    assert decoded_patch(view) == {p, %{}, [{:patch, p}]}
  end

  @spec assert_close_and_save_return_to_index(Plug.Conn.t(), binary(), binary()) :: term()
  defp assert_close_and_save_return_to_index(conn, p, id) do
    {:ok, view, _html} = live(conn, p)
    click(view, "a[name='auix-new-product']")
    assert_patch(view)
    request_close(view, "#auix-product-new-modal [data-phx-component]:has(> #auix-product-form)")
    assert decoded_patch(view) == {p, %{}, [{:patch, p}]}

    {:ok, edit_view, _html} = live(conn, p)
    click(edit_view, "tr[id^='products-#{id}'] a[name='auix-edit-product']")
    assert_patch(edit_view)

    edit_view
    |> form("#auix-product-form",
      product: %{name: "Changed", description: "d", quantity_initial: 2.0}
    )
    |> render_submit()

    assert decoded_patch(edit_view) == {p, %{}, [{:patch, p}]}
  end

  @spec assert_direct_load_returns_to_index(Plug.Conn.t(), binary(), binary()) :: term()
  defp assert_direct_load_returns_to_index(conn, p, id) do
    {:ok, view, _html} = live(conn, "#{p}/#{id}/edit")
    request_close(view, "#auix-product-edit-modal [data-phx-component]:has(> #auix-product-form)")
    assert decoded_patch(view) == {p, %{}, []}

    {:ok, save_view, _html} = live(conn, "#{p}/#{id}/edit")

    save_view
    |> form("#auix-product-form",
      product: %{name: "Changed", description: "d", quantity_initial: 2.0}
    )
    |> render_submit()

    assert decoded_patch(save_view) == {p, %{}, []}

    {:ok, show_view, _html} = live(conn, "#{p}/#{id}/show")
    render_click(show_view, "auix_route_back", %{})
    assert decoded_patch(show_view) == {p, %{}, []}
  end

  @spec assert_child_links(Plug.Conn.t(), binary(), binary(), binary()) :: term()
  defp assert_child_links(conn, p, c, id) do
    query =
      from(t in MirrorCtx.ProductTransaction,
        where: t.product_id == ^id,
        order_by: t.id,
        limit: 1
      )

    %{id: cid} = Repo.one!(query)

    {:ok, view, _html} = live(conn, "#{p}/#{id}/show")

    {:error, {:live_redirect, %{to: to}}} =
      view
      |> element("table a[name='auix-show-product__product_transaction-#{cid}']")
      |> render_click()

    assert NavigationHelper.decode_route(to) ==
             {"#{c}/#{cid}/show", %{}, [{:navigate, "#{p}/#{id}/show"}, {:patch, p}]}

    {:ok, child, _html} = live(conn, to)

    {:error, {:live_redirect, %{to: back_to}}} = render_click(child, "auix_route_back", %{})

    assert NavigationHelper.decode_route(back_to) == {"#{p}/#{id}/show", %{}, [{:patch, p}]}

    {:ok, edit_view, _html} = live(conn, "#{p}/#{id}/edit")

    {:error, {:live_redirect, %{to: edit_to}}} =
      edit_view
      |> element("table a[name='auix-edit-product__product_transaction-#{cid}']")
      |> render_click()

    assert NavigationHelper.decode_route(edit_to) ==
             {"#{c}/#{cid}/edit", %{"related_key" => "product_id", "parent_id" => id},
              [{:navigate, "#{p}/#{id}/edit"}, {:patch, p}]}
  end

  @spec assert_new_parent_continues_on_edit(Plug.Conn.t(), binary()) :: term()
  defp assert_new_parent_continues_on_edit(conn, p) do
    ref = "navigation-#{System.unique_integer([:positive])}"

    {:ok, view, _html} = live(conn, p)
    click(view, "a[name='auix-new-product']")
    assert_patch(view)

    saved =
      view
      |> form("#auix-product-form",
        product: %{reference: ref, name: "n", description: "d", quantity_initial: 1.0}
      )
      |> render_submit()

    assert is_binary(saved)
    {to, _flash} = assert_redirect(view)

    %{id: new_id} = Repo.get_by!(MirrorCtx.Product, reference: ref)

    assert NavigationHelper.decode_route(to) == {"#{p}/#{new_id}/edit", %{}, [{:patch, p}]}
  end

  @spec assert_record_navigation(Plug.Conn.t(), map(), binary(), map()) :: term()
  defp assert_record_navigation(conn, backend, p, products) do
    {:ok, view, _html} = live(conn, p)
    click(view, "table tbody tr:nth-of-type(5) td:nth-of-type(2) a")
    assert_patch(view)

    render_click(view, "read_indexed_entry", %{"page" => "1", "index" => "5"})
    assert {_path, %{}, :none} = first = decoded_patch(view)

    # Library defect on ash (#583): record navigation across a page boundary patches to another
    # record than the one the Ecto backend opens.
    if backend.name == :ctx do
      assert first == {"#{p}/#{first_product_id(products, "id_test-006")}/show", %{}, :none}
    end

    render_click(view, "read_indexed_entry", %{"page" => "2", "index" => "0"})
    assert {_path, %{}, :none} = second = decoded_patch(view)

    if backend.name == :ctx do
      assert second == {"#{p}/#{first_product_id(products, "id_test-041")}/show", %{}, :none}
    end

    render_click(view, "auix_route_back", %{})
    assert decoded_patch(view) == {p, %{}, []}
  end

  @spec nav_path(map(), binary()) :: binary()
  defp nav_path(backend, source), do: mirror_path(backend, "navigation", source)

  @spec first_product_id(map(), binary()) :: binary()
  defp first_product_id(products, key), do: products |> Map.fetch!(key) |> Map.fetch!(:id)

  @spec with_transactions_id() :: binary()
  defp with_transactions_id do
    [{_key, product} | _] = create_sample_products_with_transactions(1, 2, :test)
    product.id
  end

  @spec index_entries(binary(), pos_integer()) :: list({atom(), binary()})
  defp index_entries(p, count), do: List.duplicate({:patch, p}, count)

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
