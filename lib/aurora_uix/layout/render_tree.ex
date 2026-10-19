defmodule Aurora.Uix.Layout.RenderTree do
  @moduledoc """
  Builds one resource layout: fills in what the renderers need on the layout nodes
  (`Aurora.Uix.Layout.Node`) the layout macros produced.

  ## Key Features
  - Fills a missing layout with the default one: every non-association column for `:index`,
    and a `stacked` (or `:default_fields_layout`) sub-layout of the fields for `:form` and `:show`.
  - Resolves each field node's `%Aurora.Uix.Field{}`: the resource field with the layout's
    overrides merged over it.
  - Gives every node an id derived from the resource, the layout type and its position, so ids
    are the same on every compile.
  - Computes the tab state of `sections` and `section` nodes.

  ## Key Constraints
  - The input and the output are the same node structs; only this module fills `id`, the
    field nodes' `field` and the tab state.
  """

  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Resource

  @index_excluded_types [
    :many_to_one_association,
    :one_to_many_association,
    :one_to_one_association,
    :many_to_many_association
  ]

  @form_excluded_types [:many_to_one_association, :one_to_many_association]

  @doc """
  Builds a resource layout for rendering.

  ## Parameters
  - `layout` (Node.layout() | nil) - The layout as the macros produced it, or `nil` to use the
    default one.
  - `layout_type` (:index | :form | :show) - The layout type to build.
  - `resource` (Resource.t()) - The resolved resource the layout renders.
  - `opts` (keyword()) - `auix_create_ui` options; `:default_fields_layout` (`:stacked` or
    `:inline`) shapes the default form and show layouts.

  ## Returns
  `Aurora.Uix.Layout.Node.layout()` - The built layout.
  """
  @spec build(Node.layout() | nil, atom(), Resource.t(), keyword()) :: Node.layout()
  def build(nil, layout_type, resource, opts),
    do: layout_type |> default(resource, opts) |> build(layout_type, resource, opts)

  def build(%Node.Index{} = layout, :index, resource, _opts) do
    %{
      layout
      | id: container_id(resource, :index),
        resource: resource.name,
        children: Enum.map(layout.children, &field_node(&1, resource))
    }
  end

  def build(%{} = layout, layout_type, resource, _opts) when layout_type in [:form, :show] do
    id = container_id(resource, layout_type)

    children =
      layout.children
      |> Enum.with_index()
      |> Enum.map(fn {child, index} -> node(child, "#{id}-#{index}", resource) end)
      |> normalize_sections()

    %{layout | id: id, resource: resource.name, children: children}
  end

  @doc """
  Returns the layout used when none is declared for a resource and layout type.

  ## Parameters
  - `layout_type` (:index | :form | :show) - The layout type.
  - `resource` (Resource.t()) - The resolved resource.
  - `opts` (keyword()) - `auix_create_ui` options, see `build/4`.

  ## Returns
  `Aurora.Uix.Layout.Node.layout()` - The default layout, not built yet.
  """
  @spec default(atom(), Resource.t(), keyword()) :: Node.layout()
  def default(:index, resource, _opts) do
    %Node.Index{
      resource: resource.name,
      children: resource |> field_keys(@index_excluded_types) |> Enum.map(&%Node.Field{key: &1})
    }
  end

  def default(layout_type, resource, opts) when layout_type in [:form, :show] do
    fields = resource |> field_keys(@form_excluded_types) |> Enum.map(&%Node.Field{key: &1})

    fields_layout =
      case Keyword.get(opts, :default_fields_layout, :stacked) do
        :inline -> %Node.Inline{children: fields}
        _stacked -> %Node.Stacked{children: fields}
      end

    struct(container_module(layout_type), %{resource: resource.name, children: [fields_layout]})
  end

  @doc """
  Resolves the `%Aurora.Uix.Field{}` a field node renders.

  ## Parameters
  - `field_node` (Node.Field.t()) - The field as placed in the layout.
  - `resource` (Resource.t()) - The resource the field belongs to.

  ## Returns
  `Aurora.Uix.Field.t()` - The resource field with the layout overrides merged over it, or a new
  field when the resource has no field with that key.
  """
  @spec resolve_field(Node.Field.t(), Resource.t()) :: Field.t()
  def resolve_field(%Node.Field{key: key, overrides: overrides}, resource) do
    resource.fields
    |> Map.get(key)
    |> Kernel.||(Field.new(%{key: key, resource: resource.name}))
    |> merge_overrides(overrides)
  end

  ## PRIVATE

  @spec container_id(Resource.t(), atom()) :: binary()
  defp container_id(resource, layout_type), do: "auix-#{resource.name}-#{layout_type}"

  @spec container_module(atom()) :: module()
  defp container_module(:form), do: Node.Form
  defp container_module(:show), do: Node.Show

  @spec merge_overrides(Field.t(), Field.t() | nil) :: Field.t()
  defp merge_overrides(field, nil), do: field
  defp merge_overrides(field, overrides), do: Field.merge(field, overrides)

  @spec field_keys(Resource.t(), [atom()]) :: [atom()]
  defp field_keys(resource, excluded_types) do
    resource
    |> fields_order()
    |> Enum.reject(&(get_in(resource.fields, [&1, Access.key(:type)]) in excluded_types))
  end

  @spec fields_order(Resource.t()) :: [atom()]
  defp fields_order(%Resource{fields: fields, fields_order: []}), do: Map.keys(fields)
  defp fields_order(%Resource{fields_order: fields_order}), do: fields_order

  @spec field_node(Node.Field.t(), Resource.t()) :: Node.Field.t()
  defp field_node(%Node.Field{} = field_node, resource),
    do: %{field_node | field: resolve_field(field_node, resource)}

  @spec node(Node.t(), binary(), Resource.t()) :: Node.t()
  defp node(%Node.Field{} = field, _id, resource), do: field_node(field, resource)

  defp node(%Node.Inline{} = inline, id, resource),
    do: %{inline | id: "#{id}-inline", children: nodes(inline.children, id, resource)}

  defp node(%Node.Stacked{} = stacked, id, resource),
    do: %{stacked | id: "#{id}-stacked", children: nodes(stacked.children, id, resource)}

  defp node(%Node.Group{} = group, id, resource),
    do: %{
      group
      | id: titled_id("group", group.title, id),
        children: nodes(group.children, id, resource)
    }

  defp node(%Node.Sections{} = sections, id, resource),
    do: %{sections | id: sections_id(id), children: nodes(sections.children, id, resource)}

  defp node(%Node.Section{} = section, id, resource),
    do: %{
      section
      | id: titled_id("section", section.label, id),
        children: nodes(section.children, id, resource)
    }

  @spec nodes([Node.t()], binary(), Resource.t()) :: [Node.t()]
  defp nodes(children, id, resource) do
    children
    |> Enum.with_index()
    |> Enum.map(fn {child, index} -> node(child, "#{id}-#{index}", resource) end)
  end

  # The position part of a node id ("auix-product-form-0-1") follows the "auix-" prefix.
  @spec sections_id(binary()) :: binary()
  defp sections_id("auix-" <> position), do: "auix-sections-#{position}"

  @spec titled_id(binary(), binary() | nil, binary()) :: binary()
  defp titled_id(kind, title, "auix-" <> position), do: "auix-#{kind}-#{slug(title)}-#{position}"

  @spec slug(binary() | nil) :: binary()
  defp slug(title) when title in [nil, ""], do: "untitled"

  defp slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.trim("_")
  end

  ## Sections and tabs

  # Walks the tree in document order. `sections_index` numbers the sections containers from 1;
  # `tab_index` numbers the tabs of a container from 1. A container with no default tab
  # activates its first one.
  @spec normalize_sections([Node.t()]) :: [Node.t()]
  defp normalize_sections(nodes) do
    nodes
    |> normalize_nodes(%{
      counter: 0,
      sections_id: nil,
      sections_index: 0,
      tab_parent_id: nil,
      tab_index: 0,
      tab_active?: false
    })
    |> elem(0)
  end

  @spec normalize_nodes([Node.t()], map()) :: {[Node.t()], non_neg_integer()}
  defp normalize_nodes(nodes, state) do
    {normalized, state} =
      Enum.reduce(nodes, {[], state}, fn node, {acc, state} ->
        {normalized, state} = normalize_node(node, state)
        {[normalized | acc], state}
      end)

    normalized
    |> Enum.reverse()
    |> maybe_activate_first_tab(state.tab_active?)
    |> then(&{&1, state.counter})
  end

  @spec normalize_node(Node.t(), map()) :: {Node.t(), map()}
  defp normalize_node(%Node.Sections{} = sections, state) do
    sections_index = state.counter + 1

    {children, counter} =
      normalize_nodes(sections.children, %{
        state
        | counter: sections_index,
          sections_id: sections.id,
          sections_index: sections_index,
          tab_index: 0,
          tab_active?: false
      })

    tabs =
      children
      |> Enum.filter(&match?(%Node.Section{}, &1))
      |> Enum.map(&%{&1 | children: []})

    {%{sections | index: sections_index, tabs: tabs, children: children},
     %{
       state
       | counter: counter,
         sections_id: sections.id,
         sections_index: sections_index,
         tab_index: 0,
         tab_active?: false
     }}
  end

  defp normalize_node(%Node.Section{} = section, state) do
    tab_index = state.tab_index + 1

    {children, counter} =
      normalize_nodes(section.children, %{
        state
        | tab_parent_id: section.id,
          tab_index: tab_index,
          tab_active?: false
      })

    {%{
       section
       | sections_id: state.sections_id,
         sections_index: state.sections_index,
         tab_parent_id: state.tab_parent_id,
         tab_index: tab_index,
         children: children
     },
     %{
       state
       | counter: counter,
         tab_index: tab_index,
         tab_active?: not state.tab_active? and section.active?
     }}
  end

  defp normalize_node(%{children: children} = node, state) do
    {children, counter} = normalize_nodes(children, state)
    {%{node | children: children}, %{state | counter: counter}}
  end

  defp normalize_node(node, state), do: {node, state}

  @spec maybe_activate_first_tab([Node.t()], boolean()) :: [Node.t()]
  defp maybe_activate_first_tab(nodes, true), do: nodes

  defp maybe_activate_first_tab(nodes, false) do
    case Enum.find_index(nodes, &match?(%Node.Section{}, &1)) do
      nil -> nodes
      index -> List.update_at(nodes, index, &%{&1 | active?: true})
    end
  end
end
