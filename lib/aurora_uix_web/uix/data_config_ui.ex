defmodule AuroraUixWeb.Uix.DataConfigUI do
  @moduledoc """
  Provides declarative UI configuration for structured data in Phoenix LiveView.

  This module enables UI metadata management for any structured data format, with
  first-class support for Phoenix LiveView components. While particularly useful
  with Ecto schemas, it can configure any data structure that provides field
  definitions.

  ## Key Features
  - Field-level UI metadata (labels, placeholders, validation rules).
  - Cross-structure configuration inheritance.
  - LiveView component integration.
  - Type-aware default generation.
  - Association-aware configuration.

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

    defmodule MyAppWeb.Inventory.Views do
      auix_resource_config :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      auix_resource_config :category, schema: MyApp.Category do
        field :id, readonly: true
        field :name, max_length: 20, required: true
      end
    end
  ```
  """

  alias AuroraUix.Field
  alias AuroraUix.ResourceConfigUI
  alias AuroraUixWeb.Uix.DataConfigUI

  defmacro __using__(opts) do
    schema_name = opts[:schema_name]

    quote do
      import AuroraUixWeb.Uix.DataConfigUI

      Module.register_attribute(__MODULE__, :_auix_fields, accumulate: true)
      Module.put_attribute(__MODULE__, :_auix_schema_name, unquote(schema_name))

      @before_compile AuroraUixWeb.Uix.DataConfigUI
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    ## Schema config definitions (@_auix_resource_configs) are returned in reversed creation order, this fix that.
    schema_config = env.module |> Module.get_attribute(:_auix_resource_configs) |> Enum.reverse()
    ## Field modifications (@_auix_fields) are returned in reversed creation order, too.
    field_changes = env.module |> Module.get_attribute(:_auix_fields) |> Enum.reverse()

    Module.delete_attribute(env.module, :_auix_resource_configs)
    Module.delete_attribute(env.module, :_auix_fields)

    schema_config
    |> DataConfigUI.__change_schema_configs__(field_changes)
    |> List.flatten()
    |> then(&Module.put_attribute(env.module, :_auix_resource_configs, &1))
  end

  @doc """
  Defines UI configuration for a schema.

  ## Parameters
    - `name` (atom) - Identifier for the configuration block.
    - `opts` (keyword) - Configuration options.

  ## Options
    - `:schema` (`module`) (required) - Struct module being configured, usually an Ecto schema.
    - `:context` (`module`) - Context module containing data access functions.
    - `:include_associations` (`boolean`) - Auto configure associations (default: false).

  ## Example
    ```elixir
      auix_resource_config :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end
    ```
  """
  defmacro auix_resource_config(name, opts \\ []) do
    schema_config = __register_schema_config__(name, opts)

    quote do
      unquote(schema_config)
    end
  end

  defmacro auix_resource_config(name, opts, do: block) do
    schema_config = __register_schema_config__(name, opts)

    quote do
      unquote(schema_config)
      unquote(block)
    end
  end

  @doc """
  Adds or updates UI metadata for a single field.

  This macro allows customization of individual fields, such as setting labels, placeholders, types, and validation rules.
  The updates are stored in the schema metadata registered in the current module.

  ## Parameters

  - `field` (atom) - The name of the field.
  - `opts` (keyword) - A keyword list of field presentation options.

  ## Options

  The following options can be provided to configure the field:

  - `:field` (`atom`) - The referred field in the schema. This should be rarely changed.
  - `:html_type`(`atom`) - The html type that best represent the current field elixir type.
  - `:label` (`binary`) - A custom label for the field. (auto-generated from field name if omitted).
  - `:placeholder` (`binary`) - Placeholder text for the field.
  - `:length`(`non_neg_integer`) - Display length of the field.
  - `:precision` (`integer`) - The numeric precision for decimal or float fields.
  - `:scale` (`integer`) - The numeric scale for decimal or float fields.
  - `:readonly` (`boolean`) - Marks the field as read-only.
  - `:hidden` (`boolean`) - Hides the field.
  - `:renderer` (`function`) - Custom rendering function/component.
  - `:required` (`boolean`) - Marks the field as required.
  - `:disabled` (`boolean`) - If true, should behave as if the field does not exists. The TEMPLATE implementation
    should handle this case.

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
        DataConfigUI.__field__(
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
  Applies configuration to multiple fields simultaneously.

  ## Parameters
    - `fields` ([atom]) - List of fields to be configured.
    - `opts` (keyword) - A keyword list of fields' options. See `field/2` for options' details.

  ## Example
  ```elixir
  fields [:msrp, :rrp, :list_price], precision: 10, scale: 2
  ```
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

  @doc false
  @spec __auix_schema_config__(atom, Keyword.t()) :: ResourceConfigUI.t()
  def __auix_schema_config__(_name, opts) do
    schema = opts[:schema]

    %ResourceConfigUI{}
    |> put_option(opts, :context)
    |> put_option(opts, :schema)
    |> struct(%{fields: parse_fields(schema)})
  end

  @doc false
  @spec __field__(atom, keyword) :: map
  def __field__(field, opts) do
    opts
    |> Map.new()
    |> Map.merge(%{field: field})
  end

  @doc false
  @spec __get_schema_config__(module, atom) :: map
  def __get_schema_config__(module, name) do
    module
    |> Module.get_attribute(:_auix_resource_configs, [])
    |> DataConfigUI.__find_schema_config__(name)
  end

  @doc false
  @spec __find_schema_config__(module, atom) :: map
  def __find_schema_config__(auix_resource_config, name) do
    auix_resource_config
    |> Enum.filter(fn {schema_config_name, _metadata} -> schema_config_name == name end)
    |> Enum.map(fn {_schema_config_name, schema_config} -> schema_config end)
    |> List.last()
    |> Kernel.||(%{})
  end

  @doc false
  @spec __change_schema_configs__(list, list) :: list
  def __change_schema_configs__(schema_config, []), do: schema_config

  def __change_schema_configs__(schema_config, all_fields) do
    Enum.map(schema_config, fn {schema_name, schema_config} ->
      modified_schema_metadata =
        schema_name
        |> filter_fields(all_fields)
        |> then(&ResourceConfigUI.change(schema_config, fields: &1))

      {schema_name, modified_schema_metadata}
    end)
  end

  @doc false
  @spec __register_schema_config__(atom, Keyword.t()) :: Macro.t()
  def __register_schema_config__(name, opts) do
    quote do
      use DataConfigUI, schema_name: unquote(name)

      schema_config =
        DataConfigUI.__auix_schema_config__(
          unquote(name),
          unquote(opts)
        )

      Module.put_attribute(__MODULE__, :_auix_resource_configs, {unquote(name), schema_config})
    end
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

  @spec parse_field(module, atom) :: Field.t()
  defp parse_field(module, field) do
    type = module.__schema__(:type, field)

    attrs = %{
      field: field,
      label: field_label(field),
      placeholder: field_placeholder(field, type),
      html_type: field_html_type(type),
      length: field_length(type),
      precision: field_precision(type),
      scale: field_scale(type),
      disabled: field_disabled(field)
    }

    Field.new(attrs)
  end

  @spec field_label(atom) :: binary
  defp field_label(nil), do: ""

  defp field_label(name),
    do: name |> to_string() |> String.replace("_", " ") |> String.capitalize()

  @spec field_placeholder(atom, atom) :: binary
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
       do: :"datetime-local"

  defp field_html_type(type) when type in [:time, :time_usec], do: :time

  defp field_html_type(:boolean), do: :checkbox

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

  @spec field_disabled(atom) :: boolean
  defp field_disabled(field) when field in [:id, :deleted, :inactive, :inserted_at, :updated_at],
    do: true

  defp field_disabled(_field), do: false

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
