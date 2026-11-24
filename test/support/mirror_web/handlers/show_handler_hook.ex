defmodule Aurora.UixWeb.Test.Mirror.Handlers.ShowHandlerHook do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl

  import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3, auix_route_back: 1]
  import Phoenix.LiveView, only: [push_patch: 2, put_flash: 3]

  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  alias Phoenix.LiveView.Socket

  @doc """
  Just DO nothing to delete the transaction
  """
  @spec handle_event(binary(), map(), Socket.t()) ::
          {:noreply, Socket.t()}
  def handle_event("delete", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Item deleted successfully")
     |> push_patch(to: socket.assigns.auix[:_current_path])}
  end

  def handle_event(event, params, socket) do
    super(event, params, socket)
  end

  @impl ShowComponentImpl
  def auix_update(assigns, socket) do
    {:ok, socket} = super(assigns, socket)

    {:ok, assign_auix(socket, :fields_to_reject, [:name])}
  end

  @impl ShowComponentImpl
  def auix_handle_event("hooks_back", _params, socket) do
    {:noreply, auix_route_back(socket)}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
