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

  import Aurora.Uix.Templates.Basic.Helpers
  import Phoenix.Component, only: [assign: 3, to_form: 1, to_form: 2]
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
  Internally handles all LiveView events for the index page.

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
  Should perform the creation or update of an entity.

  ## Parameters
  - `socket` - The current socket. The assigns.action key should contain a value of :edit for updating an entity,
    or :new for creating a new entity.
  - `entity_params` - The parameters conforming the entity to be persisted.

  ## Returns
  `{:ok, struct()}` - If the entity was correctly saved.
  `{:error, Ecto.Changeset.t()}` -  If any error ocurred. The error details are described in the changeset.
  """
  @callback save_entity(socket :: Socket.t(), entity_params :: map()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour LiveComponent
      @behaviour FormImpl

      @doc false
      @impl LiveComponent
      defdelegate update(assigns, socket), to: FormImpl

      @doc false
      @impl LiveComponent
      @spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}
      def handle_event(
            "save",
            params,
            %{assigns: %{action: action, auix: auix}} = socket
          ) do
        entity_params = FormImpl.entity_params(params, socket)

        case save_entity(socket, entity_params) do
          {:ok, entity} ->
            FormImpl.notify_parent({:saved, entity})

            new_entity =
              entity
              |> BasicHelpers.primary_key_value(auix.primary_key)
              |> auix.get_function.(preload: auix.preload)

            {:noreply,
             socket
             |> clear_flash()
             |> put_flash(:info, "#{auix.name} updated successfully")
             |> assign(:action, :edit)
             |> assign_auix(:entity, new_entity)
             |> FormImpl.conditional_route_back(action, auix.one2many_rendered?)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             socket
             |> clear_flash()
             |> put_flash(:error, format_changeset_errors(changeset))
             |> assign_auix(:form, to_form(changeset))}
        end
      end

      def handle_event(event, params, socket), do: auix_handle_event(event, params, socket)

      @doc false
      @impl FormImpl
      defdelegate auix_handle_event(event, params, socket), to: FormImpl

      @doc false
      @impl FormImpl
      defdelegate save_entity(socket, entity_params), to: FormImpl

      defoverridable LiveComponent
      defoverridable save_entity: 2
    end
  end

  @doc """
  Updates the form state and assigns for the LiveComponent.

  ## Parameters

    - `assigns` (map()) - Assigns containing at least `%{auix: %{entity: map(), routing_stack: Stack.t()}}`.
    - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns

    - `{:ok, Socket.t()}` - The updated socket with form and routing stack assigned.

  ## Examples

      iex> update(%{auix: %{entity: %User{}, routing_stack: nil}}, %{assigns: %{auix: %{modules: %{context: MyApp.Users}}})
      {:ok, %Phoenix.LiveView.Socket{...}}
  """
  @spec update(map(), Socket.t()) :: {:ok, Socket.t()}
  def update(
        %{auix: %{entity: entity, routing_stack: routing_stack}} = _assigns,
        %{assigns: %{auix: auix}} = socket
      ) do
    form =
      entity
      |> auix.change_function.(%{})
      |> to_form()

    {:ok,
     socket
     |> assign_auix_new(:form, form)
     |> assign_auix_new(:_sections, %{})
     |> assign_auix(:_myself, socket.assigns.myself)
     |> assign_auix(:routing_stack, routing_stack || Stack.new())
     |> assign_auix(:embeds_many_fields, embeds_many_fields(auix))
     |> assign_layout_options()
     |> FormActions.set_actions()
     |> render_with(&Renderer.render/1)}
  end

  @doc """
  Handles form-related events such as validation, saving, and section switching.

  ## Parameters

    - `event` (binary()) - The event name (e.g., "validate", "save", "switch_section").
    - `params` (map()) - Parameters from the event.
    - `socket` (Socket.t()) - The current LiveView socket.

  ## Returns

    - `{:noreply, Socket.t()}` - The updated socket after handling the event.

  ## Examples

      iex> handle_event("validate", %{"user" => %{"name" => "Alice"}}, %{assigns: %{auix: %{module: "user"}}})
      {:noreply, %Phoenix.LiveView.Socket{...}}
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
    entity_params = entity_params(params, socket)

    socket = Phoenix.LiveView.clear_flash(socket)

    changeset = auix.change_function.(socket.assigns[:auix][:entity], entity_params)

    {:noreply, assign_auix(socket, :form, to_form(changeset, action: :validate))}
  end

  def auix_handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
    %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

    socket = Phoenix.LiveView.clear_flash(socket)

    {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
  end

  def auix_handle_event("auix_route_back", _params, socket) do
    {:noreply, auix_route_back(socket)}
  end

  def auix_handle_event(event, params, _socket) do
    raise "Event not handled. event: #{inspect(event)}. params: #{inspect(params)}"
  end

  @doc """
  Saves or updates the entity using the given params.

  ## Parameters
  - `socket` (Socket.t()) - The current LiveView socket.
  - `entity_params` (map()) - UI entity changes.

  ## Returns
  `{:ok, struct()}` - If the entity was correctly saved.
  `{:error, Ecto.Changeset.t()}` -  If any error ocurred. The error details are described in the changeset.

  """
  @spec save_entity(Socket.t(), map()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def save_entity(%{assigns: %{action: :edit, auix: auix}} = socket, entity_params) do
    auix.update_function.(socket.assigns[:auix][:entity], entity_params)
  end

  def save_entity(%{assigns: %{action: :new, auix: auix}}, entity_params) do
    auix.create_function.(entity_params)
  end

  @doc """
  Handles post-save navigation based on action and rendering context.

  For `:new` actions in one-to-many contexts, redirects to edit mode of the created entity.
  Otherwise, navigates back in the routing stack.

  ## Parameters

    - `socket` - Current socket with auix assigns
    - `action` - Form action (`:new` or `:edit`)
    - `one2many_rendered?` - Whether this is a one-to-many form context

  ## Returns

    - `Socket.t()` - Updated socket after navigation
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
  Gets the entity params and fix empty embeds many fields.

  ## Parameters
  - `params` (`map()`) - Map of parameters changed in the UI.
  - `socket` (`Phoenix.Socket.t()`) - Phoenix socket.

  ## Returns
  `map()` - With the appropriate UI parameters

  """
  @spec entity_params(map(), Socket.t()) :: map()
  def entity_params(params, %{assigns: %{auix: auix}}) do
    params
    |> Map.get(auix.module)
    |> Map.new(&maybe_fix_embeds_many(&1, auix.embeds_many_fields))
  end

  @spec maybe_fix_embeds_many(tuple(), list()) :: tuple()
  defp maybe_fix_embeds_many({key, _value} = entry, embeds_many_fields),
    do: maybe_change_embeds_many_value(entry, key in embeds_many_fields)

  @spec maybe_change_embeds_many_value(tuple(), boolean()) :: tuple()
  defp maybe_change_embeds_many_value({key, ""}, true), do: {key, []}
  defp maybe_change_embeds_many_value(entry, _embeds_many_field?), do: entry

  ## PRIVATE ##

  @spec assign_layout_options(Socket.t()) :: Socket.t()
  defp assign_layout_options(socket) do
    :form
    |> LayoutOptions.available_options()
    |> Enum.reduce(socket, &BasicHelpers.assign_auix_option(&2, &1))
  end

  @spec embeds_many_fields(map()) :: list()
  defp embeds_many_fields(%{modules: %{module: module}}) do
    if function_exported?(module, :__schema__, 2) do
      :embeds
      |> module.__schema__()
      |> Enum.map(&module.__schema__(:embed, &1))
      |> Enum.filter(fn %{cardinality: cardinality} -> cardinality == :many end)
      |> Enum.map(&to_string(&1.field))
    else
      []
    end
  end
end
