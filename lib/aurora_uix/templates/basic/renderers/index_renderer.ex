defmodule Aurora.Uix.Templates.Basic.Renderers.IndexRenderer do
  @moduledoc """
  Renders index view pages with table-based entity listings and CRUD actions in Aurora UIX.

  ## Key Features

  - Table view whose sortable column headers re-sort the rows
  - New entity creation button
  - Show/Edit/Delete actions per row
  - Modal forms for entity operations
  - Row click navigation
  - Entity field filtering
  - Integrates with Aurora UIX context and helpers
  - Card view: the layout's `card`, else a card derived from the columns; `show_on: :all`
    renders the cards alone
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver
  use Phoenix.LiveView

  import Aurora.Uix.Templates.Basic.Components

  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Renderers
  alias Aurora.Uix.Templates.Basic.Components.FilteringComponents
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer
  alias Aurora.Uix.Templates.Basic.Renderers.OneToMany

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  @doc """
  Renders an index page with a table listing of entities.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with configurations and layout_tree info.
    * `:live_action` (atom()) - Current live action (`:new`, `:edit`, `:show`).

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered index page with table and actions.
  """

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id={"auix-table-#{@auix.uri_path_id}-index-hook"} class="auix-index-container" phx-hook="AuixThemeName">
    </div>

    <div class="auix-index-container">
      <.header>
        <div id={"auix-table-#{@auix.uri_path_id}-index-title"}>
          {dt(@auix.layout_options.page_title)}
        </div>
        <:subtitle :if={! is_nil(@auix.layout_options.page_subtitle)}>
          {dt(@auix.layout_options.page_subtitle)}
        </:subtitle>
      </.header>

      <.flash kind={:error} flash={@flash} title={dt("Error!")} />
      <.flash kind={:info} flash={@flash} title={dt("Info")} />
      <.flash kind={:success} flash={@flash} title={dt("Success")} />
      <.flash kind={:warning} flash={@flash} title={dt("Warning")} />
      
      <.index_list auix={@auix} id={"auix-table-#{@auix.uri_path_id}-index"} streams={@auix.layout_options.get_streams.(assigns)} />

      <.modal :if={@live_action in [:new, :edit, :show, :show_edit]} id={"auix-#{@auix.module}-#{@live_action}-modal"} show hide_on_cancel?={@live_action == :show} on_cancel={modal_on_cancel(@live_action, @auix)}>
        <div>
          <.live_component
            module={@auix.live_component}
            id={entity_id(@auix) || @live_action}
            action={@live_action}
            {BasicHelpers.actor_assign_prop(@auix, assigns)}
            auix={
              Map.merge(Map.get(@auix, :live_component_binding, %{}), %{entity: @auix.entity,
                routing_stack: @auix.routing_stack,
                uri_path: @auix.uri_path,
                _close_path: @auix[:_current_path],
                one_to_many_related_key: @auix[:one_to_many_related_key],
                pagination: @auix.pagination,
                item_index: @auix.item_index})
            }
          />
        </div>
      </.modal>
    </div>
    """
  end

  @doc """
  Renders the rows of a one-to-many list held by an index component.

  ## Parameters
  - `assigns` (map()) - Component assigns containing:
    * `:id` (binary()) - The component id, also the id of the rows container.
    * `:one_to_many` (map()) - The parent `auix` and the one-to-many field.
    * `:rows` (list()) - The related records to list.

  ## Returns
  Rendered.t() - The rows container.
  """
  @spec render_child(map()) :: Rendered.t()
  def render_child(assigns) do
    ~H"""
    <div id={@id} class="auix-one-to-many-container">
      <OneToMany.child_rows auix={@one_to_many.auix} field={@one_to_many.field} rows={@rows} />
    </div>
    """
  end

  @doc """
  Renders an index component: the list of a resource, without the header, the flashes and the
  modal of the LiveView.

  ## Parameters
  - `assigns` (map()) - The component assigns: `:id`, `:auix` and `:streams`.

  ## Returns
  Phoenix.LiveView.Rendered.t() - The component root, `#<id>`, holding the list.
  """
  @spec render_component(map()) :: Rendered.t()
  def render_component(assigns) do
    ~H"""
    <div id={@id} class="auix-index-container" name="auix-index-component">
      <.index_list auix={@auix} id={"auix-table-#{@id}-index"} streams={@auix.layout_options.get_streams.(assigns)} />
    </div>
    """
  end

  @doc """
  Renders the list of an index: the select and header actions, the filterable table or cards
  with the row actions, and the footer actions. Both the LiveView and the index component call
  it.

  ## Parameters
  - `assigns` (map()) - Assigns with `:auix` (the index `auix` assigns; `_myself` is the event
    target of a component instance), `:id` (the id of the table body) and `:streams`.

  ## Returns
  Phoenix.LiveView.Rendered.t() - The rendered list.
  """
  attr(:auix, :map, required: true)
  attr(:id, :string, required: true)
  attr(:streams, :any, required: true)
  @spec index_list(map()) :: Rendered.t()
  def index_list(assigns) do
    default_show_function =
      case Enum.find(assigns.auix.index_row_actions, &(&1.name == :default_row_show)) do
        nil -> nil
        default_show_action -> Map.get(default_show_action, :function_component)
      end

    assigns =
      assigns
      |> Map.put(:default_show_function, default_show_function)
      |> Map.put(:card, Map.get(assigns.auix.layout_tree, :card))
      |> then(&Map.put(&1, :auix, Map.put(&1.auix, :select_labels, select_labels(&1))))

    ~H"""
    <div class="auix-index-actions">
      <div class="auix-index-select-actions" name="auix-index-select-actions">
        <%= for %{function_component: action} <- @auix.index_selected_actions do %>
          {action.(%{auix: @auix})}
        <% end %>
      </div>
      <div class="auix-index-header-actions" name="auix-index-header-actions">
        <%= for %{function_component: action} <- @auix.index_header_actions do %>
          {action.(%{auix: @auix})}
        <% end %>
      </div>
    </div>

    <.auix_simple_form :let={index_layout_form} id={@auix.index_form_id} phx-target={@auix[:_myself]} for={@auix.index_layout_form} name="auix-index_layout_form" phx-change="index-layout-change">
      <.auix_items
        id={@id}
        auix={%{configurations: @auix.configurations,
            filters: Map.get(@auix, :filters, %{}),
            index_layout_form: index_layout_form,
            filters_enabled?: @auix.filters_enabled?,
            selection: @auix.selection,
            layout_options: @auix.layout_options,
            source_key: @auix.source_key,
            empty_list?: @auix.empty_list?,
            sort: @auix.sort,
            sort_disabled?: @auix.layout_options.sort_disabled?,
            enable_viewport?: @auix[:enable_viewport?],
            _myself: @auix[:_myself]
            }}
        streams={@streams}
        row_id={Map.get(@auix.layout_options, :row_id)}
        show_on={card_show_on(@card)}
      >
        <:filter_element :for={field <- @auix.index_fields} :let={infix}>
              <FilteringComponents.filter_field
                    field={field}
                    infix={infix}
                    filter={get_in(@auix, [:index_layout_form, field.key, Access.key!(:value)])}
                    auix={@auix}/>
        </:filter_element>

        <:col :let={{_id, entity} = row_info} :for={field <- @auix.index_fields} label={dt(field.label)} field={field}>
          <%= if field.key == :selected_check__ or !@default_show_function do %>
            <.field_value entity={entity} field={field} auix={@auix}/>
          <% else %>
            {@default_show_function.(%{auix: Map.put(@auix, :row_info, row_info),
              contents: [%{inner_block: fn _, _ -> 
                assigns = %{entity: entity, field: field, auix: @auix}
                ~H"<.field_value entity={@entity} field={@field} auix={@auix}/>" end}]}
            )}
          <% end %>
        </:col>

        <:card_title :if={@card} :let={{_id, entity} = row_info}>
          <%= if @default_show_function do %>
            {@default_show_function.(%{auix: Map.put(@auix, :row_info, row_info),
              contents: [%{inner_block: fn _, _ ->
                assigns = %{text: @card.title, entity: entity, auix: @auix}
                ~H"<.card_text text={@text} entity={@entity} auix={@auix}/>" end}]}
            )}
          <% else %>
            <.card_text text={@card.title} entity={entity} auix={@auix}/>
          <% end %>
        </:card_title>

        <:card_subtitle :if={@card && @card.subtitle} :let={{_id, entity}}>
          <.card_text text={@card.subtitle} entity={entity} auix={@auix}/>
        </:card_subtitle>

        <:card_body :if={@card} :let={{_id, entity}}>
          <Renderer.render_inner_elements auix={card_auix(@auix, @card, entity)} />
        </:card_body>

        <:action :let={row_info} :for={action <- @auix.index_row_actions} name={action.name} destructive?={action.destructive?}>
          {action.function_component.(%{auix: Map.put(@auix, :row_info, row_info)})}
        </:action>

      </.auix_items>
    </.auix_simple_form>


    <div name="auix-index-footer-actions">
      <%= for %{function_component: action} <- @auix.index_footer_actions do %>
        {action.(%{auix: @auix})}
      <% end %>
    </div>
    """
  end

  # PRIVATE

  # Resolves, once per render, the label of every related record a many-to-one column can show, so
  # the cells do not query per row. The options are the ones the form select offers, which keeps
  # `option_label` applied to the related record; they are keyed by the stored foreign key.
  @spec select_labels(map()) :: %{atom() => %{binary() => term()}}
  defp select_labels(%{auix: auix} = assigns) do
    for %{option_label: option_label, data: %{resource: resource, related_key: related_key}} =
          field <- auix.index_fields,
        option_label != nil and resource != nil and related_key != nil,
        into: %{} do
      labels =
        assigns
        |> Map.put(:field, field)
        |> BasicHelpers.get_select_options()
        |> Map.fetch!(:options)
        |> Map.new(fn {label, value} -> {to_string(value), label} end)

      {field.key, labels}
    end
  end

  @spec modal_on_cancel(atom(), map()) :: JS.t()
  defp modal_on_cancel(:show, _auix), do: JS.push("auix_route_back")

  defp modal_on_cancel(_live_action, auix),
    do: JS.push("auix_request_close", target: uix_id_selector("auix-#{auix.module}-form"))

  @spec entity_id(map()) :: term() | list() | nil
  defp entity_id(%{entity: entity, primary_key: primary_key}),
    do: BasicHelpers.primary_key_value(entity, primary_key)

  defp entity_id(_auix), do: nil

  @spec card_show_on(Node.Card.t() | nil) :: :mobile | :all
  defp card_show_on(nil), do: :mobile
  defp card_show_on(%Node.Card{show_on: show_on}), do: show_on

  # A field title renders only when the field is an index column, so its value is loaded.
  @spec card_text(map()) :: Rendered.t()
  defp card_text(%{text: %Node.Field{field: field}, auix: auix} = assigns) do
    if Enum.any?(auix.index_fields, &(&1.key == field.key)) do
      ~H"<.field_value entity={@entity} field={@text.field} auix={@auix}/>"
    else
      ~H""
    end
  end

  defp card_text(%{text: text} = assigns) when is_function(text, 1) do
    ~H"{@text.(%{auix: Map.put(@auix, :entity, @entity), entity: @entity})}"
  end

  defp card_text(%{text: text} = assigns) when is_binary(text), do: ~H"{dt(@text)}"

  defp card_text(assigns), do: ~H""

  @spec card_auix(map(), Node.Card.t(), map()) :: map()
  defp card_auix(auix, card, entity) do
    Map.merge(auix, %{
      layout_tree: card,
      layout_type: :index,
      entity: entity,
      fields_to_reject: card_dropped_keys(auix, card)
    })
  end

  @spec card_dropped_keys(map(), Node.Card.t()) :: [atom()]
  defp card_dropped_keys(auix, card),
    do: (card |> Node.fields() |> Enum.map(& &1.key)) -- Enum.map(auix.index_fields, & &1.key)

  # Resolves the field's renderer for the index layout and invokes it. `layout_type` is
  # stamped onto `auix` so renderers can pattern-match it uniformly.
  @spec field_value(map()) :: Rendered.t()
  defp field_value(%{auix: auix, field: field} = assigns) do
    assigns = %{assigns | auix: Map.put(auix, :layout_type, :index)}
    Renderers.resolve(field, :index, BasicHelpers.html_type_renderers(auix, :index)).(assigns)
  end
end
