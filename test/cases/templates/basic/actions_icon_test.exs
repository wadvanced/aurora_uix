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
end
