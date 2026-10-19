defmodule Aurora.Uix.Templates.Basic.Renderers.ManyToOne do
  @moduledoc """
  Renders many-to-one association fields for Aurora UIX in Phoenix LiveView templates.

  ## Key Features

  - Displays and manages single associated records
  - Groups and labels associated fields
  - Supports nested rendering of related fields
  - Handles both form and show modes
  - Manages label and layout_tree configuration for associations
  - Integrates with Aurora UIX context and helpers
  """

  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a many-to-one association field.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:field` (map()) - Field configuration with association details.
    * `:auix` (map()) - Aurora UIX context and configuration.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered many-to-one association component.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{
          field: %{type: :many_to_one_association} = field_struct,
          auix: %{layout_tree: %Node.Field{path: []}} = auix
        } = assigns
      ) do
    children = get_association_paths(field_struct, auix.configurations, :show)

    association_label =
      get_in(auix.configurations, [field_struct.data.resource, :parsed_opts, :name])

    assigns
    |> put_in([:auix, :layout_tree], %Node.Group{
      id: "#{field_struct.html_id}",
      title: association_label,
      children: children
    })
    |> put_in([:auix, :_ignore_association_label], true)
    |> Renderer.render()
  end

  def render(%{field: %{type: :many_to_one_association}} = assigns) do
    assigns
    |> parse_many_to_one_value()
    |> set_many_to_one_resource()
    |> Renderer.render()
  end

  # Gets the related resource's layout, with every field reached through `field_struct`.
  @spec get_association_paths(Field.t(), map(), atom()) :: [Node.t()]
  defp get_association_paths(field_struct, configurations, layout_type) do
    configurations
    |> BasicHelpers.layout_children(field_struct.data.resource, layout_type)
    |> Enum.map(&through_association(&1, field_struct))
  end

  @spec through_association(Node.t(), Field.t()) :: Node.t()
  defp through_association(%Node.Field{key: key, path: path} = node, field_struct),
    do: %{node | key: field_struct.key, path: [key | path], field: field_struct}

  defp through_association(%{children: children} = node, field_struct),
    do: %{node | children: Enum.map(children, &through_association(&1, field_struct))}

  defp through_association(node, _field_struct), do: node

  # Narrows the entity to the record that holds the last field of the path.
  @spec parse_many_to_one_value(map()) :: map()
  defp parse_many_to_one_value(
         %{
           auix: %{
             layout_tree: %Node.Field{key: key, path: path},
             layout_type: :show,
             entity: entity
           }
         } =
           assigns
       ) do
    [key | path]
    |> delete_last()
    |> Enum.reduce(entity, &Map.get(&2, &1, %{}))
    |> then(&put_in(assigns, [:auix, :entity], &1))
  end

  defp parse_many_to_one_value(
         %{auix: %{layout_tree: %Node.Field{key: key}, form: form, layout_type: :form}} = assigns
       ) do
    assigns
    |> put_in([:auix, :entity], %{key => form[key].value})
    |> put_in([:auix, :layout_type], :show)
    |> parse_many_to_one_value()
  end

  # Resolves the last field of the path and makes it the node to render.
  @spec set_many_to_one_resource(map()) :: map()
  defp set_many_to_one_resource(
         %{
           auix: %{layout_tree: %Node.Field{path: path}, configurations: configurations} = auix,
           field: parent_field_struct
         } = assigns
       ) do
    ignore_association_label? = Map.get(auix, :_ignore_association_label, false)

    field_struct =
      configurations
      |> get_in([parent_field_struct.resource, :parsed_opts, :name])
      |> then(&Map.put(parent_field_struct, :label, &1))

    field =
      Enum.reduce(path, field_struct, fn field_name, parent_field ->
        parent_field
        |> maybe_ignore_parent_label(ignore_association_label?)
        |> get_many_to_one_field(field_name, configurations)
      end)

    assigns
    |> put_in(
      [
        :auix,
        :configurations,
        field.resource,
        :resource_config,
        Access.key!(:fields),
        field.key
      ],
      field
    )
    |> put_in([:auix, :resource_name], field.resource)
    |> put_in([:auix, :layout_tree], %Node.Field{key: field.key, field: field})
  end

  # Gets a nested field for a many-to-one association
  @spec get_many_to_one_field(map(), atom(), map()) :: map()
  defp get_many_to_one_field(
         %{data: %{resource: resource_name}} = parent_field,
         field_name,
         configurations
       ) do
    parent_field
    |> Map.put(:resource, resource_name)
    |> Map.put(:data, %{})
    |> get_many_to_one_field(field_name, configurations)
  end

  defp get_many_to_one_field(
         %{resource: resource_name, label: parent_label} = _parent_field,
         field_name,
         configurations
       ) do
    field_name
    |> BasicHelpers.get_field(configurations, resource_name)
    |> struct(%{readonly: true, disabled: true})
    |> Map.update(:label, "", &"#{parent_label}#{&1}")
  end

  # Optionally ignores the parent label for nested associations
  @spec maybe_ignore_parent_label(map(), boolean()) :: map()
  defp maybe_ignore_parent_label(%{label: label} = parent_field, false),
    do: Map.put(parent_field, :label, "#{label} ")

  defp maybe_ignore_parent_label(parent_field, true), do: Map.put(parent_field, :label, "")

  # Deletes the last element from a list
  @spec delete_last(list()) :: list()
  defp delete_last(list) do
    list
    |> Enum.reverse()
    |> then(fn [_first | rest] -> rest end)
    |> Enum.reverse()
  end
end
