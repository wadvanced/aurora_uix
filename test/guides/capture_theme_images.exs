Code.require_file("test/guides/image_helper.exs")

defmodule Aurora.UixWeb.Test.Guides.CaptureThemeImages do
  @moduledoc false
  # The theme is a compile-time setting, so one run captures the configured theme only. The
  # default theme adds its dark index and edit form; its light ones are the overview images,
  # captured with the same options. For another theme,
  # set `config :aurora_uix, theme_name: ...` in the checkout's config/test.exs, run
  # `MIX_ENV=test mix assets.build` and run this file again.
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  import Aurora.UixWeb.Test.Guides.ImageHelper

  alias Aurora.Uix.Templates.ThemeHelper

  @target "guides/overview/images/themes"

  feature "create_images", %{session: session} do
    create_guides_sample_data()
    product_id = get_product("item_overview-001").id

    {name, scheme} =
      case ThemeHelper.theme_name() do
        :white_charcoal -> {"theme_white_charcoal_dark", "dark"}
        theme -> {"theme_#{theme}", "light"}
      end

    session
    |> reset_window_size(:desktop)
    |> visit("/guides-overview/products")
    |> capture(:"#{name}_index", :desktop, @target, %{
      desktop: [height: 940, zoom: 0.70, center_crop_width: 700, color_scheme: scheme]
    })
    |> visit("/guides-overview/products/#{product_id}/edit")
    |> capture(:"#{name}_edit", :desktop, @target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        height: 1_200,
        zoom: 0.90,
        center_crop_width: 640,
        crop_height: 920,
        color_scheme: scheme
      ]
    })
  end
end
