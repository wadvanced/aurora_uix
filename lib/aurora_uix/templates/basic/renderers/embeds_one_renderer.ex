defmodule Aurora.Uix.Templates.Basic.Renderers.EmbedsOneRenderer do
  @moduledoc """
  Renders embedded one-to-one associations within forms and show layouts.

  ## Key Features

  - Supports embedded form fields with nested layouts.
  - Handles both form and show view rendering modes.
  - Integrates with Aurora UIX context and layout configuration.

  ## Key Constraints

  - Requires field configuration with embedded resource information.
  - Layout must be available for the embedded resource.
  """
  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Helpers.Common, as: CommonHelper
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders an embedded one-to-one field based on its configuration.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with form and layout configuration.
    * `:field` (map()) - Field definition with embedded resource information.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered embeds_one component or nested form fields.
  """

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{
          field: %{data: %{resource: embed_resource_name}} = field,
          auix: %{layout_type: :form}
        } = assigns
      ) do
    layout_tree = BasicHelpers.get_layout(assigns, embed_resource_name, :form)

    field =
      assigns
      |> BasicHelpers.get_resource(embed_resource_name, [:resource_config, :name])
      |> CommonHelper.capitalize()
      |> then(&struct(field, label: &1))

    assigns =
      assigns
      |> BasicHelpers.assign_auix(:layout_tree, layout_tree)
      |> BasicHelpers.assign_auix(:resource_name, embed_resource_name)
      |> assign(:field, field)

    ~H"""
      <div class="auix-embeds-one-container">
        <.header>
          {@field.label}
        </.header>
        <.inputs_for :let={embed_form} field={@auix.form[@field.key]}>
          <Renderer.render_inner_elements auix={Map.put(@auix, :form, embed_form)} />     
        </.inputs_for>
      </div>
    """
  end

  def render(
        %{
          field: %{key: key, data: %{resource: embed_resource_name}},
          auix: %{entity: entity, layout_type: :show}
        } = assigns
      ) do
    layout_tree = BasicHelpers.get_layout(assigns, embed_resource_name, :show)

    assigns =
      assigns
      |> BasicHelpers.assign_auix(:layout_tree, layout_tree)
      |> BasicHelpers.assign_auix(:resource_name, embed_resource_name)
      |> BasicHelpers.assign_auix(:entity, Map.get(entity || %{}, key))

    ~H"""
      <div class="auix-embeds-one-container">
        <.header>
          {@field.label}
        </.header>
          <Renderer.render_inner_elements auix={@auix} />     
      </div>

    """
  end
end
