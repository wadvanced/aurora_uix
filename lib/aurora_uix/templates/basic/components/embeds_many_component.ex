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

  import Aurora.Uix.Integration.Crud

  import Aurora.Uix.Templates.Basic.Helpers,
    only: [
      assign_auix: 3,
      assign_auix_new: 3,
      get_layout: 3,
      get_resource: 3
    ]

  alias Aurora.Uix.Templates.Basic.Actions.EmbedsMany, as: EmbedsManyActions
  alias Aurora.Uix.Templates.Basic.Renderer

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :details_opened, false)}
  end

  @impl Phoenix.LiveComponent
  @spec update(map(), Socket.t()) :: {:ok, Socket.t()}
  def update(
        %{
          field: %{data: %{resource: embed_resource_name}, key: key},
          auix: %{layout_type: layout_type}
        } = assigns,
        socket
      )
      when layout_type in [:form, :show] do
    layout_tree = get_layout(assigns, embed_resource_name, layout_type)

    field_key = to_string(key)

    primary_key = get_resource(assigns, embed_resource_name, [:parsed_opts, :primary_key])

    primary_key_field = List.first(primary_key)

    primary_key_type =
      get_resource(assigns, embed_resource_name, [
        :resource_config,
        :fields,
        primary_key_field,
        :type
      ])

    {:ok,
     socket
     |> assign(:auix, assigns.auix)
     |> assign(:field, assigns.field)
     |> assign_new_embeds_many_form()
     |> assign_auix_new(:enable_add_embeds, false)
     |> assign_auix(:layout_tree, layout_tree)
     |> assign_auix(:resource_name, embed_resource_name)
     |> assign_auix(:primary_key, primary_key)
     |> assign_auix(:primary_key_type, primary_key_type)
     |> assign_auix(:field_key, field_key)
     |> EmbedsManyActions.set_actions()}
  end

  @doc """
  Renders the embeds_many component interface.

  Displays existing embedded entries with their configured actions, and
  provides either a modal for adding new entries (when enabled) or footer
  actions. The layout is determined by the embedded resource's form
  configuration.

  ## Parameters

  * `assigns` (map()) - Component assigns containing:
    * `:auix` (map()) - Aurora.Uix context with `:layout_type` set to `:form` or `:show`.
    * `:field` (map()) - Field definition with `:data` map containing
      `:resource` atom identifying the embedded schema

  ## Returns

  A rendered `Phoenix.LiveView.Rendered` struct with the complete embeds_many
  interface.
  """
  @impl Phoenix.LiveComponent
  @spec render(map()) :: Rendered.t()
  def render(assigns) do
    ~H"""
      <div class="auix-embeds-many-container">
        <details name={"auix-details-#{@field.html_id}"} class="auix-embeds-many-details" open={@details_opened}>
          <summary class="auix-embeds-many-summary" phx-click="toggle-details-state" phx-target={@myself}>
              <div class="auix-embeds-many-summary-content">
                <span>{@field.label}</span>
                <span :if={!@details_opened} class="auix-button-badge">
                  <.embedded_entries_count auix={@auix} field={@field} />
                </span>
              </div>
          </summary>
          <div class="auix-embeds-many-content">
            <.header>
              <div :if={!@auix.enable_add_embeds} class="auix-embeds-many-header-container">
                <div class="auix-embeds-many-header-actions" name="auix-embeds_many-header_actions">
                  <%= for %{function_component: action} <- @auix.embeds_many_header_actions do %>
                    {action.(%{auix: @auix, field: @field, target: @myself})}
                  <% end %>
                </div>
              </div>
            </.header>
            <.embedded_entries auix={@auix} field={@field} target={@myself}/>
            <div :if={@auix.enable_add_embeds} >
              <.portal id={"auix-embeds-many-add-#{@field.html_id}-#{@auix.layout_type}-wrapper"} target="#portal-target">
                <.modal id={"auix-embeds-many-add-#{@field.html_id}-#{@auix.layout_type}-modal"} 
                          show={@auix.enable_add_embeds}
                          on_cancel={JS.push("toggle-add-embeds", target: @myself)}>
                  <.header>
                    <span>{gettext("Add new entry")}</span>
                  </.header>
                  <.simple_form
                    for={@auix.new_entry_form}
                    id={"auix-embeds-many-#{@field.html_id}-#{@auix.layout_type}-add-form"}
                    phx-target={@myself}
                    phx-change={JS.push("validate", target: @myself)}
                    phx-submit="add-embeds-many"
                    phx-click={JS.exec("phx-remove-class", to: "#modal")}
                  >
                    <Renderer.render_inner_elements auix={Map.merge(@auix, %{form: @auix.new_entry_form, fields_to_reject: @auix.primary_key})} />
                    <.flash flash={@flash} kind={:error}/>
                    <.flash flash={@flash} kind={:info}/>
                    <div class="auix-embeds-many-new-entry-container">
                      <div class="auix-embeds-many-new-entry-actions" name="auix-embeds_many-new_entry_actions">
                        <%= for %{function_component: action} <- @auix.embeds_many_new_entry_actions do %>
                          {action.(%{auix: @auix, field: @field, target: @myself, form_id: "auix-embeds-many-#{@field.html_id}-#{@auix.layout_type}-add-form"})}
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
        </details>
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

  def handle_event(
        "toggle-add-embeds",
        _params,
        %{assigns: %{auix: %{enable_add_embeds: enable_add_embeds}}} = socket
      ) do
    {:noreply,
     socket
     |> assign_auix(:enable_add_embeds, not enable_add_embeds)
     |> assign_new_embeds_many_form()}
  end

  def handle_event(
        "toggle-details-state",
        _params,
        %{assigns: %{details_opened: details_opened}} = socket
      ) do
    {:noreply, assign(socket, :details_opened, not details_opened)}
  end

  def handle_event("validate", params, %{assigns: %{auix: auix, field: field}} = socket) do
    params = cast_params(params)

    errors =
      auix.entity
      |> apply_change_function(auix.change_function, %{field.key => [params]})
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
    changes =
      add_embed_entry_changes(auix, field.key, params)

    form =
      auix.entity
      |> apply_change_function(auix.change_function, %{field.key => changes})
      |> to_form()

    {:noreply,
     socket
     |> assign_auix(:form, form)
     |> assign_new_embeds_many_form()
     |> put_flash(:info, gettext("Entry added successfully"))}
  end

  def handle_event("add-embeds-many", _params, socket) do
    {:noreply, put_flash(socket, :error, gettext("Entry contains errors"))}
  end

  def handle_event(
        "remove-entry",
        %{"entry_index" => entry_index},
        %{assigns: %{auix: auix, field: field}} = socket
      ) do
    changes =
      auix.form
      |> get_entries(field.key)
      |> List.delete_at(entry_index)

    form =
      auix.entity
      |> apply_change_function(auix.change_function, %{field.key => changes})
      |> to_form()

    {:noreply,
     socket
     |> assign_auix(:form, form)
     |> assign_new_embeds_many_form()
     |> put_flash(:info, gettext("Entry removed successfully"))}
  end

  ## PRIVATE

  attr(:auix, :map)
  attr(:field, :map)
  attr(:target, :string)
  @spec embedded_entries(map()) :: Rendered.t()
  defp embedded_entries(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
    <%= if Map.get(@auix.form.params, @auix.field_key) == [] do %>
        <input type="hidden" id={"#{@field.html_id}-#{@auix.layout_type}"} name={@auix.form[@field.key].name} value={[]} />
    <% else %>
      <.inputs_for :let={embed_form} field={@auix.form[@field.key]}>
        <div class="auix-embeds-many-entry-contents">
          <div class="auix-embeds-many-entry--badge">
            <span class="auix-embeds-many-entry--badge-text">{embed_form.index + 1}</span>
          </div>
          <Renderer.render_inner_elements auix={Map.put(@auix, :form, embed_form)} />
          <div class="auix-embeds-many-existing-container">
            <div class="auix-embeds-many-existing-actions" name="auix-embeds_many-existing_actions">
              <%= for %{function_component: action} <- @auix.embeds_many_existing_actions do %>
                {action.(%{auix: @auix, field: @field, entry_index: embed_form.index, target: @target})}
              <% end %>
            </div>
          </div>
        </div>
      </.inputs_for>
    <% end %>    
    """
  end

  defp embedded_entries(%{auix: %{entity: entity, layout_type: :show}, field: field} = assigns) do
    assigns =
      entity
      |> Map.get(field.key, [])
      |> then(&assign_auix(assigns, :embedded_entries, &1))

    ~H"""
    <%= for {embed_entry, entry_index} <- Enum.with_index(@auix.embedded_entries) do %>
        <div class="auix-embeds-many-entry-contents">
          <div class="auix-embeds-many-entry--badge">
            <span class="auix-embeds-many-entry--badge-text">{entry_index + 1}</span>
          </div>
          <Renderer.render_inner_elements auix={Map.put(@auix, :entity, embed_entry)} />
          <div class="auix-embeds-many-existing-container">
            <div class="auix-embeds-many-existing-actions" name="auix-embeds_many-existing_actions">
              <%= for %{function_component: action} <- @auix.embeds_many_existing_actions do %>
                {action.(%{auix: @auix, field: @field, entry_index: entry_index, target: @target})}
              <% end %>
            </div>
          </div>
        </div>
    <% end %>
    """
  end

  @spec embedded_entries_count(map) :: Rendered.t()
  defp embedded_entries_count(%{auix: %{layout_type: :form, form: %{params: []}}} = _assigns),
    do: ""

  defp embedded_entries_count(%{auix: %{layout_type: :form, form: form}, field: field} = assigns) do
    assigns =
      form[field.key]
      |> Map.get(:value, [])
      |> Enum.count()
      |> then(&Map.put(assigns, :embedded_entries_count, &1))

    ~H"""
    <%= if @embedded_entries_count > 0 do%>
      {@embedded_entries_count}
    <% end %>
    """
  end

  defp embedded_entries_count(
         %{auix: %{entity: entity, layout_type: :show}, field: field} = assigns
       ) do
    assigns =
      entity
      |> Map.get(field.key, [])
      |> Enum.count()
      |> then(&Map.put(assigns, :embedded_entries_count, &1))

    ~H"""
    <%= if @embedded_entries_count > 0 do%>
      {@embedded_entries_count}
    <% end %>
    """
  end

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

  @spec get_entries(map(), atom()) :: list()
  defp get_entries(form, field_key) do
    form[field_key]
    |> Map.get(:value, [])
    |> get_entries_changes()
    |> Enum.map(&(&1 |> extract_changes() |> convert_to_map()))
    |> Enum.reject(&is_nil/1)
  end

  @spec get_entries_changes(map() | list()) :: list()
  defp get_entries_changes(entries) when is_map(entries), do: Map.values(entries)

  defp get_entries_changes(entries), do: entries

  @spec extract_changes(map()) :: map() | nil
  defp extract_changes(%{params: params}), do: params
  defp extract_changes(entry), do: entry

  @spec convert_to_map(map() | nil) :: map() | nil
  defp convert_to_map(entry) when is_non_struct_map(entry), do: entry
  defp convert_to_map(entry) when is_struct(entry), do: Map.from_struct(entry)
  defp convert_to_map(nil), do: nil

  @spec add_embed_entry_changes(map(), atom(), map()) :: list()
  defp add_embed_entry_changes(%{form: form}, field_key, params) do
    params = cast_params(params)

    form
    |> get_entries(field_key)
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
