defmodule Aurora.UixWeb.Test.LayoutScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx

  @resources [
    {"products", "product", MirrorCtx.Product},
    {"product_locations", "product_location", MirrorCtx.ProductLocation},
    {"product_transactions", "product_transaction", MirrorCtx.ProductTransaction},
    {"product_barcodes", "product_barcode", MirrorCtx.ProductBarcode},
    {"suppliers", "supplier", MirrorCtx.Supplier}
  ]

  test "default layouts mount index, new, show and edit for every resource", %{conn: conn} do
    each_backend(fn backend ->
      for {source, _resource, _schema} <- @resources do
        {:ok, view, _} = live(conn, mirror_path(backend, "default", source))
        assert has_element?(view, ".auix-index-container")
        refute has_element?(view, ".auix-items-table-row")
      end

      create_sample_products_with_transactions(1, 2, :test)
      create_sample_product_locations(1, :test)
      create_sample_products_with_barcodes(1)
      create_sample_products_with_suppliers(1, 2)

      for {source, resource, schema} <- @resources do
        %{id: id} = schema |> Repo.all() |> List.first()

        {:ok, index_view, _} = live(conn, mirror_path(backend, "default", source))
        assert has_element?(index_view, ".auix-index-container")

        for action <- ["new", "edit"] do
          suffix = if action == "new", do: "/new", else: "/#{id}/edit"
          {:ok, form_view, _} = live(conn, mirror_path(backend, "default", source, suffix))
          assert has_element?(form_view, ".auix-index-container")
          assert has_element?(form_view, "#auix-#{resource}-#{action}-modal .auix-form-container")
        end

        {:ok, show_view, _} = live(conn, mirror_path(backend, "default", source, "/#{id}/show"))
        assert has_element?(show_view, ".auix-index-container")
        assert has_element?(show_view, ".auix-show-container")
      end
    end)
  end
end
