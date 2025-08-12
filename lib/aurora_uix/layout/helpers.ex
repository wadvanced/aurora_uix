defmodule Aurora.Uix.Layout.Helpers do
  @moduledoc """
  Provides helper utilities for Aurora.Uix UI DSL, supporting DSL block processing
  and component state management for dynamic UI generation.

  This module serves as the core processing engine for DSL block transformations,
  component registration, and field metadata extraction. It handles the conversion
  of macro-based UI definitions into standardized component structures suitable
  for template generation.

  ## Key Features

  - **DSL Block Processing**: Normalizes and transforms quoted blocks into lists of
    expressions for template processing
  - **Component Registration**: Converts DSL macro calls into standardized component
    entries with consistent structure
  - **Field Metadata Generation**: Automatically generates comprehensive field
    configurations from Elixir types and associations
  - **Type Mapping**: Provides intelligent mapping from Elixir types to HTML5 input
    types and field attributes

  ## Constraints

  - Block processing assumes well-formed quoted expressions
  - Field generation is optimized for Ecto schema integration
  - Association handling supports only `:one` and `:many` cardinalities
  - HTML type mapping follows HTML5 input specifications
  """

  alias Aurora.Uix.Action
  alias Aurora.Uix.Field

  require Logger

  @one_to_many_action_names :one_to_many |> Action.available_actions() |> Map.keys()

  @doc """
  Extracts the `:do` block from options while preserving remaining options.

  This function handles multiple input patterns for block extraction, supporting both
  keyword lists with `:do` keys and explicit block parameters. It's designed to work
  with Elixir's macro system where blocks can be passed in various formats.

  ## Parameters

  - `opts` (`keyword() | list()`) - Options list that may contain a `:do` key
  - `block` (`term()`) - Optional explicit block value, defaults to `nil`

  ## Returns

  `{term(), keyword()}` - Tuple containing the extracted block and remaining options
  """
  @spec extract_block_options(keyword() | list(), term()) :: {term(), keyword()}
  def extract_block_options(opts, block \\ nil)

  def extract_block_options(opts, nil) do
    Keyword.pop(opts, :do, [])
  end

  def extract_block_options(opts, do: block) do
    {block, opts}
  end

  def extract_block_options([], block) when is_tuple(block) do
    {block, []}
  end

  def extract_block_options([], shifted_options) do
    {[], shifted_options}
  end

  def extract_block_options(opts, block) do
    block
    |> extract_block()
    |> then(&{&1, opts})
  end

  @doc """
  Normalizes quoted blocks into a list of quoted expressions for template processing.

  Handles both single expressions and block expressions (`{:__block__, _, _}`),
  ensuring consistent output format for template generation. Each element is
  wrapped in a quote to preserve proper evaluation context.

  ## Parameters

  - `block` (`Macro.t()`) - Input block to be normalized, can be a single expression
    or a block expression

  ## Returns

  `list(Macro.t())` - List of normalized quoted expressions ready for template rendering
  """
  @spec prepare_block(Macro.t()) :: list(Macro.t())
  def prepare_block(block) do
    blocks =
      case block do
        {:__block__, _, separated_blocks} -> separated_blocks
        single_block -> [single_block]
      end

    blocks
    |> Enum.map(&quote(do: unquote(&1)))
    |> reduce_blocks()
  end

  @doc """
  Transforms DSL macro calls into standardized component entries for template generation.

  Creates a comprehensive component map containing all necessary information for
  rendering, including tag type, configuration, options, and nested elements.
  Handles special field configurations and preserves component hierarchy.

  ## Parameters

  - `tag` (`atom()`) - Component type identifier (e.g., `:form`, `:field`, `:section`)
  - `name` (`atom()`) - Component name for identification and reference
  - `config` (`keyword() | tuple() | nil`) - Static configuration or field definitions
  - `opts` (`keyword()`) - Component options and attributes
  - `do_block` (`Macro.t()`) - Nested component definitions and content
  - `env` (`Macro.Env.t()`) - Macro environment for proper code generation

  ## Returns

  `Macro.t()` - Quoted expression that evaluates to a standardized component map
  """
  @spec register_dsl_entry(
          atom(),
          atom(),
          keyword() | tuple() | nil,
          keyword(),
          Macro.t(),
          Macro.Env.t()
        ) :: Macro.t()
  def register_dsl_entry(tag, name, config, opts, do_block, env) do
    {block, opts} = extract_block_options(opts, do_block)

    inner_elements =
      case config do
        {:fields, fields} ->
          fields
          |> Enum.map(&create_field_tag(&1, env))
          |> Macro.escape()

        _other ->
          []
      end

    config = if inner_elements == [], do: config, else: []

    registration =
      quote do
        %{
          tag: unquote(tag),
          name: unquote(name),
          opts: unquote(opts),
          config: unquote(config),
          inner_elements: unquote(prepare_block(block)) ++ unquote(inner_elements)
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end

    quote do
      unquote(registration)
    end
  end

  @doc """
  Parses field metadata from Elixir type and association information.

  Generates comprehensive field configuration including display attributes,
  HTML input types, validation constraints, and association metadata. This
  function is the core of field introspection for form generation.

  ## Parameters

  - `field_key` (`atom()`) - The field identifier/name
  - `type` (`atom()`) - Elixir type (e.g., `:string`, `:integer`, `:boolean`)
  - `resource_name` (`atom()`) - Name of the resource this field belongs to
  - `association` (`map() | nil`) - Association metadata with cardinality information

  ## Returns

  `Field.t()` - Fully configured field struct with all metadata
  """
  @spec parse_field(atom(), atom(), atom(), map() | nil) :: Field.t()
  def parse_field(field_key, type, resource_name, association \\ nil) do
    attrs = %{
      key: field_key,
      label: field_label(field_key),
      placeholder: field_placeholder(field_key, type),
      type: field_type(type, association),
      html_type: field_html_type(type, association),
      length: field_length(type),
      precision: field_precision(type),
      scale: field_scale(type),
      disabled: field_disabled(field_key),
      omitted: field_omitted(field_key),
      hidden: field_hidden(field_key),
      filterable?: field_filterable(type),
      resource: resource_name,
      data: field_data(association)
    }

    Field.new(attrs)
  end

  @doc """
  Formats a display label from a field name.

  Converts atom field names to human-readable labels by capitalizing the first
  letter and replacing underscores with spaces.

  ## Parameters

  - `name` (`atom() | nil`) - Field name to format

  ## Returns

  `binary()` - Formatted display label
  """
  @spec field_label(atom() | nil) :: binary()
  def field_label(nil), do: ""

  def field_label(name),
    do: name |> to_string() |> String.replace("_", " ") |> String.capitalize()

  @doc """
  Determines default placeholder text for a field based on its type.

  Provides contextually appropriate placeholder text that helps users understand
  the expected input format, especially for temporal and numeric types.

  ## Parameters

  - `name` (`atom()`) - Field name (used as fallback for text fields)
  - `type` (`atom()`) - Elixir type determining placeholder format

  ## Returns

  `binary()` - Default placeholder text
  """
  @spec field_placeholder(atom(), atom()) :: binary()
  def field_placeholder(_, type) when type in [:id, :integer, :float, :decimal], do: "0"

  def field_placeholder(_, type)
      when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
      do: "yyyy/MM/dd HH:mm:ss"

  def field_placeholder(_, type) when type in [:time, :time_usec], do: "HH:mm:ss"
  def field_placeholder(name, _type), do: name |> to_string() |> String.capitalize()

  @doc """
  Maps an Elixir type to a field type, handling associations.

  Determines the appropriate field type for UI rendering, with special handling
  for association fields that require different treatment than scalar types.

  ## Parameters

  - `type` (`atom()`) - Base Elixir type
  - `association` (`map() | nil`) - Association metadata with cardinality info

  ## Returns

  `atom()` - Mapped field type for UI rendering
  """
  @spec field_type(atom(), map() | nil) :: atom()
  def field_type(type, nil), do: type

  def field_type(nil, %{cardinality: :many} = _association), do: :one_to_many_association

  def field_type(nil, %{cardinality: :one} = _association),
    do: :many_to_one_association

  @doc """
  Maps an Elixir type to an HTML input type.

  Provides appropriate HTML5 input types based on data type, enabling proper
  browser validation and input handling. Handles both scalar types and associations.

  ## Parameters

  - `type` (`atom()`) - Elixir type to map
  - `association` (`map() | nil`) - Association metadata for relationship fields

  ## Returns

  `atom()` - HTML5 input type
  """
  @spec field_html_type(atom(), map() | nil) :: atom()
  def field_html_type(type, _association)
      when type in [:string, :binary_id, :binary, :bitstring, Ecto.UUID],
      do: :text

  def field_html_type(type, _association) when type in [:id, :integer, :float, :decimal],
    do: :number

  def field_html_type(type, _association)
      when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
      do: :"datetime-local"

  def field_html_type(type, _association) when type in [:time, :time_usec], do: :time

  def field_html_type(:boolean, _association), do: :checkbox

  def field_html_type(type, nil), do: type

  def field_html_type(nil, %{cardinality: :many} = _association), do: :one_to_many_association

  def field_html_type(nil, %{cardinality: :one} = _association),
    do: :many_to_one_association

  def field_html_type(nil, _association), do: :unimplemented

  @doc """
  Determines display length for a field based on its type.

  Sets sensible default length constraints that work well for most UI scenarios,
  considering typical data ranges for each type.

  ## Parameters

  - `type` (`atom()`) - Elixir type to determine length for

  ## Returns

  `integer()` - Suggested display length in characters
  """
  @spec field_length(atom()) :: integer()
  def field_length(type) when type in [:string, :binary_id, :binary, :bitstring], do: 255
  def field_length(type) when type in [:id, :integer], do: 10
  def field_length(type) when type in [:float, :decimal], do: 12

  def field_length(type)
      when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
      do: 20

  def field_length(type) when type in [:time, :time_usec], do: 10
  def field_length(Ecto.UUID), do: 34
  def field_length(:boolean), do: 5
  def field_length(_type), do: 50

  @doc """
  Gets numeric precision for number fields.

  Returns the total number of significant digits for numeric types,
  with zero for non-numeric fields.

  ## Parameters

  - `type` (`atom()`) - Field type to check

  ## Returns

  `integer()` - Numeric precision, 0 for non-numeric types
  """
  @spec field_precision(atom()) :: integer()
  def field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  def field_precision(_type), do: 0

  @doc """
  Gets numeric scale for decimal/float fields.

  Returns the number of digits after the decimal point,
  with zero for non-decimal types.

  ## Parameters

  - `type` (`atom()`) - Field type to check

  ## Returns

  `integer()` - Numeric scale, 0 for non-decimal types
  """
  @spec field_scale(atom()) :: integer()
  def field_scale(type) when type in [:float, :decimal], do: 2
  def field_scale(_type), do: 0

  @doc """
  Checks if a field should be disabled by default.

  Certain fields like primary keys and system fields are typically
  not editable by users and should be disabled in forms.

  ## Parameters

  - `key` (`atom()`) - Field key to check

  ## Returns

  `boolean()` - `true` if field should be disabled
  """
  @spec field_disabled(atom()) :: boolean()
  def field_disabled(key) when key in [:id, :deleted, :inactive],
    do: true

  def field_disabled(_field), do: false

  @doc """
  Checks if a field should be omitted from forms.

  System-managed fields like timestamps are usually not included
  in user-facing forms as they're automatically managed.

  ## Parameters

  - `key` (`atom()`) - Field key to check

  ## Returns

  `boolean()` - `true` if field should be omitted
  """
  @spec field_omitted(atom()) :: boolean()
  def field_omitted(key) when key in [:inserted_at, :updated_at],
    do: true

  def field_omitted(_field), do: false

  @doc """
  Determines if a field should be hidden from display.

  Currently returns `false` for all fields, but provides extension point
  for conditional field visibility logic.

  ## Parameters

  - `field` (`atom()`) - Field key to check

  ## Returns

  `boolean()` - `true` if field should be hidden
  """
  @spec field_hidden(atom()) :: boolean()
  def field_hidden(_field), do: false

  @doc """
  Determines if a field should be filterable in queries.

  Currently returns `true` for all field types, enabling filtering
  across all data types in the UI.

  ## Parameters

  - `type` (`atom()`) - Field type to check

  ## Returns

  `boolean()` - `true` if field supports filtering
  """
  @spec field_filterable(atom()) :: boolean()
  def field_filterable(_type), do: true

  @doc """
  Extracts metadata for association fields.

  Builds a metadata map containing relationship information needed
  for proper association handling in forms and queries.

  ## Parameters

  - `association` (`map() | nil`) - Association struct from Ecto schema

  ## Returns

  `map()` - Association metadata map, empty map if no association
  """
  @spec field_data(map() | nil) :: map()
  def field_data(nil), do: %{}

  def field_data(association),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  ## PRIVATE

  # Normalizes block structure by removing empty blocks and preserving non-empty ones.
  # Used in block preparation for HEEX template generation to clean up the AST.
  @spec reduce_blocks(list(Macro.t())) :: list(Macro.t())
  defp reduce_blocks([[]]), do: []
  defp reduce_blocks(blocks), do: blocks

  # Extracts block content from either a keyword list with :do key or direct block.
  # Used to handle both inline and do-block syntax in DSL macros, providing
  # flexibility in how blocks can be specified.
  @spec extract_block(keyword() | Macro.t() | list() | nil) :: Macro.t()
  defp extract_block(nil), do: []
  defp extract_block(do: block), do: block
  defp extract_block(block), do: block

  # Creates a standardized field tag structure from various field specifications.
  # Handles atom fields, tuple fields, and fields with options to provide consistent
  # field representation for the DSL system.
  @spec create_field_tag(atom() | {atom(), keyword()}, Macro.Env.t()) :: map()
  defp create_field_tag(field, _env) when is_atom(field) do
    %{tag: :field, name: field, config: [], inner_elements: []}
  end

  defp create_field_tag({field_name, opts} = _field, env) when is_list(opts) do
    opts
    |> Enum.map(&process_field_tag_option(&1, env))
    |> then(&%{tag: :field, name: field_name, opts: &1, config: [], inner_elements: []})
  end

  defp create_field_tag(field, _env) when is_tuple(field) do
    %{tag: :field, name: field, config: [], inner_elements: []}
  end

  defp create_field_tag({field_name, opts}, _env) do
    %{tag: :field, name: field_name, config: opts, inner_elements: []}
  end

  # Processes field tag options with special handling for function components and
  # quoted expressions. Evaluates complex options at compile time for performance.
  @spec process_field_tag_option({atom(), term()}, Macro.Env.t()) :: {atom(), term()}
  defp process_field_tag_option({action_name, {action_key, {:&, _, _} = function_component}}, env)
       when action_name in @one_to_many_action_names do
    env
    |> Code.env_for_eval()
    |> then(&Code.eval_quoted_with_env(function_component, [], &1))
    |> elem(0)
    |> then(&{action_name, {action_key, &1}})
  end

  defp process_field_tag_option({option_key, {:{}, _, _} = quoted}, _env) do
    quoted
    |> Code.eval_quoted()
    |> elem(0)
    |> then(&{option_key, &1})
  end

  defp process_field_tag_option(option, _env), do: option
end
