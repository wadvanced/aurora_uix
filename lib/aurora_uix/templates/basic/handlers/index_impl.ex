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
  """
  use Aurora.Uix.GettextResolver

  import Aurora.Uix.Integration.Crud
  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.LiveView
  import Phoenix.Component

  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Filter
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Selection
  alias Aurora.Uix.Templates.Basic.Actions.Index, as: IndexActions
  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.ModulesGenerator
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

  @allowed_query_options [:where, :or_where, :order_by, :paginate, :select, :preload]

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
    form_component = ModulesGenerator.module_name(auix, ".FormComponent")
    show_component = ModulesGenerator.module_name(auix, ".ShowComponent")

    index_form_id = "auix-index-form-#{auix.module}-#{auix.layout_type}"

    {
      :ok,
      socket
      |> subscribe_to_changes()
      |> assign_auix(:form_component, form_component)
      |> assign_auix(:show_component, show_component)
      |> assign_auix(:filters_enabled?, false)
      |> assign_auix(:filters_where, [])
      |> assign_auix(:sort, nil)
      |> assign_auix(:selection, Selection.new())
      |> assign_auix(:enable_viewport?, true)
      |> assign_auix(:list_function_selected, auix.list_function_paginated)
      |> assign_auix(:reset_stream?, true)
      |> assign_auix(:index_form_id, index_form_id)
      |> assign_auix(:empty_list?, true)
      |> assign_auix(:item_index, -1)
      |> assign_layout_options()
      |> IndexActions.set_actions()
      |> assign_index_fields()
      |> assign_filters()
      |> prepare_initial_pagination(params)
      |> load_items()
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
     |> then(
       &assign_auix_routing_stack(&1, params, %{
         type: :patch,
         path: "/#{&1.assigns.auix.uri_path}"
       })
     )
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
        socket
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
        |> push_patch(to: socket.assigns.auix[:_current_path])
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  def auix_handle_event(
        "delete",
        %{"id" => id},
        %{assigns: %{auix: auix, streams: _streams}} = socket
      ) do
    get_opts = backend_socket_opts(socket, auix.get_function)
    delete_opts = backend_socket_opts(socket, auix.delete_function)
    entity = apply_get_function(auix.get_function, id, get_opts)
    {:ok, _} = apply_delete_function(auix.delete_function, entity, delete_opts)
    publish_deleted(auix, [BasicHelpers.primary_key_value(entity, auix.primary_key)])

    {:noreply,
     socket
     |> stream_delete(auix.source_key, entity)
     |> assign_selected_states()
     |> put_flash(:info, dt("Item deleted successfully"))
     |> refresh_current_page()}
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
     |> load_items()
     |> auix_route_back()}
  end

  def auix_handle_event(
        "filter-toggle",
        _params,
        %{assigns: %{auix: %{filters_enabled?: filters_enabled?}}} = socket
      ) do
    {:noreply, assign_auix(socket, :filters_enabled?, !filters_enabled?)}
  end

  def auix_handle_event(
        "filters-clear",
        _params,
        %{assigns: %{auix: %{filters: filters}}} = socket
      ) do
    {:noreply,
     filters
     |> Enum.reduce(socket, fn {key, _filter}, acc_socket ->
       update_filter(acc_socket, key, %{condition: :eq, from: nil, to: nil})
     end)
     |> assign_filters_selected_count()}
  end

  def auix_handle_event(
        "filters-submit",
        _params,
        %{assigns: %{auix: %{filters: filters}}} = socket
      ) do
    filters = get_selected_filters(filters)

    {:noreply,
     socket
     |> assign_filters_selected_count()
     |> assign_auix(:filters_where, filters)
     |> prepare_query_options()
     |> refresh_current_page()}
  end

  def auix_handle_event("index-sort", %{"key" => key}, %{assigns: %{auix: auix}} = socket) do
    case Enum.find(auix.index_fields, &(&1.sortable? and to_string(&1.key) == key)) do
      nil ->
        {:noreply, socket}

      %{key: field_key} ->
        {:noreply,
         socket
         |> assign_auix(:sort, next_sort(auix.sort, field_key))
         |> prepare_query_options()
         |> refresh_current_page()}
    end
  end

  def auix_handle_event(
        "index-layout-change",
        %{"_target" => ["filter_condition__" <> filter_key = condition_key]} = params,
        socket
      ) do
    socket =
      update_filter(socket, filter_key, %{
        condition: params |> Map.get(condition_key) |> String.to_existing_atom()
      })

    {:noreply, socket}
  end

  def auix_handle_event(
        "index-layout-change",
        %{"_target" => ["filter_to__" <> filter_key = to_key]} = params,
        socket
      ) do
    socket = update_filter(socket, filter_key, %{to: params[to_key]})
    {:noreply, socket}
  end

  def auix_handle_event(
        "index-layout-change",
        %{"_target" => ["filter_from__" <> filter_key = from_key]} = params,
        socket
      ) do
    socket = update_filter(socket, filter_key, %{from: params[from_key]})
    {:noreply, socket}
  end

  def auix_handle_event(
        "index-layout-change",
        %{"_target" => ["selected_check__" <> id]},
        %{assigns: %{auix: %{selection: selection} = auix}} =
          socket
      ) do
    page = if auix.layout_options.pagination_disabled?, do: 1, else: auix.pagination.page

    new_selection =
      selection.selected
      |> MapSet.member?(id)
      |> Kernel.!()
      |> then(&Selection.set_selected(id, selection, &1, page))

    {:noreply,
     socket
     |> assign_auix(:selection, new_selection)
     |> assign_selected_states()}
  end

  def auix_handle_event(
        "index-layout-change",
        %{"_target" => ["selected_in_page__"], "_unused_selected_in_page__" => ""} = _params,
        socket
      ) do
    {:noreply, socket}
  end

  def auix_handle_event(
        "index-layout-change",
        %{"_target" => ["selected_in_page__"]} = _params,
        %{assigns: %{auix: %{selection: selection} = auix}} = socket
      ) do
    new_selected_any_in_page? = !auix.selection.selected_any_in_page?

    new_selection =
      socket
      |> get_page_items_id()
      |> Enum.reduce(
        selection,
        &Selection.set_selected(&1, &2, new_selected_any_in_page?, auix.pagination.page)
      )

    {:noreply,
     socket
     |> assign_auix(:selection, new_selection)
     |> assign_selected_states()
     |> refresh_current_page()}
  end

  def auix_handle_event("index-layout-change", _params, socket), do: {:noreply, socket}

  def auix_handle_event("selected-toggle_all", params, socket) do
    state? = Map.get(params, "state", "false") == "true"

    {:noreply, assign_async_selected_toggle_all(socket, state?)}
  end

  def auix_handle_event("selected-cancel_toggle_all", _params, socket) do
    {:noreply, cancel_async(socket, :auix_selection_toggle_all, :cancel)}
  end

  def auix_handle_event("selected-delete_all", _params, socket) do
    {:noreply, assign_async_delete_all(socket)}
  end

  def auix_handle_event(
        "pagination_to_page",
        %{"page" => page},
        %{assigns: %{auix: %{pagination: %Pagination{}} = auix}} = socket
      ) do
    {:noreply, auix_route_forward(socket, patch: "/#{auix.uri_path}?page=#{page}")}
  end

  def auix_handle_event("pagination_to_page", _params, socket), do: {:noreply, socket}

  def auix_handle_event(
        "pagination_previous",
        params,
        %{
          assigns: %{
            auix:
              %{
                pagination: %Pagination{} = pagination,
                layout_options: %{pagination_disabled?: pagination_disabled?}
              } = auix
          }
        } = socket
      ) do
    if pagination_disabled? or Map.get(params, "pagination_disabled?") do
      {:noreply, paginate(socket, pagination.page - 1, Map.get(params, "items_per_page"))}
    else
      {:noreply,
       auix_route_forward(socket,
         patch: "/#{auix.uri_path}?page=#{previous_page(pagination)}"
       )}
    end
  end

  def auix_handle_event("pagination_previous", _params, socket), do: {:noreply, socket}

  def auix_handle_event(
        "pagination_next",
        params,
        %{
          assigns: %{
            auix:
              %{
                pagination: %Pagination{} = pagination,
                layout_options: %{pagination_disabled?: pagination_disabled?}
              } = auix
          }
        } = socket
      ) do
    if pagination_disabled? or Map.get(params, "pagination_disabled?") do
      {:noreply, paginate(socket, pagination.page + 1, Map.get(params, "items_per_page"))}
    else
      {:noreply,
       auix_route_forward(socket,
         patch: "/#{auix.uri_path}?page=#{next_page(pagination)}"
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

    %{assigns: %{auix: %{primary_keys: primary_keys, uri_path: uri_path}}} =
      new_socket = load_page(socket, int_new_page)

    case Map.get(primary_keys, int_index) do
      nil ->
        {:noreply, new_socket}

      id ->
        found_id =
          id
          |> List.first()
          |> elem(1)

        live_action_suffix = get_live_action_suffix(socket)

        {:noreply,
         push_patch(new_socket,
           to: "/#{uri_path}/#{found_id}/#{live_action_suffix}"
         )}
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
    {:noreply, refresh_current_page(socket)}
  end

  def auix_handle_info(%Event{} = event, socket) do
    {:noreply,
     socket
     |> unselect_deleted(event)
     |> assign_selected_states()
     |> refresh_current_page()
     |> react_to_open_entity(event)}
  end

  def auix_handle_info({Events, :refresh}, socket), do: {:noreply, refresh_current_page(socket)}

  def auix_handle_info({Events, :reset_selection}, socket) do
    {:noreply,
     socket
     |> assign_auix(:selection, Selection.new())
     |> assign_selected_states()
     |> refresh_current_page()}
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
  def auix_handle_async(
        :auix_selection_toggle_all,
        result,
        %{assigns: %{auix: %{selection: current_selection}}} = socket
      ) do
    selection =
      case result do
        {:ok, result_selection} -> result_selection
        _ -> current_selection
      end

    {:noreply,
     socket
     |> assign_auix(:selection, struct(selection, %{toggle_all_mode: :none}))
     |> assign_selected_states()
     |> refresh_current_page()}
  end

  def auix_handle_async(
        :auix_selection_delete_all,
        result,
        %{assigns: %{auix: %{selection: current_selection} = auix}} = socket
      ) do
    new_selection =
      case result do
        {:ok, deleted_ids} ->
          publish_deleted(auix, deleted_ids)
          Selection.new()

        _error ->
          current_selection
      end

    {:noreply,
     socket
     |> assign_auix(:selection, new_selection)
     |> assign_selected_states()
     |> refresh_current_page()}
  end

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
  @spec resource_schema(map()) :: module()
  defp resource_schema(%{configurations: configurations, resource_name: resource_name}) do
    get_in(configurations, [
      Access.key!(resource_name),
      Access.key!(:resource_config),
      Access.key!(:schema)
    ])
  end

  @spec subscribe_to_changes(Socket.t()) :: Socket.t()
  defp subscribe_to_changes(%{assigns: %{auix: auix}} = socket) do
    if connected?(socket), do: :ok = auix |> resource_schema() |> Events.subscribe()
    socket
  end

  @spec publish_deleted(map(), list()) :: :ok | {:error, term()}
  defp publish_deleted(_auix, []), do: :ok

  defp publish_deleted(auix, ids),
    do: auix |> resource_schema() |> Events.deleted(ids, from: self())

  @spec publish_child_deleted(struct()) :: :ok | {:error, term()}
  defp publish_child_deleted(%schema{} = entity) do
    ids = [BasicHelpers.primary_key_value(entity, schema.__schema__(:primary_key))]
    Events.deleted(schema, ids, from: self())
  end

  # A row checkbox stores its id as the DOM string (`"selected_check__" <> id`); "select
  # all" stores the native value. Integer keys are dropped in both forms.
  @spec unselect_deleted(Socket.t(), Event.t()) :: Socket.t()
  defp unselect_deleted(
         %{assigns: %{auix: %{selection: selection}}} = socket,
         %Event{action: :deleted, ids: ids}
       ) do
    dom_ids = for id <- ids, is_integer(id), do: Integer.to_string(id)
    assign_auix(socket, :selection, Selection.unselect(selection, ids ++ dom_ids))
  end

  defp unselect_deleted(socket, _event), do: socket

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

  defp react_to_change(%{assigns: %{auix: auix}} = socket, :show, :deleted, _entity_id) do
    socket
    |> put_flash(:info, dt("Item deleted successfully"))
    |> push_patch(to: "/#{auix.uri_path}")
  end

  defp react_to_change(%{assigns: %{auix: auix}} = socket, _form_action, :updated, _entity_id),
    do: put_flash(socket, :info, "#{auix.name} updated successfully")

  defp react_to_change(socket, _form_action, :deleted, _entity_id),
    do: put_flash(socket, :info, dt("Item deleted successfully"))

  @spec delete_selected(struct() | nil, Aurora.Uix.Integration.Connector.t(), keyword(), list()) ::
          list()
  defp delete_selected(nil, _delete_function, _delete_opts, _primary_key), do: []

  defp delete_selected(entity, delete_function, delete_opts, primary_key) do
    case apply_delete_function(delete_function, entity, delete_opts) do
      {:ok, _} -> [BasicHelpers.primary_key_value(entity, primary_key)]
      _error -> []
    end
  end

  @spec prepare_initial_pagination(Socket.t(), map()) :: Socket.t()
  defp prepare_initial_pagination(%{assigns: %{auix: auix}} = socket, params) do
    initial_page =
      params
      |> Map.get("page", "1")
      |> String.to_integer()

    per_page =
      if auix.layout_options.pagination_disabled?,
        do: auix.layout_options.infinite_scroll_items_load,
        else: auix.layout_options.pagination_items_per_page

    socket
    |> assign_auix(:initial_page, initial_page)
    |> assign_auix(:per_page, per_page)
  end

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
    |> load_page(page)
    |> assign_selected_states()
    |> assign_auix(:entity, nil)
  end

  # This one will be triggered if the items_per_page is changed.
  # That is a typical case when the elements are rendered in a small device, and fallback to infinity scroll.
  defp paginate(%{assigns: %{live_action: :index}} = socket, _page, items_per_page) do
    socket
    |> assign_auix(:initial_page, 1)
    |> assign_auix(:per_page, items_per_page)
    |> put_in([Access.key!(:assigns), :auix, :layout_options, :pagination_disabled?], true)
    |> load_items()
  end

  @spec load_page(Socket.t(), integer()) :: Socket.t()
  defp load_page(%{assigns: %{auix: %{pagination: %{page: same_page}}}} = socket, same_page) do
    socket
  end

  defp load_page(
         %{assigns: %{auix: %{pagination: pagination, list_function_selected: list_function}}} =
           socket,
         page
       ) do
    extra_opts = backend_socket_opts(socket, list_function)

    list_function
    |> apply_to_page(pagination, page, extra_opts)
    |> then(&assign_auix(socket, :read_items, &1))
    |> update_streams()
    |> assign_item_index()
  end

  @spec load_items(Socket.t(), keyword()) :: Socket.t()
  defp load_items(%{assigns: %{auix: auix}} = socket, extra_options \\ []) do
    layout_opts =
      auix.layout_tree
      |> Map.get(:opts, [])
      |> Enum.filter(&(elem(&1, 0) in @allowed_query_options))

    opts =
      auix
      |> get_in([:configurations, auix.resource_name, :resource_config])
      |> Map.get(:opts, [])
      |> Keyword.merge(layout_opts)
      |> Keyword.put_new(:order_by, [])
      |> Keyword.put_new(:where, [])
      |> merge_preload(auix.preload)

    load_items_options = Enum.map(opts, &merge_extra_option(&1, extra_options))

    read_items_options = [
      paginate: %{page: auix.initial_page, per_page: auix.per_page}
    ]

    socket
    |> assign_auix(:load_items_options, load_items_options)
    |> prepare_query_options()
    |> read_items(read_items_options)
    |> update_streams()
  end

  @spec refresh_current_page(Socket.t()) :: Socket.t()
  defp refresh_current_page(%{assigns: %{auix: %{pagination: pagination}}} = socket) do
    socket
    |> assign_auix(:reset_stream?, true)
    |> read_items(paginate: struct(pagination, %{page: pagination.page}))
    |> update_streams()
  end

  # Builds the list query from the layout and metadata options plus the submitted filters.
  # The layout `where` and the filters are concatenated into one flat condition list: both
  # `Aurora.Ctx.QueryBuilder` and the Ash query parser expect a flat list.
  # The resulting query is stored in :query_options assigns key.
  @spec prepare_query_options(Socket.t()) :: Socket.t()
  defp prepare_query_options(
         %{
           assigns: %{
             auix: %{load_items_options: load_items_options, filters_where: filters_where} = auix
           }
         } = socket
       ) do
    where =
      load_items_options
      |> Keyword.get(:where)
      |> where_conditions()
      |> Kernel.++(filters_where)

    base_options = [order_by: Keyword.get(load_items_options, :order_by), where: where]

    query_options =
      base_options
      |> maybe_put_preload(Keyword.get(load_items_options, :preload))
      |> maybe_put_sort(auix.sort)

    assign_auix(socket, :query_options, query_options)
  end

  # A `where` may be a list, a map of equalities, a single condition or a dynamic expression.
  @spec where_conditions(term()) :: list()
  defp where_conditions(nil), do: []
  defp where_conditions(conditions) when is_list(conditions), do: conditions

  defp where_conditions(conditions) when is_non_struct_map(conditions),
    do: Map.to_list(conditions)

  defp where_conditions(condition), do: [condition]

  # Associations and generated fields are only populated when the query asks for them, so the index
  # list needs the same preload the `:show` and `:edit` paths already apply.
  @spec merge_preload(keyword(), list() | nil) :: keyword()
  defp merge_preload(opts, preload) when preload in [nil, []], do: opts

  defp merge_preload(opts, preload) do
    Keyword.update(opts, :preload, preload, &Enum.uniq(List.wrap(&1) ++ preload))
  end

  # Kept out of the query entirely when there is nothing to load, so resources without preloads
  # issue the same query as before.
  @spec maybe_put_preload(keyword(), list() | nil) :: keyword()
  defp maybe_put_preload(query_options, preload) when preload in [nil, []], do: query_options

  defp maybe_put_preload(query_options, preload),
    do: Keyword.put(query_options, :preload, preload)

  # A header sort replaces the layout and metadata order_by.
  @spec maybe_put_sort(keyword(), map() | nil) :: keyword()
  defp maybe_put_sort(query_options, nil), do: query_options

  defp maybe_put_sort(query_options, %{key: key, direction: direction}),
    do: Keyword.put(query_options, :order_by, [{direction, key}])

  @spec next_sort(map() | nil, atom()) :: map()
  defp next_sort(%{key: key, direction: :asc}, key), do: %{key: key, direction: :desc}
  defp next_sort(_sort, key), do: %{key: key, direction: :asc}

  # Read the items.
  # Uses the previously store :query_options, accepts new options.
  # This is the perfect place to set paginate option for the query, since it be used only for reading the items.
  @spec read_items(Socket.t(), keyword()) :: Socket.t()
  defp read_items(
         %{
           assigns: %{
             auix: %{
               query_options: query_options,
               list_function_selected: list_function
             }
           }
         } = socket,
         options
       ) do
    extra_opts = backend_socket_opts(socket, list_function)

    read_items =
      query_options
      |> Keyword.merge(options)
      |> Keyword.merge(extra_opts)
      |> then(&apply_list_function(list_function, &1))

    assign_auix(socket, :read_items, read_items)
  end

  @spec update_streams(Socket.t()) :: Socket.t()
  defp update_streams(
         %{
           assigns: %{
             auix:
               %{
                 read_items: %{entries: entries} = pagination,
                 primary_key: primary_key
               } = auix
           }
         } = socket
       ) do
    primary_keys =
      entries
      |> Enum.with_index(fn entry, index ->
        entry
        |> Map.from_struct()
        |> Enum.filter(&(elem(&1, 0) in primary_key))
        |> then(&{index, &1})
      end)
      |> Map.new()

    entries =
      Enum.with_index(entries, fn entry, index ->
        item_id = BasicHelpers.primary_key_value(entry, auix.primary_key)

        entry
        |> Map.from_struct()
        |> Map.merge(%{:_even => rem(index, 2) == 0, :_index => index})
        |> Selection.set_item_select_state(item_id, auix.selection)
      end)

    options = if auix.reset_stream?, do: [reset: true], else: []

    socket
    |> assign_auix(:pagination, pagination)
    |> assign_auix(:primary_keys, primary_keys)
    |> assign_auix(:read_items, nil)
    |> assign_auix(:empty_list?, Enum.empty?(entries))
    |> assign_auix(:reset_stream?, !auix.layout_options.pagination_disabled?)
    |> stream(
      auix.source_key,
      entries,
      options
    )
    |> update_alternate_streams(entries, options)
  end

  @spec update_alternate_streams(Socket.t(), list(), keyword()) :: Socket.t()
  defp update_alternate_streams(
         %{
           assigns: %{
             auix: %{
               source_key: source_key,
               layout_options: %{alternate_streams_suffixes: alternate_streams_suffixes}
             }
           }
         } = socket,
         entries,
         options
       ) do
    Enum.reduce(
      alternate_streams_suffixes,
      socket,
      &stream(&2, "#{source_key}__#{&1}", entries, options)
    )
  end

  defp update_alternate_streams(socket, _entries, _options), do: socket

  @spec merge_extra_option(tuple(), list()) :: tuple()
  defp merge_extra_option({option_key, _value} = option, extra_options) do
    extra_options
    |> Keyword.get(option_key)
    |> merge_option(option)
  end

  @spec merge_option(list() | nil, tuple()) :: tuple()
  defp merge_option(extra, {:where, where}) when is_list(extra),
    do: {:where, Keyword.merge(where, extra)}

  defp merge_option(extra, {:order_by, _order_by}) when is_list(extra), do: {:order_by, extra}

  defp merge_option(nil, option), do: option

  @spec assign_layout_options(Socket.t()) :: Socket.t()
  defp assign_layout_options(socket) do
    :index
    |> LayoutOptions.available_options()
    |> Enum.reduce(socket, &BasicHelpers.assign_auix_option(&2, &1))
  end

  @spec assign_index_fields(Socket.t()) :: Socket.t()
  defp assign_index_fields(
         %{
           assigns: %{
             auix:
               %{
                 configurations: configurations,
                 layout_tree: layout_tree,
                 resource_name: resource_name
               } = auix
           }
         } = socket
       ) do
    fields_parser =
      configurations
      |> get_in([Access.key!(resource_name), Access.key!(:resource_config), Access.key!(:type)])
      |> LayoutHelpers.get_fields_parser_module()

    resource_schema = resource_schema(auix)

    select_toggle_function =
      auix
      |> Map.get(:index_selected_all_actions, [])
      |> List.first(%{})
      |> Map.get(:function_component, "")

    select_field =
      resource_schema
      |> fields_parser.parse_field(resource_name, {:selected_check__, :boolean})
      |> struct(%{
        label: select_toggle_function,
        filterable?: false,
        sortable?: false,
        index_renderer: :default
      })

    layout_tree.inner_elements
    |> Enum.filter(&(&1.tag == :field))
    |> Enum.map(&BasicHelpers.get_field(&1, configurations, resource_name))
    |> Enum.reject(
      &(&1.type in [
          :one_to_many_association,
          :many_to_one_association,
          :one_to_one_association,
          :many_to_many_association,
          :embeds_one,
          :embeds_many
        ])
    )
    |> Enum.map(&drop_upload_sort/1)
    |> then(&[select_field | &1])
    |> then(&assign_auix(socket, :index_fields, &1))
  end

  # An upload column holds an opaque file reference, so it never offers a sort control.
  @spec drop_upload_sort(Aurora.Uix.Field.t()) :: Aurora.Uix.Field.t()
  defp drop_upload_sort(field) do
    if BasicHelpers.upload_field?(field), do: struct(field, %{sortable?: false}), else: field
  end

  @spec assign_selected_states(Socket.t()) :: Socket.t()
  defp assign_selected_states(%{assigns: %{auix: %{selection: selection} = auix}} = socket) do
    selection
    |> Selection.update_states(auix.pagination.page)
    |> then(&assign_auix(socket, :selection, &1))
  end

  @spec assign_async_selected_toggle_all(Socket.t(), boolean()) :: Socket.t()
  defp assign_async_selected_toggle_all(
         %{
           assigns: %{
             auix: %{
               list_function_selected: list_function,
               selection: selection,
               pagination: %{pages_count: pages_count} = pagination,
               primary_key: primary_key
             }
           }
         } = socket,
         state?
       ) do
    toggle_all_mode = if state?, do: :check, else: :uncheck
    pagination = struct(pagination, %{entries: []})
    # Resolve socket-derived opts (e.g. actor:) BEFORE start_async — the spawned task
    # runs in a separate process and must not touch the socket.
    extra_opts = backend_socket_opts(socket, list_function)

    function =
      fn ->
        Enum.reduce(
          1..pages_count,
          selection,
          fn page, acc_selection ->
            list_function
            |> apply_to_page(pagination, page, extra_opts)
            |> Map.get(:entries, [])
            |> Enum.map(&BasicHelpers.primary_key_value(&1, primary_key))
            |> Enum.reduce(acc_selection, &Selection.set_selected(&1, &2, state?, page))
          end
        )
      end

    socket
    |> start_async(:auix_selection_toggle_all, function)
    |> assign_auix(:selection, struct(selection, %{toggle_all_mode: toggle_all_mode}))
    |> refresh_current_page()
  end

  @spec assign_async_delete_all(Socket.t()) :: Socket.t()
  defp assign_async_delete_all(%{assigns: %{auix: %{selection: selection} = auix}} = socket) do
    # Capture per-connector opts BEFORE start_async — the spawned task must not access
    # the socket from another process.
    get_opts = backend_socket_opts(socket, auix.get_function)
    delete_opts = backend_socket_opts(socket, auix.delete_function)

    get_function = auix.get_function
    delete_function = auix.delete_function
    primary_key = auix.primary_key

    function =
      fn ->
        selection.selected
        |> Enum.map(&apply_get_function(get_function, &1, get_opts))
        |> Enum.flat_map(&delete_selected(&1, delete_function, delete_opts, primary_key))
      end

    start_async(socket, :auix_selection_delete_all, function)
  end

  @spec assign_filters(Socket.t()) :: Socket.t()
  defp assign_filters(%{assigns: %{auix: %{index_fields: index_fields}}} = socket) do
    filters =
      index_fields
      |> Enum.filter(& &1.filterable?)
      |> Map.new(
        &{to_string(&1.key), Filter.new(%{key: &1.key, condition: Filter.default_condition(&1)})}
      )

    socket
    |> assign_auix(:filters, filters)
    |> assign_filters_selected_count()
    |> assign_auix(:index_layout_form, to_form(filters))
  end

  @spec assign_filters_selected_count(Socket.t()) :: Socket.t()
  defp assign_filters_selected_count(%{assigns: %{auix: %{filters: filters}}} = socket) do
    filters = get_selected_filters(filters)
    assign_auix(socket, :filters_selected_count, Enum.count(filters))
  end

  @spec assign_live_component(Socket.t()) :: Socket.t()
  defp assign_live_component(%{assigns: %{auix: auix, live_action: :show}} = socket) do
    auix
    |> ModulesGenerator.module_name(".ShowComponent")
    |> then(&assign_auix(socket, :live_component, &1))
  end

  defp assign_live_component(%{assigns: %{auix: auix}} = socket) do
    auix
    |> ModulesGenerator.module_name(".FormComponent")
    |> then(&assign_auix(socket, :live_component, &1))
  end

  @spec update_filter(Socket.t(), binary(), map()) :: Socket.t()
  defp update_filter(%{assigns: %{auix: %{filters: filters}}} = socket, filter_key, attrs) do
    filter_key = String.replace(filter_key, ~r/--\w+--/, "")

    filters =
      filters
      |> Map.get(filter_key, Filter.new(filter_key))
      |> Filter.change(attrs)
      |> then(&Map.put(filters, filter_key, &1))

    socket
    |> put_in([Access.key!(:assigns), :auix, :filters], filters)
    |> assign_auix(:index_layout_form, to_form(filters))
  end

  @spec get_selected_filters(list()) :: list()
  defp get_selected_filters(filters) do
    filters
    |> Enum.reject(fn
      {_key, %{condition: :between} = filter} ->
        is_nil(filter.from) or is_nil(filter.to)

      {_key, %{condition: :contains} = filter} ->
        is_nil(filter.from) or filter.from == ""

      {_key, %{condition: condition}} when condition in [false, true] ->
        false

      {_key, %{condition: :in} = filter} ->
        is_nil(filter.from) or filter.from == ""

      {_key, filter} ->
        is_nil(filter.from)
    end)
    |> Enum.map(fn
      {_key, %{condition: :eq} = filter} ->
        {filter.key, filter.from}

      {_key, %{condition: :between} = filter} ->
        {filter.key, filter.condition, filter.from, filter.to}

      {_key, %{condition: :contains} = filter} ->
        {filter.key, :ilike, "%" <> escape(filter.from) <> "%"}

      {_key, %{condition: condition} = filter} when condition in [false, true] ->
        {filter.key, condition}

      {_key, %{condition: :in} = filter} ->
        {filter.key, :in, in_values(filter.from)}

      {_key, filter} ->
        {filter.key, filter.condition, filter.from}
    end)
  end

  # The "in list" input is free text; both backends take `:in` values as a list only.
  @spec in_values(binary()) :: list(binary())
  defp in_values(text) do
    text
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  # Escapes ilike wildcard characters (`\`, `%`, `_`) so a `contains` filter value matches
  # literally instead of being interpreted as a pattern.
  @spec escape(binary()) :: binary()
  defp escape(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  @spec previous_page(map()) :: integer()
  defp previous_page(%{page: page}) when page <= 1, do: 1
  defp previous_page(%{page: page}), do: page - 1

  @spec next_page(map()) :: integer()
  defp next_page(%{page: page, pages_count: pages_count}) when page >= pages_count,
    do: pages_count

  defp next_page(%{page: page}), do: page + 1

  @spec get_page_items_id(Socket.t()) :: list()
  defp get_page_items_id(%{assigns: %{auix: auix}} = socket) do
    extra_opts = backend_socket_opts(socket, auix.list_function_selected)

    auix.pagination
    |> Map.get(:opts, [])
    |> Keyword.put(:select, auix.primary_key)
    |> Keyword.put(:paginate, %{per_page: auix.pagination.per_page})
    |> then(&Map.put(auix.pagination, :opts, &1))
    |> then(&apply_to_page(auix.list_function_selected, &1, auix.pagination.page, extra_opts))
    |> Map.get(:entries, [])
    |> Enum.map(&BasicHelpers.primary_key_value(&1, auix.primary_key))
  end

  @spec get_live_action_suffix(Socket.t()) :: binary()
  defp get_live_action_suffix(%{assigns: %{live_action: :show_edit}}), do: "show-edit"
  defp get_live_action_suffix(%{assigns: %{live_action: :edit}}), do: "edit"
  defp get_live_action_suffix(_socket), do: "show"
end
