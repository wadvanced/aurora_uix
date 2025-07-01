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

  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS

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

  def render(%{field: %{type: :one_to_many_association} = field, auix: auix} = assigns) do
    related_fields =
      field
      |> get_association_fields(auix.configurations)
      |> Enum.reject(&(&1.key == auix._resource_name))

    related_parsed_opts = get_in(auix.configurations, [field.data.resource, :parsed_opts])

    related_resource_config =
      get_in(auix.configurations, [field.data.resource, :resource_config])

    related_path = build_related_path(auix.source, field.data)

    related_class =
      "w-full rounded-lg text-zinc-900 sm:text-sm sm:leading-6 border border-zinc-300 px-4"

    parsed_opts = get_in(auix.configurations, [auix._resource_name, :parsed_opts])

    assigns =
      assigns
      |> Map.put(:related_parsed_opts, related_parsed_opts)
      |> Map.put(:related_resource_config, related_resource_config)
      |> Map.put(:related_path, related_path)
      |> Map.put(:related_class, related_class)
      |> Map.put(:related_fields, related_fields)
      |> Map.put(:related_key, field.data.related_key)
      |> Map.put(:owner_key, field.data.owner_key)
      |> Map.put(:parsed_opts, parsed_opts)

    ~H"""
    <div class="flex flex-col">
      <div class="flex-row gap-4">
        <.label for={"auix-one_to_many-#{@parsed_opts.module}__#{@field.key}-#{@auix._mode}"}>{"#{@related_parsed_opts.title} Elements"}
            <.auix_link :if={!@related_parsed_opts.disable_index_new_link && @auix[:_mode] == :form && @auix_entity.id != nil}
                navigate={"#{@related_parsed_opts.index_new_link}?related_key=#{@related_key}&parent_id=#{Map.get(@auix_entity, @owner_key)}"}
                id={"auix-new-#{@parsed_opts.module}__#{@field.key}-#{@auix._mode}"}>
              <.icon name="hero-plus" />
            </.auix_link>
        </.label>
      </div>
      <div id={"auix-one_to_many-#{@parsed_opts.module}__#{@field.key}-#{@auix._mode}"} class={@related_class}>
        <.table
          id={"#{@parsed_opts.module}__#{@field.key}-#{@auix._mode}"}
          auix_css_classes={@auix._css_classes}
          rows={Map.get(@auix_entity, @field.key)}
          row_click_navigate={if @related_parsed_opts.disable_index_row_click, do: nil, else: build_row_click(@related_parsed_opts, @related_path)}
        >
          <:col :let={entity} :for={related_field <- @related_fields} label={"#{related_field.label}"}><.auix_link navigate={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}"}>{Map.get(entity, related_field.key)}</.auix_link></:col>
          <:action :let={entity}>
            <div class="sr-only">
              <.auix_link navigate={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}"} name={"auix-show-#{@parsed_opts.module}__#{@related_parsed_opts.module}"} id={"auix-show-#{entity.id}-#{@auix._mode}"}>Show</.auix_link>
            </div>
            <.auix_link navigate={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}/edit"} name={"auix-edit-#{@parsed_opts.module}__#{@related_parsed_opts.module}"} id={"auix-edit-#{entity.id}-#{@auix._mode}"}><.icon name="hero-pencil" /></.auix_link>
          </:action>

          <:action :let={entity}>
            <.link
              phx-click={JS.push("delete",
                  value: %{id: entity.id,
                    context: @related_resource_config.context,
                    get_function: @related_parsed_opts.get_function,
                    delete_function: @related_parsed_opts.delete_function}
                )
                |> hide("##{entity.id}")}
              name={"auix-delete-#{@parsed_opts.module}__#{@related_parsed_opts.module}"}
              data-confirm="Are you sure?"
            >
              <.icon name="hero-trash" />
            </.link>
          </:action>
        </.table>
      </div>
    </div>
    """
  end

  # Creates a click handler function for row interactions in tables
  # Returns function that generates path with entity ID
  @spec build_row_click(map(), binary()) :: (map() -> binary())
  defp build_row_click(opts, path) do
    fn row ->
      row
      |> Map.get(:id)
      |> to_string()
      |> then(&String.replace("#{opts.index_row_click}?#{path}", "[[entity]]", &1))
    end
  end

  # Builds the URL path template for related entity operations
  # Returns path template with placeholders for dynamic values
  @spec build_related_path(binary(), map()) :: binary()
  defp build_related_path(source, data) do
    "source=#{source}/\#{@auix_entity.id}&related_key=#{data.related_key}&parent_id=\#{@auix_entity.#{data.owner_key}}"
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
