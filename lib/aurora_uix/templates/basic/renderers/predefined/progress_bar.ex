defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.ProgressBar do
  @moduledoc """
  Predefined `:progress_bar` renderer for numeric fields.

  - `:index` / `:show` — a read-only progress bar plus a percentage label.
  - `:form` — editing is not special; delegates to the default number input.

  The maximum defaults to `100`; override it per field with `data: %{max: 5}`.
  """

  use Aurora.Uix.Renderer

  alias Aurora.Uix.Renderers

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
    value = display_value(assigns)

    maximum =
      case assigns.field.data[:max] do
        nil -> 100
        configured -> to_number(configured)
      end

    pct = if maximum > 0, do: min(100.0, max(0.0, to_number(value) / maximum * 100)), else: 0.0
    assigns = assign(assigns, :pct, round(pct))

    ~H"""
    <div class="auix-progress" role="progressbar" aria-valuenow={@pct} aria-valuemin="0" aria-valuemax="100">
      <div class="auix-progress-bar" style={"width: #{@pct}%;"}></div>
      <span class="auix-progress-label">{@pct}%</span>
    </div>
    """
  end

  def render(%{auix: %{layout_type: :form}} = assigns),
    do: Renderers.default(assigns)

  @spec to_number(term()) :: number()
  defp to_number(n) when is_number(n), do: n

  defp to_number(n) when is_struct(n, Decimal), do: Decimal.to_float(n)

  defp to_number(n) when is_binary(n) do
    case Float.parse(n) do
      {number, _rest} -> number
      :error -> 0
    end
  end

  defp to_number(_other), do: 0
end
