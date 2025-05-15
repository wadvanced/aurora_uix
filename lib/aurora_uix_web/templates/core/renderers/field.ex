defmodule Aurora.Uix.Web.Templates.Core.Renderers.Field do
  @moduledoc """
  Renderer for form fields in Aurora UIX.
  """

  use Aurora.Uix.Web.CoreComponents
  import Aurora.Uix.Web.Templates.Core, only: [get_field: 3]

  alias Phoenix.LiveView.JS
  alias Aurora.Uix.Web.Templates.Core.Components.Live.AuroraIndexList

  @doc """
  Renders a form field based on its type and configuration.

  ## Parameters
    - assigns (map()) - The assigns map (Aurora UIX context)

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  def render(%{_auix: auix} = assigns) do
    field = get_field(auix._path, auix._configurations, auix._resource_name)
    assigns = assign(assigns, :field, field)

    case field do
      %{omitted: true} -> empty_render(assigns)
      %{renderer: f} when is_function(f, 1) -> custom_render(assigns)
      _field -> default_render(assigns)
    end
  end

  def empty_render(assigns) do
    ~H"""
    """
  end

  def custom_render(%{field: field} = assigns) do
    field.renderer.(assigns)
  end

  def default_render(%{field: %{field_type: :one_to_many_association, resource: nil}} = assigns) do
    ~H"""
    """
  end

  def default_render(
        %{field: %{field_type: :one_to_many_association} = field, _auix: auix} = assigns
      ) do
    resource_fields = get_association_fields(field, auix._configurations)
    related_parsed_opts = get_in(auix._configurations, [field.resource, :parsed_opts])
    related_path = build_related_path(auix.source, field.data)

    assigns =
      assigns
      |> Map.put(:related_parsed_opts, related_parsed_opts)
      |> Map.put(:related_path, related_path)
      |> Map.put(:resource_fields, resource_fields)

    ~H"""
    <.live_component
      module={AuroraIndexList}
      id={"auix-#{@parsed_opts.name}__#{@field.field}"}
      title={"#{@related_parsed_opts.title} Elements"}
      module_name={@related_parsed_opts.title}
      rows={@auix_entity[@field.field]}
      columns={@resource_fields}
      row_id={fn child -> child.id end}
      new_link={if @related_parsed_opts.disable_index_new_link, do: nil, else: build_new_link(@related_parsed_opts, @related_path)}
      row_click={if @related_parsed_opts.disable_index_row_click, do: nil, else: build_row_click(@related_parsed_opts, @related_path)}
    >
      <:action :let={entity}>
        <div class="sr-only">
          <.link navigate={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}?#{@related_path}"} id={"auix-show-#{entity.id}"}>Show</.link>
        </div>
        <.link patch={"/#{@related_parsed_opts.link_prefix}#{@related_parsed_opts.source}/#{entity.id}/edit?#{@related_path}"} id={"auix-edit-#{entity.id}"}>Edit</.link>
      </:action>
    </.live_component>
    """
  end

  def default_render(%{field: %{field_type: :many_to_one_association}} = assigns) do
    ~H"""
    <div>ASSOCIATION: many_to_one_association <%= inspect(@field.field) %></div>
    """
  end

  def default_render(assigns) do

    input_classes =
      "block w-full rounded-md border-zinc-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"

    field_id = "auix-field-#{assigns.field.field}"

    assigns =
      assigns
      |> assign(:input_classes, input_classes)
      |> assign(:field_id, field_id)
      |> assign(:select_opts, get_select_options(assigns.field))

    ~H"""
    <%= if @field.hidden do %>
      <input type="hidden" id={"#{@field_id}-#{@_auix._mode}"}
        {if @_auix._mode == :form, do: %{name: @_auix._form[@field.field].name, value: @_auix._form[@field.field].value},
         else: %{name: @field.field, value: @auix_entity[@field.field]}} />
    <% else %>
      <div class="flex flex-col">
        <.input
          id={"#{@field_id}-#{@_auix._mode}"}
          {if @_auix._mode == :form,
            do: %{field: @_auix._form[@field.field]},
            else: %{name: @field.field, value: Map.get(@auix_entity, @field.field)}}
          type={@field.field_html_type}
          label={@field.label}
          {@select_opts}
          readonly={@field.readonly}
          disabled={@field.disabled}
          class={@input_classes}
        />
      </div>
    <% end %>
    """
  end

  # Helper functions
  defp get_association_fields(field, configurations) do
    configurations
    |> get_in([field.resource, :defaulted_paths, :index, :inner_elements])
    |> Enum.filter(&(&1.tag == :field))
    |> Enum.map(&get_field(&1, configurations, field.resource))
    |> Enum.map(&%{label: &1.label, field: &1.field, field_type: &1.field_type})
  end

  defp build_related_path(source, data) do
    "source=#{source}/\#{@auix_entity.id}&related_key=#{data.related_key}&parent_id=\#{@auix_entity.#{data.owner_key}}"
  end

  defp build_new_link(opts, _path) do
    # {opts.source}", @auix_entity, :#{opts.data.related_key}, :#{opts.data.owner_key})}"
    "#{opts.index_new_link}?\#{related_path("
  end

  defp build_row_click(opts, path) do
    fn row ->
      id = row |> Map.get(:id) |> to_string()
      link = String.replace("#{opts.index_row_click}?#{path}", "[[entity]]", id)
      JS.navigate(URI.decode("/#{link}"))
    end
  end

  defp get_select_options(%{field_html_type: :select, data: data}) do
    options = for {label, value} <- data[:opts], do: {label, value}
    %{options: options, multiple: data[:multiple] || false}
  end

  defp get_select_options(_field), do: %{}
end
