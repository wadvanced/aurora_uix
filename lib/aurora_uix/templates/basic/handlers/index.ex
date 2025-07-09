defmodule Aurora.Uix.Web.Templates.Basic.Handlers.Index do
  @moduledoc """
  LiveView handler for index pages in Aurora UIX.

  Manages the lifecycle and event handling for index views, including streaming, navigation,
  deletion, and entity assignment. Integrates with Aurora UIX helpers and rendering pipeline.

  ## Key Features

    - Streams entities for efficient index rendering.
    - Handles navigation, patching, and routing stack for index and form components.
    - Supports deletion of entities with context-aware logic.
    - Integrates with Aurora UIX helpers and rendering pipeline.

  ## Key Constraints

    - Expects `:auix` key in assigns with required subkeys for context, functions, and configuration.
    - Designed for use within Phoenix LiveView index templates.
  """

  @behaviour Phoenix.LiveView

  import Aurora.Uix.Web.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Web.Templates.Basic.Renderer

  @impl true
  @doc """
  Initializes the index LiveView, streaming entities for the list key.

  ## Parameters
  - `_params`: URL/query parameters (map)
  - `_session`: Session data (map)
  - `socket`: LiveView socket with `:auix` assigns (Phoenix.LiveView.Socket.t)

  ## Returns
  - `{:ok, Phoenix.LiveView.Socket.t}`: Socket with streamed entities
  """
  def mount(_params, _session, %{assigns: %{auix: auix}} = socket) do
    {:ok, stream(socket, auix.list_key, apply(auix.modules.context, auix.list_function, []))}
  end

  @impl true
  @doc """
  Handles URL parameter changes, updates routing stack, and assigns form component.

  ## Parameters
  - `params`: URL/query parameters (map)
  - `url`: Current URL (String.t)
  - `socket`: LiveView socket with `:auix` assigns (Phoenix.LiveView.Socket.t)

  ## Returns
  - `{:noreply, Phoenix.LiveView.Socket.t}`: Updated socket
  """
  def handle_params(params, url, %{assigns: %{auix: auix}} = socket) do
    form_component = ModulesGenerator.module_name(auix.modules, auix, ".FormComponent")

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
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
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
  def handle_event(
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

  def handle_event("delete", %{"id" => id}, %{assigns: %{auix: auix}} = socket) do
    instance = apply(auix.modules.context, auix.get_function, [id])
    {:ok, _} = apply(auix.modules.context, auix.delete_function, [instance])
    {:noreply, stream_delete(socket, auix.list_key, instance)}
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

  @impl true
  @doc """
  Handles info messages for the LiveView. If the message is a tuple of the form `{_component, {:saved, entity}}`,
  it inserts the entity into the stream. Otherwise, it returns the unchanged socket.

  ## Parameters
  - `{_component, {:saved, entity}}` or any other message: Info message (tuple or any)
  - `socket`: LiveView socket with `:auix` assigns (Phoenix.LiveView.Socket.t)

  ## Returns
  - `{:noreply, Phoenix.LiveView.Socket.t}`: Updated socket
  """
  def handle_info({_component, {:saved, entity}}, %{assigns: %{auix: auix}} = socket) do
    {:noreply, stream_insert(socket, auix.list_key, entity)}
  end

  def handle_info(_input, socket) do
    {:noreply, socket}
  end

  ## PRIVATE

  @spec apply_action(Phoenix.LiveView.Socket.t(), atom(), map()) :: Phoenix.LiveView.Socket.t()
  # Assigns entity for edit action.
  defp apply_action(%{assigns: %{auix: auix}} = socket, :edit, %{"id" => id} = _params) do
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
  defp apply_action(%{assigns: %{auix: auix}} = socket, :new, params) do
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
  defp apply_action(socket, :index, _params) do
    assign_auix(socket, :entity, nil)
  end
end
