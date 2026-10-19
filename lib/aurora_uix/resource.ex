defmodule Aurora.Uix.Resource do
  @moduledoc """
  A resource: what `auix_resource_metadata` declares, plus the fields its schema parser produces.

  `auix_resource_metadata` fills the declared keys and `field_overrides`;
  `Aurora.Uix.Layout.ResourceMetadata` then parses the schema into `fields` and `fields_order`.
  The generated `auix_resources/0` and `auix_resource/1` return the result.

  - `name` (`atom`) - The resource identifier, e.g. `:product`.
  - `schema` (`module`) - Ecto schema or Ash resource (`:schema` or `:ash_resource` option).
  - `context` (`module`) - Context module of an Ecto resource.
  - `type` (`atom`) - The backend: `:ctx`, `:ash`, `:default` or a custom backend. Detected from
    the schema unless the `:type` option overrides it.
  - `order_by` - Order of the index entries, in `Ecto.Query.order_by/3` form.
  - `renderers` (`map`) - The `:renderers` option: an `html_type => renderer` table for every
    field of the resource.
  - `display_name` (`binary` | `function`) - The `:name` option: the resource's display name.
  - `title` (`binary` | `function`) - The `:title` option: the resource's display title.
  - `backend_opts` (`keyword`) - Options owned by the backend, such as Ash's `:ash_actor_assign`
    and action names, or a context's CRUD function overrides. Only the backend's context parser
    defaults read them.
  - `field_overrides` (`list`) - The `field` entries, as partial `Aurora.Uix.Field` structs
    (`resolved?: false`, unset options `nil`) in declaration order.
  - `fields` (`map`) - `Aurora.Uix.Field` structs by field key, with the overrides applied.
  - `fields_order` (`list`) - Field keys in display order, without omitted fields.
  - `resolved?` (`boolean`) - `false` while the resource is only declared; `true` once
    `resolve/1` has filled the defaults (`type: :ctx`) and resolved every field. Resolution
    in `Aurora.Uix.Layout.ResourceMetadata` sets it after parsing the schema.

  ## Key Features
  - Gives each resource option its own key; only backend-owned options share a keyword list.
  - `parser_opts/1` returns the options the context parsers read, in keyword form.

  ## Key Constraints
  - `fields` is always a map of `Aurora.Uix.Field` structs; overrides live only in
    `field_overrides`.
  """

  use Accessible

  alias Aurora.Uix.Field

  defstruct [
    :name,
    :schema,
    :context,
    :order_by,
    :display_name,
    :title,
    :type,
    renderers: %{},
    backend_opts: [],
    field_overrides: [],
    fields: %{},
    fields_order: [],
    resolved?: false
  ]

  @type t() :: %__MODULE__{
          name: atom(),
          schema: module() | nil,
          context: module() | nil,
          type: atom() | nil,
          order_by: term(),
          display_name: binary() | function() | nil,
          title: binary() | function() | nil,
          renderers: map(),
          backend_opts: keyword(),
          field_overrides: [Field.t()],
          fields: %{optional(atom() | tuple()) => Field.t()},
          fields_order: list(),
          resolved?: boolean()
        }

  @doc """
  Creates a new `Aurora.Uix.Resource` struct with the given attributes.

  ## Parameters
  - `attrs` (map() | `keyword()`) - Initial attributes with :name, :schema, :context, and :fields keys.

  ## Returns
  `Aurora.Uix.Resource.t()` - A new resource struct, resolved.

  ## Examples
  ```elixir
  Aurora.Uix.Resource.new(name: :user, schema: MyApp.User)
  # => %Aurora.Uix.Resource{name: :user, schema: MyApp.User, ...}
  ```
  """
  @spec new(map() | keyword()) :: __MODULE__.t()
  def new(attrs \\ %{}), do: %__MODULE__{} |> change(attrs) |> resolve()

  @doc """
  Updates an existing resource struct with the given attributes.

  ## Parameters
  - `resource_config` (`Aurora.Uix.Resource.t()`) - Existing resource struct to update.
  - `attrs` (map() | `keyword()`) - Attributes to update with :name, :schema, :context, and :fields keys.

  ## Returns
  `Aurora.Uix.Resource.t()` - Updated resource struct.

  ## Examples
  ```elixir
  resource = Aurora.Uix.Resource.new(name: :user)
  Aurora.Uix.Resource.change(resource, %{schema: MyApp.User})
  # => %Aurora.Uix.Resource{name: :user, schema: MyApp.User, ...}
  ```
  """
  @spec change(__MODULE__.t(), map() | keyword()) :: __MODULE__.t()
  def change(resource_config, attrs) when is_list(attrs) do
    keys =
      %__MODULE__{}
      |> Map.keys()
      |> Enum.reject(&(&1 == :fields))

    ## applies changes to resource_config struct
    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&change(resource_config, &1))
  end

  def change(resource_config, %{} = attrs), do: struct(resource_config, attrs)

  @doc """
  Fills the defaults of a declared resource, resolves its fields and marks it as resolved.

  ## Parameters
  - `resource` (`Aurora.Uix.Resource.t()`) - The resource to resolve.

  ## Returns
  `Aurora.Uix.Resource.t()` - The resource with `resolved?: true`. A resolved resource is
  returned as is.
  """
  @spec resolve(t()) :: t()
  def resolve(%__MODULE__{resolved?: true} = resource), do: resource

  def resolve(%__MODULE__{} = resource) do
    struct(resource, %{
      type: resource.type || :ctx,
      fields: Map.new(resource.fields, fn {key, field} -> {key, Field.resolve(field)} end),
      resolved?: true
    })
  end

  @doc """
  Returns the resource options read by the context parsers (`Aurora.Uix.Parser`).

  ## Parameters
  - `resource` (`Aurora.Uix.Resource.t()`) - The resolved resource.

  ## Returns
  `keyword()` - The backend options plus `:name` and `:title` when they were declared.

  ## Examples
  ```elixir
  Aurora.Uix.Resource.parser_opts(%Aurora.Uix.Resource{title: "Items", backend_opts: [a: 1]})
  # => [a: 1, title: "Items"]
  ```
  """
  @spec parser_opts(t()) :: keyword()
  def parser_opts(%__MODULE__{} = resource) do
    [name: resource.display_name, title: resource.title]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> then(&(resource.backend_opts ++ &1))
  end
end
