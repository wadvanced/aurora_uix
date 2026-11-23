defmodule Aurora.UixWeb.Test.Mirror.Handlers.FlashKindsHandlerHook do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("flash_kinds", _params, socket) do
    {:noreply, socket |> put_flash(:success, "Saved") |> put_flash(:warning, "Check")}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
