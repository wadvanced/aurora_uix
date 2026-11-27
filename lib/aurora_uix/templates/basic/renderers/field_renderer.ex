defmodule Aurora.Uix.Templates.Basic.Renderers.FieldRenderer do
  @moduledoc """
  Renders a show, form or index-card field by resolving its renderer and invoking it.

  The renderer to call is chosen by `Aurora.Uix.Renderers.resolve/3` from the field's
  slots and the current layout type; the default rendering (standard input, plus
  association / embed / upload delegation) lives in
  `Aurora.Uix.Templates.Basic.Renderers.DefaultRenderer`.
  """

  use Aurora.Uix.CoreComponentsImporter, template: Aurora.Uix.Templates.Basic
  use Aurora.Uix.GettextResolver

  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Node
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

  # A field of an index card: its label and its index value.
  defp do_render(%{auix: %{layout_type: :index} = auix, field: field} = assigns) do
    renderer = Renderers.resolve(field, :index, BasicHelpers.html_type_renderers(auix, :index))

    assigns =
      assigns
      |> assign(:entity, auix.entity)
      |> assign(:renderer, renderer)

    ~H"""
    <div class="auix-items-card-item-fieldset">
      <div class="auix-items-card-item-label">{dt(@field.label)}</div>
      <div class="auix-items-card-item-value" name="auix-column-value">{@renderer.(assigns)}</div>
    </div>
    """
  end

  defp do_render(%{auix: %{layout_type: layout_type} = auix, field: field} = assigns) do
    tables = BasicHelpers.html_type_renderers(auix, layout_type)
    Renderers.resolve(field, layout_type, tables).(assigns)
  end

  # The many-to-one renderer follows the node's association path from this field.
  @spec get_field_info(map()) :: Field.t()
  defp get_field_info(%{layout_tree: %Node.Field{field: field}}), do: field
end
