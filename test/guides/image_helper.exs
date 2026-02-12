defmodule Aurora.UixWeb.Test.Guides.ImageHelper do
  @moduledoc """
  Test helper module for capturing and processing screenshots in guide tests.

  Provides utilities for taking screenshots with Wallaby, applying transformations,
  and managing screenshot files for documentation purposes.

  ## Key Features
  - Multi-device screenshot capture (desktop and mobile)
  - Window resizing and zoom controls
  - Image post-processing (cropping, sharpening)
  - Automatic file management and cleanup

  ## Key Constraints
  - Requires Wallaby configuration with `:screenshot_dir`
  - Screen sizes are predefined (desktop: 1024x768, mobile: 412x915)
  - All image operations use the Image library
  """

  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature
  alias Aurora.Uix.Guides.Inventory
  alias Wallaby.Query
  @screenshot_dir Application.compile_env(:wallaby, :screenshot_dir)
  @screen_sizes %{desktop: %{width: 1_024, height: 768}, mobile: %{width: 412, height: 915}}

  @doc """
  Captures a screenshot with configurable window settings and image transformations.

  ## Parameters
  - `session` (Wallaby.Session.t()) - Active Wallaby session.
  - `name` (binary()) - Base name for the screenshot file.
  - `screen_size` (:desktop | :mobile) - Target screen size configuration.
  - `target` (binary()) - Directory path where screenshot will be saved.
  - `options_set` (Keyword.t()) - Options for window and image manipulation:
    * `:width` (integer()) - Window width in pixels.
    * `:height` (integer()) - Window height in pixels.
    * `:zoom` (number()) - CSS zoom level.
    * `:click` (binary()) - CSS selector to click before capture.
    * `:center_crop_width` (integer()) - Crop image width from center.
    * `:center_crop_height` (integer()) - Crop image height from center.
    * `:crop_width` (integer()) - Crop image width from origin.
    * `:crop_height` (integer()) - Crop image height from origin.
    * `:sharpen` (boolean()) - Apply sharpening filter.

  ## Returns
  Wallaby.Session.t() - Session with window reset to original screen size.
  """
  @spec capture(Wallaby.Session.t(), binary(), atom(), binary(), Keyword.t()) ::
          Wallaby.Session.t()
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

  @doc """
  Resets window size to predefined screen size dimensions and zoom level.

  ## Parameters
  - `session` (Wallaby.Session.t()) - Active Wallaby session.
  - `screen_size` (:desktop | :mobile) - Target screen size configuration.

  ## Returns
  Wallaby.Session.t() - Session with reset window size and zoom.
  """
  @spec reset_window_size(Wallaby.Session.t(), atom()) :: Wallaby.Session.t()
  def reset_window_size(session, screen_size) do
    session
    |> resize_window(@screen_sizes[screen_size].width, @screen_sizes[screen_size].height)
    |> execute_script("document.body.style.zoom = '1'")
  end

  @doc """
  Filters options for specific screen size or all screens.

  ## Parameters
  - `screen_size` (atom()) - Target screen size key.
  - `options_set` (Keyword.t()) - Options keyed by screen size or `:all`.

  ## Returns
  list() - Flattened list of applicable options.
  """
  @spec get_options(atom(), Keyword.t()) :: list()
  def get_options(screen_size, options_set) do
    options_set
    |> Enum.filter(fn {key, _value} -> key in [screen_size, :all] end)
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
  end

  @doc """
  Retrieves a product by reference from the Inventory context.

  ## Parameters
  - `reference` (binary()) - Product reference identifier.

  ## Returns
  Product.t() | nil - First matching product or nil.
  """
  @spec get_product(binary()) :: struct() | nil
  def get_product(reference) do
    [{:where, [reference: reference]}]
    |> Inventory.list_products()
    |> List.first()
  end

  ## PRIVATE

  # Pauses execution briefly to allow UI rendering to complete
  @spec pause(Wallaby.Session.t()) :: Wallaby.Session.t()
  defp pause(session) do
    Process.sleep(500)
    session
  end

  # Moves screenshot from source to target directory, removes source file on success
  @spec move_file(Wallaby.Session.t(), binary(), binary()) :: Wallaby.Session.t()
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

  @spec get_source_path(binary()) :: binary()
  defp get_source_path(file_name), do: Path.expand("#{@screenshot_dir}/#{file_name}.png")

  @spec maybe_remove_file(binary()) :: :ok
  defp maybe_remove_file(file) do
    if File.exists?(file), do: File.rm(file)
    :ok
  end

  # Applies window configuration options (width, height, zoom, click) to session
  @spec set_window_prefs(Wallaby.Session.t(), list()) :: Wallaby.Session.t()
  defp set_window_prefs(session, opts) do
    Enum.reduce(opts, session, &apply_opt(&2, &1))
  end

  # Applies image transformation options (crop, sharpen) and saves modified image
  @spec transform_image(Wallaby.Session.t(), binary(), list()) :: Wallaby.Session.t()
  defp transform_image(session, file_name, opts) do
    image_path = get_source_path(file_name)
    image = Image.open!(image_path)

    opts
    |> Enum.reduce(image, &apply_image_opt(&2, &1))
    |> Image.write!(image_path)

    session
  end

  @spec apply_opt(Wallaby.Session.t(), tuple()) :: Wallaby.Session.t()
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

  @spec apply_image_opt(Vix.Vips.Image.t(), tuple()) :: Vix.Vips.Image.t()
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
