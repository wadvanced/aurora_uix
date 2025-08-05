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
  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
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
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> load_items()
     |> maybe_create_stream(socket)}
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
     |> assign(:test, "--")
     |> assign_auix(:form_component, form_component)
     |> assign_auix(:filters_enabled?, false)
     |> assign_index_fields()
     |> assign_filters()
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
    entity = auix.get_function.(id)
    {:ok, _} = auix.delete_function.(entity)
    {:noreply, stream_delete(socket, auix.source_key, entity)}
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

  def handle_event(
        "filter-change",
        %{"_target" => ["condition__" <> filter_key = condition_key]} = params,
        socket
      ) do
    socket =
      update_filter(socket, filter_key, %{
        condition: params |> Map.get(condition_key) |> String.to_existing_atom()
      })

    {:noreply, socket}
  end

  def handle_event(
        "filter-change",
        %{"_target" => ["to__" <> filter_key = to_key]} = params,
        socket
      ) do
    socket = update_filter(socket, filter_key, %{to: params[to_key]})
    {:noreply, socket}
  end

  def handle_event(
        "filter-change",
        %{"_target" => ["from__" <> filter_key = from_key]} = params,
        socket
      ) do
    socket = update_filter(socket, filter_key, %{from: params[from_key]})
    {:noreply, socket}
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
     |> load_items(where: filters)
     |> maybe_create_stream(socket)}
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
        _params,
        %{assigns: %{auix: %{pagination: %Pagination{} = pagination} = auix}} = socket
      ) do
    {:noreply,
     auix_route_forward(socket,
       patch: "/#{auix.link_prefix}#{auix.source}?page=#{previous_page(pagination)}"
     )}
  end

  def handle_event("pagination_previous", _params, socket), do: {:noreply, socket}

  def handle_event(
        "pagination_next",
        _params,
        %{assigns: %{auix: %{pagination: %Pagination{} = pagination} = auix}} = socket
      ) do
    {:noreply,
     auix_route_forward(socket,
       patch: "/#{auix.link_prefix}#{auix.source}?page=#{next_page(pagination)}"
     )}
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

  def apply_action(
        %{
          assigns: %{
            live_action: :index,
            auix: %{pagination: %{repo_module: _repo_module} = pagination}
          }
        } = socket,
        %{"page" => page}
      ) do
    pagination
    |> CtxCore.to_page(String.to_integer(page))
    |> maybe_create_stream(socket)
    |> assign_auix(:entity, nil)
  end

  def apply_action(%{assigns: %{live_action: :index}} = socket, %{"page" => page}) do
    socket
    |> load_items()
    |> then(fn
      %{
        assigns: %{auix: %{pagination: %{repo_module: _, schema_module: _, page: _} = pagination}}
      } ->
        CtxCore.to_page(pagination, page)

      entries ->
        entries
    end)
    |> maybe_create_stream(socket)
    |> assign_auix(:entity, nil)
  end

  def apply_action(%{assigns: %{live_action: :index}} = socket, _params) do
    assign_auix(socket, :entity, nil)
  end

  ## PRIVATE
  @spec load_items(Socket.t(), keyword()) :: Socket.t()
  defp load_items(%{assigns: %{auix: auix} = assigns}, extra_options \\ []) do
    layout_opts = Map.get(auix.layout_tree, :opts, [])

    opts =
      auix
      |> get_in([:configurations, auix.resource_name, :resource_config])
      |> Map.get(:opts, [])
      |> Keyword.merge(layout_opts)
      |> Keyword.put_new(:order_by, [])
      |> Keyword.put_new(:where, [])

    list_function =
      case LayoutOptions.get(assigns, :disable_pagination) do
        {:ok, true} -> auix.list_function
        _ -> auix.list_function_paginated
      end

    full_options =
      Enum.map(opts, &merge_extra_option(&1, extra_options))

    list_function.(
      order_by: Keyword.get(full_options, :order_by),
      where: Keyword.get(full_options, :where)
    )
  end

  @spec maybe_create_stream(map(), Socket.t()) :: Socket.t()
  defp maybe_create_stream(
         %{entries: entries} = pagination,
         %{assigns: %{auix: %{primary_key: primary_key, source: source}}} = socket
       ) do
    entries
    |> Enum.map(&normalize_entry(&1, source, primary_key))
    |> then(&assign_auix(socket, :rows, &1))
    |> assign_auix(:pagination, pagination)
  end

  defp maybe_create_stream(entries, %{assigns: %{auix: auix}} = socket) do
    socket
    |> assign_auix(:pagination, nil)
    |> stream(
      auix.source_key,
      entries,
      reset: true
    )
  end

  @spec normalize_entry(map(), binary(), list() | atom()) :: tuple()
  defp normalize_entry(entry, source, primary_key) do
    entry
    |> BasicHelpers.primary_key_value(primary_key)
    |> then(&{"#{source}-#{&1}", entry})
  end

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

  @spec assign_index_fields(Socket.t()) :: Socket.t()
  defp assign_index_fields(
         %{
           assigns: %{
             auix: %{
               configurations: configurations,
               layout_tree: layout_tree,
               resource_name: resource_name
             }
           }
         } = socket
       ) do
    layout_tree.inner_elements
    |> Enum.filter(&(&1.tag == :field))
    |> Enum.map(&BasicHelpers.get_field(&1, configurations, resource_name))
    |> Enum.reject(&(&1.type in [:one_to_many_association, :many_to_one_association]))
    |> then(&assign_auix(socket, :index_fields, &1))
  end

  @spec assign_filters(Socket.t()) :: Socket.t()
  defp assign_filters(%{assigns: %{auix: %{index_fields: index_fields}}} = socket) do
    filters =
      index_fields
      |> Enum.filter(& &1.filterable?)
      |> Map.new(&{to_string(&1.key), Filter.new(&1.key)})

    socket
    |> assign_auix(:filters, filters)
    |> assign_auix(:filters_form, to_form(filters))
  end

  @spec update_filter(Socket.t(), binary(), map()) :: Socket.t()
  defp update_filter(%{assigns: %{auix: %{filters: filters}}} = socket, filter_key, attrs) do
    filters =
      filters
      |> Map.get(filter_key, Filter.new(filter_key))
      |> Filter.change(attrs)
      |> then(&Map.put(filters, filter_key, &1))

    socket
    |> put_in([Access.key!(:assigns), :auix, :filters], filters)
    |> assign_auix(:filters_form, to_form(filters))
  end

  @spec previous_page(map()) :: integer()
  defp previous_page(%{page: page}) when page <= 1, do: 1
  defp previous_page(%{page: page}), do: page - 1

  @spec next_page(map()) :: integer()
  defp next_page(%{page: page, pages_count: pages_count}) when page >= pages_count,
    do: pages_count

  defp next_page(%{page: page}), do: page + 1
end
