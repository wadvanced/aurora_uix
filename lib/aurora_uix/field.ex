defmodule Aurora.Uix.Field do
  @moduledoc """
  A module representing a configurable field in the Aurora.Uix system.

  This module defines a struct to represent field properties for UI components, such as:
    - `key` (`atom`) - The field reference in the schema.
    - `name` (`binary`) - The key's name as a binary.
    - `type` (`atom`) - The type of the field, it is read from the source and SHOULDN'T be change.
    - `html_type` (`binary`) - The HTML type of the field (e.g., `:text`, `:number`, `:date`).
    - `html_id` (`binary`) - A unique html id for the field.
    Each renderer slot is an arity-1 function `(assigns) -> rendered` **or** an atom naming a
    predefined renderer (see `Aurora.Uix.Renderer`, e.g. `:toggle_switch`, `:color`). The
    renderer to invoke is chosen by `Aurora.Uix.Renderers.resolve/3` per layout type:

      * `:index` → `index_renderer` → HTML-type tables → default (index is independent — no `renderer` fallback)
      * `:form`  → `edit_renderer` → `renderer` → HTML-type tables → default
      * `:show`  → `show_renderer` → `renderer` → HTML-type tables → default

    - `renderer` (`function` | `atom`) - Renderer for the form (edit) and show layouts unless a
      more specific `edit_renderer`/`show_renderer` is set. Does **not** apply to the index
      layout — use `index_renderer` for that.
    - `index_renderer` (`function` | `atom`) - Renderer used only for the index layout.
    - `edit_renderer` (`function` | `atom`) - Renderer used only for the form (edit) layout.
    - `show_renderer` (`function` | `atom`) - Renderer used only for the show layout.
    - `data` (`any`) - Metadata produced by the schema parsers (for example `owner_key`,
      `related`, `related_key`, `resource` and `select` for associations, embeds and enums),
      plus any renderer-specific values a host passes with the `:data` field option.
    - `option_label` (`atom` | `function`) - For many-to-one and many-to-many selectors: the field
      shown as each option's label, or a function of arity 1 (`entity`) or 2 (`assigns`, `entity`)
      returning it. `nil` uses the related primary key.
    - `query_opts` (`keyword`) - `:order_by` and `:where` applied when listing the related entries
      of an association.
    - `expanded` (`boolean` | `function`) - For `embeds_many` fields: whether the collection starts
      expanded. A function of arity 1 receives the rendering assigns.
    - `upload` (`Aurora.Uix.Field.Upload.t()` | `nil`) - Turns the field into a managed LiveView
      upload field. See `Aurora.Uix.Field.Upload`.
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
    - `filterable?` (`boolean`) - If true, it is expected that the field can be filterable by the UI.
    - `sortable?` (`boolean`) - If true, the index column header offers sorting. Parsers set it from the
      column type; it defaults to `false` for fields no parser produced.

  ## Key Features
  - Encapsulates field properties for UI rendering and configuration.
  - Supports metadata for validation, display, and interaction in forms and tables.

  ## Key Constraints
  - Field struct is used by template and resource modules for dynamic UI generation.
  - `data` holds parser output; host-facing options have their own typed keys.
  - Not intended for direct use outside Aurora.Uix internals.

  """

  use Accessible

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Field.Upload

  defstruct [
    :key,
    type: :string,
    html_type: :text,
    renderer: nil,
    index_renderer: nil,
    edit_renderer: nil,
    show_renderer: nil,
    resource: nil,
    name: "",
    label: "",
    placeholder: "",
    length: 255,
    precision: 0,
    scale: 0,
    html_id: "",
    hidden: false,
    readonly: false,
    required: false,
    disabled: false,
    omitted: false,
    filterable?: true,
    sortable?: false,
    option_label: nil,
    query_opts: [],
    expanded: false,
    upload: nil,
    data: %{}
  ]

  @type t() :: %__MODULE__{
          key: atom() | nil,
          type: atom() | nil,
          html_type: atom() | binary() | nil,
          html_id: binary(),
          renderer: function() | atom() | nil,
          index_renderer: function() | atom() | nil,
          edit_renderer: function() | atom() | nil,
          show_renderer: function() | atom() | nil,
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
          filterable?: boolean(),
          sortable?: boolean(),
          option_label: atom() | function() | nil,
          query_opts: keyword(),
          expanded: boolean() | function(),
          upload: Upload.t() | nil
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

  ## PRIVATE

  @spec set_field_id(__MODULE__.t()) :: __MODULE__.t()
  defp set_field_id(%__MODULE__{key: key} = field) when is_nil(key), do: field

  defp set_field_id(%__MODULE__{html_id: "", key: key, resource: resource} = field)
       when is_nil(resource) do
    struct(field, %{html_id: "auix-field-#{key}-#{Counter.next_count(:auix_fields)}"})
  end

  defp set_field_id(%__MODULE__{html_id: "", key: key, resource: resource} = field) do
    struct(field, %{
      html_id: "auix-field-#{resource}-#{key}-#{Counter.next_count(:auix_fields)}"
    })
  end

  defp set_field_id(field), do: field

  @spec update_name(__MODULE__.t()) :: __MODULE__.t()
  defp update_name(%{key: key} = field_struct) when is_atom(key),
    do: field_struct |> struct(%{name: to_string(key)}) |> set_field_id()

  defp update_name(%{key: {parent, field}} = field_struct),
    do: field_struct |> struct(%{name: "#{parent} #{field}"}) |> set_field_id()
end
