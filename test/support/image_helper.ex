defmodule Aurora.Uix.Test.ImageHelper do
  alias Wallaby.Query
  @screenshot_dir Application.compile_env(:wallaby, :screenshot_dir)
  @screen_sizes %{desktop: %{width: 1_024, height: 768}, mobile: %{width: 412, height: 915}}
  defmacro __using__(_opts) do
    import __MODULE__
  end

  def capture(session, name, screen_size, target, options_set) do
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
end
