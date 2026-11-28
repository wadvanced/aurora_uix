defmodule Aurora.UixWeb.Test.CtxContextFunctionsTest do
  @moduledoc "`ctx` CRUD function discovery."
  use Aurora.UixWeb.Test.UICase, :scenario_case

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx.Product

  test "a ctx resource runs its CRUD through the generated context functions", %{conn: conn} do
    each_backend([:ctx], fn backend ->
      create_sample_products(3, :test)
      path = mirror_path(backend, "default", "products")

      {:ok, view, _html} = live(conn, path)
      assert has_element?(view, "tr[id^='products-']", "item_test-1")
      assert has_element?(view, "tr[id^='products-']", "item_test-3")

      {:ok, new_view, _html} = live(conn, path <> "/new")

      new_view
      |> form("#auix-product-form",
        product: %{
          reference: "c-1",
          name: "Ctx one",
          quantity_initial: 1,
          product_barcode: %{code: "C-1"}
        }
      )
      |> render_submit()

      product = Repo.get_by!(Product, reference: "c-1")
      assert product.name == "Ctx one"

      {:ok, edit_view, _html} = live(conn, "#{path}/#{product.id}/edit")

      edit_view
      |> form("#auix-product-form", product: %{name: "Renamed"})
      |> render_submit()

      assert Repo.get!(Product, product.id).name == "Renamed"

      {:ok, index_view, _html} = live(conn, path)

      index_view
      |> element("tr#products-#{product.id} a[name='auix-delete-product']")
      |> render_click()

      assert Repo.get(Product, product.id) == nil
    end)
  end

  # A bang delete function returns the bare record instead of `{:ok, record}`.
  test "context functions in backend_opts list and delete the rows", %{conn: conn} do
    each_backend([:ctx], fn backend ->
      products = create_sample_products(3, :test)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "context-functions", "products"))

      for reference <- ["item_test-1", "item_test-2", "item_test-3"] do
        assert has_element?(view, "tr[id^='products-']", reference)
      end

      product = products["id_test-1"]

      view
      |> element("tr#products-#{product.id} a[name='auix-delete-product']")
      |> render_click()

      assert Repo.get(Product, product.id) == nil
      assert has_element?(view, "#flash-info", "Item deleted successfully")
      refute has_element?(view, "#flash-error")
    end)
  end
end
