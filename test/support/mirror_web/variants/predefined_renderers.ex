defmodule Aurora.UixWeb.Test.Mirror.Variants.PredefinedRenderers do
  @moduledoc """
  The `predefined-renderers` views variant: every predefined renderer on one product.

  ## Key Features

  - Sets the toggle switch, badge, colour, progress bar, URL and rating renderers on the index,
    show and form slots of six product fields

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.PredefinedRenderers` and
    `Aurora.UixWeb.Test.MirrorCtx.PredefinedRenderers`
  """

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource :product do
        field(:inactive,
          renderer: :toggle_switch,
          index_renderer: :toggle_switch,
          label: "Toggle switch"
        )

        field(:status, renderer: :badge, index_renderer: :badge, label: "Badge")
        field(:reference, renderer: :color, index_renderer: :color, label: "Colour")

        field(:quantity_at_hand,
          renderer: :progress_bar,
          index_renderer: :progress_bar,
          renderer_opts: [max: 100],
          label: "Progress bar"
        )

        field(:description, renderer: :url, index_renderer: :url, label: "URL")

        field(:cost,
          renderer: :rating,
          index_renderer: :rating,
          renderer_opts: [max: 5],
          label: "Rating"
        )
      end

      auix_create_ui()
    end
  end
end
