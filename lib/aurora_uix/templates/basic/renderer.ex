defmodule Aurora.Uix.Web.Templates.Basic.Renderer do
  @moduledoc """
  Main entry point for Aurora UIX template rendering.
  Dispatches rendering to specialized renderer modules based on the template tag and
  provides helpers for rendering inner elements in LiveView components.

  ## Key Features
  - Delegates rendering to specialized renderer modules based on tag type (index, show, form, group, inline, stacked, sections, section, field).
  - Provides a default empty renderer for unhandled cases.
  - Includes a helper for rendering inner elements while maintaining context.
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Renderers

  @doc """
  Renders a template based on its tag type.

  ## Parameters
    - assigns (map()) - Aurora UIX context map with _path and tag information

  ## Tag Types
    - :index - List view of entities
    - :show - Detailed entity view
    - :form - Data entry form
    - :group - Content grouping with title
    - :inline - Horizontal layout container
    - :stacked - Vertical layout container
    - :sections - Tab-based section container
    - :section - Individual section content
    - :field - Form field rendering

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()

  # Top-level renderers
  def render(%{_auix: %{_path: %{tag: :index}}} = assigns),
    do: Renderers.IndexRenderer.render(assigns)

  def render(%{_auix: %{_path: %{tag: :show}}} = assigns),
    do: Renderers.ShowRenderer.render(assigns)

  def render(%{_auix: %{_path: %{tag: :form}}} = assigns),
    do: Renderers.FormRenderer.render(assigns)

  # Group renderer
  def render(%{_auix: %{_path: %{tag: :group}}} = assigns) do
    ~H"""
    <div id={@_auix._path.config[:group_id]} class="p-3 border rounded-md bg-gray-100">
      <h3 class="font-semibold text-lg"><%= @_auix._path.config[:title] %></h3>
      <.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
    </div>
    """
  end

  # Layout renderers
  def render(%{_auix: %{_path: %{tag: :inline}}} = assigns) do
    ~H"""
    <div class="flex flex-col gap-2 sm:flex-row">
      <.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
    </div>
    """
  end

  def render(%{_auix: %{_path: %{tag: :stacked}}} = assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
    </div>
    """
  end

  # Section renderers
  def render(%{_auix: %{_path: %{tag: :sections}}} = assigns) do
    Renderers.SectionsRenderer.render(assigns)
  end

  def render(%{_auix: %{_path: %{tag: :section}}} = assigns) do
    Renderers.SectionsRenderer.section(assigns)
  end

  # Field renderer
  def render(%{_auix: %{_path: %{tag: :field}}} = assigns) do
    Renderers.FieldRenderer.render(assigns)
  end

  # Default empty renderer for unhandled cases
  def render(assigns) do
    ~H"""
    """
  end

  @doc """
  Renders inner elements of a component maintaining the _auix context.

  ## Parameters
    - assigns (map()) - Aurora UIX assigns map with _auix context and inner_elements

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render_inner_elements(map()) :: Phoenix.LiveView.Rendered.t()
  def render_inner_elements(assigns) do
    ~H"""
    <.render _auix={Map.put(@_auix, :_path, inner_path)} auix_entity={@auix_entity} :for={inner_path <- @_auix._path.inner_elements} />
    """
  end
end
