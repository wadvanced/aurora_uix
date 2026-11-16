defmodule Aurora.Uix.Templates.Basic.Handlers.IndexImpl do
  @moduledoc """
  Behaviour and macro for implementing index page handlers in Aurora UIX LiveView templates.

  Provides a set of callbacks and a `__using__/1` macro to standardize the handling of mount,
  parameter changes, events, info messages, and action application for index pages.

  ## Key Features

  - Defines required callbacks for index page lifecycle and event handling
  - Supplies a macro to inject default implementations and imports for LiveView modules
  - Integrates with Aurora UIX context and module generators for dynamic entity management
  - Supports streaming, patching, and navigation for index resources
  - Handles pagination, filtering, column-header sorting, and item selection for large datasets
  - Provides async operations for bulk actions (select all, delete all)
  - Subscribes to its schema's `Aurora.Uix.Events` topic when connected, publishes its own deletes, and answers the `refresh` and `reset_selection` commands

  ## Key Constraints

  - Expects the `:auix` assign to be present in the LiveView socket
  - Designed for use with Phoenix LiveView and Aurora UIX context modules
  - Assumes certain structure in the `auix` assign (e.g., `modules.context`, `source_key`, etc.)
  - Requires resource modules to implement CRUD operations via Aurora.Uix.Integration.Crud
  - Built-in publishers use `broadcast_from`, so the view that made a change refreshes locally and never receives its own event
  - The list itself is run by Aurora.Uix.Templates.Basic.Handlers.IndexList.
  """
  use Aurora.Uix.GettextResolver

  import Aurora.Uix.Integration.Crud
  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Navigation
  alias Aurora.Uix.Templates.Basic.Actions.Index, as: IndexActions
  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Aurora.Uix.Templates.Basic.Handlers.IndexList
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer
  alias Aurora.Uix.Templates.ThemeHelper

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @doc """
  Initializes the LiveView socket for the index page.

  ## Parameters
  - `params` (map()) - URL/query parameters.
  - `session` (map()) - Session data.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  `{:ok, Socket.t()}` - The initialized socket with streamed entities from context.
  """
  @callback auix_mount(params :: map(), session :: map(), socket :: Socket.t()) ::
              {:ok, Socket.t()}

  @doc """
  Handles URL parameter changes, updates routing stack, and assigns form component.

  ## Parameters
  - `params` (map()) - URL/query parameters.
  - `url` (binary()) - Current URL.
  - `socket` (Socket.t()) - LiveView socket with `:auix` assigns.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with routing stack and form component.
  """
  @callback auix_handle_params(params :: map(), url :: binary(), socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @doc """
  Internally handles all LiveView events for the index page.

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

  @doc """
  Handles info messages for the index LiveView.

  ## Parameters
  - `message` (term()) - Info message.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after handling message.
  """
  @callback auix_handle_info(message :: term(), socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @doc """
  Handles async task results for the index LiveView.

  ## Parameters
  - `task` (atom()) - Task name.
  - `result` (term()) - Async task result.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after handling async result.
  """
  @callback auix_handle_async(task :: atom(), result :: term(), socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @doc """
  Applies the given action to the socket.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket.
  - `params` (map()) - Action parameters.

  ## Returns
  Socket.t() - Updated socket with action-specific assigns.
  """
  @callback apply_action(
              socket :: Socket.t(),
              params :: map()
            ) ::
              Socket.t()

  @list_events IndexList.events()

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
      @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
      def mount(params, session, socket), do: auix_mount(params, session, socket)

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
      @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_event(event, params, socket), do: auix_handle_event(event, params, socket)

      @doc false
      @impl LiveView
      @spec handle_info(term(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_info(input, socket), do: auix_handle_info(input, socket)

      @doc false
      @impl LiveView
      @spec handle_async(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_async(task, result, socket), do: auix_handle_async(task, result, socket)

      @doc false
      @impl IndexImpl
      defdelegate auix_mount(params, session, socket), to: IndexImpl

      @doc false
      @impl IndexImpl
      defdelegate auix_handle_params(params, url, socket), to: IndexImpl

      @doc false
      @impl IndexImpl
      defdelegate auix_handle_event(event, params, socket), to: IndexImpl

      @doc false
      @impl IndexImpl
      defdelegate auix_handle_info(message, socket), to: IndexImpl

      @doc false
      @impl IndexImpl
      defdelegate auix_handle_async(task, result, socket), to: IndexImpl

      @doc false
      @impl IndexImpl
      defdelegate apply_action(socket, params), to: IndexImpl

      defoverridable Phoenix.LiveView
      defoverridable auix_mount: 3
      defoverridable auix_handle_params: 3
      defoverridable auix_handle_event: 3
      defoverridable auix_handle_info: 2
      defoverridable auix_handle_async: 3
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
  @spec auix_mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def auix_mount(params, _session, %{assigns: %{auix: auix}} = socket) do
    form_component = auix.artifacts.form_component
    show_component = auix.artifacts.show_component

    index_form_id = "auix-index-form-#{auix.module}-#{auix.layout_type}"

    {
      :ok,
      socket
      |> subscribe_to_changes()
      |> assign_auix(:form_component, form_component)
      |> assign_auix(:show_component, show_component)
      |> assign_auix(:index_form_id, index_form_id)
      |> assign_auix(:item_index, -1)
      |> IndexList.init(params, &IndexActions.set_actions/1)
    }
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
  def auix_handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_auix(:enable_viewport?, true)
     |> assign_auix_current_path(url)
     |> assign_auix_uri_path()
     |> assign_auix_index_new_link()
     |> push_event(:set_html_theme_name, %{theme_name: ThemeHelper.theme_name()})
     |> assign_index_routing_stack(params)
     |> render_with(&Renderer.render/1)}
  end

  @doc """
  Handles LiveView events for the index page.

  Supports delete events with custom context/functions or default auix context,
  forward/back navigation events, routing events, filtering, pagination, and selection.

  ## Parameters
  - `event` (binary()) - Event name.
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after event handling.
  """
  @spec auix_handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_event(
        "delete",
        %{
          "id" => id,
          "get_function" => get_function_string,
          "delete_function" => delete_function_string
        },
        %{assigns: %{auix: %{navigation: nav}}} = socket
      ) do
    {get_function, _} = Code.eval_string(get_function_string)
    {delete_function, _} = Code.eval_string(delete_function_string)

    get_opts = backend_socket_opts(socket, get_function)
    delete_opts = backend_socket_opts(socket, delete_function)

    socket =
      with %{} = entity <- apply_get_function(get_function, id, get_opts),
           {:ok, _changeset} <- apply_delete_function(delete_function, entity, delete_opts) do
        publish_child_deleted(entity)

        socket
        |> put_flash(:info, dt("Item deleted successfully"))
        |> push_patch(to: nav.current_path)
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  def auix_handle_event(
        "delete",
        %{"id" => id},
        %{assigns: %{auix: _auix, streams: _streams}} = socket
      ) do
    {socket, _ids} = IndexList.delete(socket, id)
    {:noreply, put_flash(socket, :info, dt("Item deleted successfully"))}
  end

  def auix_handle_event(
        "auix_route_forward",
        %{"route_type" => "navigate", "route_path" => path},
        socket
      ) do
    {:noreply, auix_route_forward(socket, to: path)}
  end

  def auix_handle_event(
        "auix_route_forward",
        %{"route_type" => "patch", "route_path" => path},
        socket
      ) do
    {:noreply, auix_route_forward(socket, patch: path)}
  end

  def auix_handle_event("auix_route_back", _params, socket) do
    {:noreply,
     socket
     |> IndexList.load_items()
     |> auix_route_back()}
  end

  def auix_handle_event(event, params, socket) when event in @list_events,
    do: IndexList.handle_event(event, params, socket)

  def auix_handle_event(
        "pagination_to_page",
        %{"page" => page},
        %{assigns: %{auix: %{pagination: %Pagination{}, navigation: nav}}} = socket
      ) do
    {:noreply, auix_route_forward(socket, patch: "#{Navigation.path(nav, :index)}?page=#{page}")}
  end

  def auix_handle_event("pagination_to_page", _params, socket), do: {:noreply, socket}

  def auix_handle_event(
        "pagination_previous",
        params,
        %{
          assigns: %{
            auix: %{
              pagination: %Pagination{} = pagination,
              layout_options: %{pagination_disabled?: pagination_disabled?},
              navigation: nav
            }
          }
        } = socket
      ) do
    if pagination_disabled? or Map.get(params, "pagination_disabled?") do
      {:noreply, paginate(socket, pagination.page - 1, Map.get(params, "items_per_page"))}
    else
      {:noreply,
       auix_route_forward(socket,
         patch: "#{Navigation.path(nav, :index)}?page=#{IndexList.previous_page(pagination)}"
       )}
    end
  end

  def auix_handle_event("pagination_previous", _params, socket), do: {:noreply, socket}

  def auix_handle_event(
        "pagination_next",
        params,
        %{
          assigns: %{
            auix: %{
              pagination: %Pagination{} = pagination,
              layout_options: %{pagination_disabled?: pagination_disabled?},
              navigation: nav
            }
          }
        } = socket
      ) do
    if pagination_disabled? or Map.get(params, "pagination_disabled?") do
      {:noreply, paginate(socket, pagination.page + 1, Map.get(params, "items_per_page"))}
    else
      {:noreply,
       auix_route_forward(socket,
         patch: "#{Navigation.path(nav, :index)}?page=#{IndexList.next_page(pagination)}"
       )}
    end
  end

  def auix_handle_event("pagination_next", _params, socket), do: {:noreply, socket}

  def auix_handle_event(
        "read_indexed_entry",
        %{"page" => new_page, "index" => index},
        socket
      ) do
    int_new_page = String.to_integer(new_page)
    int_index = String.to_integer(index)

    %{assigns: %{auix: %{primary_keys: primary_keys, navigation: nav}}} =
      new_socket = IndexList.load_page(socket, int_new_page)

    case Map.get(primary_keys, int_index) do
      nil ->
        {:noreply, new_socket}

      id ->
        found_id =
          id
          |> List.first()
          |> elem(1)

        {:noreply,
         push_patch(new_socket, to: Navigation.path(nav, record_action(socket), found_id))}
    end
  end

  @doc """
  Handles info messages for the LiveView. Re-reads the current page after a save notification, an
  `%Aurora.Uix.Event{}` on the schema's topic (dropping deleted ids from the selection first;
  an open show of an affected record re-reads it on `:updated` and closes on `:deleted`, and an
  open form on an affected record shows a flash), or the `refresh` command; the `reset_selection`
  command clears the selection, then re-reads.
  Other messages are ignored.

  ## Parameters
  - `event_info` (term()) - Info message: `{component, {:saved, entity}}`, an
    `%Aurora.Uix.Event{}`, or an `Aurora.Uix.Events` command.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with the current page refreshed or unchanged.
  """
  @spec auix_handle_info(term(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_info(
        {_component, {:saved, _entity}},
        %{assigns: %{auix: _auix, streams: _streams}} = socket
      ) do
    {:noreply, IndexList.refresh_current_page(socket)}
  end

  def auix_handle_info(%Event{} = event, socket) do
    {:noreply,
     socket
     |> IndexList.apply_event(event)
     |> react_to_open_entity(event)}
  end

  def auix_handle_info({Events, :refresh}, socket),
    do: {:noreply, IndexList.refresh_current_page(socket)}

  def auix_handle_info({Events, :reset_selection}, socket) do
    {:noreply, IndexList.reset_selection(socket)}
  end

  def auix_handle_info(_input, socket) do
    {:noreply, socket}
  end

  @doc """
  Handles async results for selection operations.

  Selecting all items in large datasets is time consuming, therefore it is handled asynchronously.

  ## Parameters
  - `task` (atom()) - Task name (`:auix_selection_toggle_all` or `:auix_selection_delete_all`).
  - `result` (term()) - Result of the async task.
  - `socket` (Socket.t()) - LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with the new selection.
  """
  @spec auix_handle_async(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_async(task, result, socket), do: IndexList.handle_async(task, result, socket)

  @doc """
  Applies the given action to the socket state.

  Handles `:edit`, `:show`, `:show_edit` actions by fetching and assigning entity, `:new` action
  by creating new entity, and `:index` action by clearing entity assignment or paginating.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket.
  - `params` (map()) - Action parameters containing entity ID for actions that require it.

  ## Returns
  Socket.t() - Updated socket with action-specific entity assignment.
  """
  @spec apply_action(Socket.t(), map()) :: Socket.t()
  def apply_action(
        %{assigns: %{auix: auix, live_action: :edit}} = socket,
        %{"id" => id} = params
      ) do
    get_opts =
      socket
      |> backend_socket_opts(auix.get_function)
      |> Keyword.put(:preload, auix.preload)

    new_entity = apply_get_function(auix.get_function, id, get_opts)

    socket
    |> assign_new_entity(params, new_entity)
    |> assign_item_index()
    |> assign_live_component()
  end

  def apply_action(
        %{assigns: %{auix: auix, live_action: :show}} = socket,
        %{"id" => id} = params
      ) do
    get_opts =
      socket
      |> backend_socket_opts(auix.get_function)
      |> Keyword.put(:preload, auix.preload)

    new_entity = apply_get_function(auix.get_function, id, get_opts)

    socket
    |> assign_new_entity(params, new_entity)
    |> assign_item_index()
    |> assign_live_component()
  end

  def apply_action(
        %{assigns: %{auix: auix, live_action: :show_edit}} = socket,
        %{"id" => id} = params
      ) do
    get_opts =
      socket
      |> backend_socket_opts(auix.get_function)
      |> Keyword.put(:preload, auix.preload)

    new_entity = apply_get_function(auix.get_function, id, get_opts)

    socket
    |> assign_new_entity(params, new_entity)
    |> assign_item_index()
    |> assign_live_component()
  end

  def apply_action(%{assigns: %{auix: auix, live_action: :new}} = socket, params) do
    new_opts =
      socket
      |> backend_socket_opts(auix.new_function)
      |> Keyword.put(:preload, auix.preload)

    new_entity = apply_new_function(auix.new_function, %{}, new_opts)

    socket
    |> assign_new_entity(params, new_entity)
    |> assign_item_index()
    |> assign_live_component()
  end

  def apply_action(%{assigns: %{live_action: :index}} = socket, %{"page" => page}) do
    page = String.to_integer(page)
    paginate(socket, page, nil)
  end

  def apply_action(%{assigns: %{live_action: :index}} = socket, _params) do
    assign_auix(socket, :entity, nil)
  end

  ## PRIVATE
  @spec subscribe_to_changes(Socket.t()) :: Socket.t()
  defp subscribe_to_changes(%{assigns: %{auix: auix}} = socket) do
    if connected?(socket), do: :ok = auix |> IndexList.resource_schema() |> Events.subscribe()
    socket
  end

  @spec publish_child_deleted(struct()) :: :ok | {:error, term()}
  defp publish_child_deleted(%schema{} = entity) do
    ids = [BasicHelpers.primary_key_value(entity, schema.__schema__(:primary_key))]
    Events.deleted(schema, ids, from: self())
  end

  @spec react_to_open_entity(Socket.t(), Event.t()) :: Socket.t()
  defp react_to_open_entity(
         %{assigns: %{live_action: live_action, auix: auix}} = socket,
         %Event{action: action, ids: ids}
       )
       when live_action in [:show, :edit, :show_edit] and action in [:updated, :deleted] do
    entity_id = BasicHelpers.primary_key_value(auix.entity, auix.primary_key)

    if not is_nil(entity_id) and entity_id in ids,
      do: react_to_change(socket, live_action, action, entity_id),
      else: socket
  end

  defp react_to_open_entity(socket, _event), do: socket

  @spec react_to_change(Socket.t(), atom(), Event.action(), term()) :: Socket.t()
  defp react_to_change(%{assigns: %{auix: auix}} = socket, :show, :updated, entity_id) do
    get_opts =
      socket
      |> backend_socket_opts(auix.get_function)
      |> Keyword.put(:preload, auix.preload)

    case apply_get_function(auix.get_function, entity_id, get_opts) do
      nil -> socket
      entity -> assign_auix(socket, :entity, entity)
    end
  end

  defp react_to_change(
         %{assigns: %{auix: %{navigation: nav}}} = socket,
         :show,
         :deleted,
         _entity_id
       ) do
    socket
    |> put_flash(:info, dt("Item deleted successfully"))
    |> push_patch(to: Navigation.path(nav, :index))
  end

  defp react_to_change(%{assigns: %{auix: auix}} = socket, _form_action, :updated, _entity_id),
    do: put_flash(socket, :info, "#{auix.name} updated successfully")

  defp react_to_change(socket, _form_action, :deleted, _entity_id),
    do: put_flash(socket, :info, dt("Item deleted successfully"))

  @spec paginate(Socket.t(), integer(), integer() | nil) :: Socket.t()
  defp paginate(
         %{
           assigns: %{
             live_action: :index,
             auix: %{pagination: %{per_page: per_page}}
           }
         } = socket,
         page,
         items_per_page
       )
       when is_nil(items_per_page) or items_per_page == per_page do
    socket
    |> IndexList.paginate(page, items_per_page)
    |> assign_auix(:entity, nil)
  end

  # This one will be triggered if the items_per_page is changed.
  # That is a typical case when the elements are rendered in a small device, and fallback to infinity scroll.
  defp paginate(%{assigns: %{live_action: :index}} = socket, page, items_per_page) do
    IndexList.paginate(socket, page, items_per_page)
  end

  @spec assign_live_component(Socket.t()) :: Socket.t()
  defp assign_live_component(%{assigns: %{auix: auix, live_action: :show}} = socket) do
    socket
    |> assign_auix(:live_component, auix.artifacts.show_component)
    |> assign_auix(:live_component_binding, live_component_binding(auix, :show_component, :show))
  end

  defp assign_live_component(%{assigns: %{auix: auix}} = socket) do
    socket
    |> assign_auix(:live_component, auix.artifacts.form_component)
    |> assign_auix(:live_component_binding, live_component_binding(auix, :form_component, :form))
  end

  # A component this module generated already holds these options.
  @spec live_component_binding(map(), atom(), :form | :show) :: map()
  defp live_component_binding(%{used: used} = auix, kind, layout_type) do
    if kind in used,
      do: BasicHelpers.component_binding(auix.configurations, auix.resource_name, layout_type),
      else: %{}
  end

  @spec assign_index_routing_stack(Socket.t(), map()) :: Socket.t()
  defp assign_index_routing_stack(%{assigns: %{auix: %{navigation: nav}}} = socket, params) do
    assign_auix_routing_stack(socket, params, %{type: :patch, path: Navigation.path(nav, :index)})
  end

  @spec record_action(Socket.t()) :: :show | :edit | :show_edit
  defp record_action(%{assigns: %{live_action: :show_edit}}), do: :show_edit
  defp record_action(%{assigns: %{live_action: :edit}}), do: :edit
  defp record_action(_socket), do: :show
end
