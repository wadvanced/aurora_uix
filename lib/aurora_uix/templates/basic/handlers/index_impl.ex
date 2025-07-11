defmodule Aurora.Uix.Web.Templates.Basic.Handlers.IndexImpl do
  @moduledoc """
  Behaviour and macro for implementing index page handlers in Aurora UIX LiveView templates.

  Provides a set of callbacks and a `__using__/1` macro to standardize the handling of mount, parameter changes,
  events, info messages, and action application for index pages. Designed for use with Phoenix LiveView and
  Aurora UIX conventions.

  ## Key Features

    - Defines required callbacks for index page lifecycle and event handling.
    - Supplies a macro to inject default implementations and imports for LiveView modules.
    - Integrates with Aurora UIX context and module generators for dynamic entity management.
    - Supports streaming, patching, and navigation for index resources.

  ## Key Constraints

    - Expects the `:auix` assign to be present in the LiveView socket.
    - Designed for use with Phoenix LiveView and Aurora UIX context modules.
    - Assumes certain structure in the `auix` assign (e.g., `modules.context`, `list_key`, etc.).

  """

  import Aurora.Uix.Web.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Web.Templates.Basic.Handlers.IndexImpl
  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Web.Templates.Basic.Renderer
  alias Phoenix.LiveView.Socket

  @doc """
  Initializes the LiveView socket for the index page.

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
            ) ::
              {:ok, Socket.t()}

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
  Handles all LiveView events for the index page.

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

  @doc """
  Handles info messages for the LiveView.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `event_info` (term()) - Info message, e.g., `{_component, {:saved, entity}}`.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after info message handling.

  """
  @callback auix_handle_info(
              caller :: module(),
              event_info :: term(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()}

  @doc """
  Applies the given action to the socket.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket.
  - `caller` (module()) - The calling module.
  - `action` (atom()) - Action to apply (`:edit`, `:new`, `:index`).
  - `params` (map()) - Action parameters.

  ## Returns
  `Socket.t()` - Updated socket with action-specific assigns.

  """
  @callback auix_apply_action(
              socket :: Socket.t(),
              caller :: module(),
              action :: atom(),
              params :: map()
            ) ::
              Socket.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour IndexImpl
      @behaviour Phoenix.LiveView

      import Aurora.Uix.Web.Templates.Basic.Helpers
      import Phoenix.LiveView

      alias Aurora.Uix.Web.Templates.Basic.Handlers.IndexImpl
      alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
      alias Aurora.Uix.Web.Templates.Basic.Renderer

      @doc false
      @impl Phoenix.LiveView
      @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
      def mount(params, session, socket) do
        auix_mount(__MODULE__, params, session, socket)
      end

      @doc false
      @impl Phoenix.LiveView
      @spec handle_params(map(), binary(), Phoenix.LiveView.Socket.t()) ::
              {:noreply, Phoenix.LiveView.Socket.t()}
      def handle_params(params, url, socket) do
        auix_handle_params(__MODULE__, params, url, socket)
      end

      @doc false
      @impl Phoenix.LiveView
      @spec handle_event(binary(), map(), Phoenix.LiveView.Socket.t()) ::
              {:noreply, Phoenix.LiveView.Socket.t()}
      def handle_event(event, params, socket) do
        auix_handle_event(__MODULE__, event, params, socket)
      end

      @doc false
      @impl Phoenix.LiveView
      @spec handle_info(term(), Phoenix.LiveView.Socket.t()) ::
              {:noreply, Phoenix.LiveView.Socket.t()}
      def handle_info(event_info, socket) do
        auix_handle_info(__MODULE__, event_info, socket)
      end

      @impl IndexImpl
      defdelegate auix_mount(caller, params, session, socket), to: IndexImpl

      @impl IndexImpl
      defdelegate auix_handle_params(caller, params, url, socket), to: IndexImpl

      @impl IndexImpl
      defdelegate auix_handle_event(caller, event, params, socket), to: IndexImpl

      @impl IndexImpl
      defdelegate auix_handle_info(caller, input, socket), to: IndexImpl

      @impl IndexImpl
      defdelegate auix_apply_action(socket, caller, action, params), to: IndexImpl

      defoverridable auix_mount: 4,
                     auix_handle_params: 4,
                     auix_handle_event: 4,
                     auix_handle_info: 3,
                     auix_apply_action: 4
    end
  end

  @doc """
  Initializes the LiveView socket for the index page by streaming entities.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `params` (map()) - URL/query parameters.
  - `session` (map()) - Session data.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  `{:ok, Socket.t()}` - The initialized socket with streamed entities from context.

  """
  @spec auix_mount(module(), map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def auix_mount(_caller, _params, _session, %{assigns: %{auix: auix}} = socket) do
    {:ok, stream(socket, auix.list_key, apply(auix.modules.context, auix.list_function, []))}
  end

  @doc """
  Handles URL parameter changes and updates socket state.

  Updates routing stack, assigns form component, and applies the current action based on
  live_action and parameters.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `params` (map()) - URL/query parameters.
  - `url` (binary()) - Current URL.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with routing stack, form component, and action applied.

  """
  @spec auix_handle_params(module(), map(), binary(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_params(caller, params, url, %{assigns: %{auix: auix}} = socket) do
    form_component = ModulesGenerator.module_name(auix, ".FormComponent")

    {:noreply,
     socket
     |> assign_auix(:form_component, form_component)
     |> assign_auix_current_path(url)
     |> assign_auix_routing_stack(params, %{
       type: :patch,
       path: "/#{auix.link_prefix}#{auix.source}"
     })
     |> render_with(&Renderer.render/1)
     |> caller.auix_apply_action(caller, socket.assigns.live_action, params)}
  end

  @doc """
  Handles LiveView events for the index page.

  Supports delete events with custom context/functions or default auix context,
  forward/back navigation events, and routing events.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `event` (binary()) - Event name (`"delete"`, `"auix_route_forward"`, `"auix_route_back"`).
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after event handling.

  """
  @spec auix_handle_event(module(), binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_event(
        _caller,
        "delete",
        %{
          "id" => id,
          "context" => context_name,
          "get_function" => get_function_name,
          "delete_function" => delete_function_name
        },
        socket
      ) do
    context = String.to_existing_atom(context_name)
    get_function = String.to_existing_atom(get_function_name)
    delete_function = String.to_existing_atom(delete_function_name)

    socket =
      with %{} = entity <- apply(context, get_function, [id]),
           {:ok, _changeset} <- apply(context, delete_function, [entity]) do
        socket
        |> put_flash(:info, "Item deleted successfully")
        |> push_patch(to: socket.assigns.auix[:_current_path])
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  def auix_handle_event(_caller, "delete", %{"id" => id}, %{assigns: %{auix: auix}} = socket) do
    instance = apply(auix.modules.context, auix.get_function, [id])
    {:ok, _} = apply(auix.modules.context, auix.delete_function, [instance])
    {:noreply, stream_delete(socket, auix.list_key, instance)}
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

  @doc """
  Handles info messages for the LiveView.

  Processes save notifications by inserting entities into the stream, ignores other messages.

  ## Parameters
  - `caller` (module()) - The calling module.
  - `event_info` (term()) - Info message, typically `{component, {:saved, entity}}`.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with entity inserted into stream or unchanged.

  """
  @spec auix_handle_info(module(), term(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_info(
        _caller,
        {_component, {:saved, entity}},
        %{assigns: %{auix: auix}} = socket
      ) do
    {:noreply, stream_insert(socket, auix.list_key, entity)}
  end

  def auix_handle_info(_caller, _input, socket) do
    {:noreply, socket}
  end

  @doc """
  Applies the given action to the socket state.

  Handles `:edit` action by fetching and assigning entity, `:new` action by creating new entity,
  and `:index` action by clearing entity assignment.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket.
  - `caller` (module()) - The calling module.
  - `action` (atom()) - Action to apply (`:edit`, `:new`, `:index`).
  - `params` (map()) - Action parameters containing entity ID for `:edit`.

  ## Returns
  `Socket.t()` - Updated socket with action-specific entity assignment.

  """
  @spec auix_apply_action(Socket.t(), module(), atom(), map()) :: Socket.t()
  def auix_apply_action(
        %{assigns: %{auix: auix}} = socket,
        _caller,
        :edit,
        %{"id" => id} = _params
      ) do
    assign_auix(
      socket,
      :entity,
      apply(auix.modules.context, auix.get_function, [
        id,
        [preload: auix.preload]
      ])
    )
  end

  def auix_apply_action(%{assigns: %{auix: auix}} = socket, _caller, :new, params) do
    assign_new_entity(
      socket,
      params,
      apply(auix.modules.context, auix.new_function, [
        %{},
        [preload: auix.preload]
      ])
    )
  end

  def auix_apply_action(socket, _caller, :index, _params) do
    assign_auix(socket, :entity, nil)
  end
end
