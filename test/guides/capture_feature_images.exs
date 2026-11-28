Code.require_file("test/guides/image_helper.exs")
Code.require_file("test/guides/views/index_cards_layout.exs")
Code.require_file("test/guides/views/associations_layout.exs")
Code.require_file("test/guides/views/embeds_layout.exs")
Code.require_file("test/guides/views/renderers_layout.exs")
Code.require_file("test/guides/views/uploads_layout.exs")
Code.require_file("test/guides/views/components_dashboard.exs")

defmodule Aurora.UixWeb.Test.Guides.CaptureFeatureImages do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  import Aurora.UixWeb.Test.Guides.ImageHelper

  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.Topic
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductBarcode
  alias Aurora.Uix.Guides.Inventory.Supplier
  alias Aurora.Uix.Repo
  alias Wallaby.Query
  alias Wallaby.Session

  @target "guides/core/images/features"
  # An image sits beside the guide that shows it, so that its relative path works on GitHub too.
  @customization_target "guides/customization/images/features"

  feature "create_images", %{session: session} do
    # Ash counts a page in a separate task, which the browser sandbox does not reach.
    disable_async? = Application.get_env(:ash, :disable_async?, false)
    Application.put_env(:ash, :disable_async?, true)
    on_exit(fn -> Application.put_env(:ash, :disable_async?, disable_async?) end)

    create_guides_sample_data()

    session
    |> reset_window_size(:desktop)
    |> capture_index_in_use()
    |> capture_index_cards()
    |> capture_components()
    |> capture_associations()
    |> capture_embeds()
    |> capture_renderers()
    |> capture_uploads()
  end

  # A click before LiveView connects is lost.
  @spec open_page(Session.t(), binary()) :: Session.t()
  defp open_page(session, path) do
    session
    |> visit(path)
    |> assert_has(Query.css(".phx-connected", count: :any))
  end

  @spec capture_index_in_use(Session.t()) :: Session.t()
  defp capture_index_in_use(session) do
    session =
      session
      |> open_page("/guides-overview/products")
      |> click(Query.css("a[name='auix-filter_toggle_open']"))
      |> assert_has(Query.css("a[name='auix-filter_toggle_close']"))
      |> click(Query.css("button[name='auix-sort-name']"))
      |> assert_has(Query.css("th[aria-sort='ascending']"))

    session
    |> click(Query.css("input[type='checkbox'][name^='selected_check__']", count: :any, at: 0))
    |> click(Query.css("input[type='checkbox'][name^='selected_check__']", count: :any, at: 2))
    |> capture(:index_in_use, :desktop, @target, %{
      desktop: [height: 940, zoom: 0.70]
    })
  end

  @spec capture_index_cards(Session.t()) :: Session.t()
  defp capture_index_cards(session) do
    session
    |> open_page("/guides-capture-cards-products")
    |> click(Query.css("[name='auix-card-menu-toggle']", count: :any, at: 0))
    |> capture(:index_cards, :desktop, @target, %{desktop: [height: 900, zoom: 0.80]})
  end

  @spec capture_associations(Session.t()) :: Session.t()
  defp capture_associations(session) do
    product = get_product("item_overview-001")

    suppliers =
      Enum.map(["Acme Supplies", "Northwind Traders", "Globex"], fn name ->
        Repo.insert!(%Supplier{name: name, country: "Chile"})
      end)

    Repo.insert!(%ProductBarcode{
      product_id: product.id,
      code: "7501234567890",
      registered_at: ~D[2026-01-15]
    })

    Product
    |> Repo.get!(product.id)
    |> Repo.preload([:product_barcode, :suppliers])
    |> Product.changeset(%{suppliers: suppliers |> Enum.take(2) |> Enum.map(& &1.id)})
    |> Repo.update!()

    session
    |> open_page("/guides-capture-associations-products/#{product.id}/edit")
    |> capture(:associations_form, :desktop, @target, %{
      desktop: [height: 900, zoom: 0.80, center_crop_width: 640, crop_height: 650]
    })
  end

  @spec capture_embeds(Session.t()) :: Session.t()
  defp capture_embeds(session) do
    post = Post |> Ash.read!() |> Enum.min_by(& &1.title)

    post
    |> Ash.Changeset.for_update(:update, %{
      comment: %{title: "Editor's note", description: "Reviewed and ready to publish."},
      tags: [%{name: "elixir"}, %{name: "phoenix"}],
      topics: [Ash.create!(Topic, %{name: "Guides", slug: "guides"}).id]
    })
    |> Ash.update!()

    session
    |> open_page("/guides-capture-embeds-posts/#{post.id}/edit")
    |> capture(:embeds_form, :desktop, @target, %{
      desktop: [height: 1_150, zoom: 0.80, center_crop_width: 640, crop_height: 900]
    })
  end

  @spec capture_renderers(Session.t()) :: Session.t()
  defp capture_renderers(session) do
    product = get_product("item_overview-002")

    Product
    |> Repo.get!(product.id)
    |> Ecto.Changeset.change(%{
      deleted: true,
      description: "#2563eb",
      status: "in_stock",
      quantity_at_hand: Decimal.new(65),
      reference: "https://example.com/lamp",
      quantity_entries: Decimal.new(4)
    })
    |> Repo.update!()

    session
    |> open_page("/guides-capture-renderers-products/#{product.id}/show")
    |> capture(:renderers_show, :desktop, @customization_target, %{
      desktop: [height: 940, zoom: 0.80, center_crop_width: 600, crop_height: 540]
    })
  end

  @spec capture_uploads(Session.t()) :: Session.t()
  defp capture_uploads(session) do
    product = get_product("item_overview-003")

    Product
    |> Repo.get!(product.id)
    |> Ecto.Changeset.change(%{thumbnail: "photos/desk-lamp.png"})
    |> Repo.update!()

    session
    |> open_page("/guides-capture-uploads-products/#{product.id}/edit")
    |> capture(:uploads_form, :desktop, @target, %{
      desktop: [height: 900, zoom: 0.80, center_crop_width: 600, crop_height: 480]
    })
  end

  @spec capture_components(Session.t()) :: Session.t()
  defp capture_components(session) do
    session
    |> open_page("/guides-capture-dashboard")
    |> capture(:components_host, :desktop, @target, %{
      desktop: [height: 768, zoom: 0.70, crop_height: 480]
    })
  end
end
