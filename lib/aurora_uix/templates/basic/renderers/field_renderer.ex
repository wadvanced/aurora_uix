defmodule Aurora.Uix.Web.Templates.Basic.Renderers.FieldRenderer do
  @moduledoc """
  Renders form fields for Aurora UIX, supporting standard, one-to-many, many-to-one, hidden, and custom field types.

  ## Key Features

  - Dynamically renders fields based on type and configuration
  - Delegates to association renderers for one-to-many and many-to-one fields
  - Supports custom field renderers
  - Handles omitted and hidden fields gracefully
  - Integrates with Aurora UIX context and helpers
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Web.Templates.Basic.Renderers.ManyToOne
  alias Aurora.Uix.Web.Templates.Basic.Renderers.OneToMany

  @doc """
  Renders a form field based on its type and configuration.

  ## Parameters
  - assigns (map()) - LiveView assigns; must include:
    - auix (map()) - Aurora UIX context
    - auix_entity (map()) - Entity being rendered
    - field (map()) - Field configuration and metadata

  ## Returns
  - Phoenix.LiveView.Rendered.t() - The rendered field component
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: auix} = assigns) do
    field = get_field_info(auix)

    assigns = assign(assigns, :field, field)

    case field do
      %{omitted: true} ->
        empty_render(assigns)

      %{renderer: custom_renderer} when is_function(custom_renderer, 1) ->
        custom_renderer.(assigns)

      _field ->
        default_render(assigns)
    end
  end

  ## PRIVATE
  # Returns field info for rendering, handling tuple and atom names
  @spec get_field_info(map()) :: map()
  defp get_field_info(%{
         _path: %{name: name} = path,
         configurations: configurations,
         _resource_name: resource_name
       })
       when is_tuple(name) do
    name
    |> elem(0)
    |> then(&Map.put(path, :name, &1))
    |> BasicHelpers.get_field(configurations, resource_name)
  end

  defp get_field_info(%{
         _path: path,
         configurations: configurations,
         _resource_name: resource_name
       }) do
    BasicHelpers.get_field(path, configurations, resource_name)
  end

  # Renders an empty component for omitted fields
  @spec empty_render(map()) :: Phoenix.LiveView.Rendered.t()
  defp empty_render(assigns) do
    ~H"""
    """
  end

  @spec default_render(map()) :: Phoenix.LiveView.Rendered.t()
  # Delegates one-to-many association rendering
  defp default_render(%{field: %{type: :one_to_many_association}} = assigns),
    do: OneToMany.render(assigns)

  # Delegates many-to-one association rendering
  defp default_render(%{field: %{type: :many_to_one_association}} = assigns),
    do: ManyToOne.render(assigns)

  # Renders standard field types with appropriate HTML structure
  defp default_render(assigns) do
    input_classes =
      "block w-full rounded-md border-zinc-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"

    assigns =
      assigns
      |> assign(:input_classes, input_classes)
      |> assign(:select_opts, get_select_options(assigns))

    ~H"""
    <%= if @field.hidden do %>
      <input type="hidden" id={"#{@field.html_id}-#{@auix._mode}"}
        {if @auix._mode == :form, do: %{name: @auix._form[@field.key].name, value: @auix._form[@field.key].value},
         else: %{name: @field.key, value: @auix_entity[@field.key]}} />
    <% else %>
      <div class="flex flex-col">
        <.input
          id={"#{@field.html_id}-#{@auix._mode}"}
          {if @auix._mode == :form,
            do: %{field: @auix._form[@field.key]},
            else: %{name: @field.key, value: Map.get(@auix_entity || %{}, @field.key)}}
          type={"#{@field.html_type}"}
          label={@field.label}
          options={@select_opts[:options]}
          multiple={@select_opts[:multiple]}
          readonly={@field.readonly}
          disabled={@field.disabled or @auix._mode == :show}
          class={@input_classes}
        />
      </div>
    <% end %>
    """
  end

  # Returns select field options and multiple selection flag if applicable
  @spec get_select_options(map()) :: map()
  defp get_select_options(%{
         field: %{
           html_type: :select,
           data: %{resource: resource_name, related_key: related_key}
         }
       })
       when is_nil(resource_name) or is_nil(related_key),
       do: %{options: [], multiple: false}

  # Select options for Many to one
  defp get_select_options(
         %{
           field: %{
             html_type: :select,
             data: %{resource: resource_name}
           },
           auix: %{configurations: configurations}
         } = assigns
       ) do
    context = get_in(configurations, [resource_name, :resource_config, Access.key!(:context)])
    list_function = get_in(configurations, [resource_name, :parsed_opts, :list_function])

    context
    |> apply(list_function, [])
    |> Enum.map(&get_many_to_one_select_option(assigns, &1))
    |> then(&%{options: &1, multiple: false})
  end

  defp get_select_options(%{field: %{html_type: :select, data: select}}) do
    case select[:opts] do
      nil ->
        %{options: [], multiple: false}

      opts ->
        options = for {label, value} <- opts, do: {label, value}
        %{options: options, multiple: select[:multiple] || false}
    end
  end

  defp get_select_options(_assigns), do: %{options: [], multiple: false}

  @spec get_many_to_one_select_option(map(), term()) :: tuple()
  defp get_many_to_one_select_option(
         %{field: %{data: %{option_label: option_label, related_key: related_key}}},
         entity
       )
       when is_atom(option_label) do
    {Map.get(entity, option_label), Map.get(entity, related_key)}
  end

  defp get_many_to_one_select_option(
         %{field: %{data: %{option_label: option_label, related_key: related_key}}},
         entity
       )
       when is_function(option_label, 1) do
    {option_label.(entity), Map.get(entity, related_key)}
  end

  defp get_many_to_one_select_option(
         %{field: %{data: %{option_label: option_label, related_key: related_key}}} = assigns,
         entity
       )
       when is_function(option_label, 2) do
    {option_label.(assigns, entity), Map.get(entity, related_key)}
  end

  defp get_many_to_one_select_option(%{field: %{data: %{related_key: related_key}}}, entity) do
    {entity |> Map.get(related_key) |> to_string(), Map.get(entity, related_key)}
  end
end
