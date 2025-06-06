defmodule Aurora.Uix.Web.Templates.Basic.Renderers.ShowRenderer do
  @moduledoc """
  Renderer module for show pages in Aurora UIX.

  Handles the rendering of detail views for individual entities, including
  an edit modal and layout-aware content rendering.
  """

  use Aurora.Uix.Web.CoreComponentsImporter
  import Aurora.Uix.Web.Templates.Basic.RoutingComponents

  alias Aurora.Uix.Web.Templates.Basic.Renderer
  alias Phoenix.LiveView.JS

  @doc """
  Renders a show page for an individual entity.

  ## Parameters
    - assigns (map()) - The assigns map (Aurora UIX context)
  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{_auix: %{_path: %{tag: :show}}} = assigns) do
    ~H"""
    <.header>
      {@_auix.name} {@auix_entity.id}
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

    <.modal :if={@live_action == :edit} id={"auix-#{@_auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
      <div>
        <.live_component
          module={@_auix._form_component}
          id={@auix_entity.id || :new}
          title={@page_title}
          action={@live_action}
          auix_entity={@auix_entity}
          auix_routing_stack={@_auix._routing_stack}
        />
      </div>
    </.modal>

    """
  end
end
