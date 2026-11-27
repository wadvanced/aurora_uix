defmodule Aurora.Uix.Filter do
  @moduledoc """
  The state of one index filter: the field, the condition and the values the user typed.

  ## Key Features

  - Conditions per field type (`conditions/1`) and the default condition (`default_condition/1`)
  - `from` and `to` hold the typed values; `to` is used by `:between`
  - `enabled?` flag

  ## Conditions

  | Atom | Description | Offered for |
  |------|-------------|-------------|
  | `:contains` | Case-insensitive substring match | text fields |
  | `:eq` | Equal to | text and other non-boolean fields |
  | `:gt` | Greater than | text and other non-boolean fields |
  | `:lt` | Less than | text and other non-boolean fields |
  | `:ge` | Greater than or equal | text and other non-boolean fields |
  | `:le` | Less than or equal | text and other non-boolean fields |
  | `:between` | Between `from` and `to` | text and other non-boolean fields |
  | `:in` | In a list of values | text and other non-boolean fields |

  A boolean field offers `nil` (any), `false` and `true`.

  ## Examples

  ```elixir
  Aurora.Uix.Filter.new(:category)
  #=> %Aurora.Uix.Filter{key: :category, condition: :eq, enabled?: false, from: nil, to: nil}

  Aurora.Uix.Filter.new(%{key: :price, condition: :between, from: 10, to: 50})
  #=> %Aurora.Uix.Filter{key: :price, condition: :between, enabled?: false, from: 10, to: 50}
  ```

  ## Key Constraints

  - `:key` and `:condition` are required
  - A binary key must name an existing atom
  """

  @conditions [
    {"equals (=)", :eq},
    {"greater than (>)", :gt},
    {"less than (<)", :lt},
    {"greater equal than (≥)", :ge},
    {"less equal than (≤)", :le},
    {"between (<o>)", :between},
    {"in list ([o])", :in}
  ]

  @text_conditions [
    {"contains (~)", :contains},
    {"equals (=)", :eq},
    {"greater than (>)", :gt},
    {"less than (<)", :lt},
    {"greater equal than (≥)", :ge},
    {"less equal than (≤)", :le},
    {"between (<o>)", :between},
    {"in list ([o])", :in}
  ]

  @text_types [:string, :binary, :bitstring]

  @boolean_conditions [
    {"-", nil},
    {"false", false},
    {"true", true}
  ]

  @enforce_keys [:key, :condition]
  defstruct [:key, :condition, enabled?: false, from: nil, to: nil]

  @type t() :: %__MODULE__{
          key: atom(),
          condition: atom(),
          enabled?: boolean(),
          from: term(),
          to: term()
        }

  @doc """
  Creates a new filter struct from various input types.

  ## Parameters

  - `attrs` (map() | atom() | binary()) - Filter configuration:
    - A map holding at least `:key` and `:condition`
    - An atom, the key of an equality filter
    - A binary naming an existing atom, converted to it

  ## Returns

  - `t()` - New filter struct with the given or default values

  ## Examples

  ```elixir
  Aurora.Uix.Filter.new("name")
  #=> %Aurora.Uix.Filter{key: :name, condition: :eq, enabled?: false, from: nil, to: nil}
  ```
  """
  @spec new(map() | atom() | binary()) :: t()
  def new(%{key: key, condition: condition} = attrs) when is_map(attrs) or is_list(attrs),
    do: struct(%__MODULE__{key: key, condition: condition}, attrs)

  def new(key) when is_binary(key), do: key |> String.to_existing_atom() |> new()
  def new(key) when is_atom(key), do: %__MODULE__{key: key, condition: :eq}

  @doc """
  Updates an existing filter with new attributes.

  ## Parameters

  - `filter` (t()) - Existing filter struct to modify
  - `attrs` (map()) - Map of attributes to update

  ## Returns

  - `t()` - Updated filter struct with merged attributes

  ## Examples

  ```elixir
  filter = Aurora.Uix.Filter.new(:status)
  Aurora.Uix.Filter.change(filter, %{condition: :in, from: "active,pending"})
  #=> %Aurora.Uix.Filter{key: :status, condition: :in, enabled?: false,
  #=>   from: "active,pending", to: nil}
  ```
  """
  @spec change(t(), map()) :: t()
  def change(filter, attrs), do: struct(filter, attrs)

  @doc """
  Returns the conditions a field offers in the filter bar.

  ## Parameters

  - `field` (map()) - Field metadata; its `:type` selects the list. Defaults to `%{}`.

  ## Returns

  - `list({binary(), atom() | boolean() | nil})` - Label and value pairs, in display order

  ## Examples

  ```elixir
  Aurora.Uix.Filter.conditions(%{type: :boolean})
  #=> [{"-", nil}, {"false", false}, {"true", true}]

  Aurora.Uix.Filter.conditions()
  #=> [{"equals (=)", :eq}, {"greater than (>)", :gt}, ..., {"in list ([o])", :in}]
  ```
  """
  @spec conditions(map()) :: list({binary(), atom() | boolean() | nil})
  def conditions(field \\ %{})
  def conditions(%{type: :boolean}), do: @boolean_conditions
  def conditions(%{type: type}) when type in @text_types, do: @text_conditions
  def conditions(_field), do: @conditions

  @doc """
  Returns the default condition for a field, based on its type.

  Text-typed fields (`:string`, `:binary`, `:bitstring`) default to `:contains`;
  every other field defaults to `:eq`.

  ## Parameters

  - `field` (map()) - Field metadata containing a `:type` key

  ## Returns

  - `atom()` - Default condition atom

  ## Examples

  ```elixir
  Aurora.Uix.Filter.default_condition(%{type: :string})
  :contains

  Aurora.Uix.Filter.default_condition(%{type: :integer})
  :eq
  ```
  """
  @spec default_condition(map()) :: atom()
  def default_condition(field \\ %{})
  def default_condition(%{type: type}) when type in @text_types, do: :contains
  def default_condition(_field), do: :eq
end
