defmodule Aurora.Uix.Templates.Basic.RoutingComponents do
  @moduledoc """
  Provides routing-related UI components for navigation in Phoenix LiveView applications using Aurora UIX. These components enable navigation and back actions that integrate with Aurora's routing system.

  ## Key Features
  - Provides navigation link components that trigger forward or back navigation events.
  - Supports both standard and styled back navigation links.
  - Designed for use with Phoenix LiveView and Aurora UIX routing.
  - Accepts custom HTML attributes and content slots for flexible usage.

  Components in this module can be overridden at runtime by configuring
  `config :aurora_uix, :basic_routing_components, MyApp.MyRoutingComponents`.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.ComponentsResolver, :basic_routing_components
  use Phoenix.Component

  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a link that triggers navigation via a click event.

  ## Attributes
  - navigate - Target path for navigation
  - patch - Target path for patching
  - rest - Additional HTML attributes for the anchor tag

  ## Slots
  - inner_block - Required. The content to be displayed within the link

  ## Returns
  Phoenix LiveView rendered content

  """
  @spec auix_link(map()) :: Rendered.t()
  attr(:navigate, :string)
  attr(:patch, :string)
  attr(:host_components, :any)
  attr(:rest, :global, include: ~w(class name download href lang referrer policy rel target type))
  slot(:inner_block, required: true)

  def auix_link(%{navigate: to, host_components: nil} = assigns) when is_binary(to) do
    ~H"""
    <a
      phx-click="auix_route_forward"
      phx-value-route_type={:navigate}
      phx-value-route_path={@navigate}
      phx-no-format
      {@rest}
    >{render_slot(@inner_block)}</a>
    """
  end

  def auix_link(%{patch: to, host_components: nil} = assigns) when is_binary(to) do
    ~H"""
    <a
      phx-click="auix_route_forward"
      phx-value-route_type={:patch}
      phx-value-route_path={@patch}
      phx-no-format
      {@rest}
    >{render_slot(@inner_block)}</a>
    """
  end

  def auix_link(%{host_components: nil} = assigns) do
    ~H"""
    <a
      phx-no-format
      {@rest}>
      {render_slot(@inner_block)}
    </a>
    """
  end

  resolve_component_for(:auix_link)

  @doc """
  Renders a simple back navigation link without styling.

  ## Attributes
  - rest - Additional HTML attributes for the anchor tag

  ## Slots
  - inner_block - Required. The content to be displayed within the link

  ## Returns
  Phoenix LiveView rendered content
  """
  attr(:host_components, :any)
  attr(:rest, :global, include: ~w(download hreflang referrerpolicy rel target type))
  slot(:inner_block, required: true)
  @spec auix_link_back(map()) :: Rendered.t()
  def auix_link_back(%{host_components: nil} = assigns) do
    ~H"""
    <a
      phx-click="auix_route_back"
      phx-no-format
      {@rest}>
      {render_slot(@inner_block)}
    </a>
    """
  end

  resolve_component_for(:auix_link_back)

  @doc """
  Renders a styled back navigation link with an arrow icon.

  ## Attributes
  - rest - Additional HTML attributes for the anchor tag

  ## Slots
  - inner_block - Required. The content to be displayed within the link

  ## Returns
  Phoenix LiveView rendered content
  """
  attr(:host_components, :any)
  attr(:rest, :global, include: ~w(download hreflang referrerpolicy rel target type))
  slot(:inner_block, required: true)
  @spec auix_back(map()) :: Rendered.t()
  def auix_back(%{host_components: nil} = assigns) do
    ~H"""
    <div class="auix-back-link-container">
      <a
        phx-click="auix_route_back"
        phx-no-format
        class="auix-back-link"
        {@rest}
      >
        <.icon name="hero-arrow-left" class="auix-icon-size-3" />
        {render_slot(@inner_block)}
      </a>
    </div>
    """
  end

  resolve_component_for(:auix_back)
end
