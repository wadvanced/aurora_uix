defmodule Aurora.Uix.Field do
  @moduledoc """
  A module representing a configurable field in the Aurora.Uix system.

  This module defines a struct to represent field properties for UI components, such as:
    - `key` (`atom`) - The field reference in the schema.
    - `name` (`binary`) - The key's name as a binary.
    - `type` (`atom`) - The type of the field, it is read from the source and SHOULDN'T be change.
    - `html_type` (`binary`) - The HTML type of the field (e.g., `:text`, `:number`, `:date`).
    - `html_id` (`binary`) - A unique html id for the field.
    - `renderer` (`function`) - A custom rendering function for the field.
    - `data` (`any`) - A general purpose field.
        Template parser expect specific format for this data, according to any of the field value.
        Refer to the template documentation to learn special fields data structure.
    - `resource` (`atom`) - Used for associations, indicate the resource_config defining the meta data of the related element.
    - `label` (`binary`) - A display label for the field.
    - `placeholder` (`binary`) - Placeholder text for input fields.
    - `length` (`non_neg_integer`) - Maximum allowed length of input (used for validations).
    - `precision` (`non_neg_integer`) - Number of digits for numeric fields.
    - `scale` (`non_neg_integer`) - Number of digits to the right of the decimal separator, for numeric fields.
    - `hidden` (`boolean`) - If true the field should be included, but not visible.
      However, it is up to the implementation whether to include the field in the generated artifact or not.
    - `readonly` (`boolean`) - If true the field should not accept changes.
    - `required` (`boolean`) - Indicates that the field should not be empty or unused.
    - `disabled` (`boolean`) - If true, the field should not participate in form interaction.
    - `omitted` (`boolean`) - If true, the field won't be display nor interact with.
      It is equivalent to not having the field at all.

  ## Key Features
  - Encapsulates field properties for UI rendering and configuration.
  - Supports metadata for validation, display, and interaction in forms and tables.

  ## Key Constraints
  - Field struct is used by template and resource modules for dynamic UI generation.
  - Some fields (e.g., `data`) may require special structure as expected by template parsers.
  - Not intended for direct use outside Aurora.Uix internals.

  """

  @behaviour Access

  alias Aurora.Uix.CounterAgent

  defstruct [
    :key,
    :type,
    :html_type,
    :renderer,
    :resource,
    name: "",
    label: "",
    placeholder: "",
    length: 0,
    precision: 0,
    scale: 0,
    html_id: "",
    hidden: false,
    readonly: false,
    required: false,
    disabled: false,
    omitted: false,
    filterable?: false,
    data: %{}
  ]

  @type t() :: %__MODULE__{
          key: atom() | nil,
          type: atom() | nil,
          html_type: atom() | binary() | nil,
          html_id: binary(),
          renderer: function() | nil,
          data: any() | nil,
          resource: module() | nil,
          name: binary(),
          label: binary(),
          placeholder: binary(),
          length: non_neg_integer(),
          precision: non_neg_integer(),
          scale: non_neg_integer(),
          hidden: boolean(),
          readonly: boolean(),
          required: boolean(),
          disabled: boolean(),
          omitted: boolean(),
          filterable?: boolean()
        }

  @doc """
  Creates a new `Aurora.Uix.Field` struct with the given attributes.

  ## Parameters
  - `attrs` (map() | keyword()) - Initial attributes for the field struct.

  ## Returns
  `Aurora.Uix.Field.t()` - New key struct with derived name and html_id.

  ## Examples
  ```elixir
  Aurora.Uix.Field.new(%{key: :user_name, label: "User"})
  # => %Aurora.Uix.Field{key: :user_name, name: "user_name", label: "User", ...}
  ```
  """
  @spec new(map() | keyword()) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

  @doc """
  Updates an existing `Aurora.Uix.Field` struct with new attributes.

  ## Parameters
  - `field` (`Aurora.Uix.Field.t()`) - The existing field struct.
  - `attrs` (map() | keyword()) - Attributes to update in the struct.

  ## Returns
  `Aurora.Uix.Field.t()` - Updated field struct with new name/html_id if field changes.

  ## Examples
  ```elixir
  field = Aurora.Uix.Field.new(%{field: :email})
  Aurora.Uix.Field.change(field, %{label: "Email Address"})
  # => %Aurora.Uix.Field{field: :email, label: "Email Address", ...}
  ```
  """
  @spec change(__MODULE__.t(), map() | keyword()) :: __MODULE__.t()
  def change(field, attrs) when is_list(attrs) do
    keys = Map.keys(%__MODULE__{})

    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&struct(field, &1))
    |> update_name()
    |> set_field_id()
  end

  def change(field, %{} = attrs), do: field |> struct(attrs) |> update_name()

  @doc """
  Generates or returns a unique HTML ID for a field.

  ## Parameters
  - `field` (`Aurora.Uix.Field.t()`) - The field struct requiring an ID.

  ## Returns
  `Aurora.Uix.Field.t()` - Field with updated html_id if empty, or unchanged if ID exists.

  ## Examples
  ```elixir
  field = Aurora.Uix.Field.new(%{key: :foo})
  Aurora.Uix.Field.set_field_id(field)
  # => %Aurora.Uix.Field{html_id: "auix-field-foo-1", ...}
  ```
  """
  @spec set_field_id(__MODULE__.t()) :: __MODULE__.t()
  def set_field_id(%__MODULE__{key: key} = field) when is_nil(key), do: field

  def set_field_id(%__MODULE__{html_id: "", key: key, resource: resource} = field)
      when is_nil(resource) do
    struct(field, %{html_id: "auix-field-#{key}-#{CounterAgent.next_count(:auix_fields)}"})
  end

  def set_field_id(%__MODULE__{html_id: "", key: key, resource: resource} = field) do
    struct(field, %{
      html_id: "auix-field-#{resource}-#{key}-#{CounterAgent.next_count(:auix_fields)}"
    })
  end

  def set_field_id(field), do: field

  @doc """
  Implements `Access.fetch/2` for the field struct.
  """
  @impl Access
  @spec fetch(__MODULE__.t(), atom()) :: any()
  def fetch(field, key) do
    Map.get(field, key)
  end

  @doc """
  Implements `Access.get_and_update/3` for the field struct.
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
  Implements `Access.pop/2` for the field struct.
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
  @spec update_name(__MODULE__.t()) :: __MODULE__.t()
  defp update_name(%{key: key} = field_struct) when is_atom(key),
    do: field_struct |> struct(%{name: to_string(key)}) |> set_field_id()

  defp update_name(%{key: {parent, field}} = field_struct),
    do: field_struct |> struct(%{name: "#{parent} #{field}"}) |> set_field_id()

  @spec maybe_update_data(map(), term(), tuple()) :: tuple()
  defp maybe_update_data(data, key, {current_value, new_value}) do
    {current_value, Map.put(data, key, new_value)}
  end

  defp maybe_update_data(data, key, :pop) do
    {Map.get(data, key), Map.delete(data, key)}
  end
end
