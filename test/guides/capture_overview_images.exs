Code.require_file("test/guides/image_helper.exs")

defmodule Aurora.UixWeb.Test.Guides.CaptureOverviewImages do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  import Aurora.UixWeb.Test.Guides.ImageHelper
  alias Wallaby.Query
  alias Wallaby.Session

  feature "create_images", %{session: session} do
    create_guides_sample_data()

    session
    |> create_overview_images(:desktop)
    |> create_overview_images(:mobile)
  end

  @spec create_overview_images(Session.t(), atom()) :: Session.t()
  defp create_overview_images(session, screen_size) do
    product_id = get_product("item_overview-001").id

    url = "/guides-overview/products"
    target = "guides/overview/images"

    session
    |> reset_window_size(screen_size)

    # index
    |> visit(url)
    |> capture(:index, screen_size, target, %{
      desktop: [zoom: 0.70, center_crop_width: 1_024, center_crop_height: 620]
    })

    # show
    |> visit("#{url}/#{product_id}/show")
    |> capture(:show, screen_size, target, %{
      all: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--show']"
      ],
      mobile: [zoom: 0.75, center_crop_width: 400]
    })

    # edit
    |> visit("#{url}/#{product_id}/edit")
    |> capture(:edit, screen_size, target, %{
      all: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']"
      ],
      desktop: [zoom: 0.90, center_crop_width: 1_024],
      mobile: [zoom: 0.75, center_crop_width: 500]
    })

    # edit switching
    |> click(Query.css("button.auix-sections-tab-button--inactive"))
    |> capture(:edit_section_switching, screen_size, target, %{
      desktop: [zoom: 0.90, center_crop_width: 1_024],
      mobile: [zoom: 0.75, center_crop_width: 500]
    })
  end
end
