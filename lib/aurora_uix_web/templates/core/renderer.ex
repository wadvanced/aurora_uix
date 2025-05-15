defmodule Aurora.Uix.Web.Templates.Core.Renderer do
  @moduledoc """
  Main entry point for Aurora UIX template rendering.
  Dispatches rendering to specialized renderer modules based on the template tag.
  """

  use Aurora.Uix.Web.CoreComponents

  alias Aurora.Uix.Web.Templates.Core.Renderers

  @doc """
  Renders a template based on its tag type.

  ## Parameters
    - assigns (map()) - The assigns map (Aurora UIX context)

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()

  # Top-level renderers
  def render(%{_auix: %{_path: %{tag: :index}}} = assigns), do: Renderers.Index.render(assigns)
  def render(%{_auix: %{_path: %{tag: :show}}} = assigns), do: Renderers.Show.render(assigns)

  # Form renderer
  def render(%{_auix: %{_path: %{tag: :form}}} = assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage {@_auix.title} records in your database.</:subtitle>
      </.header>

      <.flash kind={:error} flash={@flash} title="Error!" />

      <.simple_form
        for={@form}
        id={"auix-#{@_auix.module}-form"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="auix-form-container p-4 border rounded-lg shadow bg-white" data-layout={@_auix._path.name}>
          <.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
        </div>
        <:actions>
          <.button phx-disable-with="Saving..." id={"auix-save-#{@_auix.source}"}>Save {@_auix.name}</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # Group renderer
  def render(%{_auix: %{_path: %{tag: :group}}} = assigns) do
    ~H"""
    <div id={@_auix._path.config[:group_id]} class="p-3 border rounded-md bg-gray-100">
      <h3 class="font-semibold text-lg"><%= @_auix._path.config[:title] %></h3>
      <%= render_inner_elements(%{_auix: @_auix, auix_entity: @auix_entity}) %>
    </div>
    """
  end

  def render(%{_auix: %{_path: %{tag: :inline}}} = assigns) do
    Renderers.Layout.inline(assigns)
  end

  def render(%{_auix: %{_path: %{tag: :stacked}}} = assigns) do
    Renderers.Layout.stacked(assigns)
  end

  # Section renderers
  def render(%{_auix: %{_path: %{tag: :sections}}} = assigns) do
    Renderers.Sections.render(assigns)
  end

  def render(%{_auix: %{_path: %{tag: :section}}} = assigns) do
    Renderers.Sections.section(assigns)
  end

  # Field renderer
  def render(%{_auix: %{_path: %{tag: :field}}} = assigns) do
    Renderers.Field.render(assigns)
  end

  # Default empty renderer for unhandled cases
  def render(assigns) do
    ~H"""
    """
  end

  @doc """
  Renders inner elements of a component maintaining the _auix context.
  Used by layout components to render their inner content.

  ## Parameters
    - assigns (map()) - The assigns map containing:
      - _auix: The Aurora UIX context including inner_elements to render
  """
  def render_inner_elements(assigns) do
    ~H"""
    <.render _auix={Map.put(@_auix, :_path, inner_path)} auix_entity={@auix_entity} :for={inner_path <- @_auix._path.inner_elements} />
    """
  end
end
