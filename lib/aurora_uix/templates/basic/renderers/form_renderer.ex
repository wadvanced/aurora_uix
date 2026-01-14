defmodule Aurora.Uix.Templates.Basic.Renderers.FormRenderer do
  @moduledoc """
  Renders form live components for creating or editing entities in Aurora UIX.

  ## Key Features

  - Renders form containers and headers
  - Handles validation and submission
  - Integrates with Aurora UIX context and helpers
  - Supports customizable form layouts and actions

  This module handles the rendering of form components, including the form container,
  header, validation, and submission handling.
  """

  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.Components,
    only: [record_navigator_bar: 1, record_navigator?: 2]

  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a form view for creating or editing entities.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with form and layout configuration.
    * `:action` (atom()) - Current action (`:edit` or `:new`).

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered form with fields and submission actions.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <.record_navigator_bar :if={record_navigator?(@auix, :top)} pagination={@auix.pagination} item_index={@auix.item_index} />
      <.header>
        {if @action in [:edit, :show_edit], do: @auix.layout_options.edit_title, else: @auix.layout_options.new_title}
        <:subtitle>{if @action in [:edit, :show_edit], do: @auix.layout_options.edit_subtitle, else: @auix.layout_options.new_subtitle}</:subtitle>
        <:actions>
          <div name="auix-form-header-actions">
            <%= for %{function_component: action} <- @auix.form_header_actions do %>
              {action.(%{auix: @auix})}
            <% end %>
          </div>
        </:actions>
      </.header>

      <.flash kind={:error} flash={@flash} title="Error!" />

      <.simple_form
        for={@auix.form}
        id={"auix-#{@auix.module}-form"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="auix-form-container" data-layout={@auix.layout_tree.name}>
          <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
        </div>

        <:actions>
          <div name="auix-form-footer-actions">
            <%= for %{function_component: action} <- @auix.form_footer_actions do %>
                {action.(%{auix: @auix})}
            <% end %>
          </div>
        </:actions>
        <:actions>
          <.record_navigator_bar :if={record_navigator?(@auix, :bottom)} pagination={@auix.pagination} item_index={@auix.item_index} />
        </:actions>
      </.simple_form>

      <div id="portal-target"> </div>
    </div>
    """
  end
end
