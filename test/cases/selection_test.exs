defmodule Aurora.Uix.Test.SelectionTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Selection

  test "unselect/2 removes ids from every page" do
    selection =
      Enum.reduce(
        [{"a", 1}, {"b", 2}, {"c", 2}],
        Selection.new(),
        fn {id, page}, acc -> Selection.set_selected(id, acc, true, page) end
      )

    result = Selection.unselect(selection, ["a", "b"])

    assert result.selected == MapSet.new(["c"])
    assert result.selected_in_page == %{1 => MapSet.new(), 2 => MapSet.new(["c"])}
  end
end
