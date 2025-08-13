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
            selected_any_in_page?: false

  @type t() :: %__MODULE__{
          selected: MapSet.t(),
          selected_in_page: map(),
          selected_count: integer(),
          selected_any_in_page?: boolean()
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

  - `selected_id` (`term()`) - The unique identifier for the item to select/deselect
  - `selection` (`t()`) - The current selection struct
  - `state` (`boolean()`) - `true` to select the item, `false` to deselect
  - `page` (`integer()`) - The page number where this selection occurs (page is `1` when rendering infinite scroll)

  ## Returns

  `t()` - Updated selection struct with the new selection state.

  """
  @spec set_selected(term(), __MODULE__.t(), boolean(), integer()) :: __MODULE__.t()
  def set_selected(selected_id, %__MODULE__{} = selection, true, page) do
    new_selected = MapSet.put(selection.selected, selected_id)

    new_selected_in_page =
      selection.selected_in_page
      |> Map.get(page, MapSet.new())
      |> MapSet.put(selected_id)
      |> then(&Map.put(selection.selected_in_page, page, &1))

    struct(selection, %{selected: new_selected, selected_in_page: new_selected_in_page})
  end

  def set_selected(selected_id, %__MODULE__{} = selection, _state, page) do
    new_selected = MapSet.delete(selection.selected, selected_id)

    new_selected_in_page =
      selection.selected_in_page
      |> Map.get(page, MapSet.new())
      |> MapSet.delete(selected_id)
      |> then(&Map.put(selection.selected_in_page, page, &1))

    struct(selection, %{selected: new_selected, selected_in_page: new_selected_in_page})
  end
end
