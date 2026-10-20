defmodule Aurora.Uix.Layout.Helpers do
  @moduledoc """
  Helper utilities for Aurora.Uix UI DSL transformations.

  Resolves the fields parser of a backend and names embedded resources.

  ## Key Features

  - Field parser resolution for different connectors
  - Embedded resource naming

  ## Key Constraints

  - Requires valid fields parser module configuration
  """

  alias Ecto.Embedded

  @fields_parser_integration_modules :aurora_uix
                                     |> Application.compile_env(
                                       :fields_parser_integration_modules,
                                       ash: Aurora.Uix.Integration.Ash.FieldsParser,
                                       ctx: Aurora.Uix.Integration.Ctx.FieldsParser,
                                       default: Aurora.Uix.Integration.Default.FieldsParser
                                     )
                                     |> Map.new()

  @doc """
  Generates a unique resource identifier for embedded fields.

  ## Parameters
  - `parent_resource_name` (atom()) - The name of the parent resource.
  - `field` (map() | atom()) - The embedded field `%Ecto.Embedded{}` or the field name.

  ## Returns
  atom() - A unique identifier for the embedded resource.
  """
  @spec field_embedded_resource(atom(), map() | atom()) :: atom()
  def field_embedded_resource(parent_resource_name, %Embedded{field: field}),
    do: field_embedded_resource(parent_resource_name, field)

  def field_embedded_resource(parent_resource_name, field) do
    String.to_atom("#{parent_resource_name}__#{field}")
  end

  @doc """
  Resolves fields parser implementation module based on connector type.

  Uses compile-time configuration map to look up the appropriate module.
  The type must match a key in @crud_integration_modules or an error is raised.

  ## Parameters
  - `type` (atom()) - The connector type (`:ash` or `:ctx`).

  ## Returns
  module() - The fields parser implementation module.

  ## Raises
  RuntimeError - If type is nil or not found in configuration.
  """
  @spec get_fields_parser_module(atom()) :: module()
  def get_fields_parser_module(nil), do: raise("The type of resource_type is nil")

  def get_fields_parser_module(type) do
    case Map.get(@fields_parser_integration_modules, type) do
      nil -> raise("Invalid fields parser module for type: #{inspect(type)}")
      crud_module -> crud_module
    end
  end
end
