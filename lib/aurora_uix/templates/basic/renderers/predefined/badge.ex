defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Badge do
  @moduledoc """
  Predefined `:badge` renderer for enum / status string fields.

  - `:index` / `:show` — the value as a coloured pill.
  - `:form` — editing is not special; delegates to the default input.
  """

  use Aurora.Uix.Renderer

  alias Aurora.Uix.Renderers

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <span :if={not is_nil(@value)} class="auix-badge">{@value}</span>
    """
  end

  def render(%{auix: %{layout_type: :form}} = assigns),
    do: Renderers.default(assigns)
end
