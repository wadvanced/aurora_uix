defmodule Aurora.UixWeb.Test.AshAggregatesTest do
  @moduledoc "Ash calculations and aggregates."
  use Aurora.UixWeb.Test.UICase, :scenario_case

  alias Aurora.UixWeb.Test.MirrorAsh.Aggregates

  test "Ash calculations and aggregates are typed, disabled fields added to the preloads" do
    summary = get_in(Aggregates.auix_resource(:product), [:fields, :summary])
    assert summary.type == :string
    assert summary.html_type == :text
    assert summary.label == "Summary"
    assert summary.disabled

    fields = get_in(Aggregates.auix_resource(:product_location), [:fields])

    assert %{
             type: :integer,
             html_type: :number,
             label: "Products Count",
             disabled: true
           } = fields.products_count

    assert %{type: :string, html_type: :text} = fields.latest_product_name
    assert %{type: :utc_datetime} = fields.last_discontinued_at
    assert %{type: :string, html_type: :unimplemented} = fields.product_names

    preloads = Aggregates.auix_preloads()
    assert :summary in preloads.product
    assert :products_count in preloads.product_location
    assert :latest_product_name in preloads.product_location
    assert :product_names in preloads.product_location
  end

  test "an aggregate renders as an index column and a calculation in the show view", %{conn: conn} do
    each_backend([:ash], fn backend ->
      locations_by_id = create_sample_product_locations(1, :test)
      [location] = Map.values(locations_by_id)

      products =
        create_sample_products(3, :test, fn i ->
          %{
            product_location_id: location.id,
            quantity_initial: 1,
            discontinued_at: DateTime.add(~U[2026-01-01 00:00:00Z], i, :day)
          }
        end)

      locations = mirror_path(backend, "aggregates", "product_locations")
      {:ok, index_view, _html} = live(conn, locations)
      assert has_element?(index_view, "th", "Latest Product Name")
      assert has_element?(index_view, "td", "Item test-3")
      assert has_element?(index_view, "td", "3")

      {:ok, show_view, _html} = live(conn, "#{locations}/#{location.id}/show")

      assert has_element?(
               show_view,
               "input[name='latest_product_name'][value='Item test-3'][disabled]"
             )

      product = products |> Map.values() |> List.first()

      {:ok, product_view, _html} =
        live(conn, mirror_path(backend, "aggregates", "products", "/#{product.id}/show"))

      assert has_element?(
               product_view,
               "div.auix-show-container input[name='summary'][value='#{product.name} is #{product.status}'][disabled]"
             )

      {:ok, _view, _html} = live(conn, locations <> "/new")
      {:ok, _view, _html} = live(conn, "#{locations}/#{location.id}/edit")

      products_path = mirror_path(backend, "aggregates", "products")
      {:ok, _view, _html} = live(conn, products_path <> "/new")
      {:ok, _view, _html} = live(conn, "#{products_path}/#{product.id}/edit")
    end)
  end
end
