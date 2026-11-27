defmodule Aurora.Uix.Integration.Default.FieldsParser do
  @moduledoc """
  Fields parser of the `:default` backend, used by a resource that has no schema or whose schema
  is neither an Ecto schema nor an Ash resource.

  ## Key Features

  - Parses no fields: the resource holds only the fields its `field` entries declare
  - Adds no association and no embedded resource

  ## Key Constraints

  - Reads nothing from the schema
  """

  alias Aurora.Uix.Field
  alias Aurora.Uix.Resource

  @doc """
  Parses the fields of a schema: none for this backend.

  ## Parameters

  - `schema` (module() | nil) - Not read.
  - `resource_name` (atom()) - Not read.

  ## Returns

  list(Field.t()) - An empty list.
  """
  @spec parse_fields(module() | nil, atom()) :: list(Field.t())
  def parse_fields(_module, _resource_name), do: []

  @doc """
  Adds the associations of a schema: none for this backend.

  ## Parameters

  - `resource_schema` (module()) - Not read.
  - `resource_name` (atom()) - Not read.
  - `resources` (list(Resource.t())) - Not read.
  - `fields` (list(Field.t())) - The declared fields.

  ## Returns

  list(Field.t()) - The fields, unchanged.
  """
  @spec parse_associations(module(), atom(), list(Resource.t()), list(Field.t())) ::
          list(Field.t())
  def parse_associations(_resource_schema, _resource_name, _resources, fields), do: fields

  @doc """
  Adds the embedded resources of a schema: none for this backend.

  ## Parameters

  - `parent_resource` ({atom(), module(), atom()}) - Not read.
  - `result` (list(Resource.t())) - The resources so far.

  ## Returns

  list(Resource.t()) - The resources, unchanged.
  """
  @spec embedded_resource({atom(), module(), atom()}, list(Resource.t())) :: list(Resource.t())
  def embedded_resource(_parent_resource, result), do: result

  @doc """
  Tells whether a schema is embedded-only. A schema of an unknown backend never is.

  ## Parameters

  - `schema` (module()) - The schema module of a resource.

  ## Returns

  boolean() - Always `false`.
  """
  @spec embedded_schema?(module()) :: boolean()
  def embedded_schema?(_schema), do: false
end
