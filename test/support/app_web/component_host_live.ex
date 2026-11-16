defmodule Aurora.UixWeb.Test.ComponentHostLive do
  @moduledoc """
  A LiveView written by hand that renders generated components outside the generated LiveViews.

  Mounted with `Phoenix.LiveViewTest.live_isolated/3`. The session key `"components"` lists the
  components to render, each a map with `:module`, `:id` and `:props`. Every intent a component
  reports is shown as `#auix-host-intents li[data-component][data-intent][data-value]`.
  """
  use Aurora.UixWeb.Test, :live_view

  @doc """
  Assigns the components of the session and an empty intent list.

  ## Parameters
  - `params` (map()) - Unused.
  - `session` (map()) - Session with the optional `"components"` list.
  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns
  `{:ok, Phoenix.LiveView.Socket.t()}` - The socket with `:components` and `:intents`.
  """
  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:components, Map.get(session, "components", []))
     |> assign(:intents, [])}
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
    </div>
    """
  end

  @doc """
  Records an intent of a component, or replaces the rendered components.

  ## Parameters
  - `message` (tuple()) - `{Aurora.Uix, component_id, intent}` or `{:set_components, components}`.
  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns
  `{:noreply, Phoenix.LiveView.Socket.t()}` - The updated socket.
  """
  @impl true
  @spec handle_info(tuple(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({Aurora.Uix, component_id, intent}, socket),
    do: {:noreply, update(socket, :intents, &[{component_id, intent} | &1])}

  def handle_info({:set_components, components}, socket),
    do: {:noreply, assign(socket, :components, components)}

  @spec intent_value(tuple()) :: binary()
  defp intent_value({:open, action, id}), do: "#{action}:#{id}"
  defp intent_value({:page, page}), do: "#{page}"
  defp intent_value({:deleted, ids}), do: Enum.join(ids, ",")
  defp intent_value({:saved, entity}), do: "#{Map.get(entity, :id)}"
  defp intent_value({:closed}), do: ""
end
