defmodule Aurora.Uix.Layout.Helpers do
  @moduledoc """
  Provides helper utilities for the Aurora.Uix UI DSL.

  Serves as the core processing engine for DSL block transformations, component registration,
  and field metadata extraction. Handles the conversion of macro-based UI definitions into
  standardized component structures suitable for template generation.
  """

  alias Aurora.Uix.Action
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.TreePath

  alias Ecto.Embedded

  require Logger

  @one_to_many_action_names :one_to_many |> Action.available_actions() |> Map.keys()
  @fields_parser_integration_modules :aurora_uix
                                     |> Application.compile_env(
                                       :fields_parser_integration_modules,
                                       ash: Aurora.Uix.Integration.Ash.FieldsParser,
                                       ctx: Aurora.Uix.Integration.Ctx.FieldsParser
                                     )
                                     |> Map.new()

  @doc """
  Extracts the `:do` block from options while preserving the rest.

  Handles multiple input patterns for block extraction, supporting both
  keyword lists with a `:do` key and explicit block parameters.

  ## Parameters
  - `opts` (keyword() | list()) - An options list that may contain a `:do` key.
  - `block` (term()) - An optional explicit block value, which defaults to `nil`.

  ## Returns
  {term(), keyword()} - A tuple containing the extracted block and the remaining options.
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
  Normalizes quoted blocks into a list of quoted expressions.

  Handles both single expressions and block expressions (`{:__block__, _, _}`),
  ensuring a consistent output format for template generation.

  ## Parameters
  - `block` (Macro.t()) - The input block to be normalized.

  ## Returns
  list(Macro.t()) - A list of normalized quoted expressions.
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
  - `tag` (atom()) - The component type identifier (e.g., `:form`, `:field`).
  - `name` (atom()) - The component name for identification.
  - `config` (keyword() | tuple() | nil) - Static configuration or field definitions.
  - `opts` (keyword()) - Component options and attributes.
  - `do_block` (Macro.t()) - Nested component definitions and content.
  - `env` (Macro.Env.t()) - The macro environment for code generation.

  ## Returns
  Macro.t() - A quoted expression that evaluates to a component map.
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
  - `fields_parser` (module()) - The fields parser implementor module.
  - `resource_schema` (module()) - The schema module for the resource.
  - `field_key` (atom()) - The field identifier.
  - `type` (atom()) - The Elixir type (e.g., `:string`, `:integer`).
  - `resource_name` (atom()) - The name of the resource this field belongs to.
  - `association_or_embed` (map() | nil) - Association metadata with cardinality information.

  ## Returns
  Field.t() - A fully configured field struct.
  """
  @spec parse_field(module(), module(), atom(), atom(), atom(), map() | nil) :: Field.t()
  def parse_field(
        fields_parser,
        resource_schema,
        field_key,
        type,
        resource_name,
        association_or_embed \\ nil
      ) do
    attrs =
      %{
        key: field_key,
        label: fields_parser.field_label(field_key, resource_name, association_or_embed),
        placeholder: fields_parser.field_placeholder(field_key, type),
        type: fields_parser.field_type(type, association_or_embed),
        html_type: fields_parser.field_html_type(type, association_or_embed),
        length: fields_parser.field_length(type),
        precision: fields_parser.field_precision(type),
        scale: fields_parser.field_scale(type),
        disabled: fields_parser.field_disabled(field_key),
        omitted: fields_parser.field_omitted(field_key),
        hidden: fields_parser.field_hidden(field_key),
        filterable?: fields_parser.field_filterable(type),
        resource: resource_name,
        data:
          fields_parser.field_data(
            resource_schema,
            field_key,
            association_or_embed,
            resource_name,
            type
          )
      }

    Field.new(attrs)
  end

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

  # Resolves fields parser implementation module based on connector type.
  #
  # Uses compile-time configuration map to look up the appropriate module.
  # The type must match a key in @crud_integration_modules or an error is raised.
  @spec get_fields_parser_module(atom()) :: module()
  def get_fields_parser_module(nil), do: raise("The type of resource_type is nil")

  def get_fields_parser_module(type) do
    case Map.get(@fields_parser_integration_modules, type) do
      nil -> raise("Invalid fields parser module for type: #{inspect(type)}")
      crud_module -> crud_module
    end
  end

  @doc """
  Creates a macro expression to store layout options in the module attributes.

  ## Parameters
  - `opts` (keyword()) - The layout options to be stored.

  ## Returns
  Macro.t() - A quoted expression that, when executed, stores the options.
  """
  @spec create_layout_opts(keyword()) :: Macro.t()
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
  - `block` (term()) - The block containing layout definitions.
  - `env` (Macro.Env.t()) - The macro environment.

  ## Returns
  Macro.t() - A quoted expression that, when executed, stores the tree paths.
  """
  @spec create_layout(term(), Macro.Env.t()) :: Macro.t()
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

  Merges options defined via `auix_create_ui/2` with any existing options
  and stores them in the `@auix_layout_opts` attribute.

  ## Parameters
  - `module` (module()) - The module where the attributes are stored.
  - `define_by_module_opts` (list()) - The list of options already defined in the module.
  - `ui_defined` (list()) - The list of new options to be added.

  ## Returns
  :ok - Indicates that the options have been stored.
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

  Merges new layout tree paths with existing ones and stores them in the
  `@auix_layout_trees` attribute, avoiding duplicates.

  ## Parameters
  - `module` (module()) - The module where the attributes are stored.
  - `defined_by_module_attribute` (list()) - The list of tree paths already defined.
  - `ui_defined` (list()) - The list of new tree paths to be added.

  ## Returns
  :ok - Indicates that the tree paths have been stored.
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
