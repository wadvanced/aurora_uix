defmodule Aurora.Uix.Web.Templates.Basic.Handlers.IndexImpl do
  @callback auix_mount(params :: map(), session :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
              {:ok, Phoenix.LiveView.Socket.t()}

  @callback auix_handle_params(
              params :: map(),
              url :: binary(),
              socket :: Phoenix.LiveView.Socket.t()
            ) :: {:noreply, Phoenix.LiveView.Socket.t()}

  @callback auix_handle_event(
              event :: binary(),
              params :: map(),
              socket :: Phoenix.LiveView.Socket.t()
            ) :: {:noreply, Phoenix.LiveView.Socket.t()}

  @callback auix_handle_info(event_info :: term(), socket :: Phoenix.LiveView.Socket.t()) ::
              {:noreply, Phoenix.LiveView.Socket.t()}

  @callback auix_apply_action(socket :: Phoenix.LiveView.Socket.t(), action :: atom(), params :: map()) :: Phoenix.LiveView.Socket.t()
  alias Aurora.Uix.Web.Templates.Basic.Handlers.IndexImpl

  defmacro __using__(_opts) do
    quote do
      @behaviour IndexImpl
      @behaviour Phoenix.LiveView

      import Aurora.Uix.Web.Templates.Basic.Helpers
      import Phoenix.LiveView

      alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
      alias Aurora.Uix.Web.Templates.Basic.Renderer

      @impl Phoenix.LiveView
      def mount(params, session, socket) do
        auix_mount(params, session, socket)
      end

      @impl Phoenix.LiveView
      def handle_params(params, url, socket) do
        auix_handle_params(params, url, socket)
      end

      @impl Phoenix.LiveView
      def handle_event(event, params, socket) do
        auix_handle_event(event, params, socket)
      end

      @impl Phoenix.LiveView
      def handle_info(event_info, socket) do
        auix_handle_info(event_info, socket)
      end

      @impl IndexImpl
      def auix_mount(_params, _session, %{assigns: %{auix: auix}} = socket) do
        {:ok, stream(socket, auix.list_key, apply(auix.modules.context, auix.list_function, []))}
      end

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
      def auix_handle_params(params, url, %{assigns: %{auix: auix}} = socket) do
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
         |> auix_apply_action(socket.assigns.live_action, params)}
      end

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
      def auix_handle_event(
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

      def auix_handle_event("delete", %{"id" => id}, %{assigns: %{auix: auix}} = socket) do
        instance = apply(auix.modules.context, auix.get_function, [id])
        {:ok, _} = apply(auix.modules.context, auix.delete_function, [instance])
        {:noreply, stream_delete(socket, auix.list_key, instance)}
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
        {:noreply, auix_route_back(socket)}
      end

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
      def auix_handle_info({_component, {:saved, entity}}, %{assigns: %{auix: auix}} = socket) do
        {:noreply, stream_insert(socket, auix.list_key, entity)}
      end

      def auix_handle_info(_input, socket) do
        {:noreply, socket}
      end

      @impl IndexImpl
      # Assigns entity for edit action.
      def auix_apply_action(%{assigns: %{auix: auix}} = socket, :edit, %{"id" => id} = _params) do
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
      def auix_apply_action(%{assigns: %{auix: auix}} = socket, :new, params) do
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
      def auix_apply_action(socket, :index, _params) do
        assign_auix(socket, :entity, nil)
      end
    end
  end
end
