defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.ToggleSwitch do
  @moduledoc """
  Predefined `:toggle_switch` renderer for boolean fields.

  - `:index` / `:show` — a read-only pill showing the on/off state.
  - `:form` — a checkbox styled as a toggle, bound to the form field.
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

  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
    assigns = assign(assigns, :on, truthy?(display_value(assigns)))

    ~H"""
    <span class={["auix-toggle-pill", @on and "auix-toggle-pill--on"]}>
      {if @on, do: dt("On"), else: dt("Off")}
    </span>
    """
  end

  @spec truthy?(term()) :: boolean()
  defp truthy?(value), do: value in [true, "true"]
end
