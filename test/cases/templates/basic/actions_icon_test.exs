defmodule Aurora.Uix.Templates.Basic.ActionsIconTest do
  use ExUnit.Case, async: true

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions

  @spec name_icon(map()) :: binary()
  def name_icon(%{auix: %{name: name}}), do: "hero-#{name}"

  test "icon/4 resolves the default, a value and a function" do
    assert Actions.icon(%{}, [], :index, :default_new) == "hero-plus"
    assert Actions.icon(%{}, [default_new: :"hero-bolt"], :index, :default_new) == :"hero-bolt"

    assert Actions.icon(
             %{auix: %{name: "star"}},
             [default_new: &__MODULE__.name_icon/1],
             :index,
             :default_new
           ) == "hero-star"

    assert Action.default_icons(:many_to_many) == []
  end

  test "label_title/1 gives text labels only" do
    assert Actions.label_title("New") == "New"
    assert Actions.label_title(:new) == "new"
    assert Actions.label_title(nil) == nil

    assigns = %{}
    assert Actions.label_title(~H"<b>New</b>") == nil
  end

  test "new/1 and new/2 set destructive?" do
    fun = &__MODULE__.name_icon/1

    assert %Action{destructive?: false} = Action.new({:archive, fun})
    assert %Action{destructive?: true} = Action.new({:archive, fun, destructive?: true})
    assert %Action{destructive?: true} = Action.new({:default_row_delete, fun})
    assert %Action{destructive?: true} = Action.new(:default_row_delete, fun)

    assert %Action{destructive?: false} =
             Action.new({:default_row_delete, fun, destructive?: false})

    assert_raise ArgumentError, fn -> Action.new({:archive, fun, destroys: true}) end
  end

  test "row action operations carry destructive?" do
    fun = &__MODULE__.name_icon/1
    other = &Actions.label_title/1

    assigns = %{
      auix: %{
        layout_tree: %{
          actions: [
            add_row_action: {:archive, fun, destructive?: true},
            replace_row_action: {:default_row_delete, other}
          ]
        },
        index_row_actions: [Action.new(:default_row_delete, fun)]
      }
    }

    result = Actions.modify_actions(assigns, Action.available_actions(:index))

    assert [
             %Action{name: :default_row_delete, destructive?: true, function_component: ^other},
             %Action{name: :archive, destructive?: true}
           ] = result.auix.index_row_actions
  end
end
