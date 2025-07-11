defmodule Aurora.Uix.Web.Templates.Basic.Handlers.Form do
  @moduledoc """
  Provides a LiveComponent handler for form rendering and event management in Aurora UIX templates.

  This module implements the `Phoenix.LiveComponent` behaviour to manage form state, validation,
  and persistence for entities within the Aurora UIX framework. It handles form updates, validation,
  saving, section switching, and navigation events, integrating with context modules and routing stacks.

  ## Key Features

    - Renders and updates forms using context module functions.
    - Handles validation and save events, updating the UI and persisting changes.
    - Manages navigation and section switching within forms.
    - Integrates with routing stack for complex navigation flows.
    - Provides error handling for unhandled events.

  ## Key Constraints

    - Expects assigns to include an `:auix` map with required keys (`:entity`, `:modules`, etc.).
    - Relies on context modules to provide change, create, update, and get functions.
    - Designed for use within Aurora UIX LiveView templates.
  """

  @behaviour Phoenix.LiveComponent

  import Aurora.Uix.Web.Templates.Basic.Helpers
  import Phoenix.Component, only: [assign: 3, to_form: 1, to_form: 2]
  import Phoenix.LiveView

  alias Aurora.Uix.Stack
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Web.Templates.Basic.Renderer

  @impl true
  @doc """
  Updates the form state and assigns for the LiveComponent.

  ## Parameters

    - `assigns` (map()) - Assigns containing at least `%{auix: %{entity: map(), routing_stack: Stack.t()}}`.
    - `socket` (Phoenix.LiveView.Socket.t()) - The current LiveView socket.

  ## Returns

    - `{:ok, Phoenix.LiveView.Socket.t()}` - The updated socket with form and routing stack assigned.

  ## Examples

      iex> update(%{auix: %{entity: %User{}, routing_stack: nil}}, %{assigns: %{auix: %{modules: %{context: MyApp.Users}, change_function: :change_user}}})
      {:ok, %Phoenix.LiveView.Socket{...}}
  """
  @spec update(map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def update(
        %{auix: %{entity: entity, routing_stack: routing_stack}} = _assigns,
        %{assigns: %{auix: auix}} = socket
      ) do
    form =
      auix.modules.context
      |> apply(auix.change_function, [entity])
      |> to_form()

    {:ok,
     socket
     |> assign_auix_new(:form, form)
     |> assign_auix_new(:_sections, %{})
     |> assign_auix(:_myself, socket.assigns.myself)
     |> assign_auix(:routing_stack, routing_stack || Stack.new())
     |> render_with(&Renderer.render/1)}
  end

  @impl true
  @doc """
  Handles form-related events such as validation, saving, and section switching.

  ## Parameters

    - `event` (String.t()) - The event name (e.g., "validate", "save", "switch_section").
    - `params` (map()) - Parameters from the event.
    - `socket` (Phoenix.LiveView.Socket.t()) - The current LiveView socket.

  ## Returns

    - `{:noreply, Phoenix.LiveView.Socket.t()}` - The updated socket after handling the event.

  ## Examples

      iex> handle_event("validate", %{"user" => %{"name" => "Alice"}}, %{assigns: %{auix: %{module: "user"}}})
      {:noreply, %Phoenix.LiveView.Socket{...}}
  """
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event(event, params, %{assigns: %{auix: auix}} = socket) do
    entity_params = Map.get(params, auix.module)
    do_handle_event(event, params, entity_params, socket)
  end

  ## PRIVATE

  # Handles validation event for the form.
  @spec do_handle_event(
          String.t(),
          map(),
          map(),
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  defp do_handle_event(
         "validate",
         _params,
         %{} = entity_params,
         %{assigns: %{auix: auix}} = socket
       ) do
    socket = Phoenix.LiveView.clear_flash(socket)

    changeset =
      apply(auix.modules.context, auix.change_function, [
        socket.assigns[:auix][:entity],
        entity_params
      ])

    {:noreply, assign_auix(socket, :form, to_form(changeset, action: :validate))}
  end

  # Handles save event for the form.
  @spec do_handle_event(
          String.t(),
          map(),
          map(),
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  defp do_handle_event("save", _params, %{} = entity_params, socket) do
    socket
    |> Phoenix.LiveView.clear_flash()
    |> save(entity_params)
  end

  # Handles section switching within the form.
  @spec do_handle_event(
          String.t(),
          map(),
          map(),
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  defp do_handle_event("switch_section", %{"tab-id" => sections_tab_id}, _entity_params, socket) do
    %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

    socket = Phoenix.LiveView.clear_flash(socket)

    {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
  end

  # Handles navigation back event.
  defp do_handle_event("auix_route_back", _params, _entity_params, socket) do
    {:noreply, auix_route_back(socket)}
  end

  # Raises error for unhandled events.
  defp do_handle_event(event, params, _entity_params, _socket) do
    raise "Event not handled. event: #{inspect(event)}. params: #{inspect(params)}"
  end

  # Handles entity saving process and updates the UI accordingly.
  @spec save(Phoenix.LiveView.Socket.t(), map()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  defp save(%{assigns: %{action: action, auix: auix}} = socket, entity_params) do
    case save_entity(socket, action, entity_params) do
      {:ok, entity} ->
        notify_parent({:saved, entity})

        new_entity =
          apply(auix.modules.context, auix.get_function, [
            BasicHelpers.primary_key_value(entity, auix.primary_key),
            [preload: auix.preload]
          ])

        {:noreply,
         socket
         |> put_flash(:info, "#{auix.name} updated successfully")
         |> assign(:action, :edit)
         |> assign_auix(:entity, new_entity)
         |> conditional_route_back(action, auix.one2many_rendered?)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, format_changeset_errors(changeset))
         |> assign_auix(:form, to_form(changeset))}
    end
  end

  # Persists entity changes using the appropriate context function.
  @spec save_entity(Phoenix.LiveView.Socket.t(), atom(), map()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  defp save_entity(%{assigns: %{auix: auix}} = socket, :edit, entity_params) do
    apply(auix.modules.context, auix.update_function, [
      socket.assigns[:auix][:entity],
      entity_params
    ])
  end

  defp save_entity(%{assigns: %{auix: auix}}, :new, entity_params) do
    apply(auix.modules.context, auix.create_function, [entity_params])
  end

  # Handles routing after save based on action and rendering context.
  @spec conditional_route_back(
          Phoenix.LiveView.Socket.t(),
          atom(),
          boolean()
        ) :: Phoenix.LiveView.Socket.t()
  defp conditional_route_back(
         %{
           assigns: %{
             auix: %{routing_stack: routing_stack, entity: entity, primary_key: primary_key}
           }
         } =
           socket,
         :new,
         true
       ) do
    {new_routing_stack, original_path} = Stack.pop!(routing_stack)

    original_path
    |> Map.get(:path)
    |> URI.parse()
    |> Map.get(:path)
    |> then(&"#{&1}/#{BasicHelpers.primary_key_value(entity, primary_key)}/edit")
    |> then(
      &assign_auix(
        socket,
        :routing_stack,
        Stack.push(new_routing_stack, %{type: :navigate, path: &1})
      )
    )
    |> auix_route_back()
  end

  defp conditional_route_back(socket, _action, _one2many_rendered?),
    do: auix_route_back(socket)

  # Sends a message to the parent LiveView with the operation result.
  @spec notify_parent(tuple()) :: :ok
  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
