defmodule Aurora.Uix.Templates.Basic.Renderer do
  @moduledoc """
  Main entry point for Aurora UIX template rendering.

  Dispatches rendering to specialized renderer modules based on the template tag and
  provides helpers for rendering inner elements in LiveView components. Handles rendering
  for index, show, form, and layout container tags (group, inline, stacked, sections).
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Templates.Basic.Renderers

  @doc """
  Renders a template based on its tag type.

  ## Parameters
  - `assigns` (map()) - Aurora UIX context map whose `auix.layout_tree` is a render node.

  ## Node Types (`Aurora.Uix.Layout.Node`)
  - `Index` - List view of entities
  - `Show` - Detailed entity view
  - `Form` - Data entry form
  - `Group` - Content grouping with title
  - `Inline` - Horizontal layout container
  - `Stacked` - Vertical layout container
  - `Sections` - Tab-based section container
  - `Section` - Individual section content
  - `Field` - Form field rendering

  ## Returns
  Phoenix.LiveView.Rendered.t() - The rendered template.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()

  # Top-level renderers
  def render(%{auix: %{layout_tree: %Node.Index{}}} = assigns),
    do: Renderers.IndexRenderer.render(assigns)

  def render(%{auix: %{layout_tree: %Node.Show{}}} = assigns),
    do: Renderers.ShowComponentRenderer.render(assigns)

  def render(%{auix: %{layout_tree: %Node.Form{}}} = assigns),
    do: Renderers.FormRenderer.render(assigns)

  # Group renderer
  def render(%{auix: %{layout_tree: %Node.Group{}}} = assigns) do
    ~H"""
    <div id={@auix.layout_tree.id} class="auix-group-container">
      <h3 class="auix-group-title"><%= @auix.layout_tree.title %></h3>
      <.render_inner_elements auix={@auix} auix_entity={@auix.entity} uploads={assigns[:uploads] || %{}} />
    </div>
    """
  end

  # Layout renderers
  def render(%{auix: %{layout_tree: %Node.Inline{}}} = assigns) do
    ~H"""
    <div class="auix-inline-container">
      <.render_inner_elements auix={@auix} auix_entity={@auix.entity} uploads={assigns[:uploads] || %{}} />
    </div>
    """
  end

  def render(%{auix: %{layout_tree: %Node.Stacked{}}} = assigns) do
    ~H"""
    <div class="auix-stacked-container">
      <.render_inner_elements auix={@auix} auix_entity={@auix.entity} uploads={assigns[:uploads] || %{}} />
    </div>
    """
  end

  # Section renderers
  def render(%{auix: %{layout_tree: %Node.Sections{}}} = assigns) do
    Renderers.SectionsRenderer.render(assigns)
  end

  def render(%{auix: %{layout_tree: %Node.Section{}}} = assigns) do
    Renderers.SectionsRenderer.section(assigns)
  end

  # Field renderer
  def render(%{auix: %{layout_tree: %Node.Field{}}} = assigns) do
    Renderers.FieldRenderer.render(assigns)
  end

  # Default empty renderer for unhandled cases
  def render(assigns) do
    ~H"""
    """
  end

  @doc """
  Renders inner elements of a component maintaining the auix context.

  ## Parameters
    - assigns (map()) - Aurora UIX assigns map whose `auix.layout_tree` node has children

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render_inner_elements(map()) :: Phoenix.LiveView.Rendered.t()
  def render_inner_elements(assigns) do
    ~H"""
    <.render auix={Map.put(@auix, :layout_tree, inner_path)} auix_entity={@auix.entity} uploads={assigns[:uploads] || %{}} :for={inner_path <- inner_path(@auix)} />
    """
  end

  ## PRIVATE ##
  @spec inner_path(map()) :: list()
  defp inner_path(%{layout_tree: %{children: children}, fields_to_reject: fields_to_reject}) do
    Enum.reject(children, fn
      %Node.Field{key: key} -> key in fields_to_reject
      _other -> false
    end)
  end

  defp inner_path(%{layout_tree: %{children: children}}), do: children
end
