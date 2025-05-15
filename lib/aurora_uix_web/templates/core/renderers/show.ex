defmodule Aurora.Uix.Web.Templates.Core.Renderers.Show do
  @moduledoc """
  Renderer module for show pages in Aurora UIX.

  Handles the rendering of detail views for individual entities, including
  an edit modal and layout-aware content rendering.
  """

  use Aurora.Uix.Web.CoreComponents

  alias Aurora.Uix.Web.Templates.Core.Renderer
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
        <.link patch={"/#{@_auix.link_prefix}#{@_auix.source}/#{@auix_entity.id}/show/edit#{@_auix_source_link}"} phx-click={JS.push_focus()} id={"auix-edit-#{@_auix.module}"}>
          <.button>Edit {@_auix.name}</.button>
        </.link>
      </:actions>
    </.header>

    <div class="auix-show-container p-4 border rounded-lg shadow bg-white" data-layout="#{name}">
      <Renderer.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
    </div>

    <div id="auix-show-navigate-back">
      <.back navigate={"/#{@_auix.link_prefix}#{@_auix_source}"}>Back to {@_auix.title}</.back>
    </div>

    <.modal :if={@live_action == :edit} id={"auix-#{@_auix.module}-modal"} show on_cancel={JS.patch("/#{@_auix.link_prefix}#{@_auix.source}/#{@auix_entity.id}")}>
      <div>
        <.live_component
          module={@_auix._form_component}
          id={@auix_entity.id || :new}
          title={@page_title}
          source={@_auix.source}
          action={@live_action}
          auix_entity={@auix_entity}
          patch={"/#{@_auix.link_prefix}#{@_auix.source}"}
        />
      </div>
    </.modal>

    """
  end
end
