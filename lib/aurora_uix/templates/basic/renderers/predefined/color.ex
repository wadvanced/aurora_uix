defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Color do
  @moduledoc """
  Predefined `:color` renderer for colour-string fields (hex, rgb, named).

  - `:index` / `:show` — a framed box filled with the colour, showing the hex value
    in a contrasting text colour.
  - `:form` — a native `<input type="color">` picker bound to the form field.

  The box uses an inline `style` because the colour is dynamic data, not a
  styling choice.
  """

  use Aurora.Uix.Renderer

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: :form}} = assigns) do
    assigns = assign(assigns, :form_field, form_field(assigns))

    ~H"""
    <div class="auix-form-field-container">
      <.input
        type="color"
        field={@form_field}
        label={dt(@field.label)}
        input_class="auix-color-input"
      />
    </div>
    """
  end

  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
    value = to_string(display_value(assigns) || "")

    assigns =
      assigns
      |> assign(:value, value)
      |> assign(:text_color, contrast_text_color(value))

    ~H"""
    <span class="auix-color" style={"background-color: #{@value}; color: #{@text_color};"}>
      {@value}
    </span>
    """
  end

  # PRIVATE

  # Picks black or white text for readability against `hex`, via the YIQ contrast
  # formula. Falls back to the theme's default input text colour when `hex` isn't a
  # parseable `#rgb`/`#rrggbb` value.
  @spec contrast_text_color(binary()) :: binary()
  defp contrast_text_color(<<"#", r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    contrast_text_color_from_rgb(r, g, b)
  end

  defp contrast_text_color(<<"#", r::binary-size(1), g::binary-size(1), b::binary-size(1)>>) do
    contrast_text_color_from_rgb(r <> r, g <> g, b <> b)
  end

  defp contrast_text_color(_other), do: "var(--auix-color-input-text)"

  @spec contrast_text_color_from_rgb(binary(), binary(), binary()) :: binary()
  defp contrast_text_color_from_rgb(r, g, b) do
    with {red, ""} <- Integer.parse(r, 16),
         {green, ""} <- Integer.parse(g, 16),
         {blue, ""} <- Integer.parse(b, 16) do
      yiq = (red * 299 + green * 587 + blue * 114) / 1000
      if yiq >= 128, do: "#000000", else: "#ffffff"
    else
      _error -> "var(--auix-color-input-text)"
    end
  end
end
