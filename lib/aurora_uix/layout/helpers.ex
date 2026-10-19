defmodule Aurora.Uix.Layout.Helpers do
  @moduledoc """
  Helper utilities for Aurora.Uix UI DSL transformations.

  Serves as the core processing engine for DSL block transformations, component registration,
  and field metadata extraction. Handles the conversion of macro-based UI definitions into
  standardized component structures suitable for template generation.

  ## Key Features

  - DSL block extraction and normalization
  - Component registration and tree path creation
  - Field parser resolution for different connectors
  - Module attribute management for layouts

  ## Key Constraints

  - Requires valid fields parser module configuration
  - Module attributes must exist before storage operations
  - Field specifications must be atoms or keyword tuples
  """

  alias Aurora.Uix.Action
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Declared
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers

  alias Ecto.Embedded

  require Logger

  # Every action option name, not just one group's: a field-level action option carries a function
  # capture that has to be evaluated here, and missing a key sends raw AST to the renderer.
  @field_action_names Action.action_option_names()
  @field_override_keys Map.keys(%Field{}) -- [:__struct__, :key, :resolved?, :__spark_metadata__]
  @fields_parser_integration_modules :aurora_uix
                                     |> Application.compile_env(
                                       :fields_parser_integration_modules,
                                       ash: Aurora.Uix.Integration.Ash.FieldsParser,
                                       ctx: Aurora.Uix.Integration.Ctx.FieldsParser,
                                       default: Aurora.Uix.Integration.Default.FieldsParser
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
  Builds the field references of a layout's field list at macro expansion time.

  Function captures in field options are evaluated in the caller's environment.

  ## Parameters
  - `fields` (list()) - The quoted field list, e.g. `[:name, price: [label: "Price"]]`.
  - `env` (Macro.Env.t()) - The caller's environment.

  ## Returns
  Macro.t() - The escaped list of `Aurora.Uix.Layout.Declared.FieldRef` structs.
  """
  @spec field_refs(list(), Macro.Env.t()) :: Macro.t()
  def field_refs(fields, env), do: fields |> Enum.map(&field_ref(&1, env)) |> Macro.escape()

  @doc """
  Builds a declared index layout from the options of `index_columns`.

  ## Parameters
  - `resource` (atom()) - The resource name.
  - `columns` ([Declared.FieldRef.t()]) - The columns.
  - `opts` (keyword()) - The layout options.

  ## Returns
  `Aurora.Uix.Layout.Declared.Index.t()` - The declared layout.
  """
  @spec declare_index(atom(), [Declared.FieldRef.t()], keyword()) :: Declared.Index.t()
  def declare_index(resource, columns, opts) do
    {query, layout_opts} = Keyword.split(opts, [:order_by, :where])

    struct(
      %Declared.Index{
        resource: resource,
        columns: columns,
        order_by: query[:order_by],
        where: query[:where]
      },
      container_opts(layout_opts, :handler_module)
    )
  end

  @doc """
  Builds a declared form or show layout from the options of `edit_layout` or `show_layout`.

  ## Parameters
  - `layout_type` (:form | :show) - The layout type.
  - `resource` (atom()) - The resource name.
  - `children` ([Declared.child()]) - The sub-layouts and fields of the block.
  - `opts` (keyword()) - The layout options.

  ## Returns
  `Aurora.Uix.Layout.Declared.Form.t()` or `Aurora.Uix.Layout.Declared.Show.t()`.
  """
  @spec declare_container(:form | :show, atom(), [Declared.child()], keyword()) ::
          Declared.Form.t() | Declared.Show.t()
  def declare_container(:form, resource, children, opts),
    do:
      struct(
        %Declared.Form{resource: resource, children: children},
        container_opts(opts, :edit_handler_module)
      )

  def declare_container(:show, resource, children, opts),
    do:
      struct(
        %Declared.Show{resource: resource, children: children},
        container_opts(opts, :show_handler_module)
      )

  @doc """
  Splits the fields from the options in the list given to `group` or `section`.

  ## Parameters
  - `fields_and_opts` (list()) - The quoted list, e.g. `[:name, :price]` or `[default: true]`.
  - `option_keys` ([atom()]) - The option keys of the sub-layout.

  ## Returns
  {list(), keyword()} - The fields and the options.
  """
  @spec split_sub_layout_opts(list(), [atom()]) :: {list(), keyword()}
  def split_sub_layout_opts(fields_and_opts, option_keys) do
    Enum.split_with(fields_and_opts, fn
      {key, _value} when is_atom(key) -> key not in option_keys
      _field -> true
    end)
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
  Creates a macro expression that stores the layouts of a block in the module attributes.

  ## Parameters
  - `block` (term()) - The block containing layout definitions.

  ## Returns
  Macro.t() - A quoted expression that, when executed, stores the declared layouts.
  """
  @spec create_layout(term()) :: Macro.t()
  def create_layout(block) do
    quote do
      LayoutHelpers.put_layouts(
        __MODULE__,
        Module.get_attribute(__MODULE__, :auix_layouts, []),
        unquote(prepare_block(block))
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
  Stores declared layouts in the `@auix_layouts` module attribute.

  A layout replaces any layout stored earlier for the same resource and layout type.

  ## Parameters
  - `module` (module()) - The module where the attribute is stored.
  - `stored` (list()) - The layouts already stored.
  - `declared` ([Declared.layout()]) - The layouts to add.

  ## Returns
  :ok
  """
  @spec put_layouts(module(), list(), [Declared.layout()]) :: :ok
  def put_layouts(module, stored, declared) do
    Module.delete_attribute(module, :auix_layouts)
    Enum.each(declared, &Module.put_attribute(module, :auix_layouts, &1))

    stored
    |> List.flatten()
    |> Enum.reject(fn layout ->
      Enum.any?(
        declared,
        &(&1.__struct__ == layout.__struct__ and &1.resource == layout.resource)
      )
    end)
    |> Enum.each(&Module.put_attribute(module, :auix_layouts, &1))
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

  # Builds the field reference of one entry of a field list.
  @spec field_ref(atom() | tuple(), Macro.Env.t()) :: Declared.FieldRef.t()
  defp field_ref(key, _env) when is_atom(key), do: %Declared.FieldRef{key: key}

  defp field_ref({key, opts}, env) when is_atom(key) and is_list(opts) do
    field_opts = Enum.map(opts, &process_field_tag_option(&1, env))
    overrides = Keyword.take(field_opts, @field_override_keys)

    %Declared.FieldRef{
      key: key,
      overrides: if(overrides == [], do: nil, else: struct(%Field{key: key}, overrides)),
      actions: Keyword.take(field_opts, @field_action_names),
      order_by: Keyword.get(field_opts, :order_by),
      where: Keyword.get(field_opts, :where)
    }
  end

  defp field_ref({key, child}, _env) when is_atom(key) and is_atom(child),
    do: %Declared.FieldRef{key: key, path: [child]}

  defp field_ref({:{}, _meta, [key | path]}, _env), do: %Declared.FieldRef{key: key, path: path}

  defp field_ref(field, env) do
    raise CompileError,
      file: env.file,
      line: env.line,
      description: "invalid field in layout: #{Macro.to_string(field)}"
  end

  # Splits container options into the typed keys and the option-set `options`.
  @spec container_opts(keyword(), atom()) :: map()
  defp container_opts(opts, handler_key) do
    {actions, other_opts} = Keyword.split(opts, @field_action_names)
    {typed, options} = Keyword.split(other_opts, [:renderers, handler_key])

    %{
      renderers: typed[:renderers],
      handler_module: typed[handler_key],
      actions: actions,
      options: options
    }
  end

  # Processes field tag options, handling function components and quoted expressions.
  @spec process_field_tag_option({atom(), term()}, Macro.Env.t()) :: {atom(), term()}
  defp process_field_tag_option({action_name, {action_key, {:&, _, _} = function_component}}, env)
       when action_name in @field_action_names do
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

  defp process_field_tag_option({option_key, {:&, _, _} = function_capture}, env) do
    env
    |> Code.env_for_eval()
    |> then(&Code.eval_quoted_with_env(function_capture, [], &1))
    |> elem(0)
    |> then(&{option_key, &1})
  end

  defp process_field_tag_option(option, _env), do: option
end
