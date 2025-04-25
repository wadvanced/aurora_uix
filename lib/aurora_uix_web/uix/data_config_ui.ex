defmodule AuroraUixWeb.Uix.DataConfigUI do
  @moduledoc """
  Provides a comprehensive, declarative UI configuration system for structured data in Phoenix LiveView.

  ## Overview
  This module enables rich, metadata-driven UI configuration for data structures, with a focus on:
  - Flexible field-level UI metadata management
  - Seamless integration with Phoenix LiveView
  - Type-aware default generation
  - Cross-structure configuration inheritance

  ## Key Capabilities
  - Declarative field configuration (labels, placeholders, validation)
  - Automatic type inference for HTML input types
  - Support for Ecto schemas and custom data structures
  - Customizable rendering and interaction rules

  ## Configuration Strategies
  - Field-level customization
  - Bulk field configuration
  - Automatic default generation based on field types
  - Inheritance and extension of configurations

  ## Supported Field Attributes
  - Labels and placeholders
  - Input types and lengths
  - Validation rules
  - Rendering options (readonly, hidden, disabled)
  - Precision and scale for numeric fields

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
        field :products, resource: :product
      end
    end
  ```

  ## Performance and Flexibility
  - Minimal runtime overhead
  - Compile-time configuration generation
  - Extensible through custom parsing and rendering strategies
  """

  alias AuroraUix.Field
  alias AuroraUix.ResourceConfigUI
  alias AuroraUixWeb.Uix
  alias AuroraUixWeb.Uix.DataConfigUI

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.DataConfigUI

      Module.register_attribute(__MODULE__, :auix_resource_config, accumulate: true)
      Module.register_attribute(__MODULE__, :_auix_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :_auix_select_options, accumulate: true)

      @before_compile AuroraUixWeb.Uix.DataConfigUI
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    ## Field modifications (@_auix_fields) are returned in reversed creation order, too.

    resources =
      env.module
      |> Module.get_attribute(:_auix_fields)
      |> Enum.filter(&(&1.tag == :resource and &1.state == :end and &1.config[:schema] != nil))
      |> Enum.map(&{&1.name, &1.config[:schema]})

    changes =
      env.module
      |> Module.get_attribute(:_auix_fields)
      |> Enum.reverse()
      |> parse_change(resources, %{}, [])
      |> Map.new()

    if !Enum.empty?(changes),
      do: Module.put_attribute(env.module, :auix_resource_config, changes)

    Module.delete_attribute(env.module, :_auix_fields)

    resource_configs = Module.get_attribute(env.module, :auix_resource_config)

    resource_functions =
      resource_configs
      |> Kernel.||([])
      |> List.flatten()
      |> List.first(%{})
      |> Enum.map(fn {resource_key, resource} ->
        quote do
          @doc """
          Gets the config for a given resource.
          """
          @spec auix_resource(atom) :: map
          def auix_resource(unquote(resource_key)) do
            %{unquote(resource_key) => unquote(Macro.escape(resource))}
          end
        end
      end)

    quote do
      @doc """
      Gets all resources config.
      """
      @spec auix_resources() :: list
      def auix_resources do
        unquote(Macro.escape(resources))
      end

      unquote(resource_functions)
    end
  end

  @doc """
  Defines a declarative UI configuration for a specific resource (schema).

  Enables comprehensive UI metadata management for structured data, supporting
  dynamic configuration of fields, associations, and rendering strategies.

  ## Parameters
  - `name` (atom): A unique identifier for the resource configuration
  - `opts` (keyword): Configuration options for the resource

  ## Options
  - `:schema` (module, required): The Ecto schema or data structure being configured
  - `:context` (module, optional): Context module containing data access functions
  - `:include_associations` (boolean, default: false): Automatically configure associations

  ## Example
    ```elixir
      auix_resource_config :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end
    ```

  ## Behaviour
  - Initializes a new resource configuration block
  - Allows nested field configuration
  - Generates default configurations based on schema metadata
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

        unquote(block) || []

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
  Configures a single field within a resource configuration.

  Provides fine-grained control over field presentation, validation,
  and interaction rules. Supports comprehensive customization of
  individual fields.

  ## Parameters
  - `field` (atom): The name of the field to configure
  - `opts` (keyword): Field-specific configuration options

  ## Options

  The following options can be provided to configure the field:

  - `:field` (`atom`) - The referred field in the schema. This should be rarely changed.
  - `:field_type`(`atom`) - The html type that best represent the current field elixir type.
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

  Enables bulk configuration of fields, reducing repetitive code
  and promoting consistent field settings across multiple attributes.

  ## Parameters
  - `fields` (list of atoms): Fields to be configured
  - `opts` (keyword): Configuration options applied to all specified fields

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
      fields: [...],
      associations: [...]
    }

  """
  @spec default_config(Keyword.t(), list) :: ResourceConfigUI.t()
  def default_config(opts, resources) do
    schema = opts[:schema]

    %ResourceConfigUI{}
    |> put_option(opts, :context)
    |> put_option(opts, :schema)
    |> struct(%{fields: parse_fields(schema, resources)})
  end

  ## PRIVATE

  @spec parse_change(list, list, map, list) :: map
  defp parse_change([%{tag: :resource, state: :start} | rest], resources, acc, _current) do
    parse_change(rest, resources, acc, [])
  end

  defp parse_change(
         [%{tag: :resource, name: name, config: opts, state: :end} | rest],
         resources,
         acc,
         current
       ) do
    resource =
      opts
      |> default_config(resources)
      |> ResourceConfigUI.change(fields: Enum.reverse(current))

    parse_change(rest, resources, Map.put(acc, name, resource), [])
  end

  defp parse_change([%{tag: :field, field: field, opts: opts} | rest], resources, acc, current) do
    parse_change(rest, resources, acc, [{field, Map.new(opts)} | current])
  end

  defp parse_change([], _resources, acc, _current), do: acc

  @spec parse_fields(module | nil, list) :: list
  defp parse_fields(nil, _resources), do: []

  defp parse_fields(schema, resources) do
    Code.ensure_compiled(schema)

    if function_exported?(schema, :__schema__, 1) do
      :fields
      |> schema.__schema__()
      |> Enum.map(&parse_field(schema, resources, &1))
      |> add_associations(schema, resources)
    else
      []
    end
  end

  @spec parse_field(module, list, atom) :: Field.t()
  defp parse_field(module, resources, field) do
    type = module.__schema__(:type, field)
    association = module.__schema__(:association, field)

    attrs = %{
      field: field,
      label: field_label(field),
      placeholder: field_placeholder(field, type),
      field_type: field_type(type, association),
      field_html_type: field_html_type(type, association),
      length: field_length(type),
      precision: field_precision(type),
      scale: field_scale(type),
      disabled: field_disabled(field),
      omitted: field_omitted(field),
      resource: field_resource(association, resources),
      data: field_data(association)
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

  @spec field_type(atom, map | nil) :: atom
  defp field_type(type, nil), do: type

  defp field_type(nil, %{cardinality: :many} = _association), do: :one_to_many_association

  defp field_type(nil, %{cardinality: :one} = _association),
    do: :many_to_one_association

  @spec field_html_type(atom, map | nil) :: atom
  defp field_html_type(type, _association)
       when type in [:string, :binary_id, :binary, :bitstring, Ecto.UUID],
       do: :text

  defp field_html_type(type, _association) when type in [:id, :integer, :float, :decimal],
    do: :number

  defp field_html_type(type, _association)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: :"datetime-local"

  defp field_html_type(type, _association) when type in [:time, :time_usec], do: :time

  defp field_html_type(:boolean, _association), do: :checkbox

  defp field_html_type(type, nil), do: type

  defp field_html_type(nil, %{cardinality: :many} = _association), do: :one_to_many_association

  defp field_html_type(nil, %{cardinality: :one} = _association),
    do: :many_to_one_association

  defp field_html_type(nil, _association), do: :unimplemented

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

  @spec field_scale(atom) :: integer
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

  @spec field_data(map | nil) :: map
  defp field_data(nil), do: nil

  defp field_data(association),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  @spec field_resource(map | nil, list) :: :atom
  defp field_resource(nil, _resources), do: nil

  defp field_resource(association, resources) do
    resources
    |> Enum.find({nil, nil}, &(elem(&1, 1) == association.related))
    |> elem(0)
  end

  @spec put_option(map, Keyword.t(), atom) :: map
  defp put_option(resource_config, opts, key) do
    if Keyword.has_key?(opts, key),
      do: Map.put(resource_config, key, opts[key]),
      else: resource_config
  end

  @spec add_associations(list, module, list) :: list
  defp add_associations(fields, schema, resources) do
    :associations
    |> schema.__schema__()
    |> Enum.reduce(Enum.reverse(fields), &parse_association(schema, resources, &1, &2))
    |> Enum.reverse()
  end

  @spec parse_association(module, list, atom, list) :: list
  defp parse_association(schema, resources, association_field, fields) do
    :association
    |> schema.__schema__(association_field)
    |> then(
      &Field.new(
        field: association_field,
        field_type: field_html_type(nil, &1),
        data: field_data(&1),
        resource: field_resource(&1, resources)
      )
    )
    |> then(&[&1 | fields])
  end
end
