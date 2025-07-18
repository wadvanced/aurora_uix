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

  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a many-to-one association field.

  ## Parameters
  - assigns (map()) - LiveView assigns, must include:
    - field (map()) - Field configuration
    - auix (map()) - Aurora UIX configuration

  ## Returns
  - Phoenix.LiveView.Rendered.t()

  ## Example
      render(%{field: field, auix: auix})
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{
          field: %{type: :many_to_one_association} = field_struct,
          auix: %{layout_tree: %{name: field_name}} = auix
        } = assigns
      )
      when is_atom(field_name) do
    inner_elements = get_association_paths(field_struct, auix.configurations, :show)
    association_label = get_in(auix.configurations, [field_struct.resource, :parsed_opts, :name])

    assigns
    |> put_in([:auix, :layout_tree], %{
      tag: :group,
      config: [group_id: "#{field_struct.html_id}", title: association_label],
      inner_elements: inner_elements
    })
    |> put_in([:auix, :_ignore_association_label], true)
    |> Renderer.render()
  end

  def render(%{field: %{type: :many_to_one_association}} = assigns) do
    assigns
    |> parse_many_to_one_value()
    |> set_many_to_one_resource()
    |> trim_path()
    |> Renderer.render()
  end

  # Gets association field paths for rendering nested fields
  @spec get_association_paths(map(), map(), atom()) :: list()
  defp get_association_paths(field_struct, configurations, path_type) do
    configurations
    |> get_in([field_struct.data.resource, :defaulted_paths, path_type, :inner_elements])
    |> Kernel.||([])
    |> convert_to_many_to_one_paths(field_struct.key)
  end

  # Converts a list of paths to many-to-one field paths
  @spec convert_to_many_to_one_paths(list(), atom()) :: list()
  defp convert_to_many_to_one_paths(paths, parent_field) do
    Enum.map(paths, &convert_to_many_to_one_path(&1, parent_field))
  end

  # Converts a single layout_tree to a many-to-one field layout_tree
  @spec convert_to_many_to_one_path(map(), atom()) :: map()
  defp convert_to_many_to_one_path(
         %{tag: :field, name: field_name, inner_elements: inner_elements} = layout_tree,
         parent_field
       ) do
    Map.merge(layout_tree, %{
      name: {parent_field, field_name},
      inner_elements: convert_to_many_to_one_paths(inner_elements, parent_field)
    })
  end

  defp convert_to_many_to_one_path(%{inner_elements: inner_elements} = layout_tree, parent_field) do
    Map.put(
      layout_tree,
      :inner_elements,
      convert_to_many_to_one_paths(inner_elements, parent_field)
    )
  end

  # Parses the value for a many-to-one association, handling tuple and atom names
  @spec parse_many_to_one_value(map()) :: map()
  defp parse_many_to_one_value(%{auix: %{layout_tree: %{name: name}}} = assigns)
       when is_atom(name),
       do: assigns

  defp parse_many_to_one_value(
         %{auix: %{layout_tree: %{name: names}, layout_type: :show, entity: entity}} =
           assigns
       )
       when is_tuple(names) do
    names
    |> Tuple.to_list()
    |> delete_last()
    |> Enum.reduce(entity, &Map.get(&2, &1, %{}))
    |> then(&put_in(assigns, [:auix, :entity], &1))
  end

  defp parse_many_to_one_value(
         %{auix: %{layout_tree: %{name: names}, form: form, layout_type: :form}} = assigns
       )
       when is_tuple(names) do
    names
    |> Tuple.to_list()
    |> List.first()
    |> then(&%{&1 => form[&1].value})
    |> then(&put_in(assigns, [:auix, :entity], &1))
    |> put_in([:auix, :layout_type], :show)
    |> parse_many_to_one_value()
  end

  # Sets the resource for a many-to-one association, updating assigns
  @spec set_many_to_one_resource(map()) :: map()
  defp set_many_to_one_resource(%{auix: %{layout_tree: %{name: name}}} = assigns)
       when is_atom(name),
       do: assigns

  defp set_many_to_one_resource(
         %{
           auix: %{layout_tree: %{name: names}, configurations: configurations} = auix,
           field: parent_field_struct
         } = assigns
       ) do
    ignore_association_label? = Map.get(auix, :_ignore_association_label, false)

    field_struct =
      configurations
      |> get_in([parent_field_struct.resource, :parsed_opts, :name])
      |> then(&Map.put(parent_field_struct, :label, &1))

    field =
      names
      |> Tuple.delete_at(0)
      |> Tuple.to_list()
      |> Enum.reduce(field_struct, fn field_name, parent_field ->
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
    |> Map.delete(:data)
    |> get_many_to_one_field(field_name, configurations)
  end

  defp get_many_to_one_field(
         %{resource: resource_name, label: parent_label} = _parent_field,
         field_name,
         configurations
       ) do
    %{name: field_name}
    |> BasicHelpers.get_field(configurations, resource_name)
    |> struct(%{readonly: true, disabled: true})
    |> Map.update(:label, "", &"#{parent_label}#{&1}")
  end

  # Optionally ignores the parent label for nested associations
  @spec maybe_ignore_parent_label(map(), boolean()) :: map()
  defp maybe_ignore_parent_label(%{label: label} = parent_field, false),
    do: Map.put(parent_field, :label, "#{label} ")

  defp maybe_ignore_parent_label(parent_field, true), do: Map.put(parent_field, :label, "")

  # Trims the layout_tree for a many-to-one association to the last element
  @spec trim_path(map()) :: map()
  defp trim_path(%{auix: %{layout_tree: %{name: name}}} = assigns) when is_atom(name), do: assigns

  defp trim_path(%{auix: %{layout_tree: %{name: names}}} = assigns) do
    names
    |> Tuple.to_list()
    |> List.last()
    |> then(&put_in(assigns, [:auix, :layout_tree, :name], &1))
  end

  # Deletes the last element from a list
  @spec delete_last(list()) :: list()
  defp delete_last([]), do: []

  defp delete_last(list) do
    list
    |> Enum.reverse()
    |> then(fn [_first | rest] -> rest end)
    |> Enum.reverse()
  end
end
