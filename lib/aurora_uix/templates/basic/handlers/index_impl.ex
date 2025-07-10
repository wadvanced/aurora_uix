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
  - `params` (map()) - URL/query parameters.
  - `session` (map()) - Session data.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  - `{:ok, Socket.t()}`: The initialized socket.

  ## Examples

      iex> auix_mount(%{}, %{}, %Phoenix.LiveView.Socket{assigns: %{auix: %{list_key: :items, modules: %{context: MyApp.Context, list_function: :list_items}}}})
      {:ok, %Phoenix.LiveView.Socket{}}

  """
  @callback auix_mount(
              caller :: module,
              params :: map(),
              session :: map(),
              socket :: Socket.t()
            ) ::
              {:ok, Socket.t()}

  @doc """
  Handles URL parameter changes, updates routing stack, and assigns form component.

  ## Parameters
  - `params` (map()) - URL/query parameters.
  - `url` (binary()) - Current URL.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  - `{:noreply, Socket.t()}`: Updated socket.



  """
  @callback auix_handle_params(
              caller :: module(),
              params :: map(),
              url :: binary(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()}

  @doc """
  Handles all LiveView events for the index page, including deletion, forward navigation, and back navigation.

  ## Parameters
  - `event` (binary()) - Event name.
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  - `{:noreply, Socket.t()}`: Updated socket.

  """
  @callback auix_handle_event(
              caller :: module(),
              event :: binary(),
              params :: map(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()}

  @doc """
  Handles info messages for the LiveView, such as entity save notifications.

  ## Parameters
  - `event_info` (term()) - Info message, e.g., `{_component, {:saved, entity}}`.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  - `{:noreply, Socket.t()}`: Updated socket.

  """
  @callback auix_handle_info(
              caller :: module(),
              event_info :: term(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()}

  @doc """
  Applies the given action to the socket, such as assigning an entity for edit or new actions.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket.
  - `action` (atom()) - Action to apply (`:edit`, `:new`, `:index`).
  - `params` (map()) - Action parameters.

  ## Returns
  - `Socket.t()`: Updated socket.

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

      alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
      alias Aurora.Uix.Web.Templates.Basic.Renderer
      alias Aurora.Uix.Web.Templates.Basic.Handlers.IndexImpl

      @impl Phoenix.LiveView
      def mount(params, session, socket) do
        auix_mount(__MODULE__, params, session, socket)
      end

      @impl Phoenix.LiveView
      def handle_params(params, url, socket) do
        auix_handle_params(__MODULE__, params, url, socket)
      end

      @impl Phoenix.LiveView
      def handle_event(event, params, socket) do
        auix_handle_event(__MODULE__, event, params, socket)
      end

      @impl Phoenix.LiveView
      def handle_info(event_info, socket) do
        auix_handle_info(__MODULE__, event_info, socket)
      end

      @impl IndexImpl
      defdelegate auix_mount(caller, params, session, socket), to: IndexImpl

      @doc """
      Handles URL parameter changes, updates routing stack, and assigns form component.

      ## Parameters
      - `params`: URL/query parameters (map)
      - `url`: Current URL (String.t)
      - `socket`: LiveView socket with `:auix` assigns (Phoenix.LiveView.Socket.t)

      ## Returns
      - `{:noreply, Phoenix.LiveView.Socket.t}`: Updated socket
      """
      @impl IndexImpl
      defdelegate auix_handle_params(caller, params, url, socket), to: IndexImpl

      @doc """
      Handles all LiveView events for the index page, including deletion, forward navigation, and back navigation.

      - For the `"delete"` event, if params include `"context"`, `"get_function"`, and `"delete_function"`, it uses those to fetch and delete the entity, then flashes a message and pushes a patch. If only `"id"` is present, it uses the auix context and functions to delete and remove from the stream.
      - For the `"auix_route_forward"` event, it handles navigation and patch route types.
      - For the `"auix_route_back"` event, it handles back navigation.

      ## Parameters
      - `event`: Event name (String.t)
      - `params`: Event parameters (map)
      - `socket`: LiveView socket (Phoenix.LiveView.Socket.t)

      ## Returns
      - `{:noreply, Phoenix.LiveView.Socket.t}`: Updated socket
      """
      @impl IndexImpl
      defdelegate auix_handle_event(caller, event, params, socket), to: IndexImpl

      @doc """
      Handles info messages for the LiveView. If the message is a tuple of the form `{_component, {:saved, entity}}`,
      it inserts the entity into the stream. Otherwise, it returns the unchanged socket.

      ## Parameters
      - `{_component, {:saved, entity}}` or any other message: Info message (tuple or any)
      - `socket`: LiveView socket with `:auix` assigns (Phoenix.LiveView.Socket.t)

      ## Returns
      - `{:noreply, Phoenix.LiveView.Socket.t}`: Updated socket
      """
      @impl IndexImpl
      defdelegate auix_handle_info(caller, input, socket), to: IndexImpl

      @impl IndexImpl
      defdelegate auix_apply_action(socket, caller, action, params), to: IndexImpl
    end
  end

  def auix_mount(_caller, _params, _session, %{assigns: %{auix: auix}} = socket) do
    {:ok, stream(socket, auix.list_key, apply(auix.modules.context, auix.list_function, []))}
  end

  def auix_handle_params(caller, params, url, %{assigns: %{auix: auix}} = socket) do
    form_component = ModulesGenerator.module_name(auix, ".FormComponent")

    {:noreply,
     socket
     |> assign_index_row_click(params)
     |> assign_auix(:form_component, form_component)
     |> assign_auix_current_path(url)
     |> assign_auix_routing_stack(params, %{
       type: :patch,
       path: "/#{auix.link_prefix}#{auix.source}"
     })
     |> render_with(&Renderer.render/1)
     |> caller.auix_apply_action(caller, socket.assigns.live_action, params)}
  end

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

  # Assigns new entity for new action.
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

  # Clears entity for index action.
  def auix_apply_action(socket, _caller, :index, _params) do
    assign_auix(socket, :entity, nil)
  end
end
