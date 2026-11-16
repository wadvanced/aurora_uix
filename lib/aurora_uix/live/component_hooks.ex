defmodule Aurora.Uix.Live.ComponentHooks do
  @moduledoc """
  on_mount hook that forwards Aurora.Uix.Events to the index components of a hand-written LiveView.

  ## Key Features

  - One subscription per schema: the first index component of a schema subscribes the LiveView
    to its `Aurora.Uix.Events` topic.
  - Forwarding with `send_update/3`: every `%Aurora.Uix.Event{}` of a registered schema reaches
    every registered instance as `auix_event`.
  - No code in the host: `on_mount Aurora.Uix.Live.ComponentHooks` is the whole setup.

  ## Key Constraints

  - The registry lives in the process dictionary of the LiveView.
  - A component that left the page stays registered, and LiveView ignores the update sent to it.
  - The generated `.Index` LiveView does not use the hook: it subscribes on its own.
  """

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Phoenix.LiveComponent.CID
  alias Phoenix.LiveView.Socket

  # A LiveComponent runs in the process of its LiveView and cannot reach the LiveView's socket;
  # the process dictionary is the one place both can read.
  @key {__MODULE__, :instances}

  @doc """
  Starts an empty registry and attaches the `handle_info` hook that forwards the events.

  ## Parameters
  - `name` (atom()) - The hook name, `:default`.
  - `params` (map()) - Unused.
  - `session` (map()) - Unused.
  - `socket` (Socket.t()) - The LiveView socket.

  ## Returns
  `{:cont, Socket.t()}` - The socket with the hook attached.
  """
  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    Process.put(@key, %{})

    {:cont,
     Phoenix.LiveView.attach_hook(socket, :auix_component_events, :handle_info, &forward/2)}
  end

  @doc """
  Registers an index component instance for the events of `schema`. The first instance of a
  schema subscribes the LiveView to its topic.

  ## Parameters
  - `cid` (struct()) - The `@myself` of the component instance, a `Phoenix.LiveComponent.CID`.
  - `schema` (module()) - The schema or Ash resource the instance lists.

  ## Returns
  `:ok` - Also in a process without the hook, where nothing is registered or subscribed.
  """
  @spec register(struct(), module()) :: :ok
  def register(%CID{} = cid, schema) do
    case Process.get(@key) do
      nil ->
        :ok

      instances ->
        unless Map.has_key?(instances, schema), do: :ok = Events.subscribe(schema)
        Process.put(@key, Map.update(instances, schema, [cid], &Enum.uniq([cid | &1])))
        :ok
    end
  end

  @spec forward(term(), Socket.t()) :: {:cont | :halt, Socket.t()}
  defp forward(%Event{schema: schema} = event, socket) do
    case @key |> Process.get(%{}) |> Map.get(schema) do
      nil ->
        {:cont, socket}

      cids ->
        Enum.each(cids, &Phoenix.LiveView.send_update(&1, %{auix_event: event}))
        {:halt, socket}
    end
  end

  defp forward(_message, socket), do: {:cont, socket}
end
