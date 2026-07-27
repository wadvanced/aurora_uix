defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Url do
  @moduledoc """
  Predefined `:url` renderer for string fields holding a link.

  - `:index` / `:show` — the value as a clickable link opening in a new tab.
  - `:form` — editing is not special; delegates to the default text input.
  """

  use Aurora.Uix.Renderer

  alias Aurora.Uix.Renderers

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <.link :if={@value not in [nil, ""]} href={@value} target="_blank" rel="noopener" class="auix-url">
      {@value}
    </.link>
    """
  end

  def render(%{auix: %{layout_type: :form}} = assigns),
    do: Renderers.default(assigns)
end
