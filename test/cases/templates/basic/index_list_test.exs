defmodule Aurora.Uix.Templates.Basic.IndexListTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Handlers.IndexList

  test "events/0 lists the list events" do
    assert IndexList.events() == [
             "filter-toggle",
             "filters-clear",
             "filters-submit",
             "index-sort",
             "index-sort-direction",
             "index-layout-change",
             "selected-toggle_all",
             "selected-cancel_toggle_all",
             "selected-delete_all"
           ]
  end

  test "previous_page/1 and next_page/1 stay inside the pages" do
    assert IndexList.previous_page(%{page: 1}) == 1
    assert IndexList.previous_page(%{page: 3}) == 2
    assert IndexList.next_page(%{page: 3, pages_count: 3}) == 3
    assert IndexList.next_page(%{page: 2, pages_count: 3}) == 3
  end

  test "handle_event/3 takes only list events" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{}}}

    assert_raise FunctionClauseError, fn -> IndexList.handle_event("delete", %{}, socket) end
  end

  test "where_conditions/1 flattens a where" do
    assert IndexList.where_conditions(nil) == []
    assert IndexList.where_conditions([{:a, 1}]) == [{:a, 1}]
    assert IndexList.where_conditions(%{a: 1}) == [a: 1]
    assert IndexList.where_conditions({:a, :lt, 2}) == [{:a, :lt, 2}]
  end
end
