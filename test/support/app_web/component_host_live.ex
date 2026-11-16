defmodule Aurora.UixWeb.Test.ComponentHostLive do
  @moduledoc """
  A LiveView written by hand that renders generated components outside the generated LiveViews.

  Mounted with `Phoenix.LiveViewTest.live_isolated/3`. The session key `"components"` lists the
  components to render, each a map with `:module`, `:id` and `:props`. Every intent a component
  reports is shown as `#auix-host-intents li[data-component][data-intent][data-value]`. The
  session key `"hooks"` set to `true` mounts `Aurora.Uix.Live.ComponentHooks`; any other message
  it receives is shown as `#auix-host-other li[data-message]`.
  """
  use Aurora.UixWeb.Test, :live_view

  alias Aurora.Uix.Event
  alias Aurora.Uix.Live.ComponentHooks

  @doc """
  Assigns the components of the session and an empty intent list.

  ## Parameters
  - `params` (map()) - Unused.
  - `session` (map()) - Session with the optional `"components"` list and `"hooks"` flag.
  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns
  `{:ok, Phoenix.LiveView.Socket.t()}` - The socket with `:components`, `:intents` and `:other`.
  """
  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:components, Map.get(session, "components", []))
     |> assign(:intents, [])
     |> assign(:other, [])
     |> mount_hooks(session, Map.get(session, "hooks"))}
  end

  @doc """
  Renders the components and the intents received.

  ## Parameters
  - `assigns` (map()) - The LiveView assigns.

  ## Returns
  `Phoenix.LiveView.Rendered.t()` - The rendered host.
  """
  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id="auix-host">
      <.live_component
        :for={component <- @components}
        module={component.module}
        id={component.id}
        {component.props}
      />
      <ul id="auix-host-intents">
        <li
          :for={{component_id, intent} <- Enum.reverse(@intents)}
          data-component={component_id}
          data-intent={elem(intent, 0)}
          data-value={intent_value(intent)}
        >
        </li>
      </ul>
      <ul id="auix-host-other"><li :for={message <- Enum.reverse(@other)} data-message={message}></li></ul>
    </div>
    """
  end

  @doc """
  Records an intent of a component, or replaces the rendered components.

  ## Parameters
  - `message` (term()) - `{Aurora.Uix, component_id, intent}`, `{:set_components, components}`,
    `{:other, message}` or an `Aurora.Uix.Event` the hook did not consume.
  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns
  `{:noreply, Phoenix.LiveView.Socket.t()}` - The updated socket.
  """
  @impl true
  @spec handle_info(term(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({Aurora.Uix, component_id, intent}, socket),
    do: {:noreply, update(socket, :intents, &[{component_id, intent} | &1])}

  def handle_info({:set_components, components}, socket),
    do: {:noreply, assign(socket, :components, components)}

  def handle_info({:other, message}, socket),
    do: {:noreply, update(socket, :other, &[message | &1])}

  def handle_info(%Event{}, socket),
    do: {:noreply, update(socket, :other, &["event" | &1])}

  @spec mount_hooks(Phoenix.LiveView.Socket.t(), map(), term()) :: Phoenix.LiveView.Socket.t()
  defp mount_hooks(socket, session, true) do
    {:cont, socket} = ComponentHooks.on_mount(:default, %{}, session, socket)
    socket
  end

  defp mount_hooks(socket, _session, _hooks), do: socket

  @spec intent_value(tuple()) :: binary()
  defp intent_value({:open, action, id}), do: "#{action}:#{id}"
  defp intent_value({:page, page}), do: "#{page}"
  defp intent_value({:deleted, ids}), do: Enum.join(ids, ",")
  defp intent_value({:saved, entity}), do: "#{Map.get(entity, :id)}"
  defp intent_value({:closed}), do: ""
end
