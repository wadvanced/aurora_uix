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
    - auix: Aurora UIX context with configurations and layout_tree info
    - live_action: Current live action (:edit)
    - page_title: Title for edit modal
    - subtitle: Optional subtitle for the header

  ## Returns
  - Phoenix.LiveView.Rendered.t() - Rendered detail view with entity information and actions
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: %{layout_tree: %{tag: :show}}} = assigns) do
    ~H"""
    <div class={get_in(@auix.css_classes, [:show_renderer, :top_container]) || ""}>
      <.header>
        {@auix.layout_options.page_title}
        <:subtitle :if={@auix.layout_options.page_subtitle != nil}>{@auix.layout_options.page_subtitle}</:subtitle>
        <:actions>
          <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{@auix.entity.id}/show/edit"} id={"auix-edit-#{@auix.module}"}>
            <.button>Edit {@auix.name}</.button>
          </.auix_link>
        </:actions>
      </.header>

      <div class="auix-show-container p-4 border rounded-lg shadow bg-white" data-layout="#{name}">
        <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
      </div>

      <div id="auix-show-navigate-back">
        <.auix_back>Back to {@auix.title}</.auix_back>
      </div>

      <.modal :if={@live_action == :edit} auix={%{css_classes: @auix.css_classes}} id={"auix-#{@auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
        <div>
          <.live_component
            module={@auix._form_component}
            id={@auix.entity.id || :new}
            title={@auix.layout_options.edit_title}
            subtitle={@auix.layout_options.edit_subtitle}
            action={@live_action}
            auix={%{css_classes: @auix.css_classes, entity: @auix.entity, routing_stack: @auix.routing_stack}}
          />
        </div>
      </.modal>
    </div>
    """
  end
end
