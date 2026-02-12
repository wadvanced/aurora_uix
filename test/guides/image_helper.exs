defmodule Aurora.UixWeb.Test.Guides.ImageHelper do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature
  alias Aurora.Uix.Guides.Inventory
  alias Wallaby.Query
  @screenshot_dir Application.compile_env(:wallaby, :screenshot_dir)
  @screen_sizes %{desktop: %{width: 1_024, height: 768}, mobile: %{width: 412, height: 915}}

  def capture(session, name, screen_size, target, options_set) do
    file_name = "#{name}-#{screen_size}"
    opts = get_options(screen_size, options_set)

    session
    |> set_window_prefs(opts)
    |> pause()
    |> take_screenshot(name: file_name, log: true)
    |> transform_image(file_name, opts)
    |> move_file(file_name, target)
    |> reset_window_size(screen_size)
  end

  def reset_window_size(session, screen_size) do
    session
    |> resize_window(@screen_sizes[screen_size].width, @screen_sizes[screen_size].height)
    |> execute_script("document.body.style.zoom = '1'")
  end

  def get_options(screen_size, options_set) do
    options_set
    |> Enum.filter(fn {key, _value} -> key in [screen_size, :all] end)
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
  end

  def get_product(reference) do
    [{:where, [reference: reference]}]
    |> Inventory.list_products()
    |> List.first()
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

  defp set_window_prefs(session, opts) do
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
