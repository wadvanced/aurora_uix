defmodule Aurora.Uix.Layout.ResourceMetadata do
  @moduledoc """
  Provides a comprehensive, declarative UI configuration system for structured data in
  Phoenix LiveView.

  Enables rich, metadata-driven UI configuration for data structures with flexible
  field-level UI metadata management and seamless integration with Phoenix LiveView.

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
  """

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Layout.ResourceMetadata
  alias Aurora.Uix.Resource

  @doc false
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
    Counter.start_counter(:auix_fields)

    resources_metadata = resource_metadata(env.module)

    resource_functions = Enum.map(resources_metadata, &resource_functions/1)

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

  ### Common Options

  - `:order_by` (atom() | list() | keyword()) - Order used for displaying the index.
    * atom() - Single field name (e.g., `:name`)
    * list() - List of field names
    * keyword() - Direction-annotated fields (e.g., `[desc: :created_at]`)
    See [Ecto.Query.order_by/3](https://hexdocs.pm/ecto/Ecto.Query.html#order_by/3)
    for details about the supported directions.

  ### Context-based Integration (`:ctx` type)

  For Ecto schema resources with Context modules:

  - `:schema` (module()) - Required. Ecto schema module.
  - `:context` (module()) - Required. Context module with CRUD functions.

  ### Ash Framework Integration (`:ash` type)

  For Ash Framework resources:

  - `:ash_resource` (module()) - Required. Ash resource module.
  - `:ash_domain` (module()) - Optional. Ash domain module. If omitted, actions are
    resolved directly from the resource.

  Note: You can also use `:schema` as an alias for `:ash_resource` and `:context` as
  an alias for `:ash_domain` when working with Ash resources.

  ## Examples

  ### Context-based Resource

      auix_resource_metadata(:product,
        schema: MyApp.Inventory.Product,
        context: MyApp.Inventory,
        order_by: :reference
      )

  ### Context Resource with Sort Direction

      auix_resource_metadata(:product,
        schema: MyApp.Inventory.Product,
        context: MyApp.Inventory,
        order_by: [desc: :created_at]
      )

  ### Ash Resource

      auix_resource_metadata(:author,
        ash_resource: MyApp.Blog.Author,
        order_by: [:name]
      )

  ### Ash Resource with Domain

      auix_resource_metadata(:post,
        ash_resource: MyApp.Blog.Post,
        ash_domain: MyApp.Blog,
        order_by: [desc: :published_at]
      )

  ## Returns

  Macro.t() - Configured metadata block for the resource.
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
  - `:filterable?` (`boolean()`) - If true, allows the field to participate in UI filtering.
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
    LayoutHelpers.register_dsl_entry(:field, field, [], opts, nil, __CALLER__)
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
  @spec resource_metadata(module()) :: map()
  defp resource_metadata(module) do
    module
    |> Module.get_attribute(:_auix_process_resource_config)
    |> embedded_resources()
    |> configure_fields()
    |> add_associations()
    |> convert_fields_to_map()
  end

  @spec embedded_resources([map()]) :: [map()]
  defp embedded_resources(resource_configs) do
    resource_configs
    |> Enum.map(&embedded_resource_config_data/1)
    |> Enum.reduce(resource_configs, &embedded_resource/2)
  end

  @spec embedded_resource_config_data(map()) :: {atom(), module()} | nil
  defp embedded_resource_config_data(%{name: name, tag: :resource} = resource) do
    case define_schema_and_type(resource) do
      {nil, _} -> nil
      {schema, resource_type} -> {name, schema, resource_type}
    end
  end

  @spec embedded_resource({atom(), module()} | nil, [map()]) :: [map()]
  defp embedded_resource(nil, result), do: result

  defp embedded_resource({_parent_resource_name, _schema_module, type} = parent_resource, result) do
    LayoutHelpers.get_fields_parser_module(type).embedded_resource(parent_resource, result)
  end

  # creates the function for each resource.
  @spec resource_functions({atom(), map()}) :: Macro.t()
  defp resource_functions({resource_key, resource}) do
    quote do
      @doc """
      Gets the config for a given resource.
      """
      @spec auix_resource(atom()) :: map()
      def auix_resource(unquote(resource_key)) do
        %{unquote(resource_key) => unquote(Macro.escape(resource))}
      end
    end
  end

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
    {schema, resource_type} = define_schema_and_type(resource)

    context = resource.opts[:context] || resource.opts[:ash_domain]

    opts =
      resource.opts
      |> Keyword.delete(:schema)
      |> Keyword.delete(:context)
      |> Keyword.delete(:ash_resource)
      |> Keyword.delete(:ash_domain)

    fields_parser = LayoutHelpers.get_fields_parser_module(resource_type)

    parsed_resource =
      %Resource{name: resource.name}
      |> put_option(resource.opts, :context)
      |> put_option(resource.opts, :schema)
      |> struct(%{
        schema: schema,
        context: context,
        type: resource_type,
        opts: opts,
        fields: fields_parser.parse_fields(schema, resource.name),
        inner_elements: resource.inner_elements
      })

    {resource.name, parsed_resource}
  end

  @spec define_schema_and_type(map()) :: tuple()
  defp define_schema_and_type(resource) do
    schema =
      resource.opts[:schema] ||
        resource.opts[:ash_resource]

    resource_type = resource.opts[:type] || resource_type(schema)
    {schema, resource_type}
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
  defp apply_field_change([], field), do: field

  defp apply_field_change(change, field) do
    change
    |> Enum.reduce(%{data: Map.get(field, :data, %{})}, &maybe_add_option_to_data(&1, &2))
    |> then(&Field.change(field, &1))
  end

  @spec maybe_add_option_to_data(tuple(), map()) :: map()
  defp maybe_add_option_to_data({:option_label, option_label}, result) do
    result
    |> Map.get(:data, %{})
    |> Map.put(:option_label, option_label)
    |> then(&Map.put(result, :data, &1))
  end

  defp maybe_add_option_to_data({option_key, option_value}, result)
       when option_key in [:order_by, :where] do
    data = Map.get(result, :data, %{})

    data
    |> Map.get(:query_opts, [])
    |> Keyword.put(option_key, option_value)
    |> then(&Map.put(data, :query_opts, &1))
    |> then(&Map.put(result, :data, &1))
  end

  defp maybe_add_option_to_data({key, value}, result), do: Map.put(result, key, value)

  # - Appends unconfigured fields at end
  @spec add_new_fields_from_changes(map(), map()) :: map()
  defp add_new_fields_from_changes(resource_struct, %{inner_elements: []}), do: resource_struct

  defp add_new_fields_from_changes(%{fields: fields, name: resource_name} = resource_struct, %{
         inner_elements: field_changes
       }) do
    fields_list = Enum.map(fields, & &1.key)

    # Creates a list of Field.t() according to the changes order. New fields are added in this stage.
    new_fields =
      field_changes
      |> List.flatten()
      |> Enum.reject(&(&1.name in fields_list))
      |> Enum.map(fn field ->
        %{key: field.name, resource: resource_name}
        |> Field.new()
        |> Field.change(field.opts)
      end)

    # Filter out known processed fields and then append each field to the first_fields
    # In this way the order defined in the resource config is the one used leaving the
    # unmentioned fields at the bottom.
    fields
    |> Enum.reverse()
    |> Enum.reduce(new_fields, &[&1 | &2])
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
    fields_parser = LayoutHelpers.get_fields_parser_module(resource.type)

    schema
    |> fields_parser.parse_associations(name, resources, fields)
    |> Enum.reverse()
    |> then(&struct(resource, %{fields: &1}))
    |> configure_many_to_one_selectors()
    |> apply_field_changes(resource)
    |> add_new_fields_from_changes(resource)
    |> then(&{name, &1})
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

  @spec resource_type(nil | module()) :: atom()
  defp resource_type(nil), do: :default

  defp resource_type(schema) do
    functions = schema.__info__(:functions)

    cond do
      Enum.any?(functions, &(&1 == {:__spark_placeholder__, 0})) -> :ash
      Enum.any?(functions, &(&1 == {:__schema__, 1})) -> :ctx
      true -> :default
    end
  end
end
