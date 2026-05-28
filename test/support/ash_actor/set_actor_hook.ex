defmodule AshActorTest.SetActorHook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:current_user, _params, %{"test_actor" => actor}, socket) do
    {:cont, assign(socket, :current_user, actor)}
  end

  def on_mount(:current_user, _params, _session, socket), do: {:cont, socket}

  def on_mount(:scope, _params, %{"test_scope" => actor}, socket) do
    {:cont, assign(socket, :scope, actor)}
  end

  def on_mount(:scope, _params, _session, socket), do: {:cont, socket}
end
