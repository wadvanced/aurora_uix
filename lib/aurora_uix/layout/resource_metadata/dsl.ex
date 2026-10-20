defmodule Aurora.Uix.Layout.ResourceMetadata.Dsl do
  @moduledoc """
  Entities and option schemas of the resource metadata DSL (`Aurora.Uix.Layout.ResourceMetadata`).

  ## Key Features
  - `section/0` is the top-level section holding `auix_resource_metadata`, with its nested
    `field`, `fields` and `upload` entities.
  - `resource_schema/0` and `field_schema/0` feed the option docs of the extension.

  ## Key Constraints
  - Entity targets are `Aurora.Uix.Resource`, `Aurora.Uix.Field` and `Aurora.Uix.Field.Upload`;
    an option needs a key in its target struct, or Spark drops it.
  """

  alias Aurora.Uix.Field
  alias Aurora.Uix.Field.Upload
  alias Aurora.Uix.Resource
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Section

  @field_key_type {:or, [:atom, {:tuple, [:atom, :atom]}]}
  @renderer_type {:or, [:atom, {:fun, 1}]}
  @callback_type {:or, [{:fun, 1}, {:fun, 2}, {:fun, 3}]}
  @label_type {:or, [:string, {:fun, 0}]}

  @upload_schema [
    allow: [
      type: :keyword_list,
      default: [],
      doc:
        "Options forwarded to `Phoenix.LiveView.allow_upload/3` (`:accept`, `:max_entries`, ...)."
    ],
    consume: [
      type: @callback_type,
      doc:
        "Receives the consumed binaries (optionally the socket and the field key). See `Aurora.Uix.Field.Upload`."
    ],
    download: [
      type: @callback_type,
      doc: "Produces the file for the Download button. Without it, no button is rendered."
    ],
    downloadable?: [
      type: {:or, [:boolean, {:fun, 1}, {:fun, 2}, {:fun, 3}]},
      doc: "Whether the Download button is shown, or a callback deciding it."
    ]
  ]

  @field_schema [
    type: [type: :atom, doc: "The field type, when the parsed one must be replaced."],
    html_type: [
      type: {:or, [:atom, :string]},
      doc: "The HTML input type (`:text`, `:number`, `:select`, ...)."
    ],
    renderer: [
      type: @renderer_type,
      doc:
        "Renderer for the form and show layouts: an arity-1 function or a predefined renderer name. See `Aurora.Uix.Renderer`."
    ],
    index_renderer: [type: @renderer_type, doc: "Renderer used only for the index layout."],
    edit_renderer: [
      type: @renderer_type,
      doc: "Renderer used only for the form layout. Falls back to `:renderer`."
    ],
    show_renderer: [
      type: @renderer_type,
      doc: "Renderer used only for the show layout. Falls back to `:renderer`."
    ],
    renderer_opts: [
      type: :keyword_list,
      doc: "Settings read by the renderer, such as `max: 10` for `:rating`."
    ],
    resource: [
      type: :atom,
      doc: "For associations and embeds: the resource that describes the related entries."
    ],
    label: [type: :string, doc: "Display label. Derived from the field name when omitted."],
    placeholder: [type: :string, doc: "Placeholder text."],
    length: [type: :non_neg_integer, doc: "Display length."],
    precision: [type: :non_neg_integer, doc: "Numeric precision."],
    scale: [type: :non_neg_integer, doc: "Numeric scale."],
    hidden: [type: :boolean, doc: "Renders the field without showing it."],
    readonly: [type: :boolean, doc: "Shows the field without accepting changes."],
    required: [type: :boolean, doc: "Marks the field as required."],
    disabled: [type: :boolean, doc: "Excludes the field from form interaction."],
    omitted: [type: :boolean, doc: "Removes the field from the UI entirely."],
    filterable?: [type: :boolean, doc: "Whether the field can be filtered in the index."],
    sortable?: [
      type: :boolean,
      doc: "Whether the index column offers sorting. Parsed from the column type when omitted."
    ],
    option_label: [
      type: {:or, [:atom, {:fun, 1}, {:fun, 2}]},
      doc:
        "For selectors: the related field shown as each option's label, or a function of the entity (arity 1) or of the assigns and the entity (arity 2)."
    ],
    query_opts: [
      type: :keyword_list,
      keys: [
        order_by: [
          type: :any,
          doc: "Order of the related entries, in `Ecto.Query.order_by/3` form."
        ],
        where: [type: :any, doc: "Filter applied to the related entries."]
      ],
      doc: "Query applied when listing the related entries of an association."
    ],
    expanded: [
      type: {:or, [:boolean, {:fun, 1}]},
      doc:
        "For `embeds_many` fields: whether the collection starts expanded, or a function of the assigns."
    ],
    data: [
      type: :map,
      keys: [
        select: [
          type: :map,
          keys: [
            opts: [type: :any, required: true, doc: "The choices, as `label => value` pairs."],
            multiple: [type: :boolean, doc: "Whether several choices can be selected."]
          ],
          doc: "Choices of a `:select` field, replacing the parsed ones."
        ]
      ],
      doc: "Replaces the parsed field metadata. Only `:select` is accepted."
    ]
  ]

  @resource_schema [
    schema: [type: :atom, doc: "Ecto schema or Ash resource module."],
    ash_resource: [type: :atom, as: :schema, doc: "Alias of `:schema` for Ash resources."],
    context: [
      type: :atom,
      doc: "Context module of an Ecto resource. Required for context resources."
    ],
    type: [type: :atom, doc: "Backend (`:ctx`, `:ash`). Detected from the schema when omitted."],
    order_by: [type: :any, doc: "Order of the index entries, in `Ecto.Query.order_by/3` form."],
    where: [
      type: :any,
      doc: "Filter of the index entries. The filter bar's conditions are added to it."
    ],
    preload: [
      type: {:list, :any},
      doc:
        "Associations the index list loads besides the ones its layout renders, e.g. `[:category, posts: :author]`."
    ],
    renderers: [
      type: {:map, :atom, @renderer_type},
      doc:
        "`html_type => renderer` table for every field of the resource, e.g. `%{checkbox: :toggle_switch}`."
    ],
    name: [type: @label_type, as: :display_name, doc: "Display name of the resource."],
    title: [type: @label_type, doc: "Display title of the resource."],
    backend_opts: [
      type: :keyword_list,
      default: [],
      doc:
        "Options owned by the backend, such as Ash's `:ash_actor_assign` and action names, or a context's CRUD functions. Validated by the backend."
    ]
  ]

  @upload %Entity{
    name: :upload,
    describe: "Turns the field into a managed LiveView upload field.",
    target: Upload,
    schema: @upload_schema
  }

  @field %Entity{
    name: :field,
    describe: "Options of one field.",
    target: Field,
    args: [:key],
    schema: [{:key, [type: @field_key_type, required: true, doc: "The field."]} | @field_schema],
    entities: [upload: [@upload]],
    singleton_entity_keys: [:upload]
  }

  @fields %Entity{
    name: :fields,
    describe: "The same options for several fields.",
    target: Field,
    args: [:keys],
    schema: [
      {:keys, [type: {:list, @field_key_type}, required: true, as: :key, doc: "The fields."]}
      | @field_schema
    ]
  }

  @resource %Entity{
    name: :auix_resource_metadata,
    describe: "Declares a resource: its schema, backend and field options.",
    target: Resource,
    args: [:resource_name],
    schema: [
      {:resource_name,
       [type: :atom, required: true, as: :name, doc: "The resource identifier, e.g. `:product`."]}
      | @resource_schema
    ],
    entities: [field_overrides: [@field, @fields]]
  }

  @resources %Section{
    name: :auix_resources,
    top_level?: true,
    describe: "Resource metadata declarations.",
    entities: [@resource]
  }

  @doc """
  Returns the `auix_resources` top-level section.
  """
  @spec section() :: Section.t()
  def section, do: @resources

  @doc """
  Returns the options schema of `auix_resource_metadata`.
  """
  @spec resource_schema() :: keyword()
  def resource_schema, do: @resource_schema

  @doc """
  Returns the options schema of `field` and `fields`.
  """
  @spec field_schema() :: keyword()
  def field_schema, do: @field_schema
end
