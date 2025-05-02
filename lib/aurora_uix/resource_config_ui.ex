defmodule AuroraUix.ResourceConfigUI do
  @moduledoc """
  Manages comprehensive metadata configuration for schemas and their associated UI representations.

  This module provides a flexible struct and utility functions for:
  - Defining schema-specific UI configurations
  - Managing dynamic field definitions
  - Supporting complex UI generation scenarios

  Key features:
  - Supports custom field configurations
  - Allows runtime modification of schema metadata
  - Integrates with other AuroraUix parsing components
  """
  alias AuroraUix.Field

  defstruct [:name, :schema, :context, fields: [], fields_order: []]

  @type t() :: %__MODULE__{
          name: atom,
          schema: module,
          context: module | nil,
          fields: map | list
        }

  @doc """
  Creates a new `AuroraUix.ResourceConfigUI` struct with the given attributes.

  ## Parameters

  - `attrs` (map | keyword): A map or keyword containing the attributes to initialize the metadata.
    The allowed keys are `:name`, `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> AuroraUix.ResourceConfigUI.new()
      %AuroraUix.ResourceConfigUI{name: nil, schema: nil, context: nil, fields: []}

      iex> AuroraUix.ResourceConfigUI.new(%{name: :my_schema, schema: MySchema, fields: [AuroraUix.Field.new(field: :custom_field)]})
      %AuroraUix.ResourceConfigUI{
        name: :my_schema,
        schema: MySchema,
        context: nil,
        fields: [
          %AuroraUix.Field{
            field: :custom_field,
            field_type: nil,
            renderer: nil,
            data: nil,
            name: "custom_field",
            label: "",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false,
            disabled: false,
            omitted: false
          }
        ]
      }
  """
  @spec new(map | keyword) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

  @doc """
  Updates an existing `AuroraUix.ResourceConfigUI` struct with the given attributes.

  ## Parameters

  - `metadata`: The existing `AuroraUix.ResourceConfigUI` struct to be updated.
  - `attrs`: A map or keyword containing the attributes to update the metadata.
    The allowed keys are `:name`, `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> metadata = %AuroraUix.ResourceConfigUI{name: :my_schema, schema: MySchema, context: MyContext}
      %AuroraUix.ResourceConfigUI{
          name: :my_schema,
          schema: MySchema,
        context: MyContext,
        fields: []
      }
      iex> AuroraUix.ResourceConfigUI.change(metadata, context: nil, fields: [AuroraUix.Field.new(field: :reference)])
      %AuroraUix.ResourceConfigUI{
        name: :my_schema,
        schema: MySchema,
        context: nil,
        fields: [
          %AuroraUix.Field{
            field: :reference,
            field_type: nil,
            renderer: nil,
            data: nil,
            name: "reference",
            label: "",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false,
            disabled: false,
            omitted: false
          }
        ]
      }

      iex> metadata = %AuroraUix.ResourceConfigUI{name: :my_schema, schema: MySchema, fields: [AuroraUix.Field.new(field: :reference)]}
      %AuroraUix.ResourceConfigUI{
        name: :my_schema,
        schema: MySchema,
        context: nil,
        fields: [
          %AuroraUix.Field{
            field: :reference,
            field_type: nil,
            renderer: nil,
            data: nil,
            name: "reference",
            label: "",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false,
            disabled: false,
            omitted: false
          }
        ]
      }
      iex> AuroraUix.ResourceConfigUI.change(metadata, context: MyContext, fields: [reference: %{label: "My reference"}, description: %{label: "My description"}])
      %AuroraUix.ResourceConfigUI{
        name: :my_schema,
        schema: MySchema,
        context: MyContext,
        fields: [
          %AuroraUix.Field{
            field: :reference,
            field_type: nil,
            renderer: nil,
            data: nil,
            name: "reference",
            label: "My reference",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false,
            disabled: false,
            omitted: false
          },
          %AuroraUix.Field{
            field: :description,
            field_type: nil,
            renderer: nil,
            data: nil,
            name: "description",
            label: "My description",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false,
            disabled: false,
            omitted: false
          }
        ]
      }
  """
  @spec change(__MODULE__.t(), map | keyword) :: __MODULE__.t()
  def change(resource_config, attrs) when is_list(attrs) do
    keys =
      %__MODULE__{}
      |> Map.keys()
      |> Enum.reject(&(&1 == :fields))

    ## applies changes to resource_config struct
    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&struct(resource_config, &1))
    ## changes the fields values with fields attributes
    |> change_fields(attrs)
    |> add_fields(attrs)
  end

  def change(resource_config, %{} = attrs), do: struct(resource_config, attrs)

  ## PRIVATE
  @spec change_fields(__MODULE__.t(), list) :: __MODULE__.t()
  defp change_fields(%{fields: resource_config_fields} = resource_config, attrs)
       when is_list(attrs) do
    changed_fields =
      attrs
      |> filter(:fields)
      |> List.last()
      |> elem(1)

    schema_config_changed_fields =
      Enum.map(resource_config_fields, &change_field(&1, changed_fields))

    struct(resource_config, %{fields: schema_config_changed_fields})
  end

  defp change_fields(resource_config, _attrs),
    do: resource_config

  @spec change_field(map, list | map) :: map
  defp change_field(%{field: field_id} = resource_config_field, changed_fields)
       when is_list(changed_fields) or is_map(changed_fields) do
    changed_fields
    |> Enum.filter(fn
      {^field_id, _} -> true
      _ -> false
    end)
    |> Enum.reduce(resource_config_field, fn {_field, value}, acc -> struct(acc, value) end)
  end

  defp change_field(resource_config_field, _changed_fields), do: resource_config_field

  @spec add_fields(__MODULE__.t(), list) :: __MODULE__.t()
  defp add_fields(%{fields: resource_config_fields} = resource_config, attrs) do
    keys = Enum.map(resource_config_fields, & &1.field)

    resource_config_fields = Enum.reverse(resource_config_fields)

    attrs
    |> filter(:fields)
    |> List.last()
    |> elem(1)
    |> Enum.reject(fn
      field_properties when is_map(field_properties) -> Map.get(field_properties, :field) in keys
      field_properties when is_tuple(field_properties) -> elem(field_properties, 0) in keys
      _ -> true
    end)
    |> Enum.reduce(resource_config_fields, &create_field/2)
    |> Enum.reverse()
    |> then(&struct(resource_config, %{fields: &1}))
  end

  @spec create_field(tuple, list) :: list
  defp create_field({field, properties}, acc) do
    new_field =
      properties
      |> Map.put(:field, field)
      |> Field.new()

    [new_field | acc]
  end

  defp create_field(%Field{} = field, acc), do: [field | acc]
  defp create_field(%{field: _field_id} = attrs, _acc), do: Field.new(attrs)
  defp create_field(_field, acc), do: acc

  @spec filter(list, atom) :: list
  defp filter(attrs, key) do
    Enum.filter(attrs, fn
      {^key, _} -> true
      _ -> false
    end)
  end
end
