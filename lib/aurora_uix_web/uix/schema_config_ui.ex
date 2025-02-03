defmodule AuroraUixWeb.Uix.SchemaConfigUI do
  @moduledoc """
  Provides schema config management for AuroraUixWeb.

  This module is responsible for attaching and managing UI-related metadata for Ecto schemas.
  This metadata enhances schema usability in UI rendering, enabling customization of fields, placeholders, labels, and other attributes.

  The primary functions include:

  - `__auix_schema_config__/2`: Registers schema metadata, including fields and their configurations.
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
      auix_schema_configs :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      auix_schema_configs :category, schema: MyApp.Category do
        field :id, readonly: true
        field :name, max_length: 20, required: true
      end
  ```
  """

  alias AuroraUix.Field
  alias AuroraUix.SchemaConfig
  alias AuroraUixWeb.Uix.SchemaConfigUI

  defmacro __using__(opts) do
    schema_name = opts[:schema_name]

    quote do
      import AuroraUixWeb.Uix.SchemaConfigUI

      Module.register_attribute(__MODULE__, :_auix_fields, accumulate: true)
      Module.put_attribute(__MODULE__, :_auix_schema_name, unquote(schema_name))
    end
  end

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
  ```
  """
  @spec field(atom, Keyword.t()) :: Macro.t()
  defmacro field(field, opts \\ []) do
    quote do
      schema_name = Module.get_attribute(__MODULE__, :_auix_schema_name)

      parsed_field =
        SchemaConfigUI.__field__(
          unquote(field),
          unquote(opts)
        )

      Module.put_attribute(
        __MODULE__,
        :_auix_fields,
        {Macro.escape(schema_name), parsed_field}
      )
    end
  end

  @doc """
  Adds or updates metadata for group of fields in the schema.

  This macro allows customization of individual fields, such as setting labels, placeholders, types, and validation rules.
  See `field/2` for option details.

  """
  @spec fields([atom], Keyword.t()) :: Macro.t()
  defmacro fields(fields, opts \\ []) do
    quotes =
      Enum.map(fields, fn field ->
        quote do
          field(unquote(field), unquote(opts))
        end
      end)

    quote do
      (unquote_splicing(quotes))
    end
  end

  @doc """
  Registers schema metadata and configuration for a given schema within the module.

  This function attaches schema fields metadata, context, and other configurations.
  It is used internally by the `auix_schema_configs` macro.

  ## Parameters

  - `name` (`atom`)- An identifier for the schema configuration (atom).
  - `opts` (`Keyword.t`) - Options

  ## Options
    - `:context` - Context containing the accessing functions for the schema.
    - `:schema` - Associated ecto schema module. If it is defined, tries to create the fields metadata information from the ecto schema.
    - `:include_associations` - For each associated schema, the configuration is created.
      If true, then, every associated schema is configured inheriting the parent configuration.
  """
  @spec __auix_schema_config__(atom, Keyword.t()) :: SchemaConfig.t()
  def __auix_schema_config__(_name, opts) do
    schema = opts[:schema]

    %SchemaConfig{}
    |> put_option(opts, :context)
    |> put_option(opts, :schema)
    |> struct(%{fields: parse_fields(schema)})
  end

  @spec __field__(atom, keyword) :: map
  def __field__(field, opts) do
    opts
    |> Map.new()
    |> Map.merge(%{field: field})
  end

  @doc """
  Gets the schema configuration by its name.

  ## Parameters
    - `module`
  """
  @spec __get_schema_config__(module, atom) :: map
  def __get_schema_config__(module, name) do
    module
    |> Module.get_attribute(:_auix_schema_configs, [])
    |> SchemaConfigUI.__find_schema_config__(name)
  end

  @doc """
  Finds the schema configuration by its name.

  ## Parameters
    - `module`
  """
  @spec __find_schema_config__(module, atom) :: map
  def __find_schema_config__(auix_schema_configs, name) do
    auix_schema_configs
    |> Enum.filter(fn {schema_config_name, _metadata} -> schema_config_name == name end)
    |> Enum.map(fn {_schema_config_name, schema_config} -> schema_config end)
    |> List.last()
    |> Kernel.||(%{})
  end

  @doc """
  Updates the given schema configurations by applying field changes derived from a list of field definitions.

  This function takes two arguments:

  - `schema_config`: a collection of schema configurations.
      Each `config` will be updated based on the fields associated with its corresponding `schema_name`.
  - `all_fields`: a list of field metadata for all schema configuration.
  """
  @spec __change_schema_configs__(list, list) :: map
  def __change_schema_configs__(schema_config, []), do: schema_config

  def __change_schema_configs__(schema_config, all_fields) do
    Enum.map(
      schema_config,
      fn {schema_name, schema_config} ->
        modified_schema_metadata =
          schema_name
          |> filter_fields(all_fields)
          |> then(&SchemaConfig.change(schema_config, fields: &1))

        {schema_name, modified_schema_metadata}
      end
    )
  end

  ## PRIVATE
  @spec parse_fields(module | nil) :: list
  defp parse_fields(nil), do: []

  defp parse_fields(schema) do
    Code.ensure_compiled(schema)

    if function_exported?(schema, :__schema__, 1) do
      :fields
      |> schema.__schema__()
      |> Enum.map(&parse_field(schema, &1))
    else
      []
    end
  end

  @spec parse_field(module, atom | binary) :: Field.t()
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

    Field.new(attrs)
  end

  @spec field_label(binary) :: binary
  defp field_label(nil), do: ""

  defp field_label(name),
    do: name |> to_string() |> String.replace("_", " ") |> String.capitalize()

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

  @spec put_option(map, Keyword.t(), atom) :: map
  defp put_option(schema_config, opts, key) do
    if Keyword.has_key?(opts, key),
      do: Map.put(schema_config, key, opts[key]),
      else: schema_config
  end

  @spec filter_fields(atom, list) :: list
  defp filter_fields(schema_name, all_fields) do
    all_fields
    |> Enum.reduce([], &filter_schema(&1, &2, schema_name))
    |> Enum.map(&{&1.field, &1})
    |> Enum.reverse()
  end

  @spec filter_schema(tuple, list, atom) :: list
  defp filter_schema({field_schema_name, field_config}, acc, field_schema_name),
    do: [field_config | acc]

  defp filter_schema(_field, acc, _schema_name), do: acc
end
