defmodule Aurora.Uix.Templates.Basic.Renderers.FieldRenderer do
  @moduledoc """
  Renders a show/form field by resolving its renderer and invoking it.

  The renderer to call is chosen by `Aurora.Uix.Renderers.resolve/2` from the field's
  slots and the current layout type; the default rendering (standard input, plus
  association / embed / upload delegation) lives in
  `Aurora.Uix.Templates.Basic.Renderers.DefaultRenderer`.
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Renderers
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers

  @doc """
  Renders a field for the current layout type.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with configuration and `:layout_type`.

  ## Returns
  Phoenix.LiveView.Rendered.t() - The rendered field component.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: auix} = assigns) do
    field = get_field_info(auix)

    assigns
    |> assign(:field, field)
    |> do_render()
  end

  # PRIVATE

  @spec do_render(map()) :: Phoenix.LiveView.Rendered.t()
  defp do_render(%{field: %{omitted: true}} = assigns), do: ~H""

  defp do_render(%{auix: %{layout_type: layout_type}, field: field} = assigns),
    do: Renderers.resolve(field, layout_type).(assigns)

  # Returns field info for rendering, handling tuple and atom names
  @spec get_field_info(map()) :: map()
  defp get_field_info(%{
         layout_tree: %{name: name} = layout_tree,
         configurations: configurations,
         resource_name: resource_name
       })
       when is_tuple(name) do
    name
    |> elem(0)
    |> then(&Map.put(layout_tree, :name, &1))
    |> BasicHelpers.get_field(configurations, resource_name)
  end

  defp get_field_info(%{
         layout_tree: layout_tree,
         configurations: configurations,
         resource_name: resource_name
       }) do
    BasicHelpers.get_field(layout_tree, configurations, resource_name)
  end
end
