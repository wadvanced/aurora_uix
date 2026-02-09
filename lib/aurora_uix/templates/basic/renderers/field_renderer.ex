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

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderers.EmbedsManyRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.EmbedsOneRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.ManyToOne
  alias Aurora.Uix.Templates.Basic.Renderers.OneToMany

  alias Phoenix.HTML.Form

  @doc """
  Renders a form field based on its type and configuration.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with configuration.
    * `:field` (map()) - Field configuration and metadata.

  ## Returns
  Phoenix.LiveView.Rendered.t() - The rendered field component.
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

  # PRIVATE

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

  defp default_render(%{field: %{type: :embeds_one}} = assigns),
    do: EmbedsOneRenderer.render(assigns)

  defp default_render(%{field: %{type: :embeds_many}} = assigns),
    do: EmbedsManyRenderer.render(assigns)

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
  defp default_render_input(%{auix: %{layout_type: :form, primary_key: primary_key}} = assigns) do
    primary_key = if is_list(primary_key), do: List.first(primary_key), else: primary_key

    assigns =
      assigns
      |> BasicHelpers.assign_auix(:primary_key, primary_key)
      |> maybe_set_one_to_many_relation_to_readonly(assigns.auix[:one_to_many_related_key])

    # id={"#{@field.html_id}--#{@auix.form[@auix.primary_key].value}--#{@auix.layout_type}"}
    # id={field_id(@auix.form, @field, @auix.primary_key, @auix.layout_type)}

    ~H"""
      <div class="auix-form-field-container">
        <.input
          id={field_id(@auix.form, @field, @auix.primary_key, @auix.layout_type)}
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
      <.maybe_create_hidden_field_for_one_to_many_field auix={@auix} field={@field} 
        one_to_many_related_key={@auix[:one_to_many_related_key]} />
    """
  end

  defp default_render_input(%{auix: %{layout_type: :show, primary_key: primary_key}} = assigns) do
    primary_key = if is_list(primary_key), do: List.first(primary_key), else: primary_key
    assigns = BasicHelpers.assign_auix(assigns, :primary_key, primary_key)

    # id={"#{@field.html_id}--#{Map.get(@auix.entity || %{}, @auix.primary_key)}--#{@auix.layout_type}"}

    ~H"""
      <div class="auix-form-field-container">
        <.input
          id={field_id(@auix.entity, @field, @auix.primary_key, @auix.layout_type)}
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

  @spec maybe_set_one_to_many_relation_to_readonly(map(), nil | atom()) :: map()
  defp maybe_set_one_to_many_relation_to_readonly(
         %{field: %{key: one_to_many_related_key} = field} = assigns,
         one_to_many_related_key
       ) do
    field
    |> struct(%{disabled: true, readonly: true})
    |> then(&Map.put(assigns, :field, &1))
  end

  defp maybe_set_one_to_many_relation_to_readonly(assigns, _one_to_many_related_key), do: assigns

  @spec maybe_create_hidden_field_for_one_to_many_field(map()) :: Phoenix.LiveView.Rendered.t()
  defp maybe_create_hidden_field_for_one_to_many_field(
         %{
           field: %{key: one_to_many_related_key},
           one_to_many_related_key: one_to_many_related_key
         } = assigns
       ) do
    ~H"""
      <.input
        field={@auix.form[@field.key]}
        type="hidden"
      />
    """
  end

  defp maybe_create_hidden_field_for_one_to_many_field(assigns), do: ~H""

  @spec field_id(struct() | map(), map(), atom(), atom()) :: binary()
  defp field_id(entity, field, primary_key, :show = layout_type) do
    "#{field.html_id}--#{Counter.next_count(:auix_fields_id)}--#{Map.get(entity || %{}, primary_key)}--#{layout_type}"
  end

  defp field_id(form, field, primary_key, :form = layout_type) do
    # "#{field.html_id}--#{Counter.next_count(:auix_fields_id)}--#{form[primary_key].value}--#{layout_type}"
    "#{field.html_id}--#{Form.input_id(form, field.key)}--#{form[primary_key].value}--#{layout_type}"
  end
end
