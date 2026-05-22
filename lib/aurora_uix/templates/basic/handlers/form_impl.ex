defmodule Aurora.Uix.Templates.Basic.Handlers.FormImpl do
  @moduledoc """
  Behaviour and macro for implementing form live view component handlers in Aurora UIX LiveView templates.

  Provides a set of callbacks and a `__using__/1` macro to standardize the handling of mount, parameter changes,
  events, info messages, and action application. Designed for use with Phoenix LiveView and
  Aurora UIX conventions.

  ## Key Features

    - Defines required callbacks for form live component lifecycle and event handling.
    - Supplies a macro to inject default implementations and imports for LiveView modules.
    - Integrates with Aurora UIX context and module generators for dynamic entity management.

  ## Key Constraints

    - Expects the `:auix` assign to be present in the LiveView socket.
    - Designed for use with Phoenix LiveView and Aurora UIX context modules.
    - Assumes certain structure in the `auix` assign (e.g., `modules.context`, `source_key`, etc.).

  """
  import Aurora.Uix.Integration.Crud
  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView

  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Stack
  alias Aurora.Uix.Templates.Basic.Actions.Form, as: FormActions
  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  alias Phoenix.LiveComponent
  alias Phoenix.LiveView.Socket

  @doc """
  Updates the form state and assigns for the LiveComponent.

  ## Parameters
  - `assigns` (map()) - Assigns containing at least `%{auix: %{entity: map(), routing_stack: Stack.t()}}`.
  - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns
  `{:ok, Socket.t()}` - The updated socket with form and routing stack assigned.
  """
  @callback auix_update(assigns :: map(), socket :: Socket.t()) :: {:ok, Socket.t()}

  @doc """
  Internally handles all LiveView events for the form component.

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
  Performs the creation or update of an entity.

  Should perform the creation or update of an entity based on the current action in the socket
  assigns (`:edit` for updates, `:new` for creation).

  ## Parameters
  - `socket` (Socket.t()) - Current socket with assigns containing action type.
  - `entity_params` (map()) - Parameters conforming to the entity schema for persistence.

  ## Returns
  `{:ok, struct()}` - If the entity was correctly saved.
  `{:error, Ecto.Changeset.t()}` - If any error occurred with changeset details.
  """
  @callback save_entity(socket :: Socket.t(), entity_params :: map()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour LiveComponent
      @behaviour FormImpl

      @doc false
      @impl LiveComponent
      @spec update(map(), Socket.t()) :: {:ok, Socket.t()}
      def update(assigns, socket), do: auix_update(assigns, socket)

      @doc false
      @impl LiveComponent
      @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_event(
            "save",
            params,
            %{assigns: %{action: action, auix: auix}} = socket
          ) do
        entity_params = Map.get(params, auix.module)

        with {:ok, consumed_params} <- FormImpl.auix_consume_uploads(socket, entity_params),
             {:ok, entity} <- save_entity(socket, consumed_params) do
          FormImpl.notify_parent({:saved, entity})

          new_entity =
            entity
            |> BasicHelpers.primary_key_value(auix.primary_key)
            |> then(&apply_get_function(auix.get_function, &1, preload: auix.preload))

          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:info, "#{auix.name} updated successfully")
           |> assign(:action, :edit)
           |> assign_auix(:entity, new_entity)
           |> FormImpl.conditional_route_back(action, auix.one2many_rendered?)}
        else
          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             socket
             |> clear_flash()
             |> put_flash(:error, format_changeset_errors(changeset))
             |> assign_auix(:form, BasicHelpers.to_named_form(changeset, auix.module))}

          {:error, reason} ->
            {:noreply,
             socket
             |> clear_flash()
             |> put_flash(:error, reason)}
        end
      end

      def handle_event(event, params, socket), do: auix_handle_event(event, params, socket)

      @doc false
      @impl FormImpl
      defdelegate auix_update(assigns, socket), to: FormImpl

      @doc false
      @impl FormImpl
      defdelegate auix_handle_event(event, params, socket), to: FormImpl

      @doc false
      @impl FormImpl
      defdelegate save_entity(socket, entity_params), to: FormImpl

      defoverridable LiveComponent
      defoverridable auix_update: 2
      defoverridable auix_handle_event: 3
      defoverridable save_entity: 2
    end
  end

  @doc """
  Updates the form state and assigns for the LiveComponent.

  ## Parameters
  - `assigns` (map()) - Assigns containing at least `%{auix: %{entity: map(), routing_stack: Stack.t()}}`.
  - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns
  `{:ok, Socket.t()}` - The updated socket with form and routing stack assigned.
  """
  @spec auix_update(map(), Socket.t()) :: {:ok, Socket.t()}
  def auix_update(
        %{auix: %{entity: entity, routing_stack: routing_stack}} = _assigns,
        %{assigns: %{auix: auix}} = socket
      ) do
    form =
      auix.change_function
      |> apply_change_function(entity, auix.module, %{})
      |> to_named_form(auix.module)

    {:ok,
     socket
     |> assign_auix_new(:form, form)
     |> assign_auix_new(:_sections, %{})
     |> assign_auix(:_myself, socket.assigns.myself)
     |> assign_auix(:routing_stack, routing_stack || Stack.new())
     |> assign_layout_options()
     |> FormActions.set_actions()
     |> maybe_allow_uploads(auix)
     |> then(fn s -> assign_auix(s, :uploads, s.assigns[:uploads] || %{}) end)
     |> render_with(&Renderer.render/1)}
  end

  @doc """
  Handles form-related events such as validation, saving, and section switching.

  ## Parameters
  - `event` (binary()) - The event name (e.g., "validate", "save", "switch_section").
  - `params` (map()) - Parameters from the event.
  - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns
  `{:noreply, Socket.t()}` - The updated socket after handling the event.

  """
  @spec auix_handle_event(binary(), map(), Socket.t()) ::
          {:noreply, Socket.t()}
  # def auix_handle_event(event, params, %{assigns: %{auix: auix}} = socket) do
  #   entity_params = Map.get(params, auix.module)
  #   handle_event(event, params, entity_params, socket)
  # end

  def auix_handle_event(
        "validate",
        params,
        %{assigns: %{auix: auix}} = socket
      ) do
    entity_params = Map.get(params, auix.module)

    socket = Phoenix.LiveView.clear_flash(socket)

    form =
      auix.change_function
      |> apply_change_function(socket.assigns[:auix][:entity], auix.module, entity_params)
      |> to_named_form(auix.module, action: :validate)

    {:noreply, assign_auix(socket, :form, form)}
  end

  def auix_handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
    %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

    socket = Phoenix.LiveView.clear_flash(socket)

    {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
  end

  def auix_handle_event("auix_route_back", _params, socket) do
    {:noreply, auix_route_back(socket)}
  end

  def auix_handle_event("auix_cancel_upload", %{"field" => field, "ref" => ref}, socket) do
    key = String.to_existing_atom(field)
    {:noreply, Phoenix.LiveView.cancel_upload(socket, key, ref)}
  end

  def auix_handle_event(event, params, _socket) do
    raise "Event not handled. event: #{inspect(event)}. params: #{inspect(params)}"
  end

  @doc """
  Saves or updates the entity using the given params.

  Based on the action type (`:new` or `:edit`), either creates a new entity or updates an
  existing one.

  ## Parameters
  - `socket` (Socket.t()) - The current LiveView socket with action and auix assigns.
  - `entity_params` (map()) - UI entity changes to persist.

  ## Returns
  `{:ok, struct()}` - If the entity was correctly saved.
  `{:error, Ecto.Changeset.t()}` - If any error occurred with changeset details.

  """
  @spec save_entity(Socket.t(), map()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def save_entity(%{assigns: %{action: action, auix: auix}} = socket, entity_params)
      when action in [:edit, :show_edit] do
    apply_update_function(auix.update_function, socket.assigns[:auix][:entity], entity_params)
  end

  def save_entity(%{assigns: %{action: :new, auix: auix}}, entity_params) do
    apply_create_function(auix.create_function, entity_params)
  end

  @doc """
  Handles post-save navigation based on action and rendering context.

  For `:new` actions in one-to-many contexts, redirects to edit mode of the created entity.
  Otherwise, navigates back in the routing stack.

  ## Parameters
  - `socket` (Socket.t()) - Current socket with auix assigns.
  - `action` (atom()) - Form action (`:new` or `:edit`).
  - `one2many_rendered?` (boolean()) - Whether this is a one-to-many form context.

  ## Returns
  Socket.t() - Updated socket after navigation.

  """
  @spec conditional_route_back(
          Socket.t(),
          atom(),
          boolean()
        ) :: Socket.t()
  def conditional_route_back(
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

  def conditional_route_back(socket, _action, _one2many_rendered?),
    do: auix_route_back(socket)

  @doc """
  Sends a message to the parent LiveView with the operation result.

  Used to notify the parent component of successful operations.

  ## Parameters

    - `msg` - Tuple message to send (e.g., `{:saved, entity}`)

  ## Returns

    - `:ok`
  """
  @spec notify_parent(tuple()) :: :ok
  def notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @doc """
  Consumes all uploaded entries for upload fields and merges the results into entity params.

  For each upload field, reads the uploaded binaries and calls the field's `:consume` callback.
  Returns `{:ok, updated_params}` on success, or `{:error, reason}` if any callback returns
  an error (aborting further processing).

  When no file is selected for a field, the callback is not invoked and the field is left
  untouched in the params (`:no_change` short-circuit).

  ## Parameters
  - `socket` (Socket.t()) - The current LiveView socket.
  - `entity_params` (map()) - The raw entity parameters from the form submission.

  ## Returns
  `{:ok, map()}` - Updated params with consumed upload values merged in.
  `{:error, term()}` - If a `:consume` callback returns `{:error, reason}`.
  """
  @spec auix_consume_uploads(Socket.t(), map()) ::
          {:ok, map()} | {:error, term()}
  def auix_consume_uploads(%{assigns: %{auix: auix}} = socket, entity_params) do
    fields = BasicHelpers.upload_fields(auix)

    Enum.reduce_while(fields, {:ok, entity_params || %{}}, fn field, {:ok, params} ->
      binaries =
        Phoenix.LiveView.consume_uploaded_entries(socket, field.key, fn %{path: path}, _entry ->
          {:ok, File.read!(path)}
        end)

      result = if binaries == [], do: :no_change, else: field.data.upload.consume.(binaries)

      case result do
        :no_change -> {:cont, {:ok, params}}
        {:ok, value} -> {:cont, {:ok, Map.put(params, to_string(field.key), value)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  ## PRIVATE

  @spec maybe_allow_uploads(Socket.t(), map()) :: Socket.t()
  defp maybe_allow_uploads(socket, auix) do
    auix
    |> BasicHelpers.upload_fields()
    |> Enum.reduce(socket, fn field, acc ->
      if Map.has_key?(acc.assigns[:uploads] || %{}, field.key) do
        acc
      else
        Phoenix.LiveView.allow_upload(acc, field.key, field.data.upload.allow)
      end
    end)
  end

  @spec assign_layout_options(Socket.t()) :: Socket.t()
  defp assign_layout_options(socket) do
    :form
    |> LayoutOptions.available_options()
    |> Enum.reduce(socket, &BasicHelpers.assign_auix_option(&2, &1))
  end
end
