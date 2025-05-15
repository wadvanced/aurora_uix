defmodule Aurora.Uix.Web.Templates.Core.Renderer do
  use Aurora.Uix.Web.CoreComponents

  alias Aurora.Uix.Web.Templates.Core.Renderers

  @doc """
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{_auix: %{_path: %{tag: :index}}} = assigns) do
    Renderers.Index.render(assigns)
  end

  def render(%{_auix: %{_path: %{tag: :show}}} = assigns) do
    Renderers.Show.render(assigns)
  end

  def render(assigns) do
    ~H"""
    """
  end
end
