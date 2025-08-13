defmodule Aurora.Uix.Selection do
  @moduledoc """
  Manages selection state for paginated data structures with per-page tracking.

  This module provides a data structure and functions to handle item selections
  across multiple pages, maintaining both global selection state and per-page
  selection tracking for UI components.

  ## Key Features

  - Global selection tracking across all pages.
  - Per-page selection state for efficient UI updates
  - Automatic state derivation for selection counts and page indicators
  """

  defstruct selected: MapSet.new(),
            selected_in_page: %{},
            selected_count: 0,
            selected_any_in_page?: false,
            toggle_all_mode: :none

  @type t() :: %__MODULE__{
          selected: MapSet.t(),
          selected_in_page: map(),
          selected_count: integer(),
          selected_any_in_page?: boolean(),
          toggle_all_mode: atom()
        }

  @doc """
  Creates a new empty selection struct.

  ## Returns

  `t()` - A new selection struct with empty selection state.
  """
  @spec new() :: __MODULE__.t()
  def new, do: %__MODULE__{}

  @doc """
  Updates derived state fields based on current selections.

  Recalculates `selected_count` and `selected_any_in_page?` based on the current
  selection state.

  ## Parameters

  - `selection` (`t()`) - The selection struct to update
  - `page` (`integer()`) - The page number to check for any selections (defaults to 1 - infinite scroll case)

  ## Returns

  `t()` - Updated selection struct with recalculated state fields.
  """
  @spec update_states(__MODULE__.t(), integer()) :: __MODULE__.t()
  def update_states(%__MODULE__{} = selection, page \\ 1) do
    selected_any_in_page? =
      selection.selected_in_page
      |> Map.get(page, MapSet.new())
      |> Enum.any?()

    selected_count = Enum.count(selection.selected)

    struct(selection, %{
      selected_count: selected_count,
      selected_any_in_page?: selected_any_in_page?
    })
  end

  @doc """
  Sets the selection state for a specific item on a given page.

  Adds or removes an item from both global and per-page selection tracking.
  When `state` is `true`, the item is added to selections; otherwise it's removed.

  ## Parameters

  - `item_id` (`term()`) - The unique identifier for the item to select/deselect
  - `selection` (`t()`) - The current selection struct
  - `state` (`boolean()`) - `true` to select the item, `false` to deselect
  - `page` (`integer()`) - The page number where this selection occurs (page is `1` when rendering infinite scroll)

  ## Returns

  `t()` - Updated selection struct with the new selection state.

  """
  @spec set_selected(term(), __MODULE__.t(), boolean(), integer()) :: __MODULE__.t()
  def set_selected(item_id, %__MODULE__{} = selection, true, page) do
    new_selected = MapSet.put(selection.selected, item_id)

    new_selected_in_page =
      selection.selected_in_page
      |> Map.get(page, MapSet.new())
      |> MapSet.put(item_id)
      |> then(&Map.put(selection.selected_in_page, page, &1))

    struct(selection, %{selected: new_selected, selected_in_page: new_selected_in_page})
  end

  def set_selected(item_id, %__MODULE__{} = selection, _state, page) do
    new_selected = MapSet.delete(selection.selected, item_id)

    new_selected_in_page =
      selection.selected_in_page
      |> Map.get(page, MapSet.new())
      |> MapSet.delete(item_id)
      |> then(&Map.put(selection.selected_in_page, page, &1))

    struct(selection, %{selected: new_selected, selected_in_page: new_selected_in_page})
  end

  @doc """
  Adds selection state to an item map for UI rendering.

  Takes an item map and adds a `:selected_check__` field indicating whether
  the item is currently selected based on the global selection state.

  ## Parameters

  - `item` (`map()`) - The item map to enhance with selection state
  - `item_id` (`term()`) - The unique identifier to check for selection
  - `selection` (`t()`) - The selection struct containing current selections

  ## Returns

  `map()` - The item map with added `:selected_check__` boolean field.

  ## Examples

      iex> selection = %Aurora.Uix.Selection{selected: MapSet.new([1, 2])}
      iex> item = %{id: 1, name: "Item 1"}
      iex> Aurora.Uix.Selection.set_item_select_state(item, 1, selection)
      %{id: 1, name: "Item 1", selected_check__: true}

  """
  @spec set_item_select_state(map(), term(), __MODULE__.t()) :: map()
  def set_item_select_state(item, item_id, selection) do
    selection.selected
    |> MapSet.member?(item_id)
    |> then(&Map.put(item, :selected_check__, &1))
  end
end
