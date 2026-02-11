defmodule Aurora.UixWeb.Test.CaptureImages do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  alias Aurora.Uix.Guides.Inventory
  alias Wallaby.Query
  # alias Wallaby.Session

  @screenshot_dir Application.compile_env(:wallaby, :screenshot_dir)
  @screen_sizes %{desktop: %{width: 1_024, height: 768}, mobile: %{width: 412, height: 915}}

  feature "create_images", %{session: session} do
    create_overview_sample_data()

    session
    # |> create_overview_images()

    |> create_layout_images()
  end

  defp create_overview_images(session) do
    session
    |> create_overview_images(:desktop)
    |> create_overview_images(:mobile)
  end

  defp create_overview_images(session, screen_size) do
    product_id = get_product("item_overview-001").id

    url = "/guides-overview/products"
    target = "guides/overview/images"

    session
    |> reset_window_size(screen_size)

    # index
    |> visit(url)
    |> capture(:index, screen_size, target, %{
      desktop: [zoom: 0.70, center_crop_width: 1_280, center_crop_height: 1_024]
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
      mobile: [zoom: 0.75, center_crop_width: 800]
    })

    # edit switching
    |> click(Query.css("button.auix-sections-tab-button--inactive"))
    |> capture(:edit_section_switching, screen_size, target, %{
      desktop: [zoom: 0.90, center_crop_width: 1_024],
      mobile: [zoom: 0.75, center_crop_width: 800]
    })
  end

  defp create_layout_images(session) do
    create_layout_images(session, :desktop)
  end

  defp create_layout_images(session, screen_size) do
    Code.require_file("test/cases_live/create_ui_default_layout_test.exs")
    Code.require_file("test/cases_live/association_many2one_selector_ui_layout_test.exs")

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
    url = "/association-many_to_one_selector-layout-product_locations"

    # edit
    session
    |> visit("#{url}/#{product_location_id}/edit")
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
    url = "/association-many_to_one_selector-layout-products"

    session
    |> visit("#{url}/#{product_id}/edit")
    |> capture(:stacked_1, screen_size, target, %{
      desktop: [
        click: "input[id^='auix-field-product-reference-'][id$='#{product_id}--form']",
        center_crop_width: 1_152
      ]
    })
  end

  defp create_layout_images(session, _), do: session

  defp capture(session, name, screen_size, target, options_set) do
    file_name = "#{name}-#{screen_size}"
    opts = get_options(screen_size, options_set)

    session
    |> set_window_prefs(screen_size, opts)
    |> pause()
    |> take_screenshot(name: file_name, log: true)
    |> transform_image(file_name, opts)
    |> move_file(file_name, target)
    |> reset_window_size(screen_size)
  end

  defp reset_window_size(session, screen_size) do
    session
    |> resize_window(@screen_sizes[screen_size].width, @screen_sizes[screen_size].height)
    |> execute_script("document.body.style.zoom = '1'")
  end

  defp pause(session) do
    Process.sleep(100)
    session
  end

  defp move_file(session, file_name, target) do
    source_path = get_source_path(file_name)
    target_path = Path.expand("#{target}/#{file_name}.png")

    with :ok <- maybe_remove_file(target_path),
         :ok <- File.cp(source_path, target_path) do
      File.rm(source_path)
    else
      {:error, reason} ->
        IO.puts("Error copying \n#{source_path}\n to \n#{target_path}\n #{inspect(reason)}\n")
    end

    session
  end

  defp get_source_path(file_name), do: Path.expand("#{@screenshot_dir}/#{file_name}.png")

  defp maybe_remove_file(file) do
    if File.exists?(file), do: File.rm(file)
    :ok
  end

  defp get_options(screen_size, options_set) do
    options_set
    |> Enum.filter(fn {key, _value} -> key in [screen_size, :all] end)
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
  end

  defp set_window_prefs(session, screen_size, opts) do
    Enum.reduce(opts, session, &apply_opt(&2, &1))
  end

  defp transform_image(session, file_name, opts) do
    image_path = get_source_path(file_name)
    image = Image.open!(image_path)

    opts
    |> Enum.reduce(image, &apply_image_opt(&2, &1))
    |> Image.write!(image_path)

    session
  end

  defp get_product(reference) do
    [{:where, [reference: reference]}]
    |> Inventory.list_products()
    |> List.first()
  end

  defp apply_opt(session, {:width, new_width}) do
    %{"width" => _current_width, "height" => current_height} = window_size(session)
    resize_window(session, new_width, current_height)
  end

  defp apply_opt(session, {:height, new_height}) do
    %{"width" => current_width, "height" => _current_height} = window_size(session)
    resize_window(session, current_width, new_height)
  end

  defp apply_opt(session, {:zoom, new_zoom}) when is_number(new_zoom) do
    execute_script(session, "document.body.style.zoom = '#{new_zoom}'")
  end

  defp apply_opt(session, {:click, css}) do
    click(session, Query.css(css))
  end

  defp apply_opt(session, _), do: session

  defp apply_image_opt(image, {:center_crop_width, new_width}) do
    height = Image.height(image)
    Image.center_crop!(image, new_width, height)
  end

  defp apply_image_opt(image, {:center_crop_height, new_height}) do
    width = Image.width(image)
    Image.center_crop!(image, width, new_height)
  end

  defp apply_image_opt(image, {:crop_width, new_width}) do
    height = Image.height(image)
    Image.crop!(image, 0, 0, new_width, height)
  end

  defp apply_image_opt(image, {:crop_height, new_height}) do
    width = Image.width(image)
    Image.crop!(image, 0, 0, width, new_height)
  end

  defp apply_image_opt(image, {:sharpen, true}) do
    Image.sharpen!(image)
  end

  defp apply_image_opt(image, _), do: image
end
