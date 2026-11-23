defmodule Aurora.UixWeb.Test.Mirror.Handlers.SelectedBulkActionIndexHandler do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Events
  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Aurora.Uix.Test.MirrorCtx
  alias Aurora.Uix.Test.MirrorCtx.Product

  @impl IndexImpl
  def auix_handle_event("deactivate_selected", _params, socket) do
    Enum.each(socket.assigns.auix.selection.selected, fn id ->
      id |> MirrorCtx.get_product!() |> MirrorCtx.update_product(%{inactive: true})
    end)

    Events.changed(Product)
    Events.reset_selection()

    {:noreply, put_flash(socket, :info, "Products deactivated")}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
