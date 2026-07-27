defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Color do
  @moduledoc """
  Predefined `:color` renderer for colour-string fields (hex, rgb, named).

  - `:index` / `:show` — a colour swatch next to the raw value.
  - `:form` — a native `<input type="color">` picker bound to the form field.

  The swatch uses an inline `style` because the colour is dynamic data, not a
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
    assigns = assign(assigns, :value, to_string(display_value(assigns) || ""))

    ~H"""
    <span class="auix-color">
      <span class="auix-color-swatch" style={"background-color: #{@value};"}></span>
      <span class="auix-color-label">{@value}</span>
    </span>
    """
  end
end
