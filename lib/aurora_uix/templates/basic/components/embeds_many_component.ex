defmodule Aurora.Uix.Templates.Basic.EmbedsManyComponent do
  @moduledoc """
  A LiveComponent for managing embeds_many associations in Aurora.Uix forms.

  This component provides a complete interface for displaying, adding, and
  managing embedded records within a parent form. It handles the rendering of
  existing embedded entries, modal dialogs for adding new entries, and
  integrates with Aurora.Uix's action system for custom operations.

  ## Required Assigns

  * `:auix` - Aurora.Uix context containing form state, layout configuration,
    and resource definitions
  * `:field` - Field definition map with `:data` containing `:resource` name
    for the embedded schema

  ## Layout Requirements

  The component expects `:layout_type` to be `:form` and requires layout
  configuration for the embedded resource to be available in the Aurora.Uix
  context.

  ## Example

      <.live_component
        module={Aurora.Uix.Templates.Basic.EmbedsManyComponent}
        id="user-addresses"
        auix={@auix}
        field={%{
          key: :addresses,
          html_id: "user_addresses",
          data: %{resource: :address}
        }}
      />
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext
  use Phoenix.LiveComponent

  import Aurora.Uix.Templates.Basic.Helpers,
    only: [assign_auix: 3, assign_auix_new: 3, get_layout: 3, get_resource: 3]

  alias Aurora.Uix.Templates.Basic.Actions.EmbedsMany, as: EmbedsManyActions
  alias Aurora.Uix.Templates.Basic.Renderer

  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  @spec update(map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:auix, assigns.auix)
     |> assign(:field, assigns.field)
     |> assign_new_embeds_many_form()
     |> assign_auix_new(:enable_add_embeds, false)}
  end

  @doc """
  Renders the embeds_many component interface.

  Displays existing embedded entries with their configured actions, and
  provides either a modal for adding new entries (when enabled) or footer
  actions. The layout is determined by the embedded resource's form
  configuration.

  ## Parameters

  * `assigns` (map()) - Component assigns containing:
    * `:auix` (map()) - Aurora.Uix context with `:layout_type` set to `:form`,
      `:form` for the parent form, and action configurations
    * `:field` (map()) - Field definition with `:data` map containing
      `:resource` atom identifying the embedded schema

  ## Returns

  A rendered `Phoenix.LiveView.Rendered` struct with the complete embeds_many
  interface.
  """
  @impl Phoenix.LiveComponent
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{
          field: %{data: %{resource: embed_resource_name}} = field,
          auix: %{layout_type: :form}
        } = assigns
      ) do
    layout_tree = get_layout(assigns, embed_resource_name, :form)

    fields_to_reject = get_resource(assigns, embed_resource_name, [:parsed_opts, :primary_key])

    assigns =
      assigns
      |> assign_auix(:layout_tree, layout_tree)
      |> assign_auix(:resource_name, embed_resource_name)
      |> assign_auix(:fields_to_reject, fields_to_reject)
      |> assign(:field, field)
      |> EmbedsManyActions.set_actions()

    ~H"""
      <div class="auix-embeds-many-container">
        <.header>
          {@field.label}
        </.header>

        <.inputs_for :let={embed_form} field={@auix.form[@field.key]}>
          <div class="auix-embeds-many-entry-contents">
            <Renderer.render_inner_elements auix={Map.put(@auix, :form, embed_form)} />
            <div class="auix-embeds-many-existing-container">
              <div class="auix-embeds-many-existing-actions" name="auix-embeds_many-existing_actions">
                <%= for %{function_component: action} <- @auix.embeds_many_existing_actions do %>
                  {action.(%{auix: @auix, field: @field, entry_id: embed_form[:id].value, target: @myself})}
                <% end %>
              </div>
            </div>
          </div>
        </.inputs_for>
        <div :if={@auix.enable_add_embeds} >
          <.portal id={"auix-embeds-many-add-#{@field.html_id}-wrapper"} target="#portal-target">
            <.modal id={"auix-embeds-many-add-#{@field.html_id}"} 
                      show={@auix.enable_add_embeds}
                      on_cancel={JS.push("toggle-add-embeds", target: @myself)}>
              <.header>
                {gettext("Add new entry")}
              </.header>
              <.simple_form
                for={@auix.new_entry_form}
                id={"auix-#{@field.html_id}-add-form"}
                phx-target={@myself}
                phx-change={JS.push("validate", target: @myself)}
                phx-submit="add-embeds-many"
                phx-click={JS.exec("phx-remove-class", to: "#modal")}
              >
                <Renderer.render_inner_elements auix={Map.merge(@auix, %{form: @auix.new_entry_form, fields_to_reject: @auix.fields_to_reject})} />
                
                <div class="auix-embeds-many-new-entry-container">
                  <div class="auix-embeds-many-new-entry-actions" name="auix-embeds_many-new_entry_actions">
                    <%= for %{function_component: action} <- @auix.embeds_many_new_entry_actions do %>
                      {action.(%{auix: @auix, field: @field, target: @myself, form_id: "auix-#{@field.html_id}-add-form"})}
                    <% end %>
                  </div>
                </div>
              </.simple_form>
            </.modal>
          </.portal>      
        </div>        
        <div :if={!@auix.enable_add_embeds} class="auix-embeds-many-footer-container">
          <div class="auix-embeds-many-footer-actions" name="auix-embeds_many-footer_actions">
            <%= for %{function_component: action} <- @auix.embeds_many_footer_actions do %>
              {action.(%{auix: @auix, field: @field, target: @myself})}
            <% end %>
          </div>
        </div>
      </div>
    """
  end

  @doc """
  Validates the form for adding a new embedded entry.

  This handler is triggered on form change events within the add entry modal.
  Currently performs no validation logic but is required for the form's
  `phx-change` binding.

  ## Parameters

  * `event` (String.t()) - The event name (always `"validate"`)
  * `params` (map()) - Form parameters (unused)
  * `socket` (Phoenix.LiveView.Socket.t()) - The current socket

  ## Returns

  `{:noreply, Phoenix.LiveView.Socket.t()}` with unchanged socket state.
  """
  @impl Phoenix.LiveComponent
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("validate", params, %{assigns: %{auix: auix, field: field}} = socket) do
    params = cast_params(params)

    errors =
      auix.entity
      |> auix.change_function.(%{field.key => [params]})
      |> get_in([Access.key(:changes), field.key])
      |> Enum.filter(&(&1.action == :insert))
      |> List.first(%{})
      |> Map.get(:errors, [])

    new_entry_form =
      params
      |> to_form()
      |> struct(%{errors: errors, action: :validate})

    {:noreply, assign_auix(socket, :new_entry_form, new_entry_form)}
  end

  def handle_event(
        "add-embeds-many",
        _params,
        %{assigns: %{auix: %{new_entry_form: %{action: action}}}} = socket
      )
      when is_nil(action) do
    {:no_reply, socket}
  end

  def handle_event(
        "add-embeds-many",
        params,
        %{assigns: %{auix: %{new_entry_form: %{errors: []}} = auix, field: field}} =
          socket
      ) do
    changes = add_embed_entry_changes(auix.entity, field.key, params)

    form =
      auix.entity
      |> auix.change_function.(%{field.key => changes})
      |> to_form()

    {:noreply,
     socket
     |> assign_auix(:form, form)
     |> assign_auix(:enable_add_embeds, false)}
  end

  def handle_event("add-embeds-many", _params, socket) do
    {:noreply, put_flash(socket, :error, gettext("Entry contains errors"))}
  end

  def handle_event(
        "toggle-add-embeds",
        _params,
        %{assigns: %{auix: %{enable_add_embeds: enable_add_embeds}}} = socket
      ) do
    {:noreply, assign_auix(socket, :enable_add_embeds, not enable_add_embeds)}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  ## PRIVATE

  # Initializes the form for adding new embedded entries.
  #
  # Creates a Phoenix.HTML.Form struct with default values for all fields
  # defined in the embedded resource configuration. Default values are
  # determined by field type.
  @spec assign_new_embeds_many_form(Phoenix.LiveView.Socket.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_new_embeds_many_form(
         %{assigns: %{field: %{data: %{resource: embed_resource_name}}} = assigns} = socket
       ) do
    assigns
    |> get_resource(embed_resource_name, [:resource_config, :fields])
    |> Map.new(&map_embed_field/1)
    |> to_form()
    |> then(&assign_auix(socket, :new_entry_form, &1))
  end

  @spec add_embed_entry_changes(map(), atom(), map()) :: list()
  defp add_embed_entry_changes(entity, field_key, params) do
    params = cast_params(params)

    entity
    |> Map.get(field_key, [])
    |> Enum.map(&Map.from_struct/1)
    |> Enum.reverse()
    |> then(&[params | &1])
    |> Enum.reverse()
  end

  @spec cast_params(map()) :: map()
  defp cast_params(params) do
    params
    |> Enum.reject(fn {key, _value} -> String.starts_with?(key, "_") end)
    |> Map.new()
  end

  # Maps a field definition to a tuple of field name and default value.
  @spec map_embed_field({atom(), map()}) :: {atom(), term()}
  defp map_embed_field({_id, %{name: name, type: type}}) do
    type
    |> default_value()
    |> then(&{name, &1})
  end

  # Returns the default value for a field based on its type.
  #
  # String and binary_id fields default to empty string, all other types
  # default to nil.
  @spec default_value(atom()) :: term()
  defp default_value(type) when type in [:binary_id, :string], do: ""
  defp default_value(_type), do: nil
end
