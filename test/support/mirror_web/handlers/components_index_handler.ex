defmodule Aurora.UixWeb.Test.Mirror.Handlers.ComponentsIndexHandler do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl

  alias Aurora.Uix.Templates.Basic.Helpers

  @spec auix_handle_event(binary(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def auix_handle_event("ping", _params, socket),
    do: {:noreply, Helpers.report_intent(socket, {:page, 99})}

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
