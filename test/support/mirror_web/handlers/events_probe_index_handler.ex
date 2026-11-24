defmodule Aurora.UixWeb.Test.Mirror.Handlers.EventsProbeIndexHandler do
  @moduledoc false
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("events-test-refresh", _params, socket) do
    Events.refresh()
    {:noreply, socket}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)

  @impl IndexImpl
  def auix_handle_info(%Event{} = event, socket) do
    case Process.whereis(:auix_events_probe) do
      nil -> :ok
      probe -> send(probe, {:auix_event_seen, self(), event})
    end

    super(event, socket)
  end

  def auix_handle_info(message, socket), do: super(message, socket)
end
