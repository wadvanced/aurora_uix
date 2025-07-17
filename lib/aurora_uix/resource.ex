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
  @behaviour Access

  alias Aurora.Uix.Field

  defstruct [:name, :schema, :context, opts: [], fields: [], fields_order: [], inner_elements: []]

  @type t() :: %__MODULE__{
          name: atom(),
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
    |> then(&struct(resource_config, &1))
    ## changes the fields values with fields attributes
    |> change_fields(attrs)
    |> add_fields(attrs)
  end

  def change(resource_config, %{} = attrs), do: struct(resource_config, attrs)

  @doc """
  Implements `Access.fetch/2` for the resource struct.
  """
  @impl Access
  @spec fetch(__MODULE__.t(), atom()) :: any()
  def fetch(resource, key) do
    Map.get(resource, key)
  end

  @doc """
  Implements `Access.get_and_update/3` for the resource struct.
  """
  @impl Access
  @spec get_and_update(map(), atom(), (any() -> {any(), any()} | :pop)) :: {any(), map()}
  def get_and_update(data, key, function) do
    data
    |> Map.get(key)
    |> then(fn value -> function.(value) end)
    |> then(&maybe_update_data(data, key, &1))
  end

  @doc """
  Implements `Access.pop/2` for the resource struct.
  """
  @impl Access
  @spec pop(map(), atom()) :: {any(), map()}
  def pop(data, key) do
    if Map.has_key?(data, key) do
      {Map.get(data, key), Map.delete(data, key)}
    else
      {nil, data}
    end
  end

  ## PRIVATE

  # Updates fields in the resource config with provided changes
  @spec change_fields(__MODULE__.t(), list()) :: __MODULE__.t()
  defp change_fields(%{fields: resource_config_fields} = resource_config, attrs)
       when is_list(attrs) do
    changed_fields =
      attrs
      |> filter(:fields)
      |> List.last()
      |> elem(1)

    schema_config_changed_fields =
      Enum.map(resource_config_fields, &change_field(&1, changed_fields))

    struct(resource_config, %{fields: schema_config_changed_fields})
  end

  defp change_fields(resource_config, _attrs),
    do: resource_config

  # Updates a single field with provided changes
  @spec change_field(map(), list() | map()) :: map()
  defp change_field(%{field: field_id} = resource_config_field, changed_fields)
       when is_list(changed_fields) or is_map(changed_fields) do
    changed_fields
    |> Enum.filter(fn
      {^field_id, _} -> true
      _ -> false
    end)
    |> Enum.reduce(resource_config_field, fn {_field, value}, acc -> struct(acc, value) end)
  end

  defp change_field(resource_config_field, _changed_fields), do: resource_config_field

  # Adds new fields to the resource config that don't already exist
  @spec add_fields(__MODULE__.t(), list()) :: __MODULE__.t()
  defp add_fields(%{fields: resource_config_fields} = resource_config, attrs) do
    keys = Enum.map(resource_config_fields, & &1.key)

    resource_config_fields = Enum.reverse(resource_config_fields)

    attrs
    |> filter(:fields)
    |> List.last()
    |> elem(1)
    |> Enum.reject(fn
      field_properties when is_map(field_properties) -> Map.get(field_properties, :key) in keys
      field_properties when is_tuple(field_properties) -> elem(field_properties, 0) in keys
      _ -> true
    end)
    |> Enum.reduce(resource_config_fields, &create_field/2)
    |> Enum.reverse()
    |> then(&struct(resource_config, %{fields: &1}))
  end

  # Creates a new field from a tuple or map specification
  @spec create_field(tuple() | map(), list()) :: list()
  defp create_field({key, properties}, acc) do
    new_field =
      properties
      |> Map.put(:key, key)
      |> Field.new()

    [new_field | acc]
  end

  defp create_field(%Field{} = field, acc), do: [field | acc]

  defp create_field(%{key: _key} = attrs, _acc),
    do: Field.new(attrs)

  defp create_field(_field, acc), do: acc

  # Filters attributes list by key
  @spec filter(list(), atom()) :: list()
  defp filter(attrs, key) do
    Enum.filter(attrs, fn
      {^key, _} -> true
      _ -> false
    end)
  end

  @spec maybe_update_data(map(), term(), tuple()) :: tuple()
  defp maybe_update_data(data, key, {current_value, new_value}) do
    {current_value, Map.put(data, key, new_value)}
  end

  defp maybe_update_data(data, key, :pop) do
    {Map.get(data, key), Map.delete(data, key)}
  end
end
