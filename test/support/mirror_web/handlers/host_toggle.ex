defmodule Aurora.UixWeb.Test.Mirror.Handlers.HostToggle do
  @moduledoc false
  use Aurora.Uix.Renderer

  @impl Aurora.Uix.Renderer
  def render(assigns) do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <span class="auix-host-toggle">HOST:{@value}</span>
    """
  end
end
