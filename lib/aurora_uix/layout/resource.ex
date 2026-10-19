defmodule Aurora.Uix.Layout.Resource do
  @moduledoc """
  A resource as the host declares it with `auix_resource_metadata`, before its schema is parsed.

  `Aurora.Uix.Layout.ResourceResolver` turns a list of these into the resolved
  `Aurora.Uix.Resource` structs that the layouts and templates consume.

  - `name` (`atom`) - The resource identifier, e.g. `:product`.
  - `schema` (`module`) - Ecto schema or Ash resource (`:schema` or `:ash_resource` option).
  - `context` (`module`) - Context module of an Ecto resource.
  - `type` (`atom`) - Backend override (`:ctx`, `:ash` or a custom backend). `nil` detects it from
    the schema.
  - `order_by` - Order of the index entries, in `Ecto.Query.order_by/3` form.
  - `renderers` (`map`) - `html_type => renderer` table for every field of the resource.
  - `display_name` (`binary` | `function`) - The `:name` option: the resource's display name.
  - `title` (`binary` | `function`) - The `:title` option: the resource's display title.
  - `backend_opts` (`keyword`) - Options owned by the backend, such as Ash's `:ash_actor_assign`
    and action names, or a context's CRUD function overrides. They are read only by the
    backend's context parser defaults.
  - `fields` (`list`) - The `field` overrides, in declaration order.

  ## Key Features
  - Holds each resource option in its own key; only backend-owned options share a keyword list.
  - Keeps field overrides as `Aurora.Uix.Layout.Resource.FieldOverride` structs in declaration
    order, so later overrides of the same field win.

  ## Key Constraints
  - Carries no parsed schema information; that is added during resolution.
  """

  alias Aurora.Uix.Layout.Resource.FieldOverride

  @generic_options [:schema, :ash_resource, :context, :type, :order_by, :renderers, :name, :title]

  defstruct [
    :name,
    :schema,
    :context,
    :type,
    :order_by,
    :display_name,
    :title,
    renderers: %{},
    backend_opts: [],
    fields: []
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
          fields: [FieldOverride.t()]
        }

  @doc """
  Builds a declared resource from the options and field overrides of `auix_resource_metadata`.

  ## Parameters
  - `name` (atom()) - The resource identifier.
  - `opts` (keyword()) - The resource options. `:schema` and `:ash_resource` both set `schema`,
    `:name` sets `display_name`, and options not owned by the resource go to `backend_opts`.
  - `fields` (list(FieldOverride.t())) - The field overrides, in declaration order.

  ## Returns
  `Aurora.Uix.Layout.Resource.t()` - The declared resource.

  ## Examples
  ```elixir
  Aurora.Uix.Layout.Resource.new(:author, [ash_resource: Author, ash_actor_assign: :user], [])
  # => %Aurora.Uix.Layout.Resource{name: :author, schema: Author,
  #      backend_opts: [ash_actor_assign: :user], ...}
  ```
  """
  @spec new(atom(), keyword(), [FieldOverride.t()]) :: t()
  def new(name, opts, fields) do
    {generic, backend_opts} = Keyword.split(opts, @generic_options)

    %__MODULE__{
      name: name,
      schema: generic[:schema] || generic[:ash_resource],
      context: generic[:context],
      type: generic[:type],
      order_by: generic[:order_by],
      display_name: generic[:name],
      title: generic[:title],
      renderers: Keyword.get(generic, :renderers, %{}),
      backend_opts: backend_opts,
      fields: fields
    }
  end
end
