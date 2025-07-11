defmodule Aurora.Uix.Web.Templates.Basic.Handlers.ShowImpl do
  @moduledoc """
  Behaviour and macro for implementing show view handlers in Aurora UIX LiveView templates.

  Provides a set of callbacks and a `__using__/1` macro to standardize the handling of mount, parameter changes,
  events, info messages, and action application for show views. Designed for use with Phoenix LiveView and
  Aurora UIX conventions.

  ## Key Features

    - Defines required callbacks for the show modal lifecycle and event handling.
    - Supplies a macro to inject default implementations and imports for LiveView modules.
    - Integrates with Aurora UIX context and module generators for dynamic entity management.

  ## Key Constraints

    - Expects the `:auix` assign to be present in the LiveView socket.
    - Designed for use with Phoenix LiveView and Aurora UIX context modules.
    - Assumes certain structure in the `auix` assign (e.g., `modules.context`, `list_key`, etc.).

  """
  import Aurora.Uix.Web.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Web.Templates.Basic.Handlers.ShowImpl
  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Web.Templates.Basic.Renderer

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @doc """
  Initializes the LiveView socket for the show modal.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `params` (map()) - URL/query parameters.
  - `session` (map()) - Session data.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:ok, Socket.t()}` - The initialized socket with streamed entities.

  """
  @callback auix_mount(
              caller :: module(),
              params :: map(),
              session :: map(),
              socket :: Socket.t()
            ) :: {:ok, Socket.t()}

  @doc """
  Handles URL parameter changes, updates routing stack, and assigns form component.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `params` (map()) - URL/query parameters.
  - `url` (binary()) - Current URL.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with routing stack and form component.

  """
  @callback auix_handle_params(
              caller :: module(),
              params :: map(),
              url :: binary(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()}

  @doc """
  Handles all LiveView events for the show modal.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `event` (binary()) - Event name.
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after event handling.

  """
  @callback auix_handle_event(
              caller :: module(),
              event :: binary(),
              params :: map(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour LiveView
      @behaviour ShowImpl

      @doc false
      @impl LiveView
      @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
      def mount(params, session, socket) do
        auix_mount(__MODULE__, params, session, socket)
      end

      @doc false
      @impl LiveView
      @spec handle_params(map(), binary(), Socket.t()) ::
              {:noreply, Socket.t()}
      def handle_params(params, url, socket) do
        auix_handle_params(__MODULE__, params, url, socket)
      end

      @doc false
      @impl LiveView
      @spec handle_event(binary(), map(), Socket.t()) ::
              {:noreply, Socket.t()}
      def handle_event(event, params, socket) do
        auix_handle_event(__MODULE__, event, params, socket)
      end

      @impl ShowImpl
      defdelegate auix_mount(caller, params, session, socket), to: ShowImpl

      @impl ShowImpl
      defdelegate auix_handle_params(caller, params, url, socket), to: ShowImpl

      @impl ShowImpl
      defdelegate auix_handle_event(caller, event, params, socket), to: ShowImpl

      defoverridable auix_mount: 4, auix_handle_params: 4, auix_handle_event: 4
    end
  end

  @doc """
  Initializes the LiveView socket for the show page.

  ## Parameters
    - `caller` (module()) - Caller module.
    - `params` (map()) - Request parameters (unused).
    - `session` (map()) - Session data (unused).
    - `socket` (Socket.t()) - The LiveView socket.

  ## Returns

    - `{:ok, Socket.t()}` - The initialized socket.
  """
  @spec auix_mount(module(), map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def auix_mount(_caller, _params, _session, socket) do
    {:ok, socket}
  end

  @doc """
  Handles URL parameter changes and loads the entity for display.

  ## Parameters
    - `caller` (module()) - Caller module.
    - `params` (map()) - Parameters including the entity ID.
    - `url` (binary()) - The current URL.
    - `socket` (Socket.t()) - The LiveView socket with `:auix` assigns.

  ## Returns

    - `{:noreply, Socket.t()}` - The updated socket with entity and navigation assigns.
  """
  @spec auix_handle_params(module(), map(), binary(), Socket.t()) ::
          {:noreply, Socket.t()}
  def auix_handle_params(_caller, %{"id" => id} = params, url, %{assigns: %{auix: auix}} = socket) do
    form_component = ModulesGenerator.module_name(auix, ".FormComponent")

    {:noreply,
     socket
     |> assign_auix_new(:_sections, %{})
     |> assign_auix(:entity, auix.get_function.(id, preload: auix.preload))
     |> assign_auix(:form_component, form_component)
     |> assign_auix_current_path(url)
     |> assign_auix_routing_stack(params, %{
       type: :navigate,
       path: "/#{auix.link_prefix}#{auix.source}"
     })
     |> render_with(&Renderer.render/1)}
  end

  @doc """
  Handles all supported LiveView events for the show page.

  - `"switch_section"`: Switches between sections/tabs.
  - `"delete"`: Deletes an entity and navigates back on success.
  - `"auix_route_forward"`: Handles forward navigation (navigate/patch).
  - `"auix_route_back"`: Handles backward navigation.

  ## Parameters

    - `event` (binary()) - The event name.
    - `params` (map()) - Event parameters.
    - `socket` (Socket.t()) - The LiveView socket.

  ## Returns

    - `{:noreply, Socket.t()}` - The updated socket.

  """
  @spec auix_handle_event(module(), binary(), map(), Socket.t()) ::
          {:noreply, Socket.t()}
  def auix_handle_event(_caller, "switch_section", %{"tab-id" => sections_tab_id}, socket) do
    %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)
    {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
  end

  def auix_handle_event(_caller, "delete", params, socket) do
    %{
      "id" => id,
      "get_function" => get_function_string,
      "delete_function" => delete_function_string
    } = params

    {get_function, _} = Code.eval_string(get_function_string)
    {delete_function, _} = Code.eval_string(delete_function_string)

    socket =
      with %{} = entity <- get_function.(id, []),
           {:ok, _changeset} <- delete_function.(entity) do
        socket
        |> put_flash(:info, "Item deleted successfully")
        |> push_patch(to: socket.assigns.auix[:_current_path])
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  def auix_handle_event(
        _caller,
        "auix_route_forward",
        %{"route_type" => "navigate", "route_path" => path},
        socket
      ) do
    {:noreply, auix_route_forward(socket, to: path)}
  end

  def auix_handle_event(
        _caller,
        "auix_route_forward",
        %{"route_type" => "patch", "route_path" => path},
        socket
      ) do
    {:noreply, auix_route_forward(socket, patch: path)}
  end

  def auix_handle_event(_caller, "auix_route_back", _params, socket) do
    {:noreply, auix_route_back(socket)}
  end
end
