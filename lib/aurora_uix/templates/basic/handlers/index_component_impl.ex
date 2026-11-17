defmodule Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl do
  @moduledoc """
  Behaviour and macro for the handlers of a generated index component: the list of a resource as
  a LiveComponent that a host renders in a LiveView it writes.

  ## Key Features

  - Runs the list engine (`Aurora.Uix.Templates.Basic.Handlers.IndexList`) on the socket of the
    component: filters, sort, pagination, selection and row actions.
  - Takes the inputs `where`, `order_by`, `parent`, `page`, `options` and `notify`. The list is
    re-initialised only when one of the first five changes.
  - Reports what the user did as intents: `{:open, action, id}`, `{:deleted, ids}` and
    `{:page, page}`.
  - Every instance derives its DOM ids, its stream ids and its event target from its component
    `id`, so several instances share a page.

  ## Key Constraints

  - It never navigates: the host decides what an intent does.
  - Events reach the instance through `@auix._myself`, the `phx-target` of its markup.
  - An `Aurora.Uix.Event` reaches the instance through `update/2`, given with `send_update/3` as
    `auix_event`.
  """

  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView

  alias Aurora.Uix.Event
  alias Aurora.Uix.Live.ComponentHooks
  alias Aurora.Uix.Templates.Basic.Actions.Index, as: IndexActions
  alias Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl
  alias Aurora.Uix.Templates.Basic.Handlers.IndexList
  alias Aurora.Uix.Templates.Basic.Renderers.IndexRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.OneToMany
  alias Phoenix.LiveComponent
  alias Phoenix.LiveView.Socket

  @list_events IndexList.events()
  @input_keys [:where, :order_by, :parent, :page, :options]

  @doc """
  Initialises the list of the instance from its inputs, or applies an `Aurora.Uix.Event`.

  ## Parameters
  - `assigns` (map()) - The assigns of the component's `update/2`.
  - `socket` (Socket.t()) - The component socket, with its compiled options in `auix`.

  ## Returns
  `{:ok, Socket.t()}` - The updated socket.
  """
  @callback auix_update(assigns :: map(), socket :: Socket.t()) :: {:ok, Socket.t()}

  @doc """
  Handles the events of the instance.

  ## Parameters
  - `event` (binary()) - Event name.
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - The component socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after event handling.
  """
  @callback auix_handle_event(event :: binary(), params :: map(), socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @doc """
  Handles the results of the async tasks of the instance.

  ## Parameters
  - `task` (atom()) - Task name.
  - `result` (term()) - Async task result.
  - `socket` (Socket.t()) - The component socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after handling the result.
  """
  @callback auix_handle_async(task :: atom(), result :: term(), socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour LiveComponent
      @behaviour IndexComponentImpl

      @doc false
      @impl LiveComponent
      @spec update(map(), Socket.t()) :: {:ok, Socket.t()}
      def update(assigns, socket), do: auix_update(assigns, socket)

      @doc false
      @impl LiveComponent
      @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_event(event, params, socket), do: auix_handle_event(event, params, socket)

      @doc false
      @impl LiveComponent
      @spec handle_async(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_async(task, result, socket), do: auix_handle_async(task, result, socket)

      @doc false
      @impl IndexComponentImpl
      defdelegate auix_update(assigns, socket), to: IndexComponentImpl

      @doc false
      @impl IndexComponentImpl
      defdelegate auix_handle_event(event, params, socket), to: IndexComponentImpl

      @doc false
      @impl IndexComponentImpl
      defdelegate auix_handle_async(task, result, socket), to: IndexComponentImpl

      defoverridable LiveComponent
      defoverridable auix_update: 2
      defoverridable auix_handle_event: 3
      defoverridable auix_handle_async: 3
    end
  end

  @doc """
  Initialises the list of the instance from its inputs, or applies an `Aurora.Uix.Event`.

  An update whose inputs equal the previous ones only takes the new `notify`, so the selection,
  the page and the filters survive a re-render of the host.

  An update carrying `one_to_many` renders the rows of a one-to-many list instead: the rows are
  reloaded only when the preloaded value of the field, its `where` or its `order_by` change.

  ## Parameters
  - `assigns` (map()) - The assigns of the component's `update/2`: the inputs, or `auix_event`.
  - `socket` (Socket.t()) - The component socket, with its compiled options in `auix`.

  ## Returns
  `{:ok, Socket.t()}` - The updated socket.
  """
  @spec auix_update(map(), Socket.t()) :: {:ok, Socket.t()}
  def auix_update(%{one_to_many: one_to_many}, socket) do
    key =
      {Map.get(one_to_many.auix.entity || %{}, one_to_many.field.key),
       Map.get(one_to_many.auix.layout_tree, :where),
       Map.get(one_to_many.auix.layout_tree, :order_by)}

    socket =
      if socket.assigns[:one_to_many_key] != key,
        do:
          socket
          |> assign(:rows, OneToMany.load_rows(one_to_many))
          |> assign(:one_to_many_key, key),
        else: socket

    socket
    |> assign(:one_to_many, one_to_many)
    |> render_with(&IndexRenderer.render_child/1)
    |> then(&{:ok, &1})
  end

  def auix_update(%{auix_event: %Event{} = event}, %{assigns: %{auix: %{_inputs: _}}} = socket),
    do: {:ok, IndexList.apply_event(socket, event)}

  def auix_update(%{auix_event: _event}, socket), do: {:ok, socket}

  def auix_update(assigns, socket) do
    inputs = Map.take(assigns, @input_keys)

    if socket.assigns.auix[:_inputs] == inputs,
      do: {:ok, assign_auix(socket, :notify, Map.get(assigns, :notify, self()))},
      else: {:ok, initialize(socket, assigns, inputs)}
  end

  @doc """
  Handles the events of the instance: the list events, the row and header actions, and the
  pagination.

  ## Parameters
  - `event` (binary()) - Event name.
  - `params` (map()) - Event parameters.
  - `socket` (Socket.t()) - The component socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket after event handling. Raises for an event it does not
  handle.
  """
  @spec auix_handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_event(event, params, socket) when event in @list_events,
    do: IndexList.handle_event(event, params, socket)

  def auix_handle_event("auix_open", params, socket), do: {:noreply, report_open(socket, params)}

  def auix_handle_event("delete", %{"id" => id}, socket) do
    {socket, ids} = IndexList.delete(socket, id)
    {:noreply, report_intent(socket, {:deleted, ids})}
  end

  def auix_handle_event("pagination_to_page", %{"page" => page}, socket),
    do: {:noreply, to_page(socket, String.to_integer(page))}

  def auix_handle_event("pagination_previous", params, %{assigns: %{auix: auix}} = socket) do
    if auix.layout_options.pagination_disabled? or Map.get(params, "pagination_disabled?") do
      {:noreply,
       IndexList.paginate(socket, auix.pagination.page - 1, Map.get(params, "items_per_page"))}
    else
      {:noreply, to_page(socket, IndexList.previous_page(auix.pagination))}
    end
  end

  def auix_handle_event("pagination_next", params, %{assigns: %{auix: auix}} = socket) do
    if auix.layout_options.pagination_disabled? or Map.get(params, "pagination_disabled?") do
      {:noreply,
       IndexList.paginate(socket, auix.pagination.page + 1, Map.get(params, "items_per_page"))}
    else
      {:noreply, to_page(socket, IndexList.next_page(auix.pagination))}
    end
  end

  def auix_handle_event(event, params, _socket) do
    raise "Event not handled. event: #{inspect(event)}. params: #{inspect(params)}"
  end

  @doc """
  Handles the results of the selection async tasks. A bulk delete reports `{:deleted, ids}`.

  ## Parameters
  - `task` (atom()) - Task name (`:auix_selection_toggle_all` or `:auix_selection_delete_all`).
  - `result` (term()) - Result of the async task.
  - `socket` (Socket.t()) - The component socket.

  ## Returns
  `{:noreply, Socket.t()}` - Updated socket with the new selection.
  """
  @spec auix_handle_async(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}
  def auix_handle_async(:auix_selection_delete_all, {:ok, ids} = result, socket) do
    {:noreply, socket} = IndexList.handle_async(:auix_selection_delete_all, result, socket)
    {:noreply, report_intent(socket, {:deleted, ids})}
  end

  def auix_handle_async(task, result, socket), do: IndexList.handle_async(task, result, socket)

  ## PRIVATE

  @spec initialize(Socket.t(), map(), map()) :: Socket.t()
  defp initialize(socket, assigns, inputs) do
    id = socket.assigns.id
    first? = not Map.has_key?(socket.assigns.auix, :_inputs)

    socket
    |> assign_auix(:_inputs, inputs)
    |> assign_auix(:_myself, socket.assigns.myself)
    |> assign_auix(:_instance, id)
    |> assign_auix(:notify, Map.get(assigns, :notify, self()))
    |> assign_auix(:index_form_id, "auix-index-form-#{id}")
    |> assign_auix(:entity, nil)
    |> assign_auix(:item_index, -1)
    |> assign_auix_new(:_base_layout_tree, socket.assigns.auix.layout_tree)
    |> assign_instance_layout_tree(inputs)
    |> IndexList.init(
      %{"page" => to_string(Map.get(inputs, :page, 1))},
      &prepare(&1, id, first?)
    )
    |> assign_instance_field_ids(id)
    |> register_for_events(first?)
    |> render_with(&IndexRenderer.render_component/1)
  end

  @spec register_for_events(Socket.t(), boolean()) :: Socket.t()
  defp register_for_events(socket, true) do
    if connected?(socket),
      do:
        ComponentHooks.register(
          socket.assigns.myself,
          IndexList.resource_schema(socket.assigns.auix)
        )

    socket
  end

  defp register_for_events(socket, false), do: socket

  @spec assign_instance_layout_tree(Socket.t(), map()) :: Socket.t()
  defp assign_instance_layout_tree(%{assigns: %{auix: auix}} = socket, inputs) do
    base = auix._base_layout_tree
    resource_config = auix.configurations[auix.resource_name].resource_config

    where_scope = inputs |> Map.get(:where) |> IndexList.where_conditions()
    scope = inputs |> Map.get(:parent) |> parent_scope() |> Kernel.++(where_scope)

    where =
      if scope == [],
        do: base.where,
        else: IndexList.where_conditions(base.where || resource_config.where) ++ scope

    layout_tree =
      struct(base, %{
        where: where,
        order_by: Map.get(inputs, :order_by) || base.order_by,
        options: Keyword.merge(base.options, Map.get(inputs, :options, []))
      })

    assign_auix(socket, :layout_tree, layout_tree)
  end

  @spec parent_scope({atom(), term()} | nil) :: list()
  defp parent_scope({key, value}), do: [{key, value}]
  defp parent_scope(nil), do: []

  # A stream is configured once, before its first `stream/4`.
  @spec prepare(Socket.t(), binary(), boolean()) :: Socket.t()
  defp prepare(socket, id, first?) do
    socket = IndexActions.set_actions(socket)
    if first?, do: configure_streams(socket, id), else: socket
  end

  @spec configure_streams(Socket.t(), binary()) :: Socket.t()
  defp configure_streams(%{assigns: %{auix: auix}} = socket, id) do
    suffix_names =
      Enum.map(auix.layout_options.alternate_streams_suffixes, &"#{auix.source_key}__#{&1}")

    Enum.reduce([auix.source_key | suffix_names], socket, fn name, acc ->
      stream_configure(acc, name, dom_id: &"#{id}-#{name}-#{&1.id}")
    end)
  end

  @spec assign_instance_field_ids(Socket.t(), binary()) :: Socket.t()
  defp assign_instance_field_ids(%{assigns: %{auix: auix}} = socket, id) do
    auix.index_fields
    |> Enum.map(&struct(&1, %{html_id: "#{id}-#{&1.html_id}"}))
    |> then(&assign_auix(socket, :index_fields, &1))
  end

  @spec to_page(Socket.t(), integer()) :: Socket.t()
  defp to_page(socket, page) do
    socket
    |> IndexList.paginate(page, nil)
    |> report_intent({:page, page})
  end
end
