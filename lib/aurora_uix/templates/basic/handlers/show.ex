defmodule Aurora.Uix.Web.Templates.Basic.Handlers.Show do
  @moduledoc """
  Handles LiveView events and rendering for the "show" page of an entity in the Aurora UIX basic template.

  Provides LiveView callbacks and event handlers for:
    - Rendering entity details.
    - Switching between sections/tabs.
    - Deleting entities with feedback and navigation.
    - Forward and backward navigation within the UI.

  ## Key Features

    - Loads and displays a single entity using context and function references from assigns.
    - Handles tab/section switching via `"switch_section"` events.
    - Supports entity deletion with feedback and navigation.
    - Manages forward and backward routing events for navigation.

  ## Key Constraints

    - Expects `:auix` assign to be present in the socket, containing context, function, and preload info.
    - Assumes the presence of supporting modules: `ModulesGenerator`, `Renderer`, and helpers.
  """

  @behaviour Phoenix.LiveView

  import Aurora.Uix.Web.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Web.Templates.Basic.Renderer

  @impl true
  @doc """
  Initializes the LiveView socket for the show page.

  ## Parameters

    - `_params` (map()) - Request parameters (unused).
    - `_session` (map()) - Session data (unused).
    - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns

    - `{:ok, Phoenix.LiveView.Socket.t()}` - The initialized socket.
  """
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  @doc """
  Handles URL parameter changes and loads the entity for display.

  ## Parameters

    - `params` (map()) - Parameters including the entity ID.
    - `url` (String.t()) - The current URL.
    - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket with `:auix` assigns.

  ## Returns

    - `{:noreply, Phoenix.LiveView.Socket.t()}` - The updated socket with entity and navigation assigns.
  """
  @spec handle_params(map(), String.t(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(%{"id" => id} = params, url, %{assigns: %{auix: auix}} = socket) do
    form_component = ModulesGenerator.module_name(auix, ".FormComponent")

    {:noreply,
     socket
     |> assign_auix_new(:_sections, %{})
     |> assign_auix(:entity, auix.get_function.(id, preload: auix.preload))
     |> assign_auix(:form_component, form_component)
     |> assign_auix_current_path(url)
     |> assign_auix_routing_stack(params, %{
       type: :navigate,
       path: "/#{auix.link_prefix}#{auix.source}"
     })
     |> render_with(&Renderer.render/1)}
  end

  @impl true
  @doc """
  Handles all supported LiveView events for the show page.

  - `"switch_section"`: Switches between sections/tabs.
  - `"delete"`: Deletes an entity and navigates back on success.
  - `"auix_route_forward"`: Handles forward navigation (navigate/patch).
  - `"auix_route_back"`: Handles backward navigation.

  ## Parameters

    - `event` (String.t()) - The event name.
    - `params` (map()) - Event parameters.
    - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns

    - `{:noreply, Phoenix.LiveView.Socket.t()}` - The updated socket.

  ## Examples

      iex> handle_event("switch_section", %{"tab-id" => encoded}, socket)
      {:noreply, %Phoenix.LiveView.Socket{}}

      iex> handle_event("delete", %{"id" => "1", ...}, socket)
      {:noreply, %Phoenix.LiveView.Socket{}}
  """
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
    %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)
    {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
  end

  def handle_event("delete", params, socket) do
    %{
      "id" => id,
      "context" => context_string,
      "get_function" => get_function_string,
      "delete_function" => delete_function_string
    } = params

    context = String.to_existing_atom(context_string)
    {get_function, _} = Code.eval_string(get_function_string)
    delete_function = String.to_existing_atom(delete_function_string)

    socket =
      with %{} = entity <- get_function.(id, []),
           {:ok, _changeset} <- apply(context, delete_function, [entity]) do
        socket
        |> put_flash(:info, "Item deleted successfully")
        |> push_patch(to: socket.assigns.auix[:_current_path])
      else
        _ -> socket
      end

    {:noreply, socket}
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
end
