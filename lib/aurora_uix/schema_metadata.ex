defmodule AuroraUix.SchemaMetadata do
  @moduledoc """
  Provides a structure and functions to manage metadata for schemas and contexts.

  The `AuroraUix.Metadata` module defines a struct that holds metadata information
  about a schema, its context, and additional fields. It also provides functions
  to create and update this metadata.
  """
  alias AuroraUix.Field

  defstruct [:schema, :context, fields: []]

  @type t() :: %__MODULE__{
          schema: module,
          context: module | nil,
          fields: list(Field.t())
        }

  @doc """
  Creates a new `AuroraUix.Metadata` struct with the given attributes.

  ## Parameters

  - `attrs`: A map or keyword list containing the attributes to initialize the metadata.
    The allowed keys are `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> AuroraUix.SchemaMetadata.new()
      %AuroraUix.SchemaMetadata{schema: nil, context: nil, fields: []}

      iex> AuroraUix.SchemaMetadata.new(%{schema: MySchema, fields: [AuroraUix.Field.new(field: :custom_field)]})
      %AuroraUix.SchemaMetadata{
        schema: MySchema,
        context: nil,
        fields: [
          %AuroraUix.Field{
            field: :custom_field,
            html_type: nil,
            renderer: nil,
            name: "custom_field",
            label: "",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false
          }
        ]
      }
  """
  @spec new(map | keyword) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

  @doc """
  Updates an existing `AuroraUix.Metadata` struct with the given attributes.

  ## Parameters

  - `metadata`: The existing `AuroraUix.Metadata` struct to be updated.
  - `attrs`: A map or keyword list containing the attributes to update the metadata.
    The allowed keys are `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> metadata = %AuroraUix.SchemaMetadata{schema: MySchema, context: MyContext}
      %AuroraUix.SchemaMetadata{schema: MySchema, context: MyContext, fields: []}
      iex> AuroraUix.SchemaMetadata.change(metadata, context: nil, fields: [AuroraUix.Field.new(field: :reference)])
      %AuroraUix.SchemaMetadata{
        schema: MySchema,
        context: nil,
        fields: [
          %AuroraUix.Field{
            field: :reference,
            html_type: nil,
            renderer: nil,
            name: "reference",
            label: "",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false
          }
        ]
      }

      iex> metadata = %AuroraUix.SchemaMetadata{schema: MySchema, fields: [AuroraUix.Field.new(field: :reference)]}
      %AuroraUix.SchemaMetadata{
        schema: MySchema,
        context: nil,
        fields: [
          %AuroraUix.Field{
            field: :reference,
            html_type: nil,
            renderer: nil,
            name: "reference",
            label: "",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false
          }
        ]
      }
      iex> AuroraUix.SchemaMetadata.change(metadata, context: MyContext, fields: [reference: %{label: "My reference"}, description: %{label: "My description"}])
      %AuroraUix.SchemaMetadata{
        schema: MySchema,
        context: MyContext,
        fields: [
          %AuroraUix.Field{
            field: :reference,
            html_type: nil,
            renderer: nil,
            name: "reference",
            label: "My reference",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false
          },
          %AuroraUix.Field{
            field: :description,
            html_type: nil,
            renderer: nil,
            name: "description",
            label: "My description",
            placeholder: "",
            length: 0,
            precision: 0,
            scale: 0,
            hidden: false,
            readonly: false,
            required: false
          }
        ]
      }
  """
  @spec change(__MODULE__.t(), map | keyword) :: __MODULE__.t()
  def change(metadata, attrs) when is_list(attrs) do
    keys =
      %__MODULE__{}
      |> Map.keys()
      |> Enum.reject(&(&1 == :fields))

    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&struct(metadata, &1))
    |> change_fields(attrs)
    |> add_fields(attrs)
  end

  def change(metadata, %{} = attrs), do: struct(metadata, attrs)

  ## PRIVATE
  defp change_fields(%{fields: metadata_fields} = metadata, attrs) when is_list(attrs) do
    changed_fields =
      attrs
      |> filter(:fields)
      |> List.last()
      |> elem(1)

    metadata_changed_fields = Enum.map(metadata_fields, &change_field(&1, changed_fields))

    struct(metadata, %{fields: metadata_changed_fields})
  end

  defp change_fields(metadata, _attrs),
    do: metadata

  defp change_field(%{field: field_id} = metadata_field, changed_fields)
       when is_list(changed_fields) or is_map(changed_fields) do
    changed_fields
    |> Enum.filter(fn
      {^field_id, _} -> true
      _ -> false
    end)
    |> Enum.reduce(metadata_field, fn {_field, value}, acc -> struct(acc, value) end)
  end

  defp change_field(metadata_field, _changed_fields), do: metadata_field

  defp add_fields(%{fields: metadata_fields} = metadata, attrs) do
    keys = Enum.map(metadata_fields, & &1.field)

    metadata_fields = Enum.reverse(metadata_fields)

    attrs
    |> filter(:fields)
    |> List.last()
    |> elem(1)
    |> Enum.reject(fn
      field_properties when is_map(field_properties) -> Map.get(field_properties, :field) in keys
      field_properties when is_tuple(field_properties) -> elem(field_properties, 0) in keys
      _ -> true
    end)
    |> Enum.reduce(metadata_fields, &create_field/2)
    |> Enum.reverse()
    |> then(&struct(metadata, %{fields: &1}))
  end

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

  defp filter(attrs, key) do
    Enum.filter(attrs, fn
      {^key, _} -> true
      _ -> false
    end)
  end
end
