Code.require_file("test/guides/image_helper.exs")
Code.require_file("test/guides/views/default_layout.exs")
Code.require_file("test/guides/views/selector_layout.exs")
Code.require_file("test/guides/views/group_layout.exs")
Code.require_file("test/guides/views/section_layout.exs")
Code.require_file("test/guides/views/nested_sections_layout.exs")

defmodule Aurora.UixWeb.Test.Guides.CaptureImages do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  import Aurora.UixWeb.Test.Guides.ImageHelper

  feature "create_images", %{session: session} do
    create_guides_sample_data()

    create_layout_images(session, :desktop)
  end

  @spec create_layout_images(Session.t(), atom()) :: Session.t()
  defp create_layout_images(session, screen_size) do
    product_id = get_product("item_overview-010").id
    product_location_id = get_product("item_overview-010").product_location_id

    url = "/guides-capture-default-products"
    target = "guides/core/images/layouts"

    session
    |> visit(url)
    |> capture(:default_index, screen_size, target, %{desktop: [zoom: 0.40]})

    # show
    |> visit("#{url}/#{product_id}/show")
    |> capture(:default_show, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--show']",
        zoom: 0.60,
        center_crop_width: 600,
        sharpen: true
      ]
    })

    # edit
    session
    |> visit("#{url}/#{product_id}/edit")
    |> capture(:default_edit, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        zoom: 0.8,
        center_crop_width: 600
      ]
    })

    # inline layout
    url_inline = "/guides-capture-selector-product_locations"

    # edit
    session
    |> visit("#{url_inline}/#{product_location_id}/edit")
    |> capture(:inline_1, screen_size, target, %{
      desktop: [
        click:
          "input[id^='auix-field-product_location-reference-'][id$='#{product_location_id}--form']",
        center_crop_width: 680,
        crop_height: 420
      ]
    })

    # stacked layout
    # edit
    url_stacked = "/guides-capture-selector-products"

    session
    |> visit("#{url_stacked}/#{product_id}/edit")
    |> capture(:stacked_1, screen_size, target, %{
      desktop: [
        height: 1100,
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 720,
        crop_height: 880
      ]
    })

    # group layout
    # edit
    url_group = "/guides-capture-group-products"

    session
    |> visit("#{url_group}/#{product_id}/edit")
    |> capture(:group_1, screen_size, target, %{
      desktop: [
        height: 1100,
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 680,
        crop_height: 810
      ]
    })

    # section layout
    # edit
    url_section = "/guides-capture-section-products"

    session
    |> visit("#{url_section}/#{product_id}/edit")
    |> capture(:sections_1, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 680,
        crop_height: 590
      ]
    })
    |> click(Query.css("button[data-button-sections-index='1'][data-button-tab-index='2']"))
    |> capture(:sections_2, screen_size, target, %{
      desktop: [
        height: 1100,
        center_crop_width: 680,
        crop_height: 670
      ]
    })

    # nested sections
    url_nested = "/guides-capture-nested-sections-products"

    session
    |> visit("#{url_nested}/#{product_id}/edit")
    |> capture(:nested_1, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 600,
        crop_height: 480
      ]
    })
    |> click(Query.css("button[data-button-sections-index='1'][data-button-tab-index='2']"))
    |> capture(
      :nested_2,
      screen_size,
      target,
      %{
        desktop: [center_crop_width: 600, crop_height: 480]
      }
    )
    |> click(Query.css("button[data-button-sections-index='3'][data-button-tab-index='1']"))
    |> capture(
      :nested_3,
      screen_size,
      target,
      %{
        desktop: [center_crop_width: 600, crop_height: 480]
      }
    )
  end
end
