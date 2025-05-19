defmodule Aurora.Uix.DataConfigUI do
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
  - Validation rules (e.g. required)
  - Rendering options (readonly, hidden, disabled)
  - Precision and scale for numeric fields
  - Custom rendering via component or function
  - Omission flag to exclude fields entirely (`:omitted`)

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

  import Aurora.Uix.Helper

  alias Aurora.Uix.Field
  alias Aurora.Uix.ResourceConfigUI
  alias Aurora.Uix.DataConfigUI

  defmacro __using__(_opts) do
    quote do
      import Aurora.Uix.DataConfigUI

      Module.register_attribute(__MODULE__, :_auix_process_resource_config, accumulate: true)

      @before_compile Aurora.Uix.DataConfigUI
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    resource_configs =
      env.module
      |> Module.get_attribute(:_auix_process_resource_config)
      |> configure_fields()
      |> add_associations()
      |> convert_fields_to_map()

    resource_functions =
      Enum.map(resource_configs, fn {resource_key, resource} ->
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
      Module.put_attribute(
        unquote(env.module),
        :auix_resource_config,
        unquote(Macro.escape(resource_configs))
      )

      @doc """
      Gets all resources config.
      """
      @spec auix_resources() :: list
      def auix_resources do
        unquote(Macro.escape(resource_configs))
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
  - `do_block` block (optional): Contains field-level UI configuration for the resource

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
    {block, opts} = extract_block_options(opts, do_block)

    resource_config =
      quote do
        %{
          tag: :resource,
          name: unquote(name),
          opts: unquote(opts),
          inner_elements: unquote(prepare_block(block))
        }
      end

    quote do
      use DataConfigUI
      Module.put_attribute(__MODULE__, :_auix_process_resource_config, unquote(resource_config))
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
  - `:disabled` (`boolean`) - If true, the field should not participate in form interaction.
  - `:omitted` (`boolean`) - If true, the field will be entirely excluded from the UI and configuration.

  ## Example

  ```elixir
  field :name, label: "Product Name", placeholder: "Enter product name", required: true
  field :price, precision: 12, scale: 2, label: "Price ($)"
  ```
  """
  @spec field(atom, keyword) :: Macro.t()
  defmacro field(field, opts \\ []) do
    register_dsl_entry(:field, field, [], opts, nil)
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
  @spec fields([atom], keyword) :: Macro.t()
  defmacro fields(fields, opts \\ []) do
    quotes =
      Enum.map(fields, fn field ->
        quote do
          field(unquote(field), unquote(opts))
        end
      end)

    quote do
      unquote(quotes)
    end
  end

  ## PRIVATE

  # Configures UI fields for a resource by:
  # 1. Initializing base struct with schema/context
  # 2. Parsing schema fields into Field structs
  # 3. Applying field changes from config
  # 4. Reordering fields according to config
  # Returns {resource_name, configured_struct} tuple
  @spec configure_fields([map]) :: list
  defp configure_fields(resources) do
    Enum.map(resources, &configure_resource_fields/1)
  end

  @spec configure_resource_fields(map) :: {atom, ResourceConfigUI.t()}
  defp configure_resource_fields(resource) do
    schema = resource.opts[:schema]

    resource =
      %ResourceConfigUI{name: resource.name}
      |> put_option(resource.opts, :context)
      |> put_option(resource.opts, :schema)
      |> struct(%{fields: parse_fields(schema, resource.name)})
      |> apply_field_changes(resource)
      |> reorder_fields_by_changes(resource)

    {resource.name, resource}
  end

  # Applies field changes from config to existing fields.
  # Merges duplicate changes (last one wins) and updates each field's options.
  @spec apply_field_changes(map, map) :: map
  defp apply_field_changes(%{fields: fields} = resource_struct, %{inner_elements: field_changes}) do
    # Creates a MAP of {field_name, opts}. The opts are merged discarding previous duplicated options changes.
    changes =
      field_changes
      |> List.flatten()
      |> Enum.reduce(%{}, fn %{name: field, opts: opts}, acc ->
        acc
        |> Map.get(field, [])
        |> Keyword.merge(opts)
        |> then(&Map.put(acc, field, &1))
      end)

    # Applies each opts to the field.
    fields
    |> Enum.map(fn field ->
      changes
      |> Map.get(field.field, [])
      |> then(&Field.change(field, &1))
    end)
    |> then(&struct(resource_struct, %{fields: &1}))
  end

  # Reorders fields putting configured fields first, keeping original order for others.
  # Unchanged fields appear after explicitly configured ones.
  @spec reorder_fields_by_changes(map, map) :: map
  defp reorder_fields_by_changes(resource_struct, %{inner_elements: []}), do: resource_struct

  defp reorder_fields_by_changes(%{fields: fields} = resource_struct, %{
         inner_elements: field_changes
       }) do
    # Creates a list of the field changes encountered within the resource config block.
    changes =
      field_changes
      |> List.flatten()
      |> Enum.map(& &1.name)
      |> Enum.uniq()

    # Creates a list of Field.t() according to the changes order. New fields are added in this stage.
    first_fields =
      field_changes
      |> List.flatten()
      |> Enum.map(fn field ->
        Enum.find(
          fields,
          %{field: field.name} |> Field.new() |> Field.change(field.opts),
          fn field_struct -> field_struct.field == field.name end
        )
      end)
      |> Enum.reverse()

    # Filter out known processed fields and then append each field to the first_fields
    # In this way the order defined in the resource config is the one used leaving the
    # unmentioned fields at the bottom.
    fields
    |> Enum.reject(&(&1.field in changes))
    |> Enum.reduce(first_fields, &[&1 | &2])
    |> Enum.reverse()
    |> then(&struct(resource_struct, %{fields: &1}))
  end

  @spec convert_fields_to_map(list) :: map
  defp convert_fields_to_map(resources) do
    resources
    |> Enum.map(&convert_resource_fields_to_map/1)
    |> Map.new()
  end

  @spec convert_resource_fields_to_map({atom, map}) :: {atom, map}
  defp convert_resource_fields_to_map({resource_name, %{fields: fields} = resource})
       when is_list(fields) do
    fields_order =
      fields
      |> Enum.map(& &1.field)
      |> Enum.uniq()

    fields
    |> Enum.map(&{&1.field, &1})
    |> Map.new()
    |> then(&Map.merge(resource, %{fields: &1, fields_order: fields_order}))
    |> then(&{resource_name, &1})
  end

  defp convert_resource_fields_to_map(resource), do: resource

  # Parses schema fields into Field structs with metadata.
  # Returns empty list if schema isn't available or compiled.
  @spec parse_fields(module | nil, atom) :: list
  defp parse_fields(nil, _resource_name), do: []

  defp parse_fields(schema, resource_name) do
    Code.ensure_compiled(schema)

    if function_exported?(schema, :__schema__, 1) do
      :fields
      |> schema.__schema__()
      |> Enum.map(&parse_field(schema, resource_name, &1))
    else
      []
    end
  end

  # Creates a single Field struct with type-specific attributes:
  # - HTML input type
  # - Validation constraints
  # - Association data (if applicable)
  @spec parse_field(module, atom, atom) :: Field.t()
  defp parse_field(module, resource_name, field) do
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
      resource: resource_name,
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

  # Finds the resource name that matches an association's related schema
  # Returns nil if no match found
  @spec field_resource(map | nil, list) :: atom | nil
  defp field_resource(nil, _resources), do: nil

  defp field_resource(association, resources) do
    resources
    |> Enum.find({nil, nil}, fn {_resource_name, resource} ->
      resource.schema == association.related
    end)
    |> elem(0)
  end

  # Conditionally adds a key to the map if it exists in the options
  # Returns the unchanged map if key not present
  @spec put_option(map, keyword, atom) :: map
  defp put_option(resource_config, opts, key) do
    if Keyword.has_key?(opts, key),
      do: Map.put(resource_config, key, opts[key]),
      else: resource_config
  end

  # Processes all resources to add their associations as fields
  # Returns updated resources map with associations included
  @spec add_associations(list) :: list
  defp add_associations(resources) do
    Enum.map(resources, &add_resource_associations(&1, resources))
  end

  # Adds a resource's associations to its fields list
  # Maintains field order while prepending associations
  @spec add_resource_associations({atom, map}, list) :: {atom, map}
  defp add_resource_associations({name, %{schema: nil} = resource}, _resources),
    do: {name, resource}

  defp add_resource_associations({name, %{schema: schema, fields: fields} = resource}, resources) do
    :associations
    |> schema.__schema__()
    |> Enum.reduce(Enum.reverse(fields), &parse_association(schema, resources, &1, &2))
    |> Enum.reverse()
    |> then(&struct(resource, %{fields: &1}))
    |> then(&{name, &1})
  end

  # Converts a schema association into a Field struct
  # Includes association metadata and proper field type
  @spec parse_association(module, list, atom, map) :: list
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
