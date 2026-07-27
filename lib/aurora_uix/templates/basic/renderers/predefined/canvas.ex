defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Canvas do
  @moduledoc """
  Predefined `:canvas` renderer for string fields holding a base64 / data-URL image
  (e.g. a signature or free-hand drawing).

  - `:index` / `:show` — the stored drawing as a read-only image.
  - `:form` — a drawing pad driven by the `AuixCanvas` JS hook. On each stroke the
    hook writes the canvas' data-URL into a hidden input bound to the form field, so
    the value is submitted with the form. A Clear button empties it.

  The pad size defaults to `300x150`; override per field with
  `data: %{width: 400, height: 200}`.

  The hook ships in `assets/js/hooks.js` as part of `AuroraUix.Hooks`; hosts that
  already merge `AuroraUix.Hooks` into their `LiveSocket` need no extra wiring.
  """

  use Aurora.Uix.Renderer

  @default_width 300
  @default_height 150

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: :form}} = assigns) do
    field_struct = assigns.field
    form_field = form_field(assigns)

    assigns =
      assigns
      |> assign(:name, form_field.name)
      |> assign(:value, form_field.value)
      |> assign(:width, field_struct.data[:width] || @default_width)
      |> assign(:height, field_struct.data[:height] || @default_height)
      |> assign(:wrapper_id, field_struct.html_id <> "-canvas-wrapper")
      |> assign(:canvas_id, field_struct.html_id <> "-canvas")
      |> assign(:input_id, field_struct.html_id <> "-canvas-input")
      |> assign(:clear_id, field_struct.html_id <> "-canvas-clear")

    ~H"""
    <div class="auix-form-field-container">
      <.label>{dt(@field.label)}</.label>
      <div id={@wrapper_id} class="auix-canvas" phx-update="ignore">
        <canvas
          id={@canvas_id}
          class="auix-canvas-pad"
          width={@width}
          height={@height}
          phx-hook="AuixCanvas"
          data-auix-input-id={@input_id}
          data-auix-clear-id={@clear_id}
        >
        </canvas>
        <input type="hidden" id={@input_id} name={@name} value={@value} />
        <button type="button" id={@clear_id} class="auix-canvas-clear">{dt("Clear")}</button>
      </div>
    </div>
    """
  end

  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <img :if={@value not in [nil, ""]} src={@value} alt={dt(@field.label)} class="auix-canvas-image" />
    """
  end
end
