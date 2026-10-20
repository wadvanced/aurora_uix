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
      `related`, `related_key`, `resource` and `select` for associations, embeds and enums).
      Hosts don't set it.
    - `option_label` (`atom` | `function`) - For many-to-one and many-to-many selectors: the field
      shown as each option's label, or a function of arity 1 (`entity`) or 2 (`assigns`, `entity`)
      returning it. `nil` uses the related primary key.
    - `query_opts` (`keyword`) - `:order_by` and `:where` applied when listing the related entries
      of an association.
    - `renderer_opts` (`keyword`) - Settings read by the field's renderer, such as `:max` for the
      predefined `:rating` and `:progress_bar` renderers.
    - `expanded` (`boolean` | `function`) - For `embeds_many` fields: whether the collection starts
      expanded. A function of arity 1 receives the rendering assigns.
    - `upload` (`Aurora.Uix.Field.Upload.t()` | `nil`) - Turns the field into a managed LiveView
      upload field. See `Aurora.Uix.Field.Upload`.
    - `generated?` (`boolean` | `nil`) - If true the value is not stored with the entity (an Ash
      calculation or aggregate) and is loaded with it when a layout renders the field. The Ash parser
      sets it in `data` for the calculations and aggregates it discovers; declare it for any other.
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
    - `resolved?` (`boolean`) - `false` while the field is partial, as declared by a `field` entry
      (unset keys are `nil`); `true` once `resolve/1` has filled the defaults. Parsers and `new/1`
      return resolved fields.

  ## Key Features
  - Encapsulates field properties for UI rendering and configuration.
  - Supports metadata for validation, display, and interaction in forms and tables.

  ## Key Constraints
  - Field struct is used by template and resource modules for dynamic UI generation.
  - `data` holds parser output; host-facing options have their own typed keys.
  - A `field` option explicitly set to `nil` is indistinguishable from an unset one.
  - Not intended for direct use outside Aurora.Uix internals.

  """

  use Accessible

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Field.Upload

  @defaults %{
    type: :string,
    html_type: :text,
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
    query_opts: [],
    renderer_opts: [],
    expanded: false,
    data: %{}
  }

  defstruct [
    :key,
    :type,
    :html_type,
    :renderer,
    :index_renderer,
    :edit_renderer,
    :show_renderer,
    :resource,
    :name,
    :label,
    :placeholder,
    :length,
    :precision,
    :scale,
    :html_id,
    :hidden,
    :readonly,
    :required,
    :disabled,
    :omitted,
    :filterable?,
    :sortable?,
    :option_label,
    :query_opts,
    :renderer_opts,
    :expanded,
    :upload,
    :generated?,
    :data,
    resolved?: false,
    __spark_metadata__: nil
  ]

  @type t() :: %__MODULE__{
          key: atom() | tuple() | nil,
          type: atom() | nil,
          html_type: atom() | binary() | nil,
          html_id: binary() | nil,
          renderer: function() | atom() | nil,
          index_renderer: function() | atom() | nil,
          edit_renderer: function() | atom() | nil,
          show_renderer: function() | atom() | nil,
          data: any() | nil,
          resource: module() | nil,
          name: binary() | nil,
          label: binary() | nil,
          placeholder: binary() | nil,
          length: non_neg_integer() | nil,
          precision: non_neg_integer() | nil,
          scale: non_neg_integer() | nil,
          hidden: boolean() | nil,
          readonly: boolean() | nil,
          required: boolean() | nil,
          disabled: boolean() | nil,
          omitted: boolean() | nil,
          filterable?: boolean() | nil,
          sortable?: boolean() | nil,
          option_label: atom() | function() | nil,
          query_opts: keyword() | nil,
          renderer_opts: keyword() | nil,
          expanded: boolean() | function() | nil,
          upload: Upload.t() | nil,
          generated?: boolean() | nil,
          resolved?: boolean(),
          __spark_metadata__: term()
        }

  @doc """
  Creates a resolved `Aurora.Uix.Field` struct with the given attributes.

  ## Parameters
  - `attrs` (map() | keyword()) - Initial attributes for the field struct.

  ## Returns
  `Aurora.Uix.Field.t()` - New field with derived name and html_id, defaults applied and
  `resolved?: true`.

  ## Examples
  ```elixir
  Aurora.Uix.Field.new(%{key: :user_name, label: "User"})
  # => %Aurora.Uix.Field{key: :user_name, name: "user_name", label: "User", resolved?: true, ...}
  ```
  """
  @spec new(map() | keyword()) :: __MODULE__.t()
  def new(attrs \\ %{}), do: %__MODULE__{} |> change(attrs) |> resolve()

  @doc """
  Merges the options set in `partial` over `field`.

  Keys that are `nil` in `partial` leave `field` unchanged; `query_opts` are merged option by
  option. `key` and `resolved?` are kept from `field`.

  ## Parameters
  - `field` (t()) - The field to change, resolved or partial.
  - `partial` (t()) - A partial field, as declared by a `field` entry.

  ## Returns
  `Aurora.Uix.Field.t()` - The merged field.
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{} = field, %__MODULE__{} = partial) do
    partial
    |> Map.from_struct()
    |> Map.drop([:key, :resolved?, :__spark_metadata__])
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
    |> Map.update(:query_opts, field.query_opts, &Keyword.merge(field.query_opts || [], &1))
    |> then(&struct(field, &1))
  end

  @doc """
  Fills every unset key with its default and marks the field as resolved.

  ## Parameters
  - `field` (t()) - The field to resolve.

  ## Returns
  `Aurora.Uix.Field.t()` - The field with `resolved?: true`. A resolved field is returned as is.
  """
  @spec resolve(t()) :: t()
  def resolve(%__MODULE__{resolved?: true} = field), do: field

  def resolve(%__MODULE__{} = field) do
    @defaults
    |> Enum.filter(fn {key, _default} -> is_nil(Map.get(field, key)) end)
    |> Map.new()
    |> Map.put(:resolved?, true)
    |> then(&struct(field, &1))
  end

  @doc """
  Updates an existing `Aurora.Uix.Field` struct with new attributes.

  ## Parameters
  - `field` (`Aurora.Uix.Field.t()`) - The existing field struct.
  - `attrs` (map() | keyword()) - Attributes to update in the struct.

  ## Returns
  `Aurora.Uix.Field.t()` - Updated field struct with new name/html_id if field changes.

  ## Examples
  ```elixir
  field = Aurora.Uix.Field.new(%{key: :email})
  Aurora.Uix.Field.change(field, %{label: "Email Address"})
  # => %Aurora.Uix.Field{key: :email, label: "Email Address", ...}
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

  defp set_field_id(%__MODULE__{html_id: html_id, key: key, resource: resource} = field)
       when html_id in [nil, ""] and is_nil(resource) do
    struct(field, %{html_id: "auix-field-#{key}-#{Counter.next_count(:auix_fields)}"})
  end

  defp set_field_id(%__MODULE__{html_id: html_id, key: key, resource: resource} = field)
       when html_id in [nil, ""] do
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
