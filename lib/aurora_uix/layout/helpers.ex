defmodule Aurora.Uix.Layout.Helpers do
  @moduledoc """
  Provides helper utilities for the Aurora.Uix UI DSL.

  This module serves as the core processing engine for DSL block transformations,
  component registration, and field metadata extraction. It handles the conversion
  of macro-based UI definitions into standardized component structures suitable
  for template generation.

  ## Key Features

  - **DSL Block Processing**: Normalizes and transforms quoted blocks into lists of expressions.
  - **Component Registration**: Converts DSL macro calls into standardized component entries.
  - **Field Metadata Generation**: Automatically generates field configurations from types and associations.
  - **Type Mapping**: Maps Elixir types to HTML5 input types and field attributes.

  ## Constraints

  - Block processing assumes well-formed quoted expressions.
  - Field generation is optimized for Ecto schema integration.
  - Association handling supports only `:one` and `:many` cardinalities.
  """

  alias Aurora.Uix.Action
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.TreePath

  alias Ecto.Association.BelongsTo, as: AssociationBelongsTo
  alias Ecto.Association.Has, as: AssociationHas

  alias Ecto.Embedded

  require Logger

  @one_to_many_action_names :one_to_many |> Action.available_actions() |> Map.keys()

  @doc """
  Extracts the `:do` block from options while preserving the rest.

  This function handles multiple input patterns for block extraction, supporting both
  keyword lists with a `:do` key and explicit block parameters.

  ## Parameters
  - `opts` (`Keyword.t()` | `list()`) - An options list that may contain a `:do` key.
  - `block` (`term()`) - An optional explicit block value, which defaults to `nil`.

  ## Returns
  `{term(), Keyword.t()}` - A tuple containing the extracted block and the remaining options.
    LayoutHelpers.parse_embedded_field(embed_one, resource_name)
  """
  @spec extract_block_options(Keyword.t() | list(), term()) :: {term(), Keyword.t()}
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
  Normalizes quoted blocks into a list of quoted expressions.

  Handles both single expressions and block expressions (`{:__block__, _, _}`),
  ensuring a consistent output format for template generation.

  ## Parameters
  - `block` (`Macro.t()`) - The input block to be normalized.

  ## Returns
  `list(Macro.t())` - A list of normalized quoted expressions.
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
  Transforms DSL macro calls into standardized component entries.

  Creates a component map with all necessary information for rendering, including
  tag type, configuration, options, and nested elements.

  ## Parameters
  - `tag` (`atom()`) - The component type identifier (e.g., `:form`, `:field`).
  - `name` (`atom()`) - The component name for identification.
  - `config` (`Keyword.t()` | `tuple()` | `nil`) - Static configuration or field definitions.
  - `opts` (`Keyword.t()`) - Component options and attributes.
  - `do_block` (`Macro.t()`) - Nested component definitions and content.
  - `env` (`Macro.Env.t()`) - The macro environment for code generation.

  ## Returns
  `Macro.t()` - A quoted expression that evaluates to a component map.
  """
  @spec register_dsl_entry(
          atom(),
          atom(),
          Keyword.t() | tuple() | nil,
          Keyword.t(),
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
        %TreePath{
          tag: unquote(tag),
          name: unquote(name),
          opts: unquote(opts),
          config: unquote(config),
          inner_elements: unquote(prepare_block(block)) ++ unquote(inner_elements)
        }
      end

    quote do
      unquote(registration)
    end
  end

  @doc """
  Parses field metadata from an Elixir type and association information.

  Generates a field configuration including display attributes, HTML input types,
  validation constraints, and association metadata.

  ## Parameters
  - `field_key` (`atom()`) - The field identifier.
  - `type` (`atom()`) - The Elixir type (e.g., `:string`, `:integer`).
  - `resource_name` (`atom()`) - The name of the resource this field belongs to.
  - `association_embed` (`map()` | `nil`) - Association metadata with cardinality information.

  ## Returns
  `t:Field.t/0` - A fully configured field struct.
  """
  @spec parse_field(atom(), atom(), atom(), map() | nil) :: Field.t()
  def parse_field(field_key, type, resource_name, association_or_embed \\ nil) do
    attrs = %{
      key: field_key,
      label: field_label(field_key),
      placeholder: field_placeholder(field_key, type),
      type: field_type(type, association_or_embed),
      html_type: field_html_type(type, association_or_embed),
      length: field_length(type),
      precision: field_precision(type),
      scale: field_scale(type),
      disabled: field_disabled(field_key),
      omitted: field_omitted(field_key),
      hidden: field_hidden(field_key),
      filterable?: field_filterable(type),
      resource: resource_name,
      data: field_data(association_or_embed, resource_name)
    }

    Field.new(attrs)
  end

  @doc """
  Formats a display label from a field name.

  Converts an atom field name to a human-readable label by capitalizing it and
  replacing underscores with spaces.

  ## Parameters
  - `name` (`atom()` | `nil`) - The field name to format.

  ## Returns
  `binary()` - The formatted display label.
  """
  @spec field_label(atom() | nil) :: binary()
  def field_label(nil), do: ""

  def field_label(name),
    do: name |> to_string() |> String.replace("_", " ") |> String.capitalize()

  @doc """
  Determines the default placeholder text for a field based on its type.

  Provides contextually appropriate placeholder text to help users understand
  the expected input format.

  ## Parameters
  - `name` (`atom()`) - The field name, used as a fallback for text fields.
  - `type` (`atom()`) - The Elixir type that determines the placeholder format.

  ## Returns
  `binary()` - The default placeholder text.
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
  for association fields.

  ## Parameters
  - `type` (`atom()`) - The base Elixir type.
  - `association` (`map()` | `nil`) - Association metadata with cardinality info.

  ## Returns
  `atom()` - The mapped field type for UI rendering.
  """
  @spec field_type(atom(), map() | nil) :: atom()
  def field_type(type, nil), do: type

  def field_type(nil, %AssociationHas{cardinality: :many} = _association),
    do: :one_to_many_association

  def field_type(nil, %AssociationBelongsTo{cardinality: :one} = _association),
    do: :many_to_one_association

  def field_type(_type, %Embedded{cardinality: :one} = _embed), do: :embed_one

  @doc """
  Maps an Elixir type to an HTML input type.

  Provides appropriate HTML5 input types based on the data type, enabling proper
  browser validation and input handling.

  ## Parameters
  - `type` (`atom()`) - The Elixir type to map.
  - `association` (`map()` | `nil`) - Association metadata for relationship fields.

  ## Returns
  `atom()` - The HTML5 input type.
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

  def field_html_type(nil, %AssociationHas{cardinality: :many} = _association),
    do: :one_to_many_association

  def field_html_type(nil, %AssociationBelongsTo{cardinality: :one} = _association),
    do: :many_to_one_association

  def field_html_type(nil, %Embedded{cardinality: :one} = _embed), do: :embed_one

  def field_html_type(_type, _association), do: :unimplemented

  @doc """
  Determines the display length for a field based on its type.

  Sets sensible default length constraints that work well for most UI scenarios,
  considering typical data ranges for each type.

  ## Parameters
  - `type` (`atom()`) - The Elixir type to determine the length for.

  ## Returns
  `integer()` - The suggested display length in characters.
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
  Gets the numeric precision for number fields.

  Returns the total number of significant digits for numeric types.

  ## Parameters
  - `type` (`atom()`) - The field type to check.

  ## Returns
  `integer()` - The numeric precision, or `0` for non-numeric types.
  """
  @spec field_precision(atom()) :: integer()
  def field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  def field_precision(_type), do: 0

  @doc """
  Gets the numeric scale for decimal/float fields.

  Returns the number of digits after the decimal point.

  ## Parameters
  - `type` (`atom()`) - The field type to check.

  ## Returns
  `integer()` - The numeric scale, or `0` for non-decimal types.
  """
  @spec field_scale(atom()) :: integer()
  def field_scale(type) when type in [:float, :decimal], do: 2
  def field_scale(_type), do: 0

  @doc """
  Checks if a field should be disabled by default.

  Certain fields like primary keys and system fields are typically not editable
  by users and should be disabled in forms.

  ## Parameters
  - `key` (`atom()`) - The field key to check.

  ## Returns
  `boolean()` - `true` if the field should be disabled, otherwise `false`.
  """
  @spec field_disabled(atom()) :: boolean()
  def field_disabled(key) when key in [:id, :deleted, :inactive],
    do: true

  def field_disabled(_field), do: false

  @doc """
  Checks if a field should be omitted from forms.

  System-managed fields like timestamps are usually not included in user-facing
  forms as they are automatically managed.

  ## Parameters
  - `key` (`atom()`) - The field key to check.

  ## Returns
  `boolean()` - `true` if the field should be omitted, otherwise `false`.
  """
  @spec field_omitted(atom()) :: boolean()
  def field_omitted(key) when key in [:inserted_at, :updated_at],
    do: true

  def field_omitted(_field), do: false

  @doc """
  Determines if a field should be hidden from display.

  This function can be used to implement conditional field visibility logic.

  ## Parameters
  - `field` (`atom()`) - The field key to check.

  ## Returns
  `boolean()` - `true` if the field should be hidden, otherwise `false`.
  """
  @spec field_hidden(atom()) :: boolean()
  def field_hidden(_field), do: false

  @doc """
  Determines if a field should be filterable in queries.

  ## Parameters
  - `type` (`atom()`) - The field type to check.

  ## Returns
  `boolean()` - `true` if the field supports filtering, otherwise `false`.
  """
  @spec field_filterable(atom()) :: boolean()
  def field_filterable(_type), do: true

  @doc """
  Extracts metadata for association fields.

  Builds a metadata map containing relationship information needed for proper
  association handling in forms and queries.

  ## Parameters
  - `association` (`map()` | `nil`) - The association struct from an Ecto schema.

  ## Returns
  `map()` - An association metadata map, or an empty map if there is no association.
  """
  @spec field_data(map() | nil, atom()) :: map()
  def field_data(association_or_embed, resource_name \\ nil)

  def field_data(nil, _resource_name), do: %{}

  def field_data(%Embedded{} = embedded, resource_name) do
    %{
      related: embedded.related,
      owner: embedded.owner,
      resource: field_embedded_resource(resource_name, embedded)
    }
  end

  def field_data(%{} = association, _resource_name),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  @doc """
  Generates a unique resource identifier for embedded fields.

  ## Parameters
  - `parent_resource_name` (`atom()`) - The name of the parent resource.
  - `field` (`map()` | `atom()`) - The embedded field (%Ecto.Embedded) or the field name.

  ## Returns
  `binary()` - A unique identifier for the embedded resource.
  """
  @spec field_embedded_resource(atom(), map() | atom()) :: atom()
  def field_embedded_resource(parent_resource_name, %Embedded{field: field}),
    do: field_embedded_resource(parent_resource_name, field)

  def field_embedded_resource(parent_resource_name, field) do
    String.to_atom("#{parent_resource_name}__#{field}")
  end

  @doc """
  Creates a macro expression to store layout options in the module attributes.

  ## Parameters
  - `opts` (`Keyword.t()`) - The layout options to be stored.

  ## Returns
  `Macro.t()` - A quoted expression that, when executed, stores the options.
  """
  @spec create_layout_opts(Keyword.t()) :: Macro.t()
  def create_layout_opts(opts) do
    quote do
      LayoutHelpers.put_manual_opts(
        __MODULE__,
        Module.get_attribute(__MODULE__, :auix_layout_opts, []),
        unquote(opts)
      )
    end
  end

  @doc """
  Creates a macro expression to store layout tree paths in the module attributes.

  ## Parameters
  - `block` (`any()`) - The block containing layout definitions.
  - `env` (`Macro.Env.t()`) - The macro environment.

  ## Returns
  `Macro.t()` - A quoted expression that, when executed, stores the tree paths.
  """
  @spec create_layout(any(), Macro.Env.t()) :: Macro.t()
  def create_layout(block, env) do
    ui = register_dsl_entry(:ui, :ui, [], [], block, env)

    tree_paths =
      quote do
        Map.get(unquote(ui), :inner_elements, [])
      end

    quote do
      LayoutHelpers.put_manual_tree_paths(
        __MODULE__,
        Module.get_attribute(__MODULE__, :auix_layout_trees, []),
        unquote(tree_paths)
      )
    end
  end

  @doc """
  Stores manually configured layout options in the module attributes.

  It merges options defined via `auix_create_ui/2` with any existing options
  and stores them in the `@auix_layout_opts` attribute.

  ## Parameters
  - `module` (`module()`) - The module where the attributes are stored.
  - `define_by_module_opts` (`list()`) - The list of options already defined in the module.
  - `ui_defined` (`list()`) - The list of new options to be added.

  ## Returns
  `:ok` - Indicates that the options have been stored.
  """
  @spec put_manual_opts(module(), list(), list()) :: :ok
  def put_manual_opts(module, define_by_module_opts, ui_defined) do
    Module.delete_attribute(module, :auix_layout_opts)

    define_by_module_opts
    |> Keyword.merge(ui_defined)
    |> then(&Module.put_attribute(module, :auix_layout_opts, &1))
  end

  @doc """
  Stores manually configured layout tree paths in the module attributes.

  It merges new layout tree paths with existing ones and stores them in the
  `@auix_layout_trees` attribute, avoiding duplicates.

  ## Parameters
  - `module` (`module()`) - The module where the attributes are stored.
  - `defined_by_module_attribute` (`list()`) - The list of tree paths already defined.
  - `ui_defined` (`list()`) - The list of new tree paths to be added.

  ## Returns
  `:ok` - Indicates that the tree paths have been stored.
  """
  @spec put_manual_tree_paths(module(), list(), list()) :: :ok
  def put_manual_tree_paths(module, defined_by_module_attribute, ui_defined) do
    Module.delete_attribute(module, :auix_layout_trees)

    Enum.each(ui_defined, &Module.put_attribute(module, :auix_layout_trees, &1))

    defined_by_module_attribute
    |> List.flatten()
    |> Enum.reject(fn tree_path ->
      Enum.any?(ui_defined, &(&1.name == tree_path.name and &1.tag == tree_path.tag))
    end)
    |> Enum.each(fn tree_path ->
      Module.put_attribute(module, :auix_layout_trees, tree_path)
    end)
  end

  ## PRIVATE

  # Normalizes block structure by removing empty blocks and preserving non-empty ones.
  @spec reduce_blocks(list(Macro.t())) :: list(Macro.t())
  defp reduce_blocks([[]]), do: []
  defp reduce_blocks(blocks), do: blocks

  # Extracts block content from either a keyword list with a :do key or a direct block.
  @spec extract_block(Keyword.t() | Macro.t() | list() | nil) :: Macro.t()
  defp extract_block(nil), do: []
  defp extract_block(do: block), do: block
  defp extract_block(block), do: block

  # Creates a standardized field tag structure from various field specifications.
  @spec create_field_tag(atom() | {atom(), Keyword.t()}, Macro.Env.t()) :: map()
  defp create_field_tag(field, _env) when is_atom(field) do
    TreePath.new(%{tag: :field, name: field, config: [], inner_elements: []})
  end

  defp create_field_tag({field_name, opts} = _field, env) when is_list(opts) do
    opts
    |> Enum.map(&process_field_tag_option(&1, env))
    |> then(
      &TreePath.new(%{tag: :field, name: field_name, opts: &1, config: [], inner_elements: []})
    )
  end

  defp create_field_tag(field, _env) when is_tuple(field) do
    TreePath.new(%{tag: :field, name: field, config: [], inner_elements: []})
  end

  defp create_field_tag({field_name, opts}, _env) do
    TreePath.new(%{tag: :field, name: field_name, config: opts, inner_elements: []})
  end

  # Processes field tag options, handling function components and quoted expressions.
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
