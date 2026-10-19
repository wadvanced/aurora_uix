defmodule Aurora.Uix.Resource do
  @moduledoc """
  A resolved resource: its declaration combined with what its schema parser produced.

  Built from `Aurora.Uix.Layout.Resource` by `Aurora.Uix.Layout.ResourceResolver`, and returned
  by the generated `auix_resources/0` and `auix_resource/1`.

  - `name`, `schema`, `context`, `order_by`, `renderers`, `display_name`, `title` and
    `backend_opts` - As declared; see `Aurora.Uix.Layout.Resource`.
  - `type` (`atom`) - The backend: `:ctx`, `:ash`, `:default` or a custom backend.
  - `fields` (`map`) - `Aurora.Uix.Field` structs by field key.
  - `fields_order` (`list`) - Field keys in display order, without omitted fields.

  ## Key Features
  - Gives each resource option its own key.
  - `parser_opts/1` returns the options the context parsers read, in keyword form.

  ## Key Constraints
  - `fields` is always a map and `fields_order` always a list once resolved.
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
    type: :ctx,
    renderers: %{},
    backend_opts: [],
    fields: %{},
    fields_order: []
  ]

  @type t() :: %__MODULE__{
          name: atom(),
          schema: module() | nil,
          context: module() | nil,
          type: atom(),
          order_by: term(),
          display_name: binary() | function() | nil,
          title: binary() | function() | nil,
          renderers: map(),
          backend_opts: keyword(),
          fields: %{optional(atom() | tuple()) => Field.t()},
          fields_order: list()
        }

  @doc """
  Creates a new `Aurora.Uix.Resource` struct with the given attributes.

  ## Parameters
  - `attrs` (map() | `keyword()`) - Initial attributes with :name, :schema, :context, and :fields keys.

  ## Returns
  `Aurora.Uix.Resource.t()` - A new resource struct.

  ## Examples
  ```elixir
  Aurora.Uix.Resource.new(name: :user, schema: MyApp.User)
  # => %Aurora.Uix.Resource{name: :user, schema: MyApp.User, ...}
  ```
  """
  @spec new(map() | keyword()) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

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
