defmodule Aurora.UixWeb.Test.Compatibility.ShowHandler do
  @moduledoc """
  Show handler that overrides `auix_update/2` and `auix_handle_event/3` with `super`.

  ## Key Features
  - Routes back with `auix_route_back/1` and navigates with `push_navigate/2` from targeted events.

  ## Key Constraints
  - Test support only; mirrors the examples in `guides/core/liveview.md`.
  """
  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl

  import Aurora.Uix.Templates.Basic.Helpers, only: [auix_route_back: 1]
  import Phoenix.LiveView, only: [push_navigate: 2]

  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  alias Aurora.UixWeb.Test.Compatibility.Probe

  @impl ShowComponentImpl
  def auix_update(assigns, socket) do
    Probe.report(:show_auix_update)
    super(assigns, socket)
  end

  @impl ShowComponentImpl
  def auix_handle_event("compat_back", _params, socket) do
    {:noreply, auix_route_back(socket)}
  end

  def auix_handle_event("compat_go", _params, socket) do
    %{entity: entity, uri_path: uri_path} = socket.assigns.auix
    {:noreply, push_navigate(socket, to: "/#{uri_path}/#{entity.id}/edit")}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
