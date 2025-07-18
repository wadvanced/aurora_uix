defmodule Aurora.Uix.Templates.Basic.Handlers.IndexImpl do
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

  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Aurora.Uix.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Templates.Basic.Renderer

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

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
  @callback auix_handle_params(params :: map(), url :: binary(), socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @doc """
  Applies the given action to the socket.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket.
  - `params` (map()) - Action parameters.

  ## Returns
  `Socket.t()` - Updated socket with action-specific assigns.

  """
  @callback apply_action(
              socket :: Socket.t(),
              params :: map()
            ) ::
              Socket.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour IndexImpl
      @behaviour Phoenix.LiveView

      import Aurora.Uix.Templates.Basic.Helpers
      import Phoenix.LiveView

      alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
      alias Aurora.Uix.Templates.Basic.ModulesGenerator
      alias Aurora.Uix.Templates.Basic.Renderer

      @doc false
      @impl LiveView
      defdelegate mount(params, session, socket), to: IndexImpl

      @doc false
      @impl LiveView
      @spec handle_params(map(), binary(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_params(params, url, socket) do
        {:noreply,
         params
         |> auix_handle_params(url, socket)
         |> elem(1)
         |> then(&apply_action(&1, params))}
      end

      @doc false
      @impl LiveView
      defdelegate handle_event(event, params, socket), to: IndexImpl

      @doc false
      @impl LiveView
      defdelegate handle_info(input, socket), to: IndexImpl

      @doc false
      @impl IndexImpl
      defdelegate auix_handle_params(params, url, socket), to: IndexImpl

      @doc false
      @impl IndexImpl
      defdelegate apply_action(socket, params), to: IndexImpl

      defoverridable Phoenix.LiveView
      defoverridable apply_action: 2
    end
  end

  @doc """
  Initializes the LiveView socket for the index page by streaming entities.

  ## Parameters
  - `params` (map()) - URL/query parameters.
  - `session` (map()) - Session data.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  `{:ok, Socket.t()}` - The initialized socket with streamed entities from context.

  """
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, %{assigns: %{auix: auix}} = socket) do
    layout_opts = Map.get(auix.layout_tree, :opts, [])

    opts =
      auix
      |> get_in([:configurations, auix.resource_name, :resource_config])
      |> Map.get(:opts, [])
      |> Keyword.merge(layout_opts)

    {:ok,
     stream(
       socket,
       auix.list_key,
       auix.list_function.(
         order_by: Keyword.get(opts, :order_by, []),
         where: Keyword.get(opts, :where, [])
       )
     )}
  end

  @doc """
  Handles URL parameter changes and updates socket state.

  Updates routing stack, assigns form component, and applies the current action based on
  live_action and parameters.

  ## Parameters
  - `params` (map()) - URL/query parameters.
  - `url` (binary()) - Current URL.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with routing stack, form component, and action applied.

  """
  @spec auix_handle_params(map(), binary(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_params(params, url, %{assigns: %{auix: auix}} = socket) do
    form_component = ModulesGenerator.module_name(auix, ".FormComponent")

    {:noreply,
     socket
     |> assign_auix(:form_component, form_component)
     |> assign_auix_current_path(url)
     |> assign_auix_routing_stack(params, %{
       type: :patch,
       path: "/#{auix.link_prefix}#{auix.source}"
     })
     |> render_with(&Renderer.render/1)}
  end

  @doc """
  Handles LiveView events for the index page.

  Supports delete events with custom context/functions or default auix context,
  forward/back navigation events, and routing events.

  ## Parameters
  - `event` (binary()) - Event name (`"delete"`, `"auix_route_forward"`, `"auix_route_back"`).
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after event handling.

  """
  @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_event(
        "delete",
        %{
          "id" => id,
          "get_function" => get_function_string,
          "delete_function" => delete_function_string
        },
        socket
      ) do
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

  def handle_event("delete", %{"id" => id}, %{assigns: %{auix: auix}} = socket) do
    entity = auix.get_function.(id)
    {:ok, _} = auix.delete_function.(entity)
    {:noreply, stream_delete(socket, auix.list_key, entity)}
  end

  def handle_event(
        "auix_route_forward",
        %{"route_type" => "navigate", "route_path" => path},
        socket
      ) do
    {:noreply, auix_route_forward(socket, to: path)}
  end

  def handle_event(
        "auix_route_forward",
        %{"route_type" => "patch", "route_path" => path},
        socket
      ) do
    {:noreply, auix_route_forward(socket, patch: path)}
  end

  def handle_event("auix_route_back", _params, socket) do
    {:noreply, auix_route_back(socket)}
  end

  @doc """
  Handles info messages for the LiveView.

  Processes save notifications by inserting entities into the stream, ignores other messages.

  ## Parameters
  - `event_info` (term()) - Info message, typically `{component, {:saved, entity}}`.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with entity inserted into stream or unchanged.

  """
  @spec handle_info(term(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_info(
        {_component, {:saved, entity}},
        %{assigns: %{auix: auix}} = socket
      ) do
    {:noreply, stream_insert(socket, auix.list_key, entity)}
  end

  def handle_info(_input, socket) do
    {:noreply, socket}
  end

  @doc """
  Applies the given action to the socket state.

  Handles `:edit` action by fetching and assigning entity, `:new` action by creating new entity,
  and `:index` action by clearing entity assignment.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket.
  - `params` (map()) - Action parameters containing entity ID for `:edit`.

  ## Returns
  `Socket.t()` - Updated socket with action-specific entity assignment.

  """
  @spec apply_action(Socket.t(), map()) :: Socket.t()
  def apply_action(
        %{assigns: %{auix: auix, live_action: :edit}} = socket,
        %{"id" => id} = _params
      ) do
    assign_auix(
      socket,
      :entity,
      auix.get_function.(id, preload: auix.preload)
    )
  end

  def apply_action(%{assigns: %{auix: auix, live_action: :new}} = socket, params) do
    assign_new_entity(socket, params, auix.new_function.(%{}, preload: auix.preload))
  end

  def apply_action(%{assigns: %{live_action: :index}} = socket, _params) do
    assign_auix(socket, :entity, nil)
  end
end
