defmodule Aurora.Uix.Templates.Basic.Renderer do
  @moduledoc """
  Main entry point for Aurora UIX template rendering.

  Dispatches rendering to specialized renderer modules based on the template tag and
  provides helpers for rendering inner elements in LiveView components. Handles rendering
  for index, show, form, and layout container tags (group, inline, stacked, sections).
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Templates.Basic.Renderers

  @doc """
  Renders a template based on its tag type.

  ## Parameters
  - `assigns` (map()) - Aurora UIX context map with layout_tree and tag information.

  ## Tag Types
  - `:index` - List view of entities
  - `:show` - Detailed entity view
  - `:form` - Data entry form
  - `:group` - Content grouping with title
  - `:inline` - Horizontal layout container
  - `:stacked` - Vertical layout container
  - `:sections` - Tab-based section container
  - `:section` - Individual section content
  - `:field` - Form field rendering

  ## Returns
  Phoenix.LiveView.Rendered.t() - The rendered template.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()

  # Top-level renderers
  def render(%{auix: %{layout_tree: %{tag: :index}}} = assigns),
    do: Renderers.IndexRenderer.render(assigns)

  def render(%{auix: %{layout_tree: %{tag: :show}}} = assigns),
    do: Renderers.ShowRenderer.render(assigns)

  def render(%{auix: %{layout_tree: %{tag: :form}}} = assigns),
    do: Renderers.FormRenderer.render(assigns)

  # Group renderer
  def render(%{auix: %{layout_tree: %{tag: :group}}} = assigns) do
    ~H"""
    <div id={@auix.layout_tree.config[:group_id]} class="auix-group-container">
      <h3 class="auix-group-title"><%= @auix.layout_tree.config[:title] %></h3>
      <.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
    </div>
    """
  end

  # Layout renderers
  def render(%{auix: %{layout_tree: %{tag: :inline}}} = assigns) do
    ~H"""
    <div class="auix-inline-container">
      <.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
    </div>
    """
  end

  def render(%{auix: %{layout_tree: %{tag: :stacked}}} = assigns) do
    ~H"""
    <div class="auix-stacked-container">
      <.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
    </div>
    """
  end

  # Section renderers
  def render(%{auix: %{layout_tree: %{tag: :sections}}} = assigns) do
    Renderers.SectionsRenderer.render(assigns)
  end

  def render(%{auix: %{layout_tree: %{tag: :section}}} = assigns) do
    Renderers.SectionsRenderer.section(assigns)
  end

  # Field renderer
  def render(%{auix: %{layout_tree: %{tag: :field}}} = assigns) do
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
    - assigns (map()) - Aurora UIX assigns map with auix context and inner_elements

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render_inner_elements(map()) :: Phoenix.LiveView.Rendered.t()
  def render_inner_elements(assigns) do
    ~H"""
    <.render auix={Map.put(@auix, :layout_tree, inner_path)} auix_entity={@auix.entity} :for={inner_path <- inner_path(@auix)} />
    """
  end

  ## PRIVATE ##
  @spec inner_path(map()) :: list()
  defp inner_path(%{
         layout_tree: %{inner_elements: inner_elements},
         fields_to_reject: fields_to_reject
       }) do
    Enum.reject(inner_elements, fn
      %{tag: :field, name: name} -> name in fields_to_reject
      _other -> false
    end)
  end

  defp inner_path(%{layout_tree: %{inner_elements: inner_elements}}) do
    inner_elements
  end
end
