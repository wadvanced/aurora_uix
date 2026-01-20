defmodule Aurora.Uix.Resource do
  @moduledoc """
  Manages comprehensive metadata configuration for schemas and their associated UI representations.

  This module provides a flexible struct and utility functions for:
  - Defining schema-specific UI configurations
  - Managing dynamic field definitions
  - Supporting complex UI generation scenarios

  Key features:
  - Supports custom field configurations
  - Allows runtime modification of schema metadata
  - Integrates with other Aurora.Uix parsing components
  """

  use Accessible

  defstruct [
    :name,
    :type,
    :schema,
    :context,
    opts: [],
    fields: [],
    fields_order: [],
    inner_elements: []
  ]

  @type t() :: %__MODULE__{
          name: atom(),
          type: atom(),
          schema: module(),
          context: module() | nil,
          opts: keyword(),
          fields: map() | list(),
          fields_order: list(),
          inner_elements: list()
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
end
