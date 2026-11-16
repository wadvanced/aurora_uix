defmodule Aurora.Uix.Templates.Basic.HelpersIntentTest do
  @moduledoc """
  Unit tests for the intents a component reports and the record inputs it requires.
  """
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Helpers

  test "report_intent/2 reaches a pid and a component" do
    pid_socket = %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}, id: "c1", auix: %{notify: self()}}
    }

    Helpers.report_intent(pid_socket, {:closed})
    assert_receive {Aurora.Uix, "c1", {:closed}}

    component_socket = %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}, id: "c1", auix: %{notify: {SomeComponent, "parent"}}}
    }

    Helpers.report_intent(component_socket, {:closed})

    assert_receive {:phoenix, :send_update,
                    {{SomeComponent, "parent"},
                     %{id: "parent", auix_intent: {Aurora.Uix, "c1", {:closed}}}}}
  end

  test "report_intent/2 without notify reaches the calling process" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, id: "c1", auix: %{}}}

    Helpers.report_intent(socket, {:closed})
    assert_receive {Aurora.Uix, "c1", {:closed}}
  end

  test "a show component needs a record" do
    assert_raise ArgumentError, fn ->
      Helpers.assign_component_inputs(
        %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, id: "s1", auix: %{}}},
        %{id: "s1"},
        :show
      )
    end
  end
end
