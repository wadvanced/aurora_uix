defmodule Aurora.Uix.Layout.Options.Index do
  @moduledoc """
  Handles retrieval and processing of options specific to `:index` layout type.

  Provides functionality for managing index layout options, including pagination controls,
  page bar configurations, and row data handling. Integrates with the Aurora.Uix layout
  system to provide consistent option retrieval and processing for index-based layouts.

  ## Options

  * `:alternate_streams_suffixes` - A list of suffixes use for producing multiple streams.
    Current implementation produces an alternate stream for displaying in card format.
    - Accepts a list of `binary()` or a function of arity 1 that receives assigns.
    - Default: `["mobile"]`.
  * `:infinite_scroll_items_load` - The count of items to read into the streams when the
    infinity scroll pagination triggers.
    - Accepts a positive `integer()` or a function of arity 1 that receives assigns.
    - Default: `200`.
  * `:pagination_disabled?` - Controls whether pagination is enabled for the index list
    - Accepts `boolean()` or function of arity 1 that receives assigns and returns boolean
    - Default: `false` (pagination active)
  * `:sort_disabled?` - Turns off user sorting: the column headers and the card view's sort
    control offer none, and the `"index-sort"` event is ignored. `:order_by` still applies.
    - Accepts `boolean()` or function of arity 1 that receives assigns and returns boolean
    - Default: `false` (sorting active)
  * `:pagination_items_per_page` - Number of items to display per page.
    - Accepts a positive `integer()` or a function of arity 1 that receives assigns.
    - Default: `40`.
  * `:pages_bar_range_offset` - Function for calculating pagination bar range offset
    - Accepts a function of arity 2 that receives assigns and the breakpoint.
  * `:page_title` - Title for showing in the page.
    - Accepts a `binary()` (static title) or a function of arity 1 that receives assigns and returns a Phoenix.LiveView.Rendered.
    - Default: `"List {name}"`, where `{name}` is the resource name.
  * `:page_subtitle` - The subtitle for the index list.
    - Accepts a `binary()` or a function of arity 1 that receives assigns and returns a Phoenix.LiveView.Rendered.
    - Default: `""`.
  * `:new_action_label` - The label used in the "new" action button.
    - Accepts a `binary()` or a 0-arity function returning a `binary()` (see
      `Aurora.Uix.Layout.Options.parse_value/1`).
    - Default: `"New {name}"`, where `{name}` is the resource name.
  * `:get_streams` - Function for extracting row data from assigns
    - Accepts a function of arity 1.
  * `:row_id` - Function for extracting row identifiers
    - Accepts a function of arity 1.
  """

  use Aurora.Uix.Layout.Options, layout_type: :index

  alias Aurora.Uix.Layout.Options, as: LayoutOptions

  # A text, or a function of the assigns rendering it.
  @title {:or, [nil, :string, {:fun, 1}]}
  # A text, a function returning it, or a function of the assigns.
  @label {:or, [nil, :string, :atom, {:fun, 0}, {:fun, 1}]}

  option(:pagination_disabled?, {:or, [:boolean, {:fun, 1}]})
  option(:sort_disabled?, {:or, [:boolean, {:fun, 1}]})
  option(:page_title, @title)
  option(:page_subtitle, @title)
  option(:pages_bar_range_offset, {:or, [{:fun, 1}, {:fun, 2}]})
  option(:get_streams, {:fun, 1})
  option(:row_id, {:fun, 1})
  option(:infinite_scroll_items_load, {:or, [:pos_integer, {:fun, 1}]})
  option(:pagination_items_per_page, {:or, [:pos_integer, {:fun, 1}]})
  option(:new_action_label, @label)
  option(:alternate_streams_suffixes, {:or, [{:list, :string}, {:fun, 1}]})

  @default_pages_bar_range_offset 2
  @default_items_per_page 40
  @default_infinity_scroll_items_load 200

  @doc """
  Calculates the page bar range offset based on media query breakpoint.

  Computes the range offset for pagination bar display based on the provided media
  query breakpoint. Larger breakpoints receive proportionally larger offsets to
  accommodate more pagination links on wider screens.

  ## Parameters
  - `assigns` (map()) - The assigns map (currently unused but maintained for consistency).
  - `media_query` (atom()) - The media query breakpoint identifier.

  ## Returns
  integer() - The calculated range offset value.

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
  - `assigns` (map()) - Assigns map containing `auix` and optionally `streams`.

  ## Returns
  list() - List of row data, or empty list if no rows found.
  """
  @spec get_streams(map()) :: list()
  def get_streams(%{streams: streams}), do: streams

  def get_streams(%{auix: auix}), do: Map.get(auix, :rows, [])

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

  @doc """
  The default infinity scroll items to load.
  """
  @spec default_infinity_scroll_items_load() :: integer()
  def default_infinity_scroll_items_load, do: @default_infinity_scroll_items_load

  ## PRIVATE

  # Returns default values for supported options, otherwise delegates error.
  @spec get_default(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_default(%{auix: %{layout_type: :index}}, :pagination_disabled?),
    do: {:ok, false}

  defp get_default(%{auix: %{layout_type: :index}}, :sort_disabled?),
    do: {:ok, false}

  defp get_default(%{auix: %{layout_type: :index, title: title}}, :page_title),
    do: {:ok, "Listing #{LayoutOptions.parse_value(title)}"}

  defp get_default(%{auix: %{layout_type: :index}}, :page_subtitle),
    do: {:ok, ""}

  defp get_default(%{auix: %{layout_type: :index}}, :pages_bar_range_offset),
    do: {:ok, &__MODULE__.page_bar_range_offset/2}

  defp get_default(%{auix: %{layout_type: :index}}, :get_streams),
    do: {:ok, &__MODULE__.get_streams/1}

  defp get_default(%{auix: %{layout_type: :index}}, :row_id),
    do: {:ok, &__MODULE__.row_id/1}

  defp get_default(%{auix: %{layout_type: :index}}, :infinite_scroll_items_load),
    do: {:ok, @default_infinity_scroll_items_load}

  defp get_default(%{auix: %{layout_type: :index}}, :pagination_items_per_page),
    do: {:ok, @default_items_per_page}

  defp get_default(%{auix: %{layout_type: :index, name: name}}, :new_action_label),
    do: {:ok, "New #{LayoutOptions.parse_value(name)}"}

  defp get_default(%{auix: %{layout_type: :index}}, :alternate_streams_suffixes),
    do: {:ok, ["mobile"]}

  defp get_default(_assigns, option), do: {:not_found, option}
end
