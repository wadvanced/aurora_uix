defmodule Aurora.Uix.Templates.Basic.Renderers.OneToMany do
  @moduledoc """
  Renders one-to-many association fields in Phoenix LiveView templates for Aurora UIX.

  ## Key Features

  - Displays and manages collections of associated records
  - Provides list display with sortable columns
  - Supports actions for each record (show, edit, delete)
  - Links to create new associated records
  - Enables filtering and relationship management
  - Integrates with Aurora UIX context and helpers
  """

  use Aurora.Uix.CoreComponentsImporter
  import Aurora.Uix.Templates.Basic.Components

  alias Aurora.Uix.Templates.Basic.Actions.OneToMany, as: OneToManyActions
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers

  @doc """
  Renders a one-to-many association field.

  ## Parameters
  - assigns (map()) - The LiveView assigns including:
    - field - Field configuration map
    - auix - Configuration and options map

  ## Returns
  - Phoenix.LiveView.Rendered.t()

  ## Examples
  ```elixir
  render(%{field: field, auix: auix})
  ```
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{field: %{type: :one_to_many_association, resource: nil}} = assigns) do
    ~H"""
    """
  end

  def render(
        %{
          field: %{type: :one_to_many_association, data: data} = field,
          auix: %{layout_tree: layout_tree} = auix
        } = assigns
      ) do
    related_fields =
      field
      |> get_association_fields(auix.configurations)
      |> Enum.reject(&(&1.key == auix.resource_name))

    related_parsed_opts = get_in(auix.configurations, [data.resource, :parsed_opts])

    related_resource_config =
      get_in(auix.configurations, [data.resource, :resource_config])

    related_class =
      "w-full rounded-lg text-zinc-900 sm:text-sm sm:leading-6 border border-zinc-300 px-4"

    parsed_opts = get_in(auix.configurations, [auix.resource_name, :parsed_opts])

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
      |> put_in([:auix, :layout_tree, :opts], Map.get(layout_tree, :opts, []))
      |> OneToManyActions.set_actions()
      |> apply_options()

    ~H"""
    <div class="flex flex-col" name={"auix-one_to_many-#{@auix.association.parsed_opts.module}"}>
      <div class="flex-row gap-4">
        <.label for={"auix-one_to_many-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>{"#{@auix.association.related_parsed_opts.title} Elements"}
            <div name="auix-one_to_many-header-actions" class="inline">
              <%= for %{function_component: action} <- @auix.one_to_many_header_actions do %>
                {action.(%{auix: @auix, field: @field})}
              <% end %>
            </div>
        </.label>
      </div>
      <div id={"auix-one_to_many-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"} class={@auix.association.related_class}>
        <.auix_items
          id={"#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}
          auix={%{filters: %{}, layout_options: %{pagination_disabled?: false}}}
          rows={get_in(@auix, [:entity, Access.key!(@field.key)])}
        >
          <:col :let={entity} :for={related_field <- @auix.association.related_fields} label={"#{related_field.label}"} field={related_field}>
            {Map.get(entity, related_field.key)}
          </:col>
          <:action :let={entity} :for={%{function_component: action} <- @auix.one_to_many_row_actions}>
              {action.(%{auix: Map.put(@auix, :row_info, {BasicHelpers.primary_key_value(entity, @auix.primary_key), entity})})}
          </:action>
        </.auix_items>
      </div>
      <div class="flex-row">
        <div class="flex flex-col" name="auix-one_to_many-footer_actions">
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
    |> get_in([field.data.resource, :defaulted_paths, :index, :inner_elements])
    |> Enum.filter(&(&1.tag == :field))
    |> Enum.map(fn path_field ->
      path_field
      |> BasicHelpers.get_field(configurations, field.data.resource)
      |> then(&%{label: &1.label, key: &1.key, type: &1.type})
    end)
  end

  @spec apply_options(map()) :: map()
  defp apply_options(%{auix: %{layout_tree: %{opts: opts}}} = assigns) do
    opts
    |> Enum.reduce(assigns, &apply_option(&2, &1))
    |> maybe_apply_where()
  end

  @spec apply_option(map(), tuple()) :: map()
  defp apply_option(
         %{auix: %{association: association}} = assigns,
         {option_key, _option_value} = option
       )
       when option_key in [:order_by, :where] do
    association
    |> Map.get(:query_opts, [])
    |> then(&put_in(assigns, [:auix, :association, :query_opts], [option | &1]))
  end

  defp apply_option(assigns, _opt), do: assigns

  @spec maybe_apply_where(map()) :: map()
  defp maybe_apply_where(
         %{
           auix: %{association: %{query_opts: query_opts} = association, entity: entity} = auix,
           field: field
         } = assigns
       ) do
    owner_keys = Enum.map(auix.primary_key, &Map.get(entity, &1))

    if Enum.any?(owner_keys, &is_nil/1) do
      assigns
    else
      {custom_where, query_opts} = Keyword.pop(query_opts, :where)

      owner_keys
      |> merge_keys(association.related_key)
      |> merge_custom_where(custom_where)
      |> then(&association.related_parsed_opts.list_function.([{:where, &1} | query_opts]))
      |> then(&put_in(assigns, [:auix, :entity, Access.key!(field.key)], &1))
    end
  end

  defp maybe_apply_where(assigns), do: assigns

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
end
