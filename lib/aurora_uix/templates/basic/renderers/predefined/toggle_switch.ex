defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.ToggleSwitch do
  @moduledoc """
  Predefined `:toggle_switch` renderer for boolean fields.

  - `:index` — a read-only (disabled) sliding switch showing the on/off state.
  - `:show` — the field label above the same read-only switch.
  - `:form` — the same sliding switch, interactive and bound to the form field.
  """

  use Aurora.Uix.Renderer

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: :form}} = assigns) do
    assigns = assign(assigns, :form_field, form_field(assigns))

    ~H"""
    <div class="auix-form-field-container">
      <.input
        type="checkbox"
        field={@form_field}
        label={dt(@field.label)}
        input_class="auix-toggle-switch"
      />
    </div>
    """
  end

  def render(%{auix: %{layout_type: :index}} = assigns) do
    assigns = assign(assigns, :on, truthy?(display_value(assigns)))

    ~H"""
    <.switch on={@on} />
    """
  end

  def render(%{auix: %{layout_type: :show}} = assigns) do
    assigns = assign(assigns, :on, truthy?(display_value(assigns)))

    ~H"""
    <div class="auix-show-field">
      <span class="auix-label">{dt(@field.label)}</span>
      <.switch on={@on} />
    </div>
    """
  end

  # PRIVATE

  @spec switch(map()) :: Phoenix.LiveView.Rendered.t()
  defp switch(assigns) do
    ~H"""
    <input
      type="checkbox"
      checked={@on}
      disabled
      aria-label={if @on, do: dt("On"), else: dt("Off")}
      class="auix-checkbox auix-toggle-switch"
    />
    """
  end

  @spec truthy?(term()) :: boolean()
  defp truthy?(value), do: value in [true, "true"]
end
