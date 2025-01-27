defmodule AuroraUixWeb.Uix.SchemaMetadata do
  @moduledoc """
  Provides schema metadata management for AuroraUixWeb.

  This module is responsible for attaching and managing UI-related metadata for Ecto schemas.
  This metadata enhances schema usability in UI rendering, enabling customization of fields, placeholders, labels, and other attributes.

  The primary functions include:

  - `__auix_metadata__/4`: Registers schema metadata, including fields and their configurations.
  - `field/2`: Adds or updates field-specific metadata.
  - Internal utilities for deriving field attributes such as labels, placeholders, and types based on schema definitions.

  ## Example

  ```elixir
    defmodule MyApp.Product do
      use Ecto.Schema
      import Ecto.Changeset

      schema "products" do
        field :name, :string
        field :price, :float
        field :quantity, :integer
        belongs_to :category, MyApp.Category

        timestamps()
      end
    end

    defmodule MyApp.Category do
      use Ecto.Schema
      import Ecto.Changeset

      schema "categories" do
        field :name, :string
        has_many :products, MyApp.Product

        timestamps()
      end
    end

    defmodule MyAppWeb.ProductLive.Index do
      auix_schema_metadata :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      auix_schema_metadata :category, schema: MyApp.Category do
        field :id, readonly: true
        field :name, max_length: 20, required: true
      end
  ```
  """

  alias AuroraUix.Field
  alias AuroraUixWeb.Uix.SchemaMetadata

  @default_field_attributes %Field{html_type: :text, length: 20}

  @doc """
  Adds or updates metadata for a specific field in the schema.

  This macro allows customization of individual fields, such as setting labels, placeholders, types, and validation rules.
  The updates are stored in the schema metadata registered in the current module.

  ## Parameters

  - `field` (`atom`) - The name of the schema field.
  - `opts` (`Keyword.t`) - A keyword list of field options.

  ## Options

  The following options can be provided to configure the field:

  - `:field` (`atom`) - The referred field in the schema. This should be rarely changed.
  - `:html_type`(`atom`) - The html type that best represent the current field elixir type.
  - `:label` (`binary`) - A custom label for the field.
  - `:placeholder` (`binary`) - Placeholder text for the field.
  - `:length`(`non_neg_integer`) - Display length of the field.
  - `:precision` (`integer`) - The numeric precision for decimal or float fields.
  - `:scale` (`integer`) - The numeric scale for decimal or float fields.
  - `:readonly` (`boolean`) - Marks the field as read-only.
  - `:hidden` (`boolean`) - Hides the field
  - `:renderer` (`function`) - A function that can render the field. It can refer a function component.
  - `:required` (`boolean`) - Marks the field as required.

  ## Example

  ```elixir
  field :name, label: "Product Name", placeholder: "Enter product name", required: true
  field :price, precision: 12, scale: 2, label: "Price ($)"
  """
  @spec field(atom, Keyword.t()) :: Macro.t()
  defmacro field(field, opts \\ []) do
    quote do
      SchemaMetadata.__field__(
        __MODULE__,
        unquote(field),
        Macro.escape(unquote(opts))
      )
    end
  end

  @spec fields([atom], Keyword.t()) :: Macro.t()
  defmacro fields(fields, opts \\ []) do
    quotes =
      Enum.map(fields, fn field ->
        quote do
          SchemaMetadata.__field__(
            __MODULE__,
            unquote(field),
            Macro.escape(unquote(opts))
          )
        end
      end)

    quote do
      (unquote_splicing(quotes))
    end
  end

  @doc """
  Registers schema metadata for a given schema within the module.

  This function attaches metadata such as schema fields, context, and other configurations. It is typically used internally by the `auix_schema_metadata` macro.

  ## Parameters

  - `module` (`module`) - The module where metadata is being registered.
  - `name` (`atom`)- An identifier for the schema metadata (atom).
  - `opts` (`Keyword.t`) - Options

  ## Options
    - `:context` - Context containing the accessing functions for the schema.
    - `:schema` - Associated ecto schema module. If it is defined, tries to create the fields metadata information from the ecto schema.
    - `:include_associations` - For each associated schema, the metadata is created. If true, then, every associated schema is parsed.
  """
  @spec __auix_metadata__(module, atom, Keyword.t()) :: :ok
  def __auix_metadata__(module, name, opts) do
    schema = opts[:schema]
    context = opts[:context]

    schemas = Module.get_attribute(module, :_auix_schemas, %{})

    schemas
    |> Map.get(name, %{})
    |> put_option(opts, :context)
    |> put_option(opts, :schema)
    |> Map.put(:fields, parse_fields(schema))
    |> then(&Map.put(schemas, name, &1))
    |> then(&Module.put_attribute(module, :_auix_schemas, &1))

    include_associations(module, schema, context, opts[:include_associations])

    Module.put_attribute(module, :_auix_current_schema_name, name)
  end

  @spec __field__(module, atom, Keyword.t()) :: :ok
  def __field__(module, field, opts) do
    name = Module.get_attribute(module, :_auix_current_schema_name)

    changed_field =
      module
      |> Module.get_attribute(:_auix_schemas, %{})
      |> get_in([name, :fields, field])
      |> get_field(field)
      |> Field.change(opts)

    module
    |> Module.get_attribute(:_auix_schemas, %{})
    |> put_in([name, :fields, field], changed_field)
    |> then(&Module.put_attribute(module, :_auix_schemas, &1))
  end

  ## PRIVATE
  @spec parse_fields(module | nil) :: map
  defp parse_fields(nil), do: %{}

  defp parse_fields(schema) do
    Code.ensure_compiled(schema)

    if function_exported?(schema, :__schema__, 1) do
      :fields
      |> schema.__schema__()
      |> Enum.map(&parse_field(schema, &1))
      |> Map.new()
    else
      %{}
    end
  end

  @spec parse_field(module, atom | binary) :: {atom | binary, Field.t()}
  defp parse_field(module, field) do
    type = module.__schema__(:type, field)

    attrs = %{
      field: field,
      label: field_label(field),
      placeholder: field_placeholder(field, type),
      html_type: field_html_type(type),
      length: field_length(type),
      precision: field_precision(type),
      scale: field_scale(type)
    }

    {field, Field.new(attrs)}
  end

  @spec get_field(atom | nil, atom) :: map
  defp get_field(nil, field_name), do: struct(@default_field_attributes, %{field: field_name})
  defp get_field(field, _field_name), do: field

  @spec field_label(binary) :: binary
  defp field_label(nil), do: ""

  defp field_label(name),
    do: name |> to_string() |> String.capitalize() |> String.replace("_", " ")

  @spec field_placeholder(binary, atom) :: binary
  defp field_placeholder(_, type) when type in [:id, :integer, :float, :decimal], do: "0"

  defp field_placeholder(_, type)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: "yyyy/MM/dd HH:mm:ss"

  defp field_placeholder(_, type) when type in [:time, :time_usec], do: "HH:mm:ss"
  defp field_placeholder(name, _type), do: name |> to_string() |> String.capitalize()

  @spec field_html_type(atom) :: atom
  defp field_html_type(type) when type in [:string, :binary_id, :binary, :bitstring, Ecto.UUID],
    do: :text

  defp field_html_type(type) when type in [:id, :integer, :float, :decimal], do: :number

  defp field_html_type(type)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: :datetime_local

  defp field_html_type(type) when type in [:time, :time_usec], do: :time
  defp field_html_type(type), do: type

  @spec field_length(atom) :: integer
  defp field_length(type) when type in [:string, :binary_id, :binary, :bitstring], do: 255
  defp field_length(type) when type in [:id, :integer], do: 10
  defp field_length(type) when type in [:float, :decimal], do: 12

  defp field_length(type)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: 20

  defp field_length(type) when type in [:time, :time_usec], do: 10
  defp field_length(Ecto.UUID), do: 34
  defp field_length(:boolean), do: 5
  defp field_length(_type), do: 50

  @spec field_precision(atom) :: integer
  defp field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  defp field_precision(_type), do: 0

  @spec field_precision(atom) :: integer
  defp field_scale(type) when type in [:float, :decimal], do: 2
  defp field_scale(_type), do: 0

  @spec include_associations(module, module, module, boolean) :: :ok

  defp include_associations(module, schema, context, true = include_associations?) do
    if function_exported?(schema, :__schema__, 1) do
      :associations
      |> schema.__schema__()
      |> Enum.each(&include_association(module, schema, context, include_associations?, &1))
    end
  end

  defp include_associations(_module, _schema, _context, _include_associations?), do: :ok

  @spec include_association(module, module, module, boolean, atom) :: :ok
  defp include_association(module, schema, context, include_associations?, assoc) do
    assoc_schema =
      :association
      |> schema.__schema__(assoc)
      |> association_schema()

    Code.ensure_compiled(assoc_schema)

    assoc_name =
      assoc_schema
      |> Module.split()
      |> List.last()
      |> Macro.underscore()
      |> String.to_existing_atom()

    if Module.get_attribute(module, :_auix_schemas, %{})[assoc_name] do
      :ok
    else
      __auix_metadata__(module, assoc_name,
        schema: assoc_schema,
        context: context,
        include_associations: include_associations?
      )
    end
  end

  @spec association_schema(map) :: module
  defp association_schema(%{relationship: :parent, owner: assoc_schema}), do: assoc_schema
  defp association_schema(%{relationship: :child, related: assoc_schema}), do: assoc_schema

  @spec put_option(map, Keyword.t(), atom) :: map
  defp put_option(metadata, opts, key) do
    if Keyword.has_key?(opts, key),
      do: Map.put(metadata, key, opts[key]),
      else: metadata
  end
end
