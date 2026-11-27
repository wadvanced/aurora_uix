defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Badge do
  @moduledoc """
  Predefined `:badge` renderer for enum / status string fields.

  - `:index` — the value as a coloured pill.
  - `:show` — the field label above the same pill.
  - `:form` — editing is not special; delegates to the default input.
  """

  use Aurora.Uix.Renderer

  alias Aurora.Uix.Renderers

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: :index}} = assigns) do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <span :if={not is_nil(@value)} class="auix-badge">{@value}</span>
    """
  end

  def render(%{auix: %{layout_type: :show}} = assigns) do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <div class="auix-show-field">
      <span class="auix-label">{dt(@field.label)}</span>
      <span :if={not is_nil(@value)} class="auix-badge">{@value}</span>
    </div>
    """
  end

  def render(%{auix: %{layout_type: :form}} = assigns),
    do: Renderers.default(assigns)
end
