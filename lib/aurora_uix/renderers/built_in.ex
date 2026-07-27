defmodule Aurora.Uix.Renderers.BuiltIn do
  @moduledoc """
  Built-in predefined renderers shipped with Aurora UIX.

  This registrar maps the built-in atom names to their `&render/1` functions, plus the
  reserved `:default` key holding the default renderer. Host applications add or
  override entries through their own `Aurora.Uix.RendererRegistrar` (see that module
  and `Aurora.Uix.Renderers`).

  | Atom | Layouts | Purpose |
  |------|---------|---------|
  | `:toggle_switch` | index, show, form | Boolean as a sliding switch. |
  | `:color` | index, show, form | Colour string as a swatch (+ native picker on form). |
  | `:badge` | index, show | Enum/status string as a coloured pill. |
  | `:progress_bar` | index, show | Numeric value as a progress bar. |
  | `:url` | show | String as a clickable link (plain text on index). |
  | `:rating` | index, show, form | Numeric value as stars (interactive on form). |
  | `:default` | index, show, form | The default field rendering (fallback). |
  """

  @behaviour Aurora.Uix.RendererRegistrar

  alias Aurora.Uix.Templates.Basic.Renderers.DefaultRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.Predefined

  @impl Aurora.Uix.RendererRegistrar
  @spec renderers() :: %{atom() => (map() -> Phoenix.LiveView.Rendered.t())}
  def renderers do
    %{
      toggle_switch: &Predefined.ToggleSwitch.render/1,
      color: &Predefined.Color.render/1,
      badge: &Predefined.Badge.render/1,
      progress_bar: &Predefined.ProgressBar.render/1,
      url: &Predefined.Url.render/1,
      rating: &Predefined.Rating.render/1,
      default: &DefaultRenderer.render/1
    }
  end
end
