defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Image do
  @moduledoc """
  Predefined `:image` renderer for string fields holding an image URL or data-URL.

  - `:index` — a small thumbnail.
  - `:show` — the image at display size.
  - `:form` — editing is not special; delegates to the default text input for the URL.
  """

  use Aurora.Uix.Renderer

  alias Aurora.Uix.Renderers

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: :index}} = assigns), do: image(assigns, "auix-image--thumb")

  def render(%{auix: %{layout_type: :show}} = assigns), do: image(assigns, "")

  def render(%{auix: %{layout_type: :form}} = assigns),
    do: Renderers.default(assigns)

  # PRIVATE

  @spec image(map(), binary()) :: Phoenix.LiveView.Rendered.t()
  defp image(assigns, modifier) do
    assigns = assigns |> assign(:value, display_value(assigns)) |> assign(:modifier, modifier)

    ~H"""
    <img :if={@value not in [nil, ""]} src={@value} alt={dt(@field.label)} class={["auix-image", @modifier]} />
    """
  end
end
