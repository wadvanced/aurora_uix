defmodule Aurora.UixWeb.Test.Mirror.Handlers.FormHandlerHook do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3]

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  alias Phoenix.LiveView.Socket

  @impl FormImpl
  @spec auix_save_entity(Socket.t(), map()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def auix_save_entity(%{assigns: %{action: :edit, auix: auix}}, _entity_params) do
    {:ok, auix.entity}
  end

  def auix_save_entity(socket, entity_params), do: super(socket, entity_params)

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, socket} = super(assigns, socket)
    rejected = [:list_price | socket.assigns.auix.fields_to_reject]

    {:ok, assign_auix(socket, :fields_to_reject, rejected)}
  end

  @impl FormImpl
  def auix_update(assigns, socket) do
    {:ok, socket} = super(assigns, socket)

    {:ok, assign_auix(socket, :fields_to_reject, [:rrp])}
  end

  @impl FormImpl
  def auix_handle_event("hooks_hide_description", _params, %{assigns: %{auix: auix}} = socket) do
    {:noreply, assign_auix(socket, :fields_to_reject, [:description | auix.fields_to_reject])}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
