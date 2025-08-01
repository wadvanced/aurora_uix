defmodule Aurora.Uix.Templates.Basic.Handlers.ShowImpl do
  @moduledoc """
  Behaviour and macro for implementing show view handlers in Aurora UIX LiveView templates.

  Provides a set of callbacks and a `__using__/1` macro to standardize the handling of mount, parameter changes,
  events, info messages, and action application for show views. Designed for use with Phoenix LiveView and
  Aurora UIX conventions.

  ## Key Features

    - Defines required callbacks for the show modal lifecycle and event handling.
    - Supplies a macro to inject default implementations and imports for LiveView modules.
    - Integrates with Aurora UIX context and module generators for dynamic entity management.

  ## Key Constraints

    - Expects the `:auix` assign to be present in the LiveView socket.
    - Designed for use with Phoenix LiveView and Aurora UIX context modules.
    - Assumes certain structure in the `auix` assign (e.g., `modules.context`, `source_key`, etc.).

  """
  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.LiveView

  alias Aurora.Uix.Templates.Basic.Handlers.ShowImpl
  alias Aurora.Uix.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Templates.Basic.Renderer

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  defmacro __using__(_opts) do
    quote do
      @behaviour LiveView

      @doc false
      @impl LiveView
      defdelegate mount(params, session, socket), to: ShowImpl

      @doc false
      @impl LiveView
      defdelegate handle_params(params, url, socket), to: ShowImpl

      @doc false
      @impl LiveView
      defdelegate handle_event(event, params, socket), to: ShowImpl

      defoverridable LiveView
    end
  end

  @doc """
  Initializes the LiveView socket for the show page.

  ## Parameters
    - `params` (map()) - Request parameters (unused).
    - `session` (map()) - Session data (unused).
    - `socket` (Socket.t()) - The LiveView socket.

  ## Returns

    - `{:ok, Socket.t()}` - The initialized socket.
  """
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @doc """
  Handles URL parameter changes and loads the entity for display.

  ## Parameters
    - `params` (map()) - Parameters including the entity ID.
    - `url` (binary()) - The current URL.
    - `socket` (Socket.t()) - The LiveView socket with `:auix` assigns.

  ## Returns

    - `{:noreply, Socket.t()}` - The updated socket with entity and navigation assigns.
  """
  @spec handle_params(map(), binary(), Socket.t()) ::
          {:noreply, Socket.t()}
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

  @doc """
  Handles all supported LiveView events for the show page.

  - `"switch_section"`: Switches between sections/tabs.
  - `"delete"`: Deletes an entity and navigates back on success.
  - `"auix_route_forward"`: Handles forward navigation (navigate/patch).
  - `"auix_route_back"`: Handles backward navigation.

  ## Parameters

    - `event` (binary()) - The event name.
    - `params` (map()) - Event parameters.
    - `socket` (Socket.t()) - The LiveView socket.

  ## Returns

    - `{:noreply, Socket.t()}` - The updated socket.

  """
  @spec handle_event(binary(), map(), Socket.t()) ::
          {:noreply, Socket.t()}
  def handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
    %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)
    {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
  end

  def handle_event("delete", params, socket) do
    %{
      "id" => id,
      "get_function" => get_function_string,
      "delete_function" => delete_function_string
    } = params

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
