defmodule Aurora.Uix.Live.ComponentHooksTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Live.ComponentHooks

  test "register/2 without the hook does nothing" do
    assert ComponentHooks.register(
             %Phoenix.LiveComponent.CID{cid: 1},
             Aurora.Uix.Guides.Inventory.Product
           ) == :ok

    assert Process.get({ComponentHooks, :instances}) == nil
  end
end
