defmodule Aurora.Uix.Layout.ResourceMetadata do
  @moduledoc """
  Provides a comprehensive, declarative UI configuration system for structured data in Phoenix LiveView.

  ## Key Features
  - Enables rich, metadata-driven UI configuration for data structures.
  - Focuses on flexible field-level UI metadata management and seamless integration with Phoenix LiveView.

  ## Key Constraints
  - Supports Ecto schemas and custom data structures.
  - Designed for compile-time configuration generation with minimal runtime overhead.
  - Not intended for direct use outside Aurora.Uix internals.

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
      auix_resource_metadata :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      auix_resource_metadata :category, schema: MyApp.Category do
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

  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Layout.ResourceMetadata
  alias Aurora.Uix.Resource

  @spec __using__(any()) ::
          {:__block__, [], [{:@ | :import | {any(), any(), any()}, [...], [...]}, ...]}
  defmacro __using__(_opts) do
    quote do
      import Aurora.Uix.Layout.ResourceMetadata

      Module.register_attribute(__MODULE__, :_auix_process_resource_config, accumulate: true)

      @before_compile Aurora.Uix.Layout.ResourceMetadata
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    resources_metadata =
      env.module
      |> Module.get_attribute(:_auix_process_resource_config)
      |> configure_fields()
      |> add_associations()
      |> convert_fields_to_map()

    resource_functions =
      Enum.map(resources_metadata, fn {resource_key, resource} ->
        quote do
          @doc """
          Gets the config for a given resource.
          """
          @spec auix_resource(atom()) :: map()
          def auix_resource(unquote(resource_key)) do
            %{unquote(resource_key) => unquote(Macro.escape(resource))}
          end
        end
      end)

    quote do
      Module.put_attribute(
        unquote(env.module),
        :auix_resource_metadata,
        unquote(Macro.escape(resources_metadata))
      )

      @doc """
      Gets the configuration for all configured resources.

      Returns all resource metadata configurations.

      Returns a list of resource configurations.
      """
      @spec auix_resources() :: list()

      @doc """
      Gets the configuration for a specific resource.

      Returns a map containing just that resource's configuration.

      Returns a map with the resource key and its config.
      """
      @spec auix_resource(atom()) :: map()

      def auix_resources do
        unquote(Macro.escape(resources_metadata))
      end

      unquote(resource_functions)
    end
  end

  @doc """
  Defines UI configuration for a schema.

  ## Parameters
  - `name` (atom()) - Resource identifier.
  - `opts` (keyword()) - Configuration options.
  - `do_block` (Macro.t() | nil) - Field configurations block.

  ## Options
  - `:schema` (module()) - Required. Ecto schema/data structure module.
  - `:context` (module()) - Optional. Context module with data functions.
  - `:include_associations` (boolean()) - Optional. Auto-configure associations.

  ## Returns
  `Macro.t()` - Configured metadata block for the resource.
  """
  @spec auix_resource_metadata(atom(), keyword(), Macro.t() | nil) :: Macro.t()
  defmacro auix_resource_metadata(name, opts \\ [], do_block \\ nil) do
    {block, opts} = LayoutHelpers.extract_block_options(opts, do_block)

    resource_config =
      quote do
        %{
          tag: :resource,
          name: unquote(name),
          opts: unquote(opts),
          inner_elements: unquote(LayoutHelpers.prepare_block(block))
        }
      end

    quote do
      use ResourceMetadata
      Module.put_attribute(__MODULE__, :_auix_process_resource_config, unquote(resource_config))
    end
  end

  @doc """
  Configures a single field within a resource configuration.

  Provides fine-grained control over field presentation, validation,
  and interaction rules. Supports comprehensive customization of
  individual fields.

  ## Parameters
  - `field` (atom() | tuple()): The name of the field to configure
  - `opts` (keyword()): Field-specific configuration options

  ## Options

  The following options can be provided to configure the field:

  - `:key` (`atom()` | tuple()) - The referred field in the schema. This should be rarely changed.
  - `:type`(`atom()`) - The html type that best represent the current field elixir type.
  - `:label` (`binary()`) - A custom label for the field. (auto-generated from field name if omitted).
  - `:placeholder` (`binary()`) - Placeholder text for the field.
  - `:length`(`non_neg_integer()`) - Display length of the field.
  - `:precision` (`integer()`) - The numeric precision for decimal or float fields.
  - `:scale` (`integer()`) - The numeric scale for decimal or float fields.
  - `:readonly` (`boolean()`) - Marks the field as read-only.
  - `:hidden` (`boolean()`) - Hides the field.
  - `:renderer` (`function()`) - Custom rendering function/component.
  - `:required` (`boolean()`) - Marks the field as required.
  - `:disabled` (`boolean()`) - If true, the field should not participate in form interaction.
  - `:omitted` (`boolean()`) - If true, the field will be entirely excluded from the UI and configuration.

  ## Example

  ```elixir
  field :name, label: "Product Name", placeholder: "Enter product name", required: true
  field :price, precision: 12, scale: 2, label: "Price ($)"
  ```
  """
  @spec field(atom() | tuple(), keyword()) :: Macro.t()
  defmacro field(field, opts \\ []) do
    LayoutHelpers.register_dsl_entry(:field, field, [], opts, nil)
  end

  @doc """
  Applies configuration to multiple fields simultaneously.

  Enables bulk configuration of fields, reducing repetitive code
  and promoting consistent field settings across multiple attributes.

  ## Parameters
  - `fields` (list() of atoms or tuples): Fields to be configured
  - `opts` (keyword()): Configuration options applied to all specified fields

  ## Example
  ```elixir
  fields [:msrp, :rrp, :list_price], precision: 10, scale: 2
  ```
  """
  @spec fields([atom() | tuple()], keyword()) :: Macro.t()
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

  # Process initial field configuration for resources:
  # 1. Initializes base struct with schema/context
  # 2. Parsing schema fields into Field structs
  # 3. Applying field changes from config
  # 4. Reordering fields by configuration order
  @spec configure_fields([map()]) :: list()
  defp configure_fields(resources) do
    Enum.map(resources, &configure_resource_fields/1)
  end

  # Configure fields for a single resource:
  # - Sets up basic struct with schema and context
  # - Processes field metadata from schema
  # - Returns {name, resource} tuple
  @spec configure_resource_fields(map()) :: {atom(), Resource.t()}
  defp configure_resource_fields(resource) do
    schema = resource.opts[:schema]

    resource =
      %Resource{name: resource.name}
      |> put_option(resource.opts, :context)
      |> put_option(resource.opts, :schema)
      |> struct(%{
        fields: parse_fields(schema, resource.name),
        inner_elements: resource.inner_elements
      })

    {resource.name, resource}
  end

  # Apply field changes from resource config block:
  # - Merges changes with existing fields
  # - Later changes override earlier ones
  # - Preserves field order
  @spec apply_field_changes(map(), map()) :: map()
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
      |> Map.get(field.key, [])
      |> apply_field_change(field)
    end)
    |> then(&struct(resource_struct, %{fields: &1}))
  end

  @spec apply_field_change(keyword(), Field.t()) :: Field.t()
  defp apply_field_change(change, field) do
    change
    |> Enum.map(&maybe_add_option_to_data(&1, field))
    |> then(&Field.change(field, &1))
  end

  @spec maybe_add_option_to_data(tuple(), Field.t()) :: tuple()
  defp maybe_add_option_to_data({:option_label, option_label}, field) do
    field
    |> Map.get(:data, %{})
    |> then(&{:data, Map.put(&1, :option_label, option_label)})
  end

  defp maybe_add_option_to_data(option, _field), do: option

  # Reorder fields based on config block order:
  # - Keeps configured fields in order of appearance
  # - Appends unconfigured fields at end
  # - Maintains field associations
  @spec reorder_fields_by_changes(map(), map()) :: map()
  defp reorder_fields_by_changes(resource_struct, %{inner_elements: []}), do: resource_struct

  defp reorder_fields_by_changes(%{fields: fields, name: resource_name} = resource_struct, %{
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
          %{key: field.name, resource: resource_name}
          |> Field.new()
          |> Field.change(field.opts),
          fn field_struct -> field_struct.key == field.name end
        )
      end)
      |> Enum.reverse()

    # Filter out known processed fields and then append each field to the first_fields
    # In this way the order defined in the resource config is the one used leaving the
    # unmentioned fields at the bottom.
    fields
    |> Enum.reject(&(&1.key in changes))
    |> Enum.reduce(first_fields, &[&1 | &2])
    |> Enum.reverse()
    |> then(&struct(resource_struct, %{fields: &1}))
  end

  @spec convert_fields_to_map(list()) :: map()
  defp convert_fields_to_map(resources) do
    resources
    |> Enum.map(&convert_resource_fields_to_map/1)
    |> Map.new()
  end

  # Converts a resource's fields list to a map format for faster access.
  # Also maintains fields order in a separate list for consistent iteration.
  @spec convert_resource_fields_to_map({atom(), map()}) :: {atom(), map()}
  defp convert_resource_fields_to_map({resource_name, %{fields: fields} = resource})
       when is_list(fields) do
    fields_order =
      fields
      |> Enum.reject(& &1.omitted)
      |> Enum.map(& &1.key)
      |> Enum.uniq()

    fields
    |> Enum.map(&{&1.key, &1})
    |> Map.new()
    |> then(&Map.merge(resource, %{fields: &1, fields_order: fields_order}))
    |> then(&{resource_name, &1})
  end

  defp convert_resource_fields_to_map(resource), do: resource

  # Parses schema fields into Field structs with metadata.
  # Returns empty list if schema isn't available or compiled.
  @spec parse_fields(module() | nil, atom()) :: list()
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
  @spec parse_field(module(), atom(), atom()) :: Field.t()
  defp parse_field(module, resource_name, field_key) do
    type = module.__schema__(:type, field_key)
    association = module.__schema__(:association, field_key)

    attrs = %{
      key: field_key,
      label: field_label(field_key),
      placeholder: field_placeholder(field_key, type),
      type: field_type(type, association),
      html_type: field_html_type(type, association),
      length: field_length(type),
      precision: field_precision(type),
      scale: field_scale(type),
      disabled: field_disabled(field_key),
      omitted: field_omitted(field_key),
      hidden: field_hidden(field_key),
      resource: resource_name,
      data: field_data(association)
    }

    Field.new(attrs)
  end

  # Formats a display label from a field name
  # Capitalizes and converts underscores to spaces
  @spec field_label(atom()) :: binary()
  defp field_label(nil), do: ""

  defp field_label(name),
    do: name |> to_string() |> String.replace("_", " ") |> String.capitalize()

  # Determines default placeholder text for a field
  # Based on the field's Elixir type
  @spec field_placeholder(atom(), atom()) :: binary()
  defp field_placeholder(_, type) when type in [:id, :integer, :float, :decimal], do: "0"

  defp field_placeholder(_, type)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: "yyyy/MM/dd HH:mm:ss"

  defp field_placeholder(_, type) when type in [:time, :time_usec], do: "HH:mm:ss"
  defp field_placeholder(name, _type), do: name |> to_string() |> String.capitalize()

  # Maps an Elixir type to a field type
  # Handles both basic types and associations
  @spec field_type(atom(), map() | nil) :: atom()
  defp field_type(type, nil), do: type

  defp field_type(nil, %{cardinality: :many} = _association), do: :one_to_many_association

  defp field_type(nil, %{cardinality: :one} = _association),
    do: :many_to_one_association

  # Maps an Elixir type to an HTML input type
  # Provides appropriate HTML5 input types based on data type
  @spec field_html_type(atom(), map() | nil) :: atom()
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

  # Determines display length for a field
  # Sets sensible defaults based on data type
  @spec field_length(atom()) :: integer()
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

  # Gets numeric precision for number fields
  # Returns 0 for non-numeric fields
  @spec field_precision(atom()) :: integer()
  defp field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  defp field_precision(_type), do: 0

  # Gets numeric scale for decimal/float fields
  # Returns 0 for non-decimal fields
  @spec field_scale(atom()) :: integer()
  defp field_scale(type) when type in [:float, :decimal], do: 2
  defp field_scale(_type), do: 0

  # Checks if a field should be disabled
  # Disabled fields: id, deleted, inactive
  @spec field_disabled(atom()) :: boolean()
  defp field_disabled(key) when key in [:id, :deleted, :inactive],
    do: true

  defp field_disabled(_field), do: false

  # Checks if a field should be omitted
  # Omitted fields: inserted_at, updated_at
  @spec field_omitted(atom()) :: boolean()
  defp field_omitted(key) when key in [:inserted_at, :updated_at],
    do: true

  defp field_omitted(_field), do: false

  @spec field_hidden(atom()) :: boolean()
  defp field_hidden(_field), do: false

  # Extracts metadata for associations
  # Returns nil for non-association fields
  @spec field_data(map() | nil) :: map() | nil
  defp field_data(nil), do: nil

  defp field_data(association),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  # Finds matching resource for an association
  # Returns resource name if found, nil if not
  @spec field_resource(map() | nil, list()) :: atom() | nil
  defp field_resource(nil, _resources), do: nil

  defp field_resource(association, resources) do
    resources
    |> Enum.find({nil, nil}, fn {_resource_name, resource} ->
      resource.schema == association.related
    end)
    |> elem(0)
  end

  # Updates map with an option if present in opts
  # Returns original map if option not present
  @spec put_option(map(), keyword(), atom()) :: map
  defp put_option(resource_config, opts, key) do
    if Keyword.has_key?(opts, key),
      do: Map.put(resource_config, key, opts[key]),
      else: resource_config
  end

  # Processes and adds schema associations
  # Adds each association as a field with proper metadata
  @spec add_associations(list()) :: list
  defp add_associations(resources) do
    Enum.map(resources, fn resource ->
      resource
      |> add_resource_associations(resources)
      |> then(&{elem(&1, 0), &1 |> elem(1) |> struct(%{inner_elements: []})})
    end)
  end

  # Adds associations to a single resource
  # Maintains proper field ordering
  @spec add_resource_associations({atom(), map()}, list()) :: {atom(), map()}
  defp add_resource_associations({name, %{schema: nil} = resource}, _resources),
    do: {name, resource}

  defp add_resource_associations({name, %{schema: schema, fields: fields} = resource}, resources) do
    :associations
    |> schema.__schema__()
    |> Enum.reduce(Enum.reverse(fields), &parse_association(schema, name, resources, &1, &2))
    |> Enum.reverse()
    |> then(&struct(resource, %{fields: &1}))
    |> configure_many_to_one_selectors()
    |> apply_field_changes(resource)
    |> reorder_fields_by_changes(resource)
    |> then(&{name, &1})
  end

  # Converts a schema association into a Field struct
  # Includes association metadata and proper field type
  @spec parse_association(module(), atom(), list(Resource.t()), atom(), map()) ::
          list(Resource.t())
  defp parse_association(schema, resource_name, resources, association_field_key, fields) do
    :association
    |> schema.__schema__(association_field_key)
    |> then(
      &Field.new(
        key: association_field_key,
        html_type: field_html_type(nil, &1),
        type: field_type(nil, &1),
        data: Map.put(field_data(&1), :resource, field_resource(&1, resources)),
        resource: resource_name
      )
    )
    |> then(&[&1 | fields])
  end

  @spec configure_many_to_one_selectors(Resource.t()) :: Resource.t()
  defp configure_many_to_one_selectors(%{fields: fields} = resource) do
    fields
    |> Enum.filter(&(&1.type == :many_to_one_association))
    |> Enum.reject(&(get_in(&1, [Access.key!(:data), :resource]) == nil))
    |> Enum.map(&{&1.data.owner_key, %{html_type: :select, data: &1.data}})
    |> Enum.reduce(fields, &replace_related_field/2)
    |> then(&struct(resource, %{fields: &1}))
  end

  @spec replace_related_field(tuple(), list(Field.t())) :: list(Field.t())
  defp replace_related_field(related_changes, fields),
    do: Enum.map(fields, &replace_related_field_data(&1, related_changes))

  @spec replace_related_field_data(Field.t(), {atom(), map()}) :: Field.t()
  defp replace_related_field_data(%{type: type} = field, _related_changes)
       when type in [:many_to_one_association, :one_to_many_association],
       do: field

  defp replace_related_field_data(
         %{key: field_key, label: label} = field,
         {field_key, changes}
       ) do
    label
    |> Kernel.||("")
    |> String.replace_suffix(" id", "")
    |> then(&Map.put(changes, :label, &1))
    |> then(&Field.change(field, &1))
  end

  defp replace_related_field_data(field, _related_changes), do: field
end
