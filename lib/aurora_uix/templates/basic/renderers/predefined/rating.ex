defmodule Aurora.Uix.Templates.Basic.Renderers.Predefined.Rating do
  @moduledoc """
  Predefined `:rating` renderer for numeric fields.

  - `:index` / `:show` — read-only filled/empty stars.
  - `:form` — an interactive star selector backed by a radio group bound to the form
    field (pure HTML/CSS, no JS hook required).

  The number of stars defaults to `5`; override it per field with `data: %{max: 10}`.
  """

  use Aurora.Uix.Renderer

  @impl Aurora.Uix.Renderer
  def render(%{auix: %{layout_type: :form}} = assigns) do
    field = form_field(assigns)

    assigns =
      assigns
      |> assign(:name, field.name)
      |> assign(:current, to_int(field.value))
      |> assign(:scale, scale(assigns.field))

    ~H"""
    <fieldset class="auix-fieldset auix-rating auix-rating--input">
      <.label>{dt(@field.label)}</.label>
      <div class="auix-rating-stars">
        <label :for={i <- @scale} class="auix-rating-star-label">
          <input
            type="radio"
            name={@name}
            value={i}
            checked={i == @current}
            class="auix-rating-radio"
          />
          <span class={["auix-rating-star", i <= @current and "auix-rating-star--on"]} aria-hidden="true">★</span>
        </label>
      </div>
    </fieldset>
    """
  end

  def render(%{auix: %{layout_type: :index}} = assigns) do
    assigns =
      assigns
      |> assign(:current, to_int(display_value(assigns)))
      |> assign(:scale, scale(assigns.field))

    ~H"""
    <span class="auix-rating" aria-label={"#{@current}/#{Enum.count(@scale)}"}>
      <span
        :for={i <- @scale}
        class={["auix-rating-star", i <= @current and "auix-rating-star--on"]}
        aria-hidden="true"
      >★</span>
    </span>
    """
  end

  def render(%{auix: %{layout_type: :show}} = assigns) do
    assigns =
      assigns
      |> assign(:current, to_int(display_value(assigns)))
      |> assign(:scale, scale(assigns.field))

    ~H"""
    <div class="auix-show-field">
      <span class="auix-label">{dt(@field.label)}</span>
      <span class="auix-rating" aria-label={"#{@current}/#{Enum.count(@scale)}"}>
        <span
          :for={i <- @scale}
          class={["auix-rating-star", i <= @current and "auix-rating-star--on"]}
          aria-hidden="true"
        >★</span>
      </span>
    </div>
    """
  end

  # PRIVATE

  @spec scale(map()) :: Range.t()
  defp scale(field) do
    stars_max =
      case field.data[:max] do
        nil -> 5
        configured -> to_int(configured)
      end

    1..max(stars_max, 1)
  end

  @spec to_int(term()) :: integer()
  defp to_int(n) when is_integer(n), do: n
  defp to_int(n) when is_float(n), do: trunc(n)
  defp to_int(n) when is_struct(n, Decimal), do: n |> Decimal.round(0) |> Decimal.to_integer()

  defp to_int(n) when is_binary(n) do
    case Integer.parse(n) do
      {int, _rest} -> int
      :error -> 0
    end
  end

  defp to_int(_other), do: 0
end
