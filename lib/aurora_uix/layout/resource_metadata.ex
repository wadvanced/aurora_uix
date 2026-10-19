defmodule Aurora.Uix.Layout.ResourceMetadata do
  @moduledoc """
  Spark DSL extension for resource metadata: `auix_resource_metadata`, `field`, `fields` and
  `upload`, available in any module that calls `use Aurora.Uix`.

  Each `auix_resource_metadata` declares one resource. Its options and every field option are
  validated at compile time, so an unknown or mistyped option fails compilation at its line.
  The declared resources are then resolved (schema parsed, associations linked, field options
  applied) and returned by the generated `auix_resources/0` and `auix_resource/1`.

  ## Example

  ```elixir
  defmodule MyAppWeb.Inventory.Views do
    use Aurora.Uix

    auix_resource_metadata :product do
      schema MyApp.Product
      context MyApp.Inventory
      field :id, hidden: true
      field :name, placeholder: "Product name", length: 40, required: true
      field :price, precision: 12, scale: 2
      fields [:msrp, :rrp], precision: 10, scale: 2

      field :image do
        upload allow: [accept: ~w(.png .jpg), max_entries: 1], consume: &MyApp.store/1
      end
    end

    auix_resource_metadata :category do
      schema MyApp.Category
      context MyApp.Inventory
      field :products, resource: :product
    end

    auix_resource_metadata :author, ash_resource: MyApp.Blog.Author, order_by: [:name],
      backend_opts: [ash_actor_assign: :current_user]
  end
  ```

  ## Resource options

  #{Spark.Options.docs(Aurora.Uix.Layout.ResourceMetadata.Dsl.resource_schema())}

  ## Field options

  #{Spark.Options.docs(Aurora.Uix.Layout.ResourceMetadata.Dsl.field_schema())}

  ## Key Features
  - Compile-time validation of every resource and field option, with the offending line.
  - `backend_opts` are validated by the resource's backend (see
    `Aurora.Uix.Integration.ContextParserDefaults.backend_opts_schema/1`).
  - `fields [:a, :b], opts` declares the same options for several fields.

  ## Key Constraints
  - Function options take captured functions (`&Mod.fun/1`), not inline `fn`.
  - A context (`:ctx`) resource requires `:context`.
  - A field option explicitly set to `nil` is the same as leaving it out.
  """

  use Spark.Dsl.Extension,
    sections: [__MODULE__.Dsl.section()],
    transformers: [__MODULE__.ResolveResources]

  alias Aurora.Uix.Field
  alias Aurora.Uix.Integration.ContextParserDefaults
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Resource
  alias Spark.Dsl.Entity
  alias Spark.Error.DslError

  @doc """
  Prepares a declared resource for resolution: detects its backend, expands `fields` entries
  into one field each and validates the backend options.

  ## Parameters
  - `resource` (Resource.t()) - The resource as declared.
  - `module` (module()) - The module declaring it, for error reporting.

  ## Returns
  `Aurora.Uix.Resource.t()` - The declared resource, ready for `resolve_resources/1`.

  Raises `Spark.Error.DslError` for a context resource without `:context` or invalid
  `:backend_opts`.
  """
  @spec prepare_resource(Resource.t(), module()) :: Resource.t()
  def prepare_resource(%Resource{} = resource, module) do
    resource
    |> struct(%{type: resource.type || schema_type(resource.schema)})
    |> struct(%{field_overrides: Enum.flat_map(resource.field_overrides, &expand_keys/1)})
    |> validate_context(module)
    |> validate_backend_opts(module)
  end

  @doc """
  Returns the code defining `auix_resources/0`, `auix_resource/1` and the
  `@auix_resource_metadata` attribute for the resolved resources.

  ## Parameters
  - `resources` (map()) - Resolved resources by name.

  ## Returns
  `Macro.t()` - The code to evaluate in the declaring module.
  """
  @spec resource_functions_code(%{atom() => Resource.t()}) :: Macro.t()
  def resource_functions_code(resources) do
    resource_functions = Enum.map(resources, &resource_functions/1)

    quote do
      Module.put_attribute(__MODULE__, :auix_resource_metadata, unquote(Macro.escape(resources)))

      @doc """
      Gets the configuration for all configured resources.
      """
      @spec auix_resources() :: map()
      def auix_resources do
        unquote(Macro.escape(resources))
      end

      unquote(resource_functions)

      def auix_resource(_), do: nil
    end
  end

  ## PRIVATE

  @spec resource_functions({atom(), Resource.t()}) :: Macro.t()
  defp resource_functions({resource_key, resource}) do
    quote do
      @doc """
      Gets the config for a given resource.
      """
      @spec auix_resource(atom()) :: map()
      def auix_resource(unquote(resource_key)) do
        unquote(Macro.escape(resource))
      end
    end
  end

  @spec expand_keys(Field.t()) :: [Field.t()]
  defp expand_keys(%Field{key: keys} = field) when is_list(keys),
    do: Enum.map(keys, &struct(field, %{key: &1}))

  defp expand_keys(field), do: [field]

  @spec validate_context(Resource.t(), module()) :: Resource.t()
  defp validate_context(%Resource{schema: nil} = resource, _module), do: resource

  defp validate_context(%Resource{type: :ctx, context: nil} = resource, module) do
    raise DslError,
      module: module,
      path: [:auix_resource_metadata, resource.name],
      location: Entity.anno(resource),
      message: "context resource #{inspect(resource.name)} requires the `:context` option"
  end

  defp validate_context(resource, _module), do: resource

  @spec validate_backend_opts(Resource.t(), module()) :: Resource.t()
  defp validate_backend_opts(%Resource{} = resource, module) do
    case ContextParserDefaults.backend_opts_schema(resource.type) do
      nil ->
        resource

      schema ->
        case Spark.Options.validate(resource.backend_opts, schema) do
          {:ok, backend_opts} ->
            struct(resource, %{backend_opts: backend_opts})

          {:error, error} ->
            raise DslError,
              module: module,
              path: [:auix_resource_metadata, resource.name, :backend_opts],
              location: Entity.anno(resource),
              message: Exception.message(error)
        end
    end
  end

  ## RESOLUTION

  # The accumulated attribute lists the latest declaration first, and resolution keeps that
  # order: an association points to the latest resource declared for its schema, and a resource
  # name declared twice keeps its first declaration.

  @doc """
  Resolves the prepared resources: parses each schema, links associations and applies the
  field options.

  ## Parameters
  - `resources` (list(Resource.t())) - Prepared resources, latest declaration first.

  ## Returns
  `map()` - Resolved resources by name.
  """
  @spec resolve_resources([Resource.t()]) :: %{atom() => Resource.t()}
  def resolve_resources(resources) do
    resources
    |> add_embedded_resources()
    |> Enum.map(&parse_fields/1)
    |> then(fn parsed -> Enum.map(parsed, &resolve_fields(&1, parsed)) end)
    |> Map.new()
  end

  @spec add_embedded_resources([Resource.t()]) :: [Resource.t()]
  defp add_embedded_resources(resources) do
    resources
    |> Enum.reject(&is_nil(&1.schema))
    |> Enum.reduce(resources, fn resource, result ->
      resource.type
      |> LayoutHelpers.get_fields_parser_module()
      |> then(& &1.embedded_resource({resource.name, resource.schema, resource.type}, result))
    end)
  end

  @spec parse_fields(Resource.t()) :: {atom(), Resource.t()}
  defp parse_fields(%Resource{} = resource) do
    resource.type
    |> LayoutHelpers.get_fields_parser_module()
    |> then(& &1.parse_fields(resource.schema, resource.name))
    |> then(&{resource.name, struct(resource, %{fields: &1})})
  end

  @spec schema_type(module() | nil) :: atom()
  defp schema_type(nil), do: :default

  defp schema_type(schema) do
    functions = schema.__info__(:functions)

    cond do
      Enum.any?(functions, &(&1 == {:__spark_placeholder__, 0})) -> :ash
      Enum.any?(functions, &(&1 == {:__schema__, 1})) -> :ctx
      true -> :default
    end
  end

  # Associations are parsed against every resource, so a related resource can be found by schema.
  @spec resolve_fields({atom(), Resource.t()}, [{atom(), Resource.t()}]) :: {atom(), Resource.t()}
  defp resolve_fields({name, %Resource{schema: nil} = resource}, _resources),
    do: {name, put_fields(resource, resource.fields)}

  defp resolve_fields({name, %Resource{} = resource}, resources) do
    fields_parser = LayoutHelpers.get_fields_parser_module(resource.type)
    overrides = merge_overrides(resource.field_overrides)

    resource.schema
    |> fields_parser.parse_associations(name, resources, resource.fields)
    |> Enum.reverse()
    |> configure_many_to_one_selectors()
    |> apply_overrides(overrides)
    |> append_declared_fields(resource.field_overrides, overrides, name)
    |> then(&{name, put_fields(resource, &1)})
  end

  # Later overrides of a field win, option by option.
  @spec merge_overrides([Field.t()]) :: %{(atom() | tuple()) => Field.t()}
  defp merge_overrides(field_overrides) do
    Enum.reduce(field_overrides, %{}, fn %Field{key: key} = override, acc ->
      Map.update(acc, key, override, &Field.merge(&1, override))
    end)
  end

  @spec apply_overrides([Field.t()], map()) :: [Field.t()]
  defp apply_overrides(fields, overrides) do
    Enum.map(fields, fn field ->
      case Map.get(overrides, field.key) do
        nil -> field
        override -> Field.merge(field, override)
      end
    end)
  end

  # Fields declared but not produced by the parser are appended, in declaration order.
  @spec append_declared_fields([Field.t()], [Field.t()], map(), atom()) :: [Field.t()]
  defp append_declared_fields(fields, [], _overrides, _resource_name), do: fields

  defp append_declared_fields(fields, field_overrides, overrides, resource_name) do
    parsed_keys = Enum.map(fields, & &1.key)

    new_fields =
      field_overrides
      |> Enum.map(& &1.key)
      |> Enum.uniq()
      |> Enum.reject(&(&1 in parsed_keys))
      |> Enum.map(fn key ->
        %{key: key, resource: resource_name}
        |> Field.new()
        |> Field.merge(overrides[key])
      end)

    fields ++ new_fields
  end

  @spec configure_many_to_one_selectors([Field.t()]) :: [Field.t()]
  defp configure_many_to_one_selectors(fields) do
    fields
    |> Enum.filter(&(&1.type == :many_to_one_association))
    |> Enum.reject(&(get_in(&1, [Access.key!(:data), :resource]) == nil))
    |> Enum.map(&{&1.data.owner_key, %{html_type: :select, data: &1.data}})
    |> Enum.reduce(fields, &replace_related_field/2)
  end

  @spec replace_related_field({atom(), map()}, [Field.t()]) :: [Field.t()]
  defp replace_related_field(related_changes, fields),
    do: Enum.map(fields, &replace_related_field_data(&1, related_changes))

  @spec replace_related_field_data(Field.t(), {atom(), map()}) :: Field.t()
  defp replace_related_field_data(%{type: type} = field, _related_changes)
       when type in [
              :many_to_one_association,
              :one_to_many_association,
              :one_to_one_association,
              :many_to_many_association
            ],
       do: field

  defp replace_related_field_data(%{key: field_key, label: label} = field, {field_key, changes}) do
    label
    |> Kernel.||("")
    |> String.replace_suffix(" id", "")
    |> then(&Map.put(changes, :label, &1))
    |> then(&Field.change(field, &1))
  end

  defp replace_related_field_data(field, _related_changes), do: field

  @spec put_fields(Resource.t(), [Field.t()]) :: Resource.t()
  defp put_fields(resource, fields) do
    fields_order =
      fields
      |> Enum.reject(& &1.omitted)
      |> Enum.map(& &1.key)
      |> Enum.uniq()

    resource
    |> struct(%{fields: Map.new(fields, &{&1.key, &1}), fields_order: fields_order})
    |> Resource.resolve()
  end
end
