defmodule Aurora.UixWeb.Test.Mirror.Handlers.LoadItemsOptionsHandler do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)

    load_items_options =
      Keyword.put(socket.assigns.auix.load_items_options, :where, [
        {:reference, :lt, "item_test-06"}
      ])

    {:ok, assign_auix(socket, :load_items_options, load_items_options)}
  end
end
