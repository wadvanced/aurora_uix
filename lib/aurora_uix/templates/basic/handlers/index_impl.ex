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
    - Assumes certain structure in the `auix` assign (e.g., `modules.context`, `source_key`, etc.).

  """

  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.LiveView
  import Phoenix.Component

  alias Aurora.Ctx.Core, as: CtxCore
  alias Aurora.Ctx.Pagination
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
      @impl LiveView
      defdelegate handle_async(task, result, socket), to: IndexImpl

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
  def mount(params, _session, %{assigns: %{auix: auix}} = socket) do
    form_component = ModulesGenerator.module_name(auix, ".FormComponent")

    theme_module = ThemeHelper.theme_module()

    {:ok,
     socket
     |> assign_auix(:form_component, form_component)
     |> assign_auix(:filters_enabled?, false)
     |> assign_auix(:selection, Selection.new())
     |> assign_auix(:list_function_selected, auix.list_function_paginated)
     |> assign_auix(:reset_stream?, true)
     |> assign_auix_new(:theme_module, theme_module)
     |> assign_stylesheet()
     |> assign_layout_options()
     |> IndexActions.set_actions()
     |> assign_index_fields()
     |> assign_filters()
     |> prepare_initial_pagination(params)
     |> load_items()}
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
    {:noreply,
     socket
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

  def handle_event("delete", %{"id" => id}, %{assigns: %{auix: auix, streams: _streams}} = socket) do
    entity = auix.get_function.(id, [])
    {:ok, _} = auix.delete_function.(entity)

    {:noreply,
     socket
     |> stream_delete(auix.source_key, entity)
     |> assign_selected_states()}
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

  def handle_event(
        "filter-toggle",
        _params,
        %{assigns: %{auix: %{filters_enabled?: filters_enabled?}}} = socket
      ) do
    {:noreply, assign_auix(socket, :filters_enabled?, !filters_enabled?)}
  end

  def handle_event("filters-clear", _params, %{assigns: %{auix: %{filters: filters}}} = socket) do
    {:noreply,
     Enum.reduce(filters, socket, fn {key, _filter}, acc_socket ->
       update_filter(acc_socket, key, %{condition: :eq, from: nil, to: nil})
     end)}
  end

  def handle_event(
        "filters-submit",
        _params,
        %{assigns: %{auix: %{filters: filters}}} = socket
      ) do
    filters =
      filters
      |> Enum.reject(fn
        {_key, %{condition: :between} = filter} ->
          is_nil(filter.from) or is_nil(filter.to)

        {_key, filter} ->
          is_nil(filter.from)
      end)
      |> Enum.map(fn
        {_key, %{condition: :eq} = filter} ->
          {filter.key, filter.from}

        {_key, %{condition: :between} = filter} ->
          {filter.key, filter.condition, filter.from, filter.to}

        {_key, filter} ->
          {filter.key, filter.condition, filter.from}
      end)

    {:noreply,
     socket
     |> prepare_query_options(where: filters)
     |> refresh_current_page()}
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
        %{"_target" => ["selected_in_page__"]},
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

  def handle_event(
        "pagination_to_page",
        %{"page" => page},
        %{assigns: %{auix: %{pagination: %Pagination{}} = auix}} = socket
      ) do
    {:noreply,
     auix_route_forward(socket, patch: "/#{auix.link_prefix}#{auix.source}?page=#{page}")}
  end

  def handle_event("pagination_to_page", _params, socket), do: {:noreply, socket}

  def handle_event(
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
         patch: "/#{auix.link_prefix}#{auix.source}?page=#{previous_page(pagination)}"
       )}
    end
  end

  def handle_event("pagination_previous", _params, socket), do: {:noreply, socket}

  def handle_event(
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
         patch: "/#{auix.link_prefix}#{auix.source}?page=#{next_page(pagination)}"
       )}
    end
  end

  def handle_event("pagination_next", _params, socket), do: {:noreply, socket}

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
        %{assigns: %{auix: auix, streams: _streams}} = socket
      ) do
    {:noreply, stream_insert(socket, auix.source_key, entity)}
  end

  def handle_info(_input, socket) do
    {:noreply, socket}
  end

  @doc """
  Handles async results for selection.

  Selecting all items, in large datasets, are time consuming, therefore it is handle asynchronously.

  ## Parameters
  - `task` (atom()) - Task name.
  - `result` (tuple()) - Result of the async task.
  - `socket` (Socket.t()) - LiveView socket.

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

  def apply_action(%{assigns: %{live_action: :index}} = socket, %{"page" => page}) do
    page = String.to_integer(page)
    paginate(socket, page, nil)
  end

  def apply_action(%{assigns: %{live_action: :index}} = socket, _params) do
    assign_auix(socket, :entity, nil)
  end

  ## PRIVATE
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
             auix: %{pagination: %{repo_module: _repo_module, per_page: per_page} = pagination}
           }
         } = socket,
         page,
         items_per_page
       )
       when is_nil(items_per_page) or items_per_page == per_page do
    if page == pagination.page do
      socket
      |> assign_selected_states()
      |> assign_auix(:entity, nil)
    else
      pagination
      |> CtxCore.to_page(page)
      |> then(&assign_auix(socket, :read_items, &1))
      |> update_streams()
      |> assign_selected_states()
      |> assign_auix(:entity, nil)
    end
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

    load_items_options = Enum.map(opts, &merge_extra_option(&1, extra_options))

    read_items_options = [paginate: %{page: auix.initial_page, per_page: auix.per_page}]

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

  # Prepare the query.
  # Ensure the options set are acceptable and combines with optional new options.
  # The resulting query is stored in :query_options assigns key.
  # It is not recommended to send pagination query to this function.
  @spec prepare_query_options(Socket.t(), keyword()) :: Socket.t()
  defp prepare_query_options(
         %{assigns: %{auix: %{load_items_options: load_items_options}}} = socket,
         opts \\ []
       ) do
    merged_opts =
      Keyword.merge(load_items_options, opts, fn _key, existing, acc -> [existing | acc] end)

    query_options = [
      order_by: Keyword.get(merged_opts, :order_by),
      where: Keyword.get(merged_opts, :where)
    ]

    assign_auix(socket, :query_options, query_options)
  end

  # Read the items.
  # Uses the previously store :query_options, accepts new options.
  # This is the perfect place to set paginate option for the query, since it be used only for reading the items.
  @spec read_items(Socket.t(), keyword()) :: Socket.t()
  defp read_items(
         %{
           assigns: %{
             auix: %{query_options: query_options, list_function_selected: list_function}
           }
         } = socket,
         options
       ) do
    query_options
    |> Keyword.merge(options)
    |> list_function.()
    |> then(&assign_auix(socket, :read_items, &1))
  end

  @spec update_streams(Socket.t()) :: Socket.t()
  defp update_streams(
         %{
           assigns: %{
             auix:
               %{
                 read_items: %{entries: entries} = pagination
               } = auix
           }
         } = socket
       ) do
    entries =
      Enum.map(entries, fn entry ->
        item_id = BasicHelpers.primary_key_value(entry, auix.primary_key)

        entry
        |> Map.from_struct()
        |> Selection.set_item_select_state(item_id, auix.selection)
      end)

    options = if auix.reset_stream?, do: [reset: true], else: []

    socket
    |> assign_auix(:pagination, pagination)
    |> assign_auix(:read_items, nil)
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
    select_toggle_function =
      auix
      |> Map.get(:index_selected_all_actions, [])
      |> List.first(%{})
      |> Map.get(:function_component, "")

    select_field =
      :selected_check__
      |> LayoutHelpers.parse_field(:boolean, resource_name)
      |> struct(%{label: select_toggle_function, filterable?: false})

    layout_tree.inner_elements
    |> Enum.filter(&(&1.tag == :field))
    |> Enum.map(&BasicHelpers.get_field(&1, configurations, resource_name))
    |> Enum.reject(
      &(&1.type in [:one_to_many_association, :many_to_one_association, :embeds_one])
    )
    |> then(&[select_field | &1])
    |> then(&assign_auix(socket, :index_fields, &1))
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

    function =
      fn ->
        Enum.reduce(
          1..pages_count,
          selection,
          fn page, acc_selection ->
            pagination
            |> CtxCore.to_page(page)
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

  @spec assign_filters(Socket.t()) :: Socket.t()
  defp assign_filters(%{assigns: %{auix: %{index_fields: index_fields}}} = socket) do
    filters =
      index_fields
      |> Enum.filter(& &1.filterable?)
      |> Map.new(&{to_string(&1.key), Filter.new(&1.key)})

    socket
    |> assign_auix(:filters, filters)
    |> assign_auix(:index_layout_form, to_form(filters))
  end

  @spec assign_stylesheet(Socket.t()) :: Socket.t()
  defp assign_stylesheet(%{assigns: %{auix: %{theme_module: theme_module}}} = socket) do
    stylesheet = ThemeHelper.generate_stylesheet(theme_module)

    assign_auix(socket, :stylesheet, stylesheet)
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

  @spec previous_page(map()) :: integer()
  defp previous_page(%{page: page}) when page <= 1, do: 1
  defp previous_page(%{page: page}), do: page - 1

  @spec next_page(map()) :: integer()
  defp next_page(%{page: page, pages_count: pages_count}) when page >= pages_count,
    do: pages_count

  defp next_page(%{page: page}), do: page + 1

  @spec get_page_items_id(Socket.t()) :: list()
  defp get_page_items_id(%{
         assigns: %{auix: auix}
       }) do
    auix.pagination
    |> Map.get(:opts, [])
    |> Keyword.put(:select, auix.primary_key)
    |> Keyword.put(:paginate, %{per_page: auix.pagination.per_page})
    |> then(&Map.put(auix.pagination, :opts, &1))
    |> CtxCore.to_page(auix.pagination.page)
    |> Map.get(:entries, [])
    |> Enum.map(&BasicHelpers.primary_key_value(&1, auix.primary_key))
  end
end
