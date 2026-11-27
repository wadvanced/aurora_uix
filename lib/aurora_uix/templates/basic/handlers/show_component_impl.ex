defmodule Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl do
  @moduledoc """
  Behaviour and macro for the handlers of a generated show component.

  `use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl` defines the `Phoenix.LiveComponent`
  callbacks `update/2` and `handle_event/3`, delegating to the overridable `auix_update/2` and
  `auix_handle_event/3`.

  ## Key Features

    - Prepares the navigation, layout options and actions of the show view.
    - Handles section switching, upload downloads, and the open and close requests of a component.

  ## Key Constraints

    - Expects the `:auix` assign in the component socket.
    - Raises for an event it does not handle.
  """

  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Templates.Basic.Actions.ShowComponent, as: ShowComponentActions
  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  alias Phoenix.LiveComponent
  alias Phoenix.LiveView.Socket

  @doc """
  Updates the show view state and assigns for the LiveComponent.

  ## Parameters
  - `assigns` (map()) - Assigns containing at least `%{auix: %{routing_stack: Stack.t()}}`.
  - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns
  `{:ok, Socket.t()}` - The updated socket with show view state and routing stack assigned.
  """
  @callback auix_update(assigns :: map(), socket :: Socket.t()) :: {:ok, Socket.t()}

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
      @spec update(map(), Socket.t()) :: {:ok, Socket.t()}
      def update(assigns, socket), do: auix_update(assigns, socket)

      @doc false
      @impl LiveComponent
      @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_event(event, params, socket), do: auix_handle_event(event, params, socket)

      @doc false
      @impl ShowComponentImpl
      defdelegate auix_update(assigns, socket), to: ShowComponentImpl

      @doc false
      @impl ShowComponentImpl
      defdelegate auix_handle_event(event, params, socket), to: ShowComponentImpl

      defoverridable LiveComponent
      defoverridable auix_update: 2
      defoverridable auix_handle_event: 3
    end
  end

  @doc """
  Updates the show view state and assigns for the LiveComponent.

  ## Parameters
  - `assigns` (map()) - Assigns containing at least `%{auix: %{routing_stack: Stack.t()}}`.
  - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns
  `{:ok, Socket.t()}` - The updated socket with show view state and routing stack assigned.
  """
  @spec auix_update(map(), Socket.t()) :: {:ok, Socket.t()}
  def auix_update(
        %{auix: %{routing_stack: routing_stack}} = _assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign_auix_new(:_sections, %{})
     |> assign_auix(:_myself, socket.assigns.myself)
     |> assign_auix_navigation(routing_stack)
     |> assign_layout_options()
     |> ShowComponentActions.set_actions()
     |> BasicHelpers.assign_upload_downloadable()
     |> BasicHelpers.assign_upload_file_info()
     |> BasicHelpers.assign_embeds_expanded()
     |> render_with(&Renderer.render/1)}
  end

  @doc """
  Handles events such as section switching and navigation in the show view.

  ## Parameters
  - `event` (binary()) - The event name (`"switch_section"`, `"auix_download_upload"`, `"auix_open"`, `"auix_route_back"`).
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

  def auix_handle_event("auix_download_upload", %{"field" => field}, socket) do
    {:noreply, BasicHelpers.download_upload(socket, field)}
  end

  def auix_handle_event(
        "auix_route_back",
        _params,
        %{assigns: %{auix: %{notify: _notify}}} = socket
      ),
      do: {:noreply, report_intent(socket, {:closed})}

  def auix_handle_event("auix_open", params, socket), do: {:noreply, report_open(socket, params)}

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
