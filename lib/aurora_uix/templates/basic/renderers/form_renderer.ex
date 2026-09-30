defmodule Aurora.Uix.Templates.Basic.Renderers.FormRenderer do
  @moduledoc """
  Renders form live components for creating or editing entities in Aurora UIX.

  ## Key Features

  - Renders form containers and headers
  - Handles validation and submission
  - Integrates with Aurora UIX context and helpers
  - Supports customizable form layouts and actions
  - Renders the discard-changes dialog when a form with unsaved changes is closed

  This module handles the rendering of form components, including the form container,
  header, validation, and submission handling.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver

  import Aurora.Uix.Templates.Basic.Components,
    only: [record_navigator_bar: 1, record_navigator?: 2]

  alias Aurora.Uix.Templates.Basic.Renderer
  alias Phoenix.LiveView.JS

  @doc """
  Renders a form view for creating or editing entities.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with form and layout configuration.
    * `:action` (atom()) - Current action (`:edit`, `:new`, `:show_edit`).

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered form with fields and submission actions.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <.record_navigator_bar :if={@action in [:edit, :show_edit] and record_navigator?(@auix, :top)} pagination={@auix.pagination} item_index={@auix.item_index} />
      <.header>
        {if @action in [:edit, :show_edit], do: dt(@auix.layout_options.edit_title), else: dt(@auix.layout_options.new_title)}
        <:subtitle>{if @action in [:edit, :show_edit], do: dt(@auix.layout_options.edit_subtitle), else: dt(@auix.layout_options.new_subtitle)}</:subtitle>
        <:actions>
          <div name="auix-form-header-actions">
            <%= for %{function_component: action} <- @auix.form_header_actions do %>
              {action.(%{auix: @auix})}
            <% end %>
          </div>
        </:actions>
      </.header>

      <.flash kind={:error} flash={@flash} title={dt("Error!")} />
      <.flash kind={:info} flash={@flash} title={dt("Info")} />

      <.simple_form
        for={@auix.form}
        id={"auix-#{@auix.module}-form"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="auix-form-container" data-layout={@auix.layout_tree.name}>
          <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} uploads={assigns[:uploads] || %{}} />
        </div>

        <:actions>
          <div name="auix-form-footer-actions">
            <%= for %{function_component: action} <- @auix.form_footer_actions do %>
                {action.(%{auix: @auix})}
            <% end %>
          </div>
        </:actions>
        <:actions>
          <.record_navigator_bar :if={@action in [:edit, :show_edit] and record_navigator?(@auix, :bottom)} pagination={@auix.pagination} item_index={@auix.item_index} />
        </:actions>
      </.simple_form>

      <div id="portal-target"> </div>

      <.modal :if={@auix._discard_confirm_open?} id={"auix-#{@auix.module}-discard-confirm-modal"} show on_cancel={JS.push("auix_keep_editing", target: @myself)}>
        <div class="auix-discard-confirm">
          <div class="auix-discard-confirm-message">{dt("You have unsaved changes. Discard them and close the form?")}</div>
          <div class="auix-discard-confirm-actions">
            <.button type="button" class="auix-button--alt" name="auix-keep-editing" phx-click="auix_keep_editing" phx-target={@myself}>{dt("Keep editing")}</.button>
            <.button type="button" name="auix-discard-changes" phx-click="auix_discard_changes" phx-target={@myself}>{dt("Discard changes")}</.button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end
