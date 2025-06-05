defmodule Aurora.Uix.Web.Templates.Basic.Renderers.FormRenderer do
  @moduledoc """
  Renderer module for form views in Aurora UIX.

  This module handles the rendering of form components, including the form container,
  header, validation, and submission handling.
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Renderer

  @doc """
  Renders a form view for creating or editing entities.

  ## Parameters
    - assigns (map()) - The assigns map (Aurora UIX context)

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage {@_auix.title} records in your database.</:subtitle>
      </.header>

      <.flash kind={:error} flash={@flash} title="Error!" />

      <.simple_form
        for={@_auix._form}
        id={"auix-#{@_auix.module}-form"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="auix-form-container p-4 border rounded-lg shadow bg-white" data-layout={@_auix._path.name}>
          <Renderer.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." id={"auix-save-#{@_auix.module}"}>Save {@_auix.name}</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
