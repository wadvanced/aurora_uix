defmodule Aurora.Uix.Templates.Basic.Renderers.OneToMany do
  @moduledoc """
  Renders one-to-many association fields in Phoenix LiveView templates for Aurora UIX.

  ## Key Features

  - Displays and manages collections of associated records
  - Lists the related records in a table, honouring the field's `order_by` and `where` options
  - Supports actions for each record (show, edit, delete)
  - Links to create new associated records
  - Enables filtering and relationship management
  - Integrates with Aurora UIX context and helpers
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver
  import Aurora.Uix.Templates.Basic.Components
  import Aurora.Uix.Integration.Crud

  alias Aurora.Uix.Templates.Basic.Actions.OneToMany, as: OneToManyActions
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.HTML.Safe

  @doc """
  Renders a one-to-many association field.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:field` (map()) - Field configuration with association details.
    * `:auix` (map()) - Aurora UIX context and configuration.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered one-to-many association component.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{field: %{type: :one_to_many_association, data: %{resource: nil}}} = assigns) do
    ~H"""
    """
  end

  def render(
        %{
          field: %{type: :one_to_many_association, data: data} = field,
          auix: auix
        } = assigns
      ) do
    component = get_in(auix.configurations, [data.resource, :artifacts, :index_component])

    if is_nil(component),
      do:
        raise(
          ArgumentError,
          "the one-to-many field #{inspect(field.key)} needs an index component for #{inspect(data.resource)}; add :index_component to generate:, or name one with use: on its index_columns"
        )

    uri_path = Map.get(auix, :uri_path)
    parsed_opts = get_in(auix.configurations, [auix.resource_name, :parsed_opts])

    related_fields =
      field
      |> get_association_fields(auix.configurations)
      |> Enum.reject(&(&1.key == auix.resource_name))

    related_parsed_opts =
      auix.configurations
      |> get_in([data.resource, :parsed_opts])
      |> set_related_uri_path(parsed_opts, uri_path)
      |> set_related_new_link()

    related_resource_config =
      get_in(auix.configurations, [data.resource, :resource_config])

    related_class =
      "auix-one-to-many-container"

    assigns =
      assigns
      |> put_in([:auix, :association], %{})
      |> put_in([:auix, :association, :related_parsed_opts], related_parsed_opts)
      |> put_in([:auix, :association, :related_resource_config], related_resource_config)
      |> put_in([:auix, :association, :related_class], related_class)
      |> put_in([:auix, :association, :related_fields], related_fields)
      |> put_in([:auix, :association, :related_key], field.data.related_key)
      |> put_in([:auix, :association, :owner_key], field.data.owner_key)
      |> put_in([:auix, :association, :parsed_opts], parsed_opts)
      |> OneToManyActions.set_actions()
      |> Map.put(:component, component)
      |> Map.put(
        :socket_opts,
        BasicHelpers.backend_socket_opts(assigns, related_parsed_opts.list_function)
      )

    ~H"""
    <div class="auix-one-to-many-field" name={"auix-one_to_many-#{@auix.association.parsed_opts.module}"}>
      <div class="auix-one-to-many-header">
        <.label for={"auix-one_to_many-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>{"#{@auix.association.related_parsed_opts.title} Items"}
            <div name="auix-one_to_many-header-actions" class="auix-one-to-many-header-actions">
              <%= for %{function_component: action} <- @auix.one_to_many_header_actions do %>
                {action.(%{auix: @auix, field: @field})}
              <% end %>
            </div>
        </.label>
      </div>
      <.live_component
        module={@component}
        id={"auix-one_to_many-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}
        one_to_many={%{auix: @auix, field: @field, socket_opts: @socket_opts}}
      />
      <div class="auix-one-to-many-footer">
        <div class="auix-one-to-many-footer-actions" name="auix-one_to_many-footer_actions">
          <%= for %{function_component: action} <- @auix.one_to_many_footer_actions do %>
            {action.(%{auix: @auix, field: @field})}
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Gets field configurations for associations from the resource configurations
  # Maps field paths to their display configurations
  @spec get_association_fields(map(), map()) :: list(map())
  defp get_association_fields(field, configurations) do
    configurations
    |> BasicHelpers.layout_children(field.data.resource, :index)
    |> Enum.map(&%{label: &1.field.label, key: &1.field.key, type: &1.field.type})
  end

  @doc """
  Renders the rows of a one-to-many list: the table of the related records with their row
  actions.

  ## Parameters
  - `assigns` (map()) - Assigns containing:
    * `:auix` (map()) - The parent `auix`, with `association` and the one-to-many actions.
    * `:field` (map()) - The one-to-many field.
    * `:rows` (list()) - The related records to list.

  ## Returns
  Phoenix.LiveView.Rendered.t() - The rendered rows.
  """
  @spec child_rows(map()) :: Phoenix.LiveView.Rendered.t()
  def child_rows(assigns) do
    ~H"""
    <.auix_items
      id={"#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}
      first_column_not_checkbox?={true}    
      auix={%{filters: %{}, source_key: @auix.source_key,
        layout_options: %{pagination_disabled?: false, infinite_scroll_items_load: nil}}}
      streams={@rows}
    >
      <:col :let={entity} :for={related_field <- @auix.association.related_fields} label={dt(related_field.label)} field={related_field}>
        {display_value(entity, related_field.key)}
      </:col>
      <:action :let={entity} :for={action <- @auix.one_to_many_row_actions} name={action.name} destructive?={action.destructive?}>
          {action.function_component.(%{auix: Map.put(@auix, :row_info, {BasicHelpers.primary_key_value(entity, @auix.primary_key), entity})})}
      </:action>
    </.auix_items>
    """
  end

  @doc """
  Loads the rows of a one-to-many list.

  The `where` and `order_by` of the layout field take precedence over the ones in the field's
  `query_opts`, declared in the resource metadata. Without either, or for a parent whose owner key
  is not set yet, the rows are the preloaded value of the field. Otherwise the related list
  function is queried with the owner keys, the `where` and the `order_by`.

  ## Parameters
  - `one_to_many` (map()) - Map containing:
    * `:auix` (map()) - The parent `auix`, with `entity`, `layout_tree`, `primary_key` and
      `association`.
    * `:field` (map()) - The one-to-many field.
    * `:socket_opts` (keyword()) - Backend options for the list function.

  ## Returns
  list() - The related records.
  """
  @spec load_rows(map()) :: list()
  def load_rows(%{auix: auix, field: field} = one_to_many) do
    query_opts = Map.get(field, :query_opts) || []
    order_by = Map.get(auix.layout_tree, :order_by) || query_opts[:order_by]
    custom_where = Map.get(auix.layout_tree, :where) || query_opts[:where]

    if is_nil(order_by) and is_nil(custom_where) do
      preloaded_rows(auix.entity, field.key)
    else
      query_rows(one_to_many, order_by, custom_where)
    end
  end

  @spec query_rows(map(), term() | nil, term() | nil) :: list()
  defp query_rows(%{auix: auix, field: field} = one_to_many, order_by, custom_where) do
    owner_keys = Enum.map(auix.primary_key, &Map.get(auix.entity, &1))

    if Enum.any?(owner_keys, &is_nil/1) do
      preloaded_rows(auix.entity, field.key)
    else
      query_opts = if is_nil(order_by), do: [], else: [order_by: order_by]
      list_function = auix.association.related_parsed_opts.list_function

      owner_keys
      |> merge_keys(auix.association.related_key)
      |> merge_custom_where(custom_where)
      |> then(
        &apply_list_function(
          list_function,
          [{:where, &1} | query_opts] ++ one_to_many.socket_opts
        )
      )
      |> BasicHelpers.list_entries()
    end
  end

  @spec preloaded_rows(map() | nil, atom()) :: list()
  defp preloaded_rows(entity, key) do
    case Map.get(entity || %{}, key) do
      rows when is_list(rows) -> rows
      _not_loaded -> []
    end
  end

  @spec merge_custom_where(list(), term() | nil) :: list()
  defp merge_custom_where(related_where, nil), do: related_where
  defp merge_custom_where(related_where, []), do: related_where

  defp merge_custom_where(related_where, custom_where) when is_list(custom_where) do
    custom_where
    |> Enum.reduce(related_where, &[&1 | &2])
    |> Enum.reverse()
  end

  defp merge_custom_where(related_where, custom_where) do
    Enum.reverse([custom_where | related_where])
  end

  @spec merge_keys(list(), list() | atom(), list()) :: list()
  defp merge_keys(owner_keys, related_keys, result \\ [])
  defp merge_keys([], _, result), do: result
  defp merge_keys(_, [], result), do: result

  defp merge_keys([owner_key | _owner_keys], related_key, _result) when is_atom(related_key),
    do: [{related_key, owner_key}]

  defp merge_keys([owner_key | owner_keys], [related_key | related_keys], result) do
    merge_keys(owner_keys, related_keys, [{related_key, owner_key} | result])
  end

  @spec set_related_uri_path(map(), map(), binary() | nil) :: map()
  defp set_related_uri_path(related_parsed_opts, _parsed_opts, nil), do: related_parsed_opts

  defp set_related_uri_path(
         %{source: related_source} = related_parsed_opts,
         %{source: source} = _parsed_optsi,
         uri_path
       ) do
    uri_path
    |> String.replace(source, related_source)
    |> then(&Map.put(related_parsed_opts, :uri_path, &1))
  end

  @spec set_related_new_link(map()) :: map()
  defp set_related_new_link(%{uri_path: uri_path} = related_parsed_opts) do
    Map.put(related_parsed_opts, :index_new_link, "/#{uri_path}/new")
  end

  defp set_related_new_link(related_parsed_opts), do: related_parsed_opts

  @spec display_value(term() | nil, binary() | nil) :: String.t()
  defp display_value(nil, _key), do: ""
  defp display_value(_entity, nil), do: ""

  defp display_value(entity, key) do
    value = Map.get(entity, key)

    case Safe.impl_for(value) do
      nil -> inspect(value)
      _ -> value
    end
  end
end
