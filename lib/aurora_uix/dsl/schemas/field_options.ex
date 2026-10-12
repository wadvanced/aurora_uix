defmodule Aurora.Uix.Dsl.Schema.FieldOptions do
  @moduledoc """
  Shared Spark options schema for field-level configuration.

  ## Key Features

  - Single key set consumed by metadata-level `field` and layout-level `field`
  - Typed entries validated by Spark at compile time

  ## Key Constraints

  - Validation only; field struct defaults in `Aurora.Uix.Field` stay the defaults
  """

  @doc """
  Returns the shared field options keyword schema.

  ## Returns

  `keyword()` - Spark options schema with one entry per field key.
  """
  @spec schema() :: keyword()
  def schema do
    renderer = {:or, [:atom, {:fun, 1}]}
    order_by = {:or, [:atom, :keyword_list, {:list, :atom}]}

    [
      key: [type: :atom, required: false],
      type: [type: :atom, required: false],
      label: [type: :string, required: false],
      placeholder: [type: :string, required: false],
      length: [type: :non_neg_integer, required: false],
      precision: [type: :non_neg_integer, required: false],
      scale: [type: :non_neg_integer, required: false],
      readonly: [type: :boolean, required: false],
      hidden: [type: :boolean, required: false],
      required: [type: :boolean, required: false],
      disabled: [type: :boolean, required: false],
      omitted: [type: :boolean, required: false],
      filterable?: [type: :boolean, required: false],
      sortable?: [type: :boolean, required: false],
      renderer: [type: renderer, required: false],
      index_renderer: [type: renderer, required: false],
      edit_renderer: [type: renderer, required: false],
      show_renderer: [type: renderer, required: false],
      expanded: [type: {:or, [:boolean, {:fun, 1}]}, required: false],
      option_label: [type: {:or, [:atom, {:fun, 1}, {:fun, 2}]}, required: false],
      order_by: [type: order_by, required: false],
      where: [type: :keyword_list, required: false]
    ]
  end
end
