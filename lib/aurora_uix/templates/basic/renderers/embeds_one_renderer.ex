defmodule Aurora.Uix.Templates.Basic.Renderers.EmbedsOneRenderer do
  @moduledoc """
  Renders an embedded one-to-one association within a form.
  """
  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Helpers.Common, as: CommonHelper
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a embedded field based on its configuration.

  ## Parameters
  - assigns (map()) - LiveView assigns.

  ## Returns
  - Phoenix.LiveView.Rendered.t() - The rendered embeds_one component
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

    assigns
    |> BasicHelpers.assign_auix(:layout_tree, layout_tree)
    |> BasicHelpers.assign_auix(:resource_name, embed_resource_name)
    |> BasicHelpers.assign_auix(:entity, Map.get(entity, key))
    |> Renderer.render_inner_elements()
  end
end
