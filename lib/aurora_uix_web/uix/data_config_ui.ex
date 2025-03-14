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
  alias AuroraUixWeb.Uix
  alias AuroraUixWeb.Uix.DataConfigUI

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.DataConfigUI

      Module.register_attribute(__MODULE__, :_auix_resource_configs, accumulate: false)
      Module.register_attribute(__MODULE__, :_auix_fields, accumulate: true)

      @before_compile AuroraUixWeb.Uix.DataConfigUI
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    ## Field modifications (@_auix_fields) are returned in reversed creation order, too.
    changes =
      env.module
      |> Module.get_attribute(:_auix_fields)
      |> Enum.reverse()
      |> parse_change(%{}, [])
      |> Map.new()

    if !Enum.empty?(changes),
      do: Module.put_attribute(env.module, :_auix_resource_configs, changes)

    Module.delete_attribute(env.module, :_auix_fields)
    :ok
  end

  defp parse_change([%{tag: :resource, state: :start} | rest], acc, _current) do
    parse_change(rest, acc, [])
  end

  defp parse_change(
         [%{tag: :resource, name: name, config: opts, state: :end} | rest],
         acc,
         current
       ) do
    resource =
      opts
      |> default_config()
      |> ResourceConfigUI.change(fields: Enum.reverse(current))

    parse_change(rest, Map.put(acc, name, resource), [])
  end

  defp parse_change([%{tag: :field, field: field, opts: opts} | rest], acc, current) do
    parse_change(rest, acc, [{field, Map.new(opts)} | current])
  end

  defp parse_change([], acc, _current), do: acc

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
  defmacro auix_resource_config(name, opts \\ [], do_block \\ nil) do
    {block, opts} = Uix.extract_block_options(opts, do_block)

    resource_config =
      quote do
        use DataConfigUI

        Module.put_attribute(__MODULE__, :_auix_fields, %{
          tag: :resource,
          state: :start,
          name: unquote(name)
        })

        unquote(block)

        Module.put_attribute(__MODULE__, :_auix_fields, %{
          tag: :resource,
          state: :end,
          name: unquote(name),
          config: unquote(opts)
        })
      end

    quote do
      unquote(resource_config)
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
  - `disabled` (`boolean`) - If true, the field should not participate in form interaction.
  - `omitted` (`boolean`) - If true, the field won't be display nor interact with.
      It is equivalent to not having the field at all.

  ## Example

  ```elixir
  field :name, label: "Product Name", placeholder: "Enter product name", required: true
  field :price, precision: 12, scale: 2, label: "Price ($)"
  ```
  """
  @spec field(atom, Keyword.t()) :: Macro.t()
  defmacro field(field, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :_auix_fields,
        %{tag: :field, field: unquote(field), opts: unquote(opts)}
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

  @doc """
  Returns the default UI configuration for a resource.

  This function initializes a `%ResourceConfigUI{}` struct and populates it with the provided options.
  It specifically extracts the `:context` and `:schema` options and assigns them to the struct. Additionally,
  it processes the schema to extract and define the `fields` configuration.

  ## Parameters

    - `opts` (`Keyword.t()`): A keyword list of options containing:
    - `:context` - The context module for the resource (optional).
    - `:schema` - The schema module for the resource (required).

  ## Returns

  - `%ResourceConfigUI{}`: A struct containing the configured resource UI settings.

  ## Example

    iex> AuroraUixWeb.Uix.DataConfigUI.default_config(schema: MyApp.Products.Product)
    %ResourceConfigUI{
      context: nil,
      schema: MyApp.Products.Product,
      fields: [...]
    }

  """
  @spec default_config(Keyword.t()) :: ResourceConfigUI.t()
  def default_config(opts) do
    schema = opts[:schema]

    %ResourceConfigUI{}
    |> put_option(opts, :context)
    |> put_option(opts, :schema)
    |> struct(%{fields: parse_fields(schema)})
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
      disabled: field_disabled(field),
      omitted: field_omitted(field)
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
  defp field_disabled(field) when field in [:id, :deleted, :inactive],
    do: true

  defp field_disabled(_field), do: false

  @spec field_omitted(atom) :: boolean
  defp field_omitted(field) when field in [:inserted_at, :updated_at],
    do: true

  defp field_omitted(_field), do: false

  @spec put_option(map, Keyword.t(), atom) :: map
  defp put_option(resource_config, opts, key) do
    if Keyword.has_key?(opts, key),
      do: Map.put(resource_config, key, opts[key]),
      else: resource_config
  end
end
