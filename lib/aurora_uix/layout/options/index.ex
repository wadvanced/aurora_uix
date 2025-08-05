defmodule Aurora.Uix.Layout.Options.Index do
  @moduledoc """
  Handles retrieval and processing of options specific to `:index` layout tags.

  This module provides functionality for managing index layout options, including pagination
  controls, page bar configurations, and row data handling. It integrates with the Aurora.Uix
  layout system to provide consistent option retrieval and processing for index-based layouts.

  ## Key features

  * Retrieves and validates options for `:index` layouts
  * Supports dynamic pagination configuration with boolean and function-based controls
  * Provides responsive page bar range calculation based on media query breakpoints
  * Handles row data extraction from various sources (streams, assigns)
  * Delegates fallback option retrieval and error reporting to `Aurora.Uix.Layout.Options`

  ## Key constraints

  * Expects assigns to contain `auix` and `layout_tree` keys with appropriate structure
  * Only processes options relevant to the `:index` tag
  * Requires `layout_tree.tag` to be `:index` for option processing
  * Function-based options must have arity 1 and receive assigns as parameter

  ## Options

  * `:pagination_disabled?` - Controls whether pagination is enabled for the index list
    - Accepts `boolean()` or function of arity 1 that receives assigns and returns boolean
    - Default: `false` (pagination active)
  * `:pages_bar_range_offset` - Function for calculating pagination bar range offset
  * `:get_rows` - Function for extracting row data from assigns
  * `:row_id` - Function for extracting row identifiers

  """

  @default_pages_bar_range_offset 2

  @doc """
  Retrieves an index layout option from assigns.

  Looks up the specified option in the assigns' `auix.layout_tree.opts` when the layout tag
  is `:index`. Supports both static values and dynamic function-based options that receive
  assigns as their parameter.

  ## Parameters

  - `assigns` (`map()`) - Assigns map containing `auix` and `layout_tree` with `:index` tag
  - `option` (`atom()`) - The option key to retrieve

  ## Returns

  - `{:ok, term()}` - The value of the requested option
  - `{:not_found, atom()}` - When the option is not supported or layout tag is not `:index`

  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{auix: %{layout_tree: %{tag: :index, opts: opts}}} = assigns, option) do
    if Keyword.has_key?(opts, option),
      do: get_option(assigns, opts[option], option),
      else: get_default(assigns, option)
  end

  def get(_assigns, option), do: {:not_found, option}

  @doc """
  Calculates the page bar range offset based on media query breakpoint.

  Computes the range offset for pagination bar display based on the provided media
  query breakpoint. Larger breakpoints receive proportionally larger offsets to
  accommodate more pagination links on wider screens.

  ## Parameters

  - `assigns` (`map()`) - The assigns map (currently unused but maintained for consistency)
  - `media_query` (`atom()`) - The media query breakpoint identifier

  ## Returns

  - `integer()` - The calculated range offset value

  ## Media Query Multipliers

  - `:xl2` - 5x the default offset (10)
  - `:xl` - 4x the default offset (8)
  - `:lg` - 3x the default offset (6)
  - `:md` - 2x the default offset (4)
  - Other values - Default offset (2)

  """
  @spec page_bar_range_offset(map(), atom()) :: integer()
  def page_bar_range_offset(_assigns, :xl2), do: @default_pages_bar_range_offset * 5
  def page_bar_range_offset(_assigns, :xl), do: @default_pages_bar_range_offset * 4
  def page_bar_range_offset(_assigns, :lg), do: @default_pages_bar_range_offset * 3
  def page_bar_range_offset(_assigns, :md), do: @default_pages_bar_range_offset * 2
  def page_bar_range_offset(_assigns, _media_query), do: @default_pages_bar_range_offset

  @doc """
  Extracts row data from assigns.

  Retrieves row data from either streams (if available and matching source_key) or directly
  from the `auix.rows` field. Prioritizes stream data when both are present and source_key
  matches.

  ## Parameters

  - `assigns` (`map()`) - Assigns map containing `auix` and optionally `streams`

  ## Returns

  - `list()` - List of row data, or empty list if no rows found

  """
  @spec get_rows(map()) :: list()
  def get_rows(%{auix: %{source_key: source_key} = auix, streams: streams}) do
    case Map.get(streams, source_key) do
      nil -> Map.get(auix, :rows, [])
      rows -> rows
    end
  end

  def get_rows(%{auix: auix}), do: Map.get(auix, :rows, [])

  @doc """
  Extracts row identifier from various row data formats.

  Handles different row data structures to extract a consistent identifier. Supports
  tuple format `{id, item}`, map format with `:id` key, and returns `nil` for
  unsupported formats.

  ## Parameters

  - `row` (`{term(), term()} | map() | term()`) - Row data in various formats

  ## Returns

  - `term() | nil` - The row identifier, or `nil` if format is unsupported

  """
  @spec row_id({term(), term()} | map() | term()) :: term() | nil
  def row_id({id, _item}), do: id
  def row_id(%{id: id}), do: id
  def row_id(_), do: nil

  ## PRIVATE

  # Resolves function or boolean values for pagination_disabled? option, otherwise delegates error.
  @spec get_option(map(), term(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_option(assigns, value, :pagination_disabled?)
       when is_function(value, 1),
       do: {:ok, value.(assigns)}

  defp get_option(_assigns, value, :pagination_disabled?)
       when is_boolean(value),
       do: {:ok, value}

  defp get_option(_assigns, _value, option), do: {:not_found, option}

  # Returns default values for supported options, otherwise delegates error.
  @spec get_default(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_default(%{auix: %{layout_tree: %{tag: :index}}}, :pagination_disabled?),
    do: {:ok, false}

  defp get_default(%{auix: %{layout_tree: %{tag: :index}}}, :pages_bar_range_offset),
    do: {:ok, &__MODULE__.page_bar_range_offset/2}

  defp get_default(%{auix: %{layout_tree: %{tag: :index}}}, :get_rows),
    do: {:ok, &__MODULE__.get_rows/1}

  defp get_default(%{auix: %{layout_tree: %{tag: :index}}}, :row_id),
    do: {:ok, &__MODULE__.row_id/1}

  defp get_default(_assigns, option), do: {:not_found, option}
end
