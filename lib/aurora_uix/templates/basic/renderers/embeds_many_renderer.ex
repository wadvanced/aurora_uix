defmodule Aurora.Uix.Templates.Basic.Renderers.EmbedsManyRenderer do
  @moduledoc """
  Renders embeds_many field types in Aurora UIX forms.

  ## Key Features

  - Delegates embeds_many association rendering to the EmbedsManyComponent.
  - Transforms field configuration into appropriate component invocation.
  - Supports dynamic embedded collection management.

  ## Key Constraints

  - Requires `:auix` with form configuration and `:field` with schema information.
  """

  import Phoenix.Component, only: [sigil_H: 2, live_component: 1]
  alias Aurora.Uix.Templates.Basic.EmbedsManyComponent

  @doc """
  Renders an embeds_many field using the EmbedsManyComponent.

  ## Parameters
  - `assigns` (map()) - Component assigns containing:
    * `:auix` (map()) - Aurora UIX context with form state and configuration.
    * `:field` (map()) - Field definition including `:html_id` and schema info.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered live component for embeds_many field.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.live_component
      id={"#{@field.html_id}-#{@auix.layout_type}"}
      module={EmbedsManyComponent}
      auix={@auix}
      field={@field}
      />
    """
  end
end
