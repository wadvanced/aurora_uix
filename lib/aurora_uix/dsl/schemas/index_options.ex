defmodule Aurora.Uix.Dsl.Schema.IndexOptions do
  @moduledoc """
  Spark options schema for index-level configuration.

  ## Key Features

  - Key set mirroring the `:index` layout option defaults
  - Typed entries validated by Spark at compile time

  ## Key Constraints

  - Index layouts only; form and show layouts use their own schemas
  """

  @doc """
  Returns the index options keyword schema.

  ## Returns

  `keyword()` - Spark options schema with one entry per index key.
  """
  @spec schema() :: keyword()
  def schema do
    title = {:or, [:string, {:fun, 1}]}
    order_by = {:or, [:atom, :keyword_list, {:list, :atom}]}
    renderers = {:map, :atom, {:or, [:atom, {:fun, 1}]}}

    [
      pagination_disabled?: [type: {:or, [:boolean, {:fun, 1}]}, required: false],
      sort_disabled?: [type: {:or, [:boolean, {:fun, 1}]}, required: false],
      pagination_items_per_page: [type: :non_neg_integer, required: false],
      pages_bar_range_offset: [type: {:or, [:non_neg_integer, {:fun, 2}]}, required: false],
      get_streams: [type: {:fun, 1}, required: false],
      row_id: [type: {:fun, 1}, required: false],
      infinite_scroll_items_load: [type: :non_neg_integer, required: false],
      alternate_streams_suffixes: [type: {:list, :string}, required: false],
      page_title: [type: title, required: false],
      page_subtitle: [type: title, required: false],
      new_action_label: [type: {:or, [:string, {:fun, 0}]}, required: false],
      order_by: [type: order_by, required: false],
      where: [type: :keyword_list, required: false],
      handler_module: [type: :module, required: false],
      renderers: [type: renderers, required: false]
    ]
  end
end
