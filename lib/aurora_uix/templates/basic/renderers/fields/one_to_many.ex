defmodule Aurora.Uix.Web.Templates.Basic.Renderers.OneToMany do
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

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Actions.OneToMany, as: OneToManyActions
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers

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
        <.table
          id={"#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}
          auix={%{css_classes: @auix.css_classes}}
          rows={get_in(@auix, [:entity, Access.key!(@field.key)])}
        >
          <:col :let={entity} :for={related_field <- @auix.association.related_fields} label={"#{related_field.label}"}>
            {Map.get(entity, related_field.key)}
          </:col>
          <:action :let={entity} :for={%{function_component: action} <- @auix.one_to_many_row_actions}>
              {action.(%{auix: Map.put(@auix, :row_info, {BasicHelpers.primary_key_value(entity, @auix.primary_key), entity})})}
          </:action>
        </.table>
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
end
