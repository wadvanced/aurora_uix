defmodule Aurora.Uix.Layout.ResourceResolver do
  @moduledoc """
  Turns declared resources (`Aurora.Uix.Layout.Resource`) into resolved ones (`Aurora.Uix.Resource`).

  For every declared resource it adds the embedded resources its schema defines, parses the
  schema fields with the backend's fields parser, adds the associations, builds the
  many-to-one selectors and applies the host's field overrides.

  ## Key Features
  - The only code that knows both the declared and the resolved resource.
  - Field overrides are applied in declaration order; fields the schema does not define are
    appended after the parsed ones.

  ## Key Constraints
  - Runs at compile time, from the `__before_compile__` of `Aurora.Uix.Layout.ResourceMetadata`.
  """

  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Layout.Resource, as: DeclaredResource
  alias Aurora.Uix.Layout.Resource.FieldOverride
  alias Aurora.Uix.Resource

  @doc """
  Resolves declared resources.

  ## Parameters
  - `declared_resources` (list(DeclaredResource.t())) - The resources in declaration order.

  ## Returns
  `%{atom() => Aurora.Uix.Resource.t()}` - Resolved resources by name.
  """
  @spec resolve([DeclaredResource.t()]) :: %{atom() => Resource.t()}
  def resolve(declared_resources) do
    # Resolved latest declaration first, as before declarations were structs: an association
    # points to the latest resource declared for its schema, and a resource name declared twice
    # keeps its first declaration.
    declared_resources
    |> Enum.reverse()
    |> add_embedded_resources()
    |> Enum.map(&parse_resource/1)
    |> add_associations()
    |> Map.new()
  end

  ## PRIVATE

  @spec add_embedded_resources([DeclaredResource.t()]) :: [DeclaredResource.t()]
  defp add_embedded_resources(declared_resources) do
    declared_resources
    |> Enum.reject(&is_nil(&1.schema))
    |> Enum.reduce(declared_resources, fn declared, result ->
      type = resource_type(declared)

      type
      |> LayoutHelpers.get_fields_parser_module()
      |> then(& &1.embedded_resource({declared.name, declared.schema, type}, result))
    end)
  end

  @spec parse_resource(DeclaredResource.t()) :: {atom(), {Resource.t(), DeclaredResource.t()}}
  defp parse_resource(declared) do
    type = resource_type(declared)
    fields_parser = LayoutHelpers.get_fields_parser_module(type)

    resource = %Resource{
      name: declared.name,
      schema: declared.schema,
      context: declared.context,
      type: type,
      order_by: declared.order_by,
      renderers: declared.renderers,
      display_name: declared.display_name,
      title: declared.title,
      backend_opts: declared.backend_opts,
      fields: fields_parser.parse_fields(declared.schema, declared.name)
    }

    {declared.name, {resource, declared}}
  end

  @spec resource_type(DeclaredResource.t()) :: atom()
  defp resource_type(%DeclaredResource{type: nil, schema: schema}), do: schema_type(schema)
  defp resource_type(%DeclaredResource{type: type}), do: type

  @spec schema_type(module() | nil) :: atom()
  defp schema_type(nil), do: :default

  defp schema_type(schema) do
    functions = schema.__info__(:functions)

    cond do
      Enum.any?(functions, &(&1 == {:__spark_placeholder__, 0})) -> :ash
      Enum.any?(functions, &(&1 == {:__schema__, 1})) -> :ctx
      true -> :default
    end
  end

  # Associations are parsed against every resource, so a related resource can be found by schema.
  @spec add_associations([{atom(), {Resource.t(), DeclaredResource.t()}}]) ::
          [{atom(), Resource.t()}]
  defp add_associations(parsed) do
    resources = Enum.map(parsed, fn {name, {resource, _declared}} -> {name, resource} end)

    Enum.map(parsed, fn {name, {resource, declared}} ->
      {name, resolve_fields(resource, declared, resources)}
    end)
  end

  @spec resolve_fields(Resource.t(), DeclaredResource.t(), [{atom(), Resource.t()}]) ::
          Resource.t()
  defp resolve_fields(%Resource{schema: nil} = resource, _declared, _resources),
    do: put_fields(resource, resource.fields)

  defp resolve_fields(%Resource{} = resource, declared, resources) do
    fields_parser = LayoutHelpers.get_fields_parser_module(resource.type)
    overrides = merge_overrides(declared.fields)

    resource.schema
    |> fields_parser.parse_associations(resource.name, resources, resource.fields)
    |> Enum.reverse()
    |> configure_many_to_one_selectors()
    |> apply_overrides(overrides)
    |> append_declared_fields(declared.fields, overrides, resource.name)
    |> then(&put_fields(resource, &1))
  end

  # Later overrides of a field win, option by option.
  @spec merge_overrides([FieldOverride.t()]) :: %{(atom() | tuple()) => FieldOverride.t()}
  defp merge_overrides(field_overrides) do
    Enum.reduce(field_overrides, %{}, fn %FieldOverride{key: key} = field_override, acc ->
      Map.update(acc, key, field_override, &FieldOverride.merge(&1, field_override))
    end)
  end

  @spec apply_overrides([Field.t()], map()) :: [Field.t()]
  defp apply_overrides(fields, overrides) do
    Enum.map(fields, fn field ->
      case Map.get(overrides, field.key) do
        nil -> field
        field_override -> Field.change(field, FieldOverride.to_field_changes(field_override))
      end
    end)
  end

  # Fields declared but not produced by the parser are appended, in declaration order.
  @spec append_declared_fields([Field.t()], [FieldOverride.t()], map(), atom()) :: [Field.t()]
  defp append_declared_fields(fields, [], _overrides, _resource_name), do: fields

  defp append_declared_fields(fields, field_overrides, overrides, resource_name) do
    parsed_keys = Enum.map(fields, & &1.key)

    new_fields =
      field_overrides
      |> Enum.map(& &1.key)
      |> Enum.uniq()
      |> Enum.reject(&(&1 in parsed_keys))
      |> Enum.map(fn key ->
        %{key: key, resource: resource_name}
        |> Field.new()
        |> Field.change(FieldOverride.to_field_changes(overrides[key]))
      end)

    fields ++ new_fields
  end

  @spec configure_many_to_one_selectors([Field.t()]) :: [Field.t()]
  defp configure_many_to_one_selectors(fields) do
    fields
    |> Enum.filter(&(&1.type == :many_to_one_association))
    |> Enum.reject(&(get_in(&1, [Access.key!(:data), :resource]) == nil))
    |> Enum.map(&{&1.data.owner_key, %{html_type: :select, data: &1.data}})
    |> Enum.reduce(fields, &replace_related_field/2)
  end

  @spec replace_related_field({atom(), map()}, [Field.t()]) :: [Field.t()]
  defp replace_related_field(related_changes, fields),
    do: Enum.map(fields, &replace_related_field_data(&1, related_changes))

  @spec replace_related_field_data(Field.t(), {atom(), map()}) :: Field.t()
  defp replace_related_field_data(%{type: type} = field, _related_changes)
       when type in [
              :many_to_one_association,
              :one_to_many_association,
              :one_to_one_association,
              :many_to_many_association
            ],
       do: field

  defp replace_related_field_data(%{key: field_key, label: label} = field, {field_key, changes}) do
    label
    |> Kernel.||("")
    |> String.replace_suffix(" id", "")
    |> then(&Map.put(changes, :label, &1))
    |> then(&Field.change(field, &1))
  end

  defp replace_related_field_data(field, _related_changes), do: field

  @spec put_fields(Resource.t(), [Field.t()]) :: Resource.t()
  defp put_fields(resource, fields) do
    fields_order =
      fields
      |> Enum.reject(& &1.omitted)
      |> Enum.map(& &1.key)
      |> Enum.uniq()

    struct(resource, %{fields: Map.new(fields, &{&1.key, &1}), fields_order: fields_order})
  end
end
