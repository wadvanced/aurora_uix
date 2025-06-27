defmodule Aurora.Uix.Web.Templates.Basic.Renderers.ShowRenderer do
  @moduledoc """
  Renders detail (show) views for individual entities in Aurora UIX.

  ## Key Features

  - Displays entity attributes with layout support
  - Provides edit functionality via modal popup form
  - Consistent navigation with back button
  - Supports CSS class customization
  - Layout-aware content rendering
  - Integrates with Aurora UIX context and helpers
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Renderer
  alias Phoenix.LiveView.JS

  @doc """
  Renders a detail view page for an individual entity.

  ## Parameters
  - assigns (map()) - LiveView assigns containing:
    - _auix: Aurora UIX context with configurations and path info
    - auix_entity: Entity being displayed
    - live_action: Current live action (:edit)
    - page_title: Title for edit modal
    - subtitle: Optional subtitle for the header

  ## Returns
  - Phoenix.LiveView.Rendered.t() - Rendered detail view with entity information and actions
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{_auix: %{_path: %{tag: :show}}} = assigns) do
    ~H"""
    <div class={get_in(@_auix._css_classes, [:show_renderer, :top_container]) || ""}>
      <.header>
        {@_auix.layout_options.page_title}
        <:subtitle>{@subtitle}</:subtitle>
        <:actions>
          <.auix_link patch={"/#{@_auix.link_prefix}#{@_auix.source}/#{@auix_entity.id}/show/edit"} id={"auix-edit-#{@_auix.module}"}>
            <.button>Edit {@_auix.name}</.button>
          </.auix_link>
        </:actions>
      </.header>

      <div class="auix-show-container p-4 border rounded-lg shadow bg-white" data-layout="#{name}">
        <Renderer.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
      </div>

      <div id="auix-show-navigate-back">
        <.auix_back>Back to {@_auix.title}</.auix_back>
      </div>

      <.modal :if={@live_action == :edit} auix_css_classes={@_auix._css_classes} id={"auix-#{@_auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
        <div>
          <.live_component
            module={@_auix._form_component}
            id={@auix_entity.id || :new}
            title={@_auix.layout_options.page_title}
            action={@live_action}
            auix_entity={@auix_entity}
            auix_routing_stack={@_auix._routing_stack}
            auix_css_classes={@_auix._css_classes}
          />
        </div>
      </.modal>
    </div>
    """
  end
end
