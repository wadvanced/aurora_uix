Code.require_file("test/guides/image_helper.exs")
Code.require_file("test/cases_live/create_ui_default_layout_test.exs")
Code.require_file("test/cases_live/association_many2one_selector_ui_layout_test.exs")
Code.require_file("test/cases_live/group_ui_layout_test.exs")
Code.require_file("test/cases_live/section_ui_layout_test.exs")
Code.require_file("test/cases_live/nested_sections_ui_layout_test.exs")

defmodule Aurora.UixWeb.Test.Guides.CaptureImages do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  import Aurora.UixWeb.Test.Guides.ImageHelper

  @screenshot_dir Application.compile_env(:wallaby, :screenshot_dir)
  @screen_sizes %{desktop: %{width: 1_024, height: 768}, mobile: %{width: 412, height: 915}}

  feature "create_images", %{session: session} do
    create_overview_sample_data()

    create_layout_images(session, :desktop)
  end

  @spec create_layout_images(Session.t(), atom()) :: Session.t()
  defp create_layout_images(session, screen_size) do
    product_id = get_product("item_overview-010").id
    product_location_id = get_product("item_overview-010").product_location_id

    url = "/create-ui-default-layout-products"
    target = "guides/core/images/layouts"

    session
    |> visit(url)
    |> capture(:default_index, screen_size, target, %{
      desktop: [zoom: 0.40, width: 1_800, center_crop_width: 2_400]
    })
    # show
    |> visit("#{url}/#{product_id}/show")
    |> capture(:default_show, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--show']",
        zoom: 0.60,
        center_crop_width: 480,
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
        center_crop_width: 912
      ]
    })

    # inline layout
    url_inline = "/association-many_to_one_selector-layout-product_locations"

    # edit
    session
    |> visit("#{url_inline}/#{product_location_id}/edit")
    |> capture(:inline_1, screen_size, target, %{
      desktop: [
        click:
          "input[id^='auix-field-product_location-reference-'][id$='#{product_location_id}--form']",
        center_crop_width: 1_216,
        crop_height: 640
      ]
    })

    # stacked layout
    # edit
    url_stacked = "/association-many_to_one_selector-layout-products"

    session
    |> visit("#{url_stacked}/#{product_id}/edit")
    |> capture(:stacked_1, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 1_152
      ]
    })

    # group layout
    # edit
    url_group = "group-ui-layout-products"

    session
    |> visit("#{url_group}/#{product_id}/edit")
    |> capture(:group_1, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 1_152
      ]
    })

    # section layout
    # edit
    url_section = "section-ui-layout-products"

    session
    |> visit("#{url_section}/#{product_id}/edit")
    |> capture(:sections_1, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 1_152,
        crop_height: 896
      ]
    })
    |> click(Query.css("button[data-button-sections-index='1'][data-button-tab-index='2']"))
    |> capture(:sections_2, screen_size, target, %{
      desktop: [
        center_crop_width: 1_152,
        crop_height: 960
      ]
    })

    # nested sections
    url_nested = "nested-sections-ui-layout-products"

    session
    |> visit("#{url_nested}/#{product_id}/edit")
    |> capture(:nested_1, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 1_088,
        crop_height: 1_024
      ]
    })
    |> click(Query.css("button[data-button-sections-index='1'][data-button-tab-index='2']"))
    |> capture(:nested_2, screen_size, target, %{
      desktop: [center_crop_width: 1_088, crop_height: 1_024]
    })
    |> click(Query.css("button[data-button-sections-index='3'][data-button-tab-index='1']"))
    |> capture(:nested_3, screen_size, target, %{
      desktop: [center_crop_width: 1_088, crop_height: 1_024]
    })
  end
end
