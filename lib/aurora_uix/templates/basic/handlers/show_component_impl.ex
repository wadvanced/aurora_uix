defmodule Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl do
  @moduledoc """
  Behaviour and macro for implementing show live view component handlers in Aurora UIX LiveView templates.

  Provides a set of callbacks and a `__using__/1` macro to standardize the handling of mount, parameter changes,
  events, info messages, and action application. Designed for use with Phoenix LiveView and
  Aurora UIX conventions.

  ## Key Features

    - Defines required callbacks for form live component lifecycle and event handling.
    - Supplies a macro to inject default implementations and imports for LiveView modules.
    - Integrates with Aurora UIX context and module generators for dynamic entity management.

  ## Key Constraints

    - Expects the `:auix` assign to be present in the LiveView socket.
    - Designed for use with Phoenix LiveView and Aurora UIX context modules.
    - Assumes certain structure in the `auix` assign (e.g., `modules.context`, `source_key`, etc.).

  """

  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Stack
  alias Aurora.Uix.Templates.Basic.Actions.ShowComponent, as: ShowComponentActions
  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  alias Phoenix.LiveComponent
  alias Phoenix.LiveView.Socket

  @doc """
  Internally handles all LiveView events for the show component.

  ## Parameters
  - `event` (binary()) - Event name.
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after event handling.

  """
  @callback auix_handle_event(
              event :: binary(),
              params :: map(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour LiveComponent
      @behaviour ShowComponentImpl

      @doc false
      @impl LiveComponent
      defdelegate update(assigns, socket), to: ShowComponentImpl

      @doc false
      @impl LiveComponent
      @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_event(event, params, socket), do: auix_handle_event(event, params, socket)

      @doc false
      @impl ShowComponentImpl
      defdelegate auix_handle_event(event, params, socket), to: ShowComponentImpl

      defoverridable LiveComponent
    end
  end

  @doc """
  Updates the show view state and assigns for the LiveComponent.

  ## Parameters
  - `assigns` (map()) - Assigns containing at least `%{auix: %{entity: map(), routing_stack: Stack.t()}}`.
  - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns
  `{:ok, Socket.t()}` - The updated socket with show view state and routing stack assigned.

  """
  @spec update(map(), Socket.t()) :: {:ok, Socket.t()}
  def update(
        %{auix: %{routing_stack: routing_stack}} = _assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign_auix_new(:_sections, %{})
     |> assign_auix(:_myself, socket.assigns.myself)
     |> assign_auix(:routing_stack, routing_stack || Stack.new())
     |> assign_layout_options()
     |> ShowComponentActions.set_actions()
     |> render_with(&Renderer.render/1)}
  end

  @doc """
  Handles events such as section switching and navigation in the show view.

  ## Parameters
  - `event` (binary()) - The event name (e.g., "switch_section", "auix_route_back").
  - `params` (map()) - Parameters from the event.
  - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - The updated socket after handling the event.

  """
  @spec auix_handle_event(binary(), map(), Socket.t()) ::
          {:noreply, Socket.t()}

  def auix_handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
    %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

    socket = Phoenix.LiveView.clear_flash(socket)

    {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
  end

  def auix_handle_event(event, params, _socket) do
    raise "Event not handled. event: #{inspect(event)}. params: #{inspect(params)}"
  end

  @spec assign_layout_options(Socket.t()) :: Socket.t()
  defp assign_layout_options(socket) do
    :show
    |> LayoutOptions.available_options()
    |> Enum.reduce(socket, &BasicHelpers.assign_auix_option(&2, &1))
  end
end
