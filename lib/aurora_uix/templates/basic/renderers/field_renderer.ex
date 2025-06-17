defmodule Aurora.Uix.Web.Templates.Basic.Renderers.FieldRenderer do
  @moduledoc """
  Field renderer module for Aurora UIX forms.

  Provides specialized rendering for different field types:
  - Standard form inputs with validation
  - One-to-many associations with embedded tables
  - Many-to-one associations
  - Hidden fields
  - Custom field renderers
  """

  use Aurora.Uix.Web.CoreComponentsImporter
  import Aurora.Uix.Layout.Helper, only: [next_count: 1]
  import Aurora.Uix.Web.Templates.Basic.Helpers, only: [get_field: 3]
  import Aurora.Uix.Web.Templates.Basic.RoutingComponents

  alias Aurora.Uix.Web.Templates.Basic.Renderer
  alias Phoenix.LiveView.JS

  @doc """
  Renders a form field based on its type and configuration.

  ## Parameters
  - assigns (map()) - LiveView assigns containing:
    - _auix: Aurora UIX context with configurations
    - auix_entity: Entity being rendered
    - field: Field configuration and metadata

  ## Returns
  - Phoenix.LiveView.Rendered.t() - The rendered field component
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{_auix: auix} = assigns) do
    field = get_field_info(auix)

    assigns = assign(assigns, :field, field)

    case field do
      %{omitted: true} -> empty_render(assigns)
      %{renderer: f} when is_function(f, 1) -> custom_render(assigns)
      _field -> default_render(assigns)
    end
  end

  ## PRIVATE
  @spec get_field_info(map()) :: map()
  defp get_field_info(%{
         _path: %{name: name} = path,
         _configurations: configurations,
         _resource_name: resource_name
       })
       when is_tuple(name) do
    name
    |> elem(0)
    |> then(&Map.put(path, :name, &1))
    |> get_field(configurations, resource_name)
  end

  defp get_field_info(%{
         _path: path,
         _configurations: configurations,
         _resource_name: resource_name
       }) do
    get_field(path, configurations, resource_name)
  end

  # Renders an empty component for omitted fields
  @spec empty_render(map()) :: Phoenix.LiveView.Rendered.t()
  defp empty_render(assigns) do
    ~H"""
    """
  end

  # Renders a field using its custom renderer function
  @spec custom_render(map()) :: Phoenix.LiveView.Rendered.t()
  defp custom_render(%{field: field} = assigns) do
    field.renderer.(assigns)
  end

  # Renders different field types with appropriate HTML structure and components
  @spec default_render(map()) :: Phoenix.LiveView.Rendered.t()
  defp default_render(%{field: %{field_type: :one_to_many_association, resource: nil}} = assigns) do
    ~H"""
    """
  end

  defp default_render(
         %{field: %{field_type: :one_to_many_association} = field, _auix: auix} = assigns
       ) do
    related_fields =
      field
      |> get_association_fields(auix._configurations)
      |> Enum.reject(&(&1.field == auix._resource_name))

    related_parsed_opts = get_in(auix._configurations, [field.resource, :parsed_opts])
    related_resource_config = get_in(auix._configurations, [field.resource, :resource_config])
    related_path = build_related_path(auix.source, field.data)

    related_class =
      "w-full rounded-lg text-zinc-900 sm:text-sm sm:leading-6 border border-zinc-300 px-4"

    parsed_opts = get_in(auix._configurations, [auix._resource_name, :parsed_opts])

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
        <.label for={"auix-one_to_many-#{@parsed_opts.module}__#{@field.field}-#{@_auix._mode}"}>{"#{@related_parsed_opts.title} Elements"}
            <.auix_link :if={!@related_parsed_opts.disable_index_new_link && @_auix[:_mode] == :form && @auix_entity.id != nil}
                navigate={"#{@related_parsed_opts.index_new_link}?related_key=#{@related_key}&parent_id=#{Map.get(@auix_entity, @owner_key)}"}
                id={"auix-new-#{@parsed_opts.module}__#{@field.field}-#{@_auix._mode}"}>
              <.icon name="hero-plus" />
            </.auix_link>
        </.label>
      </div>
      <div id={"auix-one_to_many-#{@parsed_opts.module}__#{@field.field}-#{@_auix._mode}"} class={@related_class}>
        <.table
          id={"#{@parsed_opts.module}__#{@field.field}-#{@_auix._mode}"}
          auix_css_classes={@_auix._css_classes}
          rows={Map.get(@auix_entity, @field.field)}
          row_click_navigate={if @related_parsed_opts.disable_index_row_click, do: nil, else: build_row_click(@related_parsed_opts, @related_path)}
        >
          <:col :let={entity} :for={related_field <- @related_fields} label={"#{related_field.label}"}><.auix_link navigate={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}"}>{Map.get(entity, related_field.field)}</.auix_link></:col>
          <:action :let={entity}>
            <div class="sr-only">
              <.auix_link navigate={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}"} name={"auix-show-#{@parsed_opts.module}__#{@related_parsed_opts.module}"} id={"auix-show-#{entity.id}-#{@_auix._mode}"}>Show</.auix_link>
            </div>
            <.auix_link navigate={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}/edit"} name={"auix-edit-#{@parsed_opts.module}__#{@related_parsed_opts.module}"} id={"auix-edit-#{entity.id}-#{@_auix._mode}"}><.icon name="hero-pencil" /></.auix_link>
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

  defp default_render(
         %{
           field: %{field_type: :many_to_one_association} = field_struct,
           _auix: %{_path: %{name: field_name}} = auix
         } = assigns
       )
       when is_atom(field_name) do
    inner_elements = get_association_paths(field_struct, auix._configurations, :show)
    association_label = get_in(auix._configurations, [field_struct.resource, :parsed_opts, :name])

    assigns
    |> put_in([:_auix, :_path], %{
      tag: :group,
      config: [group_id: "auix-field-#{field_struct.field}", title: association_label],
      inner_elements: inner_elements
    })
    |> put_in([:_auix, :_ignore_association_label], true)
    |> Renderer.render()
  end

  defp default_render(%{field: %{field_type: :many_to_one_association}} = assigns) do
    assigns
    |> parse_many_to_one_value()
    |> set_many_to_one_resource()
    |> trim_path()
    |> render()
  end

  defp default_render(%{field: field_struct} = assigns) do
    input_classes =
      "block w-full rounded-md border-zinc-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"

    field_id = "auix-field-#{field_struct.field}"

    assigns =
      assigns
      |> assign(:input_classes, input_classes)
      |> assign(:field_id, field_id)
      |> assign(:select_opts, get_select_options(field_struct))

    ~H"""
    <%= if @field.hidden do %>
      <input type="hidden" id={"#{@field_id}-#{@_auix._mode}"}
        {if @_auix._mode == :form, do: %{name: @_auix._form[@field.field].name, value: @_auix._form[@field.field].value},
         else: %{name: @field.field, value: @auix_entity[@field.field]}} />
    <% else %>
      <div class="flex flex-col">
        <.input
          id={"#{@field_id}-#{@_auix._mode}-#{next_count(:auix)}"}
          {if @_auix._mode == :form,
            do: %{field: @_auix._form[@field.field]},
            else: %{name: @field.field, value: Map.get(@auix_entity, @field.field)}}
          type={"#{@field.field_html_type}"}
          label={@field.label}
          options={@select_opts[:options]}
          multiple={@select_opts[:multiple]}
          readonly={@field.readonly}
          disabled={@field.disabled}
          class={@input_classes}
        />
      </div>
    <% end %>
    """
  end

  @spec parse_many_to_one_value(map()) :: map()
  defp parse_many_to_one_value(%{_auix: %{_path: %{name: name}}} = assigns) when is_atom(name),
    do: assigns

  defp parse_many_to_one_value(
         %{_auix: %{_path: %{name: names}, _mode: :show}, auix_entity: entity} = assigns
       )
       when is_tuple(names) do
    names
    |> Tuple.to_list()
    |> delete_last()
    |> Enum.reduce(entity, &Map.get(&2, &1, %{}))
    |> then(&Map.put(assigns, :auix_entity, &1))
  end

  defp parse_many_to_one_value(
         %{_auix: %{_path: %{name: names}, _form: form, _mode: :form} = auix} = assigns
       )
       when is_tuple(names) do
    names
    |> Tuple.to_list()
    |> delete_last()
    |> Enum.reduce(form, & &2[&1].form)
    |> then(&Map.put(auix, :_form, &1))
    |> then(&Map.put(assigns, :_auix, &1))
  end

  @spec trim_path(map()) :: map()
  defp trim_path(%{_auix: %{_path: %{name: name}}} = assigns) when is_atom(name), do: assigns

  defp trim_path(%{_auix: %{_path: %{name: names}}} = assigns) do
    names
    |> Tuple.to_list()
    |> List.last()
    |> then(&put_in(assigns, [:_auix, :_path, :name], &1))
  end

  @spec set_many_to_one_resource(map()) :: map()
  defp set_many_to_one_resource(%{_auix: %{_path: %{name: name}}} = assigns) when is_atom(name),
    do: assigns

  defp set_many_to_one_resource(
         %{
           _auix: %{_path: %{name: names}, _configurations: configurations},
           field: parent_field_struct
         } = assigns
       ) do
    field_struct =
      configurations
      |> get_in([parent_field_struct.resource, :parsed_opts, :name])
      |> then(&Map.put(parent_field_struct, :label, &1))

    field =
      names
      |> Tuple.delete_at(0)
      |> Tuple.to_list()
      |> Enum.reduce(field_struct, &get_many_to_one_field(&1, &2, configurations))

    assigns
    |> put_in(
      [
        :_auix,
        :_configurations,
        field.resource,
        :resource_config,
        Access.key!(:fields),
        field.field
      ],
      field
    )
    |> put_in([:_auix, :_resource_name], field.resource)
  end

  @spec get_many_to_one_field(atom(), map(), map()) :: map()
  defp get_many_to_one_field(
         field_name,
         %{resource: resource_name, label: parent_label} = _parent_field,
         configurations
       ) do
    %{name: field_name}
    |> get_field(configurations, resource_name)
    |> Map.update(:label, "", &"#{parent_label} #{&1}")
  end

  # Gets field configurations for associations from the resource configurations
  @spec get_association_fields(map(), map()) :: list(map())
  defp get_association_fields(field, configurations) do
    configurations
    |> get_in([field.resource, :defaulted_paths, :index, :inner_elements])
    |> Enum.filter(&(&1.tag == :field))
    |> Enum.map(fn path_field ->
      path_field
      |> get_field(configurations, field.resource)
      |> then(&%{label: &1.label, field: &1.field, field_type: &1.field_type})
    end)
  end

  @spec get_association_paths(map(), map(), atom()) :: list()
  defp get_association_paths(field_struct, configurations, path_type) do
    configurations
    |> get_in([field_struct.resource, :defaulted_paths, path_type, :inner_elements])
    |> Kernel.||([])
    |> convert_to_many_to_one_paths(field_struct.field)
  end

  @spec convert_to_many_to_one_paths(list(), atom()) :: list()
  defp convert_to_many_to_one_paths(paths, parent_field) do
    Enum.map(paths, &convert_to_many_to_one_path(&1, parent_field))
  end

  @spec convert_to_many_to_one_path(map(), atom()) :: map()
  defp convert_to_many_to_one_path(
         %{tag: :field, name: field_name, inner_elements: inner_elements} = path,
         parent_field
       ) do
    Map.merge(path, %{
      name: parent_field,
      config: [child_field: field_name],
      inner_elements: convert_to_many_to_one_paths(inner_elements, parent_field)
    })
  end

  defp convert_to_many_to_one_path(%{inner_elements: inner_elements} = path, parent_field) do
    Map.put(path, :inner_elements, convert_to_many_to_one_paths(inner_elements, parent_field))
  end

  # Builds the URL path template for related entity operations
  @spec build_related_path(binary(), map()) :: binary()
  defp build_related_path(source, data) do
    "source=#{source}/\#{@auix_entity.id}&related_key=#{data.related_key}&parent_id=\#{@auix_entity.#{data.owner_key}}"
  end

  # Creates a click handler function for row interactions in tables
  @spec build_row_click(map(), binary()) :: (map() -> JS.t())
  defp build_row_click(opts, path) do
    fn row ->
      row
      |> Map.get(:id)
      |> to_string()
      |> then(&String.replace("#{opts.index_row_click}?#{path}", "[[entity]]", &1))
    end
  end

  # Returns select field options and multiple selection flag if applicable
  @spec get_select_options(map()) :: map()
  defp get_select_options(%{field_html_type: :select, data: data}) do
    options = for {label, value} <- data[:opts], do: {label, value}
    %{options: options, multiple: data[:multiple] || false}
  end

  defp get_select_options(_field), do: %{}

  @spec delete_last(list()) :: list()
  defp delete_last([]), do: []

  defp delete_last(list) do
    list
    |> Enum.reverse()
    |> then(fn [_first | rest] -> rest end)
    |> Enum.reverse()
  end
end
