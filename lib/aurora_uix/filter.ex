defmodule Aurora.Uix.Filter do
  @moduledoc """
  Provides a structured filter representation for query conditions with support for
  multiple comparison operators, value storage, and type-safe construction.

  ## Key Features

  - Multiple comparison operators (equality, range, set membership)
  - Type-safe construction with enforced keys
  - Flexible value storage in list format
  - Support for enabled/disabled state management

  ## Supported Operators

  | Symbol | Atom | Description |
  |--------|------|-------------|
  | `=` | `:eq` | Equal to |
  | `>` | `:gt` | Greater than |
  | `<` | `:lt` | Less than |
  | `≥` | `:ge` | Greater than or equal |
  | `≤` | `:le` | Less than or equal |
  | `b` | `:between` | Between two values |
  | `i` | `:in` | In a set of values |

  ## Examples

  ```elixir
  # Creating a basic equality filter
  filter = Aurora.Uix.Filter.new(:user_id)
  %Aurora.Uix.Filter{key: :user_id, condition: :eq, enabled?: false, values: [nil]}

  # Creating with custom attributes
  filter = Aurora.Uix.Filter.new(%{
    key: :age,
    condition: :gt,
    values: [18],
    enabled?: true
  })
  %Aurora.Uix.Filter{key: :age, condition: :gt, enabled?: true, values: [18]}

  # Creating from string key
  Aurora.Uix.Filter.new("status")
  %Aurora.Uix.Filter{key: :status, condition: :eq, enabled?: false, values: [nil]}
  ```

  ## Constraints

  - `:key` must be an atom (enforced at struct creation)
  - `:condition` must be one of the supported operators
  - `:values` are always stored in a list, even for single-value conditions
  - `:enabled?` defaults to `false` for new filters
  """

  @conditions [
    {"=", :eq},
    {">", :gt},
    {"<", :lt},
    {"≥", :ge},
    {"≤", :le},
    {"<>", :between},
    {"[]", :in}
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

  - `attrs` (map() | atom() | String.t()) - Filter configuration where:
    - Map must contain `:key` (atom) and `:condition` (atom)
    - Atom creates equality filter for that key
    - String converts to atom and creates equality filter

  ## Returns

  - `t()` - New filter struct with provided or default values

  ## Examples

  ```elixir
  # From map with all attributes
  Aurora.Uix.Filter.new(%{key: :price, condition: :between, values: [10, 50]})
  %Aurora.Uix.Filter{key: :price, condition: :between, enabled?: false, values: [10, 50]}

  # From atom key (defaults to equality)
  Aurora.Uix.Filter.new(:category)
  %Aurora.Uix.Filter{key: :category, condition: :eq, enabled?: false, values: [nil]}

  # From string key
  Aurora.Uix.Filter.new("created_at")
  %Aurora.Uix.Filter{key: :created_at, condition: :eq, enabled?: false, values: [nil]}
  ```
  """
  @spec new(map() | atom() | String.t()) :: t()
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
  Aurora.Uix.Filter.change(filter, %{condition: :in, values: ["active", "pending"]})
  %Aurora.Uix.Filter{
    key: :status,
    condition: :in,
    enabled?: false,
    values: ["active", "pending"]
  }
  ```
  """
  @spec change(t(), map()) :: t()
  def change(filter, attrs), do: struct(filter, attrs)

  @doc """
  Returns the supported condition mappings.

  Each tuple contains a human-readable symbol and its corresponding internal
  atom representation used in filter conditions.

  ## Returns

  - `list({String.t(), atom()})` - Ordered list of condition mappings

  ## Examples

  ```elixir
  Aurora.Uix.Filter.conditions()
  [
    {"=", :eq},
    {">", :gt},
    {"<", :lt},
    {"≥", :ge},
    {"≤", :le},
    {"b", :between},
    {"i", :in}
  ]
  ```
  """
  @spec conditions() :: list({String.t(), atom()})
  def conditions, do: @conditions
end
