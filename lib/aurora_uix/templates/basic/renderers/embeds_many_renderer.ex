defmodule Aurora.Uix.Templates.Basic.Renderers.EmbedsManyRenderer do
  @moduledoc """
  A renderer component for embeds_many field types in Aurora.Uix forms.

  This renderer delegates the display and interaction logic for embeds_many
  associations to the `EmbedsManyComponent` LiveComponent. It serves as a thin
  wrapper that transforms field configuration into the appropriate component
  invocation.

  ## Required Assigns

  * `:auix` - The Aurora.Uix context containing form configuration
  * `:field` - Field definition map with `:html_id` key for unique identification

  ## Example

      <EmbedsManyRenderer.render
        auix={@auix}
        field={%{
          html_id: "user_addresses",
          type: :embeds_many,
          schema: Address
        }}
      />
  """

  import Phoenix.Component, only: [sigil_H: 2, live_component: 1]
  alias Aurora.Uix.Templates.Basic.EmbedsManyComponent

  @doc """
  Renders an embeds_many field using the EmbedsManyComponent.

  Creates a live component instance with a generated ID based on the field's
  HTML identifier, passing through the Aurora.Uix context and field
  configuration.

  ## Parameters

  * `assigns` (map()) - Component assigns containing:
    * `:auix` (map()) - Aurora.Uix context with form state and configuration
    * `:field` (map()) - Field definition including `:html_id` and schema info

  ## Returns

  A rendered Phoenix.LiveView.Rendered struct containing the live component.
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
