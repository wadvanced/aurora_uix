defmodule Aurora.Uix.Templates.Basic.Handlers.IndexList do
  @moduledoc """
  The list of an index: loading, streams, filters, sort, pagination, selection and bulk actions, for a LiveView socket and for a LiveComponent socket.

  ## Key Features

  - Handles the nine list events: `"filter-toggle"`, `"filters-clear"`, `"filters-submit"`,
    `"index-sort"`, `"index-sort-direction"`, `"index-layout-change"`, `"selected-toggle_all"`,
    `"selected-cancel_toggle_all"` and `"selected-delete_all"`
  - Runs the two async tasks, `:auix_selection_toggle_all` and `:auix_selection_delete_all`
  - Loads pages into the streams of the socket it is given
  - Handles an `Aurora.Uix.Event` by dropping deleted ids from the selection and re-reading the page

  ## Key Constraints

  - It never navigates and never reads `live_action`
  - It expects the `auix` keys `Aurora.Uix.Templates.Basic.Handlers.IndexImpl.auix_mount/3` sets
  - Backend-agnostic: it reads and deletes through `Aurora.Uix.Integration.Crud`
  """

  import Aurora.Uix.Integration.Crud
  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.Component
  import Phoenix.LiveView

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Filter
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Selection
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.Socket

  # `:or_where` would OR around the filter bar's conditions and `:select` would break the
  # index projection, so neither is an index option.
  @allowed_query_options [:where, :order_by, :preload]

  @events [
    "filter-toggle",
    "filters-clear",
    "filters-submit",
    "index-sort",
    "index-sort-direction",
    "index-layout-change",
    "selected-toggle_all",
    "selected-cancel_toggle_all",
    "selected-delete_all"
  ]

  @doc """
  Returns the names of the list events `handle_event/3` takes.

  ## Returns
  list(binary()) - The list event names.
  """
  @spec events() :: [binary()]
  def events, do: @events

  @doc """
  Initializes the list: its assigns, layout options, index fields, filters and first page.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the `auix` assigns of the index.
  - `params` (map()) - URL/query parameters; `"page"` selects the initial page.
  - `prepare` ((Socket.t() -> Socket.t())) - Runs after the layout options are assigned and
    before the index fields are built.

  ## Returns
  Socket.t() - Socket with the list loaded.
  """
  @spec init(Socket.t(), map(), (Socket.t() -> Socket.t())) :: Socket.t()
  def init(%{assigns: %{auix: auix}} = socket, params, prepare) do
    socket
    |> assign_auix(:filters_enabled?, false)
    |> assign_auix(:filters_where, [])
    |> assign_auix(:sort, nil)
    |> assign_auix(:selection, Selection.new())
    |> assign_auix(:enable_viewport?, true)
    |> assign_auix(:list_function_selected, auix.list_function_paginated)
    |> assign_auix(:reset_stream?, true)
    |> assign_auix(:empty_list?, true)
    |> assign_layout_options()
    |> prepare.()
    |> assign_index_fields()
    |> assign_filters()
    |> prepare_initial_pagination(params)
    |> load_items()
  end

  @doc """
  Handles a list event. Only the names of `events/0` are accepted.

  ## Parameters
  - `event` (binary()) - Event name, one of `events/0`.
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket.
  """
  @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_event(
        "filter-toggle",
        _params,
        %{assigns: %{auix: %{filters_enabled?: filters_enabled?}}} = socket
      ) do
    {:noreply, assign_auix(socket, :filters_enabled?, !filters_enabled?)}
  end

  def handle_event(
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

  def handle_event(
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

  def handle_event(
        event,
        _params,
        %{assigns: %{auix: %{layout_options: %{sort_disabled?: true}}}} = socket
      )
      when event in ["index-sort", "index-sort-direction"],
      do: {:noreply, socket}

  # Column headers: none -> ascending -> descending -> none.
  def handle_event("index-sort", %{"key" => key}, %{assigns: %{auix: auix}} = socket) do
    case sortable_field(auix, key) do
      nil -> {:noreply, socket}
      %{key: field_key} -> {:noreply, apply_sort(socket, next_sort(auix.sort, field_key))}
    end
  end

  # Card view select: "" returns to the backend order; a field keeps the current direction.
  def handle_event("index-sort", %{"sort" => ""}, socket),
    do: {:noreply, apply_sort(socket, nil)}

  def handle_event("index-sort", %{"sort" => key}, %{assigns: %{auix: auix}} = socket) do
    case sortable_field(auix, key) do
      nil ->
        {:noreply, socket}

      %{key: field_key} ->
        direction = if auix.sort, do: auix.sort.direction, else: :asc
        {:noreply, apply_sort(socket, %{key: field_key, direction: direction})}
    end
  end

  # Card view menu: "asc" or "desc" sets the direction of the active sort.
  def handle_event(
        "index-sort-direction",
        %{"direction" => direction},
        %{assigns: %{auix: auix}} = socket
      ) do
    case {auix.sort, to_direction(direction)} do
      {nil, _direction} -> {:noreply, socket}
      {_sort, nil} -> {:noreply, socket}
      {sort, new_direction} -> {:noreply, apply_sort(socket, %{sort | direction: new_direction})}
    end
  end

  def handle_event("index-sort-direction", _params, %{assigns: %{auix: auix}} = socket) do
    case auix.sort do
      nil ->
        {:noreply, socket}

      %{direction: direction} = sort ->
        {:noreply, apply_sort(socket, %{sort | direction: flip(direction)})}
    end
  end

  def handle_event(
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

  def handle_event(
        "index-layout-change",
        %{"_target" => ["filter_to__" <> filter_key = to_key]} = params,
        socket
      ) do
    socket = update_filter(socket, filter_key, %{to: params[to_key]})
    {:noreply, socket}
  end

  def handle_event(
        "index-layout-change",
        %{"_target" => ["filter_from__" <> filter_key = from_key]} = params,
        socket
      ) do
    socket = update_filter(socket, filter_key, %{from: params[from_key]})
    {:noreply, socket}
  end

  def handle_event(
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

  def handle_event(
        "index-layout-change",
        %{"_target" => ["selected_in_page__"], "_unused_selected_in_page__" => ""} = _params,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
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

  def handle_event("index-layout-change", _params, socket), do: {:noreply, socket}

  def handle_event("selected-toggle_all", params, socket) do
    state? = Map.get(params, "state", "false") == "true"

    {:noreply, assign_async_selected_toggle_all(socket, state?)}
  end

  def handle_event("selected-cancel_toggle_all", _params, socket) do
    {:noreply, cancel_async(socket, :auix_selection_toggle_all, :cancel)}
  end

  def handle_event("selected-delete_all", _params, socket) do
    {:noreply, assign_async_delete_all(socket)}
  end

  @doc """
  Handles the results of the selection async tasks.

  Selecting all items in large datasets is time consuming, therefore it is handled asynchronously.

  ## Parameters
  - `task` (atom()) - Task name (`:auix_selection_toggle_all` or `:auix_selection_delete_all`).
  - `result` (term()) - Result of the async task.
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with the new selection.
  """
  @spec handle_async(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_async(
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

  def handle_async(
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
  Reads and deletes the record with `id`, publishes the deletion and re-reads the current page.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.
  - `id` (term()) - Id of the record to delete.

  ## Returns
  `{Socket.t(), list()}` - Updated socket and the primary key values of the deleted record.
  """
  @spec delete(Socket.t(), term()) :: {Socket.t(), list()}
  def delete(%{assigns: %{auix: auix}} = socket, id) do
    get_opts = backend_socket_opts(socket, auix.get_function)
    delete_opts = backend_socket_opts(socket, auix.delete_function)
    entity = apply_get_function(auix.get_function, id, get_opts)
    {:ok, _} = apply_delete_function(auix.delete_function, entity, delete_opts)
    id_value = BasicHelpers.primary_key_value(entity, auix.primary_key)
    publish_deleted(auix, [id_value])

    {socket
     |> stream_delete(auix.source_key, entity)
     |> assign_selected_states()
     |> refresh_current_page(), [id_value]}
  end

  @doc """
  Applies an `Aurora.Uix.Event` to the list: drops deleted ids from the selection and re-reads
  the current page.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.
  - `event` (Event.t()) - The event received on the schema's topic.

  ## Returns
  Socket.t() - Updated socket.
  """
  @spec apply_event(Socket.t(), Event.t()) :: Socket.t()
  def apply_event(socket, event) do
    socket
    |> unselect_deleted(event)
    |> assign_selected_states()
    |> refresh_current_page()
  end

  @doc """
  Clears the selection and re-reads the current page.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.

  ## Returns
  Socket.t() - Updated socket.
  """
  @spec reset_selection(Socket.t()) :: Socket.t()
  def reset_selection(socket) do
    socket
    |> assign_auix(:selection, Selection.new())
    |> assign_selected_states()
    |> refresh_current_page()
  end

  @doc """
  Moves the list to `page`. A different `items_per_page` switches the list to infinite scroll
  and reloads it from the first page.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.
  - `page` (integer()) - Page to show.
  - `items_per_page` (integer() | nil) - Items per page requested by the client, if any.

  ## Returns
  Socket.t() - Updated socket.
  """
  @spec paginate(Socket.t(), integer(), integer() | nil) :: Socket.t()
  def paginate(
        %{assigns: %{auix: %{pagination: %{per_page: per_page}}}} = socket,
        page,
        items_per_page
      )
      when is_nil(items_per_page) or items_per_page == per_page do
    socket
    |> load_page(page)
    |> assign_selected_states()
  end

  # This one will be triggered if the items_per_page is changed.
  # That is a typical case when the elements are rendered in a small device, and fallback to infinity scroll.
  def paginate(socket, _page, items_per_page) do
    socket
    |> assign_auix(:initial_page, 1)
    |> assign_auix(:per_page, items_per_page)
    |> put_in([Access.key!(:assigns), :auix, :layout_options, :pagination_disabled?], true)
    |> load_items()
  end

  @doc """
  Returns the schema of the resource the `auix` assigns describe.

  ## Parameters
  - `auix` (map()) - The `auix` assigns, with `:configurations` and `:resource_name`.

  ## Returns
  module() - The resource schema.
  """
  @spec resource_schema(map()) :: module()
  def resource_schema(%{configurations: configurations, resource_name: resource_name}) do
    get_in(configurations, [
      Access.key!(resource_name),
      Access.key!(:resource_config),
      Access.key!(:schema)
    ])
  end

  @doc """
  Loads the given page into the streams, unless it is already the current page.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.
  - `page` (integer()) - Page to load.

  ## Returns
  Socket.t() - Socket with the page streamed.
  """
  @spec load_page(Socket.t(), integer()) :: Socket.t()
  def load_page(%{assigns: %{auix: %{pagination: %{page: same_page}}}} = socket, same_page) do
    socket
  end

  def load_page(
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

  @doc """
  Builds the list query from the resource, the layout and `extra_options`, reads the initial
  page and streams it.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.
  - `extra_options` (keyword()) - `:where` and `:order_by` options merged into the query.

  ## Returns
  Socket.t() - Socket with the items streamed.
  """
  @spec load_items(Socket.t(), keyword()) :: Socket.t()
  def load_items(%{assigns: %{auix: auix}} = socket, extra_options \\ []) do
    layout_opts = layout_query_options(auix.layout_tree)

    opts =
      auix
      |> get_in([:configurations, auix.resource_name, :resource_config])
      |> resource_query_opts()
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

  @doc """
  Re-reads the current page and resets its streams.

  ## Parameters
  - `socket` (Socket.t()) - Socket with the list `auix` assigns.

  ## Returns
  Socket.t() - Socket with the current page streamed again.
  """
  @spec refresh_current_page(Socket.t()) :: Socket.t()
  def refresh_current_page(%{assigns: %{auix: %{pagination: pagination}}} = socket) do
    socket
    |> assign_auix(:reset_stream?, true)
    |> read_items(paginate: struct(pagination, %{page: pagination.page}))
    |> update_streams()
  end

  # A `where` may be a list, a map of equalities, a single condition or a dynamic expression.
  @doc """
  Flattens a `where` into a list of conditions.

  ## Parameters
  - `conditions` (term()) - `nil`, a list, a map of equalities or a single condition.

  ## Returns
  list() - The conditions as a flat list.
  """
  @spec where_conditions(term()) :: list()
  def where_conditions(nil), do: []
  def where_conditions(conditions) when is_list(conditions), do: conditions

  def where_conditions(conditions) when is_non_struct_map(conditions),
    do: Map.to_list(conditions)

  def where_conditions(condition), do: [condition]

  @doc """
  Returns the page before the current one, never below `1`.

  ## Parameters
  - `pagination` (map()) - Pagination with `:page`.

  ## Returns
  integer() - The previous page.
  """
  @spec previous_page(map()) :: integer()
  def previous_page(%{page: page}) when page <= 1, do: 1
  def previous_page(%{page: page}), do: page - 1

  @doc """
  Returns the page after the current one, never above `pages_count`.

  ## Parameters
  - `pagination` (map()) - Pagination with `:page` and `:pages_count`.

  ## Returns
  integer() - The next page.
  """
  @spec next_page(map()) :: integer()
  def next_page(%{page: page, pages_count: pages_count}) when page >= pages_count,
    do: pages_count

  def next_page(%{page: page}), do: page + 1

  ## PRIVATE
  @spec publish_deleted(map(), list()) :: :ok | {:error, term()}
  defp publish_deleted(_auix, []), do: :ok

  defp publish_deleted(auix, ids),
    do: auix |> resource_schema() |> Events.deleted(ids, from: self())

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

  # The layout's query: its `order_by` and `where`, plus its `:preload` option.
  @spec layout_query_options(map()) :: keyword()
  defp layout_query_options(layout_tree) do
    [order_by: layout_tree.order_by, where: layout_tree.where]
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Kernel.++(Enum.filter(layout_tree.options, &(elem(&1, 0) in @allowed_query_options)))
  end

  # The layout's own options override the resource's.
  @spec resource_query_opts(map()) :: keyword()
  defp resource_query_opts(resource_config) do
    Enum.reject(
      [
        order_by: resource_config.order_by,
        where: resource_config.where,
        preload: resource_config.preload
      ],
      &is_nil(elem(&1, 1))
    )
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

  @spec apply_sort(Socket.t(), map() | nil) :: Socket.t()
  defp apply_sort(socket, sort) do
    socket
    |> assign_auix(:sort, sort)
    |> prepare_query_options()
    |> refresh_current_page()
  end

  @spec sortable_field(map(), binary()) :: Aurora.Uix.Field.t() | nil
  defp sortable_field(auix, key),
    do: Enum.find(auix.index_fields, &(&1.sortable? and to_string(&1.key) == key))

  @spec flip(:asc | :desc) :: :asc | :desc
  defp flip(:asc), do: :desc
  defp flip(:desc), do: :asc

  @spec to_direction(term()) :: :asc | :desc | nil
  defp to_direction("asc"), do: :asc
  defp to_direction("desc"), do: :desc
  defp to_direction(_direction), do: nil

  @spec next_sort(map() | nil, atom()) :: map() | nil
  defp next_sort(%{key: key, direction: :asc}, key), do: %{key: key, direction: :desc}
  defp next_sort(%{key: key, direction: :desc}, key), do: nil
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

    layout_tree.children
    |> Enum.map(& &1.field)
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
end
