defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Url do
  @moduledoc """
  Predefined `:url` renderer for string fields holding a link.

  - `:index` — editing is not special; delegates to the default plain-text cell,
    since a clickable link here would compete with the row's click-to-show navigation.
  - `:show` — the value as a clickable link opening in a new tab.
  - `:form` — editing is not special; delegates to the default text input.
  """

  use Aurora.Uix.Renderer

  alias Aurora.Uix.Renderers

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: :show}} = assigns) do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <div class="auix-show-field">
      <span class="auix-label">{dt(@field.label)}</span>
      <.link :if={@value not in [nil, ""]} href={@value} target="_blank" rel="noopener" class="auix-url">
        {@value}
      </.link>
    </div>
    """
  end

  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :form],
    do: Renderers.default(assigns)
end
