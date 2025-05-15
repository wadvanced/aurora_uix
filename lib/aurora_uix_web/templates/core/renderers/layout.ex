defmodule Aurora.Uix.Web.Templates.Core.Renderers.Layout do
  @moduledoc """
  Basic layout renderers (inline and stacked) for Aurora UIX.
  """

  use Aurora.Uix.Web.CoreComponents
  alias Aurora.Uix.Web.Templates.Core.Renderer

  @doc """
  Renders an inline layout with horizontal arrangement of fields.

  ## Parameters
    - assigns (map()) - The assigns map (Aurora UIX context)
  """
  def inline(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 sm:flex-row">
      <Renderer.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
    </div>
    """
  end

  @doc """
  Renders a stacked layout with vertical arrangement of fields.

  ## Parameters
    - assigns (map()) - The assigns map (Aurora UIX context)
  """
  def stacked(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <Renderer.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
    </div>
    """
  end

end
