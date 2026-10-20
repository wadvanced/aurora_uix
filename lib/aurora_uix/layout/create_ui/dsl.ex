defmodule Aurora.Uix.Layout.CreateUI.Dsl do
  @moduledoc """
  Entities and option schemas of the layout DSL (`Aurora.Uix.Layout.CreateUI`).

  ## Key Features
  - `section/0` is the top-level section holding `auix_create_ui` and `auix_create_layout`, with
    the layouts (`index_columns`, `edit_layout`, `show_layout`), the sub-layouts (`inline`,
    `stacked`, `group`, `sections`, `section`) and `field` nested in them.
  - Every layout entity builds its `Aurora.Uix.Layout.Node` struct directly. `build_node/1`, the
    transform of every layout entity, validates the node's fields and options and puts them in
    their typed keys.

  ## Key Constraints
  - A layout's options are read as written in the call. Names beyond the actions, `renderers`
    and the handler module are checked against `Aurora.Uix.Layout.Options.available_options/1`,
    so options of a host's `:layout_options_parsers` are accepted.
  - A field list holding only `key: options` pairs is read by Spark as the sub-layout's
    options; such fields are written with `field`.
  - Spark writes the arguments into the node as given: a field list into `fields`, field
    options into `overrides` and layout options into `options`. `build_node/1` turns them into
    the node's final shape, so only built nodes leave this module.
  """

  alias Aurora.Uix.Action
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.CreateUI.Call
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Layout.Options
  alias Aurora.Uix.Layout.ResourceMetadata.Dsl, as: ResourceMetadataDsl
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Section

  @field_action_names Action.action_option_names()
  @field_override_keys Map.keys(%Field{}) -- [:__struct__, :key, :resolved?, :__spark_metadata__]
  @handler_keys %{index: :handler_module, form: :edit_handler_module, show: :show_handler_module}

  @layout_field_schema ResourceMetadataDsl.field_schema() ++
                         [
                           order_by: [
                             type: :any,
                             doc: "For one-to-many fields: order of the related entries."
                           ],
                           where: [
                             type: :any,
                             doc: "For one-to-many fields: filter of the related entries."
                           ]
                         ] ++
                         Enum.map(
                           @field_action_names,
                           &{&1,
                            [
                              type: :any,
                              doc: "For association fields: changes the field's own actions."
                            ]}
                         )

  @fields_schema [
    type: {:list, :any},
    default: [],
    doc:
      "Fields, as atoms, `{key, options}` pairs or association paths such as `{:category_id, :name}`."
  ]

  @ui_schema [
    for: [
      type: {:or, [:atom, {:list, :atom}]},
      doc: "Generates the UI only for this resource, or these resources."
    ],
    renderers: [
      type: :map,
      doc:
        "`html_type => renderer` table for every layout this call generates. See `Aurora.Uix.Renderers`."
    ],
    default_fields_layout: [
      type: {:in, [:stacked, :inline]},
      doc: "How the default form and show layouts place the fields."
    ],
    include: [
      type: {:or, [:atom, {:list, :atom}]},
      doc:
        "Modules whose layouts (`auix_layouts/0`) this call uses. The module's own layouts replace included ones for the same resource and layout type."
    ]
  ]

  @field %Entity{
    name: :field,
    describe: "Places one field, with options.",
    target: Node.Field,
    args: [:key, {:optional, :field_opts, []}],
    transform: {__MODULE__, :build_node, []},
    schema: [
      key: [
        type: :any,
        required: true,
        doc: "The field, or an association path such as `{:category_id, :name}`."
      ],
      field_opts: [
        type: :keyword_list,
        keys: @layout_field_schema,
        default: [],
        as: :overrides,
        doc: "Options."
      ]
    ]
  }

  @inline %Entity{
    name: :inline,
    describe: "Places its fields and sub-layouts side by side.",
    target: Node.Inline,
    args: [{:optional, :fields, []}],
    recursive_as: :children,
    entities: [children: [@field]],
    transform: {__MODULE__, :build_node, []},
    schema: [fields: @fields_schema]
  }

  @stacked %{
    @inline
    | name: :stacked,
      describe: "Places its fields and sub-layouts one below the other.",
      target: Node.Stacked
  }

  @group %Entity{
    name: :group,
    describe: "Frames its fields and sub-layouts under a title.",
    target: Node.Group,
    args: [:title, {:optional, :fields, []}],
    recursive_as: :children,
    entities: [children: [@field]],
    transform: {__MODULE__, :build_node, []},
    schema: [title: [type: :string, required: true, doc: "The title."], fields: @fields_schema]
  }

  @sections %Entity{
    name: :sections,
    describe: "Holds `section` tabs.",
    target: Node.Sections,
    recursive_as: :children,
    entities: [children: []],
    transform: {__MODULE__, :build_node, []}
  }

  @section %Entity{
    name: :section,
    describe: "A tab of `sections`, showing its fields and sub-layouts when selected.",
    target: Node.Section,
    args: [:label, {:optional, :fields, []}],
    recursive_as: :children,
    entities: [children: [@field]],
    transform: {__MODULE__, :build_node, []},
    schema: [
      label: [type: :string, required: true, doc: "The tab label."],
      fields: @fields_schema,
      default: [
        type: :boolean,
        default: false,
        as: :active?,
        doc: "Whether the tab starts selected."
      ]
    ]
  }

  @sub_layouts [@inline, @stacked, @group, @sections, @section, @field]

  @index_columns %Entity{
    name: :index_columns,
    describe: "The columns and options of a resource's index.",
    target: Node.Index,
    args: [:resource, :columns, {:optional, :layout_opts, []}],
    transform: {__MODULE__, :build_node, []},
    schema: [
      resource: [type: :atom, required: true, doc: "The resource."],
      columns: [
        type: {:list, :any},
        required: true,
        as: :children,
        doc: "The columns, as a field list."
      ],
      layout_opts: [
        type: :keyword_list,
        keys: [
          order_by: [type: :any, doc: "Order of the listed entries."],
          where: [type: :any, doc: "Filter of the listed entries."],
          *: [type: :any]
        ],
        default: [],
        as: :options,
        doc: "Layout options."
      ]
    ]
  }

  @edit_layout %Entity{
    name: :edit_layout,
    describe: "The form layout of a resource.",
    target: Node.Form,
    args: [:resource, {:optional, :layout_opts, []}],
    entities: [children: @sub_layouts],
    transform: {__MODULE__, :build_node, []},
    schema: [
      resource: [type: :atom, required: true, doc: "The resource."],
      layout_opts: [type: :keyword_list, default: [], as: :options, doc: "Layout options."]
    ]
  }

  @show_layout %{
    @edit_layout
    | name: :show_layout,
      describe:
        "The show layout of a resource. Without it, the show view reuses the form layout.",
      target: Node.Show
  }

  @layouts [@index_columns, @edit_layout, @show_layout]

  # Without a block, keyword options reach the entity as options rather than as `layout_opts`.
  # `for` is left out there: an option named after a special form can't be imported.
  @create_ui %Entity{
    name: :auix_create_ui,
    describe: "Generates the index, form and show LiveViews of the module's resources.",
    target: Call,
    args: [{:optional, :layout_opts, []}],
    entities: [children: @layouts],
    auto_set_fields: [kind: :auix_create_ui],
    schema: [
      {:layout_opts, [type: :keyword_list, keys: @ui_schema, default: [], doc: "Options."]}
      | Keyword.delete(@ui_schema, :for)
    ]
  }

  @create_layout %Entity{
    name: :auix_create_layout,
    describe:
      "Declares layouts for the module's `auix_create_ui`, or for other modules to include.",
    target: Call,
    entities: [children: @layouts],
    auto_set_fields: [kind: :auix_create_layout]
  }

  @ui %Section{
    name: :auix_ui,
    top_level?: true,
    describe: "UI generation and layout declarations.",
    entities: [@create_ui, @create_layout]
  }

  @doc """
  Returns the `auix_ui` top-level section.
  """
  @spec section() :: Section.t()
  def section, do: @ui

  @doc """
  Returns the options schema of `auix_create_ui`.
  """
  @spec ui_schema() :: keyword()
  def ui_schema, do: @ui_schema

  @doc """
  Returns the options schema of a field placed in a layout.
  """
  @spec layout_field_schema() :: keyword()
  def layout_field_schema, do: @layout_field_schema

  @doc """
  Turns a layout node as Spark built it into its final shape, validating its fields and options.

  ## Parameters
  - `node` (Node.t()) - The node as built by Spark; its child nodes are already built.

  ## Returns
  `{:ok, Node.t()}` or `{:error, binary()}`.
  """
  @spec build_node(Node.t()) :: {:ok, Node.t()} | {:error, binary()}
  def build_node(%Node.Field{key: key, overrides: opts}) when is_atom(key),
    do: {:ok, field_node_from_opts(key, opts)}

  def build_node(%Node.Field{key: path, overrides: opts}) do
    with {:ok, field_node} <- field_node(path) do
      {:ok, %{field_node_from_opts(field_node.key, opts) | path: field_node.path}}
    end
  end

  def build_node(%Node.Sections{children: children} = sections) do
    if Enum.all?(children, &match?(%Node.Section{}, &1)),
      do: {:ok, sections},
      else: {:error, "sections holds only section entries"}
  end

  def build_node(%Node.Section{} = section) do
    # `section "Label", default: true do ... end` passes `default` where the fields go.
    {defaults, fields} =
      Enum.split_with(section.fields, &match?({:default, value} when is_boolean(value), &1))

    active? = Keyword.get(defaults, :default, section.active?)

    with {:ok, section} <- sub_layout(%{section | fields: fields}) do
      {:ok, %{section | active?: active?}}
    end
  end

  def build_node(%Node.Index{} = index) do
    with {:ok, columns} <- field_nodes(index.children),
         {:ok, container} <- container_opts(index.options, :index) do
      {:ok, struct(%{index | children: columns}, container)}
    end
  end

  def build_node(%module{} = layout) when module in [Node.Form, Node.Show] do
    layout_type = if module == Node.Form, do: :form, else: :show

    with :ok <- reject_sections_entries(layout.children),
         {:ok, container} <- container_opts(layout.options, layout_type) do
      {:ok, struct(layout, container)}
    end
  end

  def build_node(sub_layout), do: sub_layout(sub_layout)

  ## PRIVATE

  # The sub-layouts and fields of the block first, then the listed fields.
  @spec sub_layout(Node.t()) :: {:ok, Node.t()} | {:error, binary()}
  defp sub_layout(%{children: children, fields: fields} = sub_layout) do
    with :ok <- reject_sections_entries(children),
         {:ok, field_nodes} <- field_nodes(fields) do
      {:ok, %{sub_layout | children: children ++ field_nodes, fields: []}}
    end
  end

  @spec reject_sections_entries([Node.t()]) :: :ok | {:error, binary()}
  defp reject_sections_entries(children) do
    if Enum.any?(children, &match?(%Node.Section{}, &1)),
      do: {:error, "section can only be placed inside sections"},
      else: :ok
  end

  @spec field_nodes(list()) :: {:ok, [Node.Field.t()]} | {:error, binary()}
  defp field_nodes(fields) do
    result =
      Enum.reduce_while(fields, {:ok, []}, fn field, {:ok, acc} ->
        case field_node(field) do
          {:ok, field_node} -> {:cont, {:ok, [field_node | acc]}}
          error -> {:halt, error}
        end
      end)

    case result do
      {:ok, field_nodes} -> {:ok, Enum.reverse(field_nodes)}
      error -> error
    end
  end

  @spec field_node(term()) :: {:ok, Node.Field.t()} | {:error, binary()}
  defp field_node(key) when is_atom(key), do: {:ok, %Node.Field{key: key}}

  defp field_node({key, opts}) when is_atom(key) and is_list(opts) do
    case Spark.Options.validate(opts, @layout_field_schema) do
      {:ok, opts} -> {:ok, field_node_from_opts(key, opts)}
      {:error, error} -> {:error, "field #{inspect(key)}: #{Exception.message(error)}"}
    end
  end

  defp field_node(path) when is_tuple(path) and tuple_size(path) > 1 do
    case Tuple.to_list(path) do
      [key | path] = keys ->
        if Enum.all?(keys, &is_atom/1),
          do: {:ok, %Node.Field{key: key, path: path}},
          else: invalid_field(path)
    end
  end

  defp field_node(field), do: invalid_field(field)

  @spec invalid_field(term()) :: {:error, binary()}
  defp invalid_field(field), do: {:error, "invalid field in layout: #{inspect(field)}"}

  @spec field_node_from_opts(atom(), keyword()) :: Node.Field.t()
  defp field_node_from_opts(key, opts) do
    overrides = Keyword.take(opts, @field_override_keys)

    %Node.Field{
      key: key,
      overrides: if(overrides == [], do: nil, else: struct(%Field{key: key}, overrides)),
      actions: Keyword.take(opts, @field_action_names),
      order_by: Keyword.get(opts, :order_by),
      where: Keyword.get(opts, :where)
    }
  end

  # Splits a container's options into actions, renderers, handler module and option-set options.
  @spec container_opts(keyword(), atom()) :: {:ok, map()} | {:error, binary()}
  defp container_opts(opts, layout_type) do
    handler_key = Map.fetch!(@handler_keys, layout_type)
    action_names = layout_type |> Action.available_actions() |> Map.keys()
    {actions, other_opts} = Keyword.split(opts, action_names)
    {typed, options} = Keyword.split(other_opts, typed_keys(layout_type, handler_key))
    known = option_names(layout_type)
    unknown = options |> Keyword.keys() |> Enum.reject(&(&1 in known))

    case unknown do
      [] ->
        {:ok,
         %{
           renderers: typed[:renderers],
           handler_module: typed[handler_key],
           order_by: typed[:order_by],
           where: typed[:where],
           actions: actions,
           options: options
         }}

      _unknown ->
        valid = Enum.sort(action_names ++ typed_keys(layout_type, handler_key) ++ known)

        {:error,
         "unknown #{layout_type} layout options #{inspect(unknown)}, valid options are: #{inspect(valid)}"}
    end
  end

  @spec typed_keys(atom(), atom()) :: [atom()]
  defp typed_keys(:index, handler_key), do: [:renderers, :order_by, :where, handler_key]
  defp typed_keys(_layout_type, handler_key), do: [:renderers, handler_key]

  # A form layout also used as the show layout carries the show's handler module.
  @spec option_names(atom()) :: [atom()]
  defp option_names(:form), do: [:show_handler_module | Options.available_options(:form)]
  defp option_names(layout_type), do: Options.available_options(layout_type)
end
