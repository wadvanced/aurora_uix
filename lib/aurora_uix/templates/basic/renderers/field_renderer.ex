defmodule Aurora.Uix.Templates.Basic.Renderers.FieldRenderer do
  @moduledoc """
  Renders form fields for Aurora UIX, supporting standard, one-to-many, many-to-one, hidden, and custom field types.

  ## Key Features

  - Dynamically renders fields based on type and configuration
  - Delegates to association renderers for one-to-many and many-to-one fields
  - Supports custom field renderers
  - Handles omitted and hidden fields gracefully
  - Integrates with Aurora UIX context and helpers
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderers.EmbedOneRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.ManyToOne
  alias Aurora.Uix.Templates.Basic.Renderers.OneToMany

  @doc """
  Renders a form field based on its type and configuration.

  ## Parameters
  - assigns (map()) - LiveView assigns; must include:
    - auix (map()) - Aurora UIX context
    - field (map()) - Field configuration and metadata

  ## Returns
  - Phoenix.LiveView.Rendered.t() - The rendered field component
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: auix} = assigns) do
    field =
      get_field_info(auix)

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
         layout_tree: %{name: name} = layout_tree,
         configurations: configurations,
         resource_name: resource_name
       })
       when is_tuple(name) do
    name
    |> elem(0)
    |> then(&Map.put(layout_tree, :name, &1))
    |> BasicHelpers.get_field(configurations, resource_name)
  end

  defp get_field_info(%{
         layout_tree: layout_tree,
         configurations: configurations,
         resource_name: resource_name
       }) do
    BasicHelpers.get_field(layout_tree, configurations, resource_name)
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

  defp default_render(%{field: %{type: :embed_one}} = assigns),
    do: EmbedOneRenderer.render(assigns)

  # Renders standard field types with appropriate HTML structure
  defp default_render(assigns) do
    assigns =
      assigns
      |> assign(:input_classes, "auix-form-field-input")
      |> assign(:select_opts, BasicHelpers.get_select_options(assigns))

    ~H"""
    <%= if @field.hidden do %>
      <input type="hidden" id={"#{@field.html_id}-#{@auix.layout_type}"}
        {if @auix.layout_type == :form, do: %{name: @auix.form[@field.key].name, value: @auix.form[@field.key].value},
         else: %{name: @field.key, value: @auix.entity[@field.key]}} />
    <% else %>
      <div class="auix-form-field-container">
        <.default_render_input 
            auix={@auix}
            field={@field}
            input_classes={@input_classes}
            select_opts={@select_opts} 
        />
      </div>
    <% end %>
    """
  end

  @spec default_render_input(map()) :: Phoenix.LiveView.Rendered.t()
  defp default_render_input(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
      <div class="auix-form-field-container">
        <.input
          id={"#{@field.html_id}-#{@auix.layout_type}"}
          field={@auix.form[@field.key]}
          type={"#{@field.html_type}"}
          label={@field.label}
          options={@select_opts[:options]}
          multiple={@select_opts[:multiple]}
          readonly={@field.readonly}
          disabled={@field.disabled}
          class={@input_classes}
        />
      </div>

    """
  end

  defp default_render_input(%{auix: %{layout_type: :show}} = assigns) do
    ~H"""
      <div class="auix-form-field-container">
        <.input
          id={"#{@field.html_id}-#{@auix.layout_type}"}
          name={@field.key}
          value={Map.get(@auix.entity || %{}, @field.key)}
          type={"#{@field.html_type}"}
          label={@field.label}
          options={@select_opts[:options]}
          multiple={@select_opts[:multiple]}
          readonly={@field.readonly}
          disabled={true}
          class={@input_classes}
        />
      </div>

    """
  end
end
