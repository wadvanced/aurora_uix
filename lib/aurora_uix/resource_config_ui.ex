defmodule AuroraUix.ResourceConfigUI do
  @moduledoc """
  Provides a structure and functions to manage metadata for schemas and contexts.

  The `AuroraUix.ResourceConfigUI` module defines a struct that holds metadata information
  about a schema, its context, and additional fields. It also provides functions
  to create and update this metadata.
  """
  alias AuroraUix.Field

  defstruct [:schema, :context, fields: [], form_layout: [], list_layout: []]

  @type t() :: %__MODULE__{
          schema: module,
          context: module | nil,
          fields: list(Field.t()),
          form_layout: [],
          list_layout: []
        }

  @doc """
  Creates a new `AuroraUix.ResourceConfigUI` struct with the given attributes.

  ## Parameters

  - `attrs` (map | keyword): A map or keyword containing the attributes to initialize the metadata.
    The allowed keys are `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> AuroraUix.ResourceConfigUI.new()
      %AuroraUix.ResourceConfigUI{schema: nil, context: nil, fields: [], form_layout: []}

      iex> AuroraUix.ResourceConfigUI.new(%{schema: MySchema, fields: [AuroraUix.Field.new(field: :custom_field)]})
      %AuroraUix.ResourceConfigUI{
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
            required: false,
            disabled: false
          }
        ],
        form_layout: [],
        list_layout: []
      }
  """
  @spec new(map | keyword) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

  @doc """
  Updates an existing `AuroraUix.ResourceConfigUI` struct with the given attributes.

  ## Parameters

  - `metadata`: The existing `AuroraUix.ResourceConfigUI` struct to be updated.
  - `attrs`: A map or keyword containing the attributes to update the metadata.
    The allowed keys are `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> metadata = %AuroraUix.ResourceConfigUI{schema: MySchema, context: MyContext}
      %AuroraUix.ResourceConfigUI{
        schema: MySchema,
        context: MyContext,
        fields: [],
        form_layout: [],
        list_layout: []
      }
      iex> AuroraUix.ResourceConfigUI.change(metadata, context: nil, fields: [AuroraUix.Field.new(field: :reference)])
      %AuroraUix.ResourceConfigUI{
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
            required: false,
            disabled: false
          }
        ],
        form_layout: [],
        list_layout: []
      }

      iex> metadata = %AuroraUix.ResourceConfigUI{schema: MySchema, fields: [AuroraUix.Field.new(field: :reference)]}
      %AuroraUix.ResourceConfigUI{
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
            required: false,
            disabled: false
          }
        ],
        form_layout: [],
        list_layout: []
      }
      iex> AuroraUix.ResourceConfigUI.change(metadata, context: MyContext, fields: [reference: %{label: "My reference"}, description: %{label: "My description"}])
      %AuroraUix.ResourceConfigUI{
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
            required: false,
            disabled: false
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
            required: false,
            disabled: false
          }
        ],
        form_layout: [],
        list_layout: []
      }
  """
  @spec change(__MODULE__.t(), map | keyword) :: __MODULE__.t()
  def change(schema_config, attrs) when is_list(attrs) do
    keys =
      %__MODULE__{}
      |> Map.keys()
      |> Enum.reject(&(&1 == :fields))

    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&struct(schema_config, &1))
    |> change_fields(attrs)
    |> add_fields(attrs)
  end

  def change(schema_config, %{} = attrs), do: struct(schema_config, attrs)

  ## PRIVATE
  defp change_fields(%{fields: schema_config_fields} = schema_config, attrs)
       when is_list(attrs) do
    changed_fields =
      attrs
      |> filter(:fields)
      |> List.last()
      |> elem(1)

    schema_config_changed_fields =
      Enum.map(schema_config_fields, &change_field(&1, changed_fields))

    struct(schema_config, %{fields: schema_config_changed_fields})
  end

  defp change_fields(schema_config, _attrs),
    do: schema_config

  defp change_field(%{field: field_id} = schema_config_field, changed_fields)
       when is_list(changed_fields) or is_map(changed_fields) do
    changed_fields
    |> Enum.filter(fn
      {^field_id, _} -> true
      _ -> false
    end)
    |> Enum.reduce(schema_config_field, fn {_field, value}, acc -> struct(acc, value) end)
  end

  defp change_field(schema_config_field, _changed_fields), do: schema_config_field

  defp add_fields(%{fields: schema_config_fields} = schema_config, attrs) do
    keys = Enum.map(schema_config_fields, & &1.field)

    schema_config_fields = Enum.reverse(schema_config_fields)

    attrs
    |> filter(:fields)
    |> List.last()
    |> elem(1)
    |> Enum.reject(fn
      field_properties when is_map(field_properties) -> Map.get(field_properties, :field) in keys
      field_properties when is_tuple(field_properties) -> elem(field_properties, 0) in keys
      _ -> true
    end)
    |> Enum.reduce(schema_config_fields, &create_field/2)
    |> Enum.reverse()
    |> then(&struct(schema_config, %{fields: &1}))
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
