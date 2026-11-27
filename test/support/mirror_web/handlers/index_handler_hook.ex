defmodule Aurora.UixWeb.Test.Mirror.Handlers.IndexHandlerHook do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(params, session, %{assigns: %{auix: auix}} = socket) do
    new_socket =
      auix.layout_tree
      |> Map.put(:where, {:reference, :lt, "item_test-06"})
      |> then(&assign_auix(socket, :layout_tree, &1))

    super(params, session, new_socket)
  end

  @impl IndexImpl
  def auix_apply_action(%{assigns: %{live_action: action}} = socket, params) do
    super(assign_auix(socket, :hooks_action, action), params)
  end

  # The deprecated name still runs, after `auix_apply_action/2`, until it is removed in 0.3.
  @impl IndexImpl
  def apply_action(%{assigns: %{live_action: action}} = socket, params) do
    super(assign_auix(socket, :hooks_legacy_action, action), params)
  end

  @impl IndexImpl
  def auix_mount(params, session, socket) do
    super(params, session, assign_auix(socket, :hooks_mount, "mounted"))
  end

  @impl IndexImpl
  def auix_handle_params(params, url, socket) do
    super(params, url, assign_auix(socket, :hooks_filter, Map.get(params, "filter")))
  end

  @impl IndexImpl
  def auix_handle_event("hooks_report", _params, %{assigns: %{auix: auix}} = socket) do
    saved = Map.get(auix, :hooks_saved)
    actions = "action=#{auix.hooks_action} legacy_action=#{auix.hooks_legacy_action}"
    report = "mount=#{auix.hooks_mount} filter=#{auix.hooks_filter} #{actions} saved=#{saved}"

    {:noreply, put_flash(socket, :info, report)}
  end

  def auix_handle_event("hooks_async", _params, socket) do
    {:noreply, start_async(socket, :hooks_async, fn -> "async done" end)}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)

  @impl IndexImpl
  def auix_handle_async(:hooks_async, {:ok, message}, socket) do
    {:noreply, put_flash(socket, :info, message)}
  end

  def auix_handle_async(task, result, socket), do: super(task, result, socket)

  @impl IndexImpl
  def auix_handle_info({_component, {:saved, entity}} = message, socket) do
    super(message, assign_auix(socket, :hooks_saved, entity.name))
  end

  def auix_handle_info(message, socket), do: super(message, socket)
end
