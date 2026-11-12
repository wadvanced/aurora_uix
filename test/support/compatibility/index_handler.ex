defmodule Aurora.UixWeb.Test.Compatibility.IndexHandler do
  @moduledoc """
  Index handler that overrides every documented index hook and calls `super`.

  ## Key Features
  - Reports each overridden callback through `Aurora.UixWeb.Test.Compatibility.Probe`.

  ## Key Constraints
  - Test support only; mirrors the examples in `guides/core/liveview.md`.
  """
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Aurora.UixWeb.Test.Compatibility.Probe

  @impl IndexImpl
  def auix_mount(params, session, socket) do
    Probe.report(:auix_mount)
    super(params, session, socket)
  end

  @impl IndexImpl
  def auix_handle_params(params, url, socket) do
    Probe.report(:auix_handle_params)
    super(params, url, socket)
  end

  @impl IndexImpl
  def apply_action(socket, params) do
    Probe.report(:apply_action)
    super(socket, params)
  end

  @impl IndexImpl
  def auix_handle_event("compat_ping", _params, socket) do
    Probe.report(:auix_handle_event)
    {:noreply, start_async(socket, :compat_async, fn -> :done end)}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)

  @impl IndexImpl
  def auix_handle_async(:compat_async, {:ok, :done}, socket) do
    Probe.report(:auix_handle_async)
    {:noreply, socket}
  end

  def auix_handle_async(task, result, socket), do: super(task, result, socket)

  @impl IndexImpl
  def auix_handle_info({:compat_notify, origin}, socket) do
    Probe.report({:auix_handle_info, origin})
    {:noreply, socket}
  end

  def auix_handle_info(message, socket), do: super(message, socket)
end
